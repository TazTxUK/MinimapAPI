local RS = RoomShape

MinimapAPI.RoomShapeFrames = {
	[RS.ROOMSHAPE_1x1] = 0,
	[RS.ROOMSHAPE_1x2] = 3,
	[RS.ROOMSHAPE_2x1] = 5,
	[RS.ROOMSHAPE_2x2] = 7,
	[RS.ROOMSHAPE_IH] = 1,
	[RS.ROOMSHAPE_IIH] = 6,
	[RS.ROOMSHAPE_IV] = 2,
	[RS.ROOMSHAPE_IIV] = 4,
	[RS.ROOMSHAPE_LBR] = 11,
	[RS.ROOMSHAPE_LTL] = 8,
	[RS.ROOMSHAPE_LTR] = 9,
	[RS.ROOMSHAPE_LBL] = 10,
}

MinimapAPI.RoomShapeGridPivots = {
	[RS.ROOMSHAPE_1x1] = Vector(0,0),
	[RS.ROOMSHAPE_1x2] = Vector(0,0),
	[RS.ROOMSHAPE_2x1] = Vector(0,0),
	[RS.ROOMSHAPE_2x2] = Vector(0,0),
	[RS.ROOMSHAPE_IH] = Vector(0,0),
	[RS.ROOMSHAPE_IIH] = Vector(0,0),
	[RS.ROOMSHAPE_IV] = Vector(0,0),
	[RS.ROOMSHAPE_IIV] = Vector(0,0),
	[RS.ROOMSHAPE_LBR] = Vector(0,0),
	[RS.ROOMSHAPE_LTL] = Vector(1,0),
	[RS.ROOMSHAPE_LTR] = Vector(0,0),
	[RS.ROOMSHAPE_LBL] = Vector(0,0),
}

MinimapAPI.RoomShapeGridSizes = {
	[RS.ROOMSHAPE_1x1] = Vector(1,1),
	[RS.ROOMSHAPE_1x2] = Vector(1,2),
	[RS.ROOMSHAPE_2x1] = Vector(2,1),
	[RS.ROOMSHAPE_2x2] = Vector(2,2),
	[RS.ROOMSHAPE_IH] = Vector(1,1),
	[RS.ROOMSHAPE_IIH] = Vector(2,1),
	[RS.ROOMSHAPE_IV] = Vector(1,1),
	[RS.ROOMSHAPE_IIV] = Vector(1,2),
	[RS.ROOMSHAPE_LBR] = Vector(2,2),
	[RS.ROOMSHAPE_LTL] = Vector(2,2),
	[RS.ROOMSHAPE_LTR] = Vector(2,2),
	[RS.ROOMSHAPE_LBL] = Vector(2,2),
}


MinimapAPI.RoomShapePositions = {
	[RS.ROOMSHAPE_1x1] = {Vector(0,0)},
	[RS.ROOMSHAPE_1x2] = {Vector(0,0),Vector(0,1)},
	[RS.ROOMSHAPE_2x1] = {Vector(0,0),Vector(1,0)},
	[RS.ROOMSHAPE_2x2] = {Vector(0,0),Vector(1,0),Vector(0,1),Vector(1,1)},
	[RS.ROOMSHAPE_IH] = {Vector(0,0)},
	[RS.ROOMSHAPE_IIH] = {Vector(0,0),Vector(1,0)},
	[RS.ROOMSHAPE_IV] = {Vector(0,0)},
	[RS.ROOMSHAPE_IIV] = {Vector(0,0),Vector(0,1)},
	[RS.ROOMSHAPE_LBR] = {Vector(0,0),Vector(1,0),Vector(0,1)},
	[RS.ROOMSHAPE_LTL] = {Vector(0,0),Vector(-1,1),Vector(0,1)},
	[RS.ROOMSHAPE_LTR] = {Vector(0,0),Vector(0,1),Vector(1,1)},
	[RS.ROOMSHAPE_LBL] = {Vector(0,0),Vector(1,0),Vector(1,1)},
}

