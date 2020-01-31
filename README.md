# MinimapAPI
MinimapAPI is a modding API developed for the game "The Binding of Isaac: Rebirth". Its purpose is to provide a framework that allows other modders to freely edit the ingame Minimap as they please.

When downloading, please make sure to delete your save*.dat files (if you downloaded this previously) and put this in a folder beginning with an exclamation mark (ie !MinimapAPI)

### Unique Features
* Dynamically resizable minimap
* New unique custom icons for pickups, slot machines and beggars
* Highly configurable: Turn on/off parts of the minimap, like shadows or icons
* Smooth minimap movement (This must be enabled in the config under Experimental)
* New map mode: Small full map (display all rooms in small form!)

### API Features
* Add/remove rooms from the minimap
* Custom pickups
* Custom icons
* Automatic pickup detection
* Custom color rooms


## Backlog / Todo-List
### Planned Features:
* New Setting: Map Transparency
* Split the Mod config settings in categories
* Display mode: Vanilla Borderless
* Add Map Curse Icons (Treasuremap, compass, blue map, restock,...)
  * Change position of the Map Curse icons (left, bottom[vanilla])
* Function - getRandomFreePos() : Returns a X,Y Position, where no room is present but thats adjcent to an existing room (useful for Red Key-like features)
* Function disable vanilla mapping behaviors like "build map on transition", "update current room"...
* Disable Room and Pickup icons seperately
* Add pickup display config options: (One pickup per item group, one pickup per corresponding icon, show all)
* Implement new pickup icons:
  * Blood Donation Machine
  * Fortune Telling Machine
* Draw new pickup icons (where applicable):
  * Rune (redesign)
  * Beggar (redesign)
  * Grab bags
  * Nickels
  * Dimes
  * Golden Keys
  * Golden Bombs
  * Demon Beggar
  * Key Master
  * Bomb Bum
  * Donation Machine
  * Restock Machine
  * Broken Shovel

### Known issues:
* Curse of the Lost questionmark isnt handles by the API in any way
* when entering an offmap room (Devil,angel,...), the map will center around a random spot on the map, rather than the last room visited 
* Smooth map transitions look odd

### Needs rework:
* rework the "Post Render" functions to be less redundant (for @wofsauge)
* more intuitive names for most functions
* a more intuitive way to add a room. "t" or a table is not very intuitive to use...
* Some comments for the functions with a small explaination on what they are used for, what arguments they require, which of them are optional and what the function returns

## API Documentation
### Adding a room to the minimap
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

### Removing a room from the minimap

```lua
MinimapAPI:RemoveRoom(Vector position)
```

Removes the room from the minimap at the position given.

```lua
MinimapAPI:RemoveRoomByID(id)
```

Removes all rooms from the minimap with the ID given.

### Adding custom pickups and icons

```lua
MinimapAPI:AddCustomIcon(IconID, Sprite, string animationName, number frame)
```

Adds a custom icon to the icon list, using the above parameters.
If Sprite isn't provided, MinimapAPI will use the small minimap sprite.
animationName is required.
If frame isn't provided, 0 is used as the default.
> TODO: If frame isn't provided, it will play the animation instead.

```lua
MinimapAPI:AddCustomIcon(id, Sprite, string animationName, number frame, (optional) Color color)
```

* id is for identifying this icon. You would input the same ID into a function parameter that takes IconID.
* Adds a custom icon to the icon list, using the above parameters.
* If Sprite isn't provided, MinimapAPI will use the small minimap sprite.
* animationName is required.
* If frame isn't provided, 0 is used as the default.
  * **TODO:** If frame isn't provided, it will play the animation instead.
* Color is not implemented.
  * **TODO:** The color is applied to the icon drawn.

```lua
MinimapAPI:RemoveCustomIcon(id)
```

Remove a custom icon with the ID given.

```lua
MinimapAPI:AddCustomPickup(id, IconID, EntityType, number variant, number subtype, function, icongroup, number priority)
--or
MinimapAPI:AddCustomPickup{
	ID = --any
	IconID = --IconID
	Type = --EntityType
	Variant = --number variant
	SubType = --number subtype
	Call = --function
	IconGroup = --any
	Priority = --number
}
```

Adds a custom pickup to the pickup list. The API will automatically detect any pickup with the attributes given above in the current room and display the associated IconID on the minimap.

