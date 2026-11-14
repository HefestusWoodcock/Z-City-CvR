---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_HUD : CLASS_MODULE
---@field frt number
---@field colors table<string, Color>
---@field screenspaceEffects table<string, function>
local CLASS_HUD 
    = CLASS_MODULE:New(
        "Class Hud", 
        "class_hud", 
        "A module used to create client-side HUDs for specific classes.")
CLASS_HUD.__index = CLASS_HUD


CLASS_HUD.frt = FrameTime() * 5

CLASS_HUD.EFFECT_TYPE = {
    SCREENSPACE = "screenspace",
    HALO = "halo",
    HUD_ELEMENT = "element"
}
local ADD_FUNCS = {
    [CLASS_HUD.EFFECT_TYPE.SCREENSPACE] = "AddScreenspaceEffect",
    [CLASS_HUD.EFFECT_TYPE.HALO] = "AddHalo",
    [CLASS_HUD.EFFECT_TYPE.HUD_ELEMENT] = "AddHUDElement"
}
local REMOVE_FUNCS = {
    [CLASS_HUD.EFFECT_TYPE.SCREENSPACE] = "RemoveScreenspaceEffect",
    [CLASS_HUD.EFFECT_TYPE.HALO] = "RemoveHalo",
    [CLASS_HUD.EFFECT_TYPE.HUD_ELEMENT] = "RemoveHUDElement"
}

CLASS_HUD.colors = {}

CLASS_HUD.screenspace = {}
CLASS_HUD.halos = {}
CLASS_HUD.elements = {}

CLASS_HUD.toggles = {}

function CLASS_HUD:Attach(classInstance)
    local uniqueID = CLASS_HUD.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end

if CLIENT then

    ---Adds a new screen effect that can be toggable via a client-side convar.
    ---@param identifier string Name of the toggle.
    ---@param effects {flag: string, func: function}[] A table containing effect flags, and their respective functions.
    ---@param onToggle fun(enabled: boolean) A function that runs on change.
    ---@param default boolean The default state of the toggle.
    ---@return ConVar convar
    function CLASS_HUD:CreateToggleEffect(identifier, effects, onToggle, default)
        for _, e in ipairs(effects) do 
            if not ADD_FUNCS[e.flag] then 
                error(string.format(
                    "Unknown effect flag %s has been supplied.",
                    e.flag))
            end
        end


        local applied = false
        local function ApplyState(enabled)
            enabled = enabled and true or false
            if applied == enabled then return end

            if onToggle then onToggle(enabled) end

            for _, e in ipairs(effects) do 
                local fnName = enabled and ADD_FUNCS[e.flag] or REMOVE_FUNCS[e.flag]
                -- This sends over an unnecessary param when a remove call is made.
                self[fnName](self, identifier, e.func)
            end
            
            applied = enabled
        end

        self.toggles[identifier] = { effects = effects, apply = ApplyState }

        ApplyState(default or false)

        return function(enabled)
            if enabled == nil then
                ApplyState(not applied)
            else
                ApplyState(enabled)
            end
        end
    end

    ---Adds a new screenspace effect to be rendered.
    ---@param identifier string Name of the effect.
    ---@param func function The rendering function to be passed over.
    function CLASS_HUD:AddScreenspaceEffect(identifier, func)
        if self.screenspace[identifier] then 
            error(string.format(
                "Screenspace effect with name %s already exist for %s.", 
                identifier, 
                self.moduleName))
        end

        self.screenspace[identifier] = func
    end

    ---Removes a screenspace effect from the render pool.
    ---@param identifier string Name of the effect.
    function CLASS_HUD:RemoveScreenspaceEffect(identifier)
        if not self.screenspace[identifier] then 
            error(string.format(
                "Screenspace effect with name %s could not be found for %s.", 
                identifier, 
                self.moduleName))
        end

        self.screenspace[identifier] = nil
    end

    ---Adds a new screenspace effect to be rendered.
    ---@param identifier string Name of the effect.
    ---@param func function The rendering function to be passed over.
    function CLASS_HUD:AddHalo(identifier, func)
        if self.halos[identifier] then 
            error(string.format(
                "Screenspace effect with name %s already exist for %s.", 
                identifier, 
                self.moduleName))
        end

        self.halos[identifier] = func
    end

    ---Removes a screenspace effect from the render pool.
    ---@param identifier string Name of the effect.
    function CLASS_HUD:RemoveHalo(identifier)
        if not self.halos[identifier] then 
            error(string.format(
                "Screenspace effect with name %s could not be found for %s.", 
                identifier, 
                self.moduleName))
        end

        self.halos[identifier] = nil
    end

    ---Adds a new HUD element to be rendered.
    ---@param identifier string Name of the element.
    ---@param func function The rendering function to be passed over.
    function CLASS_HUD:AddHUDElement(identifier, func) 
        if self.elements[identifier] then 
            error(string.format(
                "Screenspace effect with name %s already exist for %s.", 
                identifier, 
                self.moduleName))
        end

        self.elements[identifier] = func
    end

    ---Removes a hud element from the HUD render pool.
    ---@param identifier string Name of the element
    function CLASS_HUD:RemoveHUDElement(identifier)
        if not self.elements[identifier] then 
            error(string.format(
                "Screenspace effect with name %s could not be found for %s.", 
                identifier, 
                self.moduleName))
        end

        self.elements[identifier] = nil
    end

    function CLASS_HUD:On(player)
        local client = LocalPlayer()
        
        local idScreenspace = string.format("%s Screenspace", self.moduleName)
        local idHalo = string.format("%s Halos", self.moduleName)
        local idHUD = string.format("%s HUD", self.moduleName)

        hook.Add("RenderScreenspaceEffects", idScreenspace, function()
            if not client:Alive() then return end
            for _, effect in pairs(self.screenspace) do
                if not isfunction(effect) then continue end
                effect()
            end
        end)

        hook.Add("PreDrawHalos", idHalo, function()
            if not client:Alive() then return end
            for _, halo in pairs(self.halos) do 
                if not isfunction(halo) then continue end
                halo()
            end
        end)

        hook.Add("HUDPaint", idHUD, function()
            render.PushFilterMag(TEXFILTER.ANISOTROPIC)
            render.PushFilterMin(TEXFILTER.ANISOTROPIC)
            for _, element in pairs(self.elements) do
                if not isfunction(element) then continue end
                element()
            end
            render.PopFilterMag()
            render.PopFilterMin()
        end)
    end

    function CLASS_HUD:Off(player)
        local idScreenspace = string.format("%s Screenspace", self.moduleName)
        local idHalo = string.format("%s Halos", self.moduleName)
        local idHUD = string.format("%s HUD", self.moduleName)

        for _, toggle in pairs(self.toggles) do 
            toggle.apply(false)
        end

        hook.Remove("RenderScreenspaceEffects", idScreenspace)
        hook.Remove("PreDrawHalos", idHalo)
        hook.Remove("HUDPaint", idHUD)
    end

end

function CLASS_HUD:New(moduleName, uniqueID, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.uniqueID = uniqueID
    new.description = description
    new.colors = {}

    new.screenspace = {}
    new.halos = {}
    new.elements = {}

    new.toggles = {}

    self:Register(new)

    return new
end