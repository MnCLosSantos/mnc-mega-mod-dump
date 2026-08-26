fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Vehicle Drive Type Conversion System'
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