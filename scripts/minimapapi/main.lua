local MinimapAPI = require("scripts.minimapapi")
local cache = require("scripts.minimapapi.cache")
local constants = require("scripts.minimapapi.constants")
local Callbacks = require("scripts.minimapapi.callbacks")
local CALLBACK_PRIORITY = constants.CALLBACK_PRIORITY
require("scripts.minimapapi.apioverride")

local json = require("json")

local game = Game()
local dlcColorMult = MinimapAPI.isRepentance and 1 or 255 -- converts colors into correct value range for the DLCs
local vectorZero = Vector(0,0)

function MinimapAPI:GetScreenSize() --based off of code from kilburn
	local room = game:GetRoom()

	local pos = room:WorldToScreenPosition(vectorZero) - room:GetRenderScrollOffset() - game.ScreenShakeOffset

	local rx = pos.X + 60 * 26 / 40
	local ry = pos.Y + 140 * (26 / 40)

	return Vector(rx*2 + 13*26, ry*2 + 7*26)
end

function MinimapAPI:GetScreenCenter()
	return MinimapAPI:GetScreenSize() / 2
end

function MinimapAPI:GetHudOffset()
	return MinimapAPI.isRepentance and Options.HUDOffset or 0
end

function MinimapAPI:AddCallbackFunc(callbackID, priority, func, extraAttr)
	if MinimapAPI.isRepentance then

		MinimapAPI:AddPriorityCallback(callbackID, priority, func, extraAttr)
	else
		MinimapAPI:AddCallback(callbackID, func, extraAttr)
	end
end

function MinimapAPI:GetScreenBottomRight(offset)

	offset = offset or (MinimapAPI:GetHudOffset() * 10)

	local pos = MinimapAPI:GetScreenSize()
	local hudOffset = Vector(-offset * 2.2, -offset * 1.6)
	pos = pos + hudOffset

	return pos

end

function MinimapAPI:GetScreenBottomLeft(offset)

	offset = offset or (MinimapAPI:GetHudOffset() * 10)

	local pos = Vector(0, MinimapAPI:GetScreenBottomRight(0).Y)
	local hudOffset = Vector(offset * 2.2, -offset * 1.6)
	pos = pos + hudOffset

	return pos

end

function MinimapAPI:GetScreenTopRight(offset)
	offset = offset or (MinimapAPI:GetHudOffset() * 10)

	local pos = Vector(MinimapAPI:GetScreenBottomRight(0).X, 0)
	local hudOffset = Vector(-offset * 2.2, offset * 1.2)
	pos = pos + hudOffset

	return pos

end

function MinimapAPI:GetScreenTopLeft(offset)

	offset = offset or (MinimapAPI:GetHudOffset() * 10)

	local pos = vectorZero
	local hudOffset = Vector(offset * 2, offset * 1.2)
	pos = pos + hudOffset

	return pos

end

