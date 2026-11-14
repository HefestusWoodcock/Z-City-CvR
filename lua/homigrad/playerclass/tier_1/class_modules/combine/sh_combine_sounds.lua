---@type CLASS_SOUNDS
local CLASS_SOUNDS = hg.module:GetType("class_module"):GetRegistered("class_sounds")

---@class COMBINE_SOUNDS : CLASS_SOUNDS
local COMBINE_SOUNDS 
    = CLASS_SOUNDS:New(
        "Combine Sounds", 
        "combine_sounds", 
        "This module is used to generate sounds and phrases for Combine and Civil Protection units.")

function COMBINE_SOUNDS:Init()
    self:AddSoundHookToClass(self.HOOK_TYPE.FOOTSTEPS, function(player)
        local chr = hg.GetCurrentCharacter(player)
        if not self:ValidatePlayer(player) then return end

        if player:Alive() then
            local sounds = self:GetSounds(player, "footsteps")
            if not sounds then return end

            player.CombineLerpedFootstep 
                = LerpFT(0.5,
                    player.CombineLerpedFootStep or 60, 
                    (not player:IsSprinting() and (player:KeyDown(IN_DUCK) or player:KeyDown(IN_WALK))) and 20 or 60)
            if IsValid(player.FakeRagdoll) and player:GetNetVar("lastFake") == 0 then return end

            chr:EmitSound(
                sounds[math.random(#sounds)], 
                player.CombineLerpedFootstep)
        end
    end)

    --[[
    local hitgroups_sounds = {
        [HITGROUP_STOMACH] = true,
        [HITGROUP_CHEST]   = true,
        [HITGROUP_LEFTARM] = false,
        [HITGROUP_RIGHTARM] = false,
        [HITGROUP_RIGHTLEG] = false,
        [HITGROUP_LEFTLEG]  = false
    }
    self:AddSoundHookToClass(self.HOOK_TYPE.PAIN, function(player, dmgInfo, hitgroup, ent)
        if self:ValidatePlayer(player) then
            local sounds = self:GetSounds(player, "pain")

            player.painCD = player.painCD or 0
            if hitgroups_sounds[hitgroup] and player.painCD < CurTime() and player.organism and not player.organism.otrub and player:Alive() then
                local snd = sounds[math.random(#sounds)]
                player:EmitSound(snd,80,player.VoicePitch)
                player.painCD = CurTime() + SoundDuration(snd)
                player.lastPhr = snd
            end
        end
    end)]]

    self:AddSoundHookToClass(self.HOOK_TYPE.RELOAD, function(weapon)
        local player = weapon:GetOwner()
        if not IsValid(player) then return end

        local nearPlayers = ents.FindInSphere(player:GetPos(),300)
        for _, mate in ipairs(nearPlayers) do
            if (mate:IsPlayer() and mate ~= player and mate:Alive() and self:ValidatePlayer(mate))
                and (player:Alive() and not player.organism.otrub and self:ValidatePlayer(player) and wep.ShellEject ~= "ShotgunShellEject") then
                local sounds = self:GetSounds(player, "reload")

                local phrase = sounds[math.random(#sounds)]
                player:EmitSound(phrase,75,player.VoicePitch)
                player.phrCld = CurTime() + (SoundDuration(phrase) or 0)
                player.lastPhr = phrase
                return

            end
        end
    end)

    --[[
    self:AddSoundHookToClass(self.HOOK_TYPE.DEATH, function(player)
        local chr = hg.GetCurrentCharacter(player)
        if self:ValidatePlayer(player) then
            local sounds = self:GetSounds(player, "death")

            EmitSound(sounds[math.random(#sounds)],
                chr:GetPos(),
                chr
            )
        end
    end)]]
end

--[[ 
- Implementing this feature is entirely dependent on how the sound files are structured
- inside the content packs, and as such, I am not gonna bother with it until I've set
- up my own content pack of sounds that we use so I have a base line to work with
- and not have to cobble together novel solutions for each content pack.
-
- I also hate working with the current phrase system.

function CLASS_SOUNDS:On(player)
    
    
    if not table.IsEmpty(contextPhrases) then 
        self:ReplaceContextPhrases(function()
            local client = LocalPlayer()
            local class = client.PlayerClassName
            local subClass = client.subClass or "default"
            
            local organism = client.organism or {}
            local inPain = organism.pain > 60 ---@diagnostic disable-line:undefined-field

            local phraseID = self.uniqueID .. "_phrase"
            local sounds = self.sounds[subClass]
            local phrases = self.phrases[subClass]
            local contextPhrases = self.contextPhrases[subClass]

            if not lply:Alive() or organism.otrub or class ~= "combine" then
                return false
            end

            hg.radialOptions[#hg.radialOptions + 1] = {
                [1] = function(mouseClick)
                    if mouseClick == 1 or inPain then
                        self:PlayCharacterPhrase(player, inPain and sounds.pain[#sounds.pain] or phrases[math.random(#phrases)])
                    else
                        local tbl = {}
                        
                        tbl = self:RecursiveAssign(contextPhrases)

                        hg.CreateRadialMenu(tbl)
                    end
                end,
                [2] = organism.pain > 60 and (organism.pain <= 100 and "Yell in pain" or "Moan in pain") or "Do Phrase\nRMB - Menu"
            }
            
        end)
    end
    
end

function CLASS_SOUNDS:Off(player)
    
    if not table.IsEmpty(contextPhrases) then 
        self:RemoveContextPhrases()
    end
    
end
]]
