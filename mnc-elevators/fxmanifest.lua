fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'Elevator system with job, item, sound, animation, and progress support (QB/OX hybrid)'
version '1.4.1'

shared_script 'config.lua'

client_scripts {
    '@ox_lib/init.lua',  -- ✅ add this line so lib is available
    'client.lua'
}

server_script 'server.lua'

lua54 'yes'
