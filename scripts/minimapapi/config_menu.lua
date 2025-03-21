local MinimapAPI = require("scripts.minimapapi")
local modconfigexists, MCM = pcall(require, "scripts.modconfig")
local configPresetSettings = require("scripts.minimapapi.config_presets")

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
	Controller = Controller or {}
	Controller.DPAD_LEFT = 0
	Controller.DPAD_RIGHT = 1
	Controller.DPAD_UP = 2
	Controller.DPAD_DOWN = 3
	Controller.BUTTON_A = 4
	Controller.BUTTON_B = 5
	Controller.BUTTON_X = 6
	Controller.BUTTON_Y = 7
	Controller.BUMPER_LEFT = 8
	Controller.TRIGGER_LEFT = 9
	Controller.STICK_LEFT = 10
	Controller.BUMPER_RIGHT = 11
	Controller.TRIGGER_RIGHT = 12
	Controller.STICK_RIGHT = 13
	Controller.BUTTON_BACK = 14
	Controller.BUTTON_START = 15

	function MinimapAPI:AddHotkeySetting(category, optionName, displayText, infoText, isController)
		if (type(infoText) == "string") then infoText = {infoText} end
		local optionType = ModConfigMenu.OptionType.KEYBIND_KEYBOARD
		local hotkeyToString = InputHelper.KeyboardToString
		local deviceString = "keyboard"
		local backString = "ESCAPE"
		if isController then
			optionType = ModConfigMenu.OptionType.KEYBIND_CONTROLLER
			hotkeyToString = InputHelper.ControllerToString
			deviceString = "controller"
			backString = "BACK"
		end
		MCM.AddSetting(
			"Minimap API",
			category,
			{
				Type = optionType,
				CurrentSetting = function()
					return MinimapAPI.Config[optionName]
				end,
				Display = function()
					local key = "None"
					if (hotkeyToString[MinimapAPI.Config[optionName]]) then key = hotkeyToString[MinimapAPI.Config[optionName]] end
					return displayText .. ": " .. key
				end,
				OnChange = function(currentNum)
					if not isController and currentNum == nil then
							currentNum = Keyboard.KEY_ENTER
					end

					MinimapAPI.Config[optionName] = currentNum or -1
				end,
				PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
				PopupWidth = 280,
				Popup = function()
					local currentValue = MinimapAPI.Config[optionName]
					local keepSettingString = ""
					if currentValue > -1 then
						local currentSettingString = hotkeyToString[currentValue]
						keepSettingString = "This setting is currently set to \"" .. currentSettingString .. "\".$newlinePress this button to keep it unchanged.$newline$newline"
					end
					return "Press a button on your "..deviceString.." to change this setting.$newline$newline" .. keepSettingString .. "Press "..backString.." to go back and clear this setting."				
				end,
				Info = infoText
			}
		)
	end


	-- START MOD CONFIG MENU --

	MCM.AddText("Minimap API", "Presets", function() return "Mod by Taz and Wofsauge" end)

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
				if configPresetSettings[currentNum] then
					for i,v in pairs(configPresetSettings[currentNum]) do
						MinimapAPI.Config[i] = v
					end
				end
				MinimapAPI:FirstMapDisplayMode()
				MinimapAPI.Config.ConfigPreset = currentNum
				if Game():GetLevel():GetStage() == LevelStage.STAGE7 then
					MinimapAPI:LoadDefaultMap(0)
				end
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
				return "Show Pickup Icons: " .. (MinimapAPI.Config.ShowPickupIcons and "ON" or "OFF")
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
		"Map(1)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowShadows
			end,
			Display = function()
				return "Show Room Outlines: " .. (MinimapAPI.Config.ShowShadows and "ON" or "OFF")
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

	local levelFlagstrings = {"OFF","LEFT","BOTTOM"}
	MCM.AddSetting(
		"Minimap API",
		"Map(1)",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayLevelFlags
			end,
			Minimum = 0,
			Maximum = #levelFlagstrings-1,
			Display = function()
				return "Show Map Effect Icons: " .. levelFlagstrings[MinimapAPI.Config.DisplayLevelFlags+1]
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DisplayLevelFlags = currentNum
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"If enabled, displays the blue map, compass and treasure map icons next to the map"
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
				return "Show Current Room Pickups: " .. (MinimapAPI.Config.ShowCurrentRoomItems and "ON" or "OFF")
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
		"Map(1)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayExploredRooms
			end,
			Display = function()
				return "Show Visited Uncleared Rooms: " .. (MinimapAPI.Config.DisplayExploredRooms and "ON" or "OFF")
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

	local hicstrings = {"Never","Bosses Only","Always"}
	MCM.AddSetting(
		"Minimap API",
		"Map(2)",
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
		"Map(2)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.HideInInvalidRoom
			end,
			Display = function()
				return "Hide Map for Invalid Rooms: " .. (MinimapAPI.Config.HideInInvalidRoom and "ON" or "OFF")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.HideInInvalidRoom = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"When in a room that is not on the map",
				"(ie. devil rooms), the map will not show."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map(2)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowGridDistances
			end,
			Display = function()
				return "Show Room Distances: " .. (MinimapAPI.Config.ShowGridDistances and "ON" or "OFF")
			end,
			OnChange = function(newVal)
				MinimapAPI.Config.ShowGridDistances = newVal
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"Rooms will have their distance",
				"shown on them"
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map(2)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.HighlightStartRoom
			end,
			Display = function()
				return "Highlight Start Room: " .. (MinimapAPI.Config.HighlightStartRoom and "ON" or "OFF")
			end,
			OnChange = function(newVal)
				MinimapAPI.Config.HighlightStartRoom = newVal
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"The starting room will be highlighted when having a map."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map(2)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.HighlightFurthestRoom
			end,
			Display = function()
				return "Highlight Furthest Room: " .. (MinimapAPI.Config.HighlightFurthestRoom and "ON" or "OFF")
			end,
			OnChange = function(newVal)
				MinimapAPI.Config.HighlightFurthestRoom = newVal
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"The room furthest from the starting room",
				"will be highlighted when having a map."
			}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map(2)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.AltSemivisitedSprite
			end,
			Display = function()
				return "Alternate Visited Room Sprite: " .. (MinimapAPI.Config.AltSemivisitedSprite and "ON" or "OFF")
			end,
			OnChange = function(newVal)
				MinimapAPI.Config.AltSemivisitedSprite = newVal
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"Uses an alternate sprite for",
				"\"semivisited\" rooms."
			}
		}
	)
	MCM.AddSetting(
		"Minimap API",
		"Map(2)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.VanillaSecretRoomDisplay
			end,
			Display = function()
				return "Vanilla secretroom display: " .. (MinimapAPI.Config.VanillaSecretRoomDisplay and "ON" or "OFF")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.VanillaSecretRoomDisplay = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {
				"Enable this to display newly discovered",
				"secret rooms as a shadows instead of a normal rooms.",
			}
		}
	)

		MCM.AddSetting(
		"Minimap API",
		"Map(2)",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.OverrideVoid
			end,
			Display = function()
				return "Show true room sizes in The Void: " .. (MinimapAPI.Config.OverrideVoid and "ON" or "OFF")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.OverrideVoid = currentBool
				MinimapAPI.Config.ConfigPreset = 0
				if Game():GetLevel():GetStage() == LevelStage.STAGE7 then
					MinimapAPI:LoadDefaultMap(0) -- use dimension 0 just in case we're in the death certificate dimension
				end
			end,
			Info = {
				"Enable this to easily find Delirium on the map."
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
				return "Toggle Large Map: " .. (MinimapAPI.Config.AllowToggleLargeMap and "ON" or "OFF")
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
				return "Toggle Small Map: " .. (MinimapAPI.Config.AllowToggleSmallMap and "ON" or "OFF")
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
				return "Toggle Bounded Map: " .. (MinimapAPI.Config.AllowToggleBoundedMap and "ON" or "OFF")
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
				return "Toggle No Map: " .. (MinimapAPI.Config.AllowToggleNoMap and "ON" or "OFF")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.AllowToggleNoMap = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Teleport",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.MouseTeleport
			end,
			Display = function()
				return "Map teleportation: " .. (MinimapAPI.Config.MouseTeleport and "ON" or "OFF")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.MouseTeleport = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {"Allows you to teleport by clicking on rooms on the map or by holding down the map button and use directional buttons and confirm to teleport."}
		}
	)
	MinimapAPI:AddHotkeySetting("Modes", "TeleportConfirmKey", "Teleport Confirm (Keyboard)",
		"Press this key to confirm the selected teleport location and teleport to it. Choose A or Escape to reset it back to ENTER", false)
	MinimapAPI:AddHotkeySetting("Modes", "TeleportConfirmButton", "Teleport Confirm (Controller)",
		"Press this key to confirm the selected teleport location and teleport to it.", true)

	MCM.AddSetting(
		"Minimap API",
		"Teleport",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.MouseTeleportDisableMovement
			end,
			Display = function()
				return "Disable movement on map teleport: " .. (MinimapAPI.Config.MouseTeleportDisableMovement and "ON" or "OFF")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.MouseTeleportDisableMovement = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {"Stops you from moving and shooting while in the teleport selection action."}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Teleport",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.MouseTeleportUncleared
			end,
			Display = function()
				return "Teleport Restrictions: " .. (MinimapAPI.Config.MouseTeleportUncleared and "-" or "Only cleared rooms")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.MouseTeleportUncleared = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {"Restricts teleportation to discovered rooms"}
		}
	)
	MCM.AddSetting(
		"Minimap API",
		"Teleport",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.MouseTeleportDamageOnCurseRoom
			end,
			Display = function()
				return "Damage on teleporting to curse room: " .. (MinimapAPI.Config.MouseTeleportDamageOnCurseRoom and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.MouseTeleportDamageOnCurseRoom = currentBool
				MinimapAPI.Config.ConfigPreset = 0
			end,
			Info = {"Damages the player when he teleports into or out of a curse room and doesnt have Flat file, Isaacs heart, Flight or an open Secret room next to the curse room"}
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Map(1)",
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
		"Map(1)",
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
		"Map(1)",
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
		"Map(1)",
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
		"Map(1)",
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

	MCM.AddSetting(
		"Minimap API",
		"Pickups",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.PickupNoGrouping
			end,
			Display = function()
				return "Show Duplicate Pickups: " .. (MinimapAPI.Config.PickupNoGrouping and "ON" or "OFF")
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
				return MinimapAPI.Config.MinimapTransparency
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Minimap Transparency: " .. MinimapAPI.Config.MinimapTransparency
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.MinimapTransparency = currentNum
			end,
			Info = {
				"Changes transparency of the map.","Values other than 1 will cause the room shadow/border to not be rendered to improve visiblity"
			}
		}
	)

	MCM.AddSpace("Minimap API", "Colors")

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

	MCM.AddSpace("Minimap API", "Colors")

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

	MCM.AddSpace("Minimap API", "Colors")

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderColorR
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Border Color Red: " .. MinimapAPI.Config.BorderColorR
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderColorR = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderColorG
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Border Color Green: " .. MinimapAPI.Config.BorderColorG
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderColorG = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderColorB
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Border Color Blue: " .. MinimapAPI.Config.BorderColorB
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderColorB = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderColorA
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Border Color Alpha: " .. MinimapAPI.Config.BorderColorA
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderColorA = currentNum
			end
		}
	)

	MCM.AddSpace("Minimap API", "Colors")

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderBgColorR
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Border Background Color Red: " .. MinimapAPI.Config.BorderBgColorR
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderBgColorR = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderBgColorG
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Border Background Color Green: " .. MinimapAPI.Config.BorderBgColorG
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderBgColorG = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderBgColorB
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Border Background Color Blue: " .. MinimapAPI.Config.BorderBgColorB
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderBgColorB = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.BorderBgColorA
			end,
			Minimum = 0,
			Maximum = 4,
			ModifyBy = 0.1,
			Display = function()
				return "Border Background Color Alpha: " .. MinimapAPI.Config.BorderBgColorA
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.BorderBgColorA = currentNum
			end
		}
	)

	MCM.AddSpace("Minimap API", "Colors")

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.HighlightStartRoomColorR
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Starting Room Color Red: " .. MinimapAPI.Config.HighlightStartRoomColorR
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.HighlightStartRoomColorR = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.HighlightStartRoomColorG
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Starting Room Color Green: " .. MinimapAPI.Config.HighlightStartRoomColorG
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.HighlightStartRoomColorG = currentNum
			end
		}
	)

	MCM.AddSetting(
		"Minimap API",
		"Colors",
		{
			Type = MCM.OptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.HighlightStartRoomColorB
			end,
			Minimum = 0,
			Maximum = 1,
			ModifyBy = 0.1,
			Display = function()
				return "Starting Room Color Blue: " .. MinimapAPI.Config.HighlightStartRoomColorB
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.HighlightStartRoomColorB = currentNum
			end
		}
	)
	----------------------

	MCM.AddSetting(
		"Minimap API",
		"General",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ExternalMap
			end,
			Display = function()
				return "Enable External Map: " .. (MinimapAPI.Config.ExternalMap and "ON" or "OFF")
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
				return "Disable Minimap: " .. (MinimapAPI.Config.Disable and "ON" or "OFF")
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
				return "Display During Curse: " .. (MinimapAPI.Config.OverrideLost and "ON" or "OFF")
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
				return "Display with No HUD Seed: " .. (MinimapAPI.Config.DisplayOnNoHUD and "ON" or "OFF")
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
				return "Show Icons: " .. (MinimapAPI.Config.ShowIcons and "ON" or "OFF")
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

	MCM.AddSpace("Minimap API",	"General")
	MCM.AddSetting(
		"Minimap API",
		"General",
		{
			Type = MCM.OptionType.BOOLEAN,
			CurrentSetting = function()
				return true
			end,
			Display = "<--- Reset map info --->",
			OnChange = function(_)
				MinimapAPI:ClearLevels()
				MinimapAPI:LoadDefaultMap()
				MinimapAPI:updatePlayerPos()
				MinimapAPI:UpdateExternalMap()
			end,
			Info = {
				"Clears the current map informations and reinitializes the map based on available vanilla informations.",
				"Use this to fix the effects caused by crashes"
			}
		}
	)

end
