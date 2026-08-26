fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Advanced EMS Mobility Aid System (Crutch, Wheelchair, Cane)'
version '2.1.0'

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
    'qb-target'
}
