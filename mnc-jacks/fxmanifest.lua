fx_version 'cerulean'
game 'gta5'

author      'Stan Leigh'
description 'Car jack & axle stand lift system'
version     '1.1.4'

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

dependencies {
    'ox_lib',
    'qb-core',
}
