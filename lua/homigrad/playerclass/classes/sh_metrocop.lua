
local CLASS = player.RegClass("CivPro")

local callsigns = {
    "Defender", "Hero", "Jury", "Line", "Patrol", "Quick",
    "Roller", "Stick", "Tap", "Union", "Victor", "Xray",
    "Yellow", "Vice"
}


local primary_weapons = {
    "weapon_mp7",
    "weapon_ithaca37"
}

local primary_attachments = {
    ["weapon_mp7"] = function(ply, wep)
        if IsValid(wep) then
            hg.AddAttachmentForce(ply,wep,"holo1")
        end
    end,
    ["weapon_remington870"] = function(ply, wep)
        if IsValid(wep) then
            hg.AddAttachmentForce(ply, wep, "holo2")
        end
    end
}

local combine_subclasses = {
    default = {
        color = Color(0,140,155),
        models = "models/wststr/hlvr/metrocop/metrocop_update_pm.mdl",
        body_groups = "000010000",
        loadout = {
            {weapon = "weapon_painkillers"},
            {weapon = "weapon_bandage_sh"},
            {weapon = "weapon_tourniquet"},
            {
                weapon = "weapon_glock26",
                ammo_mult = 2
            }
        },
    },
    i3 = {
        color = Color(0,140,155),
        models = "models/wststr/hlvr/metrocop/metrocop_update_pm.mdl",
        body_groups = "000010000",
        loadout = {
            {weapon = "weapon_medkit_sh"},
            {weapon = "weapon_bigbandage_sh"},
            {weapon = "weapon_morphine"},
            {
                weapon = "weapon_fn45",
                ammo_mult = 2
            }
        },
    },
    i2 = {
        color = Color(0,140,155),
        models = "models/wststr/hlvr/metrocop/metrocop_update_pm.mdl",
        body_groups = "000010000",
        loadout = {
            {weapon = "weapon_car"},
            {weapon = "weapon_bigbandage_sh"},
            {weapon = "weapon_morphine"},
            {
                weapon = "weapon_hk_usp",
                ammo_mult = 2
            },
            {
                weapon = primary_weapons,
                ammo_mult = 2
            }
        },
    },
    i1 = {
        color = Color(0,140,155),
        models = "models/wststr/hlvr/metrocop/metrocop_update_pm.mdl",
        body_groups = "000010000",
        loadout = {
            {weapon = "weapon_salewa"},
            {weapon = "weapon_bigbandage_sh"},
            {weapon = "weapon_morphine"},
            {
                weapon = "weapon_hk_usp",
                ammo_mult = 2
            },
            {
                weapon = "weapon_coltlec",
                ammo_mult = 2
            }
        },
    }
}

local combines = {
    "npc_combine_s",
    "npc_strider",
    "npc_metropolice",
    "npc_hunter",
    "npc_rollermine",
    "npc_cscanner",
    "npc_combinegunship",
    "npc_combinedropship",
    "npc_clawscanner",
    "npc_manhack",
    "npc_combine_camera",
    "npc_turret_ceiling",
    "npc_turret_floor"
}

local rebels = {
    "npc_alyx",
    "npc_barney",
    "npc_citizen",
    "npc_eli",
    "npc_fisherman",
    "npc_kleiner",
    "npc_magnusson",
    "npc_mossman",
    "npc_odessa",
    "npc_rollermine_hacked",
    "npc_turret_floor_resistance",
    "npc_vortigaunt"
}

function CLASS.Off(self)
    if CLIENT then return end

    if eightbit and eightbit.EnableEffect and self.UserID then
        eightbit.EnableEffect(self:UserID(), 0)
    end

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
        end
    end

    self:SetNWString("PlayerRole", nil)
    self.organism.CantCheckPulse = nil

    hook.Remove("OnEntityCreated", "relation_shipdo" .. self:EntIndex())
end


CLASS.NoFreeze = true
CLASS.CanEmitRNDSound = false

local baseEquipment = {
    {weapon = "weapon_hands_sh"},
    {weapon = "weapon_hg_stunstick"},
    {weapon = "weapon_handcuffs"},
    {weapon = "weapon_handcuffs_key"},
    {weapon = "hg_flashlight"}
}

