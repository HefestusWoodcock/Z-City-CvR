local maxVDistNormal = CreateConVar("hg_voice_proximity_dist_normal", 1500, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum distance for listener to still be able to hear the speaker.")
local maxVDistWhisper = CreateConVar("hg_voice_proximity_dist_whisper", 200, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum distance for listener to still be able to hear the speaker whispering.")
local maxCDistNormal = CreateConVar("hg_chat_dist_normal", 3000, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum distance for listener to still be able to hear the speaker.")
local maxCDistWhisper = CreateConVar("hg_chat_dist_whisper", 200, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum distance for listener to still be able to hear the speaker whispering.")

local COMMUNICATION = {}

--[[
local function CheckOverwatchProximity(speaker, listener, result)
	if (listener.PlayerClassName == "Combine" or listener.PlayerClassName == "CivPro")
		and (speaker.PlayerClassName ~= "Combine" or speaker.PlayerClassName ~= "CivPro")
		and result then
			return resultt
	end
	return false
end
]]

-- Function that modifies text based on physiological conditions (e.g.: braind damage).
function COMMUNICATION.PhysMod(ply, txt)
	if not SERVER then return end

	if !ply:Alive() or !ply.organism then return end
	local _starttxt = txt

	if ply.organism.pain > 80 then
		txt = table.Random(hg.sharp_pain)
	end

	local bJawBroken = ply.organism.jaw == 1 or ply.organism.jawdislocation
	local bUnintelligeble = ply.organism.brain > 0.05
	local bHasMassiveBrainDamage = ply.organism.brain > 0.14

	txt = utf8.force(txt)

	if bJawBroken then
		local iter = utf8.codes(txt)
		local len = 0
		local chars = {}
		local minus = utf8.codepoint("-", 1, 1)
		for i, code in iter do
			if math.random(3) == 1 then -- max dist 640
				code = minus
			end

			len = len + 1
			chars[len] = utf8.char(code)
		end
		txt = table.concat(chars)
	end

	if bUnintelligeble then
		local iter = utf8.codes(txt)
		local len = 0
		local chars = {}

		for i, code in iter do
			len = len + 1
			chars[len] = utf8.char(code)
		end

		for i, code in ipairs(chars) do
			if i > 1 and math.random(bHasMassiveBrainDamage and 2 or 3) == 1 then
				local old = chars[i]
				chars[i] = chars[i - 1]
				chars[i - 1] = old
			end

			if bHasMassiveBrainDamage and math.random(3) == 1 then
				chars[i] = math.random(1, 2) == 1 and "m" or "b"
			end
		end

		txt = table.concat(chars)

		if bHasMassiveBrainDamage and math.random(2) == 1 then txt = hg.utf8_reverse(utf8.codes(txt), utf8.len(txt)) end
	end

	if ply.organism.o2[1] < 15 or (ply.organism.brain > 0.15 and math.random(4) == 1) then return "..." end

	return txt
end

local function BlockOverwatch(talker, listener)
	if talker == listener then return end

	local listenerClass = listener.PlayerClassName
	if (listenerClass ~= "Combine" and listenerClass ~= "CivPro") 
		and talker:GetNWString("PlayerRole") == "overwatch" then
			return true
	end

	return
end

util.AddNetworkString("DisableVolumeProximity")
local function NoVolumeChange(talker, listener, result)
	local result = result and true or false
	net.Start("DisableVolumeProximity")
		net.WritePlayer(talker)
		net.WriteBool(result)
	net.Send(listener)
end

-- Check function that allows listening to speaker based on conditions.
function COMMUNICATION.Logic(output, input, isChat, teamonly, text)
	if not SERVER then return end

	if not IsValid(output) then return true, true end
	if not IsValid(input) then return false end

	if BlockOverwatch(output, input) then
		return false, false
	end

	local result, is3D = hook.Run("CanListenOthers", output, input, isChat, teamonly, text)
	-- output.isProxOverwatch = CheckOverwatchProximity(output, input, result)
	NoVolumeChange(output, input, result)
	if result ~= nil then 
		local speak = output:IsSpeaking()
		output.IsSpeak = speak

		if output.IsOldSpeak ~= output.IsSpeak then
			output.IsOldSpeak = speak
			if speak then hook.Run( "StartVoice", output, input ) else hook.Run( "EndVoice", output, input )  end
		end

		return result, is3D 
	end

	local maxDist = output.VoiceWhisper and maxVDistWhisper:GetInt() or maxVDistNormal:GetInt()
	if isChat then
		maxDist = output.ChatWhisper and maxCDistWhisper:GetInt() or maxCDistNormal:GetInt()
	end


	if output:Alive() and input:Alive() and not output.organism.otrub and not input.organism.otrub and output.organism.o2[1] >= 15 and not output.organism.holdingbreath and input:TestPVS( output ) then
		if input:GetPos():Distance(output:GetPos()) < maxDist and not teamonly then
			return true, true
		else
			return false
		end
	elseif not output:Alive() and not input:Alive() then
		return true
	else
		if not input:Alive() and output:Alive() then 
			if input:GetPos():Distance(output:GetPos()) < maxDist and input:TestPVS( output ) and not teamonly then
				return true, true
			else
				return false
			end
		end
		if not output:Alive() and input:Team() == 1002 and input:Alive() then return true end

		return false
	end

end

hg = hg or {}
hg.Communication = COMMUNICATION or {}

return COMMUNICATION