-- Credits to: https://steamcommunity.com/sharedfiles/filedetails/?id=3293939372

CreateConVar("hg_voice_proximity_dist_normal", 1500, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum distance for listener to still be able to hear the speaker.")
CreateConVar("hg_voice_proximity_dist_whisper", 200, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum distance for listener to still be able to hear the speaker whispering.")
CreateConVar("hg_voice_proxmity_muted_volume", 0.2, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How muffled the voice is behind a wall. (0-1)", 0, 1)
CreateConVar("hg_voice_proxmity_enabled", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enables/disables proximity chat.", 0, 1)

local maxDistNormal = GetConVar("hg_voice_proximity_dist_normal")
local maxDistWhisper = GetConVar("hg_voice_proximity_dist_whisper")
local muteVolume = GetConVar("hg_voice_proxmity_muted_volume")
local proxEnabled = GetConVar("hg_voice_proxmity_enabled")

local function UpdateVoiceDSP(listener, talker)
    if not IsValid(listener) or not IsValid(talker) or listener == talker then return end

    if not proxEnabled:GetBool() then
        talker:SetVoiceVolumeScale(1)
        return
    end

    net.Receive("VoiceWhisperBroadcast", function(len)
        local ply = net.ReadPlayer()
        local whisper = net.ReadBool()

        if ply == talker then 
            talker.VoiceWhisper = whisper
        end
    end)

    local ply = listener
    if IsValid(listener:GetObserverTarget()) then ply = listener:GetObserverTarget() end
    if IsValid(listener.fh_target_player) then ply = listener.fh_target_player end

    local distance = ply:GetPos():Distance(talker:GetPos())
    local maxDist =  talker.VoiceWhisper and maxDistWhisper:GetInt() or maxDistNormal:GetInt()

    if distance > maxDist then return end

    local trace = util.TraceLine({
        start = ply:EyePos(),
        endpos = talker:EyePos(),
        filter = function(ent)
            return ent ~= ply and ent ~= talker and not ent:IsPlayer() and not ent:IsNPC() and ent:GetClass() ~= "prop_physics"
        end
    })

    local volume = 1
    local mute = muteVolume:GetFloat()

    if distance < 200 then
        mute = math.min(muteVolume:GetFloat() * 2, 1)
    end

    if talker:WaterLevel() == 3 then
        mute = math.max(muteVolume:GetFloat() / 2, 0)
    end

    if (trace.Hit and (trace.MatType or 0) ~= 71) or talker:WaterLevel() == 3 then
        volume = (((distance / maxDist) * -1) + 1) * mute
    else
        volume = (((distance / maxDist) * -1) + 1)
    end

    talker:SetVoiceVolumeScale(volume)
end

hook.Add("Think", "ClientVoiceFilterThink", function()
    local listener = LocalPlayer()
    if not IsValid(listener) then return end

    for _, talker in ipairs(player.GetAll()) do
        if talker ~= listener and (talker:IsSpeaking() and not talker:IsMuted()) then
            UpdateVoiceDSP(listener, talker)
        end
    end
end)

hook.Add("PlayerEndVoice", "ClientVoiceFilterEnd", function(ply)
    ply:SetVoiceVolumeScale(1)
end)

--\\Whisper
	concommand.Add("hg_voice_whisper", function(ply)
		local whisper = ply.VoiceWhisper
		ply.VoiceWhisper = not whisper
		print(ply.VoiceWhisper)
		net.Start("VoiceWhisper")
			net.WriteBool(ply.VoiceWhisper)
		net.SendToServer()
	end)
--//