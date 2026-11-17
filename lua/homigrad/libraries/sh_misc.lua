local function NicePrint(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

string.NicePrint = NicePrint

local thermal = {
    active = true, -- always on for local player
}

local COLOR_MOD = {
    ["$pp_colour_addr"]        = 0,
    ["$pp_colour_addg"]        = 0.05,   -- slight green push in shadows
    ["$pp_colour_addb"]        = 0,
    ["$pp_colour_mulr"]        = 0.15,   -- suppress red channel
    ["$pp_colour_mulg"]        = 1.1,    -- boost green channel
    ["$pp_colour_mulb"]        = 0.15,   -- suppress blue channel
    ["$pp_colour_brightness"]  = 0,
    ["$pp_colour_contrast"]    = 1.6,    -- separate hot/cold values
    ["$pp_colour_colour"]      = 0,      -- 0 = fully desaturated
    ["$pp_colour_blue"]        = 0,
}

---Bloom params: (darken, multiply, sizeX, sizeY, passes, r, g, b, a)
---Cranked up so bright (hot) areas bleed/glow like real thermal optics.
local function DrawThermalBloom()
    DrawBloom(0.1, 4, 10, 10, 2, 0.4, 1, 0.4, 1)
end


local PIXEL_SIZE = 3 -- higher = blockier/lower-res look. try 4-10.

local pixelRT, rtW, rtH
local function CreatePixelRT()

    rtW = math.ceil(ScrW() / PIXEL_SIZE)
    rtH = math.ceil(ScrH() / PIXEL_SIZE)

    pixelRT = GetRenderTargetEx(
        "thermal_pixelate_rt",
        rtW, rtH,
        RT_SIZE_LITERAL,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(2, 256), -- CLAMPS + CLAMPT, avoids edge-wrap artifacts
        0,
        IMAGE_FORMAT_BGRA8888
    )
end
if CLIENT then 
	CreatePixelRT()
end

-- Recreate the RT if the player changes resolution/window size,
-- otherwise the pixelation will look stretched/wrong.
--[[
hook.Add("OnScreenSizeChanged", "Thermal_RecreatePixelRT", function()
    CreatePixelRT()
end)]]

---Draws a hot silhouette around every visible player so they pop
---against the desaturated background, mimicking body-heat signatures.
--[[
hook.Add("PreDrawHalos", "Thermal_PlayerHeat", function()
    if not thermal.active then return end

	

    local localPly = LocalPlayer()
    local players = {}

    for _, ply in ipairs(player.GetAll()) do
        if ply ~= localPly and ply:Alive() and ply:GetNoDraw() == false then
            table.insert(players, ply)
        end
    end

    if #players == 0 then return end

    -- (entities, color, blurX, blurY, passes, additive, ignoreZ)
    halo.Add(players, Color(255, 255, 200), 3, 3, 2, true, false)
end)]]
--[[
hook.Add("RenderScreenspaceEffects", "Thermal_ColorGrade", function()
    if not thermal.active then return end

	render.CopyRenderTargetToTexture(pixelRT)

    DrawColorModify(COLOR_MOD)
	DrawThermalBloom()
	render.PushFilterMag(TEXFILTER.POINT)
	render.PushFilterMin(TEXFILTER.POINT)
	--render.DrawTextureToScreenRect(pixelRT, 0, 0, ScrW(), ScrH())
	render.PopFilterMag()
	render.PopFilterMin()
end)]]
--[[
local THERMAL_MATERIAL = "models/debug/debugwhite"
local HOT_COLOR = Color(255, 255, 200, 255)
hook.Add("PrePlayerDraw", "Thermal", function(player, flags)
	render.CopyRenderTargetToTexture(pixelRT)

	player:SetMaterial(THERMAL_MATERIAL)
	render.SetColorModulation(255, 0, 0)
	render.PushFilterMag(TEXFILTER.POINT)
	render.PushFilterMin(TEXFILTER.POINT)
	render.DrawTextureToScreenRect(pixelRT, 0, 0, ScrW(), ScrH())
	render.PopFilterMag()
	render.PopFilterMin()
end)]]

