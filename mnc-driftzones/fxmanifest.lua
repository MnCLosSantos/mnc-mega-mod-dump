-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Stan Leigh'
description 'Drift Zones - map out drift zones and auto-trigger the drift score HUD'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/enter.mp3',
    'html/sounds/exit.mp3'
}

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

client_script 'client.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib',
    'mnc-driftscore'
}
