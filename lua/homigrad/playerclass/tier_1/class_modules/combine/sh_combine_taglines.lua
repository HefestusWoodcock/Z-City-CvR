---@type CLASS_TAGLINES
local CLASS_TAGLINES = hg.module:GetType("class_module"):GetRegistered("class_taglines")

---@class COMBINE_TAGLINES : CLASS_TAGLINES
local COMBINE_TAGLINES 
    = CLASS_TAGLINES:New(
        "Combine Taglines", 
        "combine_taglines", 
        "This module generates taglines for Combine and Civil Protection units.")

---Returns a random number string.
---@param max number
---@return string number
local function RandomNumber(max) 
    local number = math.random(max)
    local isSingle = number / 10 < 1

    return (isSingle and "0" or "") .. number
end

function COMBINE_TAGLINES:On(player, data)
    local class = player.PlayerClassName
    local subClass = player.subClass
    local isLead = player:IsLeader() or false

    ---@diagnostic disable-next-line:undefined-field
    local config = self:GetAttached(class).configs.tags[subClass]

    local prefix = isLead and config.leaderPrefix or config.prefix
    local tags = isLead and config.leaderTags or config.tags

    local tag = data.tagLine or self:GetRandomTag(tags)
    local tagLine = string.format(
        "%s.%s-%s", 
        prefix,
        string.upper(tag),
        RandomNumber(20))

    self:Super("On", player, { tagLine = tagLine })
end

function COMBINE_TAGLINES:Off(player)
    local name = player.oldName
    player.oldName = nil
    player:SetNWString("PlayerName", name)
end

function COMBINE_TAGLINES:New()
    error(string.format("The module %s is a leaf class.", self.moduleName))
end