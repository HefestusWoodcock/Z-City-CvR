---@type CLASS_APPEARANCE
local CLASS_HUD = hg.module:GetType("class_module"):GetRegistered("class_appearance")

---@class REBEL_APPEARANCE : CLASS_APPEARANCE
local REBEL_APPEARANCE 
    = CLASS_HUD:New(
        "Rebel Appearance", 
        "rebel_appearance", 
        "A module used to set appearances for specific classes.")

---@alias RebelAppearance { count: number, ignoreCount?: table<number, boolean>, name: string, postFix?: string, skin?: number, bodygroups?: number[], mats?: table<string, string> }

---Generates a table of models based on the data given.
---@param modelData RebelAppearance[]
---@return ModelConfig[] models
local function GenerateModelsTable(modelData)
    local models = {}

    for model, data in pairs(modelData) do 
        for i = 1, data.count do
            -- Have to do this ugly thing cause modelers skip numbers.
            if data.ignoreCount and data.ignoreCount[i] then continue end
            local isSingle = i / 10 < 1
            local number = (isSingle and "0" or "") .. i
            local postFix = data.postFix or ""

            local modelPath 
                = string.format("%s%s%s.mdl", model, number, postFix)

            models[modelPath] = {
                name = data.name .. number,
                skin = data.skin or nil,
                bodygroups = data.bodygroups or nil,
                mats = data.mats or nil
            }
        end
    end

    return models
end

---Rebels use a different JSON format for their models,
---and this method is meant to parse that format.
function REBEL_APPEARANCE:GetClassAppearances(class, subClass)
    ---@type { models: RebelAppearance[], leaderModels: RebelAppearance[], color: { r, g, b } }
    local appearances 
        = self:Super("GetClassAppearances", class, subClass)

    ---@type Appearances
    local newAppearances = {}

    newAppearances.models 
        = GenerateModelsTable(appearances.models)
    
    if appearances.leaderModels then 
        newAppearances.leaderModels 
            = GenerateModelsTable(appearances.leaderModels)
    end

    newAppearances.color = appearances.color
    print(appearances.color)

    return newAppearances
end

function REBEL_APPEARANCE:New(moduleName, uniqueID, description)
    error(string.format("The module %s is a leaf class.", self.moduleName))
end