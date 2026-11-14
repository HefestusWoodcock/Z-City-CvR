---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_LOADOUTS : CLASS_MODULE
local CLASS_LOADOUTS 
    = CLASS_MODULE:New(
        "Class Loadouts", 
        "class_loadouts", 
        "A module used to give loadouts to their respective classes.")
CLASS_LOADOUTS.__index = CLASS_LOADOUTS

function CLASS_LOADOUTS:Attach(classInstance)
    local uniqueID = CLASS_LOADOUTS.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end

if SERVER then 
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
            if primary and configPrimary then 
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
            if secondary and configSecondary then 
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
            if utility and utilityConfig then 
                for utility, count in pairs(utility) do 
                    local utilityData = utilityConfig[utility]
                    totalPoints = totalPoints + utilityData.points * count
                end
            end

            local items = loadout.items
            local itemsConfig = configLoadout.items
            if items and itemsConfig then 
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
    ---@param data { armor: { head?: string, torso?: string }, loadout: { base?, primary?, secondary?, utility?, items? }, pointLimit: number }
    function CLASS_LOADOUTS:On(player, data)
        local classID = player.PlayerClassName
        local subClass = player.subClass
        ---@type PLAYER_CLASS
        local class = self:GetAttached(classID)

        if not IsValidLoadout(class, subClass, data) then return end
        
        ClearItems(player)
        ClearArmor(player)

        ---@diagnostic disable-next-line:unchecked-nil-access
        local armor = data["armor"] or class.configs.presets[subClass].armor
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

    self:Register(new)

    return new
end