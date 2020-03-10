local json = require("json")

local function assertLevel(bool,msg,lvl)
	if not bool then
		error(msg,lvl)
	end
end

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
	local ls = Game():GetLevel():GetStage()
	if ls == LevelStage.STAGE1_2 then
		return true
	elseif ls == LevelStage.STAGE2_2 then
		return true
	elseif ls == LevelStage.STAGE3_2 then
		return true
	elseif ls == LevelStage.STAGE4_2 then
		return true
	else
		return false
	end
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
local playerMapPos = Vector(0, 0)
MinimapAPI.Level = {}
MinimapAPI.OverrideVoid = false

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

local zvec = Vector(0, 0)

local minimapsmall = Sprite()
minimapsmall:Load("gfx/ui/minimapapi_minimap1.anm2", true)
local minimaplarge = Sprite()
minimaplarge:Load("gfx/ui/minimapapi_minimap2.anm2", true)
local minimapicons = Sprite()
minimapicons:Load("gfx/ui/minimapapi_mapitemicons.anm2", true)
local minimapcustomsmall = Sprite()
minimapcustomsmall:Load("gfx/ui/minimapapi/custom_minimap1.anm2", true)
local minimapcustomlarge = Sprite()
minimapcustomlarge:Load("gfx/ui/minimapapi/custom_minimap2.anm2", true)

function MinimapAPI:GetLevel()
	return MinimapAPI.Level
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

function MinimapAPI:GetSprite()
	return minimapsmall
end

function MinimapAPI:GetSpriteLarge()
	return minimaplarge
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

-- TODO: Add Room Shape
-- MinimapAPI.CustomRoomShapes = {}
-- function MinimapAPI:AddRoomShape(id, t)
	-- assertLevel(id ~= nil, string.format(errorBadArgument, "#1", "AddRoomShape", "any", "nil"), 3)
	-- assertLevel(getType(t) == "table", string.format(errorBadArgument, "#2", "AddRoomShape", "table", getType(t)), 3)
	-- MinimapAPI.CustomRoomShapes[id] = {
		-- Anim = t.Anim,
		-- Positions = t.Positions or {Vector(0,0)},
	-- }
	
