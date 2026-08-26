fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'mnc-boostgauge - QBCore boost gauge with 25 styles, remap aware'
version '2.4.7'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'config_removal.lua', 
}

client_scripts {
    'client.lua',
	'client_items.lua',
    'client_removal.lua', 
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
    'server_items.lua',
    'server_removal.lua',
}

files {
    'html/index.html',
    'html/script.js',
    'html/style.css'
}

dependencies {
    'qb-core',
    'ox_lib',
    'mnc-performanceparts' -- optional
}