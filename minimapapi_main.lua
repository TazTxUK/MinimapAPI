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

function MinimapAPI:SetVanillaBehavior(bool)
	disableVanillaBehavior=bool
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
	return r
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
local roomcount
local roommapdata = {}
local currentroom
local playerMapPos = Vector(0, 0)
local frozenPlayerPos
local disableVanillaBehavior = false


local mapdisplaylarge = false
local mapheldframes = 0

local callbacks_playerpos = {}
local custom_playerpos = false
local disabled_itemdet = false

local override_greed = true
local override_void = true

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
local largeIconPixelSize = Vector(16, 16)
local largeOutlinePixelSize = Vector(32, 32)
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

function MinimapAPI:GetLevel()
	return roommapdata
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
	local newRoom={}
	if type(id) == "table" and iconid == nil then
		local t = id
		if t.ID then
			MinimapAPI:RemovePickup(t.ID)
		end
		if type(t.Icon) == "table" then
			t.Icon = MinimapAPI:AddIcon(t.Icon.ID or t.ID, t.Icon.sprite, t.Icon.anim, t.Icon.frame, t.Icon.color).ID
		end
		newRoom = {
			ID = t.ID,
			IconID = t.Icon,
			Type = t.Type,
			Variant = t.Variant or -1,
			SubType = t.SubType or -1,
			Call = t.Call,
			IconGroup = t.IconGroup,
			Priority = t.Priority or defaultCustomPickupPriority
		}
	else
		if id then
			MinimapAPI:RemovePickup(id)
		end
		if type(iconid) == "table" then
			iconid = MinimapAPI:AddIcon(iconid.ID or id, iconid.sprite, iconid.anim, iconid.frame, iconid.color).ID
		end
		newRoom = {
			ID = id,
			IconID = iconid,
			Type = typ,
			Variant = variant or -1,
			SubType = subtype or -1,
			Call = call,
			IconGroup = icongroup,
			Priority = priority or defaultCustomPickupPriority
		}
	end
	MinimapAPI.PickupList[#MinimapAPI.PickupList + 1] = newRoom
	table.sort(MinimapAPI.PickupList, function(a, b) return a.Priority > b.Priority	end	)
	return newRoom
end

function MinimapAPI:RemovePickup(id)
	for i = #MinimapAPI.PickupList, 1, -1 do
		local v = MinimapAPI.PickupList[i]
		if v.ID == id then
			table.remove(MinimapAPI.PickupList, i)
		end
	end
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
	return mapheldframes > 7
end

function MinimapAPI:PlayerInRoom(roomdata)
	return playerMapPos.X == roomdata.Position.X and playerMapPos.Y == roomdata.Position.Y
end

function MinimapAPI:GetCurrentRoomPickupIDs() --gets pickup icon ids for current room ONLY
	local addIcons = {}
	local pickupgroupset = {}
	local entityset = {}
	local ents = Isaac.GetRoomEntities()
	for i, v in ipairs(MinimapAPI.PickupList) do
		if not pickupgroupset[v.IconGroup] then
			for _, ent in ipairs(ents) do
				if not entityset[GetPtrHash(ent)] then
					if ent.Type == v.Type then
						local toPickup = ent:ToPickup()
						if toPickup ~= nil then
							if toPickup:IsShopItem() then
								goto continue
							end
						end
						if v.Variant == -1 or ent.Variant == v.Variant then
							if v.SubType == -1 or ent.SubType == v.SubType then
								if (not v.Call) or v.Call(ent) then
									if v.IconGroup then
										pickupgroupset[v.IconGroup] = true
									end
									table.insert(addIcons, v.IconID)
									entityset[GetPtrHash(ent)] = true
									break
								end
							end
						end
					end
					::continue::
				end
			end
		end
	end
	return addIcons
end

function MinimapAPI:RunPlayerPosCallbacks()
	for i, v in ipairs(callbacks_playerpos) do
		local s, ret = pcall(v.call, MinimapAPI:GetCurrentRoom(), playerMapPos)
		if s then
			if ret then
				custom_playerpos = true
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
	roommapdata = {}
	local treasure_room_count = 0
	for i = 0, #rooms - 1 do
		local v = rooms:Get(i)
		local t = {
			Shape = v.Data.Shape,
			PermanentIcons = {MinimapAPI:GetRoomTypeIconID(v.Data.Type)},
			LockedIcons = {MinimapAPI:GetUnknownRoomTypeIconID(v.Data.Type)},
			ItemIcons = {},
			Position = MinimapAPI:GridIndexToVector(v.GridIndex),
			Descriptor = v
		}
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
end

function MinimapAPI:ClearMap()
	roommapdata = {}
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
	GetDisplayFlags = function(self)
		return self.DisplayFlags or 0
	end,
	IsClear = function(self)
		return self.Clear or false
	end
}

