fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MnCLosSantos'
description 'mnc-handui - Admin model-based vehicle handling editor, saved to SQL'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib',
}
