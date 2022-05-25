local MinimapAPI = require "scripts.minimapapi"

MinimapAPI.SpriteMinimapIcons = Sprite()
MinimapAPI.SpriteMinimapIcons:Load("gfx/ui/minimapapi_mapitemicons.anm2", true)

local gameLvl = Game():GetLevel()

local function TreasureMapCondition()
	return gameLvl:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT)
end

local function BlueMapCondition()
	return gameLvl:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT)
end

local function CompassCondition()
	return gameLvl:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT)
end

local function RestockCondition()
	if Game():IsGreedMode() then return true end

	for p = 0, Game():GetNumPlayers() - 1 do
		local player = Game():GetPlayer(p)

		if player:HasCollectible(CollectibleType.COLLECTIBLE_RESTOCK) then
			return true
		end
	end

	return false
end

MinimapAPI:AddMapFlag("TreasureMap", TreasureMapCondition, MinimapAPI.SpriteMinimapIcons, "icons", 2)
MinimapAPI:AddMapFlag("BlueMap", BlueMapCondition, MinimapAPI.SpriteMinimapIcons, "icons", 1)
MinimapAPI:AddMapFlag("Compass", CompassCondition, MinimapAPI.SpriteMinimapIcons, "icons", 0)
MinimapAPI:AddMapFlag("Restock", RestockCondition, MinimapAPI.SpriteMinimapIcons, "icons", 4)
