local MinimapAPI = require("scripts.minimapapi")

-- match main.lua
local largeRoomPixelSize = Vector(18, 16)

-- ours
local RoomSpriteOffset = Vector(4, 4)
local Game = Game()
local level = Game:GetLevel()
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

---@param room MinimapAPI.Room # target room
---@param curRoom MinimapAPI.Room # room we're teleporting from
---@return boolean # should player be hurt from entering or exiting a curse room
local function ShouldDamagePlayer(room, curRoom)
    if type(curRoom) == "nil" then
        return false
    end
    local enteringCurseRoom = room.Descriptor.Data.Type == RoomType.ROOM_CURSE
    local leavingCurseRoom = curRoom.Data.Type == RoomType.ROOM_CURSE

    if not (enteringCurseRoom or leavingCurseRoom) or MinimapAPI:GetConfig("MouseTeleportDamageOnCurseRoom") then
        return false
    end

    for i = 0, Game:GetNumPlayers() - 1 do
        if REPENTANCE and Isaac.GetPlayer(i):HasTrinket(TrinketType.TRINKET_FLAT_FILE)
            or Isaac.GetPlayer(i):HasCollectible(CollectibleType.COLLECTIBLE_ISAACS_HEART) then
            return false
        end
    end

    if leavingCurseRoom then
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
---@param curRoom MinimapAPI.Room # room we're teleporting from
---@return boolean # is player allowed to teleport
local function CanTeleportToRoom(room, curRoom)
    local onMomFloor = (level:GetStage() == 6
        or (level:GetStage() == 5 and (level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH > 0)))
    if MinimapAPI:GetConfig("MouseTeleportUncleared") or type(curRoom) == "nil" then
        return true
    elseif (curRoom.Data.Type == RoomType.ROOM_BOSS and gameroom:GetBossID() == 6)
    or curRoom.GridIndex == GridRooms.ROOM_BOSSRUSH_IDX
    or (onMomFloor and curRoom.GridIndex == GridRooms.ROOM_DEVIL_IDX and level:GetLastRoomDesc().Data.Type == RoomType.ROOM_BOSS) then -- Mom
        return (REPENTANCE and level:IsAscent()) or false
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
        else
            return true
        end
    else
        return false
    end
end

---@param room MinimapAPI.Room # target room
local function TeleportToRoom(room)
    local curRoom = level:GetCurrentRoomDesc()
    if room.TeleportHandler and room.TeleportHandler.Teleport then
        if not room.TeleportHandler:Teleport(room) then
            Sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.8)
        end
    elseif room.Descriptor and CanTeleportToRoom(room, curRoom) then
        if ShouldDamagePlayer(room, curRoom) then
            Isaac.GetPlayer(0):TakeDamage(1, DamageFlag.DAMAGE_CURSED_DOOR | DamageFlag.DAMAGE_NO_PENALTIES,
                EntityRef(Isaac.GetPlayer(0)), 0)
        end
        Game:GetLevel().LeaveDoor = -1
        Game:StartRoomTransition(room.Descriptor.SafeGridIndex, Direction.NO_DIRECTION,
            REPENTANCE and RoomTransitionAnim.FADE or 1)
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
            local gripPivotOffset = Vector(rgp.X * size.X / 2, rgp.Y * size.Y / 2)
            local pos = room.RenderOffset + Vector(MinimapAPI.GlobalScaleX * RoomSpriteOffset.X, RoomSpriteOffset.Y) -
                gripPivotOffset
            local center = pos + Vector(size.X / 2 * MinimapAPI.GlobalScaleX, size.Y / 2)
            local boundsTl, boundsBr = pos, pos + size
            if MinimapAPI.GlobalScaleX == -1 then -- Map is flipped
                boundsTl, boundsBr = pos - Vector(size.X, 0), pos + Vector(0, size.Y)
            end

            if mouseCoords.X > boundsTl.X and mouseCoords.X < boundsBr.X
                and mouseCoords.Y > boundsTl.Y and mouseCoords.Y < boundsBr.Y
            then
                TeleportMarkerSprite.Scale = Vector(MinimapAPI.GlobalScaleX, 1)
                TeleportMarkerSprite:Render(center, Vector(0, 0), Vector(0, 0))

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