function MinimapAPI:DeepCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[MinimapAPI:DeepCopy(orig_key)] = MinimapAPI:DeepCopy(orig_value)
		end
		setmetatable(copy, MinimapAPI:DeepCopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function MinimapAPI:GetRoomShapeFrame(rs)
	return MinimapAPI.RoomShapeFrames[rs]
end

function MinimapAPI:GetRoomShapeGridSize(rs)
	return MinimapAPI.RoomShapeGridSizes[rs]
end

function MinimapAPI:GetRoomShapePositions(rs)
	return MinimapAPI.RoomShapePositions[rs]
end

function MinimapAPI:GetRoomTypeIconID(t)
	return MinimapAPI.RoomTypeIconIDs[t]
end

function MinimapAPI:GetUnknownRoomTypeIconID(t)
	return MinimapAPI.UnknownRoomTypeIconIDs[t]
end

function MinimapAPI:GetRoomShapeIconPositions(rs, iconcount)
	iconcount = iconcount or math.huge
	if iconcount <= 1 then
		return MinimapAPI.RoomShapeIconPositions[1][rs]
	else
		return MinimapAPI.RoomShapeIconPositions[2][rs]
	end
end

function MinimapAPI:GetLargeRoomShapeIconPositions(rs, iconcount)
	iconcount = iconcount or math.huge
	if iconcount <= 1 then
		return MinimapAPI.LargeRoomShapeIconPositions[1][rs]
	elseif iconcount == 2 then
		return MinimapAPI.LargeRoomShapeIconPositions[2][rs]
	else
		return MinimapAPI.LargeRoomShapeIconPositions[3][rs]
	end
end

function MinimapAPI:GridIndexToVector(grid_index)
	return Vector(grid_index % 13, math.floor(grid_index / 13))
end

function MinimapAPI:GridVectorToIndex(v)
	return v.Y * 13 + v.X
end

function MinimapAPI:RoomDistance(room1,room2)
	return room1.Position:__sub(room2.Position):Length()
end

function MinimapAPI:GetFrameBR()
	return Vector(MinimapAPI.Config.MapFrameWidth, MinimapAPI.Config.MapFrameHeight)
end

function MinimapAPI:GetFrameCenterOffset()
	return Vector(MinimapAPI.Config.MapFrameWidth + 1, MinimapAPI.Config.MapFrameHeight + 1) / 2
end

--minimap api
local badload = false
local font = Font()
font:Load("font/pftempestasevencondensed.fnt")
local playerMapPos = vectorZero
---@type table<any, MinimapAPI.Room[]>
MinimapAPI.Levels = {}
MinimapAPI.CheckedRoomCount = 0
MinimapAPI.CurrentDimension = 0
MinimapAPI.OverrideVoid = false
MinimapAPI.changedRoomsWithShowMap = {}
MinimapAPI.DisableSpelunkerHat = false

MinimapAPI.TargetGlobalScaleX = 1 --when in mirror dimension this goes to -1
MinimapAPI.ValueGlobalScaleX = 1
MinimapAPI.GlobalScaleX = 1 --ValueGlobalScaleX square rooted

local mapheldframes = 0

local callbacks_playerpos = {}
local callbacks_displayflags = {}
local callbacks_dimension = {}

local disabled_itemdet = false
local override_greed = true

--draw
local roomCenterOffset = vectorZero
local roomAnimPivot = Vector(-2, -2)
local frameTL = Vector(2, 2)

local roomSize = Vector(8, 7)
local roomPixelSize = Vector(9, 8)
local iconPixelSize = Vector(16, 16)
local outlinePixelSize = Vector(16, 16)

local largeRoomAnimPivot = Vector(-4, -4)
local largeRoomSize = Vector(17, 15)
local unboundedMapOffset = vectorZero
local largeIconOffset = Vector(-2, -2)

local dframeHorizBarSize = Vector(53, 2)
local dframeVertBarSize = Vector(2, 47)
local dframeCenterSize = Vector(49, 43)

local mapAltCustomLarge = false

MinimapAPI.SpriteMinimapSmall = Sprite()
MinimapAPI.SpriteMinimapSmall:Load("gfx/ui/minimapapi_minimap1.anm2", true)
MinimapAPI.SpriteMinimapLarge = Sprite()
MinimapAPI.SpriteMinimapLarge:Load("gfx/ui/minimapapi_minimap2.anm2", true)

MinimapAPI.SpriteIcons = Sprite()
MinimapAPI.SpriteIcons:Load("gfx/ui/minimapapi_icons.anm2", true)
MinimapAPI.SpriteQuestionmark = Sprite()
MinimapAPI.SpriteQuestionmark:Load("gfx/ui/minimapapi/questionmark.anm2", true)
MinimapAPI.SpriteQuestionmark:Play("questionmark")

MinimapAPI.SpriteMinimapCustomSmall = Sprite()
MinimapAPI.SpriteMinimapCustomSmall:Load("gfx/ui/minimapapi/custom_minimap1.anm2", true)
MinimapAPI.SpriteMinimapCustomLarge = Sprite()
MinimapAPI.SpriteMinimapCustomLarge:Load("gfx/ui/minimapapi/custom_minimap2.anm2", true)

------ Override original API -------
if MinimapAPI.isRepentance then
	local MakeRedRoomDoor_Old = getmetatable(Level).__class.MakeRedRoomDoor
	APIOverride.OverrideClassFunction(Level, "MakeRedRoomDoor", function(self, currentRoomIdx, slot)
		local returnVal = MakeRedRoomDoor_Old(self, currentRoomIdx, slot)
		MinimapAPI:CheckForNewRedRooms()
		return returnVal
	end)
end

MinimapAPI.OverrideConfig = {}
function MinimapAPI:GetConfig(option)
	return MinimapAPI.OverrideConfig[option] ~= nil and MinimapAPI.OverrideConfig[option] or MinimapAPI.Config[option]
end

---@param key? any
---@return MinimapAPI.Room[]
function MinimapAPI:GetLevel(key)
	return MinimapAPI.Levels[key or MinimapAPI.CurrentDimension]
end

function MinimapAPI:SetLevel(level, key)
	MinimapAPI.Levels[key or MinimapAPI.CurrentDimension] = level
end

function MinimapAPI:GetIconAnimData(id)
	for _, v in ipairs(MinimapAPI.IconList) do
		if v.ID == id then
			return v
		end
	end
end

function MinimapAPI:GetDoorSlotValue(doorgroup, doordir)
	return doorgroup*4 + doordir
end

local defaultCustomPickupPriority = 14999 --more than vanilla, less than other potential custom pickups
function MinimapAPI:AddPickup(id, iconid, typ, variant, subtype, call, icongroup, priority, condition)
	local newPickup
	if type(id) == "table" and iconid == nil then
		local t = id
		id = t.ID
		if type(t.Icon) == "table" then
			t.Icon = MinimapAPI:AddIcon(t.Icon.ID or t.ID, t.Icon.sprite, t.Icon.anim, t.Icon.frame, t.Icon.color).ID
		end
		newPickup = {
			IconID = t.Icon,
			Type = t.Type,
			Variant = t.Variant or -1,
			SubType = t.SubType or -1,
			Call = t.Call,
			IconGroup = t.IconGroup,
			Priority = t.Priority or defaultCustomPickupPriority,
			Condition = t.Condition,
		}
	else
		if type(iconid) == "table" then
			iconid = MinimapAPI:AddIcon(iconid.ID or id, iconid.sprite, iconid.anim, iconid.frame, iconid.color).ID
		end
		newPickup = {
			IconID = iconid,
			Type = typ,
			Variant = variant or -1,
			SubType = subtype or -1,
			Call = call,
			IconGroup = icongroup,
			Priority = priority or defaultCustomPickupPriority,
			Condition = condition,
		}
	end
	MinimapAPI.PickupList[id] = newPickup
	table.sort(MinimapAPI.PickupList, function(a, b) return a.Priority > b.Priority	end	)
	return newPickup
end

function MinimapAPI:RemovePickup(id)
	MinimapAPI.PickupList[id] = nil
end

function MinimapAPI:AddGridEntity(id, iconid, typ, variant, call, priority, isPrespawnObject)
	local newEntry
	if type(id) == "table" and iconid == nil then
		local t = id
		id = t.ID
		if type(t.Icon) == "table" then
			t.Icon = MinimapAPI:AddIcon(t.Icon.ID or t.ID, t.Icon.sprite, t.Icon.anim, t.Icon.frame, t.Icon.color).ID
		end
		newEntry = {
			IconID = t.Icon,
			Type = t.Type,
			Variant = t.Variant or -1,
			Call = t.Call,
			Priority = t.Priority or defaultCustomPickupPriority,
			IsPrespawnObject = t.IsPrespawnObject
		}
	else
		if type(iconid) == "table" then
			iconid = MinimapAPI:AddIcon(iconid.ID or id, iconid.sprite, iconid.anim, iconid.frame, iconid.color).ID
		end
		newEntry = {
			IconID = iconid,
			Type = typ,
			Variant = variant or -1,
			Call = call,
			Priority = priority or defaultCustomPickupPriority,
			IsPrespawnObject = isPrespawnObject
		}
	end
	MinimapAPI.GridEntityList[id] = newEntry
	table.sort(MinimapAPI.GridEntityList, function(a, b) return a.Priority > b.Priority	end	)
	return newEntry
end

function MinimapAPI:RemoveGridEntity(id)
	MinimapAPI.GridEntityList[id] = nil
end

function MinimapAPI:AddIcon(id, sprite, anim, frame, color)
	MinimapAPI:RemoveIcon(id)
	local x = {
		ID = id,
		sprite = sprite,
		anim = anim,
		frame = frame,
		color = color
	}
	MinimapAPI.IconList[#MinimapAPI.IconList + 1] = x
	return x
end

function MinimapAPI:RemoveIcon(id)
	for i = #MinimapAPI.IconList, 1, -1 do
		local v = MinimapAPI.IconList[i]
		if v.ID == id then
			table.remove(MinimapAPI.IconList, i)
		end
	end
end

function MinimapAPI:AddMapFlag(id, condition, sprite, anim, frame, color)
	MinimapAPI:RemoveMapFlag(id)
	local x = {
		ID = id,
		condition = condition,
		sprite = sprite,
		anim = anim,
		frame = frame,
		color = color
	}
	MinimapAPI.MapFlags[#MinimapAPI.MapFlags + 1] = x
	return x
end

function MinimapAPI:RemoveMapFlag(id)
	for i = #MinimapAPI.MapFlags, 1, -1 do
		local v = MinimapAPI.MapFlags[i]
		if v.ID == id then
			table.remove(MinimapAPI.MapFlags, i)
		end
	end
end

function MinimapAPI:AddRoomShape(id, roomshapesmallanims, roomshapelargeanims, gridpivot, gridsize, positions, iconpositions, iconpositioncenter, largeiconpositions, largeiconpositioncenter, adjacentcoords, doorslots)
	MinimapAPI.RoomShapeFrames[id] = {
		small = roomshapesmallanims,
		large = roomshapelargeanims,
	}

	MinimapAPI.RoomShapeGridPivots[id] = gridpivot
	MinimapAPI.RoomShapeGridSizes[id] = gridsize
	MinimapAPI.RoomShapePositions[id] = positions
	MinimapAPI.RoomShapeIconPositions[1][id] = {iconpositioncenter}
	MinimapAPI.RoomShapeIconPositions[2][id] = iconpositions
	MinimapAPI.LargeRoomShapeIconPositions[1][id] = {largeiconpositioncenter}
	MinimapAPI.LargeRoomShapeIconPositions[2][id] = largeiconpositions
	MinimapAPI.LargeRoomShapeIconPositions[3][id] = largeiconpositions

	MinimapAPI.RoomShapeAdjacentCoords[id] = adjacentcoords
	MinimapAPI.RoomShapeDoorSlots[id] = doorslots
	MinimapAPI.RoomShapeDoorCoords[id] = {}

	if doorslots then
		for _,doorslot in ipairs(doorslots) do
			local doorgroup = math.floor(doorslot / 4)
			local doordir = doorslot % 4
			local result
			if doordir == 0 then
				for _,v in pairs(adjacentcoords) do
					if v.Y == gridpivot.Y + doorgroup then
						if not result or (v.X < result.X) then
							result = v
						end
					end
				end
			elseif doordir == 1 then
				for _,v in pairs(adjacentcoords) do
					if v.X == gridpivot.X + doorgroup then
						if not result or (v.Y < result.Y) then
							result = v
						end
					end
				end
			elseif doordir == 2 then
				for _,v in pairs(adjacentcoords) do
					if v.Y == gridpivot.Y + doorgroup then
						if not result or (v.X > result.X) then
							result = v
						end
					end
				end
			elseif doordir == 3 then
				for _,v in pairs(adjacentcoords) do
					if v.X == gridpivot.X + doorgroup then
						if not result or (v.Y > result.Y) then
							result = v
						end
					end
				end
			end
			MinimapAPI.RoomShapeDoorCoords[id][doorslot + 1] = result
		end
	end
end

function MinimapAPI:PickupDetectionEnabled()
	return not disabled_itemdet
end

function MinimapAPI:DisablePickupDetection()
	disabled_itemdet = true
end

function MinimapAPI:EnablePickupDetection()
	disabled_itemdet = false
end

function MinimapAPI:IsLarge()
	return mapheldframes > 0 or MinimapAPI:GetConfig("DisplayMode") == 3
end

function MinimapAPI:PlayerInRoom(roomdata)
	return playerMapPos.X == roomdata.Position.X and playerMapPos.Y == roomdata.Position.Y
end

function MinimapAPI:GetCurrentRoomPickupIDs() --gets pickup icon ids for current room ONLY
	local pickupgroupset = {}
	local addIcons = {}
	for _, ent in ipairs(Isaac.GetRoomEntities()) do
		local success = false
		local id = type(ent:GetData()) == "table" and ent:GetData().MinimapAPIPickupID -- sanity checks to get entity Data
		if id == nil then
			for i, v in pairs(MinimapAPI.PickupList) do
				local currentid = MinimapAPI.PickupList[id]
				if not currentid or (currentid.Priority < v.Priority) then
					if ent.Type == v.Type then
						local toPickup = ent:ToPickup()
						if (not toPickup) or (not toPickup:IsShopItem()) then
							if v.Variant == -1 or ent.Variant == v.Variant then
								if v.SubType == -1 or ent.SubType == v.SubType then
									if (not v.Condition) or v.Condition(ent) then
										ent:GetData().MinimapAPIPickupID = i
										id = i
										success = true
									end
								end
							end
						end
					end
				end
			end
			if not success then
				ent:GetData().MinimapAPIPickupID = false
			end
		end

		local pickupicon = MinimapAPI.PickupList[id]
		if pickupicon then
			local ind = MinimapAPI:GetConfig("PickupNoGrouping") and (#pickupgroupset + 1) or pickupicon.IconGroup
			if not pickupgroupset[ind] or MinimapAPI.PickupList[pickupgroupset[ind]].Priority < pickupicon.Priority then
				if (not pickupicon.Call) or pickupicon.Call(ent) then
					if pickupicon.IconGroup then
						pickupgroupset[ind] = id
					end
				end
			end
		end
	end
	for _,v in pairs(pickupgroupset) do
		table.insert(addIcons, v)
	end
	local iconList = {}
	for i,v in ipairs(addIcons) do
		iconList[i] = MinimapAPI.PickupList[v].IconID
	end
	for _,v in ipairs(MinimapAPI:GetCurrentRoomGridIDs()) do
		table.insert(iconList, v)
	end
	return iconList
end

function MinimapAPI:GetCurrentRoomGridIDs()
	local iconList = {}
	for _, iconEntry in pairs(MinimapAPI.GridEntityList) do
		if MinimapAPI:CurrentRoomContainsGridEntity(iconEntry) then
			if (not iconEntry.Call) or iconEntry.Call(ent) then
				table.insert(iconList, iconEntry.IconID)
			end
		end
	end
	return iconList
end

function MinimapAPI:RunPlayerPosCallbacks()
	local currentRoom = MinimapAPI:GetCurrentRoom()
	if REPENTANCE then
		local returnVal = Isaac.RunCallback(Callbacks.PLAYER_POS_CHANGED, currentRoom, playerMapPos)
		if returnVal then
			playerMapPos = returnVal
			return returnVal
		end
	end

	-- still run old callbacks for backwards compatibility
	for _, v in ipairs(callbacks_playerpos) do
		local s, ret
		-- backwards compatibility mode, pass mod reference
		if v.modReference then
			s, ret = pcall(v.call, v.modReference, currentRoom, playerMapPos)
		else
			s, ret = pcall(v.call, currentRoom, playerMapPos)
		end
		if s then
			if ret then
				playerMapPos = ret
				return ret
			end
		else
			Isaac.ConsoleOutput("Error in MinimapAPI PlayerPos Callback:\n" .. tostring(ret) .. "\n")
		end
	end
end

function MinimapAPI:RunDisplayFlagsCallbacks(room, df)
	if REPENTANCE then
		local returnVal = Isaac.RunCallback(Callbacks.GET_DISPLAY_FLAGS, room, df)
		if returnVal then
			return returnVal
		end
	end

	-- still run old callbacks for backwards compatibility
	for _, v in ipairs(callbacks_displayflags) do
		local s, ret
		-- backwards compatibility mode, pass mod reference
		if v.modReference then
			s, ret = pcall(v.call, v.modReference, room, df)
		else
			s, ret = pcall(v.call, room, df)
		end

		if s then
			if ret then
				return ret
			end
		else
			Isaac.ConsoleOutput("Error in MinimapAPI DisplayFlags Callback:\n" .. tostring(ret) .. "\n")
		end
	end
	return df
end

function MinimapAPI:RunDimensionCallbacks()
	if REPENTANCE then
		local returnVal = Isaac.RunCallback(Callbacks.GET_DIMENSION, MinimapAPI.CurrentDimension)
		if returnVal then
			MinimapAPI.CurrentDimension = returnVal
			return returnVal
		end
	end

	-- still run old callbacks for backwards compatibility
	for _, v in ipairs(callbacks_dimension) do
		local s, ret
		-- backwards compatibility mode, pass mod reference
		if v.modReference then
			s, ret = pcall(v.call, v.modReference, MinimapAPI.CurrentDimension)
		else
			s, ret = pcall(v.call, MinimapAPI.CurrentDimension)
		end
		if s then
			if ret then
				MinimapAPI.CurrentDimension = ret
				return ret
			end
		else
			Isaac.ConsoleOutput("Error in MinimapAPI Dimension Callback:\n" .. tostring(ret) .. "\n")
		end
	end
end

function MinimapAPI:InstanceOf(obj, class)
	local meta = getmetatable(obj)
	local metaclass = getmetatable(class)
	if metaclass then
		local c = metaclass.__class
		return c == meta
	else
		return false
	end
end

-- Level rooms:Get returns a constant room descriptor,
-- we need the mutable one returned by GetFromGridIdx
-- for SetDisplayFlags to work GetRoomDescAndDimFromListIndex
local function GetRoomDescAndDimFromListIndex(listIndex)
	local level = game:GetLevel()
    local constDesc = level:GetRooms():Get(listIndex)

    if not constDesc then
		Isaac.ConsoleOutput("Error in MinimapAPI GetRoomDescFromListIndex: room listindex '"..tostring(listIndex).."' doesnt exist\n")
		return nil, 0
    end
    local gridIndex = constDesc.SafeGridIndex
	local fallbackDesc,fallbackDim = nil, 0
	local maxDim = MinimapAPI.isRepentance and 2 or 0
	for dim = 0, maxDim do
		local roomDesc = level:GetRoomByIdx(gridIndex, dim)
		if roomDesc.ListIndex == listIndex then
			return roomDesc, dim
		end
		if roomDesc.SafeGridIndex == gridIndex then -- fallback when code aboth doesnt find a match. Example failcase: Seed GHXY AG8J, Mines 2 with knife piece 1
			fallbackDesc,fallbackDim = roomDesc, dim
		end
	end
	if fallbackDesc then
		return fallbackDesc, fallbackDim
	end
end

local function IsAltPath()
	local level = game:GetLevel()
	return ((level:GetStageType() == StageType.STAGETYPE_REPENTANCE or level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B) or (StageAPI and StageAPI.Loaded and StageAPI.GetCurrentStage() and StageAPI.GetCurrentStage().LevelgenStage and (StageAPI.GetCurrentStage().LevelgenStage.StageType == StageType.STAGETYPE_REPENTANCE or StageAPI.GetCurrentStage().LevelgenStage.StageType == StageType.STAGETYPE_REPENTANCE_B)))
end

function MinimapAPI:LoadDefaultMap(dimension)
	local level = game:GetLevel()
	local rooms = level:GetRooms()
	dimension = dimension or MinimapAPI.CurrentDimension
	MinimapAPI.Levels[dimension] = {}
	MinimapAPI.CheckedRoomCount = 0
	local added_descriptors = {}
	for i = 0, #rooms - 1 do
		local roomDescriptor, roomDim = GetRoomDescAndDimFromListIndex(i)
		if roomDescriptor and roomDim == dimension
		and not added_descriptors[roomDescriptor]
		and GetPtrHash(cache.Level:GetRoomByIdx(roomDescriptor.SafeGridIndex, dimension)) == GetPtrHash(roomDescriptor)
		then
			added_descriptors[roomDescriptor] = true
			local t = {
				Shape = roomDescriptor.Data.Shape,
				PermanentIcons = {MinimapAPI:GetRoomTypeIconID(roomDescriptor.Data.Type)},
				LockedIcons = {MinimapAPI:GetUnknownRoomTypeIconID(roomDescriptor.Data.Type)},
				ItemIcons = {},
				VisitedIcons = {},
				Position = MinimapAPI:GridIndexToVector(roomDescriptor.SafeGridIndex),
				Descriptor = roomDescriptor,
				AdjacentDisplayFlags = MinimapAPI.RoomTypeDisplayFlagsAdjacent[roomDescriptor.Data.Type] or 5,
				Type = roomDescriptor.Data.Type,
				Dimension = dimension,
				Visited = roomDescriptor.VisitedCount > 0,
				Clear = roomDescriptor.Clear,
				Secret = roomDescriptor.Data.Type == RoomType.ROOM_SECRET or roomDescriptor.Data.Type == RoomType.ROOM_SUPERSECRET or roomDescriptor.Data.Type == RoomType.ROOM_ULTRASECRET,
				Color = MinimapAPI.isRepentance and roomDescriptor.Flags & RoomDescriptor.FLAG_RED_ROOM == RoomDescriptor.FLAG_RED_ROOM and Color(1,0.25,0.25,1,0,0,0) or nil
			}

			if roomDescriptor.Data.Type == RoomType.ROOM_CHALLENGE and roomDescriptor.Data.Subtype == 1 then
				t.PermanentIcons = {"BossAmbushRoom"}
			end
			if MinimapAPI.isRepentance then
				if roomDescriptor.Flags & RoomDescriptor.FLAG_DEVIL_TREASURE == RoomDescriptor.FLAG_DEVIL_TREASURE then
					t.PermanentIcons = { "TreasureRoomRed" }
				end

				if roomDescriptor.Data.Type == RoomType.ROOM_DEFAULT then
					if IsAltPath() then
						local isCurseLabyrinth = level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH == LevelCurse.CURSE_OF_LABYRINTH
						if ((level:GetAbsoluteStage() == LevelStage.STAGE1_2 and not isCurseLabyrinth or level:GetAbsoluteStage() == LevelStage.STAGE1_1 and isCurseLabyrinth) or (StageAPI and StageAPI.Loaded and StageAPI.GetCurrentStage() and StageAPI.GetCurrentStage():HasMirrorDimension())) and roomDescriptor.Data.Subtype == 34 then
							t.VisitedIcons = { "MirrorRoom" }
						end

						if (level:GetAbsoluteStage() == LevelStage.STAGE2_2 and not isCurseLabyrinth or level:GetAbsoluteStage() == LevelStage.STAGE2_1 and isCurseLabyrinth) and roomDescriptor.Data.Subtype == 10 then
							t.VisitedIcons = { "MinecartRoom" }
						end
					end
				end
			end
			if override_greed and game:IsGreedMode() then
				if roomDescriptor.Data.Type == RoomType.ROOM_TREASURE and roomDescriptor.GridIndex == 98 then
					t.PermanentIcons = {"TreasureRoomGreed"}
				end
			end
			MinimapAPI:AddRoom(t)
		end
	end
	MinimapAPI.CheckedRoomCount = #rooms
	if not (MinimapAPI:GetConfig("OverrideVoid") or MinimapAPI.OverrideVoid) then
		if not game:IsGreedMode() then
			if cache.Stage == LevelStage.STAGE7 then
				for _,v in ipairs(MinimapAPI:GetLevel(dimension)) do
					if v.Descriptor.Data.Type == RoomType.ROOM_BOSS then
						if v.Shape == RoomShape.ROOMSHAPE_2x2 then
							-- Hide delirium room
							if not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP0), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT0), nil, dimension, true)
							then
								--
							elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP1), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT0), nil, dimension, true)
							then
								v.DisplayPosition = v.Position + Vector(1,0)
							elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT1), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN1), nil, dimension, true)
							then
								v.DisplayPosition = v.Position + Vector(1,1)
							elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT1), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN0), nil, dimension, true)
							then
								v.DisplayPosition = v.Position + Vector(0,1)
							end
							v.Shape = RoomShape.ROOMSHAPE_1x1
						elseif v.Shape == RoomShape.ROOMSHAPE_2x1 then
							if not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP0), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT0), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN0), nil, dimension, true)
							then
								--
							elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP1), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT0), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN1), nil, dimension, true)
							then
								v.DisplayPosition = v.Position + Vector(1,0)
							end
							v.Shape = RoomShape.ROOMSHAPE_1x1
						elseif v.Shape == RoomShape.ROOMSHAPE_1x2 then
							if not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT0), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP0), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT0), nil, dimension, true)
							then
								--
							elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT1), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN0), nil, dimension, true) or
								not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT1), nil, dimension, true)
							then
								v.DisplayPosition = v.Position + Vector(0,1)
							end
							v.Shape = RoomShape.ROOMSHAPE_1x1
						end
					end
				end
			end
		end
	end