MinimapAPI.RoomShapeIconPositions = {
	[1] = { -- iconcount <= 1
		[RS.ROOMSHAPE_1x1] = {Vector(0,0)},
		[RS.ROOMSHAPE_1x2] = {Vector(0,0.5)},
		[RS.ROOMSHAPE_2x1] = {Vector(0.5,0)},
		[RS.ROOMSHAPE_2x2] = {Vector(0.5,0.5)},
		[RS.ROOMSHAPE_IH] = {Vector(0,0)},
		[RS.ROOMSHAPE_IIH] = {Vector(0.5,0)},
		[RS.ROOMSHAPE_IV] = {Vector(0,0)},
		[RS.ROOMSHAPE_IIV] = {Vector(0,0.5)},
		[RS.ROOMSHAPE_LBR] = {Vector(0,0),Vector(1,0),Vector(0,1)},
		[RS.ROOMSHAPE_LTL] = {Vector(0,0),Vector(-1,1),Vector(0,1)},
		[RS.ROOMSHAPE_LTR] = {Vector(0,0),Vector(0,1),Vector(1,1)},
		[RS.ROOMSHAPE_LBL] = {Vector(0,0),Vector(1,0),Vector(1,1)},
	},
	[2] = { -- iconcount > 1
		[RS.ROOMSHAPE_1x1] = {Vector(0,0)},
		[RS.ROOMSHAPE_1x2] = {Vector(0,0),Vector(0,1)},
		[RS.ROOMSHAPE_2x1] = {Vector(0,0),Vector(1,0)},
		[RS.ROOMSHAPE_2x2] = {Vector(0,0),Vector(1,0),Vector(0,1),Vector(1,1)},
		[RS.ROOMSHAPE_IH] = {Vector(0,0)},
		[RS.ROOMSHAPE_IIH] = {Vector(0,0),Vector(1,0)},
		[RS.ROOMSHAPE_IV] = {Vector(0,0)},
		[RS.ROOMSHAPE_IIV] = {Vector(0,0),Vector(0,1)},
		[RS.ROOMSHAPE_LBR] = {Vector(0,0),Vector(1,0),Vector(0,1)},
		[RS.ROOMSHAPE_LTL] = {Vector(0,0),Vector(-1,1),Vector(0,1)},
		[RS.ROOMSHAPE_LTR] = {Vector(0,0),Vector(0,1),Vector(1,1)},
		[RS.ROOMSHAPE_LBL] = {Vector(0,0),Vector(1,0),Vector(1,1)},
	},
}

