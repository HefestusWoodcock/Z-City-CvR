hg = hg or {}

CreateConVar("hg_voice_proximity_dist_normal", 1500, FCVAR_ARCHIVE, "Maximum distance for listener to still be able to hear the speaker.")
CreateConVar("hg_voice_proximity_dist_whisper", 200, FCVAR_ARCHIVE, "Maximum distance for listener to still be able to hear the speaker whispering.")
CreateConVar("hg_voice_proxmity_muted_volume", 0.2, FCVAR_ARCHIVE, "How muffled the voice is behind a wall. (0-1)", 0, 1)
CreateConVar("hg_voice_proxmity_enabled", 1, FCVAR_ARCHIVE, "Enables/disables proximity chat.", 0, 1)

local Comms = hg.Communication or {}
local proxEnabled = GetConVar("hg_voice_proxmity_enabled")

function VoiceLogic(output, input, isChat)
	if not SERVER then return end

	if not IsValid(output) then return true, true end
	if not IsValid(input) then return false end

	local result, is3D = hook.Run("CanListenOthers", output, input, isChat)
	-- output.isProxOverwatch = CheckOverwatchProximity(output, input, result)
	if result ~= nil then 
		local speak = output:IsSpeaking()
		output.IsSpeak = speak

		if output.IsOldSpeak ~= output.IsSpeak then
			output.IsOldSpeak = speak
			if speak then hook.Run( "StartVoice", output, input ) else hook.Run( "EndVoice", output, input )  end
		end

		return result, is3D 
	end

	local maxDist = output.VoiceWhisper and GetConVar("hg_voice_proximity_dist_normal"):GetInt() 
						or GetConVar("hg_voice_proximity_dist_whisper"):GetInt()

	if output:Alive() and input:Alive() 
		and not output.organism.otrub and not input.organism.otrub 
		and output.organism.o2[1] >= 15 and not output.organism.holdingbreath then
			if input:GetPos():Distance(output:GetPos()) < maxDist then
				return true, true
			else
				return false
			end
	else
		return false
	end

end

hook.Add("PlayerCanHearPlayersVoice", "Proximity", function(listener, talker)
	local result, is3D = Comms.Logic(talker, listener, false) -- Throws Error
	local proximityEnabled = proxEnabled:GetInt()

	if proximityEnabled == 0 then
		return true, false
	end

	local ply = listener
	if IsValid(listener:GetObserverTarget()) then ply = listener:GetObserverTarget() end
	if IsValid(listener.fh_target_player) then ply = listener.fh_target_player end

	return result, is3D
end)

--\\Whisper
	util.AddNetworkString("VoiceWhisper")
	util.AddNetworkString("VoiceWhisperBroadcast")
	net.Receive("VoiceWhisper", function(len, ply)
		ply.VoiceWhisper = net.ReadBool()
		
		net.Start("VoiceWhisperBroadcast")
			net.WritePlayer(ply)
			net.WriteBool(ply.VoiceWhisper)
		net.Broadcast()
	end)
--//