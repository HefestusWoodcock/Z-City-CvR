---@type CLASS_HUD
local CLASS_HUD = hg.module:GetType("class_module"):GetRegistered("class_hud")

---@class ZOMBIE_HUD : CLASS_HUD
local ZOMBIE_HUD 
    = CLASS_HUD:New(
        "Zoombie Hud", 
        "zombie_hud", 
        "This module draws the HUD seen by player zombies.")

--// Draw 3d headcrab overlay
	local function DrawHeadcrab(ply, strModel, vecAdjust, fFov)
		if not IsValid(ply.FirstPersonCrab) then
			ply.FirstPersonCrab = ClientsideModel(strModel)
			ply.FirstPersonCrab:SetNoDraw(true)
			return
		end
	
		if not IsValid(ply.FirstPersonCrab2) then
			ply.FirstPersonCrab2 = ClientsideModel(strModel)
			ply.FirstPersonCrab2:SetNoDraw(true)
			ply.FirstPersonCrab2:SetModelScale(1.05)
			return
		end
	
		local mdl = ply.FirstPersonCrab
		local mdl2 = ply.FirstPersonCrab2
	
		if mdl:GetModel() != strModel then
			mdl:SetModel(strModel)
		end
	
		if mdl2:GetModel() != strModel then
			mdl2:SetModel(strModel)
		end
	
		if ply == GetViewEntity() then
			local view = render.GetViewSetup()

			cam.Start3D(view.origin, view.angles, view.fov + fFov, nil, nil, nil, nil, 1, 30)
				cam.IgnoreZ(true)

				local viewpunching = GetViewPunchAngles()
				local ang = view.angles + viewpunching

				ang:RotateAroundAxis(ang:Up(), -90)
				ang:RotateAroundAxis(ang:Forward(), 100)

				mdl:SetRenderOrigin(view.origin + ang:Forward() * vecAdjust.x + ang:Right() * vecAdjust.y + ang:Up() * vecAdjust.z)
				mdl:SetRenderAngles(ang)
				mdl2:SetRenderOrigin(view.origin + ang:Forward() * vecAdjust.x + ang:Right() * vecAdjust.y + ang:Up() * vecAdjust.z)
				mdl2:SetRenderAngles(ang)
				mdl:SetParent(ply, ply:LookupBone("ValveBiped.Bip01_Head1"))
				
				render.SetColorModulation(1, 1, 1)
					render.SetStencilWriteMask(0xFF)
					render.SetStencilTestMask(0xFF)
					render.SetStencilReferenceValue(0)
					render.SetStencilCompareFunction(STENCIL_ALWAYS)
					render.SetStencilPassOperation(STENCIL_KEEP)
					render.SetStencilFailOperation(STENCIL_KEEP)
					render.SetStencilZFailOperation(STENCIL_KEEP)
					render.ClearStencil()
					
					-- Enable stencils
					render.SetStencilEnable(true)
					-- Set everything up everything draws to the stencil buffer instead of the screen
					render.SetStencilReferenceValue(1)
					render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
					render.SetStencilPassOperation(STENCIL_REPLACE)
					
					render.SetBlend(0)
						mdl2:DrawModel()
					render.SetBlend(1)

					render.SetStencilCompareFunction(STENCIL_EQUAL)
					
					mdl:DrawModel()

					DrawBokehDOF(26, 0.93, 15)
					-- Let everything render normally again
					render.SetStencilEnable(false)
				render.SetColorModulation(1, 1, 1)

				cam.IgnoreZ(false)
			cam.End3D()
		end
	end

	hook.Add("Post Pre Post Processing", "ZombDrawHeadcrab", function()
		if lply.PlayerClassName == "zombie" and lply:Alive() and lply.organism and not lply.organism.otrub and GetViewEntity() == lply then
			DrawHeadcrab(lply, "models/nova/w_headcrab.mdl", vector_origin, -50)
		end
	end)

	--// Change view from head to upper torso because zombie model doesn't have proper head bone..
	-- "HG_CalcView", ply, origin, angles, fova, znear, zfar
	hook.Add("HGAddView", "ZombView", function(ply, origin, angles)
		if ply:Alive() and ply.PlayerClassName == "zombie" then
			local ply_spine_index = ply:LookupBone("ValveBiped.Bip01_Spine4")
			if !ply_spine_index then return end
			local ply_spine_matrix = ply:GetBoneMatrix(ply_spine_index)
			local spineAng = ply_spine_matrix:GetAngles()

			origin = origin + spineAng:Right() * -8 + spineAng:Forward() * -2
			angles.z = math.sin(CurTime() * 2) * 4

			local chr = hg.GetCurrentCharacter(ply)
			if CLIENT and hg.IsLocal(ply) and chr:GetBodygroup(1) ~= 0 then
				chr:SetBodygroup(1, 0)
			elseif chr:GetBodygroup(1) == 0 and not ply.organism.headamputated then
				chr:SetBodygroup(1, 1)
			end

			return ply, origin, angles -- change da fov maybe??
		end
	end)

	hook.Add("hg_AdjustMouseSensitivity", "ZombSens", function(sensitivity)
		if lply.PlayerClassName == "zombie" and lply:GetVelocity():LengthSqr() >= 140000 and lply:GetMoveType() == MOVETYPE_WALK then
			return 0.25
		end
	end)

	local zombMat = Material("effects/shaders/zb_grain2") -- Material("effects/shaders/zb_zomb")
	local zombMat_Add = Material("effects/shaders/zb_heat")
	hook.Add("Post Post Processing", "ZombShaders", function()
		if lply.PlayerClassName == "zombie" and lply:Alive() and GetViewEntity() == lply then
			render.UpdateScreenEffectTexture()

			zombMat_Add:SetFloat("$c0_x", -CurTime() * 0.1) //time
			zombMat_Add:SetFloat("$c0_y", 0.1) //intensity (strict)
			zombMat_Add:SetFloat("$c2_x", 2)

			render.SetMaterial(zombMat_Add)
			render.DrawScreenQuad()

			render.UpdateScreenEffectTexture()
			render.UpdateFullScreenDepthTexture()
			
			local asad = math.Clamp(math.sin(CurTime() * 2), 0.7, 1)
			zombMat:SetFloat("$c0_x", CurTime()) -- time
			zombMat:SetFloat("$c0_y", -1) -- gate
			zombMat:SetFloat("$c0_z", 2) -- Pixelize
			zombMat:SetFloat("$c1_x", 16) -- lerp
			zombMat:SetFloat("$c1_y", 0.2) -- vignette intensity
			zombMat:SetFloat("$c1_z", 0.2) -- BlurIntensity
			zombMat:SetFloat("$c2_x", 0.4 * asad) -- r
			zombMat:SetFloat("$c2_y", 0.05) -- g
			zombMat:SetFloat("$c2_z", 0) -- b
			zombMat:SetFloat("$c3_x", 0) -- ImageIntensity
		
			render.SetMaterial(zombMat)
			render.DrawScreenQuad()
		end
	end)

function ZOMBIE_HUD:New(moduleName, uniqueID, description)
    error(string.format("The module %s is a leaf class.", self.moduleName))
end