MinimapAPI.LargeRoomShapeIconPositions = {
	[1] = { -- iconcount <= 1
		[RS.ROOMSHAPE_1x1] = {Vector(0.25,0.25)},
		[RS.ROOMSHAPE_1x2] = {Vector(0.25,0.75)},
		[RS.ROOMSHAPE_2x1] = {Vector(0.75,0.25)},
		[RS.ROOMSHAPE_2x2] = {Vector(0.75,0.75)},
		[RS.ROOMSHAPE_IH] = {Vector(0.25,0.25)},
		[RS.ROOMSHAPE_IIH] = {Vector(0.75,0.25)},
		[RS.ROOMSHAPE_IV] = {Vector(0.25,0.25)},
		[RS.ROOMSHAPE_IIV] = {Vector(0.25,0.75)},
		[RS.ROOMSHAPE_LBR] = {Vector(0.25,0.25)},
		[RS.ROOMSHAPE_LTL] = {Vector(0.25,1.25)},
		[RS.ROOMSHAPE_LTR] = {Vector(0.25,1.25)},
		[RS.ROOMSHAPE_LBL] = {Vector(1.25,0.25)},
	},
	[2] = { -- iconcount == 2
		[RS.ROOMSHAPE_1x1] = {Vector(0,0.25),Vector(0.5,0.25)},
		[RS.ROOMSHAPE_1x2] = {Vector(0,0.75),Vector(0.5,0.75)},
		[RS.ROOMSHAPE_2x1] = {Vector(0.5,0.25),Vector(1,0.25)},
		[RS.ROOMSHAPE_2x2] = {Vector(0.5,0.75),Vector(1,0.75)},
		[RS.ROOMSHAPE_IH] = {Vector(0,0.25),Vector(0.5,0.25)},
		[RS.ROOMSHAPE_IIH] = {Vector(0.5,0.25),Vector(1,0.25)},
		[RS.ROOMSHAPE_IV] = {Vector(0,0.25),Vector(0.5,0.25)},
		[RS.ROOMSHAPE_IIV] = {Vector(0,0.75),Vector(0.5,0.75)},
		[RS.ROOMSHAPE_LBR] = {Vector(0,0.25),Vector(0.5,0.25)},
		[RS.ROOMSHAPE_LTL] = {Vector(0,1.25),Vector(0.5,1.25)},
		[RS.ROOMSHAPE_LTR] = {Vector(0,1.25),Vector(0.5,1.25)},
		[RS.ROOMSHAPE_LBL] = {Vector(1,0.25),Vector(1.5,0.25)},
	},
	[3] = { -- iconcount >= 3
		[RS.ROOMSHAPE_1x1] = {Vector(0,0),Vector(0.5,0),Vector(0,0.5),Vector(0.5,0.5)},
		[RS.ROOMSHAPE_1x2] = {Vector(0,0.5),Vector(0.5,1),Vector(0,1),Vector(0.5,0.5)},
		[RS.ROOMSHAPE_2x1] = {Vector(0.5,0),Vector(1,0),Vector(0.5,0.5),Vector(1,0.5)},
		[RS.ROOMSHAPE_2x2] = {Vector(0.5,0.5),Vector(1,0.5),Vector(0.5,1),Vector(1,1)},
		[RS.ROOMSHAPE_IH] = {Vector(0,0),Vector(0.5,0),Vector(0,0.5),Vector(0.5,0.5)},
		[RS.ROOMSHAPE_IIH] = {Vector(0.5,0),Vector(1,0),Vector(0.5,0.5),Vector(1,0.5)},
		[RS.ROOMSHAPE_IV] = {Vector(0,0),Vector(0.5,0),Vector(0,0.5),Vector(0.5,0.5)},
		[RS.ROOMSHAPE_IIV] = {Vector(0,0.5),Vector(0.5,1),Vector(0,1),Vector(0.5,1)},
		[RS.ROOMSHAPE_LBR] = {Vector(0,0),Vector(0.5,0),Vector(0,0.5),Vector(0.5,0.5)},
		[RS.ROOMSHAPE_LTL] = {Vector(-0.1,0.9),Vector(0.4,0.9),Vector(-0.1,1.4),Vector(0.4,1.4)},
		[RS.ROOMSHAPE_LTR] = {Vector(0,1),Vector(0.5,1),Vector(0,1.5),Vector(0.5,1.5)},
		[RS.ROOMSHAPE_LBL] = {Vector(0.9,0),Vector(1.4,0),Vector(0.9,0.5),Vector(1.4,0.5)},
	},
}

MinimapAPI.RoomTypeIconIDs = {
	nil,
    "Shop",
    nil,
    "TreasureRoom",
    "Boss",
    "Miniboss",
    "SecretRoom",
    "SuperSecretRoom",
    "Arcade",
    "CurseRoom",
    "AmbushRoom",
    "Library",
    "SacrificeRoom",
    nil,
    "AngelRoom",
    nil,
    "BossAmbushRoom",
    "IsaacsRoom",
    "BarrenRoom",
    "ChestRoom",
    "DiceRoom",
    nil,
    nil,-- "GreedExit",
    "TreasureRoomGreed"
}

MinimapAPI.UnknownRoomTypeIconIDs = {
	nil,
    "LockedRoom",
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    "LockedRoom",
    nil,
    nil,
    nil,
    nil,
    nil,
    "LockedRoom",
    "LockedRoom",
    "LockedRoom",
    "LockedRoom",
    nil,
    nil,
    nil,
}

