local json = require("json")

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
local rooms
local playerMapPos = Vector(0, 0)
MinimapAPI.Level = {}

local mapheldframes = 0

local callbacks_playerpos = {}
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

function MinimapAPI:GetCurrentRoomPickupIDs() --gets pickup icon ids for current room ONLY
	local ents = Isaac.GetRoomEntities()
	local pickupgroupset = {}
	local addIcons = {}
	for _, ent in ipairs(ents) do
		local success = false
		local hash = GetPtrHash(ent)
		if ent:GetData().MinimapAPIPickupID == nil then
			for i, v in pairs(MinimapAPI.PickupList) do
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
			if not success then
				ent:GetData().MinimapAPIPickupID = false
			end
		end
		
		local id = ent:GetData().MinimapAPIPickupID
		local pickupicon = MinimapAPI.PickupList[id]
		if pickupicon then
			if MinimapAPI.Config.PickupNoGrouping or not pickupgroupset[pickupicon.IconGroup] then
				if (not pickupicon.Call) or pickupicon.Call(ent) then
					if pickupicon.IconGroup then
						pickupgroupset[pickupicon.IconGroup] = true
					end
					table.insert(addIcons, id)
				end
			end
		end
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
		local s, ret = pcall(v.call, MinimapAPI:GetCurrentRoom(), playerMapPos)
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
			AdjacentDisplayFlags = MinimapAPI.RoomTypeDisplayFlagsAdjacent[v.Data.Type] or 5
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
	if not MinimapAPI.Config.OverrideVoid then
		if not Game():IsGreedMode() then
			if Game():GetLevel():GetStage() == LevelStage.STAGE7 then
				for i,v in ipairs(MinimapAPI.Level) do
					if v.Shape == RoomShape.ROOMSHAPE_2x2 and v.Descriptor.Data.Type == RoomType.ROOM_BOSS then
						if MinimapAPI:GetPositionRelativeToDoor(v,0) or MinimapAPI:GetPositionRelativeToDoor(v,1) then
							--
						elseif MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.UP1) or MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT0) then
							v.DisplayPosition = v.Position + Vector(1,0)
						elseif MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.RIGHT1) or MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN1) then
							v.DisplayPosition = v.Position + Vector(1,1)
						elseif MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.LEFT1) or MinimapAPI:GetPositionRelativeToDoor(v,DoorSlot.DOWN0) then
							v.DisplayPosition = v.Position + Vector(0,1)
						end
						v.Shape = RoomShape.ROOMSHAPE_1x1
					end
				end
			end
		end
	end
end

function MinimapAPI:ClearMap()
	MinimapAPI.Level = {}
end

