local MinimapAPI = require "scripts.minimapapi"
local modconfigexists, MCM = pcall(require, "scripts.modconfig")

if modconfigexists then
	local configPresets = {
		[0] = "Custom",
		"API Default",
		"Vanilla",
		"All Info",
		"Minimal",
	}
	local configPresetTexts = {
		[0] = "",
		"Default config options.",
		"A close recreation of the original AB+ map.",
		"As much information as possible.",
		"The map is long and thin.",
	}
	local configPresetFuncs = {
		function() --default
			MinimapAPI.Config.ShowIcons = true
			MinimapAPI.Config.ShowPickupIcons = true
			MinimapAPI.Config.ShowShadows = true
			MinimapAPI.Config.ShowCurrentRoomItems = false
			MinimapAPI.Config.MapFrameWidth = 65
			MinimapAPI.Config.MapFrameHeight = 60
			MinimapAPI.Config.PositionX = 4 
			MinimapAPI.Config.PositionY = 4
			MinimapAPI.Config.DisplayMode = 1
			MinimapAPI.Config.ShowLevelFlags = true
			MinimapAPI.Config.SmoothSlidingSpeed = 0.3
			MinimapAPI.Config.HideInCombat = 1
			MinimapAPI.Config.OverrideVoid = false
			MinimapAPI.Config.DisplayExploredRooms = true
			MinimapAPI.Config.AllowToggleLargeMap = true
			MinimapAPI.Config.AllowToggleSmallMap = true
			MinimapAPI.Config.AllowToggleBoundedMap = false
			MinimapAPI.Config.AllowToggleNoMap = false
			MinimapAPI.Config.PickupFirstComeFirstServe = false
			MinimapAPI.Config.PickupNoGrouping = false
		end,
		function() --vanilla
			MinimapAPI.Config.ShowIcons = true
			MinimapAPI.Config.ShowPickupIcons = true
			MinimapAPI.Config.ShowShadows = true
			MinimapAPI.Config.ShowCurrentRoomItems = false
			MinimapAPI.Config.MapFrameWidth = 50
			MinimapAPI.Config.MapFrameHeight = 45
			MinimapAPI.Config.PositionX = 4 
			MinimapAPI.Config.PositionY = 4
			MinimapAPI.Config.DisplayMode = 2
			MinimapAPI.Config.ShowLevelFlags = true
			MinimapAPI.Config.SmoothSlidingSpeed = 1
			MinimapAPI.Config.HideInCombat = 1
			MinimapAPI.Config.OverrideVoid = false
			MinimapAPI.Config.DisplayExploredRooms = false
			MinimapAPI.Config.AllowToggleLargeMap = true
			MinimapAPI.Config.AllowToggleSmallMap = false
			MinimapAPI.Config.AllowToggleBoundedMap = true
			MinimapAPI.Config.AllowToggleNoMap = false
			MinimapAPI.Config.PickupFirstComeFirstServe = false
			MinimapAPI.Config.PickupNoGrouping = false
		end,
		function() --all
			MinimapAPI.Config.ShowIcons = true
			MinimapAPI.Config.ShowPickupIcons = true
			MinimapAPI.Config.ShowShadows = true
			MinimapAPI.Config.ShowCurrentRoomItems = true
			MinimapAPI.Config.MapFrameWidth = 75
			MinimapAPI.Config.MapFrameHeight = 70
			MinimapAPI.Config.PositionX = 2 
			MinimapAPI.Config.PositionY = 2
			MinimapAPI.Config.DisplayMode = 1
			MinimapAPI.Config.ShowLevelFlags = true
			MinimapAPI.Config.SmoothSlidingSpeed = 0.3
			MinimapAPI.Config.HideInCombat = 1
			MinimapAPI.Config.OverrideVoid = false
			MinimapAPI.Config.DisplayExploredRooms = true
			MinimapAPI.Config.AllowToggleLargeMap = true
			MinimapAPI.Config.AllowToggleSmallMap = true
			MinimapAPI.Config.AllowToggleBoundedMap = true
			MinimapAPI.Config.AllowToggleNoMap = false
			MinimapAPI.Config.PickupFirstComeFirstServe = false
			MinimapAPI.Config.PickupNoGrouping = true
		end,
		function()
			MinimapAPI.Config.ShowIcons = true
			MinimapAPI.Config.ShowPickupIcons = false
			MinimapAPI.Config.ShowShadows = true
			MinimapAPI.Config.ShowCurrentRoomItems = false
			MinimapAPI.Config.MapFrameWidth = 85
			MinimapAPI.Config.MapFrameHeight = 45
			MinimapAPI.Config.PositionX = 2 
			MinimapAPI.Config.PositionY = 2
			MinimapAPI.Config.DisplayMode = 2
			MinimapAPI.Config.ShowLevelFlags = false
			MinimapAPI.Config.SmoothSlidingSpeed = 0.3
			MinimapAPI.Config.HideInCombat = 1
			MinimapAPI.Config.OverrideVoid = false
			MinimapAPI.Config.DisplayExploredRooms = true
			MinimapAPI.Config.AllowToggleLargeMap = false
			MinimapAPI.Config.AllowToggleSmallMap = true
			MinimapAPI.Config.AllowToggleBoundedMap = true
			MinimapAPI.Config.AllowToggleNoMap = false
			MinimapAPI.Config.PickupFirstComeFirstServe = false
			MinimapAPI.Config.PickupNoGrouping = false
		end,
	}
	
	MCM.AddSpace("Minimap API", "Presets")
	
	MCM.AddText("Minimap API", "Presets", function()
		return "Minimap Config Preset:"
	end)
	
	MCM.AddSpace("Minimap API", "Presets")
	
	MCM.AddSetting(
		"Minimap API",
		"Presets",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.ConfigPreset
			end,
			Minimum = 1,
			Maximum = #configPresets,
			Display = function()
				return configPresets[MinimapAPI.Config.ConfigPreset]
			end,
			OnChange = function(currentNum)
				if configPresetFuncs[currentNum] then
					configPresetFuncs[currentNum]()
				end
				MinimapAPI.Config.ConfigPreset = currentNum
			end,
		}
	)
	
	MCM.AddSpace("Minimap API", "Presets")
	
	MCM.AddText("Minimap API", "Presets", function()
		return configPresetTexts[MinimapAPI.Config.ConfigPreset]
	end)

	MCM.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowPickupIcons
			end,
			Display = function()
				return "Show Pickup Icons: " .. (MinimapAPI.Config.ShowPickupIcons and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowPickupIcons = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"If true, pickup icons like hearts will be visible."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowShadows
			end,
			Display = function()
				return "Show Room Outlines: " .. (MinimapAPI.Config.ShowShadows and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowShadows = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"If true, the dark room outlines will show."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowLevelFlags
			end,
			Display = function()
				return "Show Map Effect Icons: " .. (MinimapAPI.Config.ShowLevelFlags and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowLevelFlags = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"If true, the blue map, compass and treasure map",
				"icons will show when the effect is active."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowCurrentRoomItems
			end,
			Display = function()
				return "Show Current Room Pickups: " .. (MinimapAPI.Config.ShowCurrentRoomItems and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowCurrentRoomItems = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"If true, pickup icons will show even if Isaac",
				"is in the same room."
			}
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayExploredRooms
			end,
			Display = function()
				return "Show Visited Uncleared Rooms: " .. (MinimapAPI.Config.DisplayExploredRooms and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.DisplayExploredRooms = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"If true, rooms that have been seen but not",
				"cleared are shown as a checkerboard pattern."
			}
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleLargeMap
			end,
			Display = function()
				return "Toggle Large Map: " .. (MinimapAPI.Config.AllowToggleLargeMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleLargeMap = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleSmallMap
			end,
			Display = function()
				return "Toggle Small Map: " .. (MinimapAPI.Config.AllowToggleSmallMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleSmallMap = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleBoundedMap
			end,
			Display = function()
				return "Toggle Bounded Map: " .. (MinimapAPI.Config.AllowToggleBoundedMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleBoundedMap = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleNoMap
			end,
			Display = function()
				return "Toggle No Map: " .. (MinimapAPI.Config.AllowToggleNoMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleNoMap = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end
		}
	)
	
	local hicstrings = {"Never","Bosses Only","Always"}
	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.HideInCombat
			end,
			Minimum = 1,
			Maximum = 3,
			Display = function()
				return "Hide Map in Combat: " .. hicstrings[MinimapAPI.Config.HideInCombat]
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.HideInCombat = currentNum
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"The map will be hidden when in an uncleared room."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.MapFrameWidth
			end,
			Minimum = 10,
			Maximum = 200,
			ModifyBy = 5,
			Display = function()
				return "Bounded Map Width: " .. MinimapAPI.Config.MapFrameWidth
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.MapFrameWidth = currentNum
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"The border map's width."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.MapFrameHeight
			end,
			Minimum = 10,
			Maximum = 200,
			ModifyBy = 5,
			Display = function()
				return "Bounded Map Height: " .. MinimapAPI.Config.MapFrameHeight
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.MapFrameHeight = currentNum
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"The border map's height."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.PositionX
			end,
			Minimum = 0,
			Maximum = 80,
			ModifyBy = 2,
			Display = function()
				return "Position X: " .. MinimapAPI.Config.PositionX
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.PositionX = currentNum
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"The map's horizontal distance from the top",
				"right of the screen."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.PositionY
			end,
			Minimum = 0,
			Maximum = 80,
			ModifyBy = 2,
			Display = function()
				return "Position Y: " .. MinimapAPI.Config.PositionY
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.PositionY = currentNum
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"The map's vertical distance from the top",
				"right of the screen."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.SmoothSlidingSpeed
			end,
			Minimum = 0.1,
			Maximum = 1,
			ModifyBy = 0.05,
			Display = function()
				return "Map Interpolation: " .. MinimapAPI.Config.SmoothSlidingSpeed
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.SmoothSlidingSpeed = currentNum
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"How quickly the map moves. 1.0 = instant",
				"0.1 = very slow."
			}
		}
	)
	
	-- MCM.AddSetting(
		-- "Minimap API",
		-- "Pickups",
		-- {
			-- Type = MCM.OptionType.BOOLEAN,
			-- CurrentSetting = function()
				-- return MinimapAPI.Config.PickupFirstComeFirstServe
			-- end,
			-- Display = function()
				-- return "Sort Pickups By First Appearing: " .. (MinimapAPI.Config.PickupFirstComeFirstServe and "True" or "False")
			-- end,
			-- OnChange = function(currentBool)
				-- MinimapAPI.Config.PickupFirstComeFirstServe = currentBool
			-- end
		-- }
	-- )
	
	MCM.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.PickupNoGrouping
			end,
			Display = function()
				return "Show Duplicate Pickups: " .. (MinimapAPI.Config.PickupNoGrouping and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.PickupNoGrouping = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"Two of the same pickup can show up on",
				"the map as icons."
			}
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DefaultRoomColorR
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Room Color Red: " .. MinimapAPI.Config.DefaultRoomColorR
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DefaultRoomColorR = currentNum
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DefaultRoomColorG
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Room Color Green: " .. MinimapAPI.Config.DefaultRoomColorG
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DefaultRoomColorG = currentNum
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DefaultRoomColorB
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Room Color Blue: " .. MinimapAPI.Config.DefaultRoomColorB
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DefaultRoomColorB = currentNum
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DefaultOutlineColorR
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Outline Color Red: " .. MinimapAPI.Config.DefaultOutlineColorR
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DefaultOutlineColorR = currentNum
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DefaultOutlineColorG
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Outline Color Green: " .. MinimapAPI.Config.DefaultOutlineColorG
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DefaultOutlineColorG = currentNum
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DefaultOutlineColorB
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Outline Color Blue: " .. MinimapAPI.Config.DefaultOutlineColorB
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DefaultOutlineColorB = currentNum
			end
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"General",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ExternalMap
			end,
			Display = function()
				return "Enable External Map: " .. (MinimapAPI.Config.ExternalMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ExternalMap = currentBool
				MinimapAPI:UpdateExternalMap()
			end,
			Info = {
				"Enables output of the map's state into the log.",
				"Use in conjunction with external map."
			}
		}
	)
	
	MCM.AddSetting(
		"Minimap API",
		"General",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.Disable
			end,
			Display = function()
				return "Disable Minimap: " .. (MinimapAPI.Config.Disable and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.Disable = currentBool
			end,
			Info = {
				"Removes the minimap entirely."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"General",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.OverrideLost
			end,
			Display = function()
				return "Display During Curse: " .. (MinimapAPI.Config.OverrideLost and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.OverrideLost = currentBool
			end,
			Info = {
				"Forces map to show even when Curse of",
				"the Lost is active."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"General",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayOnNoHUD
			end,
			Display = function()
				return "Display with No HUD Seed: " .. (MinimapAPI.Config.DisplayOnNoHUD and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.DisplayOnNoHUD = currentBool
			end,
			Info = {
				"Forces map to show even when the No HUD",
				"seed is active."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"General",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowIcons
			end,
			Display = function()
				return "Show Icons: " .. (MinimapAPI.Config.ShowIcons and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowIcons = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"Setting this to false will hide",
				"all icons."
			}
		}
	)
	
end