end

function MinimapAPI:IsHUDVisible()
	if MinimapAPI:GetConfig("DisplayOnNoHUD") then
		return true
	elseif MinimapAPI.isRepentance then
		return game:GetHUD():IsVisible() and not game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD)
	end
	return not game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD)
end

function MinimapAPI:CurrentRoomContainsGridEntity(gridEntityDef)
	gridEntityDef.Variant = gridEntityDef.Variant or -1

	if gridEntityDef.IsPrespawnObject then
		local spawnList = cache.Level:GetCurrentRoomDesc().Data.Spawns
		for i = 0, spawnList.Size-1 do
			local roomConfigSpawn = spawnList:Get(i):PickEntry(0)
			if roomConfigSpawn.Type == gridEntityDef.Type
			and (gridEntityDef.Variant == -1 or roomConfigSpawn.Variant == gridEntityDef.Variant) then
				return true
			end
		end
	else
		for i = 0, cache.Room:GetGridSize() - 1 do
			local gridEntity = cache.Room:GetGridEntity(i)
			if gridEntity and gridEntityDef.Type == gridEntity:GetType()
			and (gridEntityDef.Variant == -1 or gridEntity:GetVariant()== gridEntityDef.Variant) then
				return true
			end
		end
	end
	return false
end

function MinimapAPI:EffectCrystalBall()
	for _,room in ipairs(MinimapAPI:GetLevel()) do
		if room.Type ~= RoomType.ROOM_SUPERSECRET and room.Type ~= RoomType.ROOM_ULTRASECRET then
			room:Reveal()
		end
	end
end

function MinimapAPI:CheckForNewRedRooms(dimension)
	local level = game:GetLevel()
	local rooms = level:GetRooms()
	dimension = dimension or MinimapAPI.CurrentDimension
	local added_descriptors = {}
	for i = MinimapAPI.CheckedRoomCount, #rooms - 1 do
		local roomDescriptor, roomDim = GetRoomDescAndDimFromListIndex(i)
		if roomDescriptor and roomDim == dimension
		and not added_descriptors[roomDescriptor]
		and GetPtrHash(cache.Level:GetRoomByIdx(roomDescriptor.GridIndex)) == GetPtrHash(roomDescriptor)
		then
			added_descriptors[roomDescriptor] = true
			local t = {
				Shape = roomDescriptor.Data.Shape,
				PermanentIcons = {MinimapAPI:GetRoomTypeIconID(roomDescriptor.Data.Type)},
				LockedIcons = {MinimapAPI:GetUnknownRoomTypeIconID(roomDescriptor.Data.Type)},
				ItemIcons = {},
				Position = MinimapAPI:GridIndexToVector(roomDescriptor.GridIndex),
				Descriptor = roomDescriptor,
				AdjacentDisplayFlags = MinimapAPI.RoomTypeDisplayFlagsAdjacent[roomDescriptor.Data.Type] or 5,
				Type = roomDescriptor.Data.Type,
				Level = dimension,
				Secret = roomDescriptor.Data.Type == RoomType.ROOM_SECRET or roomDescriptor.Data.Type == RoomType.ROOM_SUPERSECRET or roomDescriptor.Data.Type == RoomType.ROOM_ULTRASECRET,
				Color = roomDescriptor.Flags & RoomDescriptor.FLAG_RED_ROOM == RoomDescriptor.FLAG_RED_ROOM and Color(1,0.25,0.25,1,0,0,0) or nil
			}
			if roomDescriptor.Data.Shape == RoomShape.ROOMSHAPE_LTL then
				t.Position = t.Position + Vector(1,0)
			end
			if roomDescriptor.Data.Type == RoomType.ROOM_CHALLENGE and roomDescriptor.Data.Subtype == 1 then
				t.PermanentIcons = {"BossAmbushRoom"}
			end
			if MinimapAPI.isRepentance then
				if roomDescriptor.Flags & RoomDescriptor.FLAG_DEVIL_TREASURE == RoomDescriptor.FLAG_DEVIL_TREASURE then
					t.PermanentIcons = { "TreasureRoomRed" }
				end

				if roomDescriptor.Data.Type == RoomType.ROOM_DEFAULT then
					if IsAltPath() then
						if ((level:GetAbsoluteStage() == LevelStage.STAGE1_2 and not isCurseLabyrinth or level:GetAbsoluteStage() == LevelStage.STAGE1_1 and isCurseLabyrinth) or (StageAPI and StageAPI.Loaded and StageAPI.GetCurrentStage() and StageAPI.GetCurrentStage():HasMirrorDimension())) and roomDescriptor.Data.Subtype == 34 then
							t.VisitedIcons = { "MirrorRoom" }
						end

						if (level:GetAbsoluteStage() == LevelStage.STAGE2_2 and not isCurseLabyrinth or level:GetAbsoluteStage() == LevelStage.STAGE2_1 and isCurseLabyrinth) and roomDescriptor.Data.Subtype == 10 then
							t.VisitedIcons = { "MinecartRoom" }
						end
					end
				end
			end
			MinimapAPI:AddRoom(t)
		end
	end
	MinimapAPI.CheckedRoomCount = #rooms
	MinimapAPI:UpdateExternalMap()
end

function MinimapAPI:ClearMap(dimension)
	MinimapAPI.Levels[dimension or MinimapAPI.CurrentDimension] = {}
end

function MinimapAPI:ClearLevels()
	MinimapAPI.Levels = {}
	MinimapAPI.CheckedRoomCount = 0
end

---@class MinimapAPI.Room
---@field Position Vector
---@field DisplayPosition Vector
---@field Type RoomType
---@field ID any
---@field Shape RoomShape
---@field PermanentIcons string[]
---@field LockedIcons string[]
---@field ItemIcons string[]
---@field VisitedIcons string[]
---@field Descriptor RoomDescriptor | nil # may be nil for custom rooms
---@field TeleportHandler TeleportHandler | nil # may be nil, used to handle minimapAPI map teleport for custom rooms
---@field Color Color | nil
---@field RenderOffset Vector
---@field DisplayFlags integer
---@field Clear boolean
---@field Visited boolean
---@field AdjacentDisplayFlags integer
---@field Hidden boolean
---@field NoUpdate boolean
---@field Dimension number?
---@field IgnoreDescriptorFlags boolean
---@field TargetRenderOffset Vector
---@field PlayerDistance number
---@field Secret boolean
---@field private AdjacentRooms MinimapAPI.Room[]
local maproomfunctions = {}
function maproomfunctions:IsVisible()
	return self:GetDisplayFlags() & 1 > 0 and not self.Hidden
end

function maproomfunctions:IsShadow()
	return (self:GetDisplayFlags() or 0) & 2 > 0 and not self.Hidden
end

function maproomfunctions:IsIconVisible()
	return (self:GetDisplayFlags() or 0) & 4 > 0 and not self.Hidden
end

function maproomfunctions:IsVisited()
	return self.Visited or false
end

function maproomfunctions:GetPosition()
	return self.Position
end

function maproomfunctions:GetColor()
	if self.Color then
		return Color(self.Color.R, self.Color.G, self.Color.B, MinimapAPI:GetConfig("MinimapTransparency"), self.Color.RO,
			self.Color.GO, self.Color.BO)
	end
	return Color(MinimapAPI:GetConfig("DefaultRoomColorR"), MinimapAPI:GetConfig("DefaultRoomColorG"),
		MinimapAPI:GetConfig("DefaultRoomColorB"), MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)
end

function maproomfunctions:GetDisplayPosition()
	return self.DisplayPosition
end

function maproomfunctions:SetPosition(pos)
	self.Position = pos
	self:UpdateAdjacentRoomsCache()
end

function maproomfunctions:GetDisplayFlags()
	local roomDesc = self.Descriptor
	local df = self.DisplayFlags or 0
	if roomDesc and self.Type == RoomType.ROOM_ULTRASECRET and (roomDesc.DisplayFlags == 0 and self.DisplayFlags == 0)  then -- if red self is hidden and DFs not set
		if not self:IsVisited() then
			df = 0
		end
	else
		if roomDesc and not self.IgnoreDescriptorFlags then
			df = df | roomDesc.DisplayFlags
		end
		local hasCompass = false
		for i = 0, game:GetNumPlayers() - 1 do
			hasCompass = hasCompass or Isaac.GetPlayer(i):GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_COMPASS)
		end
		if self.Type and self.Type > 1 and not self.Hidden and hasCompass then
			df = df | 6
		end
	end
	return MinimapAPI:RunDisplayFlagsCallbacks(self, df)
end

function maproomfunctions:IsClear()
	return self.Clear or false
end

function maproomfunctions:SetDisplayFlags(df)
	if self.Descriptor then
		self.Descriptor.DisplayFlags = df
		self.DisplayFlags = df
	else
		self.DisplayFlags = df
	end
end

function maproomfunctions:Remove()
	local level = MinimapAPI:GetLevel()
	for i, v in ipairs(level) do
		if v == self then
			table.remove(level, i)
			return self
		end
	end
end

