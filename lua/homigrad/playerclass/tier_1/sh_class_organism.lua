---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_ORGANISM : CLASS_MODULE
local CLASS_ORGANISM 
    = CLASS_MODULE:New(
        "Class Orhanism", 
        "class_organism", 
        "A module used to create custom organisms for specific classes.")

function CLASS_ORGANISM:Attach(classInstance)
    local uniqueID = CLASS_ORGANISM.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end