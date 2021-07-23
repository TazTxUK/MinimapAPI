local MinimapAPI = require("scripts.minimapapi")
local SHExists, ScreenHelper = pcall(require, "scripts.screenhelper")
local cache = require("scripts.minimapapi.cache")

local json = require("json")

local function getType(obj)
	local mt = getmetatable(obj)
	if mt and mt.__type then
		return mt.__type
	end
	return type(obj)
end

local errorBadArgument = "Bad argument %s to '%s': expected %s, got %s"

--Returns screen size as Vector
function MinimapAPI:GetScreenSize()
	return (Isaac.WorldToScreen(Vector(320, 280)) - Game():GetRoom():GetRenderScrollOffset() - Game().ScreenShakeOffset) * 2
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

function MinimapAPI:IsAmbushBoss()
	return cache.Stage ~= cache.AbsoluteStage
end

function MinimapAPI:GetRoomShapeIconPositions(rs, iconcount)
	iconcount = iconcount or math.huge
	local r
	if iconcount <= 1 then
		r = MinimapAPI.RoomShapeIconPositions[1][rs]
	else
		r = MinimapAPI.RoomShapeIconPositions[2][rs]
	end
	return r
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
local rooms
local startingRoom
local playerMapPos = Vector(0, 0)
MinimapAPI.Levels = {}
MinimapAPI.CurrentDimension = 0
MinimapAPI.OverrideVoid = false
MinimapAPI.changedRoomsWithShowMap ={}

local mapheldframes = 0

local callbacks_playerpos = {}
local callbacks_displayflags = {}

local disabled_itemdet = false
local override_greed = true

--draw
local roomCenterOffset = Vector(0, 0)
local roomAnimPivot = Vector(-2, -2)
local frameTL = Vector(2, 2)
local screen_size

local roomSize = Vector(8, 7)
local roomPixelSize = Vector(9, 8)
local iconPixelSize = Vector(16, 16)
local outlinePixelSize = Vector(16, 16)

local largeRoomAnimPivot = Vector(-4, -4)
local largeRoomSize = Vector(17, 15)
local largeRoomPixelSize = Vector(18, 16)
local unboundedMapOffset = Vector(0, 0)
local largeIconOffset = Vector(-2, -2)

local dframeHorizBarSize = Vector(53, 2)
local dframeVertBarSize = Vector(2, 47)
local dframeCenterSize = Vector(49, 43)

local mapAltCustomLarge = false

local zvec = Vector(0, 0)

MinimapAPI.SpriteMinimapSmall = Sprite()
MinimapAPI.SpriteMinimapSmall:Load("gfx/ui/minimapapi_minimap1.anm2", true)
MinimapAPI.SpriteMinimapLarge = Sprite()
MinimapAPI.SpriteMinimapLarge:Load("gfx/ui/minimapapi_minimap2.anm2", true)

MinimapAPI.SpriteIcons = Sprite()
MinimapAPI.SpriteIcons:Load("gfx/ui/minimapapi_icons.anm2", true)

MinimapAPI.SpriteMinimapCustomSmall = Sprite()
MinimapAPI.SpriteMinimapCustomSmall:Load("gfx/ui/minimapapi/custom_minimap1.anm2", true)
MinimapAPI.SpriteMinimapCustomLarge = Sprite()
MinimapAPI.SpriteMinimapCustomLarge:Load("gfx/ui/minimapapi/custom_minimap2.anm2", true)

MinimapAPI.OverrideConfig = {}
function MinimapAPI:GetConfig(option)
	return MinimapAPI.OverrideConfig[option] ~= nil and MinimapAPI.OverrideConfig[option] or MinimapAPI.Config[option]
end

function MinimapAPI:GetLevel(key)
	return MinimapAPI.Levels[key or MinimapAPI.CurrentDimension]
end

function MinimapAPI:SetLevel(level, key)
	MinimapAPI.Levels[key or MinimapAPI.CurrentDimension] = level
end

function MinimapAPI:ShallowCopy(t)
	local t2 = {}
	for i, v in pairs(t) do
		t2[i] = v
	end
	return t2
end

function MinimapAPI:DeepCopy(t)
	local t2 = {}
	for i, v in pairs(t) do
		if type(v) == "table" then
			t2[i] = MinimapAPI:DeepCopy(v)
		else
			t2[i] = v
		end
	end
	return t2
end

function MinimapAPI:GetIconAnimData(id)
	for i, v in ipairs(MinimapAPI.IconList) do
		if v.ID == id then
			return v
		end
	end
end

function MinimapAPI:GetDoorSlotValue(doorgroup, doordir)
	return doorgroup*4 + doordir
end

local defaultCustomPickupPriority = 12999 --more than vanilla, less than other potential custom pickups
function MinimapAPI:AddPickup(id, iconid, typ, variant, subtype, call, icongroup, priority)
	local newRoom
	if type(id) == "table" and iconid == nil then
		local t = id
		id = t.ID
		if type(t.Icon) == "table" then
			t.Icon = MinimapAPI:AddIcon(t.Icon.ID or t.ID, t.Icon.sprite, t.Icon.anim, t.Icon.frame, t.Icon.color).ID
		end
		newRoom = {
			IconID = t.Icon,
			Type = t.Type,
			Variant = t.Variant or -1,
			SubType = t.SubType or -1,
			Call = t.Call,
			IconGroup = t.IconGroup,
			Priority = t.Priority or defaultCustomPickupPriority
		}
	else
		if type(iconid) == "table" then
			iconid = MinimapAPI:AddIcon(iconid.ID or id, iconid.sprite, iconid.anim, iconid.frame, iconid.color).ID
		end
		newRoom = {
			IconID = iconid,
			Type = typ,
			Variant = variant or -1,
			SubType = subtype or -1,
			Call = call,
			IconGroup = icongroup,
			Priority = priority or defaultCustomPickupPriority
		}
	end
	MinimapAPI.PickupList[id] = newRoom
	table.sort(MinimapAPI.PickupList, function(a, b) return a.Priority > b.Priority	end	)
	return newRoom
end

function MinimapAPI:RemovePickup(id)
	MinimapAPI.PickupList[id] = nil
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

function MinimapAPI:AddMapFlag(id, condition, sprite, anim, frame)
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
				for i,v in pairs(adjacentcoords) do
					if v.Y == gridpivot.Y + doorgroup then
						if not result or (v.X < result.X) then
							result = v
						end
					end
				end
			elseif doordir == 1 then
				for i,v in pairs(adjacentcoords) do
					if v.X == gridpivot.X + doorgroup then
						if not result or (v.Y < result.Y) then
							result = v
						end
					end
				end
			elseif doordir == 2 then
				for i,v in pairs(adjacentcoords) do
					if v.Y == gridpivot.Y + doorgroup then
						if not result or (v.X > result.X) then
							result = v
						end
					end
				end
			elseif doordir == 3 then
				for i,v in pairs(adjacentcoords) do
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
	return mapheldframes > 7 or MinimapAPI:GetConfig("DisplayMode") == 3
