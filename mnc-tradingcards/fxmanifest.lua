fx_version 'cerulean'
lua54 'yes'
game 'gta5'

author 'Stan Leigh'
description 'MNC Trading Cards System for QB-Core'
version '1.2.0'

ui_page 'web/index.html'

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

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/images/*.png',
    'web/images/*.jpg',
    'web/images/*.jpeg',
    'web/images/*.webp',
    'web/sounds/*.ogg',
    'web/sounds/*.mp3',
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
}