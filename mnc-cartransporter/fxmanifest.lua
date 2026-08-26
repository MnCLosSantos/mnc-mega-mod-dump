fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Stan Leigh'
description 'MNC Car Transporter - Loading system for tr2 trailer'
version '1.0.0'

dependencies {
    'ox_lib'
}

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