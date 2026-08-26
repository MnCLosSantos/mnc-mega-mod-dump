fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Advanced givecar command for QBCore (supports Tebex, ox_lib notifies, and garage detection)'
version '1.3.1'

lua54 'yes'

shared_script '@qb-core/shared/locale.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    '@ox_lib/init.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql'
}