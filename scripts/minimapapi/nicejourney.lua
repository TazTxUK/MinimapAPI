local MinimapAPI = require("scripts.minimapapi")

-- match main.lua
local largeRoomPixelSize = Vector(18, 16)

-- ours
local RoomSpriteOffset = Vector(4, 4)
local Game = Game()
local Sfx = SFXManager()
local gameroom = Game:GetRoom()

local TeleportMarkerSprite = Sprite()
TeleportMarkerSprite:Load("gfx/ui/minimapapi/teleport_marker.anm2", true)
TeleportMarkerSprite:SetFrame("Marker", 0)

local function niceJourney_ExecuteCmd(_, cmd, params)
    if cmd == "mapitel" then
        MinimapAPI.Config.MouseTeleport = not MinimapAPI.Config.MouseTeleport
        if MinimapAPI.Config.MouseTeleport then
            MinimapAPI.Config.MouseTeleportUncleared = params == "unclear"

            local msg = "Enabled Nice Journey (MinimapAPI mouse teleport)"
            if MinimapAPI.Config.MouseTeleportUncleared then
                msg = msg .. " with allowed teleport to uncleared rooms"
            else
                msg = msg .. "; uncleared rooms disabled, enable with 'mapitel unclear' to be able to teleport there"
            end

            Isaac.ConsoleOutput(msg .. '\n')
            Isaac.DebugString(msg)
        else
            Isaac.ConsoleOutput("Disabled Nice Journey (MinimapAPI mouse teleport)" .. '\n')
            Isaac.DebugString("Disabled Nice Journey (MinimapAPI mouse teleport)")
        end
    end
end

---Used to handle teleport in custom rooms,
---may be nil if the room is not custom.
---Each function can be nil and overrides the default
---behavior.
---@class TeleportHandler
local _telHandlerTemplate = {}
---@param room MinimapAPI.Room
---@return boolean success
function _telHandlerTemplate:Teleport(room)
end

---@param room MinimapAPI.Room
---@param cheatMode boolean # If cheat mode (unclear room teleport) is enabled
---@return boolean
function _telHandlerTemplate:CanTeleport(room, cheatMode)
end

local leavingCurseRoom = false
local enteringCurseRoom = false

---@param room MinimapAPI.Room # target room
---@param curRoom MinimapAPI.Room # room we're teleporting from
local function niceJourney_ShouldDamagePlayer(room, curRoom)
	enteringCurseRoom = room.Descriptor.Data.Type == RoomType.ROOM_CURSE
	leavingCurseRoom = (curRoom.Descriptor and curRoom.Descriptor.Data.Type == RoomType.ROOM_CURSE)

	--TODO: check door target room for any exit that isn't a curse room?
	if leavingCurseRoom then
		local doorCount = 0
		for _,doorslot in ipairs(MinimapAPI.RoomShapeDoorSlots[curRoom.Descriptor.Data.Shape]) do
		--TODO: for the life of me i cannot figure out from the door's data if it's a curse room door!!!
			local doorent = gameroom:GetDoor(doorslot)
			if doorent and doorent:IsOpen() then
				if doorent:GetSaveState().VarData == 1 then  -- opened via flat file
					leavingCurseRoom = false
					break
				end
			--Workaround for TODO above: if there's two doors that lead into a non-curse room, assume there's a safe exit
				if doorent.TargetRoomType ~= RoomType.ROOM_CURSE then
					doorCount = doorCount + 1
					if doorCount > 1 then
						leavingCurseRoom = false
						break
					end
				end
			end
		end
	end
	if enteringCurseRoom then
		for _,doorslot in ipairs(MinimapAPI.RoomShapeDoorSlots[room.Descriptor.Data.Shape]) do
			local doorent = gameroom:GetDoor(doorslot)
			if doorent and doorent:IsOpen()
			and doorent:GetSaveState().VarData == 1 then -- opened via flat file
				enteringCurseRoom = false
				break
			end
		end
	end

	Isaac.DebugString("enteringCurseRoom: "..tostring(enteringCurseRoom).." leavingCurseRoom: "..tostring(leavingCurseRoom))
	if leavingCurseRoom or enteringCurseRoom then

		for i = 0, Game:GetNumPlayers() - 1 do
			if Isaac.GetPlayer(i):HasTrinket(TrinketType.TRINKET_FLAT_FILE) then
				Isaac.DebugString("found flat file")
				return false
			end
		end
		if enteringCurseRoom then
			for i = 0, Game:GetNumPlayers() - 1 do
				if Isaac.GetPlayer(i).CanFly then
					return false
				end
			end
		end
		return true
	end
	return false
