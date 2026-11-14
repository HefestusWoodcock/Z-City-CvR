---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_APPEARANCE : CLASS_MODULE
local CLASS_APPEARANCE 
    = CLASS_MODULE:New(
        "Class Appearance", 
        "class_appearance", 
        "A module used to set appearances for specific classes.")
CLASS_APPEARANCE.__index = CLASS_APPEARANCE

function CLASS_APPEARANCE:Attach(classInstance)
    local uniqueID = CLASS_APPEARANCE.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end

---@alias ModelConfig { model: { name: string, skin: number, bodygroups?: number[], mats?: table<string, string> } }
---@alias Appearances { models: ModelConfig[], leaderModels: ModelConfig[], color: { r: number, g: number, b: number } }

---Returns an appearance table from the given table.
---@param appearances Appearances
---@param isLead? boolean
---@return table config
function CLASS_APPEARANCE:GetAppearance(appearances, isLead)
    local config = {}

    local color = appearances.color or nil
    config.color = Vector(color.r, color.g, color.b)

    if isLead and appearances.leaderModels then 
        appearances, config.model = table.Random(appearances.leaderModels)
    else
        appearances, config.model = table.Random(appearances.models)
    end

    config.skin = appearances.skin or 0
    config.bodygroups = appearances.bodygroups or {}
    config.mats = appearances.mats or {}

    return config
end

---Returns a table of appearances for a class, and a given subclass or the default.
---@param class PLAYER_CLASS
---@param subClass string
---@return Appearances appearances
function CLASS_APPEARANCE:GetClassAppearances(class, subClass) 
    local appearances = class.configs.appearances
    appearances = appearances[subClass] or appearances["default"]

    return appearances
end

if SERVER then 

    ---Sets the appearance of the player based on the config below.
    ---@param player Player
    ---@param config { model: string, skin: number?, bodygroups: number[]?, mats: table<string, string>?, color: Vector }
    local function SetAppearance(player, config)
        ApplyAppearance(player,nil,nil,nil,true)
        local Appearance = player.CurAppearance or hg.Appearance.GetRandomAppearance()
        Appearance.AAttachments = nil
        Appearance.AColthes = ""
        player:SetModel(Model(config.model))
        player:SetSubMaterial()
        player:SetNetVar("Accessories", "")

        if config.color then 
            player:SetPlayerColor(config.color)
        end
        
        if config.skin then 
            player:SetSkin(config.skin)
        end

        if config.bodygroups then 
            for id, value in ipairs(config.bodygroups) do
                player:SetBodygroup(id, value)
            end
        end

        if config.mats then 
            for id, material in pairs(config.mats) do
                player:SetSubMaterial(player:GetSubMaterialIdByName(id), material)
            end
        end
        

        player.CurAppearance = Appearance
    end

    ---Sets the appearance of the player when the class is assigned.
    ---@param player Player
    ---@param data table
    function CLASS_APPEARANCE:On(player, data)
        local class = player.PlayerClassName
        if not self:ValidatePlayer(player) then return end
        ---@type PLAYER_CLASS
        class = self:GetAttached(class)

        local config = data["appearance"] or nil
        if not config then 
            local subClass = player.subClass
            local isLead = player.IsLeader and player:IsLeader() or false

            local appearances = self:GetClassAppearances(class, subClass)

            config = self:GetAppearance(appearances, isLead)
        end
        SetAppearance(player, config)
    end

end

function CLASS_APPEARANCE:New(moduleName, uniqueID, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.uniqueID = uniqueID
    new.description = description

    self:Register(new)

    return new
end