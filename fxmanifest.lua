fx_version "cerulean"
games { "gta5" }

author "Fraser Watt (https://github.com/FrazzIe)"
description "A manager for FiveM's implementation of mumble-voip"
version "1.6"

lua54 "yes"

ui_page ""
files {}

shared_scripts {
	"sh_config.lua",
	"sh_grid.lua",
}
client_scripts {
	"cl_data.lua",
	"cl_debug.lua",
}
server_scripts {}