end

---@param room MinimapAPI.Room
local function TeleportToRoom(room)
    if room.TeleportHandler and room.TeleportHandler.Teleport then
        if not room.TeleportHandler:Teleport(room) then
            Sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.8)
        end
    elseif room.Descriptor then
		if niceJourney_ShouldDamagePlayer(room, MinimapAPI:GetCurrentRoom()) then
			Isaac.GetPlayer(0):TakeDamage(1, DamageFlag.DAMAGE_CURSED_DOOR | DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(Isaac.GetPlayer(0)), 0)
		end
        Game:GetLevel().LeaveDoor = -1
        Game:StartRoomTransition(room.Descriptor.SafeGridIndex, Direction.NO_DIRECTION, REPENTANCE and RoomTransitionAnim.FADE or 1)
    else
        Sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.8)
    end
end

local WasTriggered = false

local function niceJourney_PostRender()
    if not MinimapAPI:IsLarge() or not MinimapAPI:GetConfig("MouseTeleport") or Game:IsPaused() then
        return
    end

    -- gameCoords = false doesn't give proper render coords
    local mouseCoords = Isaac.WorldToScreen(Input.GetMousePosition(true))

    local pressed = Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT)
    local triggered = false
    if pressed and not WasTriggered then
        WasTriggered = true
        triggered = true
    elseif not pressed and WasTriggered then
        WasTriggered = false
    end

    local allowUnclear = MinimapAPI:GetConfig("MouseTeleportUncleared")

    for _, room in pairs(MinimapAPI:GetLevel()) do
        if (
            (
                room.TeleportHandler and room.TeleportHandler.CanTeleport
                    and room.TeleportHandler:CanTeleport(room, allowUnclear)
                )
                or (
                not (room.TeleportHandler and room.TeleportHandler.CanTeleport)
                    and (
                    room:IsVisited() and room:IsClear()
                        or (allowUnclear and room:IsVisible())
                    )
                )
            )
            and room ~= MinimapAPI:GetCurrentRoom()
            and (room.Descriptor or room.TeleportHandler)
        then
            local rgp = MinimapAPI.RoomShapeGridPivots[room.Shape]
            local rms = MinimapAPI:GetRoomShapeGridSize(room.Shape)
            local size = Vector(largeRoomPixelSize.X * rms.X, largeRoomPixelSize.Y * rms.Y)
			local gripPivotOffset = Vector(rgp.X * size.X / 2,rgp.Y * size.Y / 2)
            local pos = room.RenderOffset + Vector(MinimapAPI.GlobalScaleX * RoomSpriteOffset.X, RoomSpriteOffset.Y) - gripPivotOffset
            local center = pos + Vector(size.X / 2 * MinimapAPI.GlobalScaleX, size.Y / 2)
            local boundsTl, boundsBr = pos, pos + size
            if MinimapAPI.GlobalScaleX == -1 then -- Map is flipped
                boundsTl, boundsBr = pos - Vector(size.X, 0), pos + Vector(0, size.Y)
            end

            if mouseCoords.X > boundsTl.X and mouseCoords.X < boundsBr.X
                and mouseCoords.Y > boundsTl.Y and mouseCoords.Y < boundsBr.Y
            then
                TeleportMarkerSprite.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
                TeleportMarkerSprite:Render(center, Vector(0,0), Vector(0,0))

                if triggered then
                    TeleportToRoom(room)
                end
                return
            end
        end
    end
end

local addRenderCall = true

MinimapAPI:AddCallback(
    ModCallbacks.MC_POST_GAME_STARTED,
    function(self, is_save)
        if addRenderCall then
            MinimapAPI:AddCallback(ModCallbacks.MC_POST_RENDER, niceJourney_PostRender)
            addRenderCall = false
        end
    end
)

MinimapAPI:AddCallback(ModCallbacks.MC_EXECUTE_CMD, niceJourney_ExecuteCmd)
