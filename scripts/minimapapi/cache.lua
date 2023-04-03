-- copied from Music Mod Callback with some stuff removed

local constants = require("scripts.minimapapi.constants")
local CALLBACK_PRIORITY = constants.CALLBACK_PRIORITY

local cache = {}

cache.Mod = RegisterMod("MinimapAPI Cache", 1)
local mod = cache.Mod

cache.Game = Game()
cache.Dimension = 0

function cache.ReloadRoomCache()
	cache.Level = cache.Game:GetLevel()
	cache.Room = cache.Game:GetRoom()
	cache.RoomDescriptor = cache.Level:GetCurrentRoomDesc()
	cache.Stage = cache.Level:GetStage()
	cache.AbsoluteStage = cache.Level:GetAbsoluteStage()
	cache.StageType = cache.Level:GetStageType()
	cache.CurrentRoomIndex = cache.Level:GetCurrentRoomIndex()
	cache.RoomType = cache.Room:GetType()
	cache.Seeds = cache.Game:GetSeeds()

	--Dimension
	if MinimapAPI.isRepentance then
		if GetPtrHash(cache.RoomDescriptor) == GetPtrHash(cache.Level:GetRoomByIdx(cache.CurrentRoomIndex, 0)) then
			cache.Dimension = 0
		elseif GetPtrHash(cache.RoomDescriptor) == GetPtrHash(cache.Level:GetRoomByIdx(cache.CurrentRoomIndex, 2)) then
			cache.Dimension = 2
		else
			cache.Dimension = 1
		end
		cache.MirrorDimension = cache.Dimension == 1 and (((cache.Stage == LevelStage.STAGE1_1 and cache.Level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH == LevelCurse.CURSE_OF_LABYRINTH or cache.Stage == LevelStage.STAGE1_2) and (cache.StageType == StageType.STAGETYPE_REPENTANCE or cache.StageType == StageType.STAGETYPE_REPENTANCE_B)) or (StageAPI and StageAPI.Loaded and StageAPI.GetCurrentStage() and StageAPI.GetCurrentStage():HasMirrorDimension()))
	end
end
cache.ReloadRoomCache()

if MinimapAPI.isRepentance then
	mod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_ROOM, CALLBACK_PRIORITY, cache.ReloadRoomCache)
else
	mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, cache.ReloadRoomCache)
end

return cache
