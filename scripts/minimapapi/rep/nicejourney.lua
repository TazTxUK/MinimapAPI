local MinimapAPI = require("scripts.minimapapi")

-- match main.lua
local largeRoomPixelSize = Vector(18, 16)

-- ours
local RoomSpriteOffset = Vector(4, 4)
local Game = Game()

local TeleportMarkerSprite = Sprite()
TeleportMarkerSprite:Load("gfx/ui/minimapapi/teleport_marker.anm2", true)
TeleportMarkerSprite:SetFrame("Marker", 0)

local function niceJourney_ExecuteCmd(_, cmd, params)
    if cmd == "mapitel" then
        MinimapAPI.Config.MouseTeleport = not MinimapAPI.Config.MouseTeleport
        if MinimapAPI.Config.MouseTeleport then
            Isaac.ConsoleOutput("Enabled Nice Journey (MinimapAPI mouse teleport)" .. '\n')
            Isaac.DebugString("Enabled Nice Journey (MinimapAPI mouse teleport)")
        else
            Isaac.ConsoleOutput("Disabled Nice Journey (MinimapAPI mouse teleport)" .. '\n')
            Isaac.DebugString("Disabled Nice Journey (MinimapAPI mouse teleport)")
        end
    end
end

---@param room MinimapAPI.Room
local function TeleportToRoom(room)
    local desc = room.Descriptor
    if desc then
        Game:GetLevel().LeaveDoor = -1
        Game:StartRoomTransition(desc.SafeGridIndex, Direction.NO_DIRECTION, RoomTransitionAnim.FADE)
    end
end

local WasTriggered = false

local function niceJourney_PostRender()
    if not MinimapAPI:IsLarge() or not MinimapAPI:GetConfig("MouseTeleport") then
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

    for _, room in pairs(MinimapAPI:GetLevel()) do
        ---@type MinimapAPI.Room
        room = room

        if room:IsVisited() and room:IsClear() then
            local rgp = MinimapAPI.RoomShapeGridPivots[room.Shape]
            local rms = MinimapAPI:GetRoomShapeGridSize(room.Shape)
            local size = largeRoomPixelSize * rms
            local pos = room.RenderOffset + RoomSpriteOffset - rgp * size / 2
            local center = pos + size / 2
            local boundsTl, boundsBr = pos, pos + size

            -- IDebug.RenderCircle(boundsTl, true, 5)

            if mouseCoords.X > boundsTl.X and mouseCoords.X < boundsBr.X
            and mouseCoords.Y > boundsTl.Y and mouseCoords.Y < boundsBr.Y
            then
                TeleportMarkerSprite:Render(center)

                if triggered and room ~= MinimapAPI:GetCurrentRoom() then
                    TeleportToRoom(room)
                end
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