fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Advanced Safe Zones System - PolyZone circles with height, NUI Admin Menu'
version '2.0.0'
lua54 'yes'

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

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

ui_page 'html/index.html'