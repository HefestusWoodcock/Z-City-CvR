---@type CLASS_SQUADS
local CLASS_SQUADS = hg.module:GetType("class_module"):GetRegistered("class_squads")

---@class CIVPRO_SQUADS : CLASS_SQUADS
local CIVPRO_SQUADS 
    = CLASS_SQUADS:New(
        "Civil Protection Squads", 
        "civpro_squads", 
        "This module is used to create squads for Combine and Civil Protection units.")

CIVPRO_SQUADS.callSigns = {
    "Ground Protection Team"
}

function CIVPRO_SQUADS:GenerateCallSign()
    local callSign = nil

    repeat
        local tag = self.callSigns[math.random(#self.callSigns)]
        local candidateCallSign = tag .. "-" .. math.random(100, 1000)

        if not self.usedCallSigns[candidateCallSign] then
            self.usedCallSigns[candidateCallSign] = true
            callSign = candidateCallSign
        end

    until callSign ~= nil
    
    return callSign
end

function CIVPRO_SQUADS:On(player, data)
    self:Super("On", player, data)

    if SERVER then 
        local callSign = data["squad"] or nil
        local isLead = false
        local squad

        if callSign == "new" then
            callSign, squad = self:CreateNewSquad()
            isLead = true
        else 
            callSign, squad = self:GetOpenSquad(player)
            if not callSign then 
                callSign, squad = self:CreateNewSquad()
                isLead = true
            end
        end

        self:AddPlayerToSquad(player, callSign)
        if isLead then
            -- We call the super of `MakeSquadLead` here as to not
            -- trigger the sound effect, as that only works when
            -- the Combine taglines are set.
            self:MakeSquadLead(player)
        end

    end
end

function CIVPRO_SQUADS:Off(player)
    if SERVER then
        local callSign, squad = self:GetPlayerSquad(player)
        local isLead = player:IsLeader()

        self:DeassignPlayerFromSquad(player)

        if #squad.members <= 0 then 
            self:DeleteSquad(callSign)
        elseif isLead then
            self:MakeSquadLead(squad.members[math.random(#squad.members)])
        end
    end

    self:Super("Off", player)
end


