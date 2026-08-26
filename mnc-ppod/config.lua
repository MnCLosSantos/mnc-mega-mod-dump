Config = {}

-- Debug mode: shows prints in console
Config.Debug = false

-- The xsound label used per player. Unique per source.
Config.SoundLabel = "mnc_ppod"

-- Default volume (0.0 - 1.0)
Config.DefaultVolume = 0.1

-- Default audio radius in metres for personal (non-speaker) playback
Config.DefaultRadius = 5.0

-- How long (ms) client.lua waits after calling exports.xsound:PlayUrl()
Config.YoutubeLoadGraceMs = 3000

Config.RangeCheckInterval = 100

Config.RangeHysteresis = 5.0

-- Max playlists a player can save
Config.MaxPlaylists = 100

-- Max songs per playlist
Config.MaxSongsPerPlaylist = 1500


-- Fallback skin (used by e.g. `/ppod` with no argument)
-- you can also use an argumented command
-- for example "/ppod green" to show a certain ppod ui if needed
Config.DefaultiPodSkin = "silver"

-- Set to false to disable the /ppod command entirely (item-only access,
-- players can still open the ppod by using the item).
Config.EnablePpodCommand = false


Config.iPodSkins = {
    -- ── Solid colours (10) ──────────────────────────────────
    { id = "silver", item = "ppod",        label = "Silver", type = "color",
      accent = "#2563eb", chrome = "#d2d3d8", chromeD = "#a9abb3", chromeDD = "#888a92", wheel = "#c2c3ca", wheelD = "#92949c" },
    { id = "black",  item = "ppod_black",  label = "Black", type = "color",
      accent = "#3b82f6", chrome = "#2b2d33", chromeD = "#1c1d21", chromeDD = "#131315", wheel = "#3a3c42", wheelD = "#202124" },
    { id = "white",  item = "ppod_white",  label = "White", type = "color",
      accent = "#2563eb", chrome = "#f5f6f8", chromeD = "#dcdde2", chromeDD = "#c3c5cb", wheel = "#eceef2", wheelD = "#d5d7dc" },
    { id = "red",    item = "ppod_red",    label = "Red", type = "color",
      accent = "#ef4444", chrome = "#c2373c", chromeD = "#9c2b2f", chromeDD = "#7f2226", wheel = "#d1494d", wheelD = "#a3383c" },
    { id = "blue",   item = "ppod_blue",   label = "Blue", type = "color",
      accent = "#60a5fa", chrome = "#3b6cc9", chromeD = "#2d549e", chromeDD = "#234480", wheel = "#4d7cd4", wheelD = "#33599e" },
    { id = "green",  item = "ppod_green",  label = "Green", type = "color",
      accent = "#4ade80", chrome = "#3f9e5b", chromeD = "#317e48", chromeDD = "#28653a", wheel = "#4bab68", wheelD = "#337a4b" },
    { id = "yellow", item = "ppod_yellow", label = "Yellow", type = "color",
      accent = "#eab308", chrome = "#e8c94a", chromeD = "#c9ab2f", chromeDD = "#a68c22", wheel = "#f0d55f", wheelD = "#c9ab2f" },
    { id = "purple", item = "ppod_purple", label = "Purple", type = "color",
      accent = "#a855f7", chrome = "#8354c9", chromeD = "#66409e", chromeDD = "#513180", wheel = "#9366d4", wheelD = "#6a459e" },
    { id = "orange", item = "ppod_orange", label = "Orange", type = "color",
      accent = "#fb923c", chrome = "#d97a3a", chromeD = "#b1602c", chromeDD = "#8f4d23", wheel = "#e2893f", wheelD = "#b1602c" },
    { id = "pink",   item = "ppod_pink",   label = "Pink", type = "color",
      accent = "#f472b6", chrome = "#e478b0", chromeD = "#c2578e", chromeDD = "#9e4373", wheel = "#ec8ec2", wheelD = "#c2578e" },

    -- ── Artwork skins (5) ────────────────────────────────────
    { id = "racing",   item = "ppod_racing",   label = "Racing Stripes", type = "artwork", theme = "vehicle",
      accent = "#ef4444", chrome = "#1c1d21", chromeD = "#131315", chromeDD = "#0c0c0d", wheel = "#2b2d33", wheelD = "#131315" },
    { id = "carbon",   item = "ppod_carbon",   label = "Carbon Fiber", type = "artwork", theme = "vehicle",
      accent = "#9ca3af", chrome = "#232428", chromeD = "#17181b", chromeDD = "#0f1012", wheel = "#2c2d31", wheelD = "#151619" },
    { id = "camo",     item = "ppod_camo",     label = "Tactical Camo", type = "artwork", theme = "gun",
      accent = "#84cc16", chrome = "#5b5a3f", chromeD = "#46452f", chromeDD = "#363524", wheel = "#5f5e42", wheelD = "#403f2c" },
    { id = "engraved", item = "ppod_engraved", label = "Gunmetal Engraved", type = "artwork", theme = "gun",
      accent = "#cbd5e1", chrome = "#4b4f56", chromeD = "#383b40", chromeDD = "#2a2c30", wheel = "#565a61", wheelD = "#33353a" },
    { id = "haze",     item = "ppod_haze",     label = "Green Haze", type = "artwork", theme = "drug",
      accent = "#22c55e", chrome = "#1f3324", chromeD = "#16251a", chromeDD = "#0f1a12", wheel = "#233d29", wheelD = "#152418" },
}





