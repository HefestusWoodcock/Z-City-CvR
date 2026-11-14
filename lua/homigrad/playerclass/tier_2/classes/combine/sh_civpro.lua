---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CIVIL_PROTECTION : PLAYER_CLASS
local CIVIL_PROTECTION = PLAYER_CLASS:New(
    "Civil Protection",
    "civpro",
    "A police unit working as Civil Protection.")

CIVIL_PROTECTION.subClasses = {
    default = true,
    i4 = true,
    i3 = true,
    i2 = true,
    i1 = true,
    rl = true
}
CIVIL_PROTECTION.moduleLoadOrder = {
    "class_sounds",
    "class_squads",
    "class_loadouts",
    "class_appearance",
    "class_taglines",
    "class_hud"
}

CLASS_MODULE:GetRegistered("class_squads")
            :GetRegistered("civpro_squads")
            :Attach(CIVIL_PROTECTION)
CLASS_MODULE:GetRegistered("class_appearance")
            :Attach(CIVIL_PROTECTION)
CLASS_MODULE:GetRegistered("class_loadouts")
            :Attach(CIVIL_PROTECTION)
CLASS_MODULE:GetRegistered("class_taglines")
            :GetRegistered("combine_taglines")
            :Attach(CIVIL_PROTECTION)
CLASS_MODULE:GetRegistered("class_sounds")
            :GetRegistered("combine_sounds")
            :Attach(CIVIL_PROTECTION)
CLASS_MODULE:GetRegistered("class_hud")
            :GetRegistered("combine_hud")
            :Attach(CIVIL_PROTECTION)

CIVIL_PROTECTION.NoFreeze = true
CIVIL_PROTECTION.CanEmitRNDSound = false
CIVIL_PROTECTION.CanUseDefaultPhrase = true

function CIVIL_PROTECTION:On(player, data) 
    if SERVER then 
        player.organism.CantCheckPulse = true
        player.organism.recoilmul = 0.85
    end

    self:Super("On", player, data)
end

function CIVIL_PROTECTION:Off(player)
    if SERVER then 
        if IsValid(player.organism) then 
            player.organism.CantCheckPulse = nil
            hg.organism.Clear(player.organism)
        end
    end

    self:Super("Off", player)
end

---@warning This is a leaf class, and as such, no new object can be instantiated.
CIVIL_PROTECTION.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end