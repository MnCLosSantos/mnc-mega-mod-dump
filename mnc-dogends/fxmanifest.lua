-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'mnc-dogends - Pick up cigarette butts and roll them into cigs'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
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
    'qb-inventory',
    'ox_lib'
}