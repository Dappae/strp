------
-- InteractSound by Scott
-- Verstion: v0.0.1
------

-- Manifest Version
resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

-- Client Scripts
client_script 'client/main.lua'

-- Server Scripts
server_script 'server/main.lua'

-- NUI Default Page
ui_page('client/html/index.html')

-- Files needed for NUI
-- DON'T FORGET TO ADD THE SOUND FILES TO THIS!
files({
    'client/html/index.html',
    -- Begin Sound Files Here...
    'client/html/sounds/lock.ogg',
    'client/html/sounds/unlock.ogg',
    'client/html/sounds/sms.ogg',
    'client/html/sounds/Anchordown.ogg',
    'client/html/sounds/Anchorup.ogg',
    'client/html/sounds/fishing_catch.ogg',
    'client/html/sounds/fishing_reelin.ogg',
    'client/html/sounds/fishing_start.ogg',
})
