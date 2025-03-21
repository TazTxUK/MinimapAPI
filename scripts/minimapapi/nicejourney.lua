local MinimapAPI = require("scripts.minimapapi")
local constants = require("scripts.minimapapi.constants")
local CALLBACK_PRIORITY = constants.CALLBACK_PRIORITY

-- match main.lua
local largeRoomPixelSize = Vector(18, 16)

-- ours
local RoomSpriteOffset = Vector(4, 4)
local Game = Game()
local Sfx = SFXManager()

local WasTriggered = false
local currentlyHighlighted = nil
local lastMousePos = Vector( -1, -1)
local mouseMoved = false
local controlsDisabled = false
local cursorMovedWithKeyboard = false

local TeleportMarkerSprite = Sprite()
TeleportMarkerSprite:Load("gfx/ui/minimapapi/teleport_marker.anm2", true)
TeleportMarkerSprite:SetFrame("Marker", 0)
local teleportTarget

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

---@param room MinimapAPI.Room # target room
---@return boolean # should player be hurt from entering or exiting a curse room
local function ShouldDamagePlayer(room)
    local level = Game:GetLevel()
    local curRoom = level:GetCurrentRoomDesc()
    if not curRoom then
        return false
    end
    local enteringCurseRoom = room.Descriptor.Data.Type == RoomType.ROOM_CURSE
    local leavingCurseRoom = curRoom.Data.Type == RoomType.ROOM_CURSE

    if not (enteringCurseRoom or leavingCurseRoom) or not MinimapAPI:GetConfig("MouseTeleportDamageOnCurseRoom") then
        return false
    end

    for i = 0, Game:GetNumPlayers() - 1 do
        if MinimapAPI.isRepentance and Isaac.GetPlayer(i):HasTrinket(TrinketType.TRINKET_FLAT_FILE)
            or Isaac.GetPlayer(i):HasCollectible(CollectibleType.COLLECTIBLE_ISAACS_HEART) then
            return false
        end
    end

    if leavingCurseRoom then
        local gameroom = Game:GetRoom()
        for _, doorslot in ipairs(MinimapAPI.RoomShapeDoorSlots[curRoom.Data.Shape]) do
            local doorent = gameroom:GetDoor(doorslot)
            if doorent and doorent:IsOpen() then
                if doorent.TargetRoomType == RoomType.ROOM_SECRET or doorent:GetSaveState().VarData == 1 then -- Safe exit by secret room or opened via flat file
                    return false
                end
            end
        end
    elseif enteringCurseRoom then
        for i = 0, Game:GetNumPlayers() - 1 do
            if Isaac.GetPlayer(i).CanFly then
                return false
            end
        end
    end
    return true -- damage player
end

---@param room MinimapAPI.Room # target room
---@return boolean # is player allowed to teleport
local function CanTeleportToRoom(room)
    local level = Game:GetLevel()
    local gameroom = Game:GetRoom()
    local curRoom = level:GetCurrentRoomDesc()
    local onMomFloor = (level:GetStage() == 6
        or (level:GetStage() == 5 and (level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH > 0)))
    if MinimapAPI:GetConfig("MouseTeleportUncleared") or not curRoom then
        return true
    elseif (curRoom.Data.Type == RoomType.ROOM_BOSS and gameroom:GetBossID() == 6)
        or curRoom.GridIndex == GridRooms.ROOM_BOSSRUSH_IDX
        or (onMomFloor and curRoom.GridIndex == GridRooms.ROOM_DEVIL_IDX and level:GetLastRoomDesc().Data.Type == RoomType.ROOM_BOSS)-- Mom
        or (MinimapAPI.isRepentance and onMomFloor and curRoom.Data.Type == RoomType.ROOM_BOSS and gameroom:GetBossID() == 0) then -- Mausoleum Dads Note room
        return (MinimapAPI.isRepentance and level:IsAscent()) or false
    elseif curRoom.Clear then
        if curRoom.Data.Type == RoomType.ROOM_CHALLENGE and not curRoom.ChallengeDone then
            for _, doorslot in ipairs(MinimapAPI.RoomShapeDoorSlots[curRoom.Data.Shape]) do
                local doorent = gameroom:GetDoor(doorslot)
                if doorent and doorent:IsOpen() then
                    return true
                end
            end
            return false
        elseif room.Descriptor.Data.Type == RoomType.ROOM_CHALLENGE and not room.Descriptor.ChallengeDone then
            local allPlayersFullHealth = true
            local allPlayersOneHealth = true
            for i = 0, Game:GetNumPlayers() - 1 do
                local health = Isaac.GetPlayer(i):GetHearts() + Isaac.GetPlayer(i):GetSoulHearts()
                if allPlayersFullHealth and Isaac.GetPlayer(i):GetMaxHearts() > health then
                    allPlayersFullHealth = false
                end
                if health > 2 then
                    allPlayersOneHealth = false
                    break
                end
            end
            if room.Descriptor.Data.Subtype == 1 then
                return allPlayersOneHealth
            else
                return allPlayersFullHealth
            end
        elseif (MinimapAPI.isRepentance and level:GetStateFlag(LevelStateFlag.STATE_MINESHAFT_ESCAPE)) then
            return MinimapAPI.CurrentDimension ~= 1
        else
            return true
        end
    else
        return false
    end
