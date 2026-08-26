fx_version 'cerulean'
game 'gta5'

author 'Stan leigh'
description 'Vehicle Insurance, Registration, and Inspection System'
version '1.2.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png',
    'html/logo2.png',
    'html/logo3.png'
}

client_scripts {
    'client.lua'
}

shared_scripts {
    'config.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'ox_lib'
}