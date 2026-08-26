fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Stan Leigh'
description 'MNC Forklift Fix - Synced vehicle lifting for forklifts'
version '1.1.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}