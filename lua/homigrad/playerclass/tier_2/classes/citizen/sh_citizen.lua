---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CITIZEN : PLAYER_CLASS
local CITIZEN = PLAYER_CLASS:New(
    "Citizen",
    "citizen",
    "Le funny guys.")

CITIZEN.subClasses = {
    default = true
}
CITIZEN.moduleLoadOrder = {
    "class_appearance"
}

CLASS_MODULE:GetRegistered("class_appearance")
            :GetRegistered("rebel_appearance")
            :Attach(CITIZEN)

CITIZEN.CanUseDefaultPhrase = true
CITIZEN.CanEmitRNDSound = true
CITIZEN.CanUseGestures = true

---@warning This is a leaf class, and as such, no new object can be instantiated.
CITIZEN.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end