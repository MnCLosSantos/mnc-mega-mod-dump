fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh (modified)'
description 'Holiday/Trip teleport system with job/item access and optional vehicle support (QB/OX hybrid)'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

server_script 'server.lua'

lua54 'yes'