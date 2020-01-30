# MinimapAPI
MinimapAPI is a modding API developed for the game "The Binding of Isaac: Rebirth". Its purpose is to provide a framework that allows other modders to freely edit the ingame Minimap as they please.


## Backlog / Todo-List
### Planned Features:
- New Setting: Map Transparency
- Split the Mod config settings in categories
- Display mode: Vanilla Borderless
- Add Map Curse Icons (Treasuremap, compass, blue map, restock,...)
  - Change position of the Map Curse icons (left, bottom[vanilla])
- Function - getRandomFreePos() : Returns a X,Y Position, where no room is present but thats adjcent to an existing room (useful for Red Key-like features)
- Function disable vanilla mapping behaviors like "build map on transition", "update current room"...
- Disable Room and Pickup icons seperately
- Add pickup display config options: (One pickup per item group, one pickup per corresponding icon, show all)

### Known issues:
- Curse of the Lost questionmark isnt handles by the API in any way
- when entering an offmap room (Devil,angel,...), the map will center around a random spot on the map, rather than the last room visited 
- Smooth map transitions look odd

### Needs rework:
- rework the "Post Render" functions to be less redundant (Assigned: Wofsauge)
- more intuitive names for most functions
- a more intuitive way to add a room. "t" or a table is not very intuitive to use...
- Some comments for the functions with a small explaination on what they are used for, what arguments they require, which of them are optional and what the function returns

## API Documentation
### Adding and removing rooms from the minimap
```lua
MinimapAPI:AddRoom{
	ID = --any value. This is used to identify your room later.
	Position = --a vector representing the position of the room on the minimap.
	Shape = --a RoomShape enum value that represents the sprite on the minimap and where icons will be placed.
	PermanentIcons = --optional. A list of strings, where each string is the icon ID representing the room's type.
	LockedIcons = --optional. a list of strings like above, but this is only shown when the player does not know the room's type (eg locked shop, dice room)
	ItemIcons = --optional. a list of icon IDs that display on the map (eg keys and hearts). This will be overridden once the player enters this room.
	DisplayFlags = --optional. the display flags for the room. Matches the format of RoomDescriptor.DisplayFlags. Overrides self.Descriptor.DisplayFlags
	Clear = --optional. the clear boolean for the room. Overrides self.Descriptor.Clear
	Color = --optional. a Color object that is applied when this room is rendered on the map.
	Descriptor = --optional. a RoomDescriptor object if you are attaching a vanilla room to this table. Setting this will cause this room's display flags and clear boolean to be taken from this RoomDescriptor.

	AllowRoomOverlap = --optional. The API will automatically remove a room if you add this in the same position, setting this to true will disable this functionality.
}
```

MinimapAPI:AddRoom takes a table, with the keys as listed above.
Returns the room added which is a table containing all of the keys above, except for AllowRoomOverlap
(The argument table and the table returned are not the same)

Adding a room with no display flags or descriptor will render it completely hidden.
Position is not bounded, and can be any number. (Decimal, negative, massive)
The API is not strict about types, so try not to put a number into the PermanentIcons or something like that.

For what icon IDs you can use, see the Data section below.

```lua
MinimapAPI:RemoveRoom(Vector position)
```

Removes the room from the minimap at the position given.

```lua
MinimapAPI:RemoveRoomByID(id)
```

Removes all rooms from the minimap with the ID given.

```lua
MinimapAPI:RemoveRoomByID(id)
```

### Get...

```lua
MinimapAPI:GetRoom(Vector position)
```

Returns the room at the given position.

```lua
MinimapAPI:GetRoomByID(id)
```

Returns one room in the level with the given ID.
*So don't add more than one room with the same ID.*

```lua
MinimapAPI:GetPlayerPosition()
```

Returns the player's map vector position relative to (0,0)

### Data
Icon ID | Animation Name
------- | --------------
Shop | IconShop
TreasureRoom | IconTreasureRoom
Boss | IconBoss
Miniboss | IconMiniboss
SecretRoom | IconSecretRoom
SuperSecretRoom | IconSuperSecretRoom
Arcade | IconArcade
CurseRoom | IconCurseRoom
AmbushRoom | IconAmbushRoom
Library | IconLibrary
SacrificeRoom | IconSacrificeRoom
AngelRoom | IconAngelRoom
BossAmbushRoom | IconBossAmbushRoom
IsaacsRoom | IconIsaacsRoom
BarrenRoom | IconBarrenRoom
ChestRoom | IconChestRoom
DiceRoom | IconDiceRoom
TreasureRoomGreed | IconTreasureRoomGreed
LockedRoom | IconLockedRoom
WhiteHeart | IconWhiteHeart
GoldHeart | IconGoldHeart
BoneHeart | IconBoneHeart
BlackHeart | IconBlackHeart
BlueHeart | IconBlueHeart
BlendedHeart | IconBlendedHeart
HalfBlueHeart | IconHalfBlueHeart
Heart | IconHeart
HalfHeart | IconHalfHeart
Item | IconItem
Trinket | IconTrinket
EternalChest | IconEternalChest
GoldChest | IconGoldChest
RedChest | IconRedChest
Chest | IconChest
StoneChest | IconStoneChest
SpikedChest | IconSpikedChest
Pill | IconPill
Key | IconKey
Bomb | IconBomb
Coin | IconCoin
Battery | IconBattery
Card | IconCard
Slot | IconSlot

