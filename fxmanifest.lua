fx_version 'cerulean'
game 'gta5'

author 'QG Scripts'
description 'QG Markets - Advanced Market System for QBCore'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua',
    'admin_client.lua'
}

server_scripts {
    'server.lua',
    'admin_server.lua'
}

ui_page 'index.html'

files {
    'index.html',
    'style.css',
    'script.js',
    'admin_script.js',
    'wholesaler_script.js'
}

lua54 'yes'