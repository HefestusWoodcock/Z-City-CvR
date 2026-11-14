---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class INSURGENT : PLAYER_CLASS
local INSURGENT = PLAYER_CLASS:New(
    "Insurgent",
    "insurgent",
    "Chechen Fighters.")

INSURGENT.subClasses = {
    default = true,
    breacher = true,
    grenadier = true,
    heavy = true,
    sniper = true,
    medic = true
}
INSURGENT.moduleLoadOrder = {
    "class_loadouts",
    "class_appearance",
}

CLASS_MODULE:GetRegistered("class_appearance")
            :GetRegistered("rebel_appearance")
            :Attach(INSURGENT)
CLASS_MODULE:GetRegistered("class_loadouts")
            :Attach(INSURGENT)

INSURGENT.CanUseDefaultPhrase = true
INSURGENT.CanEmitRNDSound = true
INSURGENT.CanUseGestures = true

---@warning This is a leaf class, and as such, no new object can be instantiated.
INSURGENT.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end