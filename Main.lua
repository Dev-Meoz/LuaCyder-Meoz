local BASE_URL =
    "https://raw.githubusercontent.com/Dev-Meoz/LuaCyder-Meoz/main/"

local SCRIPTS = {
    [97598239454123] = {
        name = "Grow a Garden 2",
        path = "IDK-scripts/GAG2-Main.luau",
    },

    [2753915549] = {
        name = "Blox Fruits - Sea 1",
        path = "MainBF.lua",
    },

    [4442272183] = {
        name = "Blox Fruits - Sea 2",
        path = "MainBF.lua",
    },

    [7449423635] = {
        name = "Blox Fruits - Sea 3",
        path = "MainBF.lua",
    },

    [107778070777162] = {
        name = "Steal An Egg",
        path = "IDK-scripts/StealAnEgg.lua",
    },
}

local placeId = game.PlaceId
local config = SCRIPTS[placeId]

if not config then
    warn("[Loader] Unsupported PlaceId:", placeId)
    return
end

local url = BASE_URL .. config.path

print("[Loader] Game:", config.name)
print("[Loader] Script path:", url)
