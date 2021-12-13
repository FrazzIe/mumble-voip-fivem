config = {
	debug = true,
	eventPrefix = "mumble",
	proximity = {
		{ name = "whisper", input = 3.0, output = 2.5 },
		{ name = "normal", input = 3.0, output = 8.0 },
		{ name = "shouting", input = 3.0, output = 20.0 },
	},
	controls = {
		proximity = { description = "Cycle Proximity", mapper = "keyboard", param = "z" },
		radio = { description = "Talk on radio", mapper = "keyboard", param = "capital" },
	},
	channelInterval = 250,
	uiInterval = 200,
}