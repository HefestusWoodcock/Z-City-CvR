---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_SQUADS : CLASS_MODULE
---@field activeSquads table<string, Squad>
---@field defaultSize number
---@field hasLeader boolean
---@field uniqueName boolean
---@field callSigns string[]
---@field usedCallSigns table<string, boolean>
---@field squadsSync boolean Used to determine if squads are synced accross realms.
---@field callSignSync boolean Used to determine if call signs are synced accross realms.
local CLASS_SQUADS = CLASS_MODULE:New(
        "Class Squads", 
        "class_squads", 
        "A module used to create player squads of the same class.")
CLASS_SQUADS.__index = CLASS_SQUADS

CLASS_SQUADS.activeSquads = {}

CLASS_SQUADS.defaultSize = 5
CLASS_SQUADS.hasLeader = true
CLASS_SQUADS.uniqueName = true

CLASS_SQUADS.callSigns = {}
CLASS_SQUADS.usedCallSigns = {}

---@class Squad
---@field callSign string
---@field leader? Player
---@field members Player[]
---@warning Do not call squad structure methods outside of module,
---as there is no internal validation.
CLASS_SQUADS.structure = {
    leader = nil,
    members = {},
    AddMember = function(self, player)
        table.insert(self.members, player)
        return player
    end,
    RemoveMember = function(self, player)
        local player = table.RemoveByValue(self.members, player)
        return player
    end,
    MakeLeader = function(self, player)
        self.leader = player
        return player
    end,
    RemoveLeader = function(self)
        local player = self.leader
        self.leader = nil
        return player
    end
}
CLASS_SQUADS.structure.__index = CLASS_SQUADS.structure

function CLASS_SQUADS:Attach(classInstance)
    local uniqueID = CLASS_SQUADS.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end

function CLASS_SQUADS:Init()
    if SERVER then

        util.AddNetworkString("SyncSquads_" .. self.uniqueID)
        net.Receive("SyncSquads_" .. self.uniqueID, function(len, ply)
            local squads = self:GetAllSquads()
        
            local netstreamID = "SyncSquads_" .. self.uniqueID
            netstream.Start(
                ply, 
                netstreamID, 
                squads)
        end)

        util.AddNetworkString("ClearSquads_" .. self.uniqueID)
        net.Receive("ClearSquads_" .. self.uniqueID, function(len, ply)
            local netstreamID = "ClearSquads_" .. self.uniqueID
            netstream.Start(ply, netstreamID)
        end)
        
    else
        
        netstream.Hook("SyncSquads_" .. self.uniqueID, function(squads)
            self:ValidatePlayer(LocalPlayer())
            for callSign, squad in pairs(squads) do 
                squad = setmetatable(squad, self.structure)
                self.activeSquads[callSign] = squad
                self.usedCallSigns[callSign] = true
            end
        end)

        netstream.Hook("ClearSquads_" .. self.uniqueID, function(squads)
            self.activeSquads = {}
            self.usedCallSigns = {}
        end)

        netstream.Hook("CreateSquad_" .. self.uniqueID, function(callSign, squad)
            self:ValidatePlayer(LocalPlayer())
            squad = setmetatable(squad, self.structure)
            self.activeSquads[callSign] = squad
            self.usedCallSigns[callSign] = true
        end)

        netstream.Hook("DeleteSquad_" .. self.uniqueID, function(callSign)
            self:ValidatePlayer(LocalPlayer())
            self.activeSquads[callSign] = nil
            self.usedCallSigns = nil
        end)

        netstream.Hook("AssignSquad_" .. self.uniqueID, function(callSign, player)
            local squad = self:GetSquad(callSign)
            player.squad = callSign

            squad:AddMember(player)
        end)

        netstream.Hook("DeassignSquad_" .. self.uniqueID, function(callSign, player)
            local squad = self:GetSquad(callSign)

            player.squad = nil
            squad:RemoveMember(player)
        end)

        netstream.Hook("UpdateSquadLead_" .. self.uniqueID, function(callSign, player)
            local squad = self:GetSquad(callSign)
            
            squad:MakeLeader(player)
        end)

        netstream.Hook("RemoveSquadLead_" .. self.uniqueID, function(callSign, player)
            local squad = self:GetSquad(callSign)
            
            squad:RemoveLeader()
        end)

    end