end

function MinimapAPI:PlayerInRoom(roomdata)
	return playerMapPos.X == roomdata.Position.X and playerMapPos.Y == roomdata.Position.Y
end

-- MinimapAPI.GridEntityPickupIDs

function MinimapAPI:GetCurrentRoomPickupIDs() --gets pickup icon ids for current room ONLY
	local ents = Isaac.GetRoomEntities()
	local pickupgroupset = {}
	local addIcons = {}
	for _, ent in ipairs(ents) do
		local success = false
		if ent:GetData().MinimapAPIPickupID == nil then
			for i, v in pairs(MinimapAPI.PickupList) do
				local currentid = MinimapAPI.PickupList[ent:GetData().MinimapAPIPickupID]
				if not currentid or (currentid.Priority < v.Priority) then
					if ent.Type == v.Type then
						local toPickup = ent:ToPickup()
						if (not toPickup) or (not toPickup:IsShopItem()) then
							if v.Variant == -1 or ent.Variant == v.Variant then
								if v.SubType == -1 or ent.SubType == v.SubType then
									ent:GetData().MinimapAPIPickupID = i
									success = true
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
		
		local id = ent:GetData().MinimapAPIPickupID
		local pickupicon = MinimapAPI.PickupList[id]
		if pickupicon then
			local ind = MinimapAPI:GetConfig("PickupNoGrouping") and (#pickupgroupset + 1) or pickupicon.IconGroup
			-- GVM.Print("ind: "..ind)
			if not pickupgroupset[ind] or MinimapAPI.PickupList[pickupgroupset[ind]].Priority < pickupicon.Priority then
				if ind == "bombs" then
					-- GVM.Print("calling on "..pickupicon.IconID)
					-- GVM.Print("overriding "..(MinimapAPI.PickupList[pickupgroupset[ind]] and MinimapAPI.PickupList[pickupgroupset[ind]].IconID or "none"))
				end
				if (not pickupicon.Call) or pickupicon.Call(ent) then
					if pickupicon.IconGroup then
						pickupgroupset[ind] = id
					end
				end
			end
		end
	end
	for i,v in pairs(pickupgroupset) do
		addIcons[#addIcons + 1] = v
	end
	if not MinimapAPI:GetConfig("PickupFirstComeFirstServe") then
		table.sort(addIcons, function(a,b) return MinimapAPI.PickupList[a].Priority > MinimapAPI.PickupList[b].Priority end)
	end
	local r = {}
	for i,v in ipairs(addIcons) do
		r[i] = MinimapAPI.PickupList[v].IconID
	end
	return r
end

function MinimapAPI:RunPlayerPosCallbacks()
	for i, v in ipairs(callbacks_playerpos) do
		local s, ret = pcall(v.call, v.mod, MinimapAPI:GetCurrentRoom(), playerMapPos)
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
	for i, v in ipairs(callbacks_displayflags) do
		local s, ret = pcall(v.call, v.mod, room, df)
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

function MinimapAPI:LoadDefaultMap(dimension)
	rooms = Game():GetLevel():GetRooms()
	dimension = dimension or MinimapAPI.CurrentDimension
	MinimapAPI.Levels[dimension] = {}
	local level = MinimapAPI.Levels[dimension]
	local treasure_room_count = 0
	local added_descriptors = {}
	for i = 0, #rooms - 1 do
		local v = rooms:Get(i)
		local hash = GetPtrHash(v)
		if not added_descriptors[v] and GetPtrHash(cache.Level:GetRoomByIdx(v.GridIndex)) == hash then
			added_descriptors[v] = true
			local t = {
				Shape = v.Data.Shape,
				PermanentIcons = {MinimapAPI:GetRoomTypeIconID(v.Data.Type)},
				LockedIcons = {MinimapAPI:GetUnknownRoomTypeIconID(v.Data.Type)},
				ItemIcons = {},
				Position = MinimapAPI:GridIndexToVector(v.GridIndex),
				Descriptor = v,
				AdjacentDisplayFlags = MinimapAPI.RoomTypeDisplayFlagsAdjacent[v.Data.Type] or 5,
				Type = v.Data.Type,
				Level = dimension,
			}
			if v.Data.Shape == RoomShape.ROOMSHAPE_LTL then
				t.Position = t.Position + Vector(1,0)
			end
			if v.Data.Type == RoomType.ROOM_SECRET or v.Data.Type == RoomType.ROOM_SUPERSECRET then
				t.Hidden = true
			end
			if v.Data.Type == 11 then
				if MinimapAPI:IsAmbushBoss() then
					t.PermanentIcons[1] = "BossAmbushRoom"
				end
			end
			if override_greed and Game():IsGreedMode() then
				if v.Data.Type == RoomType.ROOM_TREASURE then
					treasure_room_count = treasure_room_count + 1
					if treasure_room_count == 1 then
						t.PermanentIcons = {"TreasureRoomGreed"}
						t.LockedIcons = {"TreasureRoomGreed"}
					end
				end
			end
			if cache.Stage == LevelStage.STAGE1_2 and string.find(v.Data.Name, "Mirror Room") then
				t.PermanentIcons = {"MirrorRoom"}
				t.LockedIcons = {"MirrorRoom"}
			elseif cache.Stage == LevelStage.STAGE2_2 and string.find(v.Data.Name, "Secret Entrance") then
				t.PermanentIcons = {"MinecartRoom"}
				t.LockedIcons = {"MinecartRoom"}
			end
			MinimapAPI:AddRoom(t)
		end
	end
	if not (MinimapAPI:GetConfig("OverrideVoid") or MinimapAPI.OverrideVoid) then
		if not Game():IsGreedMode() then
			if cache.Stage == LevelStage.STAGE7 then
				for i,v in ipairs(MinimapAPI:GetLevel()) do
					if v.Shape == RoomShape.ROOMSHAPE_2x2 and v.Descriptor.Data.Type == RoomType.ROOM_BOSS then
						if not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP0)) or not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT0)) then
							--
						elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP1)) or not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT0)) then
							v.DisplayPosition = v.Position + Vector(1,0)
						elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT1)) or not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN1)) then
							v.DisplayPosition = v.Position + Vector(1,1)
						elseif not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT1)) or not MinimapAPI:IsPositionFree(MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN0)) then
							v.DisplayPosition = v.Position + Vector(0,1)
						end
						v.Shape = RoomShape.ROOMSHAPE_1x1
					end
				end
			end
		end
	end
end

function MinimapAPI:EffectCrystalBall()
	for i,v in ipairs(MinimapAPI:GetLevel()) do
		if v.Type ~= RoomType.ROOM_SUPERSECRET then
			v:Reveal()
		end
	end
