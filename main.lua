MinimapAPI = RegisterMod("Minimap API",1)

local json = require("json")
require("minimapapi_data")
require("minimapapi_config")

function MinimapAPI.GetScreenSize()
	return (Isaac.WorldToScreen(Vector(320,280)) - Game():GetRoom():GetRenderScrollOffset() - Game().ScreenShakeOffset)*2
end	

function MinimapAPI.GetRoomShapeFrame(rs)
	return MinimapAPI.RoomShapeFrames[rs]
end

function MinimapAPI.GetRoomShapeGridSize(rs)
	return MinimapAPI.RoomShapeGridSizes[rs]
end

function MinimapAPI.GetRoomShapePositions(rs)
	return MinimapAPI.RoomShapePositions[rs]
end

function MinimapAPI.GetRoomTypeIconID(t)
	return MinimapAPI.RoomTypeIconIDs[t]
end

function MinimapAPI.GetUnknownRoomTypeIconID(t)
	return MinimapAPI.UnknownRoomTypeIconIDs[t]
end

function MinimapAPI.GetRoomShapeIconPositions(rs,iconcount)
	iconcount = iconcount or math.huge
	local r
	if iconcount <= 1 then
		r = MinimapAPI.RoomShapeIconPositions[1][rs]
	else
		r = MinimapAPI.RoomShapeIconPositions[2][rs]
	end
	return r
end

function MinimapAPI.GetLargeRoomShapeIconPositions(rs, iconcount)
	iconcount = iconcount or math.huge
	if iconcount <= 1 then
		return MinimapAPI.LargeRoomShapeIconPositions[1][rs]
	else
		return MinimapAPI.LargeRoomShapeIconPositions[2][rs]
	end
	return r
end

function MinimapAPI.GridIndexToVector(grid_index)
	return Vector(grid_index % 13, math.floor(grid_index/13))
end

function MinimapAPI.GridVectorToIndex(v)
	return v.Y * 13 + v.X
end

function MinimapAPI.GetFrameBR()
	return Vector(MinimapAPI.Config.MapFrameWidth, MinimapAPI.Config.MapFrameHeight)
end

function MinimapAPI.GetFrameCenterOffset()
	return Vector(MinimapAPI.Config.MapFrameWidth + 1, MinimapAPI.Config.MapFrameHeight + 1)/2
end

--minimap api
local rooms
local roomcount
local roommapdata = {}
local currentroom
local playerMapPos = Vector(0,0)

local mapdisplaylarge = false
local mapheldframes = 0

local callbacks_playerpos = {}
local custom_playerpos = false
local disabled_itemdet = false

local override_greed = true
local override_void = true

--draw
local roomCenterOffset = Vector(0,0)
local roomAnimPivot = Vector(-2,-2)
local frameTL = Vector(2,2)
local screen_size = Vector(0,0)

local roomSize = Vector(8,7)
local roomPixelSize = Vector(9,8)
local iconPixelSize = Vector(16,16)
local outlinePixelSize = Vector(16,16)

local largeRoomAnimPivot = Vector(-4,-4)
local largeRoomSize = Vector(17,15)
local largeRoomPixelSize = Vector(18,16)
local largeIconPixelSize = Vector(16,16)
local largeOutlinePixelSize = Vector(32,32)
local unboundedMapOffset = Vector(0,0)
local largeIconOffset = Vector(-2,-2)

local dframeHorizBarSize = Vector(53,2)
local dframeVertBarSize = Vector(2,47)
local dframeCenterSize = Vector(49,43)

local zvec = Vector(0,0)

local minimapsmall = Sprite()
minimapsmall:Load("gfx/ui/minimapapi_minimap1.anm2",true)
local minimaplarge = Sprite()
minimaplarge:Load("gfx/ui/minimapapi_minimap2.anm2",true)
local minimapicons = Sprite()
minimapicons:Load("gfx/ui/minimapapi_mapitemicons.anm2",true)

function MinimapAPI.GetLevel()
	return roommapdata
end

function MinimapAPI.ShallowCopy(t)
	local t2 = {}
	for i,v in pairs(t) do
		t2[i] = v
	end
	return t2
end

function MinimapAPI.DeepCopy(t)
	local t2 = {}
	for i,v in pairs(t) do
		if type(v) == "table" then
			t2[i] = MinimapAPI.DeepCopy(v)
		else
			t2[i] = v
		end
	end
	return t2
end

