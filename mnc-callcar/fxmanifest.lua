fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'mnc-callcar - Call your vehicle with valet service'
version '1.0.0'

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
