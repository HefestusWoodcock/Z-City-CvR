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
        if table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
        elseif table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
        end
    end
end

CLASS.CanUseDefaultPhrase = true

local models = {
    "",
}

local subclasses = {

    default = {},
    breacher = {},
    grenadier = {},
    sniper = {},
    medic = {}

}

function CLASS.On(self, data)
    if CLIENT then return end

    ApplyAppearance(self,nil,nil,nil,true)
    local appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    appearance.AAttachments = ""
    appearance.AColthes = ""

    local mdl_key = appearance.AModel
    if not rebel_models[mdl_key] then
        self:ChatPrint("zcity/appearance.json have invalid variables.. Setting random Appearance")
        appearance = hg.Appearance.GetRandomAppearance()
        mdl_key = appearance.AModel
    end

    self:SetPlayerColor(Color(13,101,5):ToVector())
    self:SetModel(rebel_models[mdl_key])
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")

    if not data.bNoEquipment then
        self:PlayerClassEvent("GiveEquipment", self.subClass)
    end


    if self.subClass == "medic" then
        local new_mdl = rebel_medic_models[self:GetModel()]
        if new_mdl then
            self:SetModel(new_mdl)
        end
    end


    self.subClass = nil

    if zb and zb.GiveRole then
        zb.GiveRole(self, "Rebel", Color(0, 173, 43))
    end

    self:SetBodygroup(10, 1)                  
    self:SetBodygroup(8, math.random(0,15))   
    self:SetBodygroup(9, math.random(0,9))    
    self:SetSkin(math.random(0,3))            


    self.CurAppearance = appearance
    
    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
            v:ClearEnemyMemory()
        elseif table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
            v:ClearEnemyMemory()
        end
    end
    
    local index = self:EntIndex()
    hook.Add( "OnEntityCreated", "rebel_relation_ship"..index, function( ent )
        if not IsValid(self) then hook.Remove("OnEntityCreated","rebel_relation_ship"..index) return end
        if ( ent:IsNPC() ) then
            if table.HasValue(rebels,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_LI, 0 )
            end

            if table.HasValue(combines,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_HT, 99 )
            end
        end
    end )
end