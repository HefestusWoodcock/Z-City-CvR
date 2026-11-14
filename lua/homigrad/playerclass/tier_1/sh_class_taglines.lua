---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_TAGLINES : CLASS_MODULE
---@field tagLines table<string, {tags: string[], color: Color}>
local CLASS_TAGLINES 
    = CLASS_MODULE:New(
        "Class Taglines", 
        "class_taglines", 
        "A module used to generate custom name taglines for specific classes.")
CLASS_TAGLINES.__index = CLASS_TAGLINES

CLASS_TAGLINES.tagLines = {}

function CLASS_TAGLINES:Attach(classInstance)
    local uniqueID = CLASS_TAGLINES.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end

if SERVER then 

    ---Sets the player name and colour on class assignment.
    ---@warning Will throw error if no tag-line is supplied.
    ---@param player Player
    ---@param data { tagLine: string }
    function CLASS_TAGLINES:On(player, data)
        local tagLine = data["tagLine"]

        if not tagLine then 
            error("No tagline found.")
        end

        player.oldName = player:GetNWString("PlayerName")
        player:SetNWString("PlayerName", tagLine)
    end

    ---Sets the player name back to its original value on class de-assignment.
    ---@param player Player
    function CLASS_TAGLINES:Off(player) 
        local name = player.oldName
        player.oldName = nil
        player:SetNWString("PlayerName", name or player:GetNWSring("PlayerName"))
    end

end

---Returns a random string from the table provided.
---@param tags string[]
---@return string tagLine
function CLASS_TAGLINES:GetRandomTag(tags)
    local tagLine = tags[math.random(#tags)]

    return tagLine
end

function CLASS_TAGLINES:New(moduleName, uniqueID, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.uniqueID = uniqueID
    new.description = description

    self:Register(new)

    return new
end