-- end

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
	return mapheldframes > 7 or MinimapAPI.Config.DisplayMode == 3
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
			local ind = MinimapAPI.Config.PickupNoGrouping and (#pickupgroupset + 1) or pickupicon.IconGroup
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
	if not MinimapAPI.Config.PickupFirstComeFirstServe then
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

function MinimapAPI:LoadDefaultMap()
	rooms = Game():GetLevel():GetRooms()
	MinimapAPI.Level = {}
	local treasure_room_count = 0
	for i = 0, #rooms - 1 do
		local v = rooms:Get(i)
		local t = {
			Shape = v.Data.Shape,
			PermanentIcons = {MinimapAPI:GetRoomTypeIconID(v.Data.Type)},
			LockedIcons = {MinimapAPI:GetUnknownRoomTypeIconID(v.Data.Type)},
			ItemIcons = {},
			Position = MinimapAPI:GridIndexToVector(v.GridIndex),
			Descriptor = v,
			AdjacentDisplayFlags = MinimapAPI.RoomTypeDisplayFlagsAdjacent[v.Data.Type] or 5,
			Type = v.Data.Type,
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
		MinimapAPI:AddRoom(t)
	end
	if not (MinimapAPI.Config.OverrideVoid or MinimapAPI.OverrideVoid) then
		if not Game():IsGreedMode() then
			if Game():GetLevel():GetStage() == LevelStage.STAGE7 then
				for i,v in ipairs(MinimapAPI.Level) do
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

function MinimapAPI:EffectBookOfSecrets()
	for i,v in ipairs(MinimapAPI.Level) do
		v:Reveal()
	end
end

function MinimapAPI:EffectCrystalBall()
	for i,v in ipairs(MinimapAPI.Level) do
		if v.Type ~= RoomType.ROOM_SUPERSECRET then
			v:Reveal()
		end
	end
end

function MinimapAPI:ClearMap()
	MinimapAPI.Level = {}
end

local maproomfunctions = {
	IsVisible = function(room)
		return (room.DisplayFlags or 0) & 1 > 0
	end,
	IsShadow = function(room)
		return (room.DisplayFlags or 0) & 2 > 0
	end,
	IsIconVisible = function(room)
		return (room.DisplayFlags or 0) & 4 > 0
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
		local df = room.DisplayFlags or 0
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
		else
			room.DisplayFlags = df
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
	}
	setmetatable(x, maproommeta)
	MinimapAPI.Level[#MinimapAPI.Level + 1] = x
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
	for i, v in ipairs(MinimapAPI.Level) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			removeAdjacentRoomRefs(v)
			table.remove(MinimapAPI.Level, i)
			success = true
			MinimapAPI:UpdateExternalMap()
			break
		end
	end
	return success
end

function MinimapAPI:RemoveRoomByID(id)
	for i = #MinimapAPI.Level, 1, -1 do
		local v = MinimapAPI.Level[i]
		if v.ID == id then
			removeAdjacentRoomRefs(v)
			table.remove(MinimapAPI.Level, i)
		end
	end
	MinimapAPI:UpdateExternalMap()
end

function MinimapAPI:GetRoom(pos)
	assert(MinimapAPI:InstanceOf(pos, Vector), "bad argument #1 to 'GetRoom', expected Vector")
	local success
	for i, v in ipairs(MinimapAPI.Level) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			success = v
			break
		end
	end
	return success
end

function MinimapAPI:GetRoomAtPosition(position)
	assert(MinimapAPI:InstanceOf(position, Vector), "bad argument #1 to 'GetRoomAtPosition', expected Vector")
	for i, v in ipairs(MinimapAPI.Level) do
		for _,pos in ipairs(MinimapAPI.RoomShapePositions[v.Shape]) do
			local p = v.Position + pos
			if p.X == position.X and p.Y == position.Y then
				return v
			end
		end
	end
end

function MinimapAPI:GetRoomByID(ID)
	for i, v in ipairs(MinimapAPI.Level) do
		if v.ID == ID then
			return v
		end
	end
end

function MinimapAPI:GetRoomByIdx(Idx)
	for i, v in ipairs(MinimapAPI.Level) do
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
	for _,room in ipairs(MinimapAPI.Level) do
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
	local currentroom = Game():GetLevel():GetCurrentRoomDesc()
	if currentroom.GridIndex == -1 then
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
	MinimapAPI:LoadDefaultMap()
	updatePlayerPos()
	MinimapAPI:UpdateExternalMap()
end)

function MinimapAPI:UpdateUnboundedMapOffset()
	local maxx
	local miny
	for i = 1, #(MinimapAPI.Level) do
		local v = MinimapAPI.Level[i]
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
	if colltype == CollectibleType.COLLECTIBLE_BOOK_OF_SECRETS then
		MinimapAPI:EffectBookOfSecrets()
		MinimapAPI:UpdateExternalMap()
	elseif colltype == CollectibleType.COLLECTIBLE_CRYSTAL_BALL then
		MinimapAPI:EffectCrystalBall()
		MinimapAPI:UpdateExternalMap()
	end
end)

function MinimapAPI:UpdateExternalMap()
	if MinimapAPI.Config.ExternalMap then
		local output = {}
		local extlevel = {}
		output.Level = extlevel
		for i,v in ipairs(MinimapAPI.Level) do
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
	updatePlayerPos()
	-- for i,v in ipairs(MinimapAPI.Level) do
		-- if not v.NoUpdate then
			-- v:UpdateType()
		-- end
	-- end
	MinimapAPI:UpdateExternalMap()
end)

function MinimapAPI:ShowMap()
	for i,v in ipairs(MinimapAPI.Level) do
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
	end
end)

