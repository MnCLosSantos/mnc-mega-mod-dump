fx_version 'cerulean'
game 'gta5'

author 'mnc'
description 'MNC Admin Menu'
version '2.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
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
    'html/logo.png',
    'html/watermark.png',
}