local RT = RoomType
MinimapAPI.RoomTypeDisplayFlagsAdjacent = {
	[RT.ROOM_SHOP] = 3,
	[RT.ROOM_MINIBOSS] = 1,
	[RT.ROOM_SECRET] = 0,
	[RT.ROOM_SUPERSECRET] = 0,
	[RT.ROOM_LIBRARY] = 3,
	[RT.ROOM_SACRIFICE] = 1,
	[RT.ROOM_ISAACS] = 3,
	[RT.ROOM_BARREN] = 3,
	[RT.ROOM_CHEST] = 3,
	[RT.ROOM_DICE] = 3,
}

local function notCollected(pickup) return not pickup:GetSprite():IsPlaying("Collect") end
local function chestNotCollected(pickup) return pickup.SubType ~= 0 end
local function slotNotDead(pickup) return not (pickup:GetSprite():IsPlaying("Death") or pickup:GetSprite():IsPlaying("Broken")) end
local function dresserNotDead(pickup) return not (pickup:GetSprite():IsFinished("Broken")) end

MinimapAPI.PickupNotCollected = notCollected
MinimapAPI.PickupChestNotCollected = chestNotCollected
MinimapAPI.PickupSlotMachineNotBroken = slotNotDead
MinimapAPI.PickupDresserNotDead = dresserNotDead

MinimapAPI.PickupList = {
	{ID="WhiteHeart",IconID="WhiteHeart",Type=5,Variant=10,SubType=4,Call=notCollected,IconGroup="hearts",Priority=10900},
	{ID="GoldHeart",IconID="GoldHeart",Type=5,Variant=10,SubType=7,Call=notCollected,IconGroup="hearts",Priority=10800},
	{ID="BoneHeart",IconID="BoneHeart",Type=5,Variant=10,SubType=11,Call=notCollected,IconGroup="hearts",Priority=10700},
	{ID="BlackHeart",IconID="BlackHeart",Type=5,Variant=10,SubType=6,Call=notCollected,IconGroup="hearts",Priority=10600},
	{ID="BlueHeart",IconID="BlueHeart",Type=5,Variant=10,SubType=3,Call=notCollected,IconGroup="hearts",Priority=10500},
	{ID="BlendedHeart",IconID="BlendedHeart",Type=5,Variant=10,SubType=10,Call=notCollected,IconGroup="hearts",Priority=10400},
	{ID="HalfBlueHeart",IconID="HalfBlueHeart",Type=5,Variant=10,SubType=8,Call=notCollected,IconGroup="hearts",Priority=10300},
	{ID="ScaredHeart",IconID="Heart",Type=5,Variant=10,SubType=9,Call=notCollected,IconGroup="hearts",Priority=10100},
	{ID="DoubleHeart",IconID="Heart",Type=5,Variant=10,SubType=5,Call=notCollected,IconGroup="hearts",Priority=10100},
	{ID="Heart",IconID="Heart",Type=5,Variant=10,SubType=1,Call=notCollected,IconGroup="hearts",Priority=10100},
	{ID="HalfHeart",IconID="HalfHeart",Type=5,Variant=10,SubType=2,Call=notCollected,IconGroup="hearts",Priority=10000},
	{ID="Item",IconID="Item",Type=5,Variant=100,SubType=-1,Call=function(pickup) return pickup.SubType ~= 0 end,IconGroup="collectibles",Priority=9000},
	{ID="Trinket",IconID="Trinket",Type=5,Variant=350,SubType=-1,IconGroup="collectibles",Priority=8000},
	{ID="EternalChest",IconID="EternalChest",Type=5,Variant=53,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=7600},
	{ID="GoldChest",IconID="GoldChest",Type=5,Variant=60,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=7500},
	{ID="RedChest",IconID="RedChest",Type=5,Variant=360,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=7400},
	{ID="Chest",IconID="Chest",Type=5,Variant=50,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=7300},
	{ID="StoneChest",IconID="StoneChest",Type=5,Variant=51,Call=chestNotCollected,SubType=-1,IconGroup="chests",Priority=7200},
	{ID="SpikedChest",IconID="SpikedChest",Type=5,Variant=52,Call=chestNotCollected,SubType=-1,IconGroup="chests",Priority=7100},
	{ID="MimicChest",IconID="SpikedChest",Type=5,Variant=54,Call=chestNotCollected,SubType=-1,IconGroup="chests",Priority=7000},
	{ID="GrabBag",IconID="Sack",Type=5,Variant=69,SubType=-1,Call=notCollected,IconGroup="grabbags",Priority=6500},
	{ID="Pill",IconID="Pill",Type=5,Variant=70,SubType=-1,Call=notCollected,IconGroup="pills",Priority=6000},
	{ID="Key",IconID="Key",Type=5,Variant=30,SubType=-1,Call=notCollected,IconGroup="keys",Priority=5000},
	{ID="Bomb",IconID="Bomb",Type=5,Variant=40,SubType=-1,Call=notCollected,IconGroup="bombs",Priority=4000},
	{ID="Coin",IconID="Coin",Type=5,Variant=20,SubType=-1,Call=notCollected,IconGroup="coins",Priority=3000},
	{ID="Battery",IconID="Battery",Type=5,Variant=90,SubType=-1,Call=notCollected,IconGroup="batteries",Priority=2000},
	{ID="Card",IconID="Card",Type=5,Variant=300,SubType=-1,Call=notCollected,IconGroup="cards",Priority=1000},
	{ID="Slot",IconID="Slot",Type=6,Variant=-1,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=0},
}