function MinimapAPI:PrevMapDisplayMode()
	local modes = {
		[1] = MinimapAPI.Config.AllowToggleSmallMap,
		[2] = MinimapAPI.Config.AllowToggleBoundedMap,
		[3] = MinimapAPI.Config.AllowToggleLargeMap,
		[4] = MinimapAPI.Config.AllowToggleNoMap,
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
		[1] = MinimapAPI.Config.AllowToggleSmallMap,
		[2] = MinimapAPI.Config.AllowToggleBoundedMap,
		[3] = MinimapAPI.Config.AllowToggleLargeMap,
		[4] = MinimapAPI.Config.AllowToggleNoMap,
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
	local gameLvl = Game():GetLevel()
	
	local flags = {}
	
	local offset=Vector(0,0)
	if gameLvl:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) then 
		flags[#flags + 1] = 2
	end
	if gameLvl:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) then 
		flags[#flags + 1] = 1
	end
	if gameLvl:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) then 
		flags[#flags + 1] = 0
	end
	if Isaac.GetPlayer(0):HasCollectible(CollectibleType.COLLECTIBLE_RESTOCK) or Game():IsGreedMode() then 
		flags[#flags + 1] = 4
	end
	
	-- local offset = Vector(math.floor((#flags-1)/4)*-16,0)
	local offset = Vector(0,0)
	for i,v in ipairs(flags) do
		minimapicons:SetFrame("icons", v)
		minimapicons:Render(renderOffset+offset, zvec, zvec)
		offset=offset+Vector(0,16)
		-- if offset.Y >= 48 then
			-- offset = offset + Vector(16,-48)
		-- end
	end
	
end

local function renderUnboundedMinimap(size,hide)
	if MinimapAPI.Config.OverrideLost or Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0 then
		MinimapAPI:UpdateUnboundedMapOffset()
		local offsetVec = Vector(screen_size.X - MinimapAPI.Config.PositionX, MinimapAPI.Config.PositionY)
		local renderRoomSize = size == "small" and roomSize or largeRoomSize
		local renderAnimPivot = size == "small" and roomAnimPivot or largeRoomAnimPivot
		local sprite = size == "small" and minimapsmall or minimaplarge
		
		for i, v in ipairs(MinimapAPI.Level) do
			local roomOffset = (v.DisplayPosition or v.Position) + unboundedMapOffset
			roomOffset.X = roomOffset.X * renderRoomSize.X
			roomOffset.Y = roomOffset.Y * renderRoomSize.Y
			v.TargetRenderOffset = offsetVec + roomOffset + renderAnimPivot
			if hide then
				v.TargetRenderOffset = v.TargetRenderOffset + Vector(0,-800)
			end
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI.Config.SmoothSlidingSpeed + v.RenderOffset * (1 - MinimapAPI.Config.SmoothSlidingSpeed)
			else
				v.RenderOffset = v.TargetRenderOffset
			end
			if v.RenderOffset:DistanceSquared(v.TargetRenderOffset) <= 1 then
				v.RenderOffset = v.TargetRenderOffset
			end
		end
		
		if hide then return end
		
		local defaultOutlineColor = Color(1, 1, 1, 1, math.floor(MinimapAPI.Config.DefaultOutlineColorR*255), math.floor(MinimapAPI.Config.DefaultOutlineColorG*255), math.floor(MinimapAPI.Config.DefaultOutlineColorB*255))
		if MinimapAPI.Config.ShowShadows then
			for i, v in pairs(MinimapAPI.Level) do
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
		
		local defaultRoomColor = Color(MinimapAPI.Config.DefaultRoomColorR, MinimapAPI.Config.DefaultRoomColorG, MinimapAPI.Config.DefaultRoomColorB, 1, 0, 0, 0)
		for i, v in pairs(MinimapAPI.Level) do
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
				elseif MinimapAPI.Config.DisplayExploredRooms and v:IsVisited() then
					spr = size == "small" and minimapcustomsmall or minimapcustomlarge
					anim = "RoomSemivisited"
				else
					anim = "RoomUnvisited"
				end
				if type(frame) == "table" then
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

		sprite.Color = Color(1, 1, 1, 1, 0, 0, 0)

		if MinimapAPI.Config.ShowIcons then
			for i, v in pairs(MinimapAPI.Level) do
				local incurrent = MinimapAPI:PlayerInRoom(v) and not MinimapAPI.Config.ShowCurrentRoomItems
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
					if not incurrent and MinimapAPI.Config.ShowPickupIcons then
						iconcount = iconcount + #v.ItemIcons
					end

					local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, iconcount)
					if size ~= "small" then
						locs = MinimapAPI:GetLargeRoomShapeIconPositions(v.Shape, iconcount)
					end
					renderIcons(v.PermanentIcons, locs)
					if not incurrent and MinimapAPI.Config.ShowPickupIcons then
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
	local offsetVec = Vector( screen_size.X - MinimapAPI.Config.MapFrameWidth - MinimapAPI.Config.PositionX - 1, MinimapAPI.Config.PositionY - 2)
	do
		minimapsmall.Scale = Vector((MinimapAPI.Config.MapFrameWidth + frameTL.X) / dframeHorizBarSize.X, 1)
		minimapsmall:SetFrame("MinimapAPIFrameN", 0)
		minimapsmall:Render(offsetVec, zvec, zvec)
		minimapsmall:SetFrame("MinimapAPIFrameS", 0)
		minimapsmall:Render(offsetVec + Vector(0, MinimapAPI.Config.MapFrameHeight), zvec, zvec)

		minimapsmall.Scale = Vector(1, MinimapAPI.Config.MapFrameHeight / dframeVertBarSize.Y)
		minimapsmall:SetFrame("MinimapAPIFrameW", 0)
		minimapsmall:Render(offsetVec, zvec, zvec)
		minimapsmall:SetFrame("MinimapAPIFrameE", 0)
		minimapsmall:Render(offsetVec + Vector(MinimapAPI.Config.MapFrameWidth, 0), zvec, zvec)
		
		minimapsmall.Scale =
			Vector((MinimapAPI.Config.MapFrameWidth - frameTL.X) / dframeCenterSize.X, (MinimapAPI.Config.MapFrameHeight - frameTL.Y) / dframeCenterSize.Y)
		minimapsmall:SetFrame("MinimapAPIFrameCenter", 0)
		minimapsmall:Render(offsetVec + frameTL, zvec, zvec)
		
		minimapsmall.Scale = Vector((MinimapAPI.Config.MapFrameWidth + frameTL.X) / dframeHorizBarSize.X, 1)
		minimapsmall:SetFrame("MinimapAPIFrameShadowS", 0)
		minimapsmall:Render(offsetVec + Vector(frameTL.X, frameTL.Y + MinimapAPI:GetFrameBR().Y), zvec, zvec)

		minimapsmall.Scale = Vector(1, (MinimapAPI.Config.MapFrameHeight) / (dframeVertBarSize.Y - frameTL.Y))
		minimapsmall:SetFrame("MinimapAPIFrameShadowE", 0)
		minimapsmall:Render(offsetVec + Vector(frameTL.X + MinimapAPI:GetFrameBR().X, frameTL.Y), zvec, zvec)

		minimapsmall.Scale = Vector(1, 1)
	end

	if MinimapAPI.Config.OverrideLost or Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0 then
		MinimapAPI:UpdateMinimapCenterOffset()
		
		for i, v in ipairs(MinimapAPI.Level) do
			local roomOffset = (v.DisplayPosition or v.Position) - roomCenterOffset
			roomOffset.X = roomOffset.X * roomSize.X
			roomOffset.Y = roomOffset.Y * roomSize.Y
			v.TargetRenderOffset = offsetVec + roomOffset + MinimapAPI:GetFrameCenterOffset() + roomAnimPivot
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI.Config.SmoothSlidingSpeed + v.RenderOffset * (1 - MinimapAPI.Config.SmoothSlidingSpeed)
			else
				v.RenderOffset = v.TargetRenderOffset
			end
		end
		
		local defaultOutlineColor = Color(1, 1, 1, 1, math.floor(MinimapAPI.Config.DefaultOutlineColorR*255), math.floor(MinimapAPI.Config.DefaultOutlineColorG*255), math.floor(MinimapAPI.Config.DefaultOutlineColorB*255))
		local roomInView = {}
		if MinimapAPI.Config.ShowShadows then
			for i, v in pairs(MinimapAPI.Level) do
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
								minimapsmall.Color = defaultOutlineColor
								minimapsmall:SetFrame("RoomOutline", 1)
								minimapsmall:Render(v.RenderOffset + pos, tlcutoff, brcutoff)
								roomInView[v] = true
							end
						end
					end
				end
			end
		end
		
		local defaultRoomColor = Color(MinimapAPI.Config.DefaultRoomColorR, MinimapAPI.Config.DefaultRoomColorG, MinimapAPI.Config.DefaultRoomColorB, 1, 0, 0, 0)
		for i, v in pairs(MinimapAPI.Level) do
			if roomInView[v] or not MinimapAPI.Config.ShowShadows then
				local iscurrent = MinimapAPI:PlayerInRoom(v)
				local displayflags = v:GetDisplayFlags()
				local spr = minimapsmall
				if displayflags & 0x1 > 0 then
					local frame = MinimapAPI:GetRoomShapeFrame(v.Shape)
					local anim
					if iscurrent then
						anim = "RoomCurrent"
					elseif v:IsClear() then
						anim = "RoomVisited"
					elseif MinimapAPI.Config.DisplayExploredRooms and v:IsVisited() then
						spr = minimapcustomsmall
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

		minimapsmall.Color = Color(1, 1, 1, 1, 0, 0, 0)

		if MinimapAPI.Config.ShowIcons then
			for i, v in pairs(MinimapAPI.Level) do
				if roomInView[v] then
					local incurrent = MinimapAPI:PlayerInRoom(v) and not MinimapAPI.Config.ShowCurrentRoomItems
					local displayflags = v:GetDisplayFlags() or 0
					local k = 1
					local function renderIcons(icons, locs)
						for _,icon in ipairs(icons) do
							local icontb = MinimapAPI:GetIconAnimData(icon)
							if icontb then
								local loc = locs[k]
								if not loc then return end

								local iconlocOffset = Vector(loc.X * roomSize.X, loc.Y * roomSize.Y)
								local spr = icontb.sprite or minimapsmall
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
						if not incurrent and MinimapAPI.Config.ShowPickupIcons then
							iconcount = iconcount + #v.ItemIcons
						end

						local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, iconcount)

						renderIcons(v.PermanentIcons, locs)
						if not incurrent and MinimapAPI.Config.ShowPickupIcons then
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
	if MinimapAPI.Config.Disable then return end
	
	if badload then
		font:DrawString("MinimapAPI didn't load correctly.",40,30,KColor(1,0.5,0.5,1),0,false)
		font:DrawString("Restart your game!",40,40,KColor(1,0.5,0.5,1),0,false)
		
		font:DrawString("(This tends to happen when the mod is first installed, or when",40,60,KColor(1,0.5,0.5,1),0,false)
		font:DrawString("it is re-enabled via the mod menu)",40,70,KColor(1,0.5,0.5,1),0,false)
		
		font:DrawString("If you have restarted already and are still getting this message,",40,90,KColor(1,0.5,0.5,1),0,false)
		font:DrawString("leave a comment on the workshop page.",40,100,KColor(1,0.5,0.5,1),0,false)
		return
	end
	
	if MinimapAPI.Config.HideInCombat == 2 then
		local r = Game():GetRoom()
		if not r:IsClear() and r:GetType() == RoomType.ROOM_BOSS then
			return
		end
	elseif MinimapAPI.Config.HideInCombat == 3 then
		if not Game():GetRoom():IsClear() then
			return
		end
	end
	screen_size = MinimapAPI:GetScreenSize()
	if MinimapAPI.Config.DisplayOnNoHUD or not Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) then
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
		
		--update map display flags
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) then 
			for i,v in ipairs(MinimapAPI.Level) do
				if not v.Hidden then
					v.DisplayFlags = v.DisplayFlags | 1
				end
			end
		end
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) then 
			for i,v in ipairs(MinimapAPI.Level) do
				if v.Hidden then
					v.DisplayFlags = v.DisplayFlags | 6
				end
			end
		end
		if gamelevel:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) then 
			for i,v in ipairs(MinimapAPI.Level) do
				if not v.Hidden and #v.PermanentIcons > 0 then
					v.DisplayFlags = v.DisplayFlags | 6
				end
			end
		end
		
		if MinimapAPI.Level then
			minimapsmall.Scale = Vector(1, 1)
			if MinimapAPI:IsLarge() then
				renderUnboundedMinimap("huge")
			elseif MinimapAPI.Config.DisplayMode == 1 then
				renderUnboundedMinimap("small")
			elseif MinimapAPI.Config.DisplayMode == 2 then
				renderBoundedMinimap()
			elseif MinimapAPI.Config.DisplayMode == 4 then
				renderUnboundedMinimap("small",true)
			end
			
			if MinimapAPI.Config.ShowLevelFlags then
				local levelflagoffset
				local islarge = MinimapAPI:IsLarge()
				if not islarge and MinimapAPI.Config.DisplayMode == 2 then
					levelflagoffset = Vector(screen_size.X - MinimapAPI.Config.MapFrameWidth - MinimapAPI.Config.PositionX - 9,8)
				elseif not islarge and MinimapAPI.Config.DisplayMode == 4 then
					levelflagoffset = Vector(screen_size.X - 9,8)
				else
					local minx = screen_size.X
					for i,v in ipairs(MinimapAPI.Level) do
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
				MinimapAPI:AddRoom {
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
		for i, v in ipairs(MinimapAPI.Level) do
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

