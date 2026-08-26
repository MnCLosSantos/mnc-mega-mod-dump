fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mnc-startingcar'
author 'mnc'
version '1.0.0'
description 'Claim one free starter vehicle out of 3 choices via a pink-slip style signing UI'

dependencies {
    'qb-core',
    'oxmysql',
    'xsound',
}

shared_scripts {
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
    'html/script.js',
    'html/audio.mp3',
    'html/sounds/euro.mp3',
    'html/sounds/jdm.mp3',
    'html/sounds/usdm.mp3',
}