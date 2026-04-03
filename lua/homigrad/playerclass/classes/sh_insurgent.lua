local CLASS = player.RegClass("Insurgent")

local npc_combine = {
    "npc_combine_s",
    "npc_metropolice",
    "npc_helicopter",
    "npc_combinegunship",
    "npc_combine",
    "npc_stalker",
    "npc_hunter",
    "npc_strider",
    "npc_turret_floor",
	"npc_combine_camera",
    "npc_manhack",
    "npc_cscanner",
    "npc_clawscanner"
}

local npc_rebel = {
    "npc_barney",
    "npc_citizen",
    "npc_dog",
    "npc_eli",
    "npc_kleiner",
    "npc_magnusson",
    "npc_monk",
    "npc_mossman",
    "npc_odessa",
    "npc_rollermine_hacked",
    "npc_turret_floor_resistance",
    "npc_vortigaunt",
    "npc_alyx"
}

function CLASS.Off(self)
    if CLIENT then return end
    
    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(npc_combine, v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
        elseif table.HasValue(npc_rebel, v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
        end
    end
end

CLASS.CanUseDefaultPhrase = true

local models = {
    "models/chri/chechen/player/boevik_male_02_pm.mdl",
    "models/chri/chechen/player/boevik_male_04_pm.mdl",
    "models/chri/chechen/player/boevik_male_06_pm.mdl",
    "models/chri/chechen/player/boevik_male_07_pm.mdl",
    "models/chri/chechen/player/boevik_male_08_pm.mdl",
    "models/chri/chechen/player/boevik_male_09_pm.mdl"
}

local primary_weapons = {
    "weapon_akm",
    "weapon_ak74",
    "weapon_ak74u",
    "weapon_m16a2",
    "weapon_mp7",
    "weapon_sks"
}

local primary_attachments = {
    ["weapon_svd"] = function(ply, wep)
        if IsValid(wep) then
            hg.AddAttachmentForce(ply, wep, "optic11")
        end
    end,
}

local secondary_weapons = {
    "weapon_makarov",
    "weapon_tokarev",
    "weapon_pl15",
    "weapon_cz75",
    "weapon_hk_usp"
}

local helmet_list = {
    "helmet1",
    "helmet7"
}

local vest_list = {
    "vest5",
    "vest4",
    "vest1"
}

local subclasses = {

    default = {
        body_groups = "0602",
        armor = {
            head = helmet_list,
            body = vest_list
        },
        loadout = {
            {
                weapon = primary_weapons,
                ammo_mult = 5
            },
            {
                weapon = secondary_weapons,
                ammo_mult = 3
            },
            {
                weapon = "weapon_hg_hl2nade_tpik",
                count = 2
            }
        }
    },
    breacher = {
        body_groups = "0333",
        armor = {
            head = "ent_armor_helmet3",
            body = "ent_armor_vest28"
        },
        loadout = {
            {
                weapon = {
                    "weapon_spas12",
                    "weapon_m590a1",
                    "weapon_saiga12",
                    "weapon_remington870",
                    "weapon_ks23"
                },
                ammo_mult = 5
            },
            {
                weapon = secondary_weapons,
                ammo_mult = 3
            },
            {
                weapon = "weapon_hg_hl2nade_tpik",
                count = 2
            },
            {
                weapon = "weapon_hg_flashbang_tpik",
                count = 1
            },
            {
                weapon = "weapon_breachcharge",
                count = 1
            },
        }
    },
    grenadier = {
        body_groups = "0100",
        armor = {
            head = nil,
            body = vest_list
        },
        loadout = {
            {
                weapon = "weapon_hg_rpg",
                ammo_mult = 2
            },
            {
                weapon = {
                    "weapon_skorpion",
                    "weapon_uzi",
                    "weapon_mac11"
                },
                ammo_mult = 5
            },
            {
                weapon = "weapon_hg_hl2nade_tpik",
                count = 3
            },
            {
                weapon = "weapon_traitor_ied",
                count = 1
            },
            {
                weapon = "weapon_hg_slam",
                count = 1
            },
            {
                weapon = "weapon_claymore",
                count = 1
            }
        }
    },
    heavy = {
        armor = {
            head = nil,
            body = nil
        },
        body_groups = "0201",
        loadout = {
            {
                weapon = "weapon_pkm",
                ammo_mult = 2
            },
            {
                weapon = "weapon_makarov",
                ammo_mult = 1
            }
        }
    },
    sniper = {
        armor = {
            head = nil,
            body = nil
        },
        body_groups = "0534",
        loadout = {
            {
                weapon = "weapon_svd",
                ammo_mult = 4
            },
            {
                weapon = "weapon_makarov",
                ammo_mult = 1
            }
        }
    },
    medic = {
        armor = {
            head = helmet_list,
            body = vest_list
        },
        body_groups = "0604",
        loadout = {
            {
                weapon = {
                    "weapon_ak74u",
                    "weapon_skorpion",
                    "weapon_mp7"
                },
                ammo_mult = 3
            },
            {
                weapon = secondary_weapons,
                ammo_mult = 2
            },
            {
                weapon = "weapon_medkit_sh",
                count = 1
            },
            {
                weapon = "weapon_bandage_sh",
                count = 1
            },
            {
                weapon = "weapon_mannitol",
                count = 1
            },
            {
                weapon = "weapon_morphine",
                count = 1
            },
            {
                weapon = "weapon_naloxone",
                count = 1
            },
            {
                weapon = "weapon_painkillers",
                count = 1
            },
            {
                weapon = "weapon_tourniquet",
                count = 1
            },
            {
                weapon = "weapon_needle",
                count = 1
            },
            {
                weapon = "weapon_betablock",
                count = 1
            },
            {
                weapon = "weapon_adrenaline",
                count = 1
            }
        }
    }

}

function CLASS.On(self, data)
    if CLIENT then return end

    ApplyAppearance(self, nil, nil, nil, true)
    local appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    appearance.AAttachments = ""
    appearance.AColthes = ""

    self:SetPlayerColor(Color(13,101,5):ToVector())
    self:SetModel(table.Random(models))
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")

    local sub = self.subClass or "default"
    local cfg = subclasses[sub] or subclasses["default"]

    if cfg.body_groups then
        self:SetBodyGroups(cfg.body_groups)
    end

    if not data.bNoEquipment then
        self:PlayerClassEvent("GiveEquipment", self.subClass)
    end

    self.subClass = nil

    self.CurAppearance = appearance
    
    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(npc_rebel, v:GetClass()) then
            v:AddEntityRelationship( self, D_NU, 0 )
            v:AddEntityRelationship( self.bull, v:Disposition(self) )
            v:ClearEnemyMemory()
        elseif table.HasValue(npc_combine, v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
            v:AddEntityRelationship( self.bull, v:Disposition(self) )
            v:ClearEnemyMemory()
        end
    end
    
    local index = self:EntIndex()
    hook.Add( "OnEntityCreated", "rebel_relation_ship"..index, function( ent )
        if not IsValid(self) then hook.Remove("OnEntityCreated","rebel_relation_ship"..index) return end
        if ( ent:IsNPC() ) then
            if table.HasValue(npc_rebel, ent:GetClass()) then
                ent:AddEntityRelationship( self, D_NU, 0 )
            end
            if table.HasValue(npc_combine,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_HT, 99 )
            end
        end
    end )
end

local function giveSubClassLoadout(ply, subClass)
    local cfg = subclasses[subClass] or subclasses["default"]

    ply:StripWeapons()
    ply:Give("weapon_hands_sh")
    ply:Give("weapon_painkillers")
    ply:Give("weapon_bigbandage_sh")

    for _, item in ipairs(cfg.loadout or {}) do
        if type(item.weapon) == "table" then
            local randWep = table.Random(item.weapon)
            local wep = ply:Give(randWep)
            if isfunction(primary_attachments[wep:GetClass()]) then
                primary_attachments[wep:GetClass()](ply, wep)
            end
            if wep and item.ammo_mult then
                ply:GiveAmmo(wep:GetMaxClip1() * item.ammo_mult, wep:GetPrimaryAmmoType(), true)
            end
        else
            local wep = ply:Give(item.weapon)
            if isfunction(primary_attachments[wep:GetClass()]) then
                primary_attachments[wep:GetClass()](ply, wep)
            end
            if IsValid(wep) then
                --;; патрончики
                if item.ammo_type then
                    wep:ApplyAmmoChanges(item.ammo_type)
                end
                if item.ammo_mult then
                    ply:GiveAmmo(wep:GetMaxClip1() * item.ammo_mult, wep:GetPrimaryAmmoType(), true)
                end
                --;; пример кастомной какахи 
                if item.count then
                    wep.count = item.count
                end
                if item.extra_balls then
                    wep:SetNWInt("Balls", item.extra_balls)
                end
            end
        end
    end

    --;; Система случайного говна
    ply.armors = ply.armors or {}
    local vest = cfg.armor["body"]
    local helmet = cfg.armor["head"]

    if vest and type(vest) == "table" then vest = vest[math.random(#vest)] end
    if helmet and type(helmet) == "table" then helmet = helmet[math.random(#helmet)] end

    if vest then hg.AddArmor(ply, vest) end
    if helmet then hg.AddArmor(ply, helmet) end

    ply:SyncArmor()

    ply:Give("weapon_melee")
    ply:Give("weapon_walkie_talkie")
end

function CLASS.GiveEquipment(self, subClass)
    local ply = self
    local flashlight = self:Give("hg_flashlight")
    flashlight:Use(self)

    giveSubClassLoadout(ply, subClass or "default")
end

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

    hook.Add("HomigradDamage", "Rebels_painsounds", function(ply, dmgInfo, hitgroup, ent)
        if rebel_classes[ply.PlayerClassName] then
            ply.painCD = ply.painCD or 0
            if paintable[hitgroup] and (ply.painCD < CurTime()) and ply.organism and not ply.organism.otrub and ply:Alive() and not ply.organism.holdingbreath then 
                --paintable[hitgroup](ply,ent)
            end
        end
    end)

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

return CLASS