end

---@param room MinimapAPI.Room # target room
local function TeleportToRoom(room)
    if room.TeleportHandler and room.TeleportHandler.Teleport then
        if not room.TeleportHandler:Teleport(room) then
            Sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.8)
        end
    elseif room.Descriptor and CanTeleportToRoom(room) then
        if ShouldDamagePlayer(room) then
            Isaac.GetPlayer(0):TakeDamage(1, DamageFlag.DAMAGE_CURSED_DOOR | DamageFlag.DAMAGE_NO_PENALTIES,
                EntityRef(Isaac.GetPlayer(0)), 0)
        end
        Game:GetLevel().LeaveDoor = -1
        Game:StartRoomTransition(room.Descriptor.SafeGridIndex, Direction.NO_DIRECTION,
            MinimapAPI.isRepentance and RoomTransitionAnim.FADE or 1)
    else
        Sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.8)
    end
end

local tabPressTimeStart = 0
local function HandleMoveCursorWithButtons()
    local playerController = Isaac.GetPlayer(0).ControllerIndex
    local TABpressed = Input.IsActionPressed(ButtonAction.ACTION_MAP, playerController)

    if TABpressed and tabPressTimeStart == 0 then
        tabPressTimeStart = Isaac.GetTime()
    elseif not TABpressed then
        tabPressTimeStart = 0
    elseif not currentlyHighlighted and Isaac.GetTime() - tabPressTimeStart > 500 then
        if MinimapAPI:GetCurrentRoom() then
            for _, room in ipairs(MinimapAPI:GetCurrentRoom():GetAdjacentRooms()) do
                if room:IsValidTeleportTarget() then
                    currentlyHighlighted = room
                    break
                end
            end
        else
            currentlyHighlighted = MinimapAPI:GetRoomByIdx(Game:GetLevel():GetStartingRoomIndex())
        end
    end

    if currentlyHighlighted then
        local posToCheck = nil
        if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, playerController) then
            posToCheck = MinimapAPI.Cache.MirrorDimension and { 3, 7 } or { 1, 5 } 
        elseif Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, playerController) then
            posToCheck = MinimapAPI.Cache.MirrorDimension and { 1, 5 } or { 3, 7 }
        elseif Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, playerController) then
            posToCheck = { 2, 6 }
        elseif Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, playerController) then
            posToCheck = { 4, 8 }
        end

        if posToCheck then
            cursorMovedWithKeyboard = true
            local doorPositions = MinimapAPI.RoomShapeDoorCoords[currentlyHighlighted.Shape]
            for _, possiblePos in ipairs(posToCheck) do
                if doorPositions[possiblePos] then
                    local room = MinimapAPI:GetRoomAtPosition(currentlyHighlighted.Position + doorPositions[possiblePos])
                    if room and room:IsValidTeleportTarget() then
                        currentlyHighlighted = room
                        return
                    end
                end
            end
        end
    end
end

local function round(num)
    local mult = 10 ^ 0
    return math.floor(num * mult + 0.5) / mult
end

