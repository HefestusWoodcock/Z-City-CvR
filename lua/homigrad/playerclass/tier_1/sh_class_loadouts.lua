---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")
hg.loadout_manager = hg.loadout_manager or {}
local LOADOUT_MANAGER = hg.loadout_manager

---@class CLASS_LOADOUTS : CLASS_MODULE
local CLASS_LOADOUTS 
    = CLASS_MODULE:New(
        "Class Loadouts", 
        "class_loadouts", 
        "A module used to give loadouts to their respective classes.")
CLASS_LOADOUTS.__index = CLASS_LOADOUTS

function CLASS_LOADOUTS:Attach(classInstance)
    local uniqueID = CLASS_LOADOUTS.uniqueID
    local classID = classInstance.uniqueID

    for subClass, _ in pairs(classInstance.subClasses) do 
        CreateConVar("hg_points_" .. classID .. "_" .. subClass,
                20, 
                {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_PROTECTED}, 
                "This convar is used to set the number of acquisition points for a class::subClass pair.", 
                0)

        CreateConVar("hg_enabled_class_" .. classID .. "_" .. subClass,
                1, 
                {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_PROTECTED}, 
                "This convar is used to disable a class::subClass pair from being picked in the selector.", 
                0, 
                1)
    end

    self:Super("Attach", classInstance, uniqueID)
end

---Below are methods that are used to set loadout limits,
---and to be used by the loadout menu.

---Returns if a class::subClass pair can be picked or not.
---@param classID string
---@param subClass string
---@return boolean enabled
function CLASS_LOADOUTS:GetEnabledFor(classID, subClass)
    local class = self:GetAttached(classID)
    if not class then return end

    local enabled = GetConVar("hg_enabled_class_" .. classID .. "_" .. subClass):GetBool()
    return enabled
end

---Runs through all subclasses for a class, and if none of its subclasses are enabled, returns false.
---@param classID string
---@return boolean enabled
function CLASS_LOADOUTS:IsClassEnabled(classID)
    local class = self:GetAttached(classID)
    if not class then return end

    local subClasses = class.subClasses
    for subClass, _ in pairs(subClasses) do 
        local enabled = self:GetEnabledFor(classID, subClass)
        if enabled then return enabled end
    end
    return false
end

---Returns the point total convar for a class::subClass pair.
---@param classID string
---@param subClass string
---@return number pointTotal
function CLASS_LOADOUTS:GetPointsFor(classID, subClass)
    local class = self:GetAttached(classID)
    if not class then return end

    local pointTotal = GetConVar("hg_points_" .. classID .. "_" .. subClass):GetInt()
    return pointTotal
end

if CLIENT then 

    local presetsDir = "zcity/playerclass/presets/"

    function CLASS_LOADOUTS.GetPresetList(classID, subClass)
        local dir = presetsDir .. classID .. "/" .. subClass .. "/"
        file.CreateDir(dir)
        local files = file.Find(dir .. "*.json", "DATA")
        local presets = {}
        for _, f in ipairs(files or {}) do
            if f == "current.json" then continue end
            table.insert(presets, string.StripExtension(f))
        end

        return presets
    end

    function CLASS_LOADOUTS.ReadPreset(classID, subClass, name)
        local f = presetsDir .. classID .. "/" .. subClass .. "/" .. name .. ".json"
        if not file.Exists(f, "DATA") then return nil end

        return util.JSONToTable(file.Read(f, "DATA"))
    end

    function CLASS_LOADOUTS.WritePreset(classID, subClass, name, data)
        local dir = presetsDir .. classID .. "/" .. subClass .. "/"
        
        data.presetName = name

        file.CreateDir(dir)
        file.Write(dir .. name .. ".json", util.TableToJSON(data, true))
    end

    function CLASS_LOADOUTS.DeletePreset(classID, subClass, name) 
        local f = presetsDir .. classID .. "/" .. subClass .. "/" .. name .. ".json"
        if file.Exists(f, "DATA") then 
            file.Delete(f, "DATA")
        end
    end

    function CLASS_LOADOUTS.GetLastPreset(classID, subClass) 
        local f = presetsDir .. classID .. "/" .. subClass .. "/current.json"
        if not file.Exists(f, "DATA") then return nil end

        local data = util.JSONToTable(file.Read(f, "DATA"))
        return data
    end

    function CLASS_LOADOUTS.SetLastPreset(classID, subClass, data) 
        local dir = presetsDir .. classID .. "/" .. subClass .. "/"
        file.CreateDir(dir)
        file.Write(dir .. "current.json", util.TableToJSON(data, true))
    end

    function CLASS_LOADOUTS.DrawMenu() 
        return
    end

    net.Receive("OpenLoadoutManager", function(len)
        CLASS_LOADOUTS.DrawMenu()
    end)

