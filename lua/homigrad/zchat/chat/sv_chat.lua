local hg_furcity = ConVarExists("hg_furcity") and GetConVar("hg_furcity") or CreateConVar("hg_furcity", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_LUA_SERVER), "Toggle phrase furryfier :3", 0, 1)

CreateConVar("hg_chat_dist_normal", 3000, FCVAR_ARCHIVE, "Maximum distance for listener to still be able to hear the speaker.")
CreateConVar("hg_chat_dist_whisper", 200, FCVAR_ARCHIVE, "Maximum distance for listener to still be able to hear the speaker whispering.")


hg = hg or {}
local Comms = hg.Communication or {}

hook.Add("PlayerCanSeePlayersChat", "RealiticChar", function(text, teamOnly, listener, speaker)
	if not IsValid(speaker) then return end
	local result = Comms.Logic(speaker, listener, true, false, text)

	if not IsValid(speaker) then speaker = Entity(0) end

	local Hook = hook.Run("HG_PlayerCanSeePlayersChat", listener, speaker )
	if Hook then
		return Hook
	end

	return result
end)

hook.Add("HG_PlayerSay", "huy", function(ply, txt)
	local text = txt[1]

	txt[1] = Comms.PhysMod(ply, text)
end)

hook.Add("HG_PlayerSay", "furrifyPhraseOwO", function(ply, txt)
	local text = txt[1]
	
	if hg_furcity:GetBool() or ply.PlayerClassName == "furry" then
		text = hg.FurrifyPhrase(text)
	end

	txt[1] = text
end)

--\\Whisper
    util.AddNetworkString("ChatWhisper")
    net.Receive("ChatWhisper", function(len, ply)
		ply.ChatWhisper = net.ReadBool()
	end)
--//