fx_version 'cerulean'
game 'gta5'

name 'mnc-jobclothing'
author 'Adapted for ox_lib'
description 'Multi-location persistent job clothing system using ox_lib'
version '1.3.0'
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

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'qb-target' -- optional, only if you use qb-target zones
}