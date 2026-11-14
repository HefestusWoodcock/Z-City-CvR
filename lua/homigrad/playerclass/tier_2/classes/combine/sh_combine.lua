---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class COMBINE : PLAYER_CLASS
---@field configs {appearances: table, dispositions: table, loadouts: table, sounds: table, tags: table}
local COMBINE = PLAYER_CLASS:New(
    "Overwatch Transhuman Arm",
    "combine",
    "")

COMBINE.subClasses = {
    default = true,
    shotgunner = true,
    elite = true,
    sniper = true,
    ordinal = true,
    grunt = true,
    wallhammer = true,
    suppressor = true
}
COMBINE.moduleLoadOrder = {
    "class_sounds",
    "class_squads",
    "class_loadouts",
    "class_appearance",
    "class_taglines",
    "class_hud"
}

CLASS_MODULE:GetRegistered("class_squads")
            :GetRegistered("combine_squads")
            :Attach(COMBINE)
CLASS_MODULE:GetRegistered("class_appearance")
            :Attach(COMBINE)
CLASS_MODULE:GetRegistered("class_loadouts")
            :Attach(COMBINE)
CLASS_MODULE:GetRegistered("class_taglines")
            :GetRegistered("combine_taglines")
            :Attach(COMBINE)
CLASS_MODULE:GetRegistered("class_sounds")
            :GetRegistered("combine_sounds")
            :Attach(COMBINE)
CLASS_MODULE:GetRegistered("class_hud")
            :GetRegistered("combine_hud")
            :Attach(COMBINE)

COMBINE.NoFreeze = true
COMBINE.CanEmitRNDSound = false
COMBINE.CanUseDefaultPhrase = true

local function SetTranshumanOrganism(org)
    if not IsValid(org) then return end

    org.CantCheckPulse = true
    org.bleedingmul = 0.75
    org.recoilmul = 0.6
    org.legstrength = 1.5
    org.stamina.range = 60 * 4
    org.stamina.max = 60 * 4
    org.stamina[1] = org.stamina.range

    org.shockMul = 0.4
    org.painMul = 0.6
    org.hurtMul = 0.8
    org.immobilizationMax = 10

    org.adrenalineStorage = 8

    org.CantCheckPulse = nil
end

function COMBINE:On(player, data) 
    if SERVER then
        if IsValid(player.organism) then 
            SetTranshumanOrganism(player.organism)
        end
    end

    self:Super("On", player, data)
end

function COMBINE:Off(player)
    if SERVER then 
        player.organism.CantCheckPulse = nil
        hg.organism.Clear(player.organism)
    end

    self:Super("Off", player)
end

if CLIENT then

    hook.Add("ZC_DisableShootTinnitus", "NoCombineTinnitus", function(lply)
        if lply.PlayerClassName ~= "Combine" then return end
        return true
    end)

    hook.Add("ZC_BodyTemperature", "CombineSuitWarming", function(ply, org, timeValue, changeRate, MaxWarmMul, warmLoseMul)
        if ply.PlayerClassName ~= "Combine" then return end
        return changeRate, MaxWarmMul + 0.5, warmLoseMul - 0.4
    end)

end

hook.Add("HG_CanThoughts", "CombineCantDumat", function(ply)
    if ply.PlayerClassName == "Combine" then
        return false
    end
end)

---@warning This is a leaf class, and as such, no new object can be instantiated.
COMBINE.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end