end

function MinimapAPI:ClearMap(dimension)
	MinimapAPI.Levels[dimension or MinimapAPI.CurrentDimension] = {}
end

function MinimapAPI:ClearLevels()
	MinimapAPI.Levels = {}
end

local maproomfunctions = {
	IsVisible = function(room)
		return room:GetDisplayFlags() & 1 > 0
	end,
	IsShadow = function(room)
		return (room:GetDisplayFlags() or 0) & 2 > 0
	end,
	IsIconVisible = function(room)
		return (room:GetDisplayFlags() or 0) & 4 > 0
	end,
	IsVisited = function(room)
		return room.Visited or false
	end,
	GetPosition = function(room, pos)
		return room.Position
	end,
	SetPosition = function(room, pos)
		room.Position = pos
		room:UpdateAdjacentRoomsCache()
	end,
	GetDisplayFlags = function(room)
		local roomDesc = room.Descriptor
		local df = room.DisplayFlags or 0
		if roomDesc then
			df = df | roomDesc.DisplayFlags
		end
		if room.Type and room.Type > 1 and not room.Hidden and Isaac.GetPlayer(0):GetEffects():HasCollectibleEffect(21) then
			df = df | 6
		end
		return MinimapAPI:RunDisplayFlagsCallbacks(room,df)
	end,
	IsClear = function(room)
		return room.Clear or false
	end,
	SetDisplayFlags = function(room,df)
		if room.Descriptor then
			room.Descriptor.DisplayFlags = df
			room.DisplayFlags = df
		else
			room.DisplayFlags = df
		end
	end,
	Remove = function(room)
		local level = MinimapAPI:GetLevel()
		for i,v in ipairs(level) do
			if v == room then
				table.remove(level, i)
				return room
			end
		end
	end,
	UpdateAdjacentRoomsCache = function(room)
		if room.AdjacentRooms then
			for i,v in ipairs(room:GetAdjacentRooms()) do
				v:RemoveAdjacentRoom(room)
			end
		end
		room.AdjacentRooms = {}
		for i,v in ipairs(MinimapAPI.RoomShapeAdjacentCoords[room.Shape]) do
			local roomatpos = MinimapAPI:GetRoomAtPosition(room.Position + v)
			if roomatpos then
				room.AdjacentRooms[#room.AdjacentRooms + 1] = roomatpos
				roomatpos:AddAdjacentRoom(room)
			end
		end
	end,
	AddAdjacentRoom = function(room, adjroom)
		local adjrooms = room:GetAdjacentRooms()
		for i,v in ipairs(adjrooms) do
			if v == adjroom then return end
		end
		adjrooms[#adjrooms + 1] = adjroom
	end,
	RemoveAdjacentRoom = function(room, adjroom)
		local adjrooms = room:GetAdjacentRooms()
		for i,v in ipairs(adjrooms) do
			if v == adjroom then return table.remove(adjrooms,i) end
		end
	end,
	GetAdjacentRooms = function(room)
		if not room.AdjacentRooms then
			room:UpdateAdjacentRoomsCache()
		end
		return room.AdjacentRooms
	end,
	Reveal = function(room)
		if room.Hidden then
			room.DisplayFlags = room.DisplayFlags | 6
		else
			room.DisplayFlags = room.DisplayFlags | 5
		end
	end,
	UpdateType = function(room)
		if room.Descriptor and room.Descriptor.Data then
			room.Type = room.Descriptor.Data.Type
			room.PermanentIcons = {MinimapAPI:GetRoomTypeIconID(room.Type)}
		end
	end,
}

local maproommeta = {
	__index = maproomfunctions,
	__type = "MinimapAPI.Room"
}

function MinimapAPI:AddRoom(t)
	local defaultPosition = Vector(0,-1)
	local x = {
		Position = t.Position or defaultPosition,
		DisplayPosition = t.DisplayPosition,
		Type = t.Type,
		ID = t.ID,
		Shape = t.Shape or RoomShape.ROOMSHAPE_1x1,
		PermanentIcons = t.PermanentIcons or {},
		LockedIcons = t.LockedIcons or {},
		ItemIcons = t.ItemIcons or {},
		Descriptor = t.Descriptor or nil,
		Color = t.Color or nil,
		RenderOffset = nil,
		DisplayFlags = t.DisplayFlags or 0,
		Clear = t.Clear or false,
		Visited = t.Visited or false,
		AdjacentDisplayFlags = t.AdjacentDisplayFlags or 5,
		Hidden = t.Hidden or nil,
		NoUpdate = t.NoUpdate or nil,
		Dimension = t.Dimension or MinimapAPI.CurrentDimension,
	}
	setmetatable(x, maproommeta)
	local level = MinimapAPI:GetLevel(x.Dimension)
	level[#level + 1] = x
	x:SetPosition(x.Position)
	return x
end

local function removeAdjacentRoomRefs(room)
	if not room.AdjacentRooms then return end
	for i,v in ipairs(room.AdjacentRooms) do
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

function MinimapAPI:GetRoom(pos)
	assert(MinimapAPI:InstanceOf(pos, Vector), "bad argument #1 to 'GetRoom', expected Vector")
	local success
	for i, v in ipairs(MinimapAPI:GetLevel()) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			success = v
			break
		end
	end
	return success
end

function MinimapAPI:GetRoomAtPosition(position)
	assert(MinimapAPI:InstanceOf(position, Vector), "bad argument #1 to 'GetRoomAtPosition', expected Vector")
	for i, v in ipairs(MinimapAPI:GetLevel()) do
		for _,pos in ipairs(MinimapAPI.RoomShapePositions[v.Shape]) do
			local p = v.Position + pos
			if p.X == position.X and p.Y == position.Y then
				return v
			end
		end
	end
end

function MinimapAPI:GetRoomByID(ID)
	for i, v in ipairs(MinimapAPI:GetLevel()) do
		if v.ID == ID then
			return v
		end
	end
end

function MinimapAPI:GetRoomByIdx(Idx)
	for i, v in ipairs(MinimapAPI:GetLevel()) do
		if v.Descriptor and v.Descriptor.GridIndex == Idx then
			return v
		end
	end
end

local function isRoomAdj(room1,room2)
	for i,v in ipairs(MinimapAPI.RoomShapeAdjacentCoords[room1.Shape]) do
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

function MinimapAPI:IsPositionFree(position,roomshape)
	roomshape = roomshape or 1
	for _,room in ipairs(MinimapAPI:GetLevel()) do
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
	if currentroom and currentroom then
		roomCenterOffset = playerMapPos - MinimapAPI.RoomShapeGridPivots[currentroom.Shape] + MinimapAPI:GetRoomShapeGridSize(currentroom.Shape) / 2
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

function MinimapAPI:AddPlayerPositionCallback(modtable, func)
	if not MinimapAPI:IsModTable(modtable) then
		error("Table given to AddPlayerPositionCallback was not a mod table")
	end
	callbacks_playerpos[#callbacks_playerpos + 1] = {
		mod = modtable,
		call = func
	}
end

function MinimapAPI:AddDisplayFlagsCallback(modtable, func)
	if not MinimapAPI:IsModTable(modtable) then
		error("Table given to AddDisplayFlagsCallback was not a mod table")
	end
	callbacks_displayflags[#callbacks_displayflags + 1] = {
		mod = modtable,
		call = func
	}
end

function MinimapAPI:RemovePlayerPositionCallback(modtable)
	for i, v in ipairs(callbacks_playerpos) do
		if v.mod == modtable then
			table.remove(callbacks_playerpos, i)
			break
		end
	end
end

function MinimapAPI:GetCurrentRoom() --DOESNT ALWAYS RETURN SOMETHING!!!
	return MinimapAPI:GetRoom(MinimapAPI:GetPlayerPosition())
end

local function updatePlayerPos()
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

MinimapAPI:AddCallback(	ModCallbacks.MC_POST_NEW_LEVEL,	function(self)
	MinimapAPI:ClearLevels()
	MinimapAPI:LoadDefaultMap()
	updatePlayerPos()
	MinimapAPI:UpdateExternalMap()
	startingRoom = MinimapAPI:GetCurrentRoom()
end)

function MinimapAPI:UpdateUnboundedMapOffset()
	local maxx
	local miny
	local level = MinimapAPI:GetLevel()
	for i = 1, #(level) do
		local v = level[i]
		if v:GetDisplayFlags() > 0 then
			local maxxval = v.Position.X - MinimapAPI.RoomShapeGridPivots[v.Shape].X + MinimapAPI:GetRoomShapeGridSize(v.Shape).X
			if not maxx or (maxxval > maxx) then
				maxx = maxxval
			end
			local minyval = v.Position.Y
			if not miny or (minyval < miny) then
				miny = minyval
			end
		end
	end
	if maxx and miny then
		unboundedMapOffset = Vector(-maxx, -miny)
	end
end

MinimapAPI:AddCallback(	ModCallbacks.MC_USE_ITEM, function(self, colltype, rng)
	if colltype == CollectibleType.COLLECTIBLE_CRYSTAL_BALL then
		MinimapAPI:EffectCrystalBall()
		MinimapAPI:UpdateExternalMap()
	elseif colltype == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then
		if MinimapAPI.lastCardUsedRoom == MinimapAPI:GetCurrentRoom() then
			for i,v in ipairs(MinimapAPI.changedRoomsWithShowMap) do
				MinimapAPI:GetLevel()[v[1]].DisplayFlags = v[2]
			end
			MinimapAPI:UpdateExternalMap()
		end
	end
end)

function MinimapAPI:UpdateExternalMap()
	if MinimapAPI:GetConfig("ExternalMap") then
		local output = {}
		local extlevel = {}
		output.Level = extlevel
		for i,v in ipairs(MinimapAPI:GetLevel()) do
			if v.DisplayFlags > 0 then
				local x = {
					Position = {X = v.Position.X, Y = v.Position.Y},
					Shape = v.Shape,
					PermanentIcons = #v.PermanentIcons > 0 and v.PermanentIcons or nil,
					ItemIcons = #v.ItemIcons > 0 and v.ItemIcons or nil,
					LockedIcons = #v.LockedIcons > 0 and v.LockedIcons or nil,
					DisplayFlags = v.DisplayFlags,
					Clear = v.Clear,
					Visited = v.Visited,
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

MinimapAPI:AddCallback(	ModCallbacks.MC_POST_NEW_ROOM, function(self)
	--TODO: add a callback function or something so custom dimensions can be made
	MinimapAPI.CurrentDimension = cache.Dimension
	
	if not MinimapAPI:GetLevel() then
		MinimapAPI:LoadDefaultMap()
	end
	
	updatePlayerPos()
	MinimapAPI.lastCardUsedRoom = nil
	-- for i,v in ipairs(MinimapAPI.Level) do
		-- if not v.NoUpdate then
			-- v:UpdateType()
		-- end
	-- end
	MinimapAPI:UpdateExternalMap()
end)

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

MinimapAPI:AddCallback( ModCallbacks.MC_USE_CARD, function(self, card)
	if card == Card.CARD_WORLD or card == Card.CARD_SUN or card == Card.RUNE_ANSUZ then
		MinimapAPI:ShowMap()
		MinimapAPI.lastCardUsedRoom = MinimapAPI:GetCurrentRoom()
	end
end)

function MinimapAPI:PrevMapDisplayMode()
	local modes = {
		[1] = MinimapAPI:GetConfig("AllowToggleSmallMap"),
		[2] = MinimapAPI:GetConfig("AllowToggleBoundedMap"),
		[3] = MinimapAPI:GetConfig("AllowToggleLargeMap"),
		[4] = MinimapAPI:GetConfig("AllowToggleNoMap"),
	}
	for i=1,4 do
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
	for i=1,4 do
		MinimapAPI.Config.DisplayMode = MinimapAPI.Config.DisplayMode + 1
		if MinimapAPI.Config.DisplayMode > 4 then
			MinimapAPI.Config.DisplayMode = 1
		end
		if modes[MinimapAPI.Config.DisplayMode] then
			break
		end
	end
end

MinimapAPI:AddCallback( ModCallbacks.MC_POST_UPDATE, function(self)
	local player = Isaac.GetPlayer(0)
	if Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex) then
		mapheldframes = mapheldframes + 1
	elseif mapheldframes > 0 then
		if mapheldframes < 8 then
			MinimapAPI:NextMapDisplayMode()
		end
		mapheldframes = 0
	end
end)

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
	local flags = {}
	-- local offset = Vector(math.floor((#flags-1)/4)*-16,0)
	local offset=Vector(0,0)


	for _, mapFlag in ipairs(MinimapAPI.MapFlags) do
	    if (mapFlag.condition()) then
	    	local frame

	    	-- Frame can be a function for indicators that might change, like zodiac indicator
	    	if type(mapFlag.frame) == "function" then
	    		frame = mapFlag.frame()
	    	else
	    		frame = mapFlag.frame
	    	end

	    	mapFlag.sprite:SetFrame(mapFlag.anim, frame)
	    	mapFlag.sprite:Render(renderOffset+offset, zvec, zvec)
	    	offset=offset+Vector(0,16)
	    	-- if offset.Y >= 48 then
	    		-- offset = offset + Vector(16,-48)
	    	-- end
	    end
	end
end

local furthestRoom = nil
local function renderUnboundedMinimap(size,hide)
	if MinimapAPI:GetConfig("OverrideLost") or Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0 then
		MinimapAPI:UpdateUnboundedMapOffset()
		local offsetVec
		
		if MinimapAPI:GetConfig("SyncPositionWithMCM") and SHExists then
			local screen_size = ScreenHelper.GetScreenTopRight()
			offsetVec = Vector(screen_size.X - MinimapAPI:GetConfig("PositionX"), screen_size.Y + MinimapAPI:GetConfig("PositionY"))
		else
			offsetVec = Vector(screen_size.X - MinimapAPI:GetConfig("PositionX"), MinimapAPI:GetConfig("PositionY"))
		end
		
		local renderRoomSize = size == "small" and roomSize or largeRoomSize
		local renderAnimPivot = size == "small" and roomAnimPivot or largeRoomAnimPivot
		local sprite = size == "small" and MinimapAPI.SpriteMinimapSmall or MinimapAPI.SpriteMinimapLarge
		
		
		
		for i, v in ipairs(MinimapAPI:GetLevel()) do
			local roomOffset = (v.DisplayPosition or v.Position) + unboundedMapOffset
			roomOffset.X = roomOffset.X * renderRoomSize.X
			roomOffset.Y = roomOffset.Y * renderRoomSize.Y
			v.TargetRenderOffset = offsetVec + roomOffset + renderAnimPivot
			if hide then
				v.TargetRenderOffset = v.TargetRenderOffset + Vector(0,-800)
			end
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI:GetConfig("SmoothSlidingSpeed") + v.RenderOffset * (1 - MinimapAPI:GetConfig("SmoothSlidingSpeed"))
			else
				v.RenderOffset = v.TargetRenderOffset
			end
			if v.RenderOffset:DistanceSquared(v.TargetRenderOffset) <= 1 then
				v.RenderOffset = v.TargetRenderOffset
			end
		end
		
		if hide then return end
		
		local defaultOutlineColor = Color(1, 1, 1, 1, math.floor(MinimapAPI:GetConfig("DefaultOutlineColorR")*255), math.floor(MinimapAPI:GetConfig("DefaultOutlineColorG")*255), math.floor(MinimapAPI:GetConfig("DefaultOutlineColorB")*255))
		if MinimapAPI:GetConfig("ShowShadows") then
			for i, v in pairs(MinimapAPI:GetLevel()) do
				local displayflags = v:GetDisplayFlags()
				if displayflags > 0 then
					for n, pos in ipairs(MinimapAPI:GetRoomShapePositions(v.Shape)) do
						pos = Vector(pos.X * renderRoomSize.X, pos.Y * renderRoomSize.Y)
						--local actualRoomPixelSize = renderOutlinePixelSize   -- unused
						sprite.Color = defaultOutlineColor
						sprite:SetFrame("RoomOutline", 1)
						sprite:Render(v.RenderOffset + pos, zvec, zvec)
					end
				end
			end
		end
		
		local defaultRoomColor = Color(MinimapAPI:GetConfig("DefaultRoomColorR"), MinimapAPI:GetConfig("DefaultRoomColorG"), MinimapAPI:GetConfig("DefaultRoomColorB"), 1, 0, 0, 0)
		for i, v in pairs(MinimapAPI:GetLevel()) do
			local iscurrent = MinimapAPI:PlayerInRoom(v)
			local displayflags = v:GetDisplayFlags()
			if displayflags & 0x1 > 0 then
				local frame = MinimapAPI:GetRoomShapeFrame(v.Shape)
				local anim
				local spr = sprite
				if iscurrent then
					anim = "RoomCurrent"
				elseif v:IsClear() then
					anim = "RoomVisited"
				elseif MinimapAPI:GetConfig("DisplayExploredRooms") and v:IsVisited() then
					spr = size == "small" and MinimapAPI.SpriteMinimapCustomSmall or MinimapAPI.SpriteMinimapCustomLarge
					anim = "RoomSemivisited"
				else
					anim = "RoomUnvisited"
				end
				if MinimapAPI:GetConfig("VanillaSecretRoomDisplay") and (v.PermanentIcons[1] == "SecretRoom" or v.PermanentIcons[1] == "SuperSecretRoom") and anim == "RoomUnvisited" then
					-- skip room rendering for secret rooms so only shadow is visible
					if not MinimapAPI:GetConfig("ShowShadows") then
						spr.Color = Color(0, 0, 0, 1, 0, 0, 0)
						spr:SetFrame(anim, frame)
						spr:Render(v.RenderOffset, zvec, zvec)
						spr.Color = v.Color or defaultRoomColor
					end
				elseif type(frame) == "table" then
					local fr0 = frame[size == "small" and "small" or "large"]
					local fr1 = fr0[anim] or fr0["RoomUnvisited"]
					local spr = fr1.sprite or sprite
					updateMinimapIcon(spr, fr1)
					spr.Color = v.Color or defaultRoomColor
					spr:Render(v.RenderOffset, zvec, zvec)
				else
					spr:SetFrame(anim, frame)
					spr.Color = v.Color or defaultRoomColor
					spr:Render(v.RenderOffset, zvec, zvec)
				end
			end
		end
		
		if size == "huge" and MinimapAPI:GetConfig("ShowGridDistances") then
			for _, room in pairs(MinimapAPI:GetLevel()) do
				if room.PlayerDistance then
					local s = tostring(room.PlayerDistance)
					font:DrawString(s, room.RenderOffset.X + 7, room.RenderOffset.Y + 3, KColor(0.2, 0.2, 0.2, 1), 0, false)
				end
			end
		end
		
		if size == "huge" and MinimapAPI:GetConfig("HighlightFurthestRoom") then
			local currentRoom = MinimapAPI:GetCurrentRoom()
			if currentRoom == startingRoom then
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
			end
			if furthestRoom ~= nil then
				if furthestRoom:GetDisplayFlags() ~= 5 then
					furthestRoom.Color = Color(1, 0, 0, 1, 0, 0, 0)
				else
					furthestRoom.Color = Color(1, 1, 1, 1, 0, 0, 0)
				end
			end
		end

		if MinimapAPI:GetConfig("ShowIcons") then
			local sprite = MinimapAPI.SpriteIcons
			
			for i, v in pairs(MinimapAPI:GetLevel()) do
				local incurrent = MinimapAPI:PlayerInRoom(v) and not MinimapAPI:GetConfig("ShowCurrentRoomItems")
				local displayflags = v:GetDisplayFlags()
				local k = 1
				local function renderIcons(icons, locs)
					for _,icon in ipairs(icons) do
						local icontb = MinimapAPI:GetIconAnimData(icon)
						if icontb then
							local loc = locs[k]
							if not loc then return end
							local iconlocOffset = Vector(loc.X * renderRoomSize.X, loc.Y * renderRoomSize.Y)
							local spr = icontb.sprite or sprite
							updateMinimapIcon(spr, icontb)
							if size == "small" then
								spr:Render(iconlocOffset + v.RenderOffset, zvec, zvec)
							else
								spr:Render(iconlocOffset + v.RenderOffset - largeRoomAnimPivot + largeIconOffset, zvec, zvec)
							end
							k = k + 1
						end
					end
				end

				if displayflags & 0x4 > 0 then
					local iconcount = #v.PermanentIcons
					if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
						iconcount = iconcount + #v.ItemIcons
					end

					local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, iconcount)
					if size ~= "small" then
						locs = MinimapAPI:GetLargeRoomShapeIconPositions(v.Shape, iconcount)
					end
					renderIcons(v.PermanentIcons, locs)
					if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
						renderIcons(v.ItemIcons, locs)
					end
				elseif displayflags & 0x2 > 0 then
					if v.LockedIcons and #v.LockedIcons > 0 then
						local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, #v.LockedIcons)
						if size ~= "small" then
							locs = MinimapAPI:GetLargeRoomShapeIconPositions(v.Shape, #v.LockedIcons)
						end
						renderIcons(v.LockedIcons, locs)
					end
				end
			end
		end
	end
end

local function renderBoundedMinimap()
	local offsetVec
	if MinimapAPI:GetConfig("SyncPositionWithMCM") and SHExists then
		local screen_size = ScreenHelper.GetScreenTopRight()
		offsetVec = Vector( screen_size.X - MinimapAPI:GetConfig("MapFrameWidth") - MinimapAPI:GetConfig("PositionX") - 1, screen_size.Y + MinimapAPI:GetConfig("PositionY") - 2)
	else
		offsetVec = Vector( screen_size.X - MinimapAPI:GetConfig("MapFrameWidth") - MinimapAPI:GetConfig("PositionX") - 1, MinimapAPI:GetConfig("PositionY") - 2)
	end
	do
		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,MinimapAPI:GetConfig("BorderColorA"),math.floor(MinimapAPI:GetConfig("BorderColorR")*255),math.floor(MinimapAPI:GetConfig("BorderColorG")*255),math.floor(MinimapAPI:GetConfig("BorderColorB")*255))
		MinimapAPI.SpriteMinimapSmall.Scale = Vector((MinimapAPI:GetConfig("MapFrameWidth") + frameTL.X) / dframeHorizBarSize.X, 1)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameN", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec, zvec, zvec)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameS", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + Vector(0, MinimapAPI:GetConfig("MapFrameHeight")), zvec, zvec)

		MinimapAPI.SpriteMinimapSmall.Scale = Vector(1, MinimapAPI:GetConfig("MapFrameHeight") / dframeVertBarSize.Y)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameW", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec, zvec, zvec)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameE", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + Vector(MinimapAPI:GetConfig("MapFrameWidth"), 0), zvec, zvec)
		
		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,MinimapAPI:GetConfig("BorderBgColorA"),math.floor(MinimapAPI:GetConfig("BorderBgColorR")*255),math.floor(MinimapAPI:GetConfig("BorderBgColorG")*255),math.floor(MinimapAPI:GetConfig("BorderBgColorB")*255))
		MinimapAPI.SpriteMinimapSmall.Scale =
			Vector((MinimapAPI:GetConfig("MapFrameWidth") - frameTL.X) / dframeCenterSize.X, (MinimapAPI:GetConfig("MapFrameHeight") - frameTL.Y) / dframeCenterSize.Y)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameCenter", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + frameTL, zvec, zvec)
		
		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,MinimapAPI:GetConfig("BorderColorA"),0,0,0)
		
		MinimapAPI.SpriteMinimapSmall.Scale = Vector((MinimapAPI:GetConfig("MapFrameWidth") + frameTL.X) / dframeHorizBarSize.X, 1)
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameShadowS", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + Vector(frameTL.X, frameTL.Y + MinimapAPI:GetFrameBR().Y), zvec, zvec)

		MinimapAPI.SpriteMinimapSmall.Scale = Vector(1, (MinimapAPI:GetConfig("MapFrameHeight")) / (dframeVertBarSize.Y - frameTL.Y))
		MinimapAPI.SpriteMinimapSmall:SetFrame("MinimapAPIFrameShadowE", 0)
		MinimapAPI.SpriteMinimapSmall:Render(offsetVec + Vector(frameTL.X + MinimapAPI:GetFrameBR().X, frameTL.Y), zvec, zvec)
		
		MinimapAPI.SpriteMinimapSmall.Color = Color(1,1,1,1,0,0,0)
		MinimapAPI.SpriteMinimapSmall.Scale = Vector(1, 1)
	end

	if MinimapAPI:GetConfig("OverrideLost") or Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0 then
		MinimapAPI:UpdateMinimapCenterOffset()
		
		for i, v in ipairs(MinimapAPI:GetLevel()) do
			local roomOffset = (v.DisplayPosition or v.Position) - roomCenterOffset
			roomOffset.X = roomOffset.X * roomSize.X
			roomOffset.Y = roomOffset.Y * roomSize.Y
			v.TargetRenderOffset = offsetVec + roomOffset + MinimapAPI:GetFrameCenterOffset() + roomAnimPivot
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI:GetConfig("SmoothSlidingSpeed") + v.RenderOffset * (1 - MinimapAPI:GetConfig("SmoothSlidingSpeed"))
			else
				v.RenderOffset = v.TargetRenderOffset
			end
		end
		
		local defaultOutlineColor = Color(1, 1, 1, 1, math.floor(MinimapAPI:GetConfig("DefaultOutlineColorR")*255), math.floor(MinimapAPI:GetConfig("DefaultOutlineColorG")*255), math.floor(MinimapAPI:GetConfig("DefaultOutlineColorB")*255))
		local roomInView = {}
		if MinimapAPI:GetConfig("ShowShadows") then
			for i, v in pairs(MinimapAPI:GetLevel()) do
				local displayflags = v:GetDisplayFlags()
				if displayflags > 0 then
					for n, pos in ipairs(MinimapAPI:GetRoomShapePositions(v.Shape)) do
						pos = Vector(pos.X * roomSize.X, pos.Y * roomSize.Y)
						local actualRoomPixelSize = outlinePixelSize
						local brcutoff = v.RenderOffset - offsetVec + pos + actualRoomPixelSize - MinimapAPI:GetFrameBR()
						if brcutoff.X < actualRoomPixelSize.X and brcutoff.Y < actualRoomPixelSize.Y then 
							local tlcutoff = -(v.RenderOffset - offsetVec + pos) + frameTL
							if tlcutoff.X < actualRoomPixelSize.X and tlcutoff.Y < actualRoomPixelSize.Y then
								brcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
								tlcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
								MinimapAPI.SpriteMinimapSmall.Color = defaultOutlineColor
								MinimapAPI.SpriteMinimapSmall:SetFrame("RoomOutline", 1)
								MinimapAPI.SpriteMinimapSmall:Render(v.RenderOffset + pos, tlcutoff, brcutoff)
								roomInView[v] = true
							end
						end
					end
				end
			end
		end
		
		local defaultRoomColor = Color(MinimapAPI:GetConfig("DefaultRoomColorR"), MinimapAPI:GetConfig("DefaultRoomColorG"), MinimapAPI:GetConfig("DefaultRoomColorB"), 1, 0, 0, 0)
		for i, v in pairs(MinimapAPI:GetLevel()) do
			if roomInView[v] or not MinimapAPI:GetConfig("ShowShadows") then
				local iscurrent = MinimapAPI:PlayerInRoom(v)
				local displayflags = v:GetDisplayFlags()
				local spr = MinimapAPI.SpriteMinimapSmall
				if displayflags & 0x1 > 0 then
					local frame = MinimapAPI:GetRoomShapeFrame(v.Shape)
					local anim
					if iscurrent then
						anim = "RoomCurrent"
					elseif v:IsClear() then
						anim = "RoomVisited"
					elseif MinimapAPI:GetConfig("DisplayExploredRooms") and v:IsVisited() then
						spr = MinimapAPI.SpriteMinimapCustomSmall
						anim = "RoomSemivisited"
					else
						anim = "RoomUnvisited"
					end
					if type(frame) == "table" then
						local fr0 = frame.small
						local fr1 = fr0[anim] or fr0["RoomUnvisited"]
						spr = fr1.sprite or spr
						spr.Color = v.Color or defaultRoomColor
						updateMinimapIcon(spr, fr1)
					else
						spr:SetFrame(anim, frame)
						spr.Color = v.Color or defaultRoomColor
					end
					local rms = MinimapAPI:GetRoomShapeGridSize(v.Shape)
					local rsgp = MinimapAPI.RoomShapeGridPivots[v.Shape]
					local roomPivotOffset = Vector((roomPixelSize.X - 1) * rsgp.X, (roomPixelSize.Y - 1) * rsgp.Y)
					local roomPixelBR = Vector(roomPixelSize.X * rms.X, roomPixelSize.Y * rms.Y) - roomAnimPivot
					local brcutoff = v.RenderOffset - offsetVec + roomPixelBR - MinimapAPI:GetFrameBR() - roomPivotOffset
					local tlcutoff = -(v.RenderOffset - offsetVec - roomPivotOffset)
					if brcutoff.X < roomPixelBR.X and brcutoff.Y < roomPixelBR.Y and 
					tlcutoff.X - roomPivotOffset.X < roomPixelBR.X and tlcutoff.Y - roomPivotOffset.Y < roomPixelBR.Y then
						brcutoff:Clamp(0, 0, roomPixelBR.X, roomPixelBR.Y)
						tlcutoff:Clamp(0, 0, roomPixelBR.X, roomPixelBR.Y)
						spr:Render(v.RenderOffset, tlcutoff, brcutoff)
					end
				end
			end
		end

		MinimapAPI.SpriteMinimapSmall.Color = Color(1, 1, 1, 1, 0, 0, 0)

		if MinimapAPI:GetConfig("ShowIcons") then
			for i, v in pairs(MinimapAPI:GetLevel()) do
				if roomInView[v] then
					local incurrent = MinimapAPI:PlayerInRoom(v) and not MinimapAPI:GetConfig("ShowCurrentRoomItems")
					local displayflags = v:GetDisplayFlags() or 0
					local k = 1
					local function renderIcons(icons, locs)
						for _,icon in ipairs(icons) do
							local icontb = MinimapAPI:GetIconAnimData(icon)
							if icontb then
								local loc = locs[k]
								if not loc then return end

								local iconlocOffset = Vector(loc.X * roomSize.X, loc.Y * roomSize.Y)
								local spr = icontb.sprite or MinimapAPI.SpriteMinimapSmall
								updateMinimapIcon(spr, icontb)
								local brcutoff = v.RenderOffset - offsetVec + iconlocOffset + iconPixelSize - MinimapAPI:GetFrameBR()
								local tlcutoff = frameTL - (v.RenderOffset - offsetVec + iconlocOffset)
								if brcutoff.X < iconPixelSize.X and brcutoff.Y < iconPixelSize.Y and 
								tlcutoff.X < iconPixelSize.X and tlcutoff.Y < iconPixelSize.Y then
									brcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
									tlcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
									spr:Render(iconlocOffset + v.RenderOffset, tlcutoff, brcutoff)
									k = k + 1
								end
							end
						end
					end
					
					if displayflags & 0x4 > 0 then
						local iconcount = #v.PermanentIcons
						if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
							iconcount = iconcount + #v.ItemIcons
						end

						local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, iconcount)

						renderIcons(v.PermanentIcons, locs)
						if not incurrent and MinimapAPI:GetConfig("ShowPickupIcons") then
							renderIcons(v.ItemIcons, locs)
						end
					elseif displayflags & 0x2 > 0 then
						if v.LockedIcons and #v.LockedIcons > 0 then
							local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, #v.LockedIcons)
							renderIcons(v.LockedIcons, locs)
						end
					end
				end
			end
		end
	end