-- Prop + animation played on the ped while the ppod NUI is open
Config.iPodPropModel    = "prop_phone_ing_03"
Config.iPodPropBoneId   = 28422 -- SKEL_R_Hand
Config.iPodPropOffset   = vector3(0.002, 0.002, -0.007)
Config.iPodPropRotation = vector3(-0.0, 5.0, 5.0)
Config.iPodAnimDict     = "cellphone@"
Config.iPodAnimClip     = "cellphone_text_read_base"




Config.RequireHeadphones = true -- turn false if not using qb-clothing

-- Headphones are worn as a qb-clothing hat
-- differs by texture
-- limited to the 8 textures that item actually has:
--   0 white, 1 black, 2 red, 3 blue, 4 yellow/purple, 5 purple, 6 gray, 7 green
Config.HeadphoneHatProp = 15

Config.HeadphoneSkins = {
    { id = "silver", item = "headphones_silver", label = "Silver", texture = 6 }, -- gray
    { id = "black",  item = "headphones_black",  label = "Black",  texture = 1 },
    { id = "white",  item = "headphones_white",  label = "White",  texture = 0 },
    { id = "red",    item = "headphones_red",    label = "Red",    texture = 2 },
    { id = "blue",   item = "headphones_blue",   label = "Blue",   texture = 3 },
    { id = "green",  item = "headphones_green",  label = "Green",  texture = 7 },
    { id = "yellow", item = "headphones_yellow", label = "Yellow", texture = 4 }, -- yellow/purple
    { id = "purple", item = "headphones_purple", label = "Purple", texture = 5 },
}






Config.SpeakerItem     = "ppod_speaker"
Config.SpeakerModel     = "sf_prop_sf_speaker_stand_01a"
Config.SpeakerRadius    = 15.0
Config.SpeakerInteractDistance = 2.0   -- how close you need to be to see the [E] prompt
Config.SpeakerPlaceTime  = 1200        -- ms progress bar while placing
Config.SpeakerPickupTime = 1200        -- ms progress bar while picking back up

Config.SpeakerAnim = { dict = "pickup_object", clip = "pickup_low" }







Config.BatteryEnabled      = true
Config.BatteryMax          = 100
Config.BatteryDrainAmount  = 1        -- % lost per interval while the ppod is open
Config.BatteryDrainInterval = 30000   -- ms between drain ticks (30s)
Config.BatteryLowWarning   = 15        -- % at which we start warning the player

Config.ChargerItem      = "ppod_charger"
Config.ChargeTime       = 60000        -- ms for a full charging session
Config.ChargeAmount     = 100          -- % battery after a completed charge (full recharge)