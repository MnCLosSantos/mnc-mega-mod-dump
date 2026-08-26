fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MNC'
description 'mnc-extrafix - Automatically fixes/repairs trailers when an extra is toggled, synced to all clients'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