local maproommeta = {
	__index = function(self, key)
		local desc = rawget(self, "Descriptor")
		if desc and desc[key] then
			return desc[key]
		end
		return maproomfunctions[key]
	end
}

function MinimapAPI:AddRoom(t)
	assert(type(t) == "table", "bad argument #1 to 'AddRoom', expected table")
	local defaultPosition = Vector(12, -1)
	if not t.AllowRoomOverlap then
		MinimapAPI:RemoveRoom(t.Position or defaultPosition)
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
		DisplayFlags = t.DisplayFlags or nil,
		Clear = t.Clear or nil
	}
	setmetatable(x, maproommeta)
	roommapdata[#roommapdata + 1] = x
	return x
end

function MinimapAPI:RemoveRoom(pos)
	assert(MinimapAPI:InstanceOf(pos, Vector), "bad argument #1 to 'RemoveRoom', expected Vector")
	local success = false
	for i, v in ipairs(roommapdata) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			table.remove(roommapdata, i)
			success = true
			break
		end
	end
	return success
end

function MinimapAPI:RemoveRoomByID(id)
	for i = #roommapdata, 1, -1 do
		local v = roommapdata[i]
		if v.ID == id then
			table.remove(roommapdata, i)
		end
	end
end

function MinimapAPI:GetRoom(pos)
	assert(MinimapAPI:InstanceOf(pos, Vector), "bad argument #1 to 'GetRoom', expected Vector")
	local success
	for i, v in ipairs(roommapdata) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			success = v
			break
		end
	end
	return success
end

function MinimapAPI:GetRoomByID(ID)
	for i, v in ipairs(roommapdata) do
		if v.ID == ID then
			return v
		end
	end
end

function MinimapAPI:GetPlayerPosition()
	return Vector(playerMapPos.X, playerMapPos.Y)
end

function MinimapAPI:UpdateMinimapCenterOffset(force)
	local currentroom = MinimapAPI:GetCurrentRoom()
	if currentroom and currentroom.Data then
		roomCenterOffset = playerMapPos + MinimapAPI:GetRoomShapeGridSize(currentroom.Data.Shape) / 2
	elseif force then
		roomCenterOffset = playerMapPos + Vector(0.5, 0.5)
	end
end

function MinimapAPI:SetPlayerPosition(position)
	playerMapPos = Vector(position.X, position.Y)
	custom_playerpos = true
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
	if currentroom then
		playerMapPos = MinimapAPI:GridIndexToVector(currentroom.GridIndex)
		custom_playerpos = false
		MinimapAPI:RunPlayerPosCallbacks()
	end
end

MinimapAPI:AddCallback(	ModCallbacks.MC_POST_NEW_LEVEL,	function(self)
	if disableVanillaBehavior then return end
	MinimapAPI:LoadDefaultMap()
	updatePlayerPos()
end)

function MinimapAPI:UpdateUnboundedMapOffset()
	local maxx
	local miny
	for i = 1, #(roommapdata) do
		local v = roommapdata[i]
		if (v.DisplayFlags or 0) > 0 then
			local maxxval = v.Position.X + MinimapAPI:GetRoomShapeGridSize(v.Shape).X
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
	if disableVanillaBehavior then return end
	updatePlayerPos()
end)

