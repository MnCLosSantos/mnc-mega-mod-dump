fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'car remove commands for QBCore'
version '1.4.7'

lua54 'yes'

shared_script '@qb-core/shared/locale.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql'
}