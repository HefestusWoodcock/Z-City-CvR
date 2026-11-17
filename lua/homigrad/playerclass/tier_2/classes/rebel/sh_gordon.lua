---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class GORDON : PLAYER_CLASS
local GORDON = PLAYER_CLASS:New(
    "Gordon Freeman",
    "gordon",
    "Le funny guys.")

GORDON.CanUseDefaultPhrase = true
GORDON.CanEmitRNDSound = true
GORDON.CanUseGestures = true

---@warning This is a leaf class, and as such, no new object can be instantiated.
GORDON.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end