MinimapAPI:AddCallback( ModCallbacks.MC_POST_UPDATE, function(self)
	if Input.IsActionPressed(ButtonAction.ACTION_MAP, 0) then
		mapheldframes = mapheldframes + 1
	elseif mapheldframes > 0 then
		if mapheldframes < 8 then
			MinimapAPI.Config.DisplayMode = MinimapAPI.Config.DisplayMode + 1
			if MinimapAPI.Config.DisplayMode > 2 then
				MinimapAPI.Config.DisplayMode = 1
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
	for i = 1, #(roommapdata) do
		local v = roommapdata[i]
		if (v.DisplayFlags or 0) > 0 then
			local minxval = v.Position.X
			if not minx or (minxval < minx) then minx = minxval	end
			local maxxval = v.Position.X + MinimapAPI:GetRoomShapeGridSize(v.Shape).X
			if not maxx or (maxxval > maxx) then maxx = maxxval	end
			
			local minyval = v.Position.Y
			if not miny or (minyval < miny) then miny = minyval	end
			local maxyval = v.Position.Y + MinimapAPI:GetRoomShapeGridSize(v.Shape).Y
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

		--local renderOutlinePixelSize = size=="small" and outlinePixelSize or largeOutlinePixelSize        -- unused
		for i, v in ipairs(roommapdata) do
			local roomOffset = v.Position + unboundedMapOffset
			roomOffset.X = roomOffset.X * renderRoomSize.X
			roomOffset.Y = roomOffset.Y * renderRoomSize.Y
			v.TargetRenderOffset = roomOffset + renderAnimPivot
			if v.RenderOffset then
				v.RenderOffset = v.TargetRenderOffset * MinimapAPI.Config.SmoothSlidingSpeed + v.RenderOffset * (1 - MinimapAPI.Config.SmoothSlidingSpeed)
			else
				v.RenderOffset = v.TargetRenderOffset
			end
		end

		if MinimapAPI.Config.ShowShadows then
			for i, v in pairs(roommapdata) do
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

		for i, v in pairs(roommapdata) do
			local iscurrent = MinimapAPI:PlayerInRoom(v)
			local displayflags = v:GetDisplayFlags()
			if displayflags & 0x1 > 0 then
				local anim
				if iscurrent then
					anim = "RoomCurrent"
				elseif v:IsClear() then
					anim = "RoomVisited"
				else
					anim = "RoomUnvisited"
				end
				sprite:SetFrame(anim, MinimapAPI:GetRoomShapeFrame(v.Shape))
				sprite.Color = v.Color or Color(1, 1, 1, 1, 0, 0, 0)
				sprite:Render(offsetVec + v.RenderOffset, zvec, zvec)
			end
		end

		sprite.Color = Color(1, 1, 1, 1, 0, 0, 0)

		if MinimapAPI.Config.ShowIcons then
			for i, v in pairs(roommapdata) do
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
					if not incurrent then
						iconcount = iconcount + #v.ItemIcons
					end

					local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, iconcount)
					if size ~= "small" then
						locs = MinimapAPI:GetLargeRoomShapeIconPositions(v.Shape, iconcount)
					end
					
					renderIcons(v.PermanentIcons, locs)
					if not incurrent then
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
	
		for i, v in ipairs(roommapdata) do
			local roomOffset = v.Position - roomCenterOffset
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
			for i, v in pairs(roommapdata) do
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

		for i, v in pairs(roommapdata) do
			local iscurrent = MinimapAPI:PlayerInRoom(v)
			local displayflags = v:GetDisplayFlags()
			if displayflags & 0x1 > 0 then
				local anim
				if iscurrent then
					anim = "RoomCurrent"
				elseif v:IsClear() then
					anim = "RoomVisited"
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
					minimapsmall:SetFrame(anim, MinimapAPI:GetRoomShapeFrame(v.Shape))
					minimapsmall.Color = v.Color or Color(1, 1, 1, 1, 0, 0, 0)
					minimapsmall:Render(offsetVec + v.RenderOffset, tlcutoff, brcutoff)
				end
			end
		end

		minimapsmall.Color = Color(1, 1, 1, 1, 0, 0, 0)

		if MinimapAPI.Config.ShowIcons then
			for i, v in pairs(roommapdata) do
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
					if not incurrent then
						iconcount = iconcount + #v.ItemIcons
					end

					local locs = MinimapAPI:GetRoomShapeIconPositions(v.Shape, iconcount)

					renderIcons(v.PermanentIcons, locs)
					if not incurrent then
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
	
	if MinimapAPI:IsLarge() then curseIconPos= curseIconPos + Vector(- (bounds[2]-bounds[1])* largeRoomPixelSize.X, 0) 
	elseif MinimapAPI.Config.DisplayMode == 1 then curseIconPos= curseIconPos + Vector( - (bounds[2]-bounds[1])*roomPixelSize.X, 0) 
	elseif MinimapAPI.Config.DisplayMode == 2 then curseIconPos= curseIconPos +Vector( - MinimapAPI.Config.MapFrameWidth - 8, 0) end

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
			if currentroomdata and MinimapAPI:PickupDetectionEnabled() then
				currentroomdata.ItemIcons = MinimapAPI:GetCurrentRoomPickupIDs()
			end

			if roommapdata then
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
	end
)

