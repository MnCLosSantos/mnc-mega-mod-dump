-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Engine Swap System'
version '1.9.3'
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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}