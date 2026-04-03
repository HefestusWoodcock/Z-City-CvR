local CLASS = player.RegClass("Gamemaster")

CLASS.CanUseDefaultPhrase = false
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = false

hook.Add("HG_CanThoughts", "GamemasterCantDumat", function(ply)
	if ply.PlayerClassName == "Gamemaster" then
		return false
	end
end)

local subclass = {
    default = {
        name = "Gamemaster",
        color = Color(175,0,0)
    },
    overwatch = {
        name = "Overwatch",
        color = Color(0,220,220)
    }
}

local dispositions = {}

function CLASS.Off(self)
    if CLIENT then return end

    if self.cloak then COMMANDS.zc_cloak[1](self) end
    if self.organism.godmode then COMMANDS.zc_god[1](self) end

    self:StripWeapon("weapon_physgun")
    self:StripWeapon("gmod_tool")

    for k,v in ipairs(ents.FindByClass("npc_*")) do

        local npc_class = v:GetClass()
        if npc_class == "npc_bullseye" or not dispositions[npc_class] then continue end
        local d_enum = dispositions[npc_class][1]
        local prio = dispositions[npc_class][2]
        v:AddEntityRelationship( self,  d_enum, prio)
        v:AddEntityRelationship( self.bull, v:Disposition(self) )

    end

    self:SetNWString("PlayerRole", nil)
	self:SetNWString("PlayerName", 
        self.oldname or self:GetNWString("PlayerName"))

    hook.Remove("OnEntityCreated", "relation_shipdo"..self:EntIndex())

end

local function GiveSubClassLoadout(ply, sub) 
    local cfg = subclass[sub] or subclass["default"]

    ply:StripWeapons()
    ply:Give("weapon_hands_sh")
    ply:Give("weapon_physgun")
    ply:Give("gmod_tool")

end

function CLASS.On(self, data) 
    if CLIENT then return end

    if IsValid(self.FakeRagdoll) then
        hg.FakeUp(self, nil, nil, true)
    end

    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    if !self.cloak then COMMANDS.zc_cloak[1](self) end
    if !self.organism.godmode then COMMANDS.zc_god[1](self) end

    local sub = self.subClass or "default"
    self:SetNWString("PlayerRole", sub)
    local cfg = subclass[sub] or subclass["default"]

    GiveSubClassLoadout(self, sub)

    self.oldname = self:GetNWString("PlayerName")
    self:SetNWString("PlayerName", cfg.name)

    for k,v in ipairs(ents.FindByClass("npc_*")) do

        local npc_class = v:GetClass()
        if npc_class == "npc_bullseye" then continue end
        local d_enum, prio = v:Disposition(self)
        dispositions[npc_class] = { d_enum, prio }

        v:AddEntityRelationship( self, D_NU, 0)
        v:AddEntityRelationship( self.bull, v:Disposition(self) )
        v:ClearEnemyMemory()

    end

    local index = self:EntIndex()
    hook.Add( "OnEntityCreated", "relation_shipdo"..index, function( ent )
        if not IsValid(self) then hook.Remove("OnEntityCreated", "relation_shipdo" .. index) return end
        if ( ent:IsNPC() ) then
            v:AddEntityRelationship( self, D_NU, 0)
            v:AddEntityRelationship( self.bull, v:Disposition(self) )
        end
    end )

    self.CurAppearance = appearance

end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end
end

function CLASS.PlayerDeath(self)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
            v:ClearEnemyMemory()
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
            v:ClearEnemyMemory()
        end
    end

    hook.Remove( "OnEntityCreated", "relation_shipdo"..self:EntIndex())
end

-- Overwatch HUD
if CLIENT then 

    local cmb_mat = Material("sprites/mat_jack_helmoverlay_r")
    hook.Add("RenderScreenspaceEffects","Overwatch_View",function()
        local lply = LocalPlayer()
        local role = lply:GetNWString("PlayerRole")
        if lply:Alive() and lply.PlayerClassName == "Gamemaster" and role == "overwatch" then
            surface.SetDrawColor(25,190,190,255)
            surface.SetMaterial(cmb_mat)
            surface.DrawTexturedRectRotated(
                (ScrW()/2) - 5,
                (ScrH()/2) - 5,
                ScrW() + 10,
                ScrH() + 450,
                180
            )
            render.PushFilterMag(TEXFILTER.ANISOTROPIC)
            render.PushFilterMin(TEXFILTER.ANISOTROPIC)
                CLASS.HUDPaint(lply)
            render.PopFilterMag()
            render.PopFilterMin()
        end
    end)

end

