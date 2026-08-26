fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mnc-cardelivery'
author 'mnc'
description 'Vehicle delivery job for QBCore - netId synced vehicles, random max performance mods, keys handoff, damage cap, timed delivery, dynamic payout, SQL-backed route builder'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/sounds/*.mp3',
}

dependencies {
    'qb-core',
    'qb-vehiclekeys',
    'ox_lib',
    'oxmysql'
}
