---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class REBEL : PLAYER_CLASS
local REBEL = PLAYER_CLASS:New(
    "Rebel",
    "rebel",
    "Le funny guys.")

REBEL.subClasses = {
    default = true,
    breacher = true,
    grenadier = true,
    heavy = true,
    sniper = true,
    medic = true
}
REBEL.moduleLoadOrder = {
    "class_loadouts",
    "class_appearance",
    "class_spawn"
}

CLASS_MODULE:GetRegistered("class_appearance")
            :GetRegistered("rebel_appearance")
            :Attach(REBEL)
CLASS_MODULE:GetRegistered("class_loadouts")
            :Attach(REBEL)
CLASS_MODULE:GetRegistered("class_spawn")
            :Attach(REBEL)

REBEL.CanUseDefaultPhrase = true
REBEL.CanEmitRNDSound = true
REBEL.CanUseGestures = true

---@warning This is a leaf class, and as such, no new object can be instantiated.
REBEL.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end