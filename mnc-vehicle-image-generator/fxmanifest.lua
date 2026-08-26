fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Stan Leigh'
description 'Vehicle Image Generator - Automatic vehicle screenshot capture with Discord webhook integration'
version '1.8.3'

ui_page 'html/index.html'

shared_script 'config.lua'

client_script 'client/client.lua'
server_script 'server/server.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
	'html/logo.png',
    'vehicle-images/*.png',
}

data_file 'DLC_ITYP_REQUEST' 'vehicle-images/*.png' 
dependency 'screenshot-basic'