fx_version 'cerulean'
game 'gta5'

name 'mnc-gruppe6'
author 'Stan Leigh'
description 'Gruppe 6 Collection Job for QB-Core'
version '2.2.0'

shared_scripts {
    '@ox_lib/init.lua',      
    'config.lua',
    'uniforms.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/CircleZone.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/lockscreen.png',
    'html/sechs.png',
    'html/sechslogo.png'
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-menu',
    'ox_lib' 
}