end

MinimapAPI.DisableSpelunkerHat = false

local function renderCallbackFunction(self)
	if MinimapAPI:GetConfig("Disable") or MinimapAPI.Disable then return end
	
	if badload then
		font:DrawString("MinimapAPI animation files failed to load.",70,30,KColor(1,0.5,0.5,1),0,false)
		font:DrawString("Restart your game!",70,40,KColor(1,0.5,0.5,1),0,false)
		
		font:DrawString("(This tends to happen when the mod is first installed, or when",70,60,KColor(1,0.5,0.5,1),0,false)
		font:DrawString("it is re-enabled via the mod menu)",70,70,KColor(1,0.5,0.5,1),0,false)
		
		font:DrawString("You will also need to restart the game after disabling the mod.",70,90,KColor(1,0.5,0.5,1),0,false)
		return
	end
	
	local r = Game():GetRoom()
	if r:GetFrameCount() == 0 and r:GetType() == RoomType.ROOM_BOSS and not r:IsClear() then
		return
	end
	
	if MinimapAPI:GetConfig("HideInCombat") == 2 then
		if not r:IsClear() and r:GetType() == RoomType.ROOM_BOSS then
			return
		end
	elseif MinimapAPI:GetConfig("HideInCombat") == 3 then
		if not r:IsClear() then
			return
		end
	end
	
	screen_size = MinimapAPI:GetScreenSize()
	if MinimapAPI:GetConfig("DisplayOnNoHUD") or not Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) then
		local currentroomdata = MinimapAPI:GetCurrentRoom()
		local gamelevel = Game():GetLevel()
		local gameroom = Game():GetRoom()
		local player = Isaac.GetPlayer(0)
		local hasSpelunkerHat = player:HasCollectible(CollectibleType.COLLECTIBLE_SPELUNKER_HAT) and not MinimapAPI.DisableSpelunkerHat
		
		if currentroomdata and MinimapAPI:PickupDetectionEnabled() then
			if not currentroomdata.NoUpdate then
				currentroomdata.ItemIcons = MinimapAPI:GetCurrentRoomPickupIDs()
				currentroomdata.DisplayFlags = 5
				currentroomdata.Clear = gamelevel:GetCurrentRoomDesc().Clear
				currentroomdata.Visited = true
			end
			if currentroomdata.Hidden then
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
			for i,v in ipairs(MinimapAPI:GetLevel()) do
				if not v.Hidden then
					v.DisplayFlags = v.DisplayFlags | 1
				end
			end
		end
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) then 
			for i,v in ipairs(MinimapAPI:GetLevel()) do
				if v.Hidden then
					v.DisplayFlags = v.DisplayFlags | 6
				end
			end
		end
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) then 
			for i,v in ipairs(MinimapAPI:GetLevel()) do
				if not v.Hidden and #v.PermanentIcons > 0 then
					v.DisplayFlags = v.DisplayFlags | 6
				end
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
			if MinimapAPI:IsLarge() then
				renderUnboundedMinimap("huge")
			elseif MinimapAPI:GetConfig("DisplayMode") == 1 then
				renderUnboundedMinimap("small")
			elseif MinimapAPI:GetConfig("DisplayMode") == 2 then
				renderBoundedMinimap()
			elseif MinimapAPI:GetConfig("DisplayMode") == 4 then
				renderUnboundedMinimap("small",true)
			end
			
			if MinimapAPI:GetConfig("ShowLevelFlags") then
				local levelflagoffset
				local islarge = MinimapAPI:IsLarge()
				if not islarge and MinimapAPI:GetConfig("DisplayMode") == 2 then
					levelflagoffset = Vector(screen_size.X - MinimapAPI:GetConfig("MapFrameWidth") - MinimapAPI:GetConfig("PositionX") - 9,8)
				elseif not islarge and MinimapAPI:GetConfig("DisplayMode") == 4 then
					levelflagoffset = Vector(screen_size.X - 9,8)
				else
					local minx = screen_size.X
					for i,v in ipairs(MinimapAPI:GetLevel()) do
						if v.TargetRenderOffset and v.TargetRenderOffset.Y < 64 then
							minx = math.min(minx, v.RenderOffset.X)
						end
					end
					levelflagoffset = Vector(minx-9,8)
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
		if is_save and saved.LevelData and saved.Seed == Game():GetSeeds():GetStartSeed() then
			local vanillarooms = Game():GetLevel():GetRooms()
			MinimapAPI:ClearMap()
			for i, v in ipairs(saved.LevelData) do
				MinimapAPI:AddRoom{
					Position = Vector(v.PositionX, v.PositionY),
					DisplayPosition = (v.DisplayPositionX and v.DisplayPositionY) and Vector(v.DisplayPositionX, v.DisplayPositionY),
					ID = v.ID,
					Shape = v.Shape,
					ItemIcons = v.ItemIcons,
					PermanentIcons = v.PermanentIcons,
					LockedIcons = v.LockedIcons,
					Descriptor = v.DescriptorListIndex and vanillarooms:Get(v.DescriptorListIndex),
					DisplayFlags = v.DisplayFlags,
					Clear = v.Clear,
					Color = v.Color and Color(v.Color.R, v.Color.G, v.Color.B, v.Color.A, math.floor(v.Color.RO+0.5), math.floor(v.Color.GO+0.5), math.floor(v.Color.BO+0.5)),
					AdjacentDisplayFlags = v.AdjacentDisplayFlags,
					Visited = v.Visited,
					Hidden = v.Hidden,
					NoUpdate = v.NoUpdate,
				}
			end
			if saved.playerMapPosX and saved.playerMapPosY then
				playerMapPos = Vector(saved.playerMapPosX,saved.playerMapPosY)
			end
		else
			MinimapAPI:LoadDefaultMap()
		end
	end