end

function CLASS_SQUADS:On(player, data)
    if CLIENT then

        net.Start("SyncSquads_" .. self.uniqueID)
        net.SendToServer()

    end

    local instance = self
    ---@return string? callSign
    ---@return Squad? squad
    player.GetSquad = function(self)
        local callSign, squad = instance:GetPlayerSquad(self)
        return callSign, squad
    end
    ---@return Player leader
    player.GetLeader = function(self)
        local callSign, squad = self:GetSquad()
        return squad.leader or nil
    end
    ---@return boolean
    player.IsLeader = function(self)
        local leader = self:GetLeader()
        return self == leader
    end

end

function CLASS_SQUADS:Off(player)
    player.GetSquad = nil
    player.GetLeader = nil
    player.IsLeader = nil

    if CLIENT then

        net.Start("ClearSquads_" .. self.uniqueID)
        net.SendToServer()

    end
end

---Returns the call signs of all active squads.
---@return string[] callSigns
function CLASS_SQUADS:GetAllCallSigns()
    local callSigns = table.GetKeys(self.activeSquads)

    return callSigns
end

---Returns the found squad, or throws an error if not found.
---@param callSign string The call sign of the squad being requested.
---@return Squad squad The found squad object.
function CLASS_SQUADS:GetSquad(callSign)
    local squad = self.activeSquads[callSign]

    if not squad then
        error(string.format("Squad %s doesn't exist", callSign))
    end

    return squad
end

---Returns all active squads.
---@return table<string, Squad> squads
function CLASS_SQUADS:GetAllSquads()
    local squads = table.Copy(self.activeSquads)

    return squads
end

---Returns the squad that a player belongs to, or `nil`.
---@see `CLASS_SQUADS:GetSquad(callSign)` - Uses this method internally.
---@param player Player
---@return string? callSign
---@return Squad? squad
function CLASS_SQUADS:GetPlayerSquad(player)
    local callSign = player.squad
    if not callSign then return end
    local squad = self:GetSquad(callSign)

    return callSign, squad
end

---Finds the next open valid squad for the player.
---@param player Player
---@return string? callSign
---@return Squad? squad
function CLASS_SQUADS:GetOpenSquad(player) 
    for callSign, squad in pairs(self.activeSquads) do 
        if pcall(self.ValidateSquadMember, self, player, squad) then 
            return callSign, squad
        end
    end
    return nil, nil
end