MinimapAPI.IconList = {
	{ID="Shop",anim="IconShop",frame=0},
	{ID="TreasureRoom",anim="IconTreasureRoom",frame=0},
    {ID="Boss",anim="IconBoss",frame=0},
    {ID="Miniboss",anim="IconMiniboss",frame=0},
    {ID="SecretRoom",anim="IconSecretRoom",frame=0},
    {ID="SuperSecretRoom",anim="IconSuperSecretRoom",frame=0},
    {ID="Arcade",anim="IconArcade",frame=0},
    {ID="CurseRoom",anim="IconCurseRoom",frame=0},
    {ID="AmbushRoom",anim="IconAmbushRoom",frame=0},
    {ID="Library",anim="IconLibrary",frame=0},
    {ID="SacrificeRoom",anim="IconSacrificeRoom",frame=0},
    {ID="AngelRoom",anim="IconAngelRoom",frame=0},
    {ID="BossAmbushRoom",anim="IconBossAmbushRoom",frame=0},
    {ID="IsaacsRoom",anim="IconIsaacsRoom",frame=0},
    {ID="BarrenRoom",anim="IconBarrenRoom",frame=0},
    {ID="ChestRoom",anim="IconChestRoom",frame=0},
    {ID="DiceRoom",anim="IconDiceRoom",frame=0},
    --{ID="GreedExit",anim="",frame=0},  --currently no icon
    {ID="TreasureRoomGreed",anim="IconTreasureRoomGreed",frame=0},
	--Unknowns
    {ID="LockedRoom",anim="IconLockedRoom",frame=0},
	--Pickups
	{ID="WhiteHeart",anim="IconWhiteHeart",frame=0},
	{ID="GoldHeart",anim="IconGoldHeart",frame=0},
	{ID="BoneHeart",anim="IconBoneHeart",frame=0},
	{ID="BlackHeart",anim="IconBlackHeart"},
	{ID="BlueHeart",anim="IconBlueHeart",frame=0},
	{ID="BlendedHeart",anim="IconBlendedHeart",frame=0},
	{ID="HalfBlueHeart",anim="IconHalfBlueHeart",frame=0},
	{ID="Heart",anim="IconHeart",frame=0},
	{ID="HalfHeart",anim="IconHalfHeart",frame=0},
	{ID="Item",anim="IconItem",frame=0},
	{ID="Trinket",anim="IconTrinket",frame=0},
	{ID="EternalChest",anim="IconEternalChest",frame=0},
	{ID="GoldChest",anim="IconGoldChest",frame=0},
	{ID="RedChest",anim="IconRedChest",frame=0},
	{ID="Chest",anim="IconChest",frame=0},
	{ID="StoneChest",anim="IconStoneChest",frame=0},
	{ID="SpikedChest",anim="IconSpikedChest",frame=0},
	{ID="Pill",anim="IconPill",frame=0},
	{ID="Key",anim="IconKey",frame=0},
	{ID="Bomb",anim="IconBomb",frame=0},
	{ID="Coin",anim="IconCoin",frame=0},
	{ID="Battery",anim="IconBattery",frame=0},
	{ID="Card",anim="IconCard",frame=0},
	{ID="Slot",anim="IconSlot",frame=0},
	{ID="Sack",anim="IconSack",frame=0},
}