end

function MinimapAPI:GetSaveTable(menuexit)
	local saved = {}
	saved.Config = MinimapAPI.Config
	saved.Seed = Game():GetSeeds():GetStartSeed()
	if menuexit then
		saved.playerMapPosX = playerMapPos.X
		saved.playerMapPosY = playerMapPos.Y
		saved.LevelData = {}
		for i, v in ipairs(MinimapAPI:GetLevel()) do
			saved.LevelData[#saved.LevelData + 1] = {
				PositionX = v.Position.X,
				PositionY = v.Position.Y,
				ID = type(v.ID) ~= "userdata" and v.ID,
				Shape = v.Shape,
				ItemIcons = v.ItemIcons,
				PermanentIcons = v.PermanentIcons,
				LockedIcons = v.LockedIcons,
				DescriptorListIndex = v.Descriptor and v.Descriptor.ListIndex,
				DisplayFlags = rawget(v, "DisplayFlags"),
				Clear = rawget(v, "Clear"),
				Color = v.Color and {R = v.Color.R, G = v.Color.G, B = v.Color.B, A = v.Color.A, RO = v.Color.RO, GO = v.Color.GO, BO = v.Color.BO},
				AdjacentDisplayFlags = v.AdjacentDisplayFlags,
				Visited = v.Visited,
				Hidden = v.Hidden,
				NoUpdate = v.NoUpdate,
				DisplayPositionX = v.DisplayPosition and v.DisplayPosition.X,
				DisplayPositionY = v.DisplayPosition and v.DisplayPosition.Y,
			}
		end
	end
	return saved
end

-- LOADING SAVED GAME
local addRenderCall = true
MinimapAPI:AddCallback(
	ModCallbacks.MC_POST_GAME_STARTED,
	function(self, is_save)
		badload = MinimapAPI:IsBadLoad()
		if addRenderCall then
			MinimapAPI:AddCallback(ModCallbacks.MC_POST_RENDER, renderCallbackFunction)
			addRenderCall = false
		end
		if MinimapAPI:HasData() then
			if not MinimapAPI.DisableSaving then
				local saved = json.decode(Isaac.LoadModData(MinimapAPI))
				MinimapAPI:LoadSaveTable(saved,is_save)
			else
				MinimapAPI:LoadDefaultMap()
			end
			MinimapAPI:UpdateExternalMap()
		else
			MinimapAPI:LoadDefaultMap()
		end
	end
)

-- SAVING GAME
MinimapAPI:AddCallback(
	ModCallbacks.MC_PRE_GAME_EXIT,
	function(self, menuexit)
		if not MinimapAPI.DisableSaving then
			MinimapAPI:SaveData(json.encode(MinimapAPI:GetSaveTable(menuexit)))
		end
	end
)

