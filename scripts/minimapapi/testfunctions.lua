local MinimapAPI = require("scripts.minimapapi")

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

function MinimapAPI.Debug.OfSprite(sprite)
	MinimapAPI:ClearMap()
	for j=0,15 do
		for i=0,15 do
			if MinimapAPI:IsPositionFree(Vector(i,j)) then
				local s = 1
				local size = MinimapAPI.RoomShapeGridSizes[s]

				local kcolor = sprite:GetTexel(Vector(i,j),Vector(0,0),1)
				MinimapAPI:AddRoom{
					DisplayFlags = 5,
					Position = Vector(i,j),
					Clear = true,
					Shape = s,
					Color = Color(kcolor.Red, kcolor.Green, kcolor.Blue, kcolor.Alpha, 0, 0, 0)
				}
			end
		end
	end
	MinimapAPI:SetPlayerPosition(Vector(0,0))
end

function MinimapAPI.Debug.Gen(r,noborderbreak)
	MinimapAPI:ClearMap()
	local x = MinimapAPI:AddRoom{Position=Vector(0,0),DisplayFlags=5}

	local powval = 2
	local function addRoom(pw)
		local rng = math.random()
		local pos = MinimapAPI.Level[math.floor((rng^pw)*#MinimapAPI.Level + 1)].Position
		local dirrng = math.random(0,3)
		local dir
		    if dirrng == 0 then dir = Vector(1,0)
		elseif dirrng == 1 then dir = Vector(0,1)
		elseif dirrng == 2 then dir = Vector(-1,0)
		elseif dirrng == 3 then dir = Vector(0,-1)
		end
		pos = pos + dir
		if MinimapAPI:IsPositionFree(pos) then
			local new = MinimapAPI:AddRoom{Position=pos,DisplayFlags=5}
			if (#new:GetAdjacentRooms() < 2 or math.random() <= 0.2) and (not noborderbreak or (math.abs(new.Position.X) <= 6 and math.abs(new.Position.Y) <= 6)) then
				powval = 2
				table.sort(MinimapAPI.Level, function(a,b) return a.Position:DistanceSquared(x.Position) > b.Position:DistanceSquared(x.Position) end)
				return new
			else
				powval = math.max(powval - 0.5,0.5)
				MinimapAPI:RemoveRoom(new.Position)
			end
		end
	end

	local function getEndpoints()
		local endpoints = {}
		for i,v in ipairs(MinimapAPI.Level) do
			if #v:GetAdjacentRooms() == 1 then
				endpoints[#endpoints + 1] = v
			end
		end
		-- table.sort(endpoints, function(a,b) return a.Position:DistanceSquared(x.Position) < b.Position:DistanceSquared(x.Position) end)
		table.sort(endpoints, function(a,b) return math.abs(a.Position:Length()-25) < math.abs(a.Position:Length()-25) end)
		return endpoints
	end

	local game = Game()
	local level = game:GetLevel()
	local stageId = level:GetStage()

	local numberOfRooms = math.min(20, math.random(0,1) + 5 + math.floor(stageId * 10 / 3))
	--curse laby
	--curse lost
	if stageId == 12 then
		numberOfRooms = 50 + math.random(0,9)
	end
	--hard mode

	local minDeadEnds = 5
	if stageId ~= 1 then
		minDeadEnds = minDeadEnds + 1
	end
	--curse laby
	if stageId == 12 then
		minDeadEnds = minDeadEnds + 2
	end

	local i = 2
	r = r or numberOfRooms
	while i <= r do
		if addRoom(powval) then i = i + 1 end
	end

	while #getEndpoints() < minDeadEnds do
		local new = addRoom(1)
		if new and #new:GetAdjacentRooms() ~= 1 then
			MinimapAPI:RemoveRoom(new.Position)
		end
	end

	local endpoints = getEndpoints()

	local function deqEndp()
		local ep = endpoints[#endpoints]
		endpoints[#endpoints] = nil
		return ep
	end

	local function qEndp(x)
		endpoints[#endpoints + 1] = x
	end

	local function placeRoom(typ, room)
		room.PermanentIcons = {typ}
	end

	local last = deqEndp()
	placeRoom("Boss",last)
	placeRoom("SuperSecretRoom",deqEndp())
	if stageId < 7 or (stageId < 9 --[[and has silver dollar and vic lap < 3]]) then
		placeRoom("Shop",deqEndp())
	end
	if stageId < 7 or (stageId < 9 --[[and has bloody crown]]) then
		placeRoom("TreasureRoom",deqEndp())
	end
	if stageId < 12 then
		local deadend = deqEndp()
		if deadend then
			local roomtype
			-- dice room check
			-- else sacrifice
			-- bleh
			qEndp(deadend)
		end
	end
	--lib or some shit
	--curse
	-- miniboss
	--chall
	--chest and arcade
	--bedroom
	--secret
	--grave

	while true do
		local dead = deqEndp()
		if dead then
			placeRoom("Boss",dead)
		else
			break
		end
	end

	for i,v in ipairs(MinimapAPI.Level) do
		local dist = v.Position:Distance(last.Position)
		if dist <= 25 then
			v.Color = Color(0,1,1-(dist)/25,1,0,0,0)
		elseif dist <= 50 then
			v.Color = Color((dist-25)/25,1,(dist-25)/25,1,0,0,0)
		else
			v.Color = Color(1,1,1,1,0,0,0)
		end
		v.Clear = true
		v.Position.X = v.Position.X - v.Position.Y*0.2
	end

	MinimapAPI:SetPlayerPosition(Vector(0,0))
end

function MinimapAPI.Debug.PeriodicTable()
	local text = {
		"H" ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"He",
		"Li","Be",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"B" ,"C" ,"N" ,"O" ,"F" ,"Ne",
		"Na","Mg",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"Al","Si","P" ,"S" ,"Cl","Ar",
		"K" ,"Ca","Sc","Ti","V" ,"Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr",
		"Rb","Sr","Y" ,"Zr","Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I" ,"Xe",
		"Cs","Ba","",  "Hf","Ta","W" ,"Re","Os","Ir","Pt","Au","Hg","Tl","Pb","Bi","Po","At","Rn",
		"Fr","Ra","",  "Rf","Db","Sg","Bh","Hs","Mt","Ds","Rg","Cn","Nh","Fl","Mc","Lv","Ts","Og",
		""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,
		""  ,""  ,"La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb","Lu",""  ,
		""  ,""  ,"Ac","Th","Pa","U", "Np","Pu","Am","Cm","Bk","Cf","Es","Fm","Md","No","Lr",""  ,
	}
	local typ = {
		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,
		2,3,0,0,0,0,0,0,0,0,0,0,7,1,1,1,6,5,
		2,3,0,0,0,0,0,0,0,0,0,0,8,7,1,1,6,5,
		2,3,4,4,4,4,4,4,4,4,4,4,8,7,7,1,6,5,
		2,3,4,4,4,4,4,4,4,4,4,4,8,8,7,7,6,5,
		2,3,0,4,4,4,4,4,4,4,4,4,8,8,8,7,6,5,
		2,3,0,4,4,4,4,4,4,4,4,4,8,8,8,8,6,5,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
		10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
	}
	local col = {
		KColor(52/255, 83/255, 211/255, 1),
		KColor(1,0,0,1),
		KColor(1,0.5,0,1),
		KColor(1,1,0,1),
		KColor(57/255,5/255,126/255,1),
		KColor(112/255,10/255,1,1),
		KColor(71/255,156/255,255/255,1),
		KColor(0/255,156/255,75/255,1),
		KColor(1,0.8,0.8,1),
		KColor(1,0.5,0.5,1),
	}
	local wid = 18
	MinimapAPI:ClearMap()
	for i=1,#text do
		local v = text[i]
		local x = (i-1)%wid
		local y = math.floor((i-1)/wid)
		if v:len() > 0 then
			local room = MinimapAPI:AddRoom{
				Position = Vector(x,y),
				Text = v,
				TextColor = col[typ[i]],
				DisplayFlags = 5,
				Clear = true,
			}
			if v == "Au" then
				room.PermanentIcons = {"TreasureRoom"}
				room.Text = nil
			elseif v == "Ag" then
				room.PermanentIcons = {"TreasureRoomGreed"}
				room.Text = nil
			end
		end
	end
end