function MinimapAPI.GetIconAnimData(id)
	for i,v in ipairs(MinimapAPI.IconList) do
		if v.ID == id then
			return {sprite=v.sprite or minimapsmall, anim=v.anim, frame=v.frame or 0}
		end
	end
end

function MinimapAPI.GetSprite()
	return minimapsmall
end

function MinimapAPI.GetSpriteLarge()
	return minimaplarge
end

function MinimapAPI.AddCustomPickupIcon(id, iconid, typ, variant, subtype, call, icongroup, priority)
	MinimapAPI.RemoveCustomPickupIcon(id)
	MinimapAPI.PickupList[#MinimapAPI.PickupList + 1] = {
		ID = id,
		IconID = iconid,
		Type = typ,
		Variant = variant or -1,
		SubType = subtype or -1,
		Call = call,
		IconGroup = icongroup,
		Priority = priority or math.huge,
	}
	table.sort(MinimapAPI.PickupList, function(a,b) return a.Priority > b.Priority end)
end

function MinimapAPI.RemoveCustomPickupIcon(id)
	for i=#MinimapAPI.PickupList,1,-1 do
		local v = MinimapAPI.PickupList[i]
		if v.ID == id then
			table.remove(MinimapAPI.PickupList,i)
		end
	end
end

function MinimapAPI.PickupDetectionEnabled()
	return not disabled_itemdet
end

function MinimapAPI.DisablePickupDetection()
	disabled_itemdet = true
end

function MinimapAPI.EnablePickupDetection()
	disabled_itemdet = false
end

function MinimapAPI.IsLarge()
	return mapheldframes > 7
end

function MinimapAPI.PlayerInRoom(roomdata)
	return playerMapPos.X == roomdata.Position.X and playerMapPos.Y == roomdata.Position.Y
end

function MinimapAPI.GetCurrentRoomPickupIDs() --gets pickup icon ids for current room ONLY
	local addIcons = {}
	local pickupgroupset = {}
	local ents = Isaac.GetRoomEntities()
	for i,v in ipairs(MinimapAPI.PickupList) do
		if not pickupgroupset[v.IconGroup] then
			for _,ent in ipairs(ents) do
				if ent.Type == v.Type then
					if v.Variant == -1 or ent.Variant == v.Variant then
						if v.SubType == -1 or ent.SubType == v.SubType then
							if (not v.Call) or v.Call(ent) then
								if v.IconGroup then
									pickupgroupset[v.IconGroup] = true
								end
								table.insert(addIcons, v.IconID)
							end
						end
					end
				end
			end
		end
	end
	return addIcons
end

function MinimapAPI.RunPlayerPosCallbacks()
	for i,v in ipairs( callbacks_playerpos ) do
		local s,ret = pcall(v.call, MinimapAPI.GetCurrentRoom(), playerMapPos)
		if s then
			if ret then
				custom_playerpos = true
				playerMapPos = ret
				return ret
			end
		else
			Isaac.ConsoleOutput("Error in MinimapAPI PlayerPos Callback:\n"..tostring(ret).."\n")
		end
	end
end

function MinimapAPI.GetDisplayFlags(roomdata)
	return roomdata.DisplayFlags or 0
end

function MinimapAPI.GetClear(roomdata)
	return roomdata.Clear or false
end

function MinimapAPI.InstanceOf(obj,class)
	local meta = getmetatable(obj)
	local metaclass = getmetatable(class)
	if metaclass then
		local c = metaclass.__class
		return c == meta
	else
		return false
	end
end

function MinimapAPI.LoadDefaultMap()
	rooms = Game():GetLevel():GetRooms()
	roommapdata = {}
	local treasure_room_count = 0
	local isGreed = Game().Difficulty == 2 or Game().Difficulty == 3
	for i=0,#rooms-1 do
		local v = rooms:Get(i)
		local t = {
			Shape = v.Data.Shape,
			PermanentIcons = {MinimapAPI.GetRoomTypeIconID(v.Data.Type)},
			LockedIcons = {MinimapAPI.GetUnknownRoomTypeIconID(v.Data.Type)},
			ItemIcons = {},
			Position = MinimapAPI.GridIndexToVector(v.GridIndex),
			Descriptor = v,
		}
		if override_greed and isGreed then
			if v.Data.Type == RoomType.ROOM_TREASURE then
				treasure_room_count = treasure_room_count + 1
				if treasure_room_count == 1 then
					t.PermanentIcons = {{anim="IconTreasureRoomGreed"}}
				end
			end
		end
		MinimapAPI.AddRoom(t)
	end
