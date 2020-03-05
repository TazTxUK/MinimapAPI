MinimapAPI.Debug = {}

function MinimapAPI.Debug.Icons()
	MinimapAPI:ClearMap()
	local val = math.ceil(math.sqrt(#MinimapAPI.IconList))
	local iconn = 1
	for i=1,val do
		for j=1,val do
			local s = 1
			local p = Vector(i,j)
			local icon = MinimapAPI.IconList[iconn]
			if not icon then return end
			if MinimapAPI:IsPositionFree(p,s) then
				local x = {
					Position = p,
					Shape = s,
					DisplayFlags = 5,
					PermanentIcons = {icon.ID}
				}
				
				MinimapAPI:AddRoom(x)
				iconn = iconn + 1
			end
		end
	end
	
	local cent = math.floor(val/2)
	MinimapAPI:SetPlayerPosition(Vector(cent,cent))
end

function MinimapAPI.Debug.Shapes()
	MinimapAPI:ClearMap()
	local x = 0
	for i,v in pairs(MinimapAPI.RoomShapeFrames) do
		while not MinimapAPI:IsPositionFree(Vector(x,0),i) do
			x = x + 1
		end
		MinimapAPI:AddRoom{
			DisplayFlags = 5,
			Shape = i,
			Position = Vector(x,0)
		}
		MinimapAPI:AddRoom{
			DisplayFlags = 5,
			Shape = i,
			Position = Vector(x,4),
			Clear = true,
		}
		MinimapAPI:AddRoom{
			DisplayFlags = 5,
			Shape = i,
			Position = Vector(x,8),
			Visited = true,
		}
	end
	MinimapAPI:SetPlayerPosition(Vector(1,1))
end

function MinimapAPI.Debug.RandomMap(x,y)
	x = x or 13
	y = y or 13
	MinimapAPI:ClearMap()
	for i=1,x do
		for j=1,y do
			local s = math.random() <= 0.05 and math.random(1,12) or 1
			local p = Vector(i,j)
			if math.random() <= 0.5 and MinimapAPI:IsPositionFree(p,s) then
				local x = {
					Position = p,
					Shape = s,
					Color = Color(math.random(0,1),math.random(0,1),math.random(0,1),1,0,0,0),
					DisplayFlags = 5,
				}
				x.PermanentIcons = {}
				
				for i=1,4 do
					if math.random() <= 0.5 then
						break
					end
					x.PermanentIcons[#x.PermanentIcons + 1] = MinimapAPI.IconList[math.random(#MinimapAPI.IconList)].ID
				end
				MinimapAPI:AddRoom(x)
			end
		end
	end
end

function MinimapAPI.Debug.Colors()
	MinimapAPI:ClearMap()
	local rng = {
		math.random(0,1),
		math.random(0,1),
		math.random(0,1),
		math.random(0,1),
		math.random(0,1),
		math.random(0,1)
	}
	for j=0,15 do
		for i=0,15 do
			if MinimapAPI:IsPositionFree(Vector(i,j)) then
				local s = math.random(1,12)
				local size = MinimapAPI.RoomShapeGridSizes[s]
				if not MinimapAPI:IsPositionFree(Vector(i,j),s) or size.X + i > 16 or size.Y + j > 16 or s == RoomShape.ROOMSHAPE_IH or s == RoomShape.ROOMSHAPE_IIH or s == RoomShape.ROOMSHAPE_IV or s == RoomShape.ROOMSHAPE_IIV then
					s = 1
				end
			
				MinimapAPI:AddRoom{
					DisplayFlags = 5,
					Position = Vector(i,j),
					Clear = true,
					Shape = s,
					Color = Color(
						i/15*rng[1] + j/15*rng[2],
						i/15*rng[3] + j/15*rng[4],
						i/15*rng[5] + j/15*rng[6],
						1, 0, 0, 0)
				}
			end
		end
	end
	MinimapAPI:SetPlayerPosition(Vector(math.random(0,12),math.random(0,12)))
end