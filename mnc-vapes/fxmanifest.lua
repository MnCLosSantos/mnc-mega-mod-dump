fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'mnc-vapes - Vape devices, juice crafting, placeable station'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua',           -- core vape equip / puff / menus
    'crafting_client.lua',  -- juice crafting UI + portable table
}

server_scripts {
    'server.lua',           -- core vape data, DB, vape management
    'crafting_server.lua',  -- juice crafting + placeable table server logic
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-inventory',
    'ox_lib',
    'oxmysql'
}