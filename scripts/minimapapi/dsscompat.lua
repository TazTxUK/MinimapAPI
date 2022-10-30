local MinimapAPI = require("scripts.minimapapi")
local json = require("json")

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

    local menuDirectory = {
        --LEVEL 1
        main = {
            title = 'minimapapi',
            buttons = {
                {str = 'resume game', action = 'resume'},
                {str = 'settings', dest = 'settings'},
                {str = 'presets'}, --, dest = 'settings'},
                {str = 'minimapapi info', dest = 'info'},
            },
            tooltip = dssmod.menuOpenToolTip
        },
        settings = {
            title = 'settings',
            buttons = {
                {str = 'pickups', dest = 'pickups'},
                {str = 'map', dest = 'map'},
    
                dssmod.gamepadToggleButton,
                dssmod.menuKeybindButton,
                dssmod.paletteButton,
                dssmod.menuHintButton,
                dssmod.menuBuzzerButton,
            },
            tooltip = dssmod.menuOpenToolTip
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
                        MinimapAPI.Config.ShowPickupIcons = var == 1
                        MinimapAPI.Config.ConfigPreset = 0
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
                        MinimapAPI.Config.PickupNoGrouping = var == 1
                        MinimapAPI.Config.ConfigPreset = 0
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
                        MinimapAPI.Config.ShowShadows = var == 1
                        MinimapAPI.Config.ConfigPreset = 0
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
                        MinimapAPI.Config.DisplayLevelFlags = var
                        MinimapAPI.Config.ConfigPreset = 0
                    end,
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