---Generates a random call sign based on stored call signs.
---@warning If you run out of call signs, this method will cause an infinite loop.
---@return string callSign A unique call sign string.
function CLASS_SQUADS:GenerateCallSign()
    local callSign = nil

    repeat
        local tag = self.callSigns[math.random(#self.callSigns)]
        local candidateCallSign = tag .. "-0" .. math.random(9)

        if not self.usedCallSigns[candidateCallSign] then
            self.usedCallSigns[candidateCallSign] = true
            callSign = candidateCallSign
        end

    until callSign ~= nil
    
    return callSign
end

if SERVER then 

    ---Creates a new squad and syncs it on both realms.
    ---@return string callSign Unique, case-sensitive call sign key of the squad object.
    ---@return Squad squad The newly created squad object.
    function CLASS_SQUADS:CreateNewSquad()
        local callSign = self:GenerateCallSign()
        local squad = setmetatable({}, self.structure)

        self.activeSquads[callSign] = squad

        local netstreamID = "CreateSquad_" .. self.uniqueID
        netstream.Start(
            nil, 
            netstreamID, 
            callSign, 
            squad)

        return callSign, squad
    end

    ---Deletes the squad object of the given callsign and syncs
    ---changes across the realms.
    ---
    ---Will also do cascade removal of all assigned members to that squad.
    ---@param callSign string Unique, case-sensitive call sign key.
    function CLASS_SQUADS:DeleteSquad(callSign)
        local squad = self:GetSquad(callSign)

        self.activeSquads[callSign] = nil
        self.usedCallSigns[callSign] = nil

        if #squad.members > 0 then 
            for _, member in ipairs(squad.members) do 
                self:DeassignPlayerFromSquad(member)
            end
        end
        
        local netstreamID = "DeleteSquad_" .. self.uniqueID
        netstream.Start(nil, netstreamID, callSign)
    end

    ---Internal function for unique name/tagline validation.
    ---@param members Player[] Sequential table of members of a squad.
    ---@param player Player Player entity that will be compared.
    ---@return boolean bool Will return either true or false, if `SQUADS.uniqueTag`
    ---is true, and the passed player's name matches another member's name.
    local function IsUniqueTag(player, members)
        for _, member in ipairs(members) do 
            if member:GetNWString("PlayerName") == player:GetNWString("PlayerName") then 
                return false
            end
        end
        return true
    end

    ---Makes sure that a squad is valid for a new member to join into.
    ---@warning Will throw an error otherwise.
    ---@param player Player
    ---@param squad Squad
    ---@return true
    function CLASS_SQUADS:ValidateSquadMember(player, squad) 
        if not squad then error("Squad doesn't exist.") end
        if self.defaultSize <= #squad.members then 
            error("Adding exceeds squad size.") 
        end
        if self.uniqueTag and not IsUniqueTag(player, squad.members) then 
            error("Another member has this tagline.")
        end
        return true
    end

    ---Adds a player to a squad based on:
    ---1. The given callsign;
    ---2. To a random, open one;
    ---@warning Will throw an error if either fails.
    ---@param player Player
    ---@param callSign? string
    ---@return true
    function CLASS_SQUADS:AddPlayerToSquad(player, callSign)
        local squad
        if callSign then 
            squad = self:GetSquad(callSign)
            self:ValidateSquadMember(player, squad)
        else 
            callSign, squad = self:GetOpenSquad(player)
            if not callSign then 
                error(string.format(
                    "There are no open squads in %s.",
                    self.moduleName))
            end
        end

        player.squad = callSign
        squad:AddMember(player)

        local netstreamID = "AssignSquad_" .. self.uniqueID
        netstream.Start(
            squad.members, 
            netstreamID, 
            callSign,
            player)

        return true
    end

    ---Removes a player from their assigned squad.
    ---@param player Player
    ---@return true | false # Returns false if the player isn't in a squad.
    function CLASS_SQUADS:DeassignPlayerFromSquad(player)
        local callSign, squad = self:GetPlayerSquad(player)
        if not squad then return false end

        if player == squad.leader then 
            self:RemoveSquadLead(player)
        end

        local netstreamID = "DeassignSquad_" .. self.uniqueID
        netstream.Start(
            squad.members, 
            netstreamID, 
            callSign,
            player)

        player.squad = nil
        squad:RemoveMember(player)

        return true
    end

    ---Make a player the leader of their assigned squad.
    ---
    ---Throws an error if:
    ---1. The squad module cannot have leaders.
    ---2. The player is not in a squad.
    ---@param player Player
    ---@return true
    function CLASS_SQUADS:MakeSquadLead(player)
        if not self.hasLeader then 
            error(string.format("%s cannot have leaders.", self.moduleName)) 
        end

        local callSign, squad = self:GetPlayerSquad(player)
        if not squad then
            error(string.format(
                    "%s is not in a squad.", 
                    player:GetNWString("PlayerName")))
        end

        squad:MakeLeader(player)

        local netstreamID = "UpdateSquadLead_" .. self.uniqueID
        netstream.Start(
            squad.members, 
            netstreamID,
            callSign,
            player)

        return true
    end

    ---Remove the leader from a player's assigned squad.
    ---
    ---Throws an error if:
    ---1. The squad module cannot have leaders.
    ---2. The player is not in a squad.
    ---@param player Player
    ---@return true
    function CLASS_SQUADS:RemoveSquadLead(player)
        if not self.hasLeader then 
            error(string.format("%s cannot have leaders.", self.moduleName)) 
        end

        local callSign, squad = self:GetPlayerSquad(player)
        if not squad then
            error(string.format(
                    "%s is not in a squad.", 
                    player:GetNWString("PlayerName")))
        end

        squad:RemoveLeader()

        local netstreamID = "RemoveSquadLead_" .. self.uniqueID
        netstream.Start(
            squad.members, 
            netstreamID, 
            callSign)

        return true
    end

end

function CLASS_SQUADS:New(moduleName, uniqueID, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.uniqueID = uniqueID
    new.description = description

    new.activeSquads = {}
    new.callSigns = {}
    new.usedCallSigns = {}

    self:Register(new)

    return new
end