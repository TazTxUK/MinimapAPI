
if ModConfigMenu then
	local configPresets = {
		"API Default",
		"Vanilla",
		"Beta",
	}
	local configPresetTexts = {
		"Default config options.",
		"A close recreation of the original AB+ map.",
		"The original look of Wofsauge's miniMAPI.",
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
			MinimapAPI.Config.ShowLevelFlags = false
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
		function() --wofsauge
			MinimapAPI.Config.ShowIcons = true
			MinimapAPI.Config.ShowPickupIcons = true
			MinimapAPI.Config.ShowShadows = false
			MinimapAPI.Config.ShowCurrentRoomItems = true
			MinimapAPI.Config.MapFrameWidth = 70
			MinimapAPI.Config.MapFrameHeight = 70
			MinimapAPI.Config.PositionX = 6 
			MinimapAPI.Config.PositionY = 6
			MinimapAPI.Config.DisplayMode = 2
			MinimapAPI.Config.ShowLevelFlags = true
			MinimapAPI.Config.SmoothSlidingSpeed = 1
			MinimapAPI.Config.HideInCombat = 1
			MinimapAPI.Config.OverrideVoid = false
			MinimapAPI.Config.DisplayExploredRooms = false
			MinimapAPI.Config.AllowToggleLargeMap = false
			MinimapAPI.Config.AllowToggleSmallMap = true
			MinimapAPI.Config.AllowToggleBoundedMap = true
			MinimapAPI.Config.AllowToggleNoMap = false
			MinimapAPI.Config.PickupFirstComeFirstServe = true
			MinimapAPI.Config.PickupNoGrouping = false
		end,
	}
	
	ModConfigMenu.AddSpace("Minimap API", "Presets")
	
	ModConfigMenu.AddText("Minimap API", "Presets", function()
		return "Minimap Config Preset:"
	end)
	
	ModConfigMenu.AddSpace("Minimap API", "Presets")
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Presets",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
			end
		}
	)
	
	ModConfigMenu.AddSpace("Minimap API", "Presets")
	
	ModConfigMenu.AddText("Minimap API", "Presets", function()
		return configPresetTexts[MinimapAPI.Config.ConfigPreset]
	end)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowPickupIcons
			end,
			Display = function()
				return "Show Pickup Icons: " .. (MinimapAPI.Config.ShowPickupIcons and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowPickupIcons = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowShadows
			end,
			Display = function()
				return "Show Room Outlines: " .. (MinimapAPI.Config.ShowShadows and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowShadows = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowLevelFlags
			end,
			Display = function()
				return "Show Map Effect Icons: " .. (MinimapAPI.Config.ShowLevelFlags and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowLevelFlags = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowCurrentRoomItems
			end,
			Display = function()
				return "Show Current Room Pickups: " .. (MinimapAPI.Config.ShowCurrentRoomItems and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowCurrentRoomItems = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayExploredRooms
			end,
			Display = function()
				return "Show Visited Uncleared Rooms: " .. (MinimapAPI.Config.DisplayExploredRooms and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.DisplayExploredRooms = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleLargeMap
			end,
			Display = function()
				return "Toggle Large Map: " .. (MinimapAPI.Config.AllowToggleLargeMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleLargeMap = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleSmallMap
			end,
			Display = function()
				return "Toggle Small Map: " .. (MinimapAPI.Config.AllowToggleSmallMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleSmallMap = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleBoundedMap
			end,
			Display = function()
				return "Toggle Bounded Map: " .. (MinimapAPI.Config.AllowToggleBoundedMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleBoundedMap = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Modes",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AllowToggleNoMap
			end,
			Display = function()
				return "Toggle No Map: " .. (MinimapAPI.Config.AllowToggleNoMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleNoMap = currentBool
			end
		}
	)
	
	local hicstrings = {"Never","Bosses Only","Always"}
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Map",
		{
			Type = ModConfigMenuOptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.SmoothSlidingSpeed
			end,
			Minimum = 0.25,
			Maximum = 1,
			ModifyBy = 0.25,
			Display = function()
				return "Smooth Movement Speed: " .. MinimapAPI.Config.SmoothSlidingSpeed
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.SmoothSlidingSpeed = currentNum
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.PickupFirstComeFirstServe
			end,
			Display = function()
				return "Sort Pickups By First Appearing: " .. (MinimapAPI.Config.PickupFirstComeFirstServe and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.PickupFirstComeFirstServe = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.PickupNoGrouping
			end,
			Display = function()
				return "Show Duplicate Pickups: " .. (MinimapAPI.Config.PickupNoGrouping and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.PickupNoGrouping = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ExternalMap
			end,
			Display = function()
				return "Enable External Map: " .. (MinimapAPI.Config.ExternalMap and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ExternalMap = currentBool
				MinimapAPI:UpdateExternalMap()
			end
		}
	)
	
	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.Disable
			end,
			Display = function()
				return "Disable Minimap: " .. (MinimapAPI.Config.Disable and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.Disable = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.OverrideLost
			end,
			Display = function()
				return "Display During Curse: " .. (MinimapAPI.Config.OverrideLost and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.OverrideLost = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayOnNoHUD
			end,
			Display = function()
				return "Display with No HUD Seed: " .. (MinimapAPI.Config.DisplayOnNoHUD and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.DisplayOnNoHUD = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowIcons
			end,
			Display = function()
				return "Show Icons: " .. (MinimapAPI.Config.ShowIcons and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowIcons = currentBool
			end
		}
	)
	
end