end

function MinimapAPI.ClearMap()
	roommapdata = {}
end

local maproommeta = {
	__index = function(self, key)
		local desc = rawget(self,"Descriptor")
		if desc then
			return desc[key]
		end
	end,
}

function MinimapAPI.AddRoom(t)
	assert(type(t)=="table","bad argument #1 to 'AddRoom', expected table")
	local defaultPosition = Vector(12,-1)
	if not t.AllowRoomOverlap then
		MinimapAPI.RemoveRoom(t.Position or defaultPosition)
	end
	local x = {
		Position = t.Position or defaultPosition,
		ID = t.ID,
		Shape = t.Shape or RoomShape.ROOMSHAPE_1x1,
		PermanentIcons = t.PermanentIcons or {},
		LockedIcons = t.LockedIcons or {},
		ItemIcons = t.ItemIcons or {},
		Descriptor = t.Descriptor or nil,
		RenderOffset = Vector(0,0),
		
		DisplayFlags = t.DisplayFlags or nil,
		Clear = t.Clear or nil,
	}
	setmetatable(x,maproommeta)
	roommapdata[#roommapdata + 1] = x
	return x
end

function MinimapAPI.RemoveRoom(pos)
	assert(MinimapAPI.InstanceOf(pos,Vector),"bad argument #1 to 'RemoveRoom', expected Vector")
	local success = false
	for i,v in ipairs(roommapdata) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			table.remove(roommapdata, i)
			success = true
			break
		end
	end
	return success
end

function MinimapAPI.GetRoom(pos)
	assert(MinimapAPI.InstanceOf(pos,Vector),"bad argument #1 to 'GetRoom', expected Vector")
	local success
	for i,v in ipairs(roommapdata) do
		if v.Position.X == pos.X and v.Position.Y == pos.Y then
			success = v
			break
		end
	end
	return success
end

function MinimapAPI.GetPlayerPosition()
	return Vector(playerMapPos.X, playerMapPos.Y)
end

function MinimapAPI.UpdateMinimapCenterOffset()
	local currentroom = MinimapAPI.GetCurrentRoom()
	if currentroom and currentroom.Data then
		roomCenterOffset = playerMapPos + MinimapAPI.GetRoomShapeGridSize(currentroom.Data.Shape)/2	
	else
		roomCenterOffset = playerMapPos + Vector(0.5,0.5)
	end
end

function MinimapAPI.SetPlayerPosition(position)
	playerMapPos = Vector(position.X, position.Y)
	MinimapAPI.UpdateMinimapCenterOffset()
	custom_playerpos = true
end

function MinimapAPI.IsModTable(modtable)
	if type(modtable) == "table" and modtable.Name and modtable.AddCallback then
		return true
	end
	return false
end

function MinimapAPI.AddPlayerPositionCallback(modtable,func)
	if not MinimapAPI.IsModTable(modtable) then
		error("Table given to AddPlayerPositionCallback was not a mod table")
	end
	MinimapAPI.RemovePlayerPositionCallback(modtable)
	callbacks_playerpos[#callbacks_playerpos + 1] = {
		mod = modtable,
		call = func
	}
end

function MinimapAPI.RemovePlayerPositionCallback(modtable)
	for i,v in ipairs(callbacks_playerpos) do
		if v.mod == modtable then
			table.remove(callbacks_playerpos,i)
			break
		end
	end
end

function MinimapAPI.GetCurrentRoom() --DOESNT ALWAYS RETURN SOMETHING!!!
	return MinimapAPI.GetRoom(MinimapAPI.GetPlayerPosition())
end

MinimapAPI:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function(self)
	MinimapAPI.LoadDefaultMap()
	MinimapAPI.UpdateUnboundedMapOffset()
end)

function MinimapAPI.UpdateUnboundedMapOffset()
	local maxx
	local miny
	for i=1,#(roommapdata) do
		local v = roommapdata[i]
		if (v.DisplayFlags or 0) > 0 then
			local maxxval = v.Position.X + MinimapAPI.GetRoomShapeGridSize(v.Shape).X
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
		unboundedMapOffset = Vector(-maxx,-miny)
	end
end

MinimapAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(self)
	local currentroom = Game():GetLevel():GetCurrentRoomDesc()
	if currentroom then
		playerMapPos = MinimapAPI.GridIndexToVector(currentroom.GridIndex)
		custom_playerpos = false
		MinimapAPI.RunPlayerPosCallbacks()
		MinimapAPI.UpdateMinimapCenterOffset()
	end
