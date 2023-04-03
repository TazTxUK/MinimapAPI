local MinimapAPI = require("scripts.minimapapi")

MinimapAPI.SpriteMinimapIcons = Sprite()
MinimapAPI.SpriteMinimapIcons:Load("gfx/ui/minimapapi_mapitemicons.anm2", true)

local game = Game()
local gameLvl = game:GetLevel()

local function anyPlayerHasCollectible(collectible)
	for p = 0, game:GetNumPlayers() - 1 do
		local player = game:GetPlayer(p)
		if player:HasCollectible(collectible) then
			return true
		end
	end

	return false
end

local function MindCondition()
	return game:GetLevel():GetStateFlag(LevelStateFlag.STATE_FULL_MAP_EFFECT) or anyPlayerHasCollectible(CollectibleType.COLLECTIBLE_MIND)
end

local function TreasureMapCondition()
	if MindCondition() then return false end
	return game:GetLevel():GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) or anyPlayerHasCollectible(CollectibleType.COLLECTIBLE_TREASURE_MAP)
end

local function BlueMapCondition()
	if MindCondition() then return false end
	return game:GetLevel():GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) or anyPlayerHasCollectible(CollectibleType.COLLECTIBLE_BLUE_MAP)
end

local function CompassCondition()
	if MindCondition() then return false end
	return game:GetLevel():GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) or anyPlayerHasCollectible(CollectibleType.COLLECTIBLE_COMPASS)
end

local function RestockCondition()
	if game:IsGreedMode() then return true end
	return anyPlayerHasCollectible(CollectibleType.COLLECTIBLE_RESTOCK)
end

local function DarknessCurse()
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_DARKNESS > 0
end
local function LabyrinthCurse()
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH > 0
end
local function LostCurse()
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_THE_LOST > 0
end
local function UnknownCurse()
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN > 0
end
local function CursedCurse()
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_THE_CURSED > 0
end
local function MazeCurse()
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_MAZE > 0
end
local function BlindCurse()
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_BLIND > 0
end
local function GiantCurse() --unused, but keep anyways just in case
	return gameLvl:GetCurses() & LevelCurse.CURSE_OF_GIANT > 0
end

MinimapAPI:AddMapFlag("Darkness", DarknessCurse, MinimapAPI.SpriteMinimapIcons, "curses", 0)
MinimapAPI:AddMapFlag("Labyrinth", LabyrinthCurse, MinimapAPI.SpriteMinimapIcons, "curses", 1)
MinimapAPI:AddMapFlag("Lost", LostCurse, MinimapAPI.SpriteMinimapIcons, "curses", 2)
MinimapAPI:AddMapFlag("Unknown", UnknownCurse, MinimapAPI.SpriteMinimapIcons, "curses", 3)
MinimapAPI:AddMapFlag("Cursed", CursedCurse, MinimapAPI.SpriteMinimapIcons, "curses", 4)
MinimapAPI:AddMapFlag("Maze", MazeCurse, MinimapAPI.SpriteMinimapIcons, "curses", 5)
MinimapAPI:AddMapFlag("Blind", BlindCurse, MinimapAPI.SpriteMinimapIcons, "curses", 6)
if MinimapAPI.isRepentance then
	MinimapAPI:AddMapFlag("Giant", GiantCurse, MinimapAPI.SpriteMinimapIcons, "curses", 7)
end

MinimapAPI:AddMapFlag("Compass", CompassCondition, MinimapAPI.SpriteMinimapIcons, "icons", 0)
MinimapAPI:AddMapFlag("BlueMap", BlueMapCondition, MinimapAPI.SpriteMinimapIcons, "icons", 1)
MinimapAPI:AddMapFlag("TreasureMap", TreasureMapCondition, MinimapAPI.SpriteMinimapIcons, "icons", 2)
MinimapAPI:AddMapFlag("Restock", RestockCondition, MinimapAPI.SpriteMinimapIcons, "icons", 4)
MinimapAPI:AddMapFlag("Mind", MindCondition, MinimapAPI.SpriteMinimapIcons, "icons", 6)
