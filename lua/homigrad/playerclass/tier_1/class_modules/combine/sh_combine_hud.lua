---@type CLASS_HUD
local CLASS_HUD = hg.module:GetType("class_module"):GetRegistered("class_hud")

---@class COMBINE_HUD : CLASS_HUD
local COMBINE_HUD 
    = CLASS_HUD:New(
        "Combine Hud", 
        "combine_hud", 
        "This module draws the HUD seen by Combine and Civil Protection units.")

if CLIENT then

    local color_hp = Color(0,255,255,220)
    local color_ar = Color(0,255,255,220)
    local color_glow = Color(15,165,165,0)
    local color_glow_ar = Color(15,165,165,0)
    local color_glow_ammo = Color(15,165,165,0)
    local color_sight = Color(15,165,165,220)
    local color_pulse = Color(15,165,165,220)

    local color_hp2 = Color(165,15,15)
    local color_ar2 = Color(165,15,15)
    local color_glow2 = Color(165,15,15)
    local color_glow_ar2 = Color(165,15,15)
    local color_glow_ammo2 = Color(165,15,15)
    local color_sight2 = Color(165,15,15)
    local color_pulse2 = Color(165,15,15)

    local armor_txt, hp_txt, pulse_txt, stamina_txt, ammo_txt = 0,0,0,0,0
    local bloodlerp, ammolerp = 0,0
    local blood_old, old_hp_txt, old_ar_txt, old_ammo_txt = 5000,0,0,0
    local pos_sight = Vector(ScrW(),ScrH(),0)
    local bg_color = Color(0,0,0,150)
    local armorlerp = 0

    surface.CreateFont("CMBFontDefault",{
        font = "Roboto Light",
        extended = true,
        size = ScreenScale(24),
        weight = 500,
        scanlines = 3,
        antialias = true
    })

    surface.CreateFont("CMBFontSmall",{
        font = "Roboto Light",
        extended = true,
        size = ScreenScale(7.5),
        weight = 1500,
        scanlines = 3,
        antialias = true
    })

    surface.CreateFont("CMBFontSmallBG",{
        font = "Roboto Light",
        extended = true,
        size = ScreenScale(7.5),
        weight = 500,
        blursize = 1,
        scanlines = 3,
        antialias = true
    })

    surface.CreateFont("CMBFontDefaultBG",{
        font = "Roboto Light",
        extended = true,
        size = ScreenScale(24.5),
        weight = 1500,
        blursize = 1,
        scanlines = 3,
        antialias = true
    })

    local function drawGlowingText(txt, font, x, y, col, col_glow, col_glow2, align)
        draw.DrawText(txt, font, x + 1, y + 1, col_glow, align)
        if col_glow2 then
            draw.DrawText(txt, font, x + 2, y + 2, col_glow2, align)
        end
        draw.DrawText(txt, font, x, y, col, align)
    end

    local function drawBGPanel(pos_x,pos_y,alpha)
        local size_w, size_h = ScrW() * 0.12, ScrH() * 0.075
        local pos_w, pos_h = ScrW() * pos_x, ScrH() * pos_y - size_h
        return {pos_w, pos_h}, {size_w, size_h}
    end

    local silentlerp = 0
    local silentclr = Color(0,255,255,220)
    local posSight = Vector(ScrW(),ScrH(),0)

    local cmb_mat = Material("sprites/mat_jack_helmoverlay_r")

    COMBINE_HUD:AddScreenspaceEffect("Combine_Helmet", function()
        local client = LocalPlayer()
        local role = client:GetNWString("PlayerRole")
        if role == "Elite" or role == "Shotgunner" then
            surface.SetDrawColor(255,25,25,255)
        else
            surface.SetDrawColor(25,190,190,255)
        end
        surface.SetMaterial(cmb_mat)
        surface.DrawTexturedRectRotated(
            (ScrW() / 2) - 5,
            (ScrH() / 2) - 5,
            ScrW() + 10,
            ScrH() + 450,
            180
        )
    end)

    local function TracePlayers(player, target) 
        local trace = util.TraceLine({
            start = player:EyePos(),
            endpos = target:EyePos(),
            filter = function(ent)
                return ent ~= player and ent ~= target and not ent:IsPlayer() and not ent:IsNPC() and ent:GetClass() ~= "prop_physics"
            end
        })

        return trace
    end

    local haloUpdateInterval = 0.2
    local lastHaloUpdate = 0
    local memberHalos = {}
    ---Adds a halo to squad members that are not visible
    COMBINE_HUD:AddHalo("Squad_Member_Halo", function()
        local client = LocalPlayer()
        if client.PlayerClassName ~= "combine" then return end
        if not client.GetSquad then return end
        local callSign, squad = client:GetSquad()
        if not squad then return end

        local time = CurTime()
        if time - lastHaloUpdate >= haloUpdateInterval then 
            lastHaloUpdate = time
            table.Empty(memberHalos)

            for _, member in ipairs(squad.members) do
                if client == member then continue end

                -- We use this instead of `ent:IsDormant()` as the PVS system
                -- is not efficient in checking actual visibility between two
                -- players in real time.
                local trace = TracePlayers(client, member)
                if not (trace.Hit and (trace.MatType or 0) ~= 71) then continue end

                memberHalos[#memberHalos + 1] = member
            end
        end
        
        for _, member in ipairs(memberHalos) do 
             if squad.leader and member == squad.leader then 
                halo.Add(
                    {member}, 
                    Color(175, 25, 25, 255), 
                    0, 
                    0, 
                    1, 
                    false, 
                    true)
            else 
                halo.Add(
                    {member}, 
                    Color(0, 220, 220, 255), 
                    0, 
                    0, 
                    1, 
                    true, 
                    true)
            end
        end
    end)

    --local role = client:GetNWString("PlayerRole")
    local is_red = nil
    --local is_lead = role == "Leader"
    
    COMBINE_HUD:AddHUDElement("squad_designation", function()
        local client = LocalPlayer()
        local callSign = client.GetSquad and client:GetSquad() or "Unit-Unassigned"
        
        local pos, size = drawBGPanel(0.5, 0.9)
        surface.SetFont("CMBFontDefault")
        local player_name = client:GetNWString("PlayerName")
        local col_bg = bg_color

        draw.DrawText(player_name .. " | " .. callSign, "CMBFontSmall",
            pos[1],
            pos[2] + (size[2] / 2),
            col_bg,
            TEXT_ALIGN_CENTER
        )
        draw.DrawText(player_name .. " | " .. callSign, "CMBFontSmall",
            pos[1],
            pos[2] + (size[2] / 2),
            is_red and color_hp2 or color_hp,
            TEXT_ALIGN_CENTER
        )
    end)

    
    COMBINE_HUD:AddHUDElement("squad_info", function()
        local client = LocalPlayer()
        -- Return here so we don't crash the HUD-elements.
        if not client.GetSquad 
            and not not client:GetSquad() then return end   
        local callSign, squad = client:GetSquad()

        local pos, size = drawBGPanel(0.9, 0.2, 100)
        surface.SetFont("CMBFontDefault")
        local col_bg = bg_color
        for i, member in ipairs(squad.members) do
            if member == client then continue end

            local name = member:GetNWString("PlayerName")
            local org = member.organism
            if not org or not org.pulse then continue end

            local pulse = org.heartbeat
            local member_pulse = math.Round(pulse)
            draw.DrawText( name .. " |  " .. member_pulse .. " BPM", "CMBFontSmall",
                pos[1],
                pos[2] + (size[2] * i),
                col_bg,
                TEXT_ALIGN_CENTER
            )
            draw.DrawText( name .. " |  " .. member_pulse .. " BPM", "CMBFontSmall",
                pos[1],
                pos[2] + (size[2] * i),
                is_red and color_hp2 or color_hp,
                TEXT_ALIGN_CENTER
            )
        end
    end)

    COMBINE_HUD:AddHUDElement("hp_display", function()
        local client = LocalPlayer()
        local pos, size = drawBGPanel(0.065,0.98)
        surface.SetFont("CMBFontDefault")
        local bloodcount = math.Round(100 * client.organism.blood / 5000 , 0)
        local _,txt_size_y = surface.GetTextSize(bloodcount)
        hp_txt = math.min(hp_txt + 1, bloodcount)
        local col_bg = bg_color
        col_bg.a = 225
        draw.DrawText("000","CMBFontDefaultBG",
            pos[1] + size[1] * 0.08 + 1,
            pos[2] + (size[2] / 2) - txt_size_y / 2 + 1,
            col_bg,
            TEXT_ALIGN_RIGHT
        )

        if is_red then
            color_glow2.a = math.Round(Lerp(COMBINE_HUD.frt, color_glow2.a, old_hp_txt ~= hp_txt and 255 or 0))
            drawGlowingText(hp_txt,
                            "CMBFontDefault",
                            pos[1] + size[1] * 0.08,
                            pos[2] + (size[2] / 2) - txt_size_y / 2,
                            color_hp2,
                            color_glow2,
                            nil,
                            TEXT_ALIGN_RIGHT)
        else
            color_glow.a = math.Round(Lerp(COMBINE_HUD.frt, color_glow.a, old_hp_txt ~= hp_txt and 255 or 0))
            drawGlowingText(hp_txt,
                            "CMBFontDefault",
                            pos[1] + size[1] * 0.08,
                            pos[2] + (size[2] / 2) - txt_size_y / 2,
                            color_hp,
                            color_glow,
                            nil,
                            TEXT_ALIGN_RIGHT)
        end
        old_hp_txt = hp_txt

        draw.DrawText("% | BLOOD","CMBFontSmall",
            pos[1] + size[1] * 0.085 + 1,
            pos[2] + (size[2] / 1.8) + 1,
            col_bg,
            TEXT_ALIGN_LEFT
        )
        draw.DrawText("% | BLOOD","CMBFontSmall",
            pos[1] + size[1] * 0.085,
            pos[2] + (size[2] / 1.8),
            is_red and color_hp2 or color_hp,
            TEXT_ALIGN_LEFT
        )
    end)

    COMBINE_HUD:AddHUDElement("pulse_display", function()
        local client = LocalPlayer()
        local pos, size = drawBGPanel(0.035,0.925)
        surface.SetFont("CMBFontSmall")
        local org = client.organism
        if not org or not org.pulse then return end
        local pulse = org.heartbeat
        pulse_txt = math.Round(math.min(pulse_txt + 1, pulse))
        local col_bg = bg_color
        col_bg.a = 225

        draw.DrawText(pulse_txt,"CMBFontSmall",
            pos[1] + size[1] * -0.09,
            pos[2] + (size[2] / 2),
            col_bg,
            TEXT_ALIGN_LEFT
        )
        draw.DrawText(pulse_txt,"CMBFontSmall",
            pos[1] + size[1] * -0.095,
            pos[2] + (size[2] / 2),
            is_red and color_hp2 or color_hp,
            TEXT_ALIGN_LEFT
        )
        draw.DrawText("| HEART.B/MIN","CMBFontSmall",
            pos[1] + size[1] * 0.06 + 1 + 10,
            pos[2] + (size[2] / 2) + 1,
            col_bg,
            TEXT_ALIGN_LEFT
        )
        draw.DrawText("| HEART.B/MIN","CMBFontSmall",
            pos[1] + size[1] * 0.06 + 12,
            pos[2] + (size[2] / 2),
            is_red and color_hp2 or color_hp,
            TEXT_ALIGN_LEFT
        )
    end)

    COMBINE_HUD:AddHUDElement("stamina_display", function()
        local client = LocalPlayer()
        local pos, size = drawBGPanel(0.035,0.895)
        surface.SetFont("CMBFontSmall")
        local org = client.organism
        if not org or not org.stamina then return end
        local stamina = org.stamina[1] or 180
        stamina_txt = math.Round(math.min(stamina_txt + 1, stamina))
        local col_bg = bg_color
        col_bg.a = 225

        draw.DrawText(stamina_txt,"CMBFontSmall",
            pos[1] + size[1] * -0.09,
            pos[2] + (size[2] / 2),
            col_bg,
            TEXT_ALIGN_LEFT
        )
        draw.DrawText(stamina_txt,"CMBFontSmall",
            pos[1] + size[1] * -0.095,
            pos[2] + (size[2] / 2),
            is_red and color_hp2 or color_hp,
            TEXT_ALIGN_LEFT
        )
        draw.DrawText("| STAMINA","CMBFontSmall",
            pos[1] + size[1] * 0.065 + 1 + 10,
            pos[2] + (size[2] / 2) + 1,
            col_bg,
            TEXT_ALIGN_LEFT
        )
        draw.DrawText("| STAMINA","CMBFontSmall",
            pos[1] + size[1] * 0.065 + 12,
            pos[2] + (size[2] / 2),
            is_red and color_hp2 or color_hp,
            TEXT_ALIGN_LEFT
        )
    end)

    COMBINE_HUD:AddHUDElement("silent_mode", function()
        local client = LocalPlayer()
        local pos, size = drawBGPanel(0.5,0.99)
        surface.SetFont("CMBFontSmall")
        silentlerp = LerpFT(0.1,silentlerp,(client:KeyDown(IN_DUCK) or client:KeyDown(IN_WALK)) and 1 or 0)
        local col_bg = bg_color
        col_bg.a = 225 * silentlerp
        silentclr.a = 225 * silentlerp
        local txt = "SNEAK MODE"
        draw.DrawText(txt,"CMBFontSmall",
            pos[1],
            pos[2] + (size[2] / 2),
            col_bg,
            TEXT_ALIGN_CENTER
        )
        draw.DrawText(txt,"CMBFontSmall",
            pos[1],
            pos[2] + (size[2] / 2),
            silentclr,
            TEXT_ALIGN_CENTER
        )
    end)

    COMBINE_HUD:AddHUDElement("ammo_display", function()
        local client = LocalPlayer()
        local wep = client:GetActiveWeapon()
        if IsValid(wep) and wep.Clip1 then
            ammolerp = Lerp(COMBINE_HUD.frt,ammolerp,(wep:Clip1() < 0) and 0 or 1)
            local pos, size = drawBGPanel(0.93,0.98)
            surface.SetFont("CMBFontDefault")
            local _,txt_size_y = surface.GetTextSize(client:Armor())
            local col_bg = bg_color
            col_bg.a = 225 * ammolerp
            ammo_txt = math.min(ammo_txt + 1, wep:Clip1())

            draw.DrawText("000","CMBFontDefaultBG",
                pos[1] + size[1] * 0.08 + 1,
                pos[2] + (size[2] / 2) - txt_size_y / 2 + 1,
                col_bg,
                TEXT_ALIGN_RIGHT
            )

            if is_red then
                color_glow_ammo2.a = math.Round(Lerp(COMBINE_HUD.frt, color_glow_ammo2.a, old_ammo_txt ~= ammo_txt and 255 or 0))
                drawGlowingText(ammo_txt,"CMBFontDefault",
                    pos[1] + size[1] * 0.08,
                    pos[2] + (size[2] / 2) - txt_size_y / 2,
                    color_ar2, color_glow_ammo2, nil, TEXT_ALIGN_RIGHT
                )
            else
                color_glow_ammo.a = math.Round(Lerp(COMBINE_HUD.frt, color_glow_ammo.a, old_ammo_txt ~= ammo_txt and 255 or 0))
                drawGlowingText(ammo_txt,"CMBFontDefault",
                    pos[1] + size[1] * 0.08,
                    pos[2] + (size[2] / 2) - txt_size_y / 2,
                    color_ar, color_glow_ammo, nil, TEXT_ALIGN_RIGHT
                )
            end
            old_ammo_txt = ammo_txt

            draw.DrawText("AMMO","CMBFontSmall",
                pos[1] + size[1] * 0.085 + 1,
                pos[2] + (size[2] / 1.8) + 1,
                col_bg,
                TEXT_ALIGN_LEFT
            )
            draw.DrawText("AMMO","CMBFontSmall",
                pos[1] + size[1] * 0.085,
                pos[2] + (size[2] / 1.8),
                is_red and color_ar2 or color_ar,
                TEXT_ALIGN_LEFT
            )
        end
    end)

    local pnv_light = nil
    local pnv_color_1 = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0.07,
        ["$pp_colour_addb"] = 0.1,
        ["$pp_colour_brightness"] = 0.01,
        ["$pp_colour_contrast"] = 0.6,
        ["$pp_colour_colour"] = 0.08,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0.1,
        ["$pp_colour_mulb"] = 0.2
    }
    local pnv_color_2 = {
        ["$pp_colour_addr"] = 0.06,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0.05,
        ["$pp_colour_contrast"] = 0.6,
        ["$pp_colour_colour"] = 0.08,
        ["$pp_colour_mulr"] = 0.2,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    local visor_effects = {
        {
            flag = COMBINE_HUD.EFFECT_TYPE.SCREENSPACE,
            func = function()
                local client = LocalPlayer()

                local class = client:GetNWString("PlayerRole")
                local cc = (class == "Elite" or class == "Shotgunner") and pnv_color_2 or pnv_color_1
                DrawColorModify(cc)
                DrawBloom(0.1, 0.5, 2, 2, 1, 0.4, 1, 1, 1)
            end
        },
        {
            flag = COMBINE_HUD.EFFECT_TYPE.HALO,
            func = function()
                local client = LocalPlayer()

                
                pnv_light:SetPos(client:EyePos()) ---@diagnostic disable-line:unchecked-nil-access
                pnv_light:SetAngles(client:EyeAngles()) ---@diagnostic disable-line:unchecked-nil-access
                pnv_light:Update() ---@diagnostic disable-line:unchecked-nil-access
            end
        }
    }
    
    ---This visor effects gives Civil Protection and Combine units night-vision.
    local toggleVisor = COMBINE_HUD:CreateToggleEffect("visor", visor_effects, 
        function(enabled)
            local client = LocalPlayer()

            if enabled then
                surface.PlaySound("items/nvg_on.wav")

                if not IsValid(pnv_light) then
                    pnv_light = ProjectedTexture()
                    pnv_light:SetTexture("effects/flashlight001")
                    pnv_light:SetBrightness(2)
                    pnv_light:SetEnableShadows(false)
                    pnv_light:SetConstantAttenuation(0.02)
                    pnv_light:SetNearZ(12)
                    pnv_light:SetFOV(70)
                end
                pnv_light:SetPos(client:EyePos())
                pnv_light:SetAngles(client:EyeAngles())
                pnv_light:Update()
            else
                surface.PlaySound("items/nvg_off.wav")

                if IsValid(pnv_light) then 
                    pnv_light:Remove()
                end
                pnv_light = nil
            end
        end, false)
    toggleVisor(false)

    
    concommand.Add("hg_toggle_visor", function()
        local client = LocalPlayer()
        if client.PlayerClassName ~= "combine" 
            and client.PlayerClassName ~= "civpro" then return end

        toggleVisor()
    end)
end


function COMBINE_HUD:New(moduleName, uniqueID, description)
    error(string.format("The module %s is a leaf class.", self.moduleName))
end