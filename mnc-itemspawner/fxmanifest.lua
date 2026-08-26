fx_version 'cerulean'
lua54 'yes'
game 'gta5'

author 'Stan Leigh'
description 'MNC Item Spawner for QB-Core'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

files {
    'web/*',
    'web/**/*.png',
    'web/**/*.css',
}

dependencies {
    'qb-core',
    'ox_lib',
}