local function niceJourney_PostRender()
    if not MinimapAPI:IsLarge() or not MinimapAPI:GetConfig("MouseTeleport") or Game:IsPaused() then
        currentlyHighlighted = nil
        tabPressTimeStart = 0
        teleportTarget = nil
        return
    end

    -- gameCoords = false doesn't give proper render coords
    local mouseCoords = Isaac.WorldToScreen(Input.GetMousePosition(true))
    mouseCoords = Vector(round(mouseCoords.X), round(mouseCoords.Y))
    mouseMoved = mouseCoords.X ~= lastMousePos.X or mouseCoords.Y ~= lastMousePos.Y
    lastMousePos = mouseCoords

    local playerController = Isaac.GetPlayer(0).ControllerIndex
    local TABpressed = Input.IsActionPressed(ButtonAction.ACTION_MAP, playerController)
    HandleMoveCursorWithButtons()

    teleportTarget = nil
    for _, room in pairs(MinimapAPI:GetLevel()) do
        if room:IsValidTeleportTarget()
            and (room.Descriptor or room.TeleportHandler)
        then
            local rgp = MinimapAPI.RoomShapeGridPivots[room.Shape]
            local rms = MinimapAPI:GetRoomShapeGridSize(room.Shape)
            local size = Vector(largeRoomPixelSize.X * rms.X, largeRoomPixelSize.Y * rms.Y)
            local gripPivotOffset = Vector(rgp.X * size.X / 2, rgp.Y * size.Y / 2)
            if room.RenderOffset and MinimapAPI.GlobalScaleX then
                local pos = room.RenderOffset + Vector(MinimapAPI.GlobalScaleX * RoomSpriteOffset.X, RoomSpriteOffset.Y)
                    - gripPivotOffset
                local center = pos + Vector(size.X / 2 * MinimapAPI.GlobalScaleX, size.Y / 2)
                local boundsTl, boundsBr = pos, pos + size
                if MinimapAPI.GlobalScaleX == -1 then -- Map is flipped
                    boundsTl, boundsBr = pos - Vector(size.X, 0), pos + Vector(0, size.Y)
                end
                if (TABpressed and not mouseMoved and currentlyHighlighted == room)
                    or (mouseCoords.X > boundsTl.X and mouseCoords.X < boundsBr.X
                    and mouseCoords.Y > boundsTl.Y and mouseCoords.Y < boundsBr.Y) then
                    TeleportMarkerSprite.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
                    if room == MinimapAPI:GetCurrentRoom() then
                        TeleportMarkerSprite.Color = Color(1, 1, 1, 0.5, 0, 0, 0)
                        teleportTarget = 'current'
                    else
                        TeleportMarkerSprite.Color = Color(1, 1, 1, 1, 0, 0, 0)
                        teleportTarget = room
                    end
                    currentlyHighlighted = room
                    TeleportMarkerSprite:Render(center, Vector(0, 0), Vector(0, 0))
                    break
                end
            end
        end
    end

    local pressed = Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) or
        Input.IsButtonTriggered(MinimapAPI.Config.TeleportConfirmKey, 0) or
        Input.IsButtonTriggered(MinimapAPI.Config.TeleportConfirmButton, playerController)
    if pressed and not WasTriggered and teleportTarget
        and teleportTarget ~= 'current' then
        WasTriggered = true
        TeleportToRoom(teleportTarget)
        teleportTarget = nil
    elseif not pressed and WasTriggered then
        WasTriggered = false
    end
end

MinimapAPI:AddCallbackFunc(
    ModCallbacks.MC_POST_UPDATE,
    CALLBACK_PRIORITY,
    function(_)
        if tabPressTimeStart > 1000 and not controlsDisabled and cursorMovedWithKeyboard and MinimapAPI:GetConfig("MouseTeleportDisableMovement") then
            Isaac.GetPlayer(0).ControlsEnabled = false
            if MinimapAPI.isRepentance and Isaac.GetPlayer(0):GetOtherTwin() then
                Isaac.GetPlayer(0):GetOtherTwin().ControlsEnabled = false
            end
            controlsDisabled = true
        elseif tabPressTimeStart == 0 and controlsDisabled then
            Isaac.GetPlayer(0).ControlsEnabled = true
            if MinimapAPI.isRepentance and Isaac.GetPlayer(0):GetOtherTwin() then
                Isaac.GetPlayer(0):GetOtherTwin().ControlsEnabled = true
            end
            controlsDisabled = false
        end
    end
)

local addRenderCall = true

MinimapAPI:AddCallbackFunc(
    ModCallbacks.MC_POST_GAME_STARTED,
    CALLBACK_PRIORITY,
    function(_, _)
        if addRenderCall then
			if REPENTOGON then
				MinimapAPI:AddCallbackFunc(ModCallbacks.MC_POST_HUD_RENDER, CALLBACK_PRIORITY, niceJourney_PostRender)
			elseif StageAPI and StageAPI.Loaded then
				StageAPI.AddCallback("MinimapAPI", "POST_HUD_RENDER", constants.STAGEAPI_CALLBACK_PRIORITY, niceJourney_PostRender)
				MinimapAPI.UsingStageAPIPostHUDRender = true -- only for stage api
			else
				MinimapAPI:AddCallbackFunc(ModCallbacks.MC_POST_RENDER, CALLBACK_PRIORITY, niceJourney_PostRender)
			end
            addRenderCall = false
        end
    end
)

MinimapAPI:AddCallbackFunc(ModCallbacks.MC_EXECUTE_CMD, CALLBACK_PRIORITY, niceJourney_ExecuteCmd)
