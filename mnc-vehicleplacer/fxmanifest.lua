fx_version 'cerulean'
game 'gta5'
author 'Stan Leigh'
description 'MNC vehicleplacer'
version '1.0.8'
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