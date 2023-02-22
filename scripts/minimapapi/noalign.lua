local MinimapAPI = require("scripts.minimapapi")

--Functions for rooms that are not grid aligned

local function aabb(r1p1,r1p2,r2p1,r2p2)
	if
	(
		(r2p1.X < r1p2.X) and
		(r2p1.Y < r1p2.Y) and
		(r2p2.X > r1p1.X) and
		(r2p2.Y > r1p1.Y)
	)
	then
		return true
	else
		return false
	end
end

function MinimapAPI:IsPositionFreeNoAlign(position,roomshape)
	roomshape = roomshape or 1
	for _,room in ipairs(MinimapAPI.Level) do
		for i=1,#(MinimapAPI.RoomShapeRectangles[room.Shape]),2 do
			for j=1,#(MinimapAPI.RoomShapeRectangles[roomshape]),2 do
				local r1p1 = room.Position + MinimapAPI.RoomShapeRectangles[room.Shape][i]
				local r1p2 = room.Position + MinimapAPI.RoomShapeRectangles[room.Shape][i+1]
				local r2p1 = position + MinimapAPI.RoomShapeRectangles[roomshape][j]
				local r2p2 = position + MinimapAPI.RoomShapeRectangles[roomshape][j+1]
				if aabb(r1p1,r1p2,r2p1,r2p2) then
					return false
				end
			end
		end
	end
	return true
end
