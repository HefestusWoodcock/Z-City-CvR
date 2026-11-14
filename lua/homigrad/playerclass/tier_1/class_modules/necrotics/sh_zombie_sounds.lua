---@type CLASS_SOUNDS
local CLASS_SOUNDS = hg.module:GetType("class_module"):GetRegistered("class_sounds")

---@class ZOMBIE_SOUNDS : CLASS_SOUNDS
local ZOMBIE_SOUNDS 
    = CLASS_SOUNDS:New(
        "Zombie Sounds", 
        "zombie_sounds", 
        "This module is used to generate sounds and phrases for zombie players.")

function ZOMBIE_SOUNDS:Init()
    return
    self:AddSoundHookToClass(self.HOOK_TYPE.FOOTSTEPS, function(player)
        local chr = hg.GetCurrentCharacter(player)
        if not self:ValidatePlayer(player) then return end

        if player:Alive() then
            local sounds = self:GetSounds(player, "footsteps")
            if not sounds then return end

            chr:EmitSound(sounds[math.random(#sounds)], 65, math.random(95, 105))
        end
    end)

	hook.Add("HG_ReplacePhrase", "ZombPhrases", function(ply, phrase, muffed, pitch) -- pitch means pitched effect, not exact sound pitch
        if not self:ValidatePlayer(ply) then return end
	
		local inPain = ply.organism.pain > 30
		local sounds = self:GetSounds(ply, inPain and "pain" or "idle")

		return ply, sounds[math.random(#sounds)], inPain and false or true, pitch
	end)

	hook.Add("HG_ReplaceBurnPhrase", "ZombBurnPhrases", function(ply, phrase)
		if not self:ValidatePlayer(ply) then return end

		local sounds = self:GetSounds(ply, "idle")

		return ply, sounds[math.random(#sounds)]
	end)
end

function ZOMBIE_SOUNDS:New(moduleName, uniqueID, description)
    error(string.format("The module %s is a leaf class.", self.moduleName))
end