fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'mnc-parking - Persistent vehicle parking with cover system'
version '1.5.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua',
    'cover_client.lua',
    'vip_client.lua', 
    'trailer_client.lua',	
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'vip_server.lua',  
    'server.lua',
    'cover_server.lua',
}