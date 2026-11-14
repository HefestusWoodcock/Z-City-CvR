---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class ZOMBIE : PLAYER_CLASS
local ZOMBIE = PLAYER_CLASS:New(
    "Zombie",
    "zombie",
    "Headcrab Zombies.")

ZOMBIE.subClasses = {
	default = true,
	fast = true,
	combine = true
}
ZOMBIE.moduleLoadOrder = {
    "class_sounds",
	"class_appearance"
}

CLASS_MODULE:GetRegistered("class_sounds")
			:GetRegistered("zombie_sounds")
            :Attach(ZOMBIE)
CLASS_MODULE:GetRegistered("class_appearance")
            :Attach(ZOMBIE)

ZOMBIE.CanUseDefaultPhrase = false
ZOMBIE.CanEmitRNDSound = false
ZOMBIE.CanUseGestures = false

function ZOMBIE:Init()
	self:Super("Init")

	hook.Add("HG_MovementCalc_2", "ZombSpeed", function(mul, ply, cmd, mv)
		if IsValid(ply) and ply.PlayerClassName == "zombie" then
			mul[1] = ply.subClass == "fast" and 0.8 or 0.6
			if ply:IsSprinting() then
				mul[1] = ply.subClass == "fast" and 1.4 or 1.2
			end
			local speedGain = ply.subClass == "fast" and 140 or 70
			if ply.SpeedGainMul ~= speedGain then
				ply.SpeedGainMul = speedGain
			end
		end
	end)

	hook.Add("UpdateAnimation", "ZombAnimRate", function(ply, vel, maxSeqGroundSpeed)
		if ply.PlayerClassName == "zombie" then
			local isAmputated = ply:IsBerserk() and ply.organism and (ply.organism.llegamputated or ply.organism.rlegamputated)
			if not IsValid(ply) or not ply:Alive() or isAmputated then return end

			if vel:LengthSqr() >= 77000 and vel:LengthSqr() < 110000 then
				ply:SetPlaybackRate(1.0)
				return ply, vel, maxSeqGroundSpeed
			end

			if vel:LengthSqr() >= 17000 then
				ply:SetPlaybackRate(1.2)
				return ply, vel, maxSeqGroundSpeed
			end

			if not ply:OnGround() then
				ply:SetPlaybackRate(0.8)
				return ply, vel, maxSeqGroundSpeed
			end
		end
	end)

	--// Zombie animations
	hook.Add("CalcMainActivity", "ZombAnims", function(ply, vel)
		if ply.PlayerClassName == "zombie" then
			local subClass = ply.subClass
			local subClassAnims = self.configs.animations[subClass] or self.configs.animations["default"]
			local anim = subClassAnims["walk"] or subClassAnims["walk"]
			if vel:LengthSqr() <= 0 then
				anim = subClassAnims["idle"] or subClassAnims["idle"]
			end
			if vel:LengthSqr() >= 17000 then 
				anim = subClassAnims["run"] or subClassAnims["run"]
			end
			if ply:IsFlagSet(FL_ANIMDUCKING) then
				anim = subClassAnims["crouch"] or subClassAnims["crouch"]
			end
			if not ply:IsOnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
				if vel:Length2DSqr() >= 17000 then
					anim = subClassAnims["leap"] or subClassAnims["leap"]
				else
					anim = subClassAnims["jump"] or subClassAnims["jump"]
				end
			end

			return anim, -1
		end
	end)
end


function ZOMBIE:On(player, data)
	
	if SERVER then
		player:SetNWString("PlayerName", "Zombie")

		--\\ Startup organism effects
		if IsValid(player.organism) then
			player.organism.temperature = 41
			player.organism.brain = 0.05
			player.organism.disorientation = 2
			player.organism.otrub = false
			player.organism.needotrub = false
			player.organism.painadd = -10
		end

		--\\ Remove armor
		local armors = player:GetNetVar("Armor",{})
		if armors["head"] and !hg.armor["head"][armors["head"]].nodrop then
			hg.DropArmorForce(player, armors["head"])
		end

		if armors["face"] and !hg.armor["face"][armors["face"]].nodrop then
			hg.DropArmorForce(player, armors["face"])
		end

		--\\ Give hands if we don't have it
		if player:HasWeapon("weapon_hands_sh") then
			player:SelectWeapon("weapon_hands_sh")
		else
			local hands = player:Give("weapon_hands_sh")
			player:SelectWeapon("weapon_hands_sh")
		end
	end

	self:Super("On", player, data)
