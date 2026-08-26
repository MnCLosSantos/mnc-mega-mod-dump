name 'mnc-carplay'
author 'MnC Los Santos'
version '1.0.0'
description 'Vehicle-mounted Carplay tablet unit — install/remove items, 15 skins, shared radius playback for driver + passengers'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/carplay_racing.png',
    'html/img/carplay_carbon.png',
    'html/img/carplay_camo.png',
    'html/img/carplay_engraved.png',
    'html/img/carplay_wood.png',
}

dependency 'xsound'
dependency 'ox_lib'
dependency 'oxmysql'
dependency 'qb-core'