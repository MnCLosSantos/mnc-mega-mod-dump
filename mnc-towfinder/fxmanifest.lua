fx_version 'cerulean'
game 'gta5'

author 'MNC'
description 'Tow Bar Extra Finder - Scans all QB-Core vehicles for tow bar extras'
version '1.0.0'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
}

dependencies {
    'ox_lib',
    'qb-core',
}
