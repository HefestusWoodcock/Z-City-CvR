---@type CLASS_TYPE
local CLASS_TYPE = hg.class

---@class PLAYER_CLASS : CLASS_TYPE
---@field subClasses table<string, true> A table to check what subclasses a class object contains.
---@field configs table Configurations and data of the class instance.
---@field modules table<string, CLASS_MODULE> Attached class module instances to this class.
---@field moduleLoadOrder string[] An ordered array of module IDs, in-case their load ordering matters.
local PLAYER_CLASS = CLASS_TYPE:CreateClass("player_class", CLASS_TYPE)
PLAYER_CLASS.className = "Player Class"
PLAYER_CLASS.uniqueID = "player_class"
PLAYER_CLASS.description = "A playerclass object used to assign classes to players."
PLAYER_CLASS.subClasses = { default = true }
PLAYER_CLASS.configs = {}
PLAYER_CLASS.modules = {}
PLAYER_CLASS.moduleLoadOrder = nil

local registry = {}

---This function recursively reads through all the files inside a directory.
---@param dir string A string directory path.
local function ReadDir(dir, configTable)
    dir = dir .. "/"
	local files, directories = file.Find(dir .. "*", "GAME")
	if files then
		for k, v in ipairs(files) do
            local fileJSON = file.Read(dir .. v, "GAME")
			local fileName = string.Split(v, ".")
            configTable[fileName[1]] = util.JSONToTable(fileJSON)
            if fileName[1] == "tags" then 
                for k, v in pairs(configTable[fileName[1]]) do 
                    print(k .. " | " .. v)
                end
            end
            
		end
	end

	if directories then
		for k, v in ipairs(directories) do
			ReadDir(dir .. v, configTable)
		end
	end
end

---This method runs at start-up reads all the stored JSON data for
---the class and assigns them to the player class config table.
function PLAYER_CLASS:Init()
    local dir_path = "data_static/classes/" .. self.uniqueID
    ReadDir(dir_path, self.configs)

    --Load Order that has no type checking, 
    --so it's up to you to make sure you didn't mess up.
    local loadOrder = self.moduleLoadOrder
    if loadOrder then 
        for _, module in ipairs(loadOrder) do
            module = self:GetModule(module)
            if not module then continue end

            module:Init()
        end
    else 
        for _, module in pairs(self.modules) do 
            module:Init()
        end
    end
end

---Sets class-specific NPC dispositions for the player.
---@param player Player
---@param dispositions table A table of NPC classes to set dispositions to.
local function SetDisposition(player, dispositions)
    if not dispositions then return end
    for k, v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(dispositions["allies"],v:GetClass()) then
            v:AddEntityRelationship( player, D_LI, 0 )
            v:ClearEnemyMemory()
        elseif table.HasValue(dispositions["enemies"],v:GetClass()) then
            v:AddEntityRelationship( player, D_HT, 99 )
            v:ClearEnemyMemory()
        end
    end

    local index = player:EntIndex()
    hook.Add( "OnEntityCreated", "relation_shipdo" .. index, function( ent )
        if not IsValid(player) then 
            hook.Remove("OnEntityCreated", "relation_shipdo" .. index) 
            return 
        end
        if ( ent:IsNPC() ) then
            if table.HasValue(dispositions["allies"],ent:GetClass()) then
                ent:AddEntityRelationship( player, D_LI, 0 )
            end

            if table.HasValue(dispositions["enemies"],ent:GetClass()) then
                ent:AddEntityRelationship( player, D_HT, 99 )
            end
        end
    end )
end

---Resets class-specific positions set for a player.
---@param player Player
local function ResetDisposition(player, dispositions) 
    if not dispositions then return end 
    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(dispositions["allies"],v:GetClass()) then
            v:AddEntityRelationship( player, D_HT, 99 )
        elseif table.HasValue(dispositions["enemies"],v:GetClass()) then
            v:AddEntityRelationship( player, D_LI, 0 )
        end
    end

    hook.Remove("OnEntityCreated", "relation_shipdo" .. player:EntIndex())
end