else 

    util.AddNetworkString("OpenLoadoutManager")

    ---Set whether a class::subClass pair can be picked in the selector.
    ---@param classID string
    ---@param subClass string
    ---@param enabled boolean
    function CLASS_LOADOUTS:SetEnabledFor(classID, subClass, enabled) 
        local class = self:GetAttached(classID)
        if not class then return end

        local enabledConVar = GetConVar("hg_enabled_class_" .. classID .. "_" .. subClass)
        enabledConVar:SetBool(enabled)
    end

    ---Set the point total convar for a class::subClass pair.
    ---@param classID string
    ---@param subClass string
    ---@param points number
    function CLASS_LOADOUTS:SetPointsFor(classID, subClass, points)  
        local class = self:GetAttached(classID)
        if not class then return end
    
        local pointConVar = GetConVar("hg_points_" .. classID .. "_" .. subClass)
        pointConVar:SetInt(points)
    end

    ---Sends over the class and data for setting the player's class.
    ---@param player Player
    ---@param classID string
    ---@param subClass string
    ---@param data table
    function CLASS_LOADOUTS:SetLoadout(player, classID, subClass, data)
        local enabled = self:GetEnabledFor(classID, subClass)
        if not enabled then return end

        data.loadoutSet = true
        data.pointLimit = self:GetPointsFor(classID, subClass)
    
        player:SetPlayerClass(classID, subClass, data)
    end

    netstream.Hook("SetLoadout", function(player, classID, subClass, data)
        CLASS_LOADOUTS:SetLoadout(player, classID, subClass, data)
    end)

    COMMANDS.loadout = {
        function(ply, args)
            if not ply.PlayerClassName then return end
            if not ply:IsAdmin() then return end

            net.Start("OpenLoadoutManager")
            net.Send(ply)
        end,
        0
    }

    COMMANDS.setclassenabled = {
        function(ply, args)
            local bVal = tobool(args[1])
            local classID = args[2] and string.lower(args[2]) or nil
            local subClass = args[3] and string.lower(args[3]) or nil

            if not ply:IsAdmin() then return end
            local errorVal, class = pcall(PLAYER_CLASS.GetClass, PLAYER_CLASS, classID) 
            if errorVal and class then 
                local subClasses = class.subClasses
                if subClass then 
                    if not subClasses[subClass] then 
                        ply:ChatPrint("Sub class not found.")
                        return 
                    end
                    CLASS_LOADOUTS:SetEnabledFor(classID, subClass, bVal)
                    ply:ChatPrint("Sub class has been successfuly " .. (bVal and "enabled" or "disabled") .. " .")
                else 
                    for subClass, _ in pairs(subClasses) do 
                        CLASS_LOADOUTS:SetEnabledFor(classID, subClass, bVal)
                    end
                    ply:ChatPrint("Sub classses has been successfuly " .. (bVal and "enabled" or "disabled") .. " .")
                end
            else
                ply:ChatPrint("Class not found.")
            end
        end,
        0
    }

    COMMANDS.setclasspoints = {
        function(ply, args)
            local points = tonumber(args[1])
            local classID = args[2] and string.lower(args[2]) or nil
            local subClass = args[3] and string.lower(args[3]) or nil

            if not ply:IsAdmin() then return end
            local bVal, class = pcall(PLAYER_CLASS.GetClass, PLAYER_CLASS, classID) 
            if bVal and class then 
                local subClasses = class.subClasses
                if subClass then 
                    if not subClasses[subClass] then 
                        ply:ChatPrint("Sub class not found.")
                        return 
                    end
                    CLASS_LOADOUTS:SetPointsFor(classID, subClass, points)
                    ply:ChatPrint("Points have been set successfully for sub class.")
                else 
                    for subClass, _ in pairs(subClasses) do 
                        CLASS_LOADOUTS:SetPointsFor(classID, subClass, points)
                    end
                    ply:ChatPrint("Points have been set successfully for all sub classes.")
                end
            else
                ply:ChatPrint("Class not found.")
            end
        end,
        0
    }

