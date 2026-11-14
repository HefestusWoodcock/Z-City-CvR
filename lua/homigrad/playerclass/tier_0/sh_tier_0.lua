local PLAYER_CLASS = hg.player_class
local PlayerMeta = FindMetaTable("Player")

---Returns the player class instance assigned to a player.
---@return PLAYER_CLASS
function PlayerMeta:GetPlayerClass()
	local classID = self.PlayerClassName
	if not classID then return end

	return PLAYER_CLASS:GetClass(classID)
end

---Runs a method of the player class instance that is assigned to a player.
---@param methodName string Identifier of the method stored on the class instance.
---@param ...? any Any additional arguments to be supplied.
---@return function func
function PlayerMeta:PlayerClassEvent(methodName, ...) --haha
	--if name == "Think" then return end
	local class = self:GetPlayerClass()
	local func = class and class[methodName]
	--[[
	if not func then 
		for _, module in pairs(class.modules) do
			func = module[methodName]
			if func then 
				class = module
			end
		end
	end]]

	if func then
		return func(class, self, ...)
	end
end

---@deprecated Not used anywhere. Don't even understand how it's supposed to be used.
function player.EventPoint(pos, name, radius, ...)
	for i, ply in player.Iterator() do
		if ply:GetPos():Distance(pos) > radius then continue end
		ply:PlayerClassEvent("EventPoint", name, pos, radius, ...)
	end
end

---@deprecated Not used anywhere. Don't even understand how it's supposed to be used.
function player.Event(ply, name, ...)
	ply:PlayerClassEvent("Event", name, ...)
end

if SERVER then return end
net.Receive("SetupClass", function()
	local ply = net.ReadPlayer()
	if not IsValid(ply) then
		return
	end
	local classID = net.ReadString()
	local class = PLAYER_CLASS:GetClass(classID)
	if not class then return end

	local subClass = net.ReadString()
	local data = net.ReadTable()
	
	ply.subClass = subClass
	if LocalPlayer() ~= ply then
		ply.PlayerClassName = classID
		return
	end

	ply:PlayerClassEvent("Off")
	ply.PlayerClassName = classID
	ply:PlayerClassEvent("On", data)
end)

---@deprecated Doesn't seem to do anything aside from being related to another thing called PluvTown.
hook.Add("PostDrawAppearance", "PlayerClass", function(ent, ply) end)

if CLIENT then
	hook.Add("Player Think", "ClassPlyThink", function(ply, time, dtime)
		ply:PlayerClassEvent("Think", time, dtime)
	end)
end

--hook.Add("HGReloading", "PlayerClass", function(wep) wep:GetOwner():PlayerClassEvent("HGReloading", wep) end)
--hook.Add("PlayerFootstep", "PlayerClass", function(ply, pos, foot, sound, volume, rf) ply:PlayerClassEvent("PlayerFootstep", ply, pos, foot, sound, volume, rf) end)