---Player class event that runs when assigned to a player.
---@param player Player The player to assign the class to.
---@param data table A table of data to be processed.
function PLAYER_CLASS:On(player, data)
    if IsValid(self.FakeRagdoll) then
        hg.FakeUp(self, nil, nil)
    end
    
    if SERVER then
        local dispositions = self.configs.dispositions or nil
        SetDisposition(player, dispositions)
    end

    --- Class Modules

    --Load Order that has no type checking, 
    --so it's up to you to make sure you didn't mess up.
    local loadOrder = self.moduleLoadOrder
    if loadOrder then 
        for _, module in ipairs(loadOrder) do
            module = self:GetModule(module)
            if not module then continue end

            module:On(player, data)
        end
    else 
        for _, module in pairs(self.modules) do 
            module:On(player, data)
        end
    end

    return true
end

---Player class event that runs when player has the class removed.
---@param player Player The player to remove the class from.
function PLAYER_CLASS:Off(player)
    if SERVER then
        local dispositions = self.configs.dispositions or {}
        ResetDisposition(player, dispositions)
    end

     --Load Order that has no type checking, 
    --so it's up to you to make sure you didn't mess up.
    local loadOrder = self.moduleLoadOrder
    if loadOrder then 
        for _, module in ipairs(loadOrder) do
            module = self:GetModule(module)
            if not module then continue end

            module:Off(player)
        end
    else 
        for _, module in pairs(self.modules) do 
            module:Off(player)
        end
    end

    return true
end

---Player class event that runs when a player kills another player of the same class.
---Works only on specific gamemodes.
function PLAYER_CLASS:Guilt(player, victim)
    if victim:GetPlayerClass() == player:GetPlayerClass() then
        return 1
    end
end

---Player class event that runs when the player has died.
function PLAYER_CLASS:PlayerDeath(player)
    ResetDisposition(player, self.configs.dispositions)
end

---Player class event that runs every think tick.
---@param player Player
---@param time number
---@param dTime number
function PLAYER_CLASS:Think(player, time, dTime)
    return
end

---This function is used to tranform strings into the classes' unique IDs.
---@param str string
---@return string str
local function FormatString(str) 
    return str:lower():gsub("%s+", "_")
end

---Returns the entire table of stored PLAYER_CLASS instances.
---@return table<string, PLAYER_CLASS>
function PLAYER_CLASS:GetAll() 
    return table.Copy(registry)
end

---This method returns a requested class name,
---otherwise it will throw an error if none found.
---@param classID string 
---@return PLAYER_CLASS class
function PLAYER_CLASS:GetClass(classID)
    local class = registry[classID]
    if not class then 
        error(string.format(
                "Class with ID %s not found.", 
                classID)) 
    end

    return class
end

---Adds a new `PLAYER_CLASS` object to the registry for player classes.
---@param instance PLAYER_CLASS Newly instantiated player class to be registered.
function PLAYER_CLASS:Register(instance)
    local classID = instance.uniqueID

    if registry[classID] then 
        error(string.format(
                "Class with ID %s is already registered.", 
                classID))
    end

    registry[classID] = instance
end

---Returns an attached class module using its name or `nil` if not found.
---@param moduleID string Unique ID of module requested.
---@return CLASS_MODULE? module Returned module if found; otherwise, `nil`.
function PLAYER_CLASS:GetModule(moduleID)
    local module = self.modules[moduleID]
    if not module then return end
    return module
end

---Returns the config for a subclass, or for the 'default' subclass
---if not found.
---@warning Throws an error if the config type could not be found.
---@param configType string
---@param subClass string
---@return table config
function PLAYER_CLASS:GetSubConfig(configType, subClass)
    local config = self.configs[configType]
    if not IsValid(configType) then 
        error("Config of type " 
                .. configType 
                .. " could not be found") 
    end

    local config = config[subClass] or config["default"]
    return config
end

---Create a new player class instance and store in the player class registry.
---@generic T : self
---@param className string Name of player class.
---@param uniqueID string An unique ID of the class without spaces.
---@param description string Description of the player class.
---@return T new Newly instantiated player class object.
function PLAYER_CLASS:New(className, uniqueID, description)
    local new = setmetatable({}, self)

    new.className = className
    new.uniqueID = uniqueID or FormatString(className)
    new.description = description
    new.modules = {}
    new.configs = {}

    self:Register(new)

    local hookID = string.format(
        "%s_%s_Init", 
        new.name, 
        new.className)
    hook.Add("Initialize", hookID, function()
        new:Init()
    end)

    return new
end

hg.player_class = PLAYER_CLASS or {}

return PLAYER_CLASS