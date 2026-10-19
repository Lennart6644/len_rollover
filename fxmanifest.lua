fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Lennart'
description 'len_rollover - Vehicle rollover detection with multilingual glass UI'
version '2.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'locales/locale.lua',
    'locales/de.lua',
    'locales/en.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
