---@type PLAYER_CLASS
local PLAYER_CLASS = hg.player_class
---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_SPAWN : CLASS_MODULE
---@field spawns table<string, Entity[]>
local CLASS_SPAWN
    = CLASS_MODULE:New(
        "Class Spawn", 
        "class_spawn", 
        "A module used to crate spawn entities for class-specific spawn locations.")
CLASS_SPAWN.__index = CLASS_SPAWN

CLASS_SPAWN.spawns = {}

function CLASS_SPAWN:Attach(classInstance)
    local uniqueID = CLASS_SPAWN.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end

function CLASS_SPAWN:Init()
    hook.Add("PlayerSelectSpawn", "ClassSpawn", function(ply)
        local class = ply:GetPlayerClass()
        local attached = class:GetModule(self.uniqueID)
        if not attached then return end

        local spawns = {}
        for _, e in ipairs(self.spawns[class.uniqueID]) do
            local tr = util.TraceHull({
                start = e:GetPos(),
                endpos = e:GetPos(),
                maxs = Vector(16, 16, 72),
                mins = Vector(-16, -16, 0),
                filter = e
            })
            if not tr.Hit then
                table.insert(spawns, e)
            end
        end
        if #spawns > 0 then return spawns[math.random(1, #spawns)] end
    end)
end

if SERVER then 

    ---Creates a new `class_spawn` entity on the position given. 
    ---@param classID string
    ---@param pos Vector
    ---@param angle Angle
    function CLASS_SPAWN:CreateClassSpawnEnt(classID, pos, angle)
        local spawn = ents.Create("ent_class_spawn")

        spawn:SetPos(pos)
        spawn:SetAngles(angle)
        spawn:Spawn()

        classSpawns = self.spawns[classID] or {}
        if table.IsEmpty(classSpawns) then 
            self.spawns[classID] = classSpawns
        end
        table.insert(classSpawns, spawn)
    end

    COMMANDS.setspawnpoint = {
        function(ply, args)
            if not ply:IsAdmin() then return end

            local classID = string.lower(args[1])
            local class = PLAYER_CLASS:GetClass(classID)

            if not class then return end
            if not class:GetModule(CLASS_SPAWN.uniqueID) then
                ply:ChatPrint("Cannot set a spawn point for this class.")
                return
            end

            CLASS_SPAWN:CreateClassSpawnEnt(
                classID, 
                ply:GetPos() + Vector(0, 0, 1), 
                Angle(0, ply:EyeAngles().y, 0))
        end,
        0
    }

end

function CLASS_SPAWN:New(moduleName, uniqueID, description)
    error(string.format("The module %s is a leaf class.", self.moduleName))
end