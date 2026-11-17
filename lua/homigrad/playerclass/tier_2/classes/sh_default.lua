---@class PLAYER_CLASS
local PLAYER_CLASS = hg.player_class

---@class DEFAULT : PLAYER_CLASS
local DEFAULT = PLAYER_CLASS:New(
    "Default", 
    "default", 
    "Default class of a player.")

DEFAULT.CanUseDefaultPhrase = true
DEFAULT.CanEmitRNDSound = true
DEFAULT.CanUseGestures = true

if CLIENT then 

else 

    function DEFAULT:Off(player, data)
        return true
    end

    function DEFAULT:On(player, data)
        ApplyAppearance(player)

        return true
    end

    function DEFAULT:Guilt(player, victim)
        return
    end

end

DEFAULT.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end