local function giveSubClassLoadout(ply, subclass)
    local config = combine_subclasses[subclass] or combine_subclasses["default"]
    ply:StripWeapons()
    ply:RemoveAllAmmo()
    
    for _, item in ipairs(baseEquipment) do
        local wep = ply:Give(item.weapon)
        if item.weapon == "hg_flashlight" then 
            wep:Use(ply)
        end
    end

    for _, item in ipairs(config.loadout or {}) do
        if type(item.weapon) == "table" then
            local randWep = item.weapon[math.random(#item.weapon)]
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
end

function CLASS.On(self, data)
    if CLIENT then return end

    if eightbit and eightbit.EnableEffect and self.UserID then
        eightbit.EnableEffect(self:UserID(), eightbit.EFF_PROOT) --!! placeholder
    end

    if IsValid(self.FakeRagdoll) then
        hg.FakeUp(self, nil, nil, true)
    end

    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local sub = self.subClass or "default"
    local cfg = combine_subclasses[sub] or combine_subclasses["default"]
    local useModel = istable(cfg.models) and cfg.models[math.random(#cfg.models)] or cfg.models
    self:SetModel(useModel)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")
    self:SetPlayerColor(cfg.color:ToVector())

    if cfg.body_groups then
        self:SetBodyGroups(cfg.body_groups)
    end

    self.organism.CantCheckPulse = true

    --;; Армор
    self.armors = {}
    self.armors["torso"] = "metrocop_armor"
    self.armors["head"] = "metrocop_helmet"
    self:SyncArmor()

    if not data.bNoEquipment then
        giveSubClassLoadout(self, sub)
    end

    self.subClass = nil
    self.organism.recoilmul = 0.85

    local callsign = sub ~= "default" and sub or "i4"
    callsign = callsign .. ":" .. table.Random(callsigns) .. "-" .. math.random(1,25)

    if zb.GiveRole then zb.GiveRole(self, "Officer", Color(89,230,255)) end
    self:SetNWString("PlayerName", callsign)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
            v:ClearEnemyMemory()
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
            v:ClearEnemyMemory()
        end
    end

    local index = self:EntIndex()
    hook.Add( "OnEntityCreated", "relation_shipdo" .. index, function( ent )
        if not IsValid(self) then hook.Remove("OnEntityCreated", "relation_shipdo" .. index) return end
        if ( ent:IsNPC() ) then
            --print(ent:GetClass())
            if table.HasValue(combines,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_LI, 0 )
            end

            if table.HasValue(rebels,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_HT, 99 )
            end
        end
    end )

    self.CurAppearance = appearance
end

function CLASS.Guilt(self, victim)
    if CLIENT then return end

    if victim:GetPlayerClass() == self:GetPlayerClass() then
        return 1
    end
end

function CLASS.PlayerDeath(self)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
            v:AddEntityRelationship( self.bull, v:Disposition(self) )
            v:ClearEnemyMemory()
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
            v:AddEntityRelationship( self.bull, v:Disposition(self) )
            v:ClearEnemyMemory()
        end
    end

    EmitSound( "npc/metropolice/die" .. math.random(1,4) .. ".wav", self:GetPos() )

    hook.Remove( "OnEntityCreated", "relation_shipdo" .. self:EntIndex())
end

local radio_on = {
    "voice_replacement/hla_grunt/vo/on1.wav",
    "voice_replacement/hla_grunt/vo/on2.wav",
    "voice_replacement/hla_grunt/vo/on3.wav",
    "voice_replacement/hla_grunt/vo/on4.wav",
    "voice_replacement/hla_grunt/vo/on5.wav"
}

local radio_off = {
    "voice_replacement/hla_grunt/vo/off1.wav",
    "voice_replacement/hla_grunt/vo/off2.wav",
    "voice_replacement/hla_grunt/vo/off3.wav",
    "voice_replacement/hla_grunt/vo/off4.wav",
    "voice_replacement/hla_grunt/vo/off5.wav",
    "voice_replacement/hla_grunt/vo/off6.wav",
    "voice_replacement/hla_grunt/vo/off7.wav"
}

local function RadioSoundOn(ent, pitch)
    ent:EmitSound(radio_on[math.random(1, #radio_on)], 70, pitch)
end

local function RadioSoundOff(ent, pitch)
    ent:EmitSound(radio_off[math.random(1, #radio_off)], 70, pitch)
end

if SERVER then
    local mtcop_phrases = {}
    local files,_ = file.Find("sound/npc/metropolice/vo/*.wav","GAME")
    for k,v in ipairs(files) do
        mtcop_phrases[k] = "npc/metropolice/vo/" .. v
    end

    hook.Add("HG_ReplacePhrase", "metropolice_phrase", function(ply, phrase, muffed, pitch)
        if IsValid(ply) and ply.PlayerClassName == "CivPro" then
            print(ply)
            print(ply.PlayerClassName)
            return ply, mtcop_phrases[math.random(#mtcop_phrases)], muffed, pitch
        end
    end)

    local function CanListen(output, input, isChat)
        if (not IsValid(output) or not IsValid(input)) then
            return
        end

        if (not output:Alive() or output.organism.otrub or not input:Alive() or input.organism.otrub) then
            return false
        end

        if (output.PlayerClassName == "CivPro" or output:GetNWString("PlayerRole") == "overwatch")
            and input.PlayerClassName == "CivPro" then
                return true
        end
    end

    hook.Add("CanListenOthers", "TAC-Radio CivPro", function(output, input, isChat, teamonly, text)
        if CanListen(output, input, isChat) then
            if isChat then
                RadioSoundOn(output, 100)
                if output == input then return end
                RadioSoundOn(input, 100)

                if input:GetPos():DistToSqr(output:GetPos()) < 600000 and not output.organism.otrub and not input.organism.otrub then
                    return true
                else
                    input:ChatPrint("TAC-" .. output:GetNWString("PlayerName") .. ": " .. text)
                    return false
                end
            else
                return true, false
            end
        end
    end)

    hook.Add("StartVoice", "TAC-Radio CivPro", function(output)
        for i, input in player.Iterator() do
            if CanListen(output, input, false) then
                if output == input then
                    RadioSoundOn(output, 100)
                    continue
                end

                RadioSoundOn(input, 100)
            end
        end
    end)

    hook.Add("EndVoice", "TAC-Radio OTA", function(output)
        for i, input in player.Iterator() do
            if CanListen(output, input, false) then
                if output == input then
                    RadioSoundOff(output, 100)
                    continue
                end

                RadioSoundOff(input, 100)
            end
        end
    end)
end

if CLIENT then
    local cmb_mat = Material("sprites/mat_jack_helmoverlay_r")
    hook.Add("PostDrawHUD","Metrocop_helmet",function()
        local lply = LocalPlayer()
        if lply:Alive() and lply.PlayerClassName == "Metrocop" then
            surface.SetDrawColor(150,190,190,255)
            surface.SetMaterial(cmb_mat)
            surface.DrawTexturedRectRotated(
                (ScrW() / 2) - 5,
                (ScrH() / 2) - 5,
                ScrW() + 10,
                ScrH() + 450,
                180
            )
        end
    end)
end

return CLASS