-- Overwatch Commands
if CLIENT then 

    local overwatch_commands = {
        ["/broadcast"] = function(msg, ply)

            for _, unit in ipairs(player.GetAll()) do
                if unit.PlayerClassName ~= "Combine" and unit.PlayerClassName ~= "Gamemaster" then continue end
                
                net.Start("OW_NotifyUnit")
                    net.WriteEntity(unit)
                    net.WriteString("New Overwatch Directive: " .. msg)
                    net.WriteColor(Color(0, 190, 190))
                net.SendToServer()
                
            end

        end,
        ["/objective"] = function(msg, ply) 
            
            net.Start("OW_NotifyUnit")
                net.WriteEntity(ply)
                net.WriteString("New Overwatch Directive: " .. msg)
                net.WriteColor(Color(0, 190, 190))
            net.SendToServer()

            net.Start("OW_AssignNewObjective")
                net.WriteEntity(ply)
                net.WriteString(msg)
            net.SendToServer()

        end,
        ["/notify"] = function(msg, ply) 
            
            net.Start("OW_NotifyUnit")
                net.WriteEntity(ply)
                net.WriteString("Overwatch Directive to Unit " .. ply:GetNWString("PlayerName") .. ": " .. msg)
                net.WriteColor(Color(0, 190, 190))
            net.SendToServer()

        end
    }

    --[[ Not Needed
    hook.Add("HG_OnPlayerCommand", "Overwatch_Broadcast", function(ply, texta)
        if lply:Alive() and lply.PlayerClassName ~= "Gamemaster" then return end

        local text = texta[1]
        local cmd = string.lower(string.Explode(" ", text)[1])
        local txt = string.Explode(" ", text)
        table.remove(txt,1)
        if overwatch_commands[cmd] then
            overwatch_commands[cmd](table.concat( txt, " " ), ply)
        end
    end)
    ]]

    function AttachFunctionToSquad( Directive ) 
        
        tbl = {}
        for _, unit in ipairs(player.GetAll()) do 
            local role = unit:GetNWString("PlayerRole")
            if unit.PlayerClassName ~= "Combine" and role ~= "Leader" then continue end

            net.Start("OW_SquadInfoRequest"); 
                net.WriteEntity(unit)
            net.SendToServer()
            net.Receive("OW_SquadInfoSent", function()
                local squad_name = net.ReadString()
                local members = net.ReadTable(true)

                tbl[#tbl + 1] = {
                    [1] = function(mouseClick)
                        Directive(squad_name, unit, members)

                        return 0
                    end,
                    [2] = squad_name
                }
            end)
        end
        hg.CreateRadialMenu(tbl)

        return tbl
    
    end

    function AttachFunctionToUnit( Directive, GeneralDirective )
    
        tbl = {}
        local active_units = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply.PlayerClassName ~= "Combine" and ply.PlayerClassName ~= "CivPro" then continue end
            table.insert(active_units, #active_units + 1, ply)
        end

        if GeneralDirective then 
            tbl[#tbl + 1] = {
                [1] = function()
                    GeneralDirective(active_units)
                end,
                [2] = "To All Active Units"
            }
        end

        for _, unit in ipairs(active_units) do
            tbl[#tbl + 1] = {
                [1] = function() 
                    Directive(unit)
                end,
                [2] = unit:GetNWString("PlayerName")
            }
        end
        hg.CreateRadialMenu(tbl)

        return tbl

    end 

    hook.Add("radialOptions", "Overwatch", function()

		if lply:Alive() and lply:GetNWString("PlayerRole") == "overwatch" then
			hg.radialOptions[#hg.radialOptions + 1] = {
				[1] = function(mouseClick)

                    local tbl = { 
                        [1] = {
                            [1] = function(mouseClick) 
                                AttachFunctionToUnit( function(unit)
                                    RunConsoleCommand("ulx", "spectate", unit:Nick())
                                end, nil )

                                return -1
                            end,
                            [2] = "Open Unit Camera"
                        },
                        [2] = { 
                            [1] = function(mouseClick)
                                AttachFunctionToUnit( function(unit) 
                                    Derma_StringRequest(
                                        "Overwatch Notify",
                                        "Write directive for unit " .. unit:GetNWString("PlayerName"),
                                        "",
                                        function(text) 
                                            overwatch_commands["/notify"](text, unit)
                                        end
                                    ) 
                                end, function(active_units) 
                                    Derma_StringRequest(
                                        "Overwatch Broadcast",
                                        "Write broadcast directive for all active units.",
                                        "",
                                        function(text) 
                                            for _, unit in ipairs(active_units) do 
                                                overwatch_commands["/notify"](text, unit)
                                            end
                                        end
                                    ) 
                                end) 

                                return -1
                            end,
                            [2] = "Notify Units"
                        },
                        [3] = {
                            [1] = function(mouseClick) 
                                AttachFunctionToSquad( function(squad, leader, members) 
                                    Derma_StringRequest(
                                        "Overwatch Objective",
                                        "Write objective for squad " .. squad,
                                        "",
                                        function(text)
                                            overwatch_commands["/objective"](text, leader)
                                            for _, unit in ipairs(members) do 
                                                overwatch_commands["/objective"](text, unit)
                                            end
                                        end
                                    ) 
                                end )
                                
                                return -1 
                            end,
                            [2] = "Assign New Objective"
                        }
                    }
                    hg.CreateRadialMenu(tbl)

                    return -1

				end,
                [2] = "Overwatch Directives"
			}
		end

	end)
else
    util.AddNetworkString("OW_NotifyUnit")
    net.Receive("OW_NotifyUnit", function(len, ply)
        if ply:GetNWString("PlayerRole") ~= "overwatch" then return end

        local ent = net.ReadEntity()
        local msg = net.ReadString()
        local color = net.ReadColor()
        
        net.Start("HGNotificate")
            net.WriteString(msg)
            net.WriteColor(color)
        net.Send(ent)
    end)

    util.AddNetworkString("OW_AssignNewObjective")
    net.Receive("OW_AssignNewObjective", function(len, ply) 
        if ply:GetNWString("PlayerRole") ~= "overwatch" then return end

        local ent = net.ReadEntity()
        local objective = net.ReadString()

        net.Start("SendObjective")
            net.WriteString(objective)
        net.Send(ent)
    end)
end

return CLASS