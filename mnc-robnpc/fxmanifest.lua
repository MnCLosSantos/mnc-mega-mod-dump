fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Rob Npc'
version '1.1.0'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'qb-target',
    'ox_lib'
}

lua54 'yes'