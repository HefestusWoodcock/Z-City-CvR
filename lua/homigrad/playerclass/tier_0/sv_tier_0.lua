local PLAYER_CLASS = hg.player_class
local Player = FindMetaTable("Player")

---Player meta-method that sets a player class based on the given ID.
---@param classID? string The unique id string of a registered class.
---@param subClass? string A sub-class of the class.
---@param data? table Table of data to be passed over to the class set-up method.
function Player:SetPlayerClass(classID, subClass, data)
	classID = classID or "default"
	data = data or {}

	self:PlayerClassEvent("Off")
	local class = PLAYER_CLASS:GetClass(classID)
	subClass = class.subClasses[subClass] and subClass or "default"
	if class then 
		self.PlayerClassName = classID
		self.subClass = subClass
		self:PlayerClassEvent("On", data)
	end

	net.Start("SetupClass")
		net.WritePlayer(self)
		net.WriteString(classID)
		net.WriteString(subClass)
		net.WriteTable(data)
	net.Broadcast()
end


util.AddNetworkString("SetupClass")
---Syncs player classes on new spawn.
hook.Add("PlayerInitializeSpawn", "PlayerClass", function(plySend)
	for i, ply in player.Iterator() do
		if not ply:GetPlayerClass() then continue end
		print(ply:GetNWString("Class"))
		net.Start("SetupClass")
			net.WritePlayer(ply)
			net.WriteString(ply:GetNWString("Class"))
		net.Send(plySend)
	end
end)

hook.Add("PostPostPlayerDeath", "PlayerClass", function(ply, ragdoll)
	hook.Run("PlayerClassDeath")
	ply:PlayerClassEvent("PlayerDeath")
	ply:SetPlayerClass()
end)

hook.Add("Player Think", "ClassPlyThink", function(ply, time, dtime)
	ply:PlayerClassEvent("Think", player, time, dtime)
end)

COMMANDS.playerclass = {
	function(ply, args)

		local className = string.lower(args[1]) or nil

		if not ply:IsAdmin() then return end
		if #args == 1 then
			ply:SetPlayerClass(className)
			ply:ChatPrint(ply:Name())
		elseif #args == 3 then
			for i, ply2 in pairs(player.GetListByName(className)) do
				ply2:SetPlayerClass(args[2], args[3])
				ply:ChatPrint(ply2:Name())
			end
		else 
			ply:SetPlayerClass(className, args[2])
			ply:ChatPrint(ply:Name())
		end

	end,
	0
}