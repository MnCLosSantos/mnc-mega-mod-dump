name 'mnc-ppod'
author 'MnC Los Santos'
version '1.0.0'
description 'Personal ppod (iPod-style) music player with headphones, speakers, battery and NUI'
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
    'html/img/ppod_racing.png',
    'html/img/ppod_carbon.png',
    'html/img/ppod_camo.png',
    'html/img/ppod_engraved.png',
    'html/img/ppod_haze.png',
}

dependency 'xsound'
dependency 'ox_lib'
dependency 'oxmysql'
dependency 'qb-core'
