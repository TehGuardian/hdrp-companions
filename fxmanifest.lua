fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'hdrp-companions'
version '1.0.2'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'locales/en.lua', -- Change to your language
    'config.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/client.lua',
    'client/client-sell.lua',
	'client/npcs.lua',
	'client/pets.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/server-sell.lua',
    'server/versionchecker.lua',
}

dependencies {
    'rsg-core',
    'rsg-target',
    'ox_lib'
}

this_is_a_map 'yes'

lua54 'yes'

export 'CheckPetLevel'
export 'CheckPetBondingLevel'
export 'CheckActivePet'