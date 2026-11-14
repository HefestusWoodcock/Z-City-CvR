---@type CLASS_MODULE
local CLASS_MODULE = hg.module:GetType("class_module")

---@class CLASS_SOUNDS : CLASS_MODULE
---@field sounds table<string, string>
---@field phrases table
---@field contextPhrases table
local CLASS_SOUNDS 
    = CLASS_MODULE:New(
        "Class Sounds", 
        "class_sounds", 
        "A module used to set-up custom phrases and sound-effects for specific classes.")
CLASS_SOUNDS.__index = CLASS_SOUNDS

CLASS_SOUNDS.sounds = {}
CLASS_SOUNDS.phrases = {}
CLASS_SOUNDS.contextPhrases = {}

---@enum HOOK_TYPE
CLASS_SOUNDS.HOOK_TYPE = {
    FOOTSTEPS = "footsteps",
    PAIN = "pain",
    RELOAD = "reload",
    DEATH = "death"
}
CLASS_SOUNDS.HOOKS = {
    [CLASS_SOUNDS.HOOK_TYPE.FOOTSTEPS] = "HG_PlayerFootstep",
    [CLASS_SOUNDS.HOOK_TYPE.PAIN] = "HomigradDamage",
    [CLASS_SOUNDS.HOOK_TYPE.RELOAD] = "HGReloading",
    [CLASS_SOUNDS.HOOK_TYPE.DEATH] = "PlayerClassDeath"
}

function CLASS_SOUNDS:Attach(classInstance)
    local uniqueID = CLASS_SOUNDS.uniqueID
    self:Super("Attach", classInstance, uniqueID)
end

function CLASS_SOUNDS:Init(classConfigs)
    util.AddNetworkString("PlayCharacterPhrase")
    net.Receive("PlayCharacterPhrase", function(len, player)
        if (player.phrCld or 0) > CurTime() then return end

        ---@type Entity
        ---@diagnostic disable-next-line
        local chr = hg.GetCurrentCharacter(player)

        local phrase = net.ReadString()
        local muffed = net.ReadBool()
        local pitch = net.ReadBool()
        chr:EmitSound(
            phrase, 
            muffed and 65 or 75,
            player.VoicePitch or 100,
            1,
            CHAN_AUTO, 
            0, 
            pitch and 56 or muffed and 14 or 0
        )

        if string.match( phrase, ".ogg" ) then // ogg doesn't return the right soundduration
            player.phrCld = CurTime() + 1
        else
            player.phrCld = CurTime() + (SoundDuration(phrase) or 0)
        end
        player.lastPhr = phrase
    end)


    return true
end

---Goes through a player's class configs and returns the sound table
---for the wanteds sound type.
---@param player Player The player whose class is being accessed for sound files.
---@param soundType string The type of sounds.
---@return string[] sounds
function CLASS_SOUNDS:GetSounds(player, soundType)
    local class = player:GetPlayerClass()
    local subClass = player.subClass

    ---@diagnostic disable-next-line:unchecked-nil-access
    local sounds = class.configs.sounds[subClass] or class.configs.sounds["default"]
    sounds = sounds[soundType] or nil

    return sounds
end

