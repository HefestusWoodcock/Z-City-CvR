--[[
if SERVER then
    local paintable = {
        [HITGROUP_STOMACH] = function(ply,ent)
            local base_folder = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/"
            local snd = (ply.painCD and CurTime() < ply.painCD + 10 ) and base_folder.."pain0"..math.random(1,9)..".wav"
                         or base_folder.."mygut02.wav"
            ent:EmitSound(snd,80,ply.VoicePitch)
            ply.painCD = CurTime() + SoundDuration(snd)
            ply.lastPhr = snd
        end,
        [HITGROUP_CHEST] = function(ply,ent)
            local base_folder = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/"
            local snd = base_folder.."pain0"..math.random(1,9)..".wav"
            ent:EmitSound(snd,80,ply.VoicePitch)
            ply.painCD = CurTime() + SoundDuration(snd)
            ply.lastPhr = snd
        end,
        [HITGROUP_LEFTARM] = function(ply,ent)
            local base_folder = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/"
            local snd = (ply.painCD and CurTime() < ply.painCD + 10 ) and base_folder.."pain0"..math.random(1,9)..".wav"
                         or base_folder.."myarm0"..math.random(1,2)..".wav"
            ent:EmitSound(snd,80,ply.VoicePitch)
            ply.painCD = CurTime() + SoundDuration(snd)
            ply.lastPhr = snd
        end,
        [HITGROUP_RIGHTARM] = function(ply,ent)
            local base_folder = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/"
            local snd = (ply.painCD and CurTime() < ply.painCD + 10 ) and base_folder.."pain0"..math.random(1,9)..".wav"
                         or base_folder.."myarm0"..math.random(1,2)..".wav"
            ent:EmitSound(snd,80,ply.VoicePitch)
            ply.painCD = CurTime() + SoundDuration(snd)
            ply.lastPhr = snd
        end,
        [HITGROUP_RIGHTLEG] = function(ply,ent)
            local base_folder = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/"
            local snd = (ply.painCD and CurTime() < ply.painCD + 10 ) and base_folder.."pain0"..math.random(1,9)..".wav"
                         or base_folder.."myleg0"..math.random(1,2)..".wav"
            ent:EmitSound(snd,80,ply.VoicePitch)
            ply.painCD = CurTime() + SoundDuration(snd)
            ply.lastPhr = snd
        end,
        [HITGROUP_LEFTLEG] = function(ply,ent)
            local base_folder = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/"
            local snd = (ply.painCD and CurTime() < ply.painCD + 10 ) and base_folder.."pain0"..math.random(1,9)..".wav"
                         or base_folder.."myleg0"..math.random(1,2)..".wav"
            ent:EmitSound(snd,80,ply.VoicePitch)
            ply.painCD = CurTime() + SoundDuration(snd)
            ply.lastPhr = snd
        end
    }

    hook.Add("HGReloading", "Rebels_reloadalert", function(wep)
        if CLIENT then return end
        local ply = wep:GetOwner()
        if not IsValid(ply) then return end
        ply.ReloadSND_CD = ply.ReloadSND_CD or 0
        if ply.ReloadSND_CD > CurTime() then return end

        local nearby = ents.FindInSphere(ply:GetPos(), 300)
        for _, mate in ipairs(nearby) do
            if mate:IsPlayer() and mate ~= ply and mate:Alive() and rebel_classes[mate.PlayerClassName] then
                if ply:Alive() and not ply.organism.otrub and rebel_classes[ply.PlayerClassName] and wep.ShellEject ~= "ShotgunShellEject" then
                    local base_folder = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/"
                    local phrase = (math.random(1,2) == 2) and (base_folder.."coverwhilereload01.wav") or (base_folder.."coverwhilereload02.wav")
                    ply:EmitSound(phrase, 75, ply.VoicePitch)
                    ply.phrCld = CurTime() + (SoundDuration(phrase) or 0)
                    ply.lastPhr = phrase
                    ply.ReloadSND_CD = CurTime() + SoundDuration(phrase)*3
                    return
                end
            end
        end
    end)
end
]]