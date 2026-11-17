---@type CLASS_SQUADS
local CLASS_SQUADS = hg.module:GetType("class_module"):GetRegistered("class_squads")

---@class COMBINE_SQUADS : CLASS_SQUADS
local COMBINE_SQUADS 
    = CLASS_SQUADS:New(
        "Combine Squads", 
        "combine_squads", 
        "This module is used to create squads for Combine and Civil Protection units.")

COMBINE_SQUADS.callSigns = {
    "Apex", "Helix", "Ice", "Ion", "Mace",
    "Payback", "Quicksand", "Sundown", "Uniform"
}


local PATH = "npc/combine_soldier/vo/"
local NUMBERS = {
    [0] = "zero", "one", "two", "three", "four", "five", 
    "six", "seven", "eight", "niner", "ten"
}
local DEPLOYED = {
    "npc/combine_soldier/vo/_comma.wav",
    "npc/combine_soldier/vo/fullactive.wav",
    "npc/combine_soldier/vo/off2.wav"
}
local PROMOTION = {
    "npc/combine_soldier/vo/isfieldpromoted.wav",
    "npc/combine_soldier/vo/off2.wav"
}
local SQUAD_DOWN = {
    [1] = {
        "npc/combine_soldier/vo/overwatchteamisdown.wav",
        "npc/combine_soldier/vo/_period.wav"
    },
    [2] = {
        "npc/combine_soldier/vo/lostcontact.wav"
    }
}

function COMBINE_SQUADS:On(player, data)
    self:Super("On", player, data)

    if SERVER then 
        local callSign = data["squad"] or nil
        local isLead = false
        local squad

        if callSign == "new" then
            callSign, squad = self:CreateNewSquad(player)
            isLead = true
        else 
            callSign, squad = self:GetOpenSquad(player)
            if not callSign then 
                callSign, squad = self:CreateNewSquad(player)
                isLead = true
            end
        end

        self:AddPlayerToSquad(player, callSign)
        if isLead then
            -- We call the super of `MakeSquadLead` here as to not
            -- trigger the sound effect, as that only works when
            -- the Combine taglines are set.
            self:Super("MakeSquadLead", player)
        end

    end
end

function COMBINE_SQUADS:Off(player)
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

local function RadioNotify(sounds, player)
    ---@type CLASS_SOUNDS
    local SOUNDS 
        = hg.module:GetType("class_module")
                    :GetRegistered("class_sounds")

    SOUNDS:PlaySequentialSounds(
        sounds, 
        player:GetPos(), 
        player, 
        nil, 
        1, 
        85)
end

---Used to parse names and returns a table of sound file names.
---@param name string
---@return string[] tbl
local function ParseNameToSoundFile(name)
    local tbl = {}
    local tokens = string.Split(name, "-")

    table.insert(tbl, PATH .. string.lower(tokens[1]) .. ".wav")
    ---We are doing it like this so '15' is spoked as 'one-five'.
    local numbers = string.ToTable(tokens[2])
    for _, number in ipairs(numbers) do 
        table.insert(tbl, PATH .. NUMBERS[tonumber(number)] .. ".wav")
    end

    return tbl
end

if SERVER then 

    ---Plays a sound on a combine unit when a new squad is initialised.
    ---@param player? Player Used only to play sound on player.
    ---@return string callSign
    ---@return Squad squad
    function COMBINE_SQUADS:CreateNewSquad(player)
        ---@type string
        local callSign, squad = self:Super("CreateNewSquad")

        if IsValid(player) and player.PlayerClassName == "combine" then 
            local sounds = ParseNameToSoundFile(callSign)
            table.Add(sounds, DEPLOYED)

            RadioNotify(sounds, player)
        end

        return callSign, squad
    end

    ---Plays a sound on a combine unit when a new squad is deleted.
    ---@param callSign string 
    ---@param player? Player Used only to play sound on player.
    ---@return string callSign
    ---@return Squad squad
    function COMBINE_SQUADS:DeleteSquad(callSign, player)
        self:Super("DeleteSquad", callSign)

        if IsValid(player) and player.PlayerClassName == "combine" then 
            local sounds = table.Copy(SQUAD_DOWN[1])
            table.Add(sounds, ParseNameToSoundFile(callSign))
            table.Add(sounds, SQUAD_DOWN[2])

            RadioNotify(sounds, player)
        end
    end

    ---Plays a sound on a combine unit is promoted to leader.
    ---
    ---@warning Will throw an error if the playername isn't set.
    ---@param player? Player
    ---@return true
    function COMBINE_SQUADS:MakeSquadLead(player)
        self:Super("MakeSquadLead", player)

        if IsValid(player) and player.PlayerClassName == "combine" then             
            ---@see COMBINE_TAGLINES For tagline generation.
            local tokens = string.Split(player:GetNWString("PlayerName"), ".")

            local sounds = ParseNameToSoundFile(tokens[2])
            table.Add(sounds, PROMOTION)

            RadioNotify(sounds, player)
        end

        return true
    end

end

function COMBINE_SQUADS:New(moduleName, uniqueID, description)
    error(string.format("The module %s is a leaf class.", self.moduleName))
end