end

function ZOMBIE:Off(player)
	
	if SERVER then 
		if IsValid(player.organism) then
			player.organism.brain = 0
			player.organism.disorientation = 0
			hg.organism.Clear(player.organism)
		end
	end

	self:Super("Off", player)
end

local function RenewZombieOrganism(org) 
	org.stamina["max"] = 200
	org.stamina["range"] = 200

	if org.otrub then
		org.consciousness = 1
		org.adrenalineAdd = 4
		org.analgesia = 0.4
		org.painadd = -5
	end

	if org.pain >= 30 then
		org.consciousness = 1
		org.adrenalineAdd = 1
		org.painadd = -15
	end

	org.pulse = 70
	org.o2["curregen"] = 2

	if org.brain >= 0.1 then
		org.brain = 0.05
	end

	if org.consciousness <= 0.3 then
		org.consciousness = 1
		org.needotrub = false
	end

	org.jawdislocation = false
	org.llegdislocation = false
	org.rlegdislocation = false
	org.rarmdislocation = false
end

---@param player Player
function ZOMBIE:Think(player)
    if CLIENT then return end

	--\\ Remove armor
	local armors = player:GetNetVar("Armor",{})
	if armors["head"] and !hg.armor["head"][armors["head"]].nodrop then
		hg.DropArmorForce(player, armors["head"])
	end

	if armors["face"] and !hg.armor["face"][armors["face"]].nodrop then
		hg.DropArmorForce(player, armors["face"])
	end

	-- Only hands can be an active item.
	local wep = player:GetActiveWeapon()
	if IsValid(wep) and wep ~= NULL and wep:GetClass() ~= "weapon_hands_sh" then
		if player:HasWeapon("weapon_hands_sh") then
			player:SelectWeapon("weapon_hands_sh")
		else
			local hands = player:Give("weapon_hands_sh")
			player:SelectWeapon("weapon_hands_sh")
		end
	end

	local org = player.organism
	RenewZombieOrganism(org)
end

-- Zombie Hooks
-- Some of the boiler plate down here should probably be moved to somewhere else.
hook.Add("HG_CanThoughts", "ZombCantDumat", function(ply)
	if ply.PlayerClassName == "zombie" then
		return false
	end
end)

-- Can't pickup weapons or use doors.
hook.Add("PlayerCanPickupWeapon", "ZombCantPickup", function(ply, ent)
	if IsValid(ply) and ply.PlayerClassName == "zombie" and ent:GetClass() ~= "weapon_hands_sh" then
		return false
	end
end)

hook.Add("PlayerUse", "ZombCantPickup", function(ply, ent)
	if IsValid(ply) and ply.PlayerClassName == "zombie" and ent:GetClass() ~= "func_button" then
		return false
	end
end)

--// Player speed & animation speed stuff


if SERVER then
	--[[hook.Add("OnHeadExplode", "ZombAmputate", function(ply, rag)
		print(ply, rag)
		if ply.PlayerClassName == "zombie" then
			rag:SetBodygroup(1, 0)
		end
	end)]]

	--// Zombies can't loot anyone
	hook.Add("ZB_CanLootInventory", "ZombCanLoot", function(ply, ent, canloot)
		if ply.PlayerClassName == "zombie" then
			return ply, ent, false
		end
	end)

	--// Zombies can't speak
	hook.Add("HG_PlayerCanHearPlayersVoice", "ZombVoice", function(listener, speaker)
		if speaker.PlayerClassName == "zombie" then
			return false, false
		end
	end)
end

hook.Add("PlayerCanLegAttack", "ZombKick", function(ply)
	if ply.PlayerClassName == "zombie" then
		return false
	end
end)

--// Zombie can't drive vehicles
hook.Add("CanPlayerEnterVehicle", "ZombVehicle", function(ply, ent)
	if ply.PlayerClassName == "zombie" then
		return false
	end
end)

---@warning This is a leaf class, and as such, no new object can be instantiated.
ZOMBIE.new = function()
    error(string.format("The class object %s is a leaf class.", self.className))
end