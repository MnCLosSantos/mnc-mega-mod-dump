fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Vehicle Anti-Lag / Exhaust Flame System'
version '1.0.0'
lua54 'yes'

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

-- OGG sound files served via NUI
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/sounds/*.ogg',
}