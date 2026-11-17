
-- Voice Lines

local cmb_phrases = {
    "npc/combine_soldier/vo/prison_soldier_activatecentral.wav",
    "npc/combine_soldier/vo/prison_soldier_boomersinbound.wav",
    "npc/combine_soldier/vo/prison_soldier_bunker1.wav",
    "npc/combine_soldier/vo/prison_soldier_bunker2.wav",
    "npc/combine_soldier/vo/prison_soldier_bunker3.wav",
    "npc/combine_soldier/vo/prison_soldier_containD8.wav",
    "npc/combine_soldier/vo/prison_soldier_fallback_b4.wav",
    "npc/combine_soldier/vo/prison_soldier_freeman_antlions.wav",
    "npc/combine_soldier/vo/prison_soldier_fullbioticoverrun.wav",
    "npc/combine_soldier/vo/prison_soldier_leader9dead.wav",
    "npc/combine_soldier/vo/prison_soldier_negativecontainment.wav",
    "npc/combine_soldier/vo/prison_soldier_prosecuteD7.wav",
    "npc/combine_soldier/vo/prison_soldier_sundown3dead.wav",
    "npc/combine_soldier/vo/prison_soldier_tohighpoints.wav",
    "npc/combine_soldier/vo/prison_soldier_visceratorsA5.wav"
}

local cmb_context_phrases = {

    ["Affirmative."] = {
        "npc/combine_soldier/vo/affirmative.wav",
        "npc/combine_soldier/vo/affirmative2.wav",
        "npc/combine_soldier/vo/copy.wav",
        "npc/combine_soldier/vo/copythat.wav"
    },
    ["Moving."] = {
        "npc/combine_soldier/vo/unitisinbound.wav",
        "npc/combine_soldier/vo/unitisclosing.wav",
        "npc/combine_soldier/vo/unitismovingin.wav"
    },
    ["Retreat!"] = {
        "npc/combine_soldier/vo/ripcord.wav",
        "npc/combine_soldier/vo/ripcordripcord.wav",
        "npc/combine_soldier/vo/displace.wav",
        "npc/combine_soldier/vo/displace2.wav"
    },
    ["Target sighted."] = {
        "npc/combine_soldier/vo/contactconfirmprosecuting.wav",
        "npc/combine_soldier/vo/contactconfim.wav"
    },
    ["Medic."] = {
        "npc/combine_soldier/vo/requestmedical.wav",
        "npc/combine_soldier/vo/requeststimdose.wav"
    },
    ["Negative."] = {
        "voice_replacement/hla_ordinal/vo/unabletocommence_01.wav"
    },
    ["Laugh."] = {
        "npc/metropolice/vo/chuckle.wav"
    }

}

local radio_off = {
    "voice_replacement/hla_grunt/vo/off1.wav",
    "voice_replacement/hla_grunt/vo/off2.wav",
    "voice_replacement/hla_grunt/vo/off3.wav",
    "voice_replacement/hla_grunt/vo/off4.wav",
    "voice_replacement/hla_grunt/vo/off5.wav",
    "voice_replacement/hla_grunt/vo/off6.wav",
    "voice_replacement/hla_grunt/vo/off7.wav"
}

local radio_on = {
    "voice_replacement/hla_grunt/vo/on1.wav",
    "voice_replacement/hla_grunt/vo/on2.wav",
    "voice_replacement/hla_grunt/vo/on3.wav",
    "voice_replacement/hla_grunt/vo/on4.wav",
    "voice_replacement/hla_grunt/vo/on5.wav"
}

local function RadioSoundOn(ent, pitch)
    ent:EmitSound(radio_on[math.random(1, #radio_on)], 70, pitch)
end

local function RadioSoundOff(ent, pitch)
    ent:EmitSound(radio_off[math.random(1, #radio_off)], 70, pitch)
end

--;; Серверные хуки и звуки шагов/смерти
if SERVER then
    local function CanListen(output, input, isChat)
        if (not IsValid(output) or not IsValid(input)) then
            return
        end

        if (not output:Alive() or output.organism.otrub or not input:Alive() or input.organism.otrub) then
            return false
        end

        if (output.PlayerClassName == "Combine" or output:GetNWString("PlayerRole") == "overwatch")
            and input.PlayerClassName == "Combine" then
                return true
        end
    end

    hook.Add("CanListenOthers", "TAC-Radio OTA", function(output, input, isChat, teamonly, text)
        if CanListen(output, input, isChat) then
            if isChat then
                RadioSoundOn(output, 100)
                if output == input then return end
                RadioSoundOn(input, 100)

                if input:GetPos():DistToSqr(output:GetPos()) < 600000 and not output.organism.otrub and not input.organism.otrub then
                    return true
                else
                    input:ChatPrint("TAC-" .. output:GetNWString("PlayerName") .. ": " .. text)
                    return false
                end
            else
                return true, false
            end
        end
    end)

    hook.Add("StartVoice", "TAC-Radio OTA", function(output)
        for i, input in player.Iterator() do
            if CanListen(output, input, false) then
                if output == input then
                    RadioSoundOn(output, 100)
                    continue
                end

                RadioSoundOn(input, 100)
            end
        end
    end)

    hook.Add("EndVoice", "TAC-Radio OTA", function(output)
        for i, input in player.Iterator() do
            if CanListen(output, input, false) then
                if output == input then
                    RadioSoundOff(output, 100)
                    continue
                end

                RadioSoundOff(input, 100)
            end
        end
    end)
end


return CLASS