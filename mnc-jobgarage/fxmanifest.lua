fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Stan Leigh'
description 'Advanced Job Garage System'
version '1.4.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
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
    'html/app.js',
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'qb-target',
}