end    

---Below are methods for checking and giving loadouts.

---Reads weapon table and gives the player the weapon, 
---applying ammo changes, and giving required ammunition.
---@param player Player Player to give weapon to.
---@param tbl table Table containing weapon class, and other configs.
local function GiveWeapon(player, tbl)
    local wep = player:Give(tbl.weapon)

    if IsValid(wep) then
        if tbl.ammoType then
            wep:ApplyAmmoChanges(tbl.ammoType)
        end
        if tbl.ammo then
            player:GiveAmmo(wep:GetMaxClip1() * tbl.ammo, wep:GetPrimaryAmmoType(), true)
        end
        if tbl.attachments then 
            for _, att in pairs(tbl.attachments) do 
                hg.AddAttachmentForce(player, wep, att)
            end
        end
    end
end

---Reads weapon table and gives the player the weapon, 
---applying ammo changes, and giving required ammunition.
---@param player Player Player to give item to.
---@param item string Class name of item.
---@param count? number Number of items to give.
local function GiveItem(player, item, count)
    local wep = player:Give(item)
    if item == "hg_flashlight" then 
        wep:Use(player)
        return
    end
    if IsValid(wep) then
        if count then
            wep.count = count
        end
    end
end

---Runs through the loadout list and gives items to the player.
---@param player Player Player to give loadout to.
---@param loadout table Table containing loadout data.
local function GiveLoadout(player, loadout)
    local base = loadout.base or {}
    for _, item  in ipairs(base) do 
        GiveItem(player, item, 1)
    end

    local primary = loadout.primary or {}
    if not table.IsEmpty(primary) then 
        GiveWeapon(player, primary) 
    end
    local secondary = loadout.secondary or {}
    if not table.IsEmpty(secondary) then 
        GiveWeapon(player, secondary) 
    end

    local utility = loadout.utility or {}
    for util, count in pairs(utility) do
        if count == 0 then continue end
        GiveItem(player, util, count)
    end

    local items = loadout.items or {}
    for item, bVal in pairs(items) do
        if not bVal then continue end
        GiveItem(player, item, 1)
    end
end

local function ClearItems(player) 
    player:StripWeapons()
    player:RemoveAllAmmo()
    player:Give("weapon_hands_sh")
end

local function SetArmor(player, config)
    player.armors = {}
    for placement, armor in pairs(config) do
        player.armors[placement] = armor
    end
    player:SyncArmor()
end

local function ClearArmor(player) 
    player.armors = {}
    player:SyncArmor()
end