if ModConfigMenu then
	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.Disable
			end,
			Display = function()
				return "Disable Minimap: " .. (MinimapAPI.Config.Disable and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.Disable = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.OverrideLost
			end,
			Display = function()
				return "Display During Curse: " .. (MinimapAPI.Config.OverrideLost and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.OverrideLost = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayOnNoHUD
			end,
			Display = function()
				return "Display with No HUD Seed: " .. (MinimapAPI.Config.DisplayOnNoHUD and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.DisplayOnNoHUD = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowIcons
			end,
			Display = function()
				return "Show Icons: " .. (MinimapAPI.Config.ShowIcons and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowIcons = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowShadows
			end,
			Display = function()
				return "Show Shadows: " .. (MinimapAPI.Config.ShowShadows and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowShadows = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowLevelFlags
			end,
			Display = function()
				return "Show Level Flags: " .. (MinimapAPI.Config.ShowLevelFlags and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowLevelFlags = currentBool
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowCurrentRoomItems
			end,
			Display = function()
				return "Show Current Room Items: " .. (MinimapAPI.Config.ShowCurrentRoomItems and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowCurrentRoomItems = currentBool
			end
		}
	)
	
	local hicstrings = {"Never","Bosses Only","Always"}
	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.NUMBER,
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
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayMode
			end,
			Minimum = 1,
			Maximum = 2,
			Display = function()
				return "Display Mode: " ..
					({
						"Borderless",
						"Bordered"
					})[MinimapAPI.Config.DisplayMode]
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.DisplayMode = currentNum
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.MapFrameWidth
			end,
			Minimum = 10,
			Maximum = 100,
			ModifyBy = 5,
			Display = function()
				return "Border Width: " .. MinimapAPI.Config.MapFrameWidth
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.MapFrameWidth = currentNum
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.MapFrameHeight
			end,
			Minimum = 10,
			Maximum = 100,
			ModifyBy = 5,
			Display = function()
				return "Border Height: " .. MinimapAPI.Config.MapFrameHeight
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.MapFrameHeight = currentNum
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.PositionX
			end,
			Minimum = 0,
			Maximum = 40,
			ModifyBy = 2,
			Display = function()
				return "Position X: " .. MinimapAPI.Config.PositionX
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.PositionX = currentNum
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.PositionY
			end,
			Minimum = 0,
			Maximum = 40,
			ModifyBy = 2,
			Display = function()
				return "Position Y: " .. MinimapAPI.Config.PositionY
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.PositionY = currentNum
			end
		}
	)

	ModConfigMenu.AddSetting(
		"Minimap API",
		"Visual",
		{
			Type = ModConfigMenuOptionType.NUMBER,
			CurrentSetting = function()
				return MinimapAPI.Config.SmoothSlidingSpeed
			end,
			Minimum = 0.25,
			Maximum = 1,
			ModifyBy = 0.25,
			Display = function()
				return "Smooth Movement Speed: " .. MinimapAPI.Config.SmoothSlidingSpeed
			end,
			OnChange = function(currentNum)
				MinimapAPI.Config.SmoothSlidingSpeed = currentNum
			end
		}
	)
end

-- LOADING SAVED GAME
MinimapAPI:AddCallback(
	ModCallbacks.MC_POST_GAME_STARTED,
	function(self, is_save)
		if MinimapAPI:HasData() then
			local saved = json.decode(Isaac.LoadModData(MinimapAPI))
			for i,v in pairs(saved.Config) do
				MinimapAPI.Config[i] = v
			end
			if is_save then
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
						Color = v.Color and Color(v.Color.R, v.Color.G, v.Color.B, v.Color.A, v.Color.RO, v.Color.GO, v.Color.BO)
					}
				end
			end
		end
	end
)

-- SAVING GAME
MinimapAPI:AddCallback(
	ModCallbacks.MC_PRE_GAME_EXIT,
	function()
		local saved = {}
		saved.Config = MinimapAPI.Config
		saved.LevelData = {}
		for i, v in ipairs(roommapdata) do
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
				Color = v.Color and {R = v.Color.R, G = v.Color.G, B = v.Color.B, A = v.Color.A, RO = v.Color.RO, GO = v.Color.GO, BO = v.Color.BO}
			}
		end
		MinimapAPI:SaveData(json.encode(saved))
	end
)

require("minimapapi_scripts")
Isaac.ConsoleOutput("Minimap API loaded!\n")