local maproomfunctions = {
	IsVisible = function(self)
		return (self.DisplayFlags or 0) & 1 > 0
	end,
	IsShadow = function(self)
		return (self.DisplayFlags or 0) & 2 > 0
	end,
	IsIconVisible = function(self)
		return (self.DisplayFlags or 0) & 4 > 0
	end,
	IsVisited = function(self)
		return self.Visited or false
	end,
	GetDisplayFlags = function(self)
		return self.DisplayFlags or 0
	end,
	IsClear = function(self)
		return self.Clear or false
	end,
	SetDisplayFlags = function(self,df)
		if self.Descriptor then
			self.Descriptor.DisplayFlags = df
		else
			self.DisplayFlags = df
		end
	end,
	GetAdjacentRooms = function(room)
		local x = {}
		for i,v in ipairs(MinimapAPI.RoomShapeAdjacentCoords[room.Shape]) do
			x[#x + 1] = MinimapAPI:GetRoomAtPosition(room.Position + v)
		end
		return x
	end
}

local maproommeta = {
	__index = maproomfunctions
}

function MinimapAPI:AddRoom(t)
	local defaultPosition = Vector(12, -1)
	if not t.AllowRoomOverlap then
		for i,v in ipairs(MinimapAPI.RoomShapePositions[t.Shape or RoomShape.ROOMSHAPE_1x1]) do
			MinimapAPI:RemoveRoom((t.Position or defaultPosition)+v)
		end
	end
	local x = {
		Position = t.Position or defaultPosition,
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
	return x
end

function MinimapAPI:RemoveRoom(pos)
	assert(MinimapAPI:InstanceOf(pos, Vector), "bad argument #1 to 'RemoveRoom', expected Vector")
	local success = false
	for i, v in ipairs(MinimapAPI.Level) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			table.remove(MinimapAPI.Level, i)
			success = true
			break
		end
	end
	return success
end

function MinimapAPI:RemoveRoomByID(id)
	for i = #MinimapAPI.Level, 1, -1 do
		local v = MinimapAPI.Level[i]
		if v.ID == id then
			table.remove(MinimapAPI.Level, i)
		end
	end
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
	local p = MinimapAPI.RoomShapeDoorCoords[room.Shape][doorslot]
	if p then
		return p + room.Position
	else
		return nil
	end
end

function MinimapAPI:IsPositionFree(position)
	for _,room in ipairs(MinimapAPI.Level) do
		for _,pos in ipairs(MinimapAPI.RoomShapePositions[room.Shape]) do
			local p = pos + room.Position
			if p.X == position.X and p.Y == position.Y then
				return false
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
	MinimapAPI:RemovePlayerPositionCallback(modtable)
	callbacks_playerpos[#callbacks_playerpos + 1] = {
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

MinimapAPI:AddCallback(	ModCallbacks.MC_POST_NEW_LEVEL,	function(self)
	MinimapAPI:LoadDefaultMap()
	updatePlayerPos()
end)

function MinimapAPI:UpdateUnboundedMapOffset()
	local maxx
	local miny
	for i = 1, #(MinimapAPI.Level) do
		local v = MinimapAPI.Level[i]
		if (v.DisplayFlags or 0) > 0 then
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

MinimapAPI:AddCallback(	ModCallbacks.MC_POST_NEW_ROOM, function(self)
	updatePlayerPos()
end)

function MinimapAPI:ShowMap()
	for i,v in ipairs(MinimapAPI.Level) do
		if v.Hidden then
			v.DisplayFlags = 6
		else
			v.DisplayFlags = 5
		end
	end
end

MinimapAPI:AddCallback( ModCallbacks.MC_USE_CARD, function(self, card)
	if card == Card.CARD_WORLD or card == Card.CARD_SUN then
		MinimapAPI:ShowMap()
	end
end)

MinimapAPI:AddCallback( ModCallbacks.MC_POST_UPDATE, function(self)
	if Input.IsActionPressed(ButtonAction.ACTION_MAP, 0) then
		mapheldframes = mapheldframes + 1
	elseif mapheldframes > 0 then
		if mapheldframes < 8 then
			local modes = {
				[1] = MinimapAPI.Config.AllowToggleSmallMap,
				[2] = MinimapAPI.Config.AllowToggleBoundedMap,
				[3] = MinimapAPI.Config.AllowToggleLargeMap,
			}
			for i=1,3 do
				MinimapAPI.Config.DisplayMode = MinimapAPI.Config.DisplayMode + 1
				if MinimapAPI.Config.DisplayMode > 3 then
					MinimapAPI.Config.DisplayMode = 1
				end
				if modes[MinimapAPI.Config.DisplayMode] then
					break
				end
			end
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

function MinimapAPI:GetDiscoveredBounds()
	local minx
	local maxx
	local miny
	local maxy
	for i = 1, #(MinimapAPI.Level) do
		local v = MinimapAPI.Level[i]
		if (v.DisplayFlags or 0) > 0 then
			local minxval = v.Position.X
			if not minx or (minxval < minx) then minx = minxval	end
			local maxxval = v.Position.X - MinimapAPI.RoomShapeGridPivots[v.Shape].X + MinimapAPI:GetRoomShapeGridSize(v.Shape).X
			if not maxx or (maxxval > maxx) then maxx = maxxval	end
			
			local minyval = v.Position.Y
			if not miny or (minyval < miny) then miny = minyval	end
			local maxyval = v.Position.Y - MinimapAPI.RoomShapeGridPivots[v.Shape].Y + MinimapAPI:GetRoomShapeGridSize(v.Shape).Y
			if not maxy or (maxyval > maxy) then maxy = maxyval	end
		end
	end
	return {minx,maxx,miny,maxy}
end

local function renderUnboundedMinimap(size)
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
			v.TargetRenderOffset = roomOffset + renderAnimPivot
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI.Config.SmoothSlidingSpeed + v.RenderOffset * (1 - MinimapAPI.Config.SmoothSlidingSpeed)
			else
				v.RenderOffset = v.TargetRenderOffset
			end
			if v.RenderOffset:DistanceSquared(v.TargetRenderOffset) <= 1 then
				v.RenderOffset = v.TargetRenderOffset
			end
		end

		if MinimapAPI.Config.ShowShadows then
			for i, v in pairs(MinimapAPI.Level) do
				local displayflags = v:GetDisplayFlags()
				if displayflags > 0 then
					for n, pos in ipairs(MinimapAPI:GetRoomShapePositions(v.Shape)) do
						pos = Vector(pos.X * renderRoomSize.X, pos.Y * renderRoomSize.Y)
						--local actualRoomPixelSize = renderOutlinePixelSize   -- unused
						sprite:SetFrame("RoomOutline", 1)
						sprite:Render(offsetVec + v.RenderOffset + pos, zvec, zvec)
					end
				end
			end
		end
		
		local defaultRoomColor = Color(MinimapAPI.Config.DefaultRoomColorR, MinimapAPI.Config.DefaultRoomColorG, MinimapAPI.Config.DefaultRoomColorB, 1, 0, 0, 0)
		for i, v in pairs(MinimapAPI.Level) do
			local iscurrent = MinimapAPI:PlayerInRoom(v)
			local displayflags = v:GetDisplayFlags()
			if displayflags & 0x1 > 0 then
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
				spr:SetFrame(anim, MinimapAPI:GetRoomShapeFrame(v.Shape))
				spr.Color = v.Color or defaultRoomColor
				spr:Render(offsetVec + v.RenderOffset, zvec, zvec)
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
								spr:Render(offsetVec + iconlocOffset + v.RenderOffset, zvec, zvec)
							else
								spr:Render(offsetVec + iconlocOffset + v.RenderOffset - largeRoomAnimPivot + largeIconOffset, zvec, zvec)
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
	local offsetVec = Vector( screen_size.X - MinimapAPI.Config.MapFrameWidth - MinimapAPI.Config.PositionX - 1, MinimapAPI.Config.PositionY - 2.5)
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
			Vector(MinimapAPI.Config.MapFrameWidth / dframeCenterSize.X, MinimapAPI.Config.MapFrameHeight / dframeCenterSize.Y)
		minimapsmall:SetFrame("MinimapAPIFrameCenter", 0)
		minimapsmall:Render(offsetVec, zvec, zvec)

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
			v.TargetRenderOffset = roomOffset + MinimapAPI:GetFrameCenterOffset() + roomAnimPivot
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI.Config.SmoothSlidingSpeed + v.RenderOffset * (1 - MinimapAPI.Config.SmoothSlidingSpeed)
			else
				v.RenderOffset = v.TargetRenderOffset
			end
		end

		if MinimapAPI.Config.ShowShadows then
			for i, v in pairs(MinimapAPI.Level) do
				local displayflags = v:GetDisplayFlags()
				if displayflags > 0 then
					for n, pos in ipairs(MinimapAPI:GetRoomShapePositions(v.Shape)) do
						pos = Vector(pos.X * roomSize.X, pos.Y * roomSize.Y)
						local actualRoomPixelSize = outlinePixelSize
						local brcutoff = v.RenderOffset + pos + actualRoomPixelSize - MinimapAPI:GetFrameBR()
						local tlcutoff = -(v.RenderOffset + pos)
						if brcutoff.X < actualRoomPixelSize.X and brcutoff.Y < actualRoomPixelSize.Y and 
						tlcutoff.X < actualRoomPixelSize.X and tlcutoff.Y < actualRoomPixelSize.Y then
							brcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
							tlcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
							minimapsmall:SetFrame("RoomOutline", 1)
							minimapsmall:Render(offsetVec + v.RenderOffset + pos, tlcutoff, brcutoff)
						end
					end
				end
			end
		end
	
		local defaultRoomColor = Color(MinimapAPI.Config.DefaultRoomColorR, MinimapAPI.Config.DefaultRoomColorG, MinimapAPI.Config.DefaultRoomColorB, 1, 0, 0, 0)
		for i, v in pairs(MinimapAPI.Level) do
			local iscurrent = MinimapAPI:PlayerInRoom(v)
			local displayflags = v:GetDisplayFlags()
			local spr = minimapsmall
			if displayflags & 0x1 > 0 then
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
				local rms = MinimapAPI:GetRoomShapeGridSize(v.Shape)
				local actualRoomPixelSize = Vector(roomPixelSize.X * rms.X, roomPixelSize.Y * rms.Y) - roomAnimPivot
				local brcutoff = v.RenderOffset + actualRoomPixelSize - MinimapAPI:GetFrameBR()
				local tlcutoff = -v.RenderOffset
				if brcutoff.X < actualRoomPixelSize.X and brcutoff.Y < actualRoomPixelSize.Y and 
				tlcutoff.X < actualRoomPixelSize.X and tlcutoff.Y < actualRoomPixelSize.Y then
					brcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
					tlcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
					spr:SetFrame(anim, MinimapAPI:GetRoomShapeFrame(v.Shape))
					spr.Color = v.Color or defaultRoomColor
					spr:Render(offsetVec + v.RenderOffset, tlcutoff, brcutoff)
				end
			end
		end

		minimapsmall.Color = Color(1, 1, 1, 1, 0, 0, 0)

		if MinimapAPI.Config.ShowIcons then
			for i, v in pairs(MinimapAPI.Level) do
				local incurrent = MinimapAPI:PlayerInRoom(v) and not MinimapAPI.Config.ShowCurrentRoomItems
				local displayflags = v.DisplayFlags or 0
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
							local brcutoff = v.RenderOffset + iconlocOffset + iconPixelSize - MinimapAPI:GetFrameBR()
							local tlcutoff = frameTL - (v.RenderOffset + iconlocOffset)
							if brcutoff.X < iconPixelSize.X and brcutoff.Y < iconPixelSize.Y and 
							tlcutoff.X < iconPixelSize.X and tlcutoff.Y < iconPixelSize.Y then
								brcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
								tlcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
								spr:Render(offsetVec + iconlocOffset + v.RenderOffset, tlcutoff, brcutoff)
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

local function renderMinimapIcons()
	local gameLvl = Game():GetLevel()
	local curseIconPos = Vector( screen_size.X - MinimapAPI.Config.PositionX, MinimapAPI.Config.PositionY + 5)
	local bounds = MinimapAPI:GetDiscoveredBounds()
	
	if #bounds == 0 then return end
	
	if MinimapAPI:IsLarge() then curseIconPos= curseIconPos + Vector(- (bounds[2]-bounds[1])* largeRoomPixelSize.X, 0)
	elseif MinimapAPI.Config.DisplayMode == 1 then curseIconPos= curseIconPos + Vector( - (bounds[2]-bounds[1])*roomPixelSize.X, 0) 
	elseif MinimapAPI.Config.DisplayMode == 2 then curseIconPos= curseIconPos + Vector( - MinimapAPI.Config.MapFrameWidth - 8, 0) end

	if true then
		local offset=Vector(0,0)
		if gameLvl:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) then 
			minimapicons:SetFrame("icons", 2)
			minimapicons:Render(curseIconPos+offset, zvec, zvec)
			offset=offset+Vector(0,16)
		end
		if gameLvl:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) then 
			minimapicons:SetFrame("icons", 1)
			minimapicons:Render(curseIconPos+offset, zvec, zvec)
			offset=offset+Vector(0,16)
		end
		if gameLvl:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) then 
			minimapicons:SetFrame("icons", 0)
			minimapicons:Render(curseIconPos+offset, zvec, zvec)
		end
	end
end

MinimapAPI.DisableSpelunkerHat = false
MinimapAPI:AddCallback( ModCallbacks.MC_POST_RENDER, function(self)
	if MinimapAPI.Config.Disable then return end
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
		local player = Isaac.GetPlayer(0)
		local hasSpelunkerHat = player:HasCollectible(CollectibleType.COLLECTIBLE_SPELUNKER_HAT) and not MinimapAPI.DisableSpelunkerHat
		if currentroomdata and MinimapAPI:PickupDetectionEnabled() then
			if not currentroomdata.NoUpdate then
				currentroomdata.ItemIcons = MinimapAPI:GetCurrentRoomPickupIDs()
				currentroomdata.DisplayFlags = 5
				currentroomdata.Clear = gamelevel:GetCurrentRoomDesc().Clear
				currentroomdata.Visited = true
			end
			for _,adjroom in ipairs(currentroomdata:GetAdjacentRooms()) do
				if not adjroom.NoUpdate then
					adjroom.DisplayFlags = adjroom.DisplayFlags | (hasSpelunkerHat and 5 or adjroom.AdjacentDisplayFlags)
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
			end
			if MinimapAPI.Config.ShowLevelFlags then
				renderMinimapIcons()
			end
		end
	end
end)

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
					ID = v.ID,
					Shape = v.Shape,
					ItemIcons = v.ItemIcons,
					PermanentIcons = v.PermanentIcons,
					LockedIcons = v.LockedIcons,
					Descriptor = v.DescriptorListIndex and vanillarooms:Get(v.DescriptorListIndex),
					DisplayFlags = v.DisplayFlags,
					Clear = v.Clear,
					Color = v.Color and Color(v.Color.R, v.Color.G, v.Color.B, v.Color.A, v.Color.RO, v.Color.GO, v.Color.BO),
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
			}
		end
	end
	return saved
end

-- LOADING SAVED GAME
MinimapAPI:AddCallback(
	ModCallbacks.MC_POST_GAME_STARTED,
	function(self, is_save)
		if MinimapAPI:HasData() then
			if not MinimapAPI.DisableSaving then
				local saved = json.decode(Isaac.LoadModData(MinimapAPI))
				MinimapAPI:LoadSaveTable(saved,is_save)
			else
				MinimapAPI:LoadDefaultMap()
			end
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