* ID is any value that is used to identify this pickup.
* IconID is the id of any icon that is used to display the pickup on the minimap (See IconIDs section under Data)
* EntityType is the type of the pickup.
* variant is the variant of the pickup. If nil or -1, all variants are accepted.
* subtype is the subtype of the pickup. If nil or -1, all subtypes are accepted.
* function is a function that takes the pickup as an argument and returns true if it can be displayed on the map, false otherwise. (Useful for pickups that have been collected but still exist) If nil, then the pickup will always be accepted if it matches the type, variant and subtype.
* IconGroup (typically a string, but can be any value). If two or more icons are of the same icon group, and both want to be displayed, only the one with the highest priority will be shown. (For a list, see IconGroups under Data)
* Priority is a number. Icons with higher priorities will be displayed over other icons. Default = 11000

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

## Data
### IconIDs
IconID | Animation Name
------ | --------------
"Shop" | "IconShop"
"TreasureRoom" | "IconTreasureRoom"
"Boss" | "IconBoss"
"Miniboss" | "IconMiniboss"
"SecretRoom" | "IconSecretRoom"
"SuperSecretRoom" | "IconSuperSecretRoom"
"Arcade" | "IconArcade"
"CurseRoom" | "IconCurseRoom"
"AmbushRoom" | "IconAmbushRoom"
"Library" | "IconLibrary"
"SacrificeRoom" | "IconSacrificeRoom"
"AngelRoom" | "IconAngelRoom"
"BossAmbushRoom" | "IconBossAmbushRoom"
"IsaacsRoom" | "IconIsaacsRoom"
"BarrenRoom" | "IconBarrenRoom"
"ChestRoom" | "IconChestRoom"
"DiceRoom" | "IconDiceRoom"
"TreasureRoomGreed" | "IconTreasureRoomGreed"
"LockedRoom" | "IconLockedRoom"
"WhiteHeart" | "IconWhiteHeart"
"GoldHeart" | "IconGoldHeart"
"BoneHeart" | "IconBoneHeart"
"BlackHeart" | "IconBlackHeart"
"BlueHeart" | "IconBlueHeart"
"BlendedHeart" | "IconBlendedHeart"
"HalfBlueHeart" | "IconHalfBlueHeart"
"Heart" | "IconHeart"
"HalfHeart" | "IconHalfHeart"
"Item" | "IconItem"
"Trinket" | "IconTrinket"
"EternalChest" | "IconEternalChest"
"GoldChest" | "IconGoldChest"
"RedChest" | "IconRedChest"
"Chest" | "IconChest"
"StoneChest" | "IconStoneChest"
"SpikedChest" | "IconSpikedChest"
"Pill" | "IconPill"
"Key" | "IconKey"
"Bomb" | "IconBomb"
"Coin" | "IconCoin"
"Battery" | "IconBattery"
"Card" | "IconCard"
"Slot" | "IconSlot"

### Built in Pickups
ID | IconID | IconGroup | Priority
-- | ------ | --------- | --------
"WhiteHeart" | "WhiteHeart" | "hearts" | 10900
"GoldHeart" | "GoldHeart" | "hearts" | 10800
"BoneHeart" | "BoneHeart" | "hearts" | 10700
"BlackHeart" | "BlackHeart" | "hearts" | 10600
"BlueHeart" | "BlueHeart" | "hearts" | 10500
"BlendedHeart" | "BlendedHeart" | "hearts" | 10400
"HalfBlueHeart" | "HalfBlueHeart" | "hearts" | 10300
"ScaredHeart" | "Heart" | "hearts" | 10200
"Heart" | "Heart" | "hearts" | 10100
"HalfHeart" | "HalfHeart" | "hearts" | 10000
"Item" | "Item" | "collectibles" | 9000
"Trinket" | "Trinket" | "collectibles" | 8000
"EternalChest" | "EternalChest" | "chests" | 7500
"GoldChest" | "GoldChest" | "chests" | 7400
"RedChest" | "RedChest" | "chests" | 7300
"Chest" | "Chest" | "chests" | 7200
"StoneChest" | "StoneChest" | "chests" | 7100
"SpikedChest" | "SpikedChest" | "chests" | 7000
"Pill" | "Pill" | "pills" | 6000
"Key" | "Key" | "keys" | 5000
"Bomb" | "Bomb" | "bombs" | 4000
"Coin" | "Coin" | "coins" | 3000
"Battery" | "Battery" | "batteries" | 2000
"Card" | "Card" | "cards" | 1000
"Slot" | "Slot" | "slots" | 0
