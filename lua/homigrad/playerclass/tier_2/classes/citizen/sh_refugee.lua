---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class REFUGEE : PLAYER_CLASS
local REFUGEE = PLAYER_CLASS:New(
    "Refugee",
    "refugee",
    "")

REFUGEE.subClasses = {
    default = true
}
REFUGEE.moduleLoadOrder = {
    "class_appearance",
    "class_loadouts"
}

CLASS_MODULE:GetRegistered("class_appearance")
            :GetRegistered("rebel_appearance")
            :Attach(REFUGEE)
CLASS_MODULE:GetRegistered("class_loadouts")
            :Attach(REFUGEE)

REFUGEE.CanUseDefaultPhrase = true
REFUGEE.CanEmitRNDSound = true
REFUGEE.CanUseGestures = true

---@warning This is a leaf class, and as such, no new object can be instantiated.
REFUGEE.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end