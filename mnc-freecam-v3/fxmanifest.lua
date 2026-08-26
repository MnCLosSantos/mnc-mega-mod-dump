fx_version 'cerulean'
games { 'gta5' }

description 'Free Cam v3'
author 'Stan Leigh'
version '3.0.0'

shared_script  'config.lua'
client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

files {
    'html/index.html',
}

ui_page 'html/index.html'