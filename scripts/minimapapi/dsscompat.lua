local MinimapAPI = require("scripts.minimapapi")
local json = require("json")
local configPresetSettings = require("scripts.minimapapi.config_presets")

-- Do not add DSS on our side (wouldn't really make sense to support MCM
-- otherwise) but add a way for dependent mods to add MinimapAPI config to DSS
-- Added since integration in Rev, for consistency

-- run only once in case more dependents mod call it
local AddedDSSMenu = false

local EditedProviders = {}

function MinimapAPI:AddDSSMenu(DSSModName, dssmod, MenuProvider)
    if not EditedProviders[DSSModName] then
        EditedProviders[DSSModName] = true

       -- Hijack save data of provided menu to save minimapapi data,
        -- in case it isn't already handled by dependent mod
        -- (ie it's the standalone version)
        if not MinimapAPI.DisableSaving then
            local prevSaveDataFun = MenuProvider.SaveSaveData
            function MenuProvider.SaveSaveData()
                prevSaveDataFun()
                MinimapAPI:SaveData(json.encode(MinimapAPI:GetSaveTable()))
            end
        end
    end

    if AddedDSSMenu then
        return
    end

	local configPresets = {
		"custom",
		"api default",
		"vanilla",
		"all info",
		"minimal",
	}
	local configPresetTexts = {
		{ "manual", "custom", "settings" },
		{ "default mod", "config", "options" },
		{ "a close", "recreation", "of the", "original", "isaac map" },
		{ "as much", "information", "as possible" },
		{ "the map", "is long", "and thin" },
	}

    local JustChangedPreset = false

    local function ResetPresetIfChanged(saveVar, var)
        if saveVar ~= var and not JustChangedPreset then
            MinimapAPI.Config.ConfigPreset = 0
        end
    end

    local menuDirectory = {
        --LEVEL 1
        main = {
            title = 'minimapapi',
            buttons = {
                {str = 'resume game', action = 'resume'},
                {str = 'settings', dest = 'settings'},
                {str = 'presets', dest = 'presets'},
                {str = 'minimapapi info', dest = 'info'},
            },
            tooltip = dssmod.menuOpenToolTip
        },
        presets = {
            title = 'presets',
            buttons = {
                {
                    str = 'preset',
                    variable = "ConfigPreset",
                    choices = configPresets,
                    tooltip = {strset = {''}},
                    setting = 1,
                    update = function(button, item, tbl)
                        button.tooltip.strset = configPresetTexts[button.setting]
                    end,
                    load = function()
                        return MinimapAPI.Config.ConfigPreset + 1
                    end,
                    store = function(var)
                        MinimapAPI.Config.ConfigPreset = var - 1

                        if configPresetSettings[MinimapAPI.Config.ConfigPreset] then
                            for i,v in pairs(configPresetSettings[MinimapAPI.Config.ConfigPreset]) do
                                MinimapAPI.Config[i] = v
                            end
                        end
                        MinimapAPI:FirstMapDisplayMode()
                        if Game():GetLevel():GetStage() == LevelStage.STAGE7 then
                            MinimapAPI:LoadDefaultMap(0)
                        end
                    end,
                },
                {str = ''},
                {str = 'presets for'},
                {str = 'map settings'},
            },
            tooltip = dssmod.menuOpenToolTip
        },
        settings = {
            title = 'settings',
            buttons = {
                {str = 'general', dest = 'general'},
                {str = 'pickups', dest = 'pickups'},
                {str = 'map', dest = 'map'},
                {str = 'modes', dest = 'modes'},
                {str = 'colors', dest = 'colors'},

                dssmod.gamepadToggleButton,
                dssmod.menuKeybindButton,
                dssmod.paletteButton,
                dssmod.menuHintButton,
                dssmod.menuBuzzerButton,
            },
            tooltip = dssmod.menuOpenToolTip
        },
        general = {
            title = "general settings",
            buttons = {
                {
                    str = 'external map',
                    choices = {'on', 'off'},
                    setting = 2,
                    tooltip = {strset = {'output map', 'state into', 'the log, for', 'use by', 'external', 'maps' }},
                    variable = 'ExternalMap',
                    load = function()
                        return MinimapAPI.Config.ExternalMap and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.ExternalMap = var == 1
                        MinimapAPI:UpdateExternalMap()
                    end
                },
                {
                    str = 'disable map',
                    choices = {'on', 'off'},
                    setting = 2,
                    tooltip = {strset = {'removes the', 'minimap', 'entirely' }},
                    variable = 'Disable',
                    load = function()
                        return MinimapAPI.Config.Disable and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.Disable = var == 1
                    end
                },
                {
                    str = 'enable with lost',
                    choices = {'on', 'off'},
                    setting = 2,
                    tooltip = {strset = {'forces map to', 'show with', 'curse of the', 'lost active' }},
                    variable = 'OverrideLost',
                    load = function()
                        return MinimapAPI.Config.OverrideLost and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.OverrideLost = var == 1
                    end
                },
                {
                    str = 'enable with seed',
                    choices = {'on', 'off'},
                    setting = 2,
                    tooltip = {strset = {'forces map to', 'show even', 'with no hud', 'seed' }},
                    variable = 'DisplayOnNoHUD',
                    load = function()
                        return MinimapAPI.Config.DisplayOnNoHUD and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.DisplayOnNoHUD = var == 1
                    end
                },
                {
                    str = 'show icons',
                    choices = {'on', 'off'},
                    setting = 1,
                    tooltip = {strset = {'off:', 'hide all icons' }},
                    variable = 'ShowIcons',
                    load = function()
                        return MinimapAPI.Config.ShowIcons and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.ShowIcons = var == 1
                    end
                },
                {
                    str = ''
                },
                {
                    str = 'reset map info',
                    tooltip = {strset = {'clears current', 'map data and', 'reinitialize', 'it, use to', 'fix crash', 'effects' }},
                    func = function()
                        MinimapAPI:ClearLevels()
                        MinimapAPI:LoadDefaultMap()
                        MinimapAPI:updatePlayerPos()
                        MinimapAPI:UpdateExternalMap()
                    end,
                },
            },
            tooltip = dssmod.menuOpenToolTip,
        },
        pickups = {
            title = 'pickup settings',
            buttons = {
                {
                    str = 'pickup icons',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'show pickup', 'icons' }},
                    variable = 'PickupIcons',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.ShowPickupIcons and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.ShowPickupIcons, var == 1)
                        MinimapAPI.Config.ShowPickupIcons = var == 1
                    end
                },
                {
                    str = 'current room icons',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'show pickup', 'icons even if', 'isaac is in', 'the current', 'room' }},
                    variable = 'ShowCurrentRoomItems',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.ShowCurrentRoomItems and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.ShowCurrentRoomItems = var == 1
                    end
                },
                {
                    str = 'duplicate icons',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'show pickup', 'icons multiple', 'times if more', 'are in the', 'room' }},
                    variable = 'PickupNoGrouping',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.PickupNoGrouping and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.PickupNoGrouping, var == 1)
                        MinimapAPI.Config.PickupNoGrouping = var == 1
                    end
                },
            },
            tooltip = dssmod.menuOpenToolTip,
        },
        map = {
            title = 'map settings',
            buttons = {
                {
                    str = 'room outlines',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'show dark', 'room outlines' }},
                    variable = 'ShowShadows',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.ShowShadows and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.ShowShadows, var == 1)
                        MinimapAPI.Config.ShowShadows = var == 1
                    end
                },
                {
                    str = 'map effect icons',
                    choices = {'off', 'left', 'bottom'},
                    tooltip = {strset = {'blue map,', 'compass and', 'treasure map', 'icons' }},
                    variable = 'ShowShadows',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.DisplayLevelFlags
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.DisplayLevelFlags, var)
                        MinimapAPI.Config.DisplayLevelFlags = var
                    end,
                },
                {
                    str = 'show unclr vstd',
                    size = 1,
                    choices = {'on', 'off'},
                    tooltip = {strset = {'seen but not', 'cleared rooms', 'will show as', 'checkerboard', 'pattern' }},
                    variable = 'ShowShadows',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.DisplayExploredRooms and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.DisplayExploredRooms, var == 1)
                        MinimapAPI.Config.DisplayExploredRooms = var == 1
                    end,
                },
                {
                    str = 'bounded map width',
                    min = 10,
                    max = 100,
                    increment = 5,
                    setting = 50,
                    variable = "MapFrameWidth",
                    tooltip = {strset = {'border map\'s', 'width' }},
                    load = function()
                        return MinimapAPI.Config.MapFrameWidth
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.MapFrameWidth, var)
                        MinimapAPI.Config.MapFrameWidth = var
                    end,
                },
                {
                    str = 'bounded map height',
                    min = 10,
                    max = 100,
                    increment = 5,
                    setting = 50,
                    variable = "MapFrameHeight",
                    tooltip = {strset = {'border map\'s', 'height' }},
                    load = function()
                        return MinimapAPI.Config.MapFrameHeight
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.MapFrameHeight, var)
                        MinimapAPI.Config.MapFrameHeight = var
                    end,
                },
                {
                    str = 'position x',
                    min = 0,
                    max = 100,
                    increment = 2,
                    setting = 10,
                    variable = "PositionX",
                    tooltip = {strset = {'horizontal', 'distance from', 'top right of', 'the screen' }},
                    load = function()
                        return MinimapAPI.Config.PositionX
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.PositionX, var)
                        MinimapAPI.Config.PositionX = var
                    end,
                },
                {
                    str = 'position y',
                    min = 0,
                    max = 100,
                    increment = 2,
                    setting = 10,
                    variable = "PositionY",
                    tooltip = {strset = {'vertical', 'distance from', 'top right of', 'the screen' }},
                    load = function()
                        return MinimapAPI.Config.PositionY
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.PositionY, var)
                        MinimapAPI.Config.PositionY = var
                    end,
                },
                {
                    str = 'map interpolation',
                    min = 0.1,
                    max = 1,
                    increment = 0.05,
                    setting = 0.5,
                    variable = "SmoothSlidingSpeed",
                    tooltip = {strset = {'how quickly', 'the map moves'}},
                    load = function()
                        return MinimapAPI.Config.SmoothSlidingSpeed
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.SmoothSlidingSpeed, var)
                        MinimapAPI.Config.SmoothSlidingSpeed = var
                    end,
                },
                -- Map 2 section
                {
                    str = 'hide in combat',
                    choices = {'never', 'bosses only', 'always'},
                    tooltip = {strset = {'hide map', 'in uncleared', 'rooms' }},
                    variable = 'HideInCombat',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.HideInCombat
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.HideInCombat, var)
                        MinimapAPI.Config.HideInCombat = var
                    end,
                },
                {
                    str = 'hide outside',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'hide map', 'in rooms', 'not on the', 'map (ie.', 'devil rooms)' }},
                    variable = 'HideInInvalidRoom',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.HideInInvalidRoom and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.HideInInvalidRoom, var == 1)
                        MinimapAPI.Config.HideInInvalidRoom = var == 1
                    end,
                },
                {
                    str = 'room distance',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'rooms will', 'have their', 'distance shown' }},
                    variable = 'ShowGridDistances',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.ShowGridDistances and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.ShowGridDistances, var == 1)
                        MinimapAPI.Config.ShowGridDistances = var == 1
                    end,
                },
                {
                    str = 'highlight start',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'starting room', 'will be', 'highlighted' }},
                    variable = 'HighlightStartRoom',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.HighlightStartRoom and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.HighlightStartRoom, var == 1)
                        MinimapAPI.Config.HighlightStartRoom = var == 1
                    end,
                },
                {
                    str = 'highlight far',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'furthest room', 'from start', 'will be', 'highlighted'}},
                    variable = 'HighlightFurthestRoom',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.HighlightFurthestRoom and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.HighlightFurthestRoom, var == 1)
                        MinimapAPI.Config.HighlightFurthestRoom = var == 1
                    end,
                },
                {
                    str = 'alt visited',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'alternate', 'sprite for', 'semivisited', 'rooms' }},
                    variable = 'AltSemivisitedSprite',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.AltSemivisitedSprite and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.AltSemivisitedSprite, var == 1)
                        MinimapAPI.Config.AltSemivisitedSprite = var == 1
                    end,
                },
                {
                    str = 'secret shadows',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'discovered', 'secret rooms', 'show as', 'shadows', 'instead of', 'normal rooms' }},
                    variable = 'VanillaSecretRoomDisplay',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.VanillaSecretRoomDisplay and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.VanillaSecretRoomDisplay, var == 1)
                        MinimapAPI.Config.VanillaSecretRoomDisplay = var == 1
                    end,
                },
                {
                    str = 'true room sizes',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'show', 'true room', 'sizes in', 'the void', 'to easily', 'find', 'delirium' }},
                    variable = 'OverrideVoid',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.OverrideVoid and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.OverrideVoid, var == 1)
                        MinimapAPI.Config.OverrideVoid = var == 1
                        if Game():GetLevel():GetStage() == LevelStage.STAGE7 then
                            MinimapAPI:LoadDefaultMap(0)
                        end
                    end,
                },
            },
            tooltip = dssmod.menuOpenToolTip,
        },
        modes = {
            title = 'mode settings',
            buttons = {
                {
                    str = 'toggle large',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'allow toggle', 'large map' }},
                    variable = 'AllowToggleLargeMap',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.AllowToggleLargeMap and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.AllowToggleLargeMap, var == 1)
                        MinimapAPI.Config.AllowToggleLargeMap = var == 1
                    end
                },
                {
                    str = 'toggle small',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'allow toggle', 'small map' }},
                    variable = 'AllowToggleSmallMap',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.AllowToggleSmallMap and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.AllowToggleSmallMap, var == 1)
                        MinimapAPI.Config.AllowToggleSmallMap = var == 1
                    end
                },
                {
                    str = 'toggle bounded',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'allow toggle', 'bounded map' }},
                    variable = 'AllowToggleBoundedMap',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.AllowToggleBoundedMap and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.AllowToggleBoundedMap, var == 1)
                        MinimapAPI.Config.AllowToggleBoundedMap = var == 1
                    end
                },
                {
                    str = 'toggle none',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'allow toggle', 'no map' }},
                    variable = 'AllowToggleNoMap',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.AllowToggleNoMap and 1 or 2
                    end,
                    store = function(var)
                        ResetPresetIfChanged(MinimapAPI.Config.AllowToggleNoMap, var == 1)
                        MinimapAPI.Config.AllowToggleNoMap = var == 1
                    end
                },
                {
                    str = 'mouse teleport',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'allows to', 'teleport by', 'clicking on', 'rooms on', 'the map' }},
                    variable = 'MouseTeleport',
                    setting = 2,
                    load = function()
                        return MinimapAPI.Config.MouseTeleport and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.MouseTeleport = var == 1
                    end
                },
                {
                    str = 'restrict teleport',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'restricts', 'teleport', 'to cleared', 'rooms' }},
                    variable = 'MouseTeleportUncleared',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.MouseTeleportUncleared and 2 or 1
                    end,
                    store = function(var)
                        MinimapAPI.Config.MouseTeleportUncleared = var == 2
                    end
                },
                {
                    str = 'teleport curse dmg',
                    choices = {'on', 'off'},
                    tooltip = {strset = {'damage on', 'teleport', 'to curse', 'rooms' }},
                    variable = 'MouseTeleportDamageOnCurseRoom',
                    setting = 1,
                    load = function()
                        return MinimapAPI.Config.MouseTeleportDamageOnCurseRoom and 1 or 2
                    end,
                    store = function(var)
                        MinimapAPI.Config.MouseTeleportDamageOnCurseRoom = var == 1
                    end
                },
            },
            tooltip = dssmod.menuOpenToolTip,
        },
        colors = {
            title = 'color settings',
            buttons = {
                {
                    str = 'map transparency',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 1,
                    tooltip = {strset = {'values other', 'than 1', 'will hide', 'room borders', 'to improve', 'visibility' }},
                    variable = 'MinimapTransparency',
                    load = function()
                        return MinimapAPI.Config.MinimapTransparency
                    end,
                    store = function(var)
                        MinimapAPI.Config.MinimapTransparency = var
                    end
                },
                {
                    str = 'room color r',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'DefaultRoomColorR',
                    load = function()
                        return MinimapAPI.Config.DefaultRoomColorR
                    end,
                    store = function(var)
                        MinimapAPI.Config.DefaultRoomColorR = var
                    end
                },
                {
                    str = 'room color g',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'DefaultRoomColorG',
                    load = function()
                        return MinimapAPI.Config.DefaultRoomColorG
                    end,
                    store = function(var)
                        MinimapAPI.Config.DefaultRoomColorG = var
                    end
                },
                {
                    str = 'room color b',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'DefaultRoomColorB',
                    load = function()
                        return MinimapAPI.Config.DefaultRoomColorB
                    end,
                    store = function(var)
                        MinimapAPI.Config.DefaultRoomColorB = var
                    end
                },
                {
                    str = 'outline color r',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'DefaultOutlineColorR',
                    load = function()
                        return MinimapAPI.Config.DefaultOutlineColorR
                    end,
                    store = function(var)
                        MinimapAPI.Config.DefaultOutlineColorR = var
                    end
                },
                {
                    str = 'outline color g',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'DefaultOutlineColorG',
                    load = function()
                        return MinimapAPI.Config.DefaultOutlineColorG
                    end,
                    store = function(var)
                        MinimapAPI.Config.DefaultOutlineColorG = var
                    end
                },
                {
                    str = 'outline color b',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'DefaultOutlineColorB',
                    load = function()
                        return MinimapAPI.Config.DefaultOutlineColorB
                    end,
                    store = function(var)
                        MinimapAPI.Config.DefaultOutlineColorB = var
                    end
                },
                {
                    str = 'border color r',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'BorderColorR',
                    load = function()
                        return MinimapAPI.Config.BorderColorR
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderColorR = var
                    end
                },
                {
                    str = 'border color g',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'BorderColorG',
                    load = function()
                        return MinimapAPI.Config.BorderColorG
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderColorG = var
                    end
                },
                {
                    str = 'border color b',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'BorderColorB',
                    load = function()
                        return MinimapAPI.Config.BorderColorB
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderColorB = var
                    end
                },
                {
                    str = 'border color a',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 1,
                    variable = 'BorderColorA',
                    load = function()
                        return MinimapAPI.Config.BorderColorA
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderColorA = var
                    end
                },
                {
                    str = 'border bg r',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'BorderBgColorR',
                    load = function()
                        return MinimapAPI.Config.BorderBgColorR
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderBgColorR = var
                    end
                },
                {
                    str = 'border bg g',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'BorderBgColorG',
                    load = function()
                        return MinimapAPI.Config.BorderBgColorG
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderBgColorG = var
                    end
                },
                {
                    str = 'border bg b',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 0.9,
                    variable = 'BorderBgColorB',
                    load = function()
                        return MinimapAPI.Config.BorderBgColorB
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderBgColorB = var
                    end
                },
                {
                    str = 'border bg a',
                    min = 0,
                    max = 1,
                    increment = 0.1,
                    setting = 1,
                    variable = 'BorderBgColorA',
                    load = function()
                        return MinimapAPI.Config.BorderBgColorA
                    end,
                    store = function(var)
                        MinimapAPI.Config.BorderBgColorA = var
                    end
                },
            },
            tooltip = dssmod.menuOpenToolTip,
        },
        info = {
            title = 'minimapapi info',
            fsize = 2,
            nocursor = true,
            scroller = true,
            buttons = {
                {str = 'minimapapi', clr = 3},
                {str = 'adds more map icons'},
                {str = 'and allows mods to'},
                {str = 'add their own'},
                {str = 'plus other features'},
                {str = ''},
                {str = 'you can change visual'},
                {str = 'presets in the settings'},
                {str = ''},
                {str = 'for technical reasons'},
                {str = 'the minimap cannot be'},
                {str = 'at partial trasparency'},
            },
            tooltip = dssmod.menuOpenToolTip
        },
    }

    local menuDirectoryKey = {
        Item = menuDirectory.main,
        Main = 'main',
        Idle = false,
        MaskAlpha = 1,
        Settings = {},
        SettingsChanged = false,
        Path = {},
    }

    DeadSeaScrollsMenu.AddMenu("MinimapAPI", {
        Run = dssmod.runMenu,
        Open = dssmod.openMenu,
        Close = dssmod.closeMenu,
        Directory = menuDirectory,
        DirectoryKey = menuDirectoryKey,
    })

    AddedDSSMenu = true
end
