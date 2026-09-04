fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mnc-pinkslips'
author 'mnc'
description "Class-locked point-to-point pinkslip racing for QBCore - buy-in pot races grind toward per-player pinkslip unlocks, winner takes the parked vehicle straight to Pillbox Garage, loser's own car goes on the line"
version '1.0.0'

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
    'qb-garages',
    'ox_lib',
    'oxmysql'
}
