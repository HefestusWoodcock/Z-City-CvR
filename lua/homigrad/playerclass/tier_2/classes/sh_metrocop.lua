local radio_on = {
    "voice_replacement/hla_grunt/vo/on1.wav",
    "voice_replacement/hla_grunt/vo/on2.wav",
    "voice_replacement/hla_grunt/vo/on3.wav",
    "voice_replacement/hla_grunt/vo/on4.wav",
    "voice_replacement/hla_grunt/vo/on5.wav"
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

local function RadioSoundOn(ent, pitch)
    ent:EmitSound(radio_on[math.random(1, #radio_on)], 70, pitch)
end

local function RadioSoundOff(ent, pitch)
    ent:EmitSound(radio_off[math.random(1, #radio_off)], 70, pitch)
end

if SERVER then
    local mtcop_phrases = {}
    local files,_ = file.Find("sound/npc/metropolice/vo/*.wav","GAME")
    for k,v in ipairs(files) do
        mtcop_phrases[k] = "npc/metropolice/vo/" .. v
    end

    hook.Add("HG_ReplacePhrase", "metropolice_phrase", function(ply, phrase, muffed, pitch)
        if IsValid(ply) and ply.PlayerClassName == "CivPro" then
            print(ply)
            print(ply.PlayerClassName)
            return ply, mtcop_phrases[math.random(#mtcop_phrases)], muffed, pitch
        end
    end)

    local function CanListen(output, input, isChat)
        if (not IsValid(output) or not IsValid(input)) then
            return
        end

        if (not output:Alive() or output.organism.otrub or not input:Alive() or input.organism.otrub) then
            return false
        end

        if (output.PlayerClassName == "CivPro" or output:GetNWString("PlayerRole") == "overwatch")
            and input.PlayerClassName == "CivPro" then
                return true
        end
    end

    hook.Add("CanListenOthers", "TAC-Radio CivPro", function(output, input, isChat, teamonly, text)
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

    hook.Add("StartVoice", "TAC-Radio CivPro", function(output)
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

