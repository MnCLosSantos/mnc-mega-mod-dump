fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Stan Leigh'
description 'Vehicle Info Editor and Saver V2'
version '2.3.7'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css'
}

client_script 'client.lua'
server_script 'server.lua'

dependency 'ox_lib'