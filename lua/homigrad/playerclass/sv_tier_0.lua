local classList = player.classList
local Player = FindMetaTable("Player")
function Player:SetPlayerClass(value, subclass, data)
	data = data or {}

	value = value or "none"
	subclass = subclass or "default"
	local old = self.PlayerClassName
	self.PlayerClassNameOld = old
	old = classList[old]
	if old and old.Off then old.Off(self) end
	self.PlayerClassName = value
	self.subClass = subclass
	self:PlayerClassEvent("On", data) -- WHO WRITE THIS SHIT
	net.Start("setupclass")
		net.WriteEntity(self)
		net.WriteString(value)
		net.WriteString(self.PlayerClassNameOld or "")
		net.WriteString(subclass)
		net.WriteTable(data)
	net.Broadcast()
	--if self:Alive() then
	--	hg.FakeUp(self, true, true)
	--end
end

function Player:GiveSwep(list, mulClip1) -- улучшенный tdm.GiveSwep
	if not list then return end
	local wep = self:Give(type(list) == "table" and list[math.random(#list)] or list)
	mulClip1 = mulClip1 or 3
	if IsValid(wep) then
		wep:SetClip1(wep:GetMaxClip1())
		self:GiveAmmo(wep:GetMaxClip1() * mulClip1, wep:GetPrimaryAmmoType())
	end
end

util.AddNetworkString("setupclass")
hook.Add("PlayerInitializeSpawn", "PlayerClass", function(plySend)
	for i, ply in player.Iterator() do
		if not ply:GetPlayerClass() then continue end
		net.Start("setupclass")
			net.WriteEntity(ply)
			net.WriteString(ply:GetNWString("Class"))
			net.WriteString(ply:GetNWString("ClassOld"))
		net.Send(plySend)
	end
end)

hook.Add("PostPostPlayerDeath", "PlayerClass", function(ply, ragdoll)
	ply:PlayerClassEvent("PlayerDeath")
	ply:SetPlayerClass()
end)

hook.Add("Player Think", "ClassPlyThink", function(ply, time, dtime)
	ply:PlayerClassEvent("Think", time, dtime)
end)

COMMANDS.playerclass = {
	function(ply, args)

		if not ply:IsAdmin() then return end
		if #args == 1 then
			ply:SetPlayerClass(args[1])
			ply:ChatPrint(ply:Name())
		elseif #args == 3 then
			for i, ply2 in pairs(player.GetListByName(args[1])) do
				ply2:SetPlayerClass(args[1], args[3])
				ply:ChatPrint(ply2:Name())
			end
		else 
			ply:SetPlayerClass(args[1], args[2])
			ply:ChatPrint(ply:Name())
		end

	end,
	0
}