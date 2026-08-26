fx_version 'cerulean'
game 'gta5'

author 'Stan Leigh'
description 'mnc-boostpreview - /boostpreview gallery of all mnc-boostgauge styles, bezels & presets + press-E display points'
version '1.0.0'

ui_page 'html/index.html'

shared_script 'config.lua'

client_scripts {
    'client.lua',
}

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
}

dependencies {
    'qb-core',
    'ox_lib',
    'mnc-boostgauge', -- this resource borrows mnc-boostgauge's gauge CSS at runtime via nui://
}