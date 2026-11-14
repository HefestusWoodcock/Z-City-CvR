---@type MODULE
local MODULE = hg.module
---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class

---@class CLASS_MODULE : MODULE
local CLASS_MODULE = MODULE:NewType(
                        "Player Class Module",
                        "class_module",
                        "A module base used for creating player class modules.")
CLASS_MODULE.__index = CLASS_MODULE

---Runs at game initialization.
function CLASS_MODULE:Init()
    return
end

---Validates if a player is part of attached classes.
---@see Attach() and self.attachedTo
---@param player Player
---@return true | false
function CLASS_MODULE:ValidatePlayer(player)
    if not IsValid(player) then return end    
    local pClass = player.PlayerClassName
    local isOfClass = self.attachedTo[pClass]
    if isOfClass then 
        return true
    end
    return false
end

function CLASS_MODULE:Attach(classInstance, uniqueID)
    if not classInstance:IsInstanceOf(PLAYER_CLASS) then
        error(string.format(
            "The class instance is not of type %s.", 
            PLAYER_CLASS.name))
    end

    self:Super("Attach", classInstance, uniqueID)

    return true
end

---Player class module method called when the class is assigned.
---@param player? Player Player on which the module is called on. 
---@param data? any A table of module-specific data to be processed.
function CLASS_MODULE:On(player, data)
    return
end

---Player class module method called when the class is removed.
---@param player? Player Player on which the module is called on. 
function CLASS_MODULE:Off(player)
    return
end

---Create a new player class module instance and 
---store in the player class module registry.
---@generic T : self
---@param name string Name of the module.
---@param uniqueID string Unique ID of the new instance module.
---@param description string Description of its function.
---@return T new The newly instantiated class module.
---@usage `local EXAMPLE_MODULE = hg.module.classmodule:New("example_module", "Description")`
function CLASS_MODULE:New(name, uniqueID, description)
    local new = setmetatable({}, self)

    new.name = name
    new.uniqueID = uniqueID
    new.description = description
    new.type = self.type
    new.registry = {}
    
    self:Register(new)

    return new
end

return CLASS_MODULE