MinimapAPI.RoomShapeAdjacentCoords = {

	{Vector(-1, 0), Vector(0, -1), Vector(1, 0), Vector(0, 1)}, -- ROOMSHAPE_1x1 
	{Vector(-1, 0),Vector(1, 0)}, -- ROOMSHAPE_IH  
	{Vector(0, -1),Vector(0, 1)}, -- ROOMSHAPE_IV  
	{Vector(-1, 0), Vector(0, -1), Vector(1, 0), Vector(0, 2), Vector(-1, 1), Vector(1, 1)}, -- ROOMSHAPE_1x2  
	{Vector(0, -1), Vector(0, 2)}, -- ROOMSHAPE_IIV  
	{Vector(-1, 0),Vector(0, -1),Vector(2, 0),Vector(0, 1),Vector(-1, 0),Vector(1, -1),Vector(2, 0),Vector(1, 1)}, -- ROOMSHAPE_2x1  
	{Vector(-1, 0),Vector(2,0)}, -- ROOMSHAPE_IIH  
	{Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,2),Vector(-1,1),Vector(1,-1),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_2x2  
	{Vector(-1,0),Vector(1,0),Vector(-1,2),Vector(-2,1),Vector(0,-1),Vector(1,1),Vector(0,2)}, -- ROOMSHAPE_LTL
	{Vector(-1,0),Vector(0,-1),Vector(1,0),Vector(0,2),Vector(-1,1),Vector(1,0),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_LTR  
	{Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,1),Vector(0,1),Vector(1,-1),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_LBL  
	{Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,2),Vector(-1,1),Vector(1,-1),Vector(1,1),Vector(1,1)} -- ROOMSHAPE_LBR  

}

MinimapAPI.RoomShapeDoorCoords = {

-- L0 		UP0		R0		D0		L1		UP1		R1		D1
	{Vector(-1, 0), Vector(0, -1), Vector(1, 0), Vector(0, 1),nil,nil,nil,nil}, -- ROOMSHAPE_1x1 
	{Vector(-1, 0),nil,Vector(1, 0),nil,nil,nil,nil,nil}, -- ROOMSHAPE_IH  
	{nil,Vector(0, -1),nil,Vector(0, 1),nil,nil,nil,nil}, -- ROOMSHAPE_IV  
	{Vector(-1, 0), Vector(0, -1), Vector(1, 0), Vector(0, 2), Vector(-1, 1),nil, Vector(1, 1),nil}, -- ROOMSHAPE_1x2  
	{nil,Vector(0, -1),nil, Vector(0, 2),nil,nil,nil,nil}, -- ROOMSHAPE_IIV  
	{Vector(-1, 0),Vector(0, -1),Vector(2, 0),Vector(0, 1),Vector(-1, 0),Vector(1, -1),Vector(2, 0),Vector(1, 1)}, -- ROOMSHAPE_2x1  
	{Vector(-1, 0),nil,Vector(2,0),nil,nil,nil,nil,nil}, -- ROOMSHAPE_IIH  
	{Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,2),Vector(-1,1),Vector(1,-1),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_2x2  
	{Vector(-1,0),Vector(-1,0),Vector(1,0),Vector(-1,2),Vector(-2,1),Vector(0,-1),Vector(1,1),Vector(0,2)}, -- ROOMSHAPE_LTL
	{Vector(-1,0),Vector(0,-1),Vector(1,0),Vector(0,2),Vector(-1,1),Vector(1,0),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_LTR  
	{Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,1),Vector(0,1),Vector(1,-1),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_LBL  
	{Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,2),Vector(-1,1),Vector(1,-1),Vector(1,1),Vector(1,1)} -- ROOMSHAPE_LBR  

}

-- Available doorslot ids per roomshape
MinimapAPI.RoomShapeDoorSlots ={
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