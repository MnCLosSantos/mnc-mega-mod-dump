-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Vehicle Differential System (Welded & LSD)'
version '1.0.0'
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