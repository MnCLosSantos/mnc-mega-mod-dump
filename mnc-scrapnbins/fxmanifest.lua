fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'mnc-scrapnbins - Fully dynamic bin & scrap search'
version '2.0.0'

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
    'qb-core'
}