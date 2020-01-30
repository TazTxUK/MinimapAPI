
--Quick port of wof's code for ease of use
--Maybe needs reformatting

local miniMAPI = MinimapAPI

miniMAPI.RoomShapeAdjacentRoomCoords = {

-- L0 		UP0		R0		D0		L1		UP1		R1		D1
{{-1, 0}, {0, -1}, {1, 0}, {0, 1},{},{},{},{}}, -- ROOMSHAPE_1x1 
{{-1, 0},{},{1, 0},{},{},{},{},{}}, -- ROOMSHAPE_IH  
{{},{0, -1},{},{0, 1},{},{},{},{}}, -- ROOMSHAPE_IV  
{{-1, 0}, {0, -1}, {1, 0}, {0, 2}, {-1, 1},{}, {1, 1},{}}, -- ROOMSHAPE_1x2  
{{},{0, -1},{}, {0, 2},{},{},{},{}}, -- ROOMSHAPE_IIV  
{{-1, 0},{0, -1},{2, 0},{0, 1},{-1, 0},{1, -1},{2, 0},{1, 1}}, -- ROOMSHAPE_2x1  
{{-1, 0},{},{2,0},{},{},{},{},{}}, -- ROOMSHAPE_IIH  
{{-1,0},{0,-1},{1,0},{0,1},{-1,1},{1,-1},{2,1},{1,2}}, -- ROOMSHAPE_2x2  
{{-1,0},{-1,0},{1,0},{-1,2},{-2,1},{0,-1},{1,2},{0,2}}, -- ROOMSHAPE_LTL
{{-1,0},{0,-1},{1,0},{0,2},{-1,1},{1,0},{2,1},{1,2}}, -- ROOMSHAPE_LTR  
{{-1,0},{0,-1},{2,0},{0,1},{0,1},{1,-1},{2,1},{1,2}}, -- ROOMSHAPE_LBL  
{{-1,0},{0,-1},{2,0},{0,2},{-1,1},{1,-1},{1,1},{1,1}} -- ROOMSHAPE_LBR  

}

-- Available doorslot ids per roomshape
miniMAPI.RoomShapeDoorSlots ={
{0,1,2,3}, -- ROOMSHAPE_1x1 
{0,2}, -- ROOMSHAPE_IH  
{1,3}, -- ROOMSHAPE_IV  
{0,1,2,3,4,6}, -- ROOMSHAPE_1x2  
{1,3}, -- ROOMSHAPE_IIV  
{0,1,2,3,5,7}, -- ROOMSHAPE_2x1  
{0,2}, -- ROOMSHAPE_IIH  
{0,1,2,3,4,5,6,7}, -- ROOMSHAPE_2x2  
{0,1,2,3,4,5,6,7}, -- ROOMSHAPE_LTL  
{0,1,2,3,4,5,6,7}, -- ROOMSHAPE_LTR  
{0,1,2,3,4,5,6,7}, -- ROOMSHAPE_LBL  
{0,1,2,3,4,5,6,7} -- ROOMSHAPE_LBR  
}

-- Returns true and the door, when "room" is adjacent to "curRoom"
function miniMAPI:IsAdjacentRoom(curRoom, room) 
	local checkPos = miniMAPI.RoomShapeAdjacentRoomCoords[room.Shape]
	-- Get possible current room positions
	local posToCheck = {{curRoom.Position.X, curRoom.Position.Y}}
	for _,child in ipairs(curRoom.childrenPositions) do
		table.insert(posToCheck,child)
	end
	for i = 1, #checkPos do
		if #checkPos[i]>0 then
			for j = 1, #posToCheck do
				if room.Position.X + checkPos[i][1] == posToCheck[j][1] and room.Position.Y + checkPos[i][2] == posToCheck[j][2] then
					return {true,checkPos[i][1]}
				end
			end
		end
	end
	return {false,-1}
end

-- Returns the room relative to the doorslot position of the defined roomID
function miniMAPI:GetRelativeToDoorPos(room,DoorSlot) 
	if not miniMAPI:IsDoorSlotAllowed(roomID,DoorSlot) then return nil end
	local doorSlotOffset= miniMAPI.RoomShapeAdjacentRoomCoords[room.Shape][DoorSlot+1]
	return miniMAPI:GetRoom(Vector(room.Position.X+doorSlotOffset[1],room.Position.Y+doorSlotOffset[2]))
end

-- Returns wheather or not a doorslot can be used in the specified room.
function miniMAPI:IsDoorSlotAllowed(room,DoorSlot)
	for i=1,#miniMAPI.RoomShapeDoorSlots[room.Shape] do
		if miniMAPI.RoomShapeDoorSlots[room.Shape][i]==DoorSlot then return true end
	end
	return false
end

-- TODO
function miniMAPI:GetRandomFreePos(roomID) end