if CLIENT then 

    --[[
    - Implementing this feature is entirely dependent on how the sound files are structured
    - inside the content packs, and as such, I am not gonna bother with it until I've set
    - up my own content pack of sounds that we use so I have a base line to work with
    - and not have to cobble together novel solutions for each content pack.
    -
    - I also hate working with the current phrase system.

    function CLASS_SOUNDS:GetRandomPhrase(phrases)
        return table.Random(phrases)
    end

    function CLASS_SOUNDS:RecursiveAssign(tbl)
        local client = LocalPlayer()
		local new_tbl = {}
        local count = #new_tbl + 1

		for context, phrases in pairs(tbl) do	
			local soundName = phrases["soundName"] or nil

            if not soundName then 
                new_tbl[count] = {
					[1] = function(mouseClick)
						self:RecursiveAssign(phrases)
					end,
					[2] = context
				}
            else
                local targeted = phrases["targeted"]
                if targeted then 
                    new_tbl[count] = {
						[1] = function(mouseClick)
							if mouseClick == 1 then
								RunConsoleCommand("hg_phrase_context", context, SendRandomPhrase(value["Normal."]))
							else 
								MemberAssign(context, value["Order."])
							end
						end,
						[2] = context .. "\nRMB - Order Menu"
					}
                else 
                    new_tbl[count] = {
                        [1] = function()
                            self:PlayCharacterPhrase(client, self:GetRandomPhrase(phrases), nil, nil)
                        end,
                        [2] = context
                    }
                end
            end
		end

		hg.CreateRadialMenu(new_tbl)
		return new_tbl
    end

    ---Replaces the radial menu option for context phrases with a custom one.
    ---@param func fun(): boolean The function should return true if its replacing the option.
    function CLASS_SOUNDS:ReplaceContextPhrases(func)
        local identifier = self.uniqueID .. "_ContextRadial"
        hook.Add("HG_ReplacePhraseRadial", identifier, func)
    end

    ---Removes the custom radial menu option for phrases.
    function CLASS_SOUNDS:RemoveContextPhrases()
        local identifier = self.uniqueID .. "_ContextRadial"
        hook.Remove("HG_ReplacePhraseRadial", identifier)
    end

    
    function CLASS_SOUNDS:PlayCharacterPhrase(player, phrase, muffed, pitch)
        net.Start("PlayCharacterPhrase")
            net.WriteString(phrase)
            net.WriteBool(muffed or false)
            net.WriteBool(pitch or false)
        net.SendToServer()
    end
    ]]

else 

    ---This method allows us to add sound hooks to play during
    ---an event. By wrapping it in a method function, we can
    ---access other methods within the module, like `PlaySequentialSounds`
    ---
    ---@warning Make sure to call this method inside `Init` to use `self`.
    ---@warning The callbacks of some hooks have different parameters
    ---and may return different values.
    ---@realm server
    ---@param hookType HOOK_TYPE The event we are attaching to.
    ---@param func function The callback function for the event running.
    function CLASS_SOUNDS:AddSoundHookToClass(hookType, func)
        hook.Add(self.HOOKS[hookType], self.uniqueID .. "_" .. hookType, func)
    end

    ---This method allows for a sequence of sounds to be played.
    ---
    ---The parameters sent over match the internal `EmitSound()`.
    ---@param sounds string[] A table of ordered sound paths to play.
    ---@param position Vector The position where the sounds will play.
    ---@param entity? Entity The entity to emit the sounds from.
    ---@param channel? CHAN The sound channel.
    ---@param volume? number The volume of the sounds, from 0 to 1.
    ---@param soundLevel? SNDLVL The sound level of the sounds.
    ---@param soundFlags? SND The flags of the sounds.
    ---@param pitch? number The pitch of the sounds, from 0 to 255.
    ---@param dsp? number The DSP preset for the sounds.
    ---@param filter? CRecipientFilter If played serverside, 
    ---the sound will only be networked to the clients in the filter.
    function CLASS_SOUNDS:PlaySequentialSounds(sounds, position, entity, channel, volume, soundLevel, soundFlags, pitch, dsp, filter) 
        local accumulator = 0
        for _, phrase in ipairs(sounds) do

            timer.Simple(accumulator, function ()
                EmitSound(
                    phrase, 
                    position, 
                    entity:EntIndex(), 
                    channel, 
                    volume, 
                    soundLevel, 
                    soundFlags, 
                    pitch, 
                    dsp, 
                    filter)
            end)
            accumulator = accumulator + SoundDuration(phrase) * 1.1

        end
    end

end

function CLASS_SOUNDS:New(moduleName, uniqueID, description)
    local new = setmetatable({}, self)

    new.moduleName = moduleName
    new.uniqueID = uniqueID
    new.description = description

    self:Register(new)

    return new
end