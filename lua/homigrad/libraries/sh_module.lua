---@type CLASS_TYPE
local CLASS_TYPE = hg.class

---@class MODULE : CLASS_TYPE
---@field moduleName string
---@field uniqueID string
---@field description string
---@field type string
---@field registry table<string, MODULE> Registry of instances created under this module base.
---@generic T : CLASS_TYPE
---@field attachedTo table<string, T> Registry of classes this module is attached to.
local MODULE = CLASS_TYPE:CreateClass("module", CLASS_TYPE)

MODULE.moduleName = "Module"
MODULE.uniqueID = "module"
MODULE.description = "Description of what this module does."
MODULE.type = "module"
MODULE.registry = {}
MODULE.attachedTo = {}

local types = {}

---This function is used to tranform strings into the classes' unique IDs.
---@param str string Passed string for formating.
---@return string str Newly formatted string.
local function FormatString(str)
    return str:lower():gsub("%s+", "_")
end

---This method attaches a module instance to a class object.
---@param classInstance CLASS_TYPE A class instance for the module to attach to.
---@param uniqueID? string Use this to assign an unique ID to the module being attached.
---@return true bool Returns true if it encounter no errors.
function MODULE:Attach(classInstance, uniqueID)
    if not classInstance:IsInstanceOf(CLASS_TYPE) then 
        error(string.format(
            "Module %s is attaching to a non-Class object.", 
            self.moduleName))
    end

    classInstance.modules = classInstance.modules or {}
    if classInstance.modules[self.uniqueID] then 
        error(string.format(
            "Class %s has already a %s module attached.", 
            classInstance.className,
            self.moduleName))
    end

    uniqueID = uniqueID or self.uniqueID
    classInstance.modules[uniqueID] = self
    self.attachedTo[classInstance.uniqueID] = classInstance

    return true
end

---This method gets a module base from the registry based on the type string given.
---@param moduleType string The name for the module type to be called.
---@return MODULE module Registered module type within the `module` base.
function MODULE:GetType(moduleType)
    local module = types[moduleType]

    if not module then 
        error(string.format(
            "Module type %s does not exist.", 
            moduleType))
    end

    return module
end

---This method returns the class that this module is attached to,
---using its unique ID.
---@warning Will throw an error if no such class is found to be attached to.
---@param classID string
---@return CLASS_TYPE class
function MODULE:GetAttached(classID)
    local class = self.attachedTo[classID]

    if not class then 
        error(string.format(
            "Class with id %s was not found to be attached to.", 
            classID))
    end

    return class
end

---Instantiate a new module type and add it to `hg.module` based on its type.
---@generic T : self
---@param moduleName string Name of the module.
---@param description string Description of what the module does.
---@param moduleType string Module type that is inherited by its other instances.
---@return T new Newly instantiated module.
---@usage `local example = hg.module:New("example", "desc", "exampleType")`
function MODULE:NewType(moduleName, moduleType, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.type = moduleType
    new.description = description
    new.registry = {}
    new.attached = {}

    if types[moduleType] then 
        error(string.format(
            "Module type %s already exists.", 
            moduleType)) 
    end

    types[moduleType] = new

    return new
end

---Method to get a table of all modules.
---
---@warning Makes a copy of the registry table and returns that.
---@return table<string, MODULE> modules A table of all registered instances created under the class.
function MODULE:GetAll()
    return table.Copy(self.registry)
end

---Returns a registered module in the registry of a module base.
---@param moduleID string
---@return MODULE module
function MODULE:GetRegistered(moduleID)
    local module = self.registry[moduleID]

    if not module then 
        error(string.format(
            "Module with id %s not found.", 
            moduleID))
    end

    return module
end

---Registers a new module instance into the module base registry table.
---@param instance MODULE The module instance to be registered.
function MODULE:Register(instance)
    local moduleID = instance.uniqueID

    if self.registry[moduleID] then 
        error(string.format(
            "Module with ID %s is already registered.", 
            moduleID))
    end

    self.registry[moduleID] = instance
end

---Creates a new instance of the module base and registers it to the base's registry.
---@generic T : self
---@param moduleName string Name of the module instance.
---@param uniqueID string The uniqueID of the instance.
---@param description string Description of the instance.
---@return T new The newly instantiated instance under the module type.
function MODULE:New(moduleName, uniqueID, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.uniqueID = uniqueID or FormatString(moduleName)
    new.description = description
    new.registry = {}
    new.attachedTo = {}

    self:Register(new)

    return new
end

hg.module = hg.module or MODULE

return MODULE