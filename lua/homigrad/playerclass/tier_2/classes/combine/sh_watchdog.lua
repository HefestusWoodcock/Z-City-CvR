--[[

local watchdog = {
        color = Color(70, 100, 0),
        models = Model("models/player/beta_elite.mdl"),
        mat = {
            ["models/beta_elite/sd_sniper_regular_armor"] = "models/shadertest/predator",
            ["models/beta_elite/sd_conscript_regular_alice_laat"] = "models/shadertest/predator",
            ["models/beta_elite/sd_conscript_regular_harness_belt"] = "models/shadertest/predator",
            ["models/beta_elite/sd_conscript_regular_pouch_frag"] = "models/shadertest/predator",
            ["models/beta_elite/sd_conscript_regular_loadout_c"] = "models/shadertest/predator"
        },
        armor = {
            ["head"] = "cmb_helmet",
            ["torso"] = "cmb_armor"
        },
        loadout = {
            {weapon = "weapon_melee"},
            {
                weapon = "weapon_hg_slam",
                count = 1

            },
            {
                weapon = "weapon_hg_hl2nade_tpik",
                count = 2
            },
            {
                weapon = "weapon_hg_flashbang_tpik",
                count = 1
            },
            {
                weapon = "weapon_hk_usp",
                ammo_mult = 5
            },
            {
                weapon = "weapon_combinesniper",
                ammo_mult = 5
            },
        },
        phrases = "grunt_phrases.json",
        context_phrases = "grunt_context_phrases.json"
    }

]]