function maproomfunctions:UpdateAdjacentRoomsCache()
	if self.AdjacentRooms then
		for _, v in ipairs(self:GetAdjacentRooms()) do
			v:RemoveAdjacentRoom(self)
		end
	end
	self.AdjacentRooms = {}
	for _, v in ipairs(MinimapAPI.RoomShapeAdjacentCoords[self.Shape]) do
		local roomatpos = MinimapAPI:GetRoomAtPosition(self.Position + v)
		if roomatpos then
			self.AdjacentRooms[#self.AdjacentRooms + 1] = roomatpos
			roomatpos:AddAdjacentRoom(self)
		end
	end
end

function maproomfunctions:AddAdjacentRoom(adjroom)
	local adjrooms = self:GetAdjacentRooms()
	for _, v in ipairs(adjrooms) do
		if v == adjroom then return end
	end
	adjrooms[#adjrooms + 1] = adjroom
end

function maproomfunctions:RemoveAdjacentRoom(adjroom)
	local adjrooms = self:GetAdjacentRooms()
	for i, v in ipairs(adjrooms) do
		if v == adjroom then return table.remove(adjrooms, i) end
	end
end

function maproomfunctions:GetAdjacentRooms()
	if not self.AdjacentRooms then
		self:UpdateAdjacentRoomsCache()
	end
	return self.AdjacentRooms
end

function maproomfunctions:Reveal()
	if self.Hidden then
		self.DisplayFlags = self.DisplayFlags | 6
		self.Hidden = true
	else
		self.DisplayFlags = self.DisplayFlags | 5
	end
end

function maproomfunctions:UpdateType()
	local level = game:GetLevel()
	if self.Descriptor and self.Descriptor.Data and not self.NoUpdate then
		self.Type = self.Descriptor.Data.Type
		self.PermanentIcons = { MinimapAPI:GetRoomTypeIconID(self.Type) }

		if self.Descriptor.Data.Type == RoomType.ROOM_CHALLENGE and self.Descriptor.Data.Subtype == 1 then
			self.PermanentIcons = { "BossAmbushRoom" }
		end
		if MinimapAPI.isRepentance then
			if self.Descriptor.Flags & RoomDescriptor.FLAG_DEVIL_TREASURE == RoomDescriptor.FLAG_DEVIL_TREASURE then
				self.PermanentIcons = { "TreasureRoomRed" }
			end
			if self.Descriptor.Data.Type == RoomType.ROOM_DEFAULT then
				if IsAltPath() then
					if ((level:GetAbsoluteStage() == LevelStage.STAGE1_2 and not isCurseLabyrinth or level:GetAbsoluteStage() == LevelStage.STAGE1_1 and isCurseLabyrinth) or (StageAPI and StageAPI.Loaded and StageAPI.GetCurrentStage() and StageAPI.GetCurrentStage():HasMirrorDimension())) and self.Descriptor.Data.Subtype == 34 then
						self.VisitedIcons = { "MirrorRoom" }
					end

					if (level:GetAbsoluteStage() == LevelStage.STAGE2_2 and not isCurseLabyrinth or level:GetAbsoluteStage() == LevelStage.STAGE2_1 and isCurseLabyrinth) and roomDescriptor.Data.Subtype == 10 then
						self.VisitedIcons = { "MinecartRoom" }
					end
				end
			end
		end
		if override_greed and game:IsGreedMode() then
			if self.Descriptor.Data.Type == RoomType.ROOM_TREASURE and self.Descriptor.GridIndex == 98 then
				self.PermanentIcons = { "TreasureRoomGreed" }
			end
		end
	end
end

function maproomfunctions:SyncRoomDescriptor()
	if self.Descriptor and self.Descriptor.Data then
		self.Shape = self.Descriptor.Data.Shape
		self.PermanentIcons = {MinimapAPI:GetRoomTypeIconID(self.Descriptor.Data.Type)}
		self.LockedIcons = {MinimapAPI:GetUnknownRoomTypeIconID(self.Descriptor.Data.Type)}
		self.ItemIcons = {}
		self.VisitedIcons = {}
		self.Position = MinimapAPI:GridIndexToVector(self.Descriptor.SafeGridIndex)
		self.Descriptor = self.Descriptor
		self.AdjacentDisplayFlags = MinimapAPI.RoomTypeDisplayFlagsAdjacent[self.Descriptor.Data.Type] or 5
		self.Type = self.Descriptor.Data.Type
		self.Dimension = MinimapAPI.CurrentDimension
		self.Visited = self.Descriptor.VisitedCount > 0
		self.Clear = self.Descriptor.Clear
		self.Secret = self.Descriptor.Data.Type == RoomType.ROOM_SECRET or self.Descriptor.Data.Type == RoomType.ROOM_SUPERSECRET or self.Descriptor.Data.Type == RoomType.ROOM_ULTRASECRET
		self.Color = MinimapAPI.isRepentance and self.Descriptor.Flags & RoomDescriptor.FLAG_RED_ROOM == RoomDescriptor.FLAG_RED_ROOM and Color(1,0.25,0.25,1,0,0,0) or nil

		self:UpdateType()
	end
end

function maproomfunctions:IsValidTeleportTarget()
	local allowUnclear = MinimapAPI:GetConfig("MouseTeleportUncleared")
	return (
		self.TeleportHandler and self.TeleportHandler.CanTeleport
			and self.TeleportHandler:CanTeleport(self, allowUnclear)
		)
		or (
		not (self.TeleportHandler and self.TeleportHandler.CanTeleport)
			and (
			self:IsVisited() and self:IsClear()
				or (allowUnclear and self:IsVisible())
			)
		)
end

local maproommeta = {
	__index = maproomfunctions,
	__type = "MinimapAPI.Room"
}

---@param room MinimapAPI.Room # Not exactly a `MinimapAPI.Room`, but has same fields
---@return MinimapAPI.Room
function MinimapAPI:AddRoom(room)
	local defaultPosition = Vector(0,-1)
	local newRoom = {
		Position = room.Position or defaultPosition,
		DisplayPosition = room.DisplayPosition,
		Type = room.Type,
		ID = room.ID,
		Shape = room.Shape or RoomShape.ROOMSHAPE_1x1,
		PermanentIcons = room.PermanentIcons or {},
		LockedIcons = room.LockedIcons or {},
		ItemIcons = room.ItemIcons or {},
		VisitedIcons = room.VisitedIcons or {},
		Descriptor = room.Descriptor or nil,
		Color = room.Color or nil,
		RenderOffset = nil,
		DisplayFlags = room.DisplayFlags or 0,
		Clear = room.Clear or false,
		Visited = room.Visited or false,
		AdjacentDisplayFlags = room.AdjacentDisplayFlags or 5,
		Secret = room.Type == RoomType.ROOM_SECRET or room.Type == RoomType.ROOM_SUPERSECRET or room.Type == RoomType.ROOM_ULTRASECRET,
		Hidden = room.Hidden or nil,
		NoUpdate = room.NoUpdate or nil,
		Dimension = room.Dimension or MinimapAPI.CurrentDimension,
		IgnoreDescriptorFlags = room.IgnoreDescriptorFlags or false,
		TeleportHandler = room.TeleportHandler or nil,
	}
	setmetatable(newRoom, maproommeta)

	local level = MinimapAPI:GetLevel(newRoom.Dimension)

	if not level then
		MinimapAPI.Levels[newRoom.Dimension] = {}
		level = MinimapAPI.Levels[newRoom.Dimension]
	end

	level[#level + 1] = newRoom
	newRoom:SetPosition(newRoom.Position)
	return newRoom
end

local function removeAdjacentRoomRefs(room)
	if not room.AdjacentRooms then return end
	for _,v in ipairs(room.AdjacentRooms) do
		v:RemoveAdjacentRoom(room)
	end
end

function MinimapAPI:RemoveRoom(pos)
	assert(MinimapAPI:InstanceOf(pos, Vector), "bad argument #1 to 'RemoveRoom', expected Vector")
	local success = false
	local level = MinimapAPI:GetLevel()
	for i, v in ipairs(level) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			removeAdjacentRoomRefs(v)
			table.remove(level, i)
			success = true
			MinimapAPI:UpdateExternalMap()
			break
		end
	end
	return success
end

function MinimapAPI:RemoveRoomByID(id)
	local level = MinimapAPI:GetLevel()
	for i = #level, 1, -1 do
		local v = level[i]
		if v.ID == id then
			removeAdjacentRoomRefs(v)
			table.remove(level, i)
		end
	end
	MinimapAPI:UpdateExternalMap()
end

---@param position Vector
---@return MinimapAPI.Room | nil
function MinimapAPI:GetRoomAtPosition(position)
	assert(MinimapAPI:InstanceOf(position, Vector), "bad argument #1 to 'GetRoomAtPosition', expected Vector")
	for _, v in ipairs(MinimapAPI:GetLevel()) do
		for _,pos in ipairs(MinimapAPI.RoomShapePositions[v.Shape]) do
			local p = v.Position + pos
			if p.X == position.X and p.Y == position.Y then
				return v
			end
		end
	end
	return nil
end

---@param ID any
---@return MinimapAPI.Room | nil
function MinimapAPI:GetRoomByID(ID)
	for _, v in ipairs(MinimapAPI:GetLevel()) do
		if v.ID == ID then
			return v
		end
	end
	return nil
end

---@param Idx integer
---@return MinimapAPI.Room | nil
function MinimapAPI:GetRoomByIdx(Idx)
	for _, v in ipairs(MinimapAPI:GetLevel()) do
		if v.Descriptor and v.Descriptor.SafeGridIndex == Idx then
			return v
		end
	end
	return nil
end

local function isRoomAdj(room1,room2)
	for _,v in ipairs(MinimapAPI.RoomShapeAdjacentCoords[room1.Shape]) do
		local offsetpos = room1.Position + v
		if offsetpos.X == room2.Position.X and offsetpos.Y == room2.Position.Y then
			return true
		end
	end
	return false
end

function MinimapAPI:IsRoomAdjacent(room1, room2)
	return isRoomAdj(room1, room2) and isRoomAdj(room2, room1)
end

function MinimapAPI:GetPositionRelativeToDoor(room, doorslot)
	local p = MinimapAPI.RoomShapeDoorCoords[room.Shape][doorslot+1]
	if p then
		return p + room.Position
	else
		return nil
	end
end

function MinimapAPI:IsPositionFree(position,roomshape,dimension,redRoomsAreFree)
	roomshape = roomshape or 1
	dimension = dimension or MinimapAPI.CurrentDimension
	redRoomsAreFree = redRoomsAreFree or false

	-- treat red rooms as free positions
	if MinimapAPI.isRepentance and redRoomsAreFree then
		local idx = MinimapAPI:GridVectorToIndex(position)
		local roomDesc = cache.Level:GetRoomByIdx(idx, dimension)
		if roomDesc.Flags & RoomDescriptor.FLAG_RED_ROOM == RoomDescriptor.FLAG_RED_ROOM then
			return true
		end
	end

	for _,room in ipairs(MinimapAPI:GetLevel(dimension)) do
		for _,pos in ipairs(MinimapAPI.RoomShapePositions[room.Shape]) do
			for _,pos2 in ipairs(MinimapAPI.RoomShapePositions[roomshape]) do
				local p = pos + room.Position
				local p2 = position + pos2
				if p.X == p2.X and p.Y == p2.Y then
					return false
				end
			end
		end
	end
	return true
end

function MinimapAPI:GetPlayerPosition()
	return Vector(playerMapPos.X, playerMapPos.Y)
end

function MinimapAPI:UpdateMinimapCenterOffset(force)
	local currentroom = MinimapAPI:GetCurrentRoom()
	if currentroom then
		roomCenterOffset = playerMapPos - MinimapAPI.RoomShapeGridPivots[currentroom.Shape] + MinimapAPI:GetRoomShapeGridSize(currentroom.Shape) / 2
		roomCenterOffset = roomCenterOffset * Vector(MinimapAPI.GlobalScaleX, 1)
	elseif force then
		roomCenterOffset = playerMapPos + Vector(0.5, 0.5)
	end
end

function MinimapAPI:SetPlayerPosition(position)
	playerMapPos = Vector(position.X, position.Y)
end

function MinimapAPI:IsModTable(modtable)
	if type(modtable) == "table" and modtable.Name and modtable.AddCallback then
		return true
	end
	return false
end

-- Callbacks
-- it's recommended to use the vanilla callback system, old functions are kept as follows for backwards compatibility
-- try to handle both using a mod table as key
-- for backwards compatibility, and using a string

-- Use of a string as key or something else that doesn't change between
-- mod reloads is recommended
---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:AddPlayerPositionCallback(modkey, func)
	local modtable

	if MinimapAPI:IsModTable(modkey) then
		modtable = modkey
		modkey = modtable.Name
	end

	callbacks_playerpos[#callbacks_playerpos + 1] = {
		mod = modkey,
		modReference = modtable,
		call = func
	}
end

-- Use of a string as key or something else that doesn't change between
-- mod reloads is recommended
---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:AddDisplayFlagsCallback(modkey, func)
	local modtable

	if MinimapAPI:IsModTable(modkey) then
		modtable = modkey
		modkey = modtable.Name
	end

	callbacks_displayflags[#callbacks_displayflags + 1] = {
		mod = modkey,
		modReference = modtable,
		call = func
	}
end

-- Use of a string as key or something else that doesn't change between
-- mod reloads is recommended
---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:AddDimensionCallback(modkey, func)
	local modtable

	if MinimapAPI:IsModTable(modkey) then
		modtable = modkey
		modkey = modtable.Name
	end

	callbacks_dimension[#callbacks_dimension + 1] = {
		mod = modkey,
		modReference = modtable,
		call = func
	}
end

---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:RemoveAllCallbacks(modkey)
	MinimapAPI:RemovePlayerPositionCallbacks(modkey)
	MinimapAPI:RemoveDisplayFlagsCallbacks(modkey)
	MinimapAPI:RemoveDimensionCallbacks(modkey)
end

local function RemoveFromCallbackTable(tbl, modkey)
	if MinimapAPI:IsModTable(modkey) then
		modkey = modkey.Name
	end

	-- remove during iterate is bad if iteration continues
	local toRemove = {}
	for i, v in ipairs(tbl) do
		if v.mod == modkey then
			toRemove[#toRemove+1] = i
		end
	end
	for _, i in ipairs(toRemove) do
		table.remove(tbl, i)
	end
end

---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:RemovePlayerPositionCallbacks(modkey)
	RemoveFromCallbackTable(callbacks_playerpos, modkey)
end

---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:RemovePlayerPositionCallback(modkey)
	MinimapAPI:RemovePlayerPositionCallbacks(modkey)
end

---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:RemoveDisplayFlagsCallbacks(modkey)
	RemoveFromCallbackTable(callbacks_displayflags, modkey)
end

---@deprecated Use vanilla callbacks as defined in callbacks.lua
function MinimapAPI:RemoveDimensionCallbacks(modkey)
	RemoveFromCallbackTable(callbacks_dimension, modkey)
end

function MinimapAPI:GetCurrentRoom() --DOESNT ALWAYS RETURN SOMETHING!!!
	return MinimapAPI:GetRoomAtPosition(MinimapAPI:GetPlayerPosition())
end

function MinimapAPI:updatePlayerPos()
	local currentroom = cache.RoomDescriptor
	if currentroom.GridIndex < 0 then
		playerMapPos = Vector(-32768,-32768)
	else
		playerMapPos = MinimapAPI:GridIndexToVector(currentroom.GridIndex) + MinimapAPI.RoomShapeGridPivots[currentroom.Data.Shape]
	end
	MinimapAPI:RunPlayerPosCallbacks()
end

function MinimapAPI:IsBadLoad()
	local spr = Sprite()
	spr:Load("gfx/ui/minimap1.anm2", true)
	spr:SetFrame("RoomUnvisited", 0)
	spr:SetLastFrame()
	return spr:GetFrame() ~= 0
end

MinimapAPI:AddCallbackFunc(ModCallbacks.MC_POST_NEW_LEVEL, CALLBACK_PRIORITY, function(_)
	MinimapAPI:ClearLevels()
	MinimapAPI:LoadDefaultMap()
	MinimapAPI:updatePlayerPos()
	MinimapAPI:UpdateExternalMap()
end)

function MinimapAPI:UpdateUnboundedMapOffset()
	local maxx
	local miny
	for _, room in ipairs(MinimapAPI:GetLevel()) do
		if room:GetDisplayFlags() > 0 then
			local position = room.DisplayPosition or room.Position
			local maxxval = (
				position.X - MinimapAPI.RoomShapeGridPivots[room.Shape].X +
				(MinimapAPI.GlobalScaleX >= 0 and MinimapAPI:GetRoomShapeGridSize(room.Shape).X or 0)
			) * MinimapAPI.GlobalScaleX
			if not maxx or (maxxval > maxx) then
				maxx = maxxval
			end
			local minyval = position.Y
			if not miny or (minyval < miny) then
				miny = minyval
			end
		end
	end
	if maxx and miny then
		unboundedMapOffset = Vector(-maxx, -miny)
	end
end

local currentMapStateCopy = {}
local GlowingHourglassTriggered = false

MinimapAPI:AddCallbackFunc(ModCallbacks.MC_USE_ITEM, CALLBACK_PRIORITY, function(_, colltype, _)
	if colltype == CollectibleType.COLLECTIBLE_CRYSTAL_BALL then
		MinimapAPI:EffectCrystalBall()
		MinimapAPI:UpdateExternalMap()
	elseif MinimapAPI.isRepentance and colltype == CollectibleType.COLLECTIBLE_RED_KEY then
		MinimapAPI:CheckForNewRedRooms()
	elseif colltype == CollectibleType.COLLECTIBLE_DADS_KEY then
		if MinimapAPI:GetCurrentRoom() then
			for _,room in ipairs(MinimapAPI:GetCurrentRoom():GetAdjacentRooms()) do
				room:SetDisplayFlags(5)
			end
		end
		MinimapAPI:UpdateExternalMap()
	elseif colltype == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then
		GlowingHourglassTriggered = true
		if MinimapAPI.lastCardUsedRoom == MinimapAPI:GetCurrentRoom() then
			for _,v in ipairs(MinimapAPI.changedRoomsWithShowMap) do
				MinimapAPI:GetLevel()[v[1]].DisplayFlags = v[2]
			end
			MinimapAPI:UpdateExternalMap()
		end
	end
end)

if MinimapAPI.isRepentance then
	MinimapAPI:AddCallbackFunc(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, CALLBACK_PRIORITY, function(_)
		for i = 0, game:GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			if player:HasTrinket(TrinketType.TRINKET_CRYSTAL_KEY) or
				player:GetEffects():HasTrinketEffect(TrinketType.TRINKET_CRYSTAL_KEY) then
				MinimapAPI:CheckForNewRedRooms()
				return
			end
		end
	end)
end

function MinimapAPI:UpdateExternalMap()
	if MinimapAPI:GetConfig("ExternalMap") then
		local output = {}
		local extlevel = {}
		output.Level = extlevel
		for _,v in ipairs(MinimapAPI:GetLevel()) do
			if v:IsVisible() then
				local x = {
					Position = {X = v.Position.X, Y = v.Position.Y},
					Shape = v.Shape,
					PermanentIcons = #v.PermanentIcons > 0 and v.PermanentIcons or nil,
					ItemIcons = #v.ItemIcons > 0 and v.ItemIcons or nil,
					LockedIcons = #v.LockedIcons > 0 and v.LockedIcons or nil,
					VisitedIcons = #v.VisitedIcons > 0 and v.VisitedIcons or nil,
					DisplayFlags = v.DisplayFlags,
					Clear = v.Clear,
					Visited = v.Visited,
					Type = v.Type
				}
				if v.Color then
					x.Color = {R = v.Color.R, G = v.Color.G, B = v.Color.B, A = v.Color.A, RO = v.Color.RO, GO = v.Color.GO, BO = v.Color.BO}
				end
				extlevel[#extlevel + 1] = x
			end
		end
		output.PlayerPosition = {X = playerMapPos.X, Y = playerMapPos.Y}
		Isaac.DebugString("MinimapAPI.External "..json.encode(output))
	end
end


MinimapAPI:AddCallbackFunc(ModCallbacks.MC_POST_NEW_ROOM, CALLBACK_PRIORITY, function(_)
	MinimapAPI.CurrentDimension = cache.Dimension
	MinimapAPI:RunDimensionCallbacks()
	if not MinimapAPI:GetLevel() then
		MinimapAPI:LoadDefaultMap()
	end

	if MinimapAPI.isRepentance and not (game:GetLevel():GetStartingRoomIndex() == game:GetLevel():GetCurrentRoomIndex() and game:GetLevel():GetCurrentRoomDesc().VisitedCount == 1) then
		-- only check if not in level transition
		MinimapAPI:CheckForNewRedRooms()
	end
	MinimapAPI:updatePlayerPos()

	MinimapAPI:HandleCurseOfMaze()

	MinimapAPI.lastCardUsedRoom = nil
	if not GlowingHourglassTriggered then
		MinimapAPI:CopyLevels()
	else
		MinimapAPI:RewindLevels()
	end
	GlowingHourglassTriggered = false

	MinimapAPI:UpdateExternalMap()
end)

function MinimapAPI:CopyLevels()
	currentMapStateCopy = {}
	for i, lvl in pairs(MinimapAPI.Levels) do
		currentMapStateCopy[i] = {}
		for index, room in pairs(lvl) do
			local roomCopy ={
				AdjacentDisplayFlags= room.AdjacentDisplayFlags,
				Color= room.Color,
				Descriptor= room.Descriptor,
				Dimension= room.Dimension,
				DisplayFlags= room.DisplayFlags,
				DisplayPosition= room.DisplayPosition,
				Hidden= room.Hidden,
				ID= room.ID,
				IgnoreDescriptorFlags= room.IgnoreDescriptorFlags,
				NoUpdate= room.NoUpdate,
				RenderOffset= room.RenderOffset,
				Shape= room.Shape,
				Secret = room.Secret,
				ItemIcons= MinimapAPI:DeepCopy(room.ItemIcons),
				LockedIcons= MinimapAPI:DeepCopy(room.LockedIcons),
				PermanentIcons= MinimapAPI:DeepCopy(room.PermanentIcons),
				VisitedIcons= MinimapAPI:DeepCopy(room.VisitedIcons),
			}
			currentMapStateCopy[i][index] = roomCopy
		end
	end
end

function MinimapAPI:RewindLevels()
	MinimapAPI:ClearLevels()
	MinimapAPI:LoadDefaultMap()
	MinimapAPI:updatePlayerPos()
	for i, lvl in pairs(currentMapStateCopy) do
		if MinimapAPI.Levels[i] then
			for index, room in pairs(lvl) do
				local newRoom = MinimapAPI.Levels[i][index]
				if newRoom then -- safety check for corrupted rewind data
					newRoom.AdjacentDisplayFlags= room.AdjacentDisplayFlags
					newRoom.Color= room.Color
					newRoom.Descriptor= room.Descriptor
					newRoom.Dimension= room.Dimension
					newRoom.DisplayFlags= room.DisplayFlags
					newRoom.DisplayPosition= room.DisplayPosition
					newRoom.Hidden= room.Hidden
					newRoom.ID= room.ID
					newRoom.IgnoreDescriptorFlags= room.IgnoreDescriptorFlags
					newRoom.NoUpdate= room.NoUpdate
					newRoom.RenderOffset= room.RenderOffset
					newRoom.Shape= room.Shape
					newRoom.Secret = room.Secret
					newRoom.ItemIcons= MinimapAPI:DeepCopy(room.ItemIcons)
					newRoom.LockedIcons= MinimapAPI:DeepCopy(room.LockedIcons)
					newRoom.PermanentIcons= MinimapAPI:DeepCopy(room.PermanentIcons)
					newRoom.VisitedIcons= MinimapAPI:DeepCopy(room.VisitedIcons)
				end
			end
		end
	end
end

function MinimapAPI:HandleCurseOfMaze()
	if game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_MAZE ~= LevelCurse.CURSE_OF_MAZE then
		return
	end
	local changedRooms = {}
	for i,room in ipairs(MinimapAPI:GetLevel()) do
		if room.Descriptor and room.Descriptor.Data then
			if room.LastDataVariant and room.LastDataVariant ~= room.Descriptor.Data.Variant then
				table.insert(changedRooms, i)
			end
			room.LastDataVariant = room.Descriptor.Data.Variant
		end
	end
	if #changedRooms >= 2 then
		local room1 = MinimapAPI:GetLevel()[changedRooms[1]]
		local room2 = MinimapAPI:GetLevel()[changedRooms[2]]
		local room1Pos = room1.Position
		room1.Position = room2.Position
		room2.Position = room1Pos
	end
end

function MinimapAPI:ShowMap()
	MinimapAPI.changedRoomsWithShowMap = {}
	for i,v in ipairs(MinimapAPI:GetLevel()) do
		table.insert(MinimapAPI.changedRoomsWithShowMap, {i,v.DisplayFlags})
		if v.Hidden then
			v.DisplayFlags = 6
		else
			v.DisplayFlags = 5
		end
	end
	MinimapAPI:UpdateExternalMap()
end

MinimapAPI:AddCallbackFunc(ModCallbacks.MC_USE_CARD, CALLBACK_PRIORITY, function(_, card)
	if card == Card.CARD_WORLD or card == Card.CARD_SUN or card == Card.RUNE_ANSUZ then
		MinimapAPI.lastCardUsedRoom = MinimapAPI:GetCurrentRoom()
	elseif MinimapAPI.isRepentance and card == Card.CARD_CRACKED_KEY or card == Card.CARD_SOUL_CAIN then
		--Update visibility of adjacent rooms like secret rooms
		for _,room in ipairs(MinimapAPI:GetCurrentRoom():GetAdjacentRooms()) do
			room:SetDisplayFlags(5)
		end
		MinimapAPI:CheckForNewRedRooms()
	end
end)

function MinimapAPI:PrevMapDisplayMode()
	local modes = {
		[1] = MinimapAPI:GetConfig("AllowToggleSmallMap"),
		[2] = MinimapAPI:GetConfig("AllowToggleBoundedMap"),
		[3] = MinimapAPI:GetConfig("AllowToggleLargeMap"),
		[4] = MinimapAPI:GetConfig("AllowToggleNoMap"),
	}
	for _ = 1, 4 do
		MinimapAPI.Config.DisplayMode = MinimapAPI.Config.DisplayMode - 1
		if MinimapAPI.Config.DisplayMode < 1 then
			MinimapAPI.Config.DisplayMode = 4
		end
		if modes[MinimapAPI.Config.DisplayMode] then
			break
		end
	end
end

function MinimapAPI:NextMapDisplayMode()
	local modes = {
		[1] = MinimapAPI:GetConfig("AllowToggleSmallMap"),
		[2] = MinimapAPI:GetConfig("AllowToggleBoundedMap"),
		[3] = MinimapAPI:GetConfig("AllowToggleLargeMap"),
		[4] = MinimapAPI:GetConfig("AllowToggleNoMap"),
	}
	for _ = 1, 4 do
		MinimapAPI.Config.DisplayMode = MinimapAPI.Config.DisplayMode + 1
		if MinimapAPI.Config.DisplayMode > 4 then
			MinimapAPI.Config.DisplayMode = 1
		end
		if modes[MinimapAPI.Config.DisplayMode] then
			break
		end
	end
end

function MinimapAPI:FirstMapDisplayMode()
	local modes = {
		[1] = MinimapAPI:GetConfig("AllowToggleSmallMap"),
		[2] = MinimapAPI:GetConfig("AllowToggleBoundedMap"),
		[3] = MinimapAPI:GetConfig("AllowToggleLargeMap"),
		[4] = MinimapAPI:GetConfig("AllowToggleNoMap"),
	}

	MinimapAPI.Config.DisplayMode = 1

	for i = 1, 4 do
		if modes[i] then
			MinimapAPI.Config.DisplayMode = i
			break
		end
	end
end

MinimapAPI:AddCallbackFunc(ModCallbacks.MC_INPUT_ACTION, CALLBACK_PRIORITY, function(_, entity, _, buttonAction)

	if entity and buttonAction == ButtonAction.ACTION_MAP then
		local player = entity:ToPlayer()
		if player then
			if Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex) then
				mapheldframes = mapheldframes + 1
			elseif mapheldframes > 0 then
				if mapheldframes <= 8 or (MinimapAPI:GetConfig("DisplayMode") == 3 and mapheldframes == 9) then -- this is dumb but for some reason it works
					MinimapAPI:NextMapDisplayMode()
				end

				mapheldframes = 0
			end
		end
	end
end, InputHook.IS_ACTION_PRESSED)

local defaultColor = Color(1, 1, 1, 1, 0, 0, 0)
local function updateMinimapIcon(spr, t)
	if t.anim then
		spr:SetFrame(t.anim, t.frame or 0)
	end
	if t.Color then
		spr.Color = t.Color or defaultColor
	end
end

local function renderMinimapLevelFlags(renderOffset)
	local offset = vectorZero

	for _, mapFlag in ipairs(MinimapAPI.MapFlags) do
		if (mapFlag.condition()) then
			local frame

			-- Frame can be a function for indicators that might change, like zodiac indicator
			if type(mapFlag.frame) == "function" then
				frame = mapFlag.frame()
			else
				frame = mapFlag.frame
			end

			mapFlag.sprite.Color = Color(1,1,1,MinimapAPI:GetConfig("MinimapTransparency"),0,0,0)
			mapFlag.sprite:SetFrame(mapFlag.anim, frame)
			mapFlag.sprite:Render(renderOffset + offset, vectorZero, vectorZero)

			if MinimapAPI:GetConfig("DisplayLevelFlags") == 1 then -- LEFT
				offset = offset + Vector(0, 16)
			else -- BOTTOM
				offset = offset + Vector(-16, 0)
			end
		end
	end
end


---@return integer
local function renderIcons(icons, locs, k, room, sprite, size, renderRoomSize)
	for _, icon in ipairs(icons) do
		local icontb = MinimapAPI:GetIconAnimData(icon)
		if icontb then
			local loc = locs[k]
			if not loc then return k end
			local iconlocOffset = Vector(loc.X * renderRoomSize.X, loc.Y * renderRoomSize.Y)
			local spr = icontb.sprite or sprite
			updateMinimapIcon(spr, icontb)
			spr.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
			local pos = iconlocOffset
			if size ~= "small" then
				pos = pos + largeIconOffset - largeRoomAnimPivot
			end
			pos.X = pos.X * MinimapAPI.GlobalScaleX
			pos = pos + room.RenderOffset
			spr.Color = Color(1, 1, 1, MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)
			spr:Render(pos, vectorZero, vectorZero)
			k = k + 1
		end
	end
	return k
end

function MinimapAPI:renderQuestionMark(offsetVec)
	MinimapAPI.SpriteQuestionmark:Render(offsetVec, vectorZero, vectorZero)
end

local function renderUnboundedMinimap(size,hide)
	local screen_size = MinimapAPI:GetScreenTopRight()
	local offsetVec = Vector(screen_size.X - MinimapAPI:GetConfig("PositionX"), screen_size.Y + MinimapAPI:GetConfig("PositionY"))
	if not(MinimapAPI:GetConfig("OverrideLost") or game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0) then
		MinimapAPI:renderQuestionMark(offsetVec + Vector(-10,10))
		return
	end
	MinimapAPI:UpdateUnboundedMapOffset()
	local renderRoomSize = size == "small" and roomSize or largeRoomSize
	local renderAnimPivot = size == "small" and roomAnimPivot or largeRoomAnimPivot
	local sprite = size == "small" and MinimapAPI.SpriteMinimapSmall or MinimapAPI.SpriteMinimapLarge

	sprite.Scale = Vector(MinimapAPI.GlobalScaleX, 1)

	for _, level in pairs(MinimapAPI.Levels) do
		for _,room in ipairs(level) do
			local roomPos = room.DisplayPosition or room.Position
			local roomOffset = Vector(MinimapAPI.GlobalScaleX * roomPos.X, roomPos.Y) + unboundedMapOffset
			roomOffset.X = roomOffset.X * renderRoomSize.X
			roomOffset.Y = roomOffset.Y * renderRoomSize.Y
			room.TargetRenderOffset = offsetVec + roomOffset + renderAnimPivot
			if hide then
				room.TargetRenderOffset = room.TargetRenderOffset + Vector(0,-800)
			end
			if room.RenderOffset then
				room.RenderOffset = room.TargetRenderOffset * MinimapAPI:GetConfig("SmoothSlidingSpeed") + room.RenderOffset * (1 - MinimapAPI:GetConfig("SmoothSlidingSpeed"))
			else
				room.RenderOffset = room.TargetRenderOffset
			end
			if room.RenderOffset:DistanceSquared(room.TargetRenderOffset) <= 1 then
				room.RenderOffset = room.TargetRenderOffset
			end
		end
	end

	if hide then return end

	MinimapAPI:renderRoomShadows(false)

	for _, room in pairs(MinimapAPI:GetLevel()) do
		local iscurrent = MinimapAPI:PlayerInRoom(room)
		if room:IsVisible() then
			local frame = MinimapAPI:GetRoomShapeFrame(room.Shape)
			local anim
			local spr = sprite
			if iscurrent then
				anim = "RoomCurrent"
			elseif room:IsClear() then
				anim = "RoomVisited"
			elseif MinimapAPI:GetConfig("DisplayExploredRooms") and room:IsVisited() then
				spr = size == "small" and MinimapAPI.SpriteMinimapCustomSmall or MinimapAPI.SpriteMinimapCustomLarge
				anim = "RoomSemivisited"
			else
				anim = "RoomUnvisited"
			end
			spr.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
			if MinimapAPI:GetConfig("VanillaSecretRoomDisplay") and (room.PermanentIcons[1] == "SecretRoom" or room.PermanentIcons[1] == "SuperSecretRoom") and anim == "RoomUnvisited" then
				-- skip room rendering for secret rooms so only shadow is visible
				if not MinimapAPI:GetConfig("ShowShadows") then
					spr.Color = Color(0, 0, 0, MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)
					spr:SetFrame(anim, frame)
					spr:Render(room.RenderOffset, vectorZero, vectorZero)
					spr.Color = room:GetColor()
				end
			elseif type(frame) == "table" then
				local fr0 = frame[size == "small" and "small" or "large"]
				local fr1 = fr0[anim] or fr0["RoomUnvisited"]
				spr = fr1.sprite or sprite
				updateMinimapIcon(spr, fr1)
			else
				spr:SetFrame(anim, frame)
			end
			spr.Color = room:GetColor()
			spr:Render(room.RenderOffset, vectorZero, vectorZero)
		end
	end
	if size == "huge" then
		if MinimapAPI:GetConfig("ShowGridDistances") then
			for _, room in pairs(MinimapAPI:GetLevel()) do
				if room.PlayerDistance then
					local s = tostring(room.PlayerDistance)
					local offsetX = 7
					if MinimapAPI.TargetGlobalScaleX < 0 then
						offsetX = offsetX * MinimapAPI.TargetGlobalScaleX * 3 + 2
					end
					font:DrawString(s, room.RenderOffset.X + offsetX, room.RenderOffset.Y + 3,
						KColor(0.2, 0.2, 0.2, MinimapAPI:GetConfig("MinimapTransparency")), 0, false)
				end
			end
		end

		if MinimapAPI:GetConfig("HighlightStartRoom") then
			local startRoom = MinimapAPI:GetRoomByIdx(game:GetLevel():GetStartingRoomIndex())
			if startRoom then
				startRoom.Color = Color(0, 1, 0, MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)
			end
		end

		if MinimapAPI:GetConfig("HighlightFurthestRoom") then
			local furthestRoom = nil
			local furthestDist = 1
			for _, room in pairs(MinimapAPI:GetLevel()) do
				local dist = room.PlayerDistance
				if dist then
					if furthestDist < dist and room:GetDisplayFlags() & 0x2 == 0 then
						furthestRoom = room
						furthestDist = dist
					end
				end
			end
			if furthestRoom ~= nil then
				if furthestRoom:GetDisplayFlags() ~= 5 then
					furthestRoom.Color = Color(1, 0, 0, MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)
				else
					furthestRoom.Color = Color(1, 1, 1, MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)
				end
			end
		end
	end

	if MinimapAPI:GetConfig("ShowIcons") then
		sprite = MinimapAPI.SpriteIcons

		for _, room in pairs(MinimapAPI:GetLevel()) do
			local incurrent = MinimapAPI:PlayerInRoom(room) and not MinimapAPI:GetConfig("ShowCurrentRoomItems")
			local k = 1

			if room:IsIconVisible() then
				local iconcount = #room.PermanentIcons
				if room:IsVisited() then
					iconcount = iconcount + #room.VisitedIcons
				end
				if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
					iconcount = iconcount + #room.ItemIcons
				end

				local locs = MinimapAPI:GetRoomShapeIconPositions(room.Shape, iconcount)
				if size ~= "small" then
					locs = MinimapAPI:GetLargeRoomShapeIconPositions(room.Shape, iconcount)
				end

				k = renderIcons(room.PermanentIcons, locs, k, room, sprite, size, renderRoomSize)
				if room:IsVisited() then
					k = renderIcons(room.VisitedIcons, locs, k, room, sprite, size, renderRoomSize)
				end
				if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
					k = renderIcons(room.ItemIcons, locs, k, room, sprite, size, renderRoomSize)
				end
			elseif room:IsShadow() then
				if room.LockedIcons and #room.LockedIcons > 0 then
					local locs = MinimapAPI:GetRoomShapeIconPositions(room.Shape, #room.LockedIcons)
					if size ~= "small" then
						locs = MinimapAPI:GetLargeRoomShapeIconPositions(room.Shape, #room.LockedIcons)
					end
					k = renderIcons(room.LockedIcons, locs, k, room, sprite, size, renderRoomSize)
				end
			end
		end
	end
end

local function renderBoundedMinimap()
	local screen_size = MinimapAPI:GetScreenTopRight()
	local offsetVec = Vector( screen_size.X - MinimapAPI:GetConfig("MapFrameWidth") - MinimapAPI:GetConfig("PositionX") + outlinePixelSize.X, screen_size.Y + MinimapAPI:GetConfig("PositionY") - outlinePixelSize.Y/2 - 2)
	do
		local frameWidth = ((MinimapAPI:GetConfig("MapFrameWidth") + frameTL.X) / dframeHorizBarSize.X) -- * MinimapAPI.GlobalScaleX

		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,MinimapAPI:GetConfig("BorderColorA"),MinimapAPI:GetConfig("BorderColorR") * dlcColorMult, MinimapAPI:GetConfig("BorderColorG") * dlcColorMult, MinimapAPI:GetConfig("BorderColorB") * dlcColorMult)
		MinimapAPI.SpriteMinimapSmall.Scale = Vector(frameWidth, 1)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameN", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec, vectorZero, vectorZero)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameS", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + Vector(0, MinimapAPI:GetConfig("MapFrameHeight")), vectorZero, vectorZero)

		MinimapAPI.SpriteMinimapSmall.Scale = Vector(1, (MinimapAPI:GetConfig("MapFrameHeight")-2) / dframeVertBarSize.Y)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameW", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec+Vector(0,2), vectorZero, vectorZero)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameE", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec+Vector(0,2) + Vector(MinimapAPI:GetConfig("MapFrameWidth"), 0), vectorZero, vectorZero)

		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,MinimapAPI:GetConfig("BorderBgColorA"), MinimapAPI:GetConfig("BorderBgColorR") * dlcColorMult,MinimapAPI:GetConfig("BorderBgColorG") * dlcColorMult, MinimapAPI:GetConfig("BorderBgColorB") * dlcColorMult)
		MinimapAPI.SpriteMinimapSmall.Scale =
			Vector(((MinimapAPI:GetConfig("MapFrameWidth") - frameTL.X) / dframeCenterSize.X), (MinimapAPI:GetConfig("MapFrameHeight") - frameTL.Y) / dframeCenterSize.Y)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameCenter", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + frameTL, vectorZero, vectorZero)

		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,MinimapAPI:GetConfig("BorderColorA"),0,0,0)

		MinimapAPI.SpriteMinimapSmall.Scale = Vector(((MinimapAPI:GetConfig("MapFrameWidth") + frameTL.X) / dframeHorizBarSize.X), 1)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameShadowS", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + Vector(frameTL.X, frameTL.Y + MinimapAPI:GetFrameBR().Y), vectorZero, vectorZero)

		MinimapAPI.SpriteMinimapSmall.Scale = Vector(1, (MinimapAPI:GetConfig("MapFrameHeight")) / (dframeVertBarSize.Y - frameTL.Y))
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameShadowE", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + Vector(frameTL.X + MinimapAPI:GetFrameBR().X, frameTL.Y), vectorZero, vectorZero)

		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,MinimapAPI:GetConfig("MinimapTransparency"),0,0,0)
		MinimapAPI.SpriteMinimapSmall.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
	end

	if not(MinimapAPI:GetConfig("OverrideLost") or game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0) then
		MinimapAPI:renderQuestionMark(offsetVec + Vector(MinimapAPI:GetConfig("MapFrameWidth")/2,MinimapAPI:GetConfig("MapFrameHeight")/2))
		return
	end
	MinimapAPI:UpdateMinimapCenterOffset()

	for _, level in pairs(MinimapAPI.Levels) do
		for _, v in ipairs(level) do
			local roomOffset = (v.DisplayPosition or v.Position) * Vector(MinimapAPI.GlobalScaleX, 1) - roomCenterOffset
			roomOffset.X = roomOffset.X * roomSize.X
			roomOffset.Y = roomOffset.Y * roomSize.Y
			v.TargetRenderOffset = offsetVec + roomOffset + MinimapAPI:GetFrameCenterOffset() + roomAnimPivot
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI:GetConfig("SmoothSlidingSpeed") + v.RenderOffset * (1 - MinimapAPI:GetConfig("SmoothSlidingSpeed"))
			else
				v.RenderOffset = v.TargetRenderOffset
			end
		end
	end

	MinimapAPI:renderRoomShadows(true)

	for _, room in pairs(MinimapAPI:GetLevel()) do
		local iscurrent = MinimapAPI:PlayerInRoom(room)
		local spr = MinimapAPI.SpriteMinimapSmall
		if room:IsVisible() then
			local frame = MinimapAPI:GetRoomShapeFrame(room.Shape)
			local anim
			if iscurrent then
				anim = "RoomCurrent"
			elseif room:IsClear() then
				anim = "RoomVisited"
			elseif MinimapAPI:GetConfig("DisplayExploredRooms") and room:IsVisited() then
				spr = MinimapAPI.SpriteMinimapCustomSmall
				anim = "RoomSemivisited"
			else
				anim = "RoomUnvisited"
			end
			if type(frame) == "table" then
				local fr0 = frame.small
				local fr1 = fr0[anim] or fr0["RoomUnvisited"]
				spr = fr1.sprite or spr
				updateMinimapIcon(spr, fr1)
			else
				spr:SetFrame(anim, frame)
			end
			local rms = MinimapAPI:GetRoomShapeGridSize(room.Shape)
			local rsgp = MinimapAPI.RoomShapeGridPivots[room.Shape]
			local roomPivotOffset = Vector((roomPixelSize.X - 1) * rsgp.X, (roomPixelSize.Y - 1) * rsgp.Y)
			local roomPixelBR = Vector(roomPixelSize.X * rms.X, roomPixelSize.Y * rms.Y) - roomAnimPivot
			local brcutoff = room.RenderOffset - offsetVec + roomPixelBR - MinimapAPI:GetFrameBR() - roomPivotOffset
			local tlcutoff = -(room.RenderOffset - offsetVec - roomPivotOffset)
			if brcutoff.X < roomPixelBR.X and brcutoff.Y < roomPixelBR.Y and
				tlcutoff.X - roomPivotOffset.X < roomPixelBR.X and tlcutoff.Y - roomPivotOffset.Y < roomPixelBR.Y then
				brcutoff:Clamp(0, 0, roomPixelBR.X, roomPixelBR.Y)
				tlcutoff:Clamp(0, 0, roomPixelBR.X, roomPixelBR.Y)
				spr.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
				spr.Color = room:GetColor()
				spr:Render(room.RenderOffset, tlcutoff, brcutoff)
			end
		end
	end
	MinimapAPI.SpriteMinimapSmall.Color = Color(1, 1, 1, MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)

	if MinimapAPI:GetConfig("ShowIcons") then
		for _, room in pairs(MinimapAPI:GetLevel()) do
			local incurrent = MinimapAPI:PlayerInRoom(room) and not MinimapAPI:GetConfig("ShowCurrentRoomItems")
			local k = 1
			local function renderIconsInlineFunc(icons, locs)
				for _, icon in ipairs(icons) do
					local icontb = MinimapAPI:GetIconAnimData(icon)
					if icontb then
						local loc = locs[k]
						if not loc then return end

						local iconlocOffset = Vector(loc.X * roomSize.X, loc.Y * roomSize.Y)
						local spr = icontb.sprite or MinimapAPI.SpriteIcons
						spr.Color = Color(1, 1, 1, MinimapAPI:GetConfig("MinimapTransparency"), 0, 0, 0)
						updateMinimapIcon(spr, icontb)
						local brcutoff = room.RenderOffset - offsetVec + iconlocOffset + iconPixelSize - MinimapAPI:GetFrameBR()
						local tlcutoff = frameTL - (room.RenderOffset - offsetVec + iconlocOffset)
						if brcutoff.X < iconPixelSize.X and brcutoff.Y < iconPixelSize.Y and
							tlcutoff.X < iconPixelSize.X and tlcutoff.Y < iconPixelSize.Y then
							brcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
							tlcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
							spr.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
							spr:Render(iconlocOffset + room.RenderOffset, tlcutoff, brcutoff)
							k = k + 1
						end
					end
				end
			end

			if room:IsIconVisible() then
				local iconcount = #room.PermanentIcons
				if room:IsVisited() then
					iconcount = iconcount + #room.VisitedIcons
				end
				if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
					iconcount = iconcount + #room.ItemIcons
				end

				local locs = MinimapAPI:GetRoomShapeIconPositions(room.Shape, iconcount)

				renderIconsInlineFunc(room.PermanentIcons, locs)
				if room:IsVisited() then
					renderIconsInlineFunc(room.VisitedIcons, locs)
				end
				if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
					renderIconsInlineFunc(room.ItemIcons, locs)
				end
			elseif room:IsShadow() then
				if room.LockedIcons and #room.LockedIcons > 0 then
					local locs = MinimapAPI:GetRoomShapeIconPositions(room.Shape, #room.LockedIcons)
					renderIconsInlineFunc(room.LockedIcons, locs)
				end
			end
		end
	end
end

function MinimapAPI:renderRoomShadows(useCutOff)
	if not (MinimapAPI:GetConfig("ShowShadows") and MinimapAPI:GetConfig("MinimapTransparency") == 1) then
		return
	end
	local defaultOutlineColor = Color(1, 1, 1, MinimapAPI:GetConfig("MinimapTransparency"), MinimapAPI:GetConfig("DefaultOutlineColorR") * dlcColorMult, MinimapAPI:GetConfig("DefaultOutlineColorG") * dlcColorMult, MinimapAPI:GetConfig("DefaultOutlineColorB") * dlcColorMult)
	local renderRoomSize = not MinimapAPI:IsLarge() and roomSize or largeRoomSize
	local screen_size = MinimapAPI:GetScreenTopRight()
	local offsetVec = Vector( screen_size.X - MinimapAPI:GetConfig("MapFrameWidth") - MinimapAPI:GetConfig("PositionX") + outlinePixelSize.X, screen_size.Y + MinimapAPI:GetConfig("PositionY") - outlinePixelSize.Y/2 - 2)

	local sprite = not MinimapAPI:IsLarge() and MinimapAPI.SpriteMinimapSmall or MinimapAPI.SpriteMinimapLarge
	sprite.Color = defaultOutlineColor
	sprite:SetFrame("RoomOutline", 1)

	for _, room in pairs(MinimapAPI:GetLevel()) do
		if room:IsShadow() or room:IsVisible() then
			for _, pos in ipairs(MinimapAPI:GetRoomShapePositions(room.Shape)) do
				pos = Vector(pos.X * renderRoomSize.X * MinimapAPI.GlobalScaleX, pos.Y * renderRoomSize.Y)
				if useCutOff then
					local actualRoomPixelSize = outlinePixelSize
					local brcutoff = room.RenderOffset - offsetVec + pos + actualRoomPixelSize - MinimapAPI:GetFrameBR()
					if brcutoff.X < actualRoomPixelSize.X and brcutoff.Y < actualRoomPixelSize.Y then
						local tlcutoff = -(room.RenderOffset - offsetVec + pos) + frameTL
						if tlcutoff.X < actualRoomPixelSize.X and tlcutoff.Y < actualRoomPixelSize.Y then
							brcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
							tlcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
							sprite:Render(room.RenderOffset + pos, tlcutoff, brcutoff)
						end
					end
				else
					sprite:Render(room.RenderOffset + pos, vectorZero, vectorZero)
				end
			end
		end
	end
end

local function renderCallbackFunction(_)
	if MinimapAPI:GetConfig("Disable") or MinimapAPI.Disable then return end

	if badload then
		local fontColor = KColor(1,0.5,0.5,1)
		font:DrawString("MinimapAPI animation files failed to load.",70,30,fontColor,0,false)
		font:DrawString("Restart your game!",70,40,fontColor,0,false)

		font:DrawString("(This tends to happen when the mod is first installed, or when",70,60,fontColor,0,false)
		font:DrawString("it is re-enabled via the mod menu)",70,70,fontColor,0,false)

		font:DrawString("You will also need to restart the game after disabling the mod.",70,90,fontColor,0,false)
		return
	end

	local gameroom = game:GetRoom()
	-- Hide in boss intro cutscene
	if gameroom:GetFrameCount() == 0 and gameroom:GetType() == RoomType.ROOM_BOSS and not gameroom:IsClear() then
		return
	end
	-- Hide in Mega Satan (BossID: 55) fight
	if gameroom:GetType() == RoomType.ROOM_BOSS and gameroom:GetBossID() == 55 then
		return
	end
	-- Hide in Beast fight
	if MinimapAPI.isRepentance and gameroom:GetType() == RoomType.ROOM_DUNGEON and game:GetLevel():GetAbsoluteStage() == LevelStage.STAGE8 then
		return
	end

	if MinimapAPI:GetConfig("HideInCombat") == 2 then
		if not gameroom:IsClear() and gameroom:GetType() == RoomType.ROOM_BOSS then
			return
		end
	elseif MinimapAPI:GetConfig("HideInCombat") == 3 then
		if not gameroom:IsClear() then
			return
		end
	end

	--Hide during StageAPI reimplemented stage transition
	if MinimapAPI.UsingPostHUDRender and StageAPI.TransitionAnimationData.State == 2 then
		return
	end

	MinimapAPI.TargetGlobalScaleX = cache.MirrorDimension and -1 or 1

	if MinimapAPI.ValueGlobalScaleX < MinimapAPI.TargetGlobalScaleX then
		MinimapAPI.ValueGlobalScaleX = math.min(MinimapAPI.ValueGlobalScaleX + 0.2, MinimapAPI.TargetGlobalScaleX)
	elseif MinimapAPI.ValueGlobalScaleX > MinimapAPI.TargetGlobalScaleX then
		MinimapAPI.ValueGlobalScaleX = math.max(MinimapAPI.ValueGlobalScaleX - 0.2, MinimapAPI.TargetGlobalScaleX)
	end
	MinimapAPI.GlobalScaleX = MinimapAPI.ValueGlobalScaleX

	if MinimapAPI:IsHUDVisible() or MinimapAPI.ForceMapRender then
		MinimapAPI.ForceMapRender = false
		local currentroomdata = MinimapAPI:GetCurrentRoom()
		local gamelevel = game:GetLevel()
		local hasSpelunkerHat = false
		for i = 0, game:GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			hasSpelunkerHat = hasSpelunkerHat or (player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_SPELUNKER_HAT) and not MinimapAPI.DisableSpelunkerHat)
		end
		if currentroomdata and MinimapAPI:PickupDetectionEnabled() then
			if not currentroomdata.NoUpdate then
				currentroomdata.ItemIcons = MinimapAPI:GetCurrentRoomPickupIDs()
				currentroomdata.DisplayFlags = 5
				currentroomdata.Clear = gamelevel:GetCurrentRoomDesc().Clear
				currentroomdata.Visited = true
			end
			if currentroomdata.Secret then
				-- Special handling for Secret rooms and updating the adjacent room visibility
				for _,doorslot in ipairs(MinimapAPI.RoomShapeDoorSlots[currentroomdata.Shape]) do
					local doorent = gameroom:GetDoor(doorslot)
					if doorent and doorent:IsOpen() then
						local coord = currentroomdata.Position + MinimapAPI.RoomShapeDoorCoords[currentroomdata.Shape][doorslot+1]
						local room = MinimapAPI:GetRoomAtPosition(coord)
						if room then
							room:Reveal()
						end
					end
				end
			else
				for _,adjroom in ipairs(currentroomdata:GetAdjacentRooms()) do
					if not adjroom.NoUpdate then
						adjroom.DisplayFlags = adjroom.DisplayFlags | (hasSpelunkerHat and (adjroom.Hidden and 6 or 5) or adjroom.AdjacentDisplayFlags)
					end
				end
			end
		end

		if not currentroomdata and MinimapAPI:GetConfig("HideInInvalidRoom") then
			return
		end

		if currentroomdata and (MinimapAPI:GetConfig("ShowGridDistances") or MinimapAPI:GetConfig("HighlightFurthestRoom")) then
			for _,room in ipairs(MinimapAPI:GetLevel()) do
				room.PlayerDistance = nil
			end
			currentroomdata.PlayerDistance = 0

			local function calcadjdistances(thisroom)
				for _,room in ipairs(thisroom:GetAdjacentRooms()) do
					if room.PlayerDistance == nil or (room.PlayerDistance and room.PlayerDistance > thisroom.PlayerDistance + 1) then
						if room:GetDisplayFlags() > 0 then
							room.PlayerDistance = thisroom.PlayerDistance + 1
							calcadjdistances(room)
						else
							room.PlayerDistance = false
						end
					end
				end
			end

			calcadjdistances(currentroomdata)
		end

		--update map display flags
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) then
			for _,v in ipairs(MinimapAPI:GetLevel()) do
				if not v.Secret then
					v.DisplayFlags = v.DisplayFlags | 1
				end
			end
		end
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) then
			for _,v in ipairs(MinimapAPI:GetLevel()) do
				if v.Secret and v.Type ~= RoomType.ROOM_ULTRASECRET then
					v.DisplayFlags = v.DisplayFlags | 5
				end
			end
		end
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) then
			for _,v in ipairs(MinimapAPI:GetLevel()) do
				if #v.PermanentIcons > 0 and not v.Secret then
					v.DisplayFlags = v.DisplayFlags | 6
				end
			end
		end

		-- treasure rooms are the only room with a permanent icon that can dynamically change (devil's crown), so we have to constantly update its type
		for _,v in ipairs(MinimapAPI:GetLevel()) do
			if v.Type == RoomType.ROOM_TREASURE then
				v:UpdateType()
			end
		end

		if MinimapAPI:GetConfig("AltSemivisitedSprite") then
			if not mapAltCustomLarge then
				mapAltCustomLarge = true
				MinimapAPI.SpriteMinimapCustomLarge:ReplaceSpritesheet(0, "gfx/ui/minimapapi/custom_minimap2_alt.png")
				MinimapAPI.SpriteMinimapCustomLarge:LoadGraphics()
			end
		else
			if mapAltCustomLarge then
				mapAltCustomLarge = false
				MinimapAPI.SpriteMinimapCustomLarge:ReplaceSpritesheet(0, "gfx/ui/minimapapi/custom_minimap2.png")
				MinimapAPI.SpriteMinimapCustomLarge:LoadGraphics()
			end
		end

		if MinimapAPI:GetLevel() then
			MinimapAPI.SpriteMinimapSmall.Scale = Vector(1, 1)
			if MinimapAPI:IsLarge() then -- big unbound map
				renderUnboundedMinimap("huge")
			elseif MinimapAPI:GetConfig("DisplayMode") == 1 then -- small unbound map
				renderUnboundedMinimap("small")
			elseif MinimapAPI:GetConfig("DisplayMode") == 2 then -- Bounded map
				if MinimapAPI.GlobalScaleX < 1 then
					renderUnboundedMinimap("small")
				else
					renderBoundedMinimap()
				end
			elseif MinimapAPI:GetConfig("DisplayMode") == 4 then -- hidden map
				renderUnboundedMinimap("small",true)
			end

			if MinimapAPI:GetConfig("DisplayLevelFlags") > 0 then
				local levelflagoffset
				local islarge = MinimapAPI:IsLarge()
				local screen_size = MinimapAPI:GetScreenTopRight()
				if not islarge and MinimapAPI:GetConfig("DisplayMode") == 2 and MinimapAPI.GlobalScaleX >= 1 then -- Bounded map
					if MinimapAPI:GetConfig("DisplayLevelFlags") == 1 then                            -- LEFT
						levelflagoffset = Vector(
							screen_size.X - MinimapAPI:GetConfig("MapFrameWidth") - MinimapAPI:GetConfig("PositionX")
							+ roomPixelSize.X,
							screen_size.Y + MinimapAPI:GetConfig("PositionY") + 3)
					else -- BOTTOM
						levelflagoffset = Vector(screen_size.X - MinimapAPI:GetConfig("PositionX") + roomPixelSize.X,
							screen_size.Y + MinimapAPI:GetConfig("MapFrameHeight") + MinimapAPI:GetConfig("PositionY") +
							3)
					end
				elseif not islarge and MinimapAPI:GetConfig("DisplayMode") == 4 then -- hidden map
					levelflagoffset = Vector(screen_size.X - MinimapAPI:GetConfig("PositionX") - roomPixelSize.X,
					screen_size.Y + roomPixelSize.Y)
				else
					local minx = screen_size.X
					local maxY = 0
					local size = (islarge and largeRoomSize or roomSize)
					local questionmarkOffset = Vector(0, 0)
					if not (MinimapAPI:GetConfig("OverrideLost") or game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0) then
						questionmarkOffset = Vector(32, 32)
					else
						for _, room in ipairs(MinimapAPI:GetLevel()) do
							if room.TargetRenderOffset and room:IsVisible() then
								if MinimapAPI.GlobalScaleX >= 0 then
									minx = math.min(minx, room.RenderOffset.X)
								else
									minx = math.min(minx,
										room.RenderOffset.X +
										MinimapAPI.GlobalScaleX * MinimapAPI:GetRoomShapeGridSize(room.Shape).X * size.X)
								end
								maxY = math.max(maxY,
									room.RenderOffset.Y + MinimapAPI:GetConfig("PositionY") +
									MinimapAPI:GetRoomShapeGridSize(room.Shape).X * size.Y)
							end
						end
					end
					if MinimapAPI:GetConfig("DisplayLevelFlags") == 1 then -- LEFT
						levelflagoffset = Vector(minx, MinimapAPI:GetConfig("PositionY")) + Vector(-size.X/2, size.Y/2+2) +
						Vector(-questionmarkOffset.X, 0)
					else                                    -- BOTTOM
						levelflagoffset = Vector(screen_size.X - MinimapAPI:GetConfig("PositionX"), maxY) +
						Vector( - roomPixelSize.X/2, size.Y/2+2) + Vector(0, questionmarkOffset.Y)
					end
				end
				renderMinimapLevelFlags(levelflagoffset)
			end
		end
	end
end

MinimapAPI.DisableSaving = false

function MinimapAPI:LoadSaveTable(saved,is_save)
	if saved then
		for i,v in pairs(saved.Config) do
			MinimapAPI.Config[i] = v
		end

		if is_save and saved.LevelData and saved.Seed == game:GetSeeds():GetStartSeed() then
			MinimapAPI:ClearLevels()
			for dim, level in pairs(saved.LevelData) do
				dim = tonumber(dim)
				MinimapAPI.Levels[dim or 0] = {}
				for _, v in ipairs(level) do
					local desc
					if v.DescriptorListIndex then
						desc, _ = GetRoomDescAndDimFromListIndex(v.DescriptorListIndex)
					end
					MinimapAPI:AddRoom({
						Position = Vector(v.PositionX, v.PositionY),
						DisplayPosition = (v.DisplayPositionX and v.DisplayPositionY) and Vector(v.DisplayPositionX, v.DisplayPositionY),
						ID = v.ID,
						Type = v.Type,
						Shape = v.Shape,
						ItemIcons = v.ItemIcons,
						PermanentIcons = v.PermanentIcons,
						LockedIcons = v.LockedIcons,
						VisitedIcons = v.VisitedIcons,
						Descriptor = desc,
						DisplayFlags = v.DisplayFlags,
						Clear = v.Clear,
						Color = v.Color and Color(v.Color.R, v.Color.G, v.Color.B, v.Color.A, v.Color.RO, v.Color.GO, v.Color.BO),
						AdjacentDisplayFlags = v.AdjacentDisplayFlags,
						Secret = v.Secret,
						Visited = v.Visited,
						Hidden = v.Hidden,
						NoUpdate = v.NoUpdate,
						Dimension = dim,
					})
				end
			end
			if saved.playerMapPosX and saved.playerMapPosY then
				playerMapPos = Vector(saved.playerMapPosX,saved.playerMapPosY)
			end
			MinimapAPI.CheckedRoomCount = saved.CheckedRoomCount or 0
		else
			MinimapAPI:LoadDefaultMap()
		end
	end
end

function MinimapAPI:GetSaveTable(menuexit)
	local saved = {}
	saved.Config = MinimapAPI.Config
	saved.Seed = game:GetSeeds():GetStartSeed()
	if menuexit then
		saved.playerMapPosX = playerMapPos.X
		saved.playerMapPosY = playerMapPos.Y
		saved.CheckedRoomCount = MinimapAPI.CheckedRoomCount
		saved.LevelData = {}
		for idx, level in pairs(MinimapAPI.Levels) do
			saved.LevelData[idx] = {}
			for _, v in ipairs(level) do
				saved.LevelData[idx][#saved.LevelData[idx] + 1] = {
					PositionX = v.Position.X,
					PositionY = v.Position.Y,
					ID = type(v.ID) ~= "userdata" and v.ID,
					Shape = v.Shape,
					ItemIcons = v.ItemIcons,
					Type = v.Type,
					PermanentIcons = v.PermanentIcons,
					LockedIcons = v.LockedIcons,
					VisitedIcons = v.VisitedIcons,
					DescriptorListIndex = v.Descriptor and v.Descriptor.ListIndex,
					DisplayFlags = rawget(v, "DisplayFlags"),
					Clear = rawget(v, "Clear"),
					Color = v.Color and
						{ R = v.Color.R, G = v.Color.G, B = v.Color.B, A = v.Color.A, RO = v.Color.RO, GO = v.Color.GO, BO = v.Color.BO },
					AdjacentDisplayFlags = v.AdjacentDisplayFlags,
					Secret = v.Secret,
					Visited = v.Visited,
					Hidden = v.Hidden,
					NoUpdate = v.NoUpdate,
					DisplayPositionX = v.DisplayPosition and v.DisplayPosition.X,
					DisplayPositionY = v.DisplayPosition and v.DisplayPosition.Y,
				}
			end
		end
	end
	return saved
end

-- LOADING SAVED GAME
local isFirstGame = true
local addRenderCall = true
function MinimapAPI:OnGameLoad(_, is_save)
	badload = MinimapAPI:IsBadLoad()
	if addRenderCall then
		if REPENTOGON then
			MinimapAPI:AddCallbackFunc(ModCallbacks.MC_POST_HUD_RENDER, CALLBACK_PRIORITY, renderCallbackFunction)
		elseif StageAPI and StageAPI.Loaded then
			StageAPI.AddCallback("MinimapAPI", "POST_HUD_RENDER", constants.STAGEAPI_CALLBACK_PRIORITY, renderCallbackFunction)
			MinimapAPI.UsingStageAPIPostHUDRender = true -- only for stage api
		else
			MinimapAPI:AddCallbackFunc(ModCallbacks.MC_POST_RENDER, CALLBACK_PRIORITY, renderCallbackFunction)
		end
		addRenderCall = false
	end
	if MinimapAPI:HasData() then
		if not MinimapAPI.DisableSaving then
			local saved = json.decode(Isaac.LoadModData(MinimapAPI))
			MinimapAPI:LoadSaveTable(saved, is_save)
		else
			MinimapAPI:LoadDefaultMap()
		end
		MinimapAPI:UpdateExternalMap()
	else
		MinimapAPI:LoadDefaultMap()
	end
	if isFirstGame then
		MinimapAPI:FirstMapDisplayMode()
		isFirstGame = false
	end
end

MinimapAPI:AddCallbackFunc(ModCallbacks.MC_POST_GAME_STARTED, CALLBACK_PRIORITY, MinimapAPI.OnGameLoad)

-- SAVING GAME
MinimapAPI:AddCallbackFunc(
	ModCallbacks.MC_PRE_GAME_EXIT,
	CALLBACK_PRIORITY,
	function(_, menuexit)
		if not MinimapAPI.DisableSaving then
			MinimapAPI:SaveData(json.encode(MinimapAPI:GetSaveTable(menuexit)))
		end
	end
)
