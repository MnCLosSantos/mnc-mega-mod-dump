fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Food Vans'
version '1.3.6'

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

lua54 'yes'
