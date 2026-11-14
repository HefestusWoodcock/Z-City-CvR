local PLAYER_CLASS = hg.player_class

hg.class_selector = hg.class_selector or {}
local CLASS_SELECTOR = hg.class_selector

local presetsDir = "zcity/playerclass/presets/"

hook.Add("Initialize", "Init_Class_Points", function()
    local classes = PLAYER_CLASS:GetAll()

    for classID, class in pairs(classes) do 
        if classID == "gamemaster" 
            or classID == "overwatch" 
            or classID == "default" then continue end

        for subClass, _ in pairs(class.subClasses) do 
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
    end
end)

---Returns if a class::subClass pair can be picked or not.
---@param classID string
---@param subClass string
---@return boolean enabled
function CLASS_SELECTOR:GetEnabledFor(classID, subClass)
    local enabled = GetConVar("hg_enabled_class_" .. classID .. "_" .. subClass):GetBool()
    return enabled
end

---Runs through all subclasses for a class, and if none of its subclasses are enabled, returns false.
---@param classID string
---@return boolean enabled
function  CLASS_SELECTOR:IsClassEnabled(classID)
    local class = PLAYER_CLASS:GetClass(classID)
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
function CLASS_SELECTOR:GetPointsFor(classID, subClass)
    local pointTotal = GetConVar("hg_points_" .. classID .. "_" .. subClass):GetInt()
    return pointTotal
end

if CLIENT then 

    function CLASS_SELECTOR.GetPresetList(classID, subClass)
        local dir = presetsDir .. classID .. "/" .. subClass .. "/"
        file.CreateDir(dir)
        local files = file.Find(dir .. "*.json", "DATA")
        local presets = {}
        for _, f in ipairs(files or {}) do
            table.insert(presets, string.StripExtension(f))
        end
        return presets
    end

    function CLASS_SELECTOR.ReadPreset(classID, subClass, name)
        local f = presetsDir .. classID .. "/" .. subClass .. "/" .. name .. ".json"
        if not file.Exists(f, "DATA") then return nil end
        return util.JSONToTable(file.Read(f, "DATA"))
    end

    function CLASS_SELECTOR.WritePreset(classID, subClass, name, data)
        local dir = presetsDir .. classID .. "/" .. subClass .. "/"
        file.CreateDir(dir)
        file.Write(dir .. name .. ".json", util.TableToJSON(data, true))
    end

    net.Receive("OpenClassSelector", function(len)
        CLASS_SELECTOR.DrawSelector()
    end)

else 
    util.AddNetworkString("OpenClassSelector")

    ---Set whether a class::subClass pair can be picked in the selector.
    ---@param classID string
    ---@param subClass string
    ---@param enabled boolean
    function CLASS_SELECTOR:SetEnabledFor(classID, subClass, enabled) 
        local enabledConVar = GetConVar("hg_enabled_class_" .. classID .. "_" .. subClass)
        enabledConVar:SetBool(enabled)
    end

    ---Set the point total convar for a class::subClass pair.
    ---@param classID string
    ---@param subClass string
    ---@param points number
    function CLASS_SELECTOR:SetPointsFor(classID, subClass, points)    
        local pointConVar = GetConVar("hg_points_" .. classID .. "_" .. subClass)
        pointConVar:SetInt(points)
    end

    ---Sends over the class and data for setting the player's class.
    ---@param player Player
    ---@param classID string
    ---@param subClass string
    ---@param data table
    function CLASS_SELECTOR:SetPlayerClass(player, classID, subClass, data)
        local enabled = self:GetEnabledFor(classID, subClass)
        if not enabled then return end
    
        data.pointLimit = self:GetPointsFor(classID, subClass)
    
        player:SetPlayerClass(classID, subClass, data)
    end

    netstream.Hook("SetPlayerClass_ClassSelector", function(player, classID, subClass, data)
        CLASS_SELECTOR:SetPlayerClass(player, classID, subClass, data)
    end)

    COMMANDS.selectclass = {
        function(ply, args)
            net.Start("OpenClassSelector")
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
                    CLASS_SELECTOR:SetEnabledFor(classID, subClass, bVal)
                    ply:ChatPrint("Sub class has been successfuly " .. (bVal and "enabled" or "disabled") .. " .")
                else 
                    for subClass, _ in pairs(subClasses) do 
                        CLASS_SELECTOR:SetEnabledFor(classID, subClass, bVal)
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
                    CLASS_SELECTOR:SetPointsFor(classID, subClass, points)
                    ply:ChatPrint("Points have been set successfully for sub class.")
                else 
                    for subClass, _ in pairs(subClasses) do 
                        CLASS_SELECTOR:SetPointsFor(classID, subClass, points)
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