---Calculates the cost of the chosen loadout and returns false,
---if it extends the allocated acqusition points.
---@param class PLAYER_CLASS
---@param subClass string
---@param data { armor: { head?: string, face?: string, torso?: string }, loadout: { primary?, secondary?, utility?, items? }, pointLimit: number }
---@return boolean
local function IsValidLoadout(class, subClass, data)
    local config = class:GetSubConfig("loadouts", subClass)
    
    local pointLimit = data.pointLimit
    if not pointLimit then 
        ErrorNoHalt("No point total logged in class data.")
        return false
    end

    local totalPoints = 0
    local armor = data.armor
    local armorConfig = config.armor or nil
    if armor and armorConfig then 
        for placement, armor in pairs(armor) do 
            local armorData = armorConfig[placement][armor]
            if not armorData then continue end
            totalPoints = totalPoints + armorData.points or 0
        end
    end

    local loadout = data.loadout
    local configLoadout = config.loadout or nil
    if loadout and configLoadout then 

        local primary = loadout.primary
        local configPrimary = configLoadout.primary
        if primary and configPrimary and not table.IsEmpty(primary) then 
            local weapon = primary.weapon
            local weaponData = configPrimary[weapon]
            totalPoints = totalPoints + weaponData.points or 0

            local ammoType = primary.ammoType
            local ammoNum = primary.ammo or 0
            local ammoTypeData = weaponData.ammoTypes[ammoType]
            totalPoints = totalPoints + ammoTypeData.points * ammoNum

            local attachments = primary.attachments
            local attachmentsConfig = weaponData.attachments
            if attachments and attachmentsConfig then 
                for placement, attachment in pairs(attachments) do 
                    local attachmentData = attachmentsConfig[placement][attachment]
                    totalPoints = totalPoints + attachmentData.points or 0
                end
            end
        end

        local secondary = loadout.secondary
        local configSecondary = configLoadout.secondary
        if secondary and configSecondary and not table.IsEmpty(secondary) then 
            print("Entered Secondary")
            local weapon = secondary.weapon
            local weaponData = configSecondary[weapon]
            totalPoints = totalPoints + weaponData.points or 0

            local ammoType = secondary.ammoType
            local ammoNum = secondary.ammo or 0
            local ammoTypeData = weaponData.ammoTypes[ammoType]
            totalPoints = totalPoints + ammoTypeData.points * ammoNum

            local attachments = secondary.attachments
            local attachmentsConfig = weaponData.attachments
            if attachments and attachmentsConfig then 
                for placement, attachment in pairs(attachments) do 
                    local attachmentData = attachmentsConfig[placement][attachment]
                    totalPoints = totalPoints + (attachmentData.points or 0)
                end
            end
        end

        local utility = loadout.utility
        local utilityConfig = configLoadout.utility
        if utility and utilityConfig and not table.IsEmpty(utility) then 
            for utility, count in pairs(utility) do 
                local utilityData = utilityConfig[utility]
                totalPoints = totalPoints + utilityData.points * count
            end
        end

        local items = loadout.items
        local itemsConfig = configLoadout.items
        if items and itemsConfig and not table.IsEmpty(items) then 
            for item, _ in pairs(items) do 
                local itemData = itemsConfig[item]
                totalPoints = totalPoints + (itemData.points or 0)
            end
        end
    end

    if totalPoints > pointLimit then return false end
    return true
end

---Sets a player's loadout on class assignment.
---@param player Player
---@param data { loadoutSet: boolean?, renderArmor: boolean?, armor: { head?: string, torso?: string }, loadout: { base?, primary?, secondary?, utility?, items? }, pointLimit: number }
function CLASS_LOADOUTS:On(player, data)
    local classID = player.PlayerClassName
    local subClass = player.subClass
    ---@type PLAYER_CLASS
    local class = self:GetAttached(classID)

    if CLIENT and not data.loadoutSet then 

        self:DrawMenu()

    end

    if SERVER then

        if not data.loadoutSet then return end
        if not IsValidLoadout(class, subClass, data) then return end
    
        ClearItems(player)
        ClearArmor(player)

        ---@diagnostic disable-next-line:unchecked-nil-access
        local armor = data["armor"] or class.configs.presets[subClass].armor
        player:SetNetVar("PlayerHideVest", not data.renderArmor)
        SetArmor(player, armor)
        

        ---@diagnostic disable-next-line:unchecked-nil-access
        local loadout = data.loadout or class.configs.presets[subClass].loadout
        GiveLoadout(player, loadout)

    end

end

function CLASS_LOADOUTS:New(moduleName, uniqueID, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.uniqueID = uniqueID
    new.description = description
    new.attachedTo = {}

    self:Register(new)

    return new
end