end)

MinimapAPI:AddCallback(ModCallbacks.MC_POST_UPDATE, function(self)
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

local function renderHugeMinimap()
	if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0 then
		MinimapAPI.UpdateUnboundedMapOffset() --taz's note to himself: has to be updated per frame!
		local offsetVec = Vector(screen_size.X - 4, 4)
		for i,v in ipairs(roommapdata) do
			local roomOffset = v.Position + unboundedMapOffset
			roomOffset.X = roomOffset.X * largeRoomSize.X --Vector(v.Position.X * largeRoomSize.X,v.Position.Y * largeRoomSize.Y)
			roomOffset.Y = roomOffset.Y * largeRoomSize.Y 
			v.RenderOffset = roomOffset + largeRoomAnimPivot
		end
		
		if MinimapAPI.Config.ShowShadows then
			for i,v in pairs(roommapdata) do
				local displayflags = MinimapAPI.GetDisplayFlags(v)
				if displayflags > 0 then
					for n,pos in ipairs(MinimapAPI.GetRoomShapePositions(v.Shape)) do
						pos = Vector(pos.X * largeRoomSize.X, pos.Y * largeRoomSize.Y)
						local actualRoomPixelSize = largeOutlinePixelSize
						minimaplarge:SetFrame("RoomOutline",1)
						minimaplarge:Render(offsetVec + v.RenderOffset + pos,zvec,zvec)
					end
				end
			end
		end
		
		for i,v in pairs(roommapdata) do
			local iscurrent = MinimapAPI.PlayerInRoom(v)
			local displayflags = MinimapAPI.GetDisplayFlags(v)
			if displayflags & 0x1 > 0 then
				local anim
				if iscurrent then
					anim = "RoomCurrent"
				elseif MinimapAPI.GetClear(v) then
					anim = "RoomVisited"
				else
					anim = "RoomUnvisited"
				end
				minimaplarge:SetFrame(anim,MinimapAPI.GetRoomShapeFrame(v.Shape))
				minimaplarge:Render(offsetVec + v.RenderOffset,zvec,zvec)
			end
		end
		
		if MinimapAPI.Config.ShowIcons then
			for i,v in pairs(roommapdata) do
				local incurrent = MinimapAPI.PlayerInRoom(v)
				local displayflags = MinimapAPI.GetDisplayFlags(v)
				local k = 1
				local function renderIcon(icon,locs)
					local loc = locs[k]
					if not loc then return end
					
					local iconlocOffset = Vector(loc.X * largeRoomPixelSize.X, loc.Y * largeRoomPixelSize.Y)
					local spr = icon.sprite or minimapsmall
					spr:SetFrame(icon.anim,icon.frame)
					spr:Render(offsetVec + iconlocOffset + v.RenderOffset - largeRoomAnimPivot + largeIconOffset,zvec,zvec)
					k = k + 1
				end
				
				if displayflags & 0x4 > 0 then
					local iconcount = #v.PermanentIcons
					if not incurrent then
						iconcount = iconcount + #v.ItemIcons
					end
					
					local locs = MinimapAPI.GetLargeRoomShapeIconPositions(v.Shape, iconcount)
					
					for _,icon in ipairs(v.PermanentIcons) do
						renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
					end
					if not incurrent then
						for _,id in ipairs(v.ItemIcons) do
							renderIcon(MinimapAPI.GetIconAnimData(id),locs)
						end
					end
				elseif displayflags & 0x2 > 0 then
					if v.LockedIcons and #v.LockedIcons > 0 then
						local locs = MinimapAPI.GetLargeRoomShapeIconPositions(v.Shape, #v.LockedIcons)
						for _,icon in ipairs(v.LockedIcons) do
							renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
						end
					end
				end
			end
		end
	end
end

local function renderUnboundedMinimap()
	if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0 then
		MinimapAPI.UpdateUnboundedMapOffset()
		local offsetVec = Vector(screen_size.X - MinimapAPI.Config.PositionX, MinimapAPI.Config.PositionY)
	
		for i,v in ipairs(roommapdata) do
			local roomOffset = v.Position + unboundedMapOffset
			roomOffset.X = roomOffset.X * roomSize.X 
			roomOffset.Y = roomOffset.Y * roomSize.Y 
			v.RenderOffset = roomOffset + roomAnimPivot
		end
		
		if MinimapAPI.Config.ShowShadows then
			for i,v in pairs(roommapdata) do
				local displayflags = MinimapAPI.GetDisplayFlags(v)
				if displayflags > 0 then
					for n,pos in ipairs(MinimapAPI.GetRoomShapePositions(v.Shape)) do
						pos = Vector(pos.X * roomSize.X, pos.Y * roomSize.Y)
						local actualRoomPixelSize = outlinePixelSize
						minimapsmall:SetFrame("RoomOutline",1)
						minimapsmall:Render(offsetVec + v.RenderOffset + pos,zvec,zvec)
					end
				end
			end
		end
		
		for i,v in pairs(roommapdata) do
			local iscurrent = MinimapAPI.PlayerInRoom(v)
			local displayflags = MinimapAPI.GetDisplayFlags(v)
			if displayflags & 0x1 > 0 then
				local anim
				if iscurrent then
					anim = "RoomCurrent"
				elseif MinimapAPI.GetClear(v) then
					anim = "RoomVisited"
				else
					anim = "RoomUnvisited"
				end
				minimapsmall:SetFrame(anim,MinimapAPI.GetRoomShapeFrame(v.Shape))
				minimapsmall:Render(offsetVec + v.RenderOffset,zvec,zvec)
			end
		end
		
		if MinimapAPI.Config.ShowIcons then
			for i,v in pairs(roommapdata) do
				local incurrent = MinimapAPI.PlayerInRoom(v)
				local displayflags = MinimapAPI.GetDisplayFlags(v)
				local k = 1
				local function renderIcon(icon,locs)
					local loc = locs[k]
					if not loc then return end
					
					local iconlocOffset = Vector(loc.X * roomSize.X, loc.Y * roomSize.Y)
					local spr = icon.sprite or minimapsmall
					spr:SetFrame(icon.anim,icon.frame)
					spr:Render(offsetVec + iconlocOffset + v.RenderOffset,zvec,zvec)
					k = k + 1
				end
				
				if displayflags & 0x4 > 0 then
					local iconcount = #v.PermanentIcons
					if not incurrent then
						iconcount = iconcount + #v.ItemIcons
					end
					
					local locs = MinimapAPI.GetRoomShapeIconPositions(v.Shape, iconcount)
					
					for _,icon in ipairs(v.PermanentIcons) do
						renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
					end
					if not incurrent then
						for _,icon in ipairs(v.ItemIcons) do
							renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
						end
					end
				elseif displayflags & 0x2 > 0 then
					if v.LockedIcons and #v.LockedIcons > 0 then
						local locs = MinimapAPI.GetRoomShapeIconPositions(v.Shape, #v.LockedIcons)
						for _,icon in ipairs(v.LockedIcons) do
							renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
						end
					end
				end
			end
		end
	end
end

local function renderBoundedMinimap()
	local offsetVec = Vector(screen_size.X - MinimapAPI.Config.MapFrameWidth - MinimapAPI.Config.PositionX - 1, MinimapAPI.Config.PositionY - 2.5)
	do
		local fw = 0
		while fw < MinimapAPI.Config.MapFrameWidth - dframeHorizBarSize.X do
			minimapsmall:SetFrame("MinimapAPIFrameN",0)
			minimapsmall:Render(offsetVec + Vector(fw, 0),zvec,zvec)
			minimapsmall:SetFrame("MinimapAPIFrameS",0)
			minimapsmall:Render(offsetVec + Vector(fw, MinimapAPI.Config.MapFrameHeight),zvec,zvec)
			fw = fw + dframeHorizBarSize.X
		end
		local horizcutoff = Vector(dframeHorizBarSize.X - (MinimapAPI.Config.MapFrameWidth - fw),0)
		minimapsmall:SetFrame("MinimapAPIFrameN",0)
		minimapsmall:Render(offsetVec + Vector(fw, 0),zvec,horizcutoff)
		minimapsmall:SetFrame("MinimapAPIFrameS",0)
		minimapsmall:Render(offsetVec + Vector(fw, MinimapAPI.Config.MapFrameHeight),zvec,horizcutoff)
		
		local fh = 0
		while fh < MinimapAPI.Config.MapFrameHeight - dframeVertBarSize.Y do
			minimapsmall:SetFrame("MinimapAPIFrameW",0)
			minimapsmall:Render(offsetVec + Vector(0, fh),zvec,zvec)
			minimapsmall:SetFrame("MinimapAPIFrameE",0)
			minimapsmall:Render(offsetVec + Vector(MinimapAPI.Config.MapFrameWidth, fh),zvec,zvec)
			fh = fh + dframeVertBarSize.Y
		end
		local vertcutoff = Vector(0,dframeVertBarSize.Y - (MinimapAPI.Config.MapFrameHeight - fh) - 2)
		minimapsmall:SetFrame("MinimapAPIFrameW",0)
		minimapsmall:Render(offsetVec + Vector(0, fh),zvec,vertcutoff)
		minimapsmall:SetFrame("MinimapAPIFrameE",0)
		minimapsmall:Render(offsetVec + Vector(MinimapAPI.Config.MapFrameWidth, fh),zvec,vertcutoff)
		
		fw = 0
		while fw < MinimapAPI.Config.MapFrameWidth do
			local cutoff = Vector(0,0)
			if fw > MinimapAPI.Config.MapFrameWidth - dframeCenterSize.X then
				cutoff.X = dframeCenterSize.X - (MinimapAPI.Config.MapFrameWidth - fw)
			end
			fh = 0
			while fh < MinimapAPI.Config.MapFrameHeight do
				if fh > MinimapAPI.Config.MapFrameHeight - dframeCenterSize.Y then
					cutoff.Y = dframeCenterSize.Y - (MinimapAPI.Config.MapFrameHeight - fh)
				end
				minimapsmall:SetFrame("MinimapAPIFrameCenter",0)
				minimapsmall:Render(offsetVec + Vector(fw, fh),zvec,cutoff)
				fh = fh + dframeCenterSize.Y
			end
			fw = fw + dframeCenterSize.X
		end
	end
	
	if MinimapAPI.Config.OverrideLost or Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_LOST <= 0 then
		for i,v in ipairs(roommapdata) do
			local roomOffset = v.Position - roomCenterOffset
			roomOffset.X = roomOffset.X * roomSize.X
			roomOffset.Y = roomOffset.Y * roomSize.Y
			v.RenderOffset = roomOffset + MinimapAPI.GetFrameCenterOffset() + roomAnimPivot
		end
		
		if MinimapAPI.Config.ShowShadows then
			for i,v in pairs(roommapdata) do
				local displayflags = MinimapAPI.GetDisplayFlags(v)
				if displayflags > 0 then
					for n,pos in ipairs(MinimapAPI.GetRoomShapePositions(v.Shape)) do
						pos = Vector(pos.X * roomSize.X, pos.Y * roomSize.Y)
						local actualRoomPixelSize = outlinePixelSize
						local brcutoff = v.RenderOffset + pos + actualRoomPixelSize - MinimapAPI.GetFrameBR()
						local tlcutoff = -(v.RenderOffset + pos)
						if brcutoff.X < actualRoomPixelSize.X and brcutoff.Y < actualRoomPixelSize.Y and
						tlcutoff.X < actualRoomPixelSize.X and tlcutoff.Y < actualRoomPixelSize.Y then
							brcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
							tlcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
							minimapsmall:SetFrame("RoomOutline",1)
							minimapsmall:Render(offsetVec + v.RenderOffset + pos,tlcutoff,brcutoff)
						end
					end
				end
			end
		end
		
		for i,v in pairs(roommapdata) do
			local iscurrent = MinimapAPI.PlayerInRoom(v)
			local displayflags = MinimapAPI.GetDisplayFlags(v)
			if displayflags & 0x1 > 0 then
				local anim
				if iscurrent then
					anim = "RoomCurrent"
				elseif MinimapAPI.GetClear(v) then
					anim = "RoomVisited"
				else
					anim = "RoomUnvisited"
				end
				local rms = MinimapAPI.GetRoomShapeGridSize(v.Shape)
				local actualRoomPixelSize = Vector(roomPixelSize.X * rms.X, roomPixelSize.Y * rms.Y) - roomAnimPivot
				local brcutoff = v.RenderOffset + actualRoomPixelSize - MinimapAPI.GetFrameBR()
				local tlcutoff = -v.RenderOffset
				if brcutoff.X < actualRoomPixelSize.X and brcutoff.Y < actualRoomPixelSize.Y and
				tlcutoff.X < actualRoomPixelSize.X and tlcutoff.Y < actualRoomPixelSize.Y then
					brcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
					tlcutoff:Clamp(0, 0, actualRoomPixelSize.X, actualRoomPixelSize.Y)
					minimapsmall:SetFrame(anim,MinimapAPI.GetRoomShapeFrame(v.Shape))
					minimapsmall:Render(offsetVec + v.RenderOffset,tlcutoff,brcutoff)
				end
			end
		end
		
		if MinimapAPI.Config.ShowIcons then
			for i,v in pairs(roommapdata) do
				local incurrent = MinimapAPI.PlayerInRoom(v)
				local displayflags = MinimapAPI.GetDisplayFlags(v)
				local k = 1
				local function renderIcon(icon,locs)
					if icon then
						local loc = locs[k]
						if not loc then return end
						
						local iconlocOffset = Vector(loc.X * roomSize.X, loc.Y * roomSize.Y)
						local spr = icon.sprite or minimapsmall
						local brcutoff = v.RenderOffset + iconlocOffset + iconPixelSize - MinimapAPI.GetFrameBR()
						local tlcutoff = frameTL-(v.RenderOffset + iconlocOffset)
						if brcutoff.X < iconPixelSize.X and brcutoff.Y < iconPixelSize.Y and
						tlcutoff.X < iconPixelSize.X and tlcutoff.Y < iconPixelSize.Y then
							brcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
							tlcutoff:Clamp(0, 0, iconPixelSize.X, iconPixelSize.Y)
							spr:SetFrame(icon.anim,icon.frame)
							spr:Render(offsetVec + iconlocOffset + v.RenderOffset,tlcutoff,brcutoff)
							k = k + 1
						end
					end
				end
				
				if displayflags & 0x4 > 0 then
					local iconcount = #v.PermanentIcons
					if not incurrent then
						iconcount = iconcount + #v.ItemIcons
					end
					
					local locs = MinimapAPI.GetRoomShapeIconPositions(v.Shape, iconcount)
					
					for _,icon in ipairs(v.PermanentIcons) do
						renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
					end
					if not incurrent then
						for _,icon in ipairs(v.ItemIcons) do
							renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
						end
					end
				elseif displayflags & 0x2 > 0 then
					if v.LockedIcons and #v.LockedIcons > 0 then
						local locs = MinimapAPI.GetRoomShapeIconPositions(v.Shape, #v.LockedIcons)
						for _,icon in ipairs(v.LockedIcons) do
							renderIcon(MinimapAPI.GetIconAnimData(icon),locs)
						end
					end
				end
			end
		end
	end
end

MinimapAPI:AddCallback(ModCallbacks.MC_POST_RENDER, function(self)
	screen_size = MinimapAPI.GetScreenSize()
	if MinimapAPI.Config.DisplayOnNoHUD or not Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) then
		
		local currentroomdata = MinimapAPI.GetCurrentRoom()
		if currentroomdata and MinimapAPI.PickupDetectionEnabled() then
			currentroomdata.ItemIcons = MinimapAPI.GetCurrentRoomPickupIDs()
		end
			
		if roommapdata then
			if MinimapAPI.IsLarge() then
				renderHugeMinimap()
			elseif MinimapAPI.Config.DisplayMode == 1 then
				renderUnboundedMinimap()
			elseif MinimapAPI.Config.DisplayMode == 2 then
				renderBoundedMinimap()
			end
		end
	end
end)

if ModConfigMenu then
	ModConfigMenu.AddSetting("Minimap API","General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.Disable
			end,
			Display = function()
				return "Disable Minimap: "..(MinimapAPI.Config.Disable and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.Disable = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting("Minimap API","General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.OverrideLost
			end,
			Display = function()
				return "Display During Curse: "..(MinimapAPI.Config.OverrideLost and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.OverrideLost = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting("Minimap API","General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.DisplayOnNoHUD
			end,
			Display = function()
				return "Display with No HUD Seed: "..(MinimapAPI.Config.DisplayOnNoHUD and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.DisplayOnNoHUD = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting("Minimap API","General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowIcons
			end,
			Display = function()
				return "Show Icons: "..(MinimapAPI.Config.ShowIcons and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowIcons = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting("Minimap API","General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowShadows
			end,
			Display = function()
				return "Show Shadows: "..(MinimapAPI.Config.ShowShadows and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowShadows = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting("Minimap API","General",
		{
			Type = ModConfigMenuOptionType.BOOLEAN,
			CurrentSetting = function()
				return MinimapAPI.Config.ShowLevelFlags
			end,
			Display = function()
				return "Show Level Flags: "..(MinimapAPI.Config.ShowLevelFlags and "True" or "False")
			end,
			OnChange = function(currentBool)
				MinimapAPI.Config.ShowLevelFlags = currentBool
			end
		}
	)
	
	ModConfigMenu.AddSetting("Minimap API", "General", {
		Type = ModConfigMenuOptionType.NUMBER,
		CurrentSetting = function()
			return MinimapAPI.Config.DisplayMode
		end,
		Minimum = 1,
		Maximum = 2,
		Display = function()
			return "Display Mode: "..({
				"Borderless",
				"Bordered"
			})[MinimapAPI.Config.DisplayMode]
		end,
		OnChange = function(currentNum)
			MinimapAPI.Config.DisplayMode = currentNum
		end,
	})
	
	ModConfigMenu.AddSetting("Minimap API", "General", {
		Type = ModConfigMenuOptionType.NUMBER,
		CurrentSetting = function()
			return MinimapAPI.Config.MapFrameWidth
		end,
		Minimum = 10,
		Maximum = 100,
		ModifyBy = 5,
		Display = function()
			return "Border Width: "..MinimapAPI.Config.MapFrameWidth
		end,
		OnChange = function(currentNum)
			MinimapAPI.Config.MapFrameWidth = currentNum
		end,
	})
	
	ModConfigMenu.AddSetting("Minimap API", "General", {
		Type = ModConfigMenuOptionType.NUMBER,
		CurrentSetting = function()
			return MinimapAPI.Config.MapFrameHeight
		end,
		Minimum = 10,
		Maximum = 100,
		ModifyBy = 5,
		Display = function()
			return "Border Height: "..MinimapAPI.Config.MapFrameHeight
		end,
		OnChange = function(currentNum)
			MinimapAPI.Config.MapFrameHeight = currentNum
		end,
	})
	
	ModConfigMenu.AddSetting("Minimap API", "General", {
		Type = ModConfigMenuOptionType.NUMBER,
		CurrentSetting = function()
			return MinimapAPI.Config.PositionX
		end,
		Minimum = 0,
		Maximum = 40,
		ModifyBy = 2,
		Display = function()
			return "Position X: "..MinimapAPI.Config.PositionX
		end,
		OnChange = function(currentNum)
			MinimapAPI.Config.PositionX = currentNum
		end,
	})
	
	ModConfigMenu.AddSetting("Minimap API", "General", {
		Type = ModConfigMenuOptionType.NUMBER,
		CurrentSetting = function()
			return MinimapAPI.Config.PositionY
		end,
		Minimum = 0,
		Maximum = 40,
		ModifyBy = 2,
		Display = function()
			return "Position Y: "..MinimapAPI.Config.PositionY
		end,
		OnChange = function(currentNum)
			MinimapAPI.Config.PositionY = currentNum
		end,
	})
end

-- LOADING SAVED GAME
MinimapAPI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(self,is_save)
	if MinimapAPI:HasData() then
		local saved = json.decode(Isaac.LoadModData(MinimapAPI))
		MinimapAPI.Config = saved.Config
		if is_save then
			local vanillarooms = Game():GetLevel():GetRooms()
			MinimapAPI.ClearMap()
			for i,v in ipairs(saved.LevelData) do
				MinimapAPI.AddRoom{
					Position = Vector(v.PositionX,v.PositionY),
					ID = v.ID,
					Shape = v.Shape,
					ItemIcons = v.ItemIcons,
					PermanentIcons = v.PermanentIcons,
					LockedIcons = v.LockedIcons,
					Descriptor = v.DescriptorListIndex and vanillarooms:Get(v.DescriptorListIndex),
					DisplayFlags = v.DisplayFlags,
					Clear = v.Clear,
				}
			end
		end
	end
end)


-- SAVING GAME
MinimapAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
	local saved = {}
	saved.Config = MinimapAPI.Config
	saved.LevelData = {}
	for i,v in ipairs(roommapdata) do
		saved.LevelData[#saved.LevelData + 1] = {
			PositionX = v.Position.X,
			PositionY = v.Position.Y,
			ID = type(v.ID) ~= "userdata" and v.ID,
			Shape = v.Shape,
			ItemIcons = v.ItemIcons,
			PermanentIcons = v.PermanentIcons,
			LockedIcons = v.LockedIcons,
			DescriptorListIndex = v.Descriptor and v.Descriptor.ListIndex,
			DisplayFlags = rawget(v,"DisplayFlags"),
			Clear = rawget(v,"Clear"),
		}
	end
	MinimapAPI:SaveData(json.encode(saved))
end)


Isaac.ConsoleOutput("Minimap API loaded!\n")