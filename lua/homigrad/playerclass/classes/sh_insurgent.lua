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