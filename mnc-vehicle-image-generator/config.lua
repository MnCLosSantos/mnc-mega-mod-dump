Config = {}

-- ** Discord Webhook Configuration ** --
-- Leave empty - YOU input a webhook in the UI when it's opened
Config.DefaultWebhook = 'https://discord.com/api/webhooks/1501951192861905090/XUPF902fLMa4Z5d83fYV1lYh6TgnCWfzlXrMGTV6qspCsdvD9CHruItR4r-2P35Lydqg' -- Set a default webhook here to pre-fill the UI input field

-- ** Camera Settings **--
Config.CameraSettings = {
    coords = vector3(90.48, -2731.8, 6.0), -- Where vehicles spawn
    heading = 290.2, -- Vehicle heading
    cameraOffset = vector3(6.8, -4, 0.6), -- Camera position, front-left elevated
    cameraRotation = vector3(176.6, -181.1, -118.5), -- Camera angle, for front 3/4 view
    fov = 71.5 -- Field of view
}

-- ** Screenshot Settings ** --
Config.ScreenshotSettings = {
    encoding = 'png',
    quality = 1.0 -- 0.0 to 1.0
}

-- ** Delay between captures (milliseconds) ** --
Config.CaptureDelay = 1000 -- 5 seconds between each vehicle (prevents Discord rate limiting if your using webhooks)

-- ** Chunk size for batch captures ** --
-- Capture this many vehicles then pause to free memory and avoid pool size crashes
-- Recommended: 25-50 for large vehicle lists
Config.ChunkSize = 25

Config.VehicleSpawnCodes = {
    'banshee3',
    'driftcheburek',
    'polbuffalo6',
    'driftjester3',
    'cargobob5',
    'driftfuto2',
    'stockade4',
    'yosemite1500',
    'dominator10',
    'coquette6',
    'firebolt',
    'chavosv6',
    'duster2',
    'polcoquette4',
    'jester5',
    'suzume',
    'tampa4',
    'driftdominator10',
    'driftgauntlet4',
    'sentinel5',
    'fmj2',
    'xtreme',
    'driftrt3000',
    'driftdominator9',
    'driftkeitora',
    'polbuffalo',
    'veranogt',
    'elegyrh8c',
    's95n',
    'bgmscout2',
    'dominator9c2',
    'gwoodcab',
    'keitorac',
    'echelon',
    'sentinel5c',
    'customcoupewb',
    'cometmans',
    'adderc',
    '2jetz',
    'arbitergtc',
    'arbitergtn',
    'bgmscout',
    'gstap3',
    'cyber',
    'dominator9c',
    'gwood',
    'gwood2',
    'gwoodb',
    'gwoodcop',
    'keitora6x6',
    'kurumac',
    'polelegj',
    'polelegus',
    'purit',
    's95c',
    'kanjosj0',
    'cypherwb',
    'jdvigeror',
    'asterope1rs',
    'jdvigerord',
    'lexicorn',
    'nosferas',
    'seaspray',
    'vigremake',
    'vectrec',
}
