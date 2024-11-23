local MinimapAPI = require("scripts.minimapapi")

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

MinimapAPI.RoomShapeRectangles = {
	[RS.ROOMSHAPE_1x1] = {Vector(0,0),Vector(1,1)},
	[RS.ROOMSHAPE_1x2] = {Vector(0,0),Vector(1,2)},
	[RS.ROOMSHAPE_2x1] = {Vector(0,0),Vector(2,1)},
	[RS.ROOMSHAPE_2x2] = {Vector(0,0),Vector(2,2)},
	[RS.ROOMSHAPE_IH] = {Vector(0,0),Vector(1,1)},
	[RS.ROOMSHAPE_IIH] = {Vector(0,0),Vector(2,1)},
	[RS.ROOMSHAPE_IV] = {Vector(0,0),Vector(1,1)},
	[RS.ROOMSHAPE_IIV] = {Vector(0,0),Vector(1,2)},
	[RS.ROOMSHAPE_LBR] = {Vector(0,0),Vector(1,2), Vector(1,0), Vector(2,1)},
	[RS.ROOMSHAPE_LTL] = {Vector(0,0),Vector(1,2), Vector(-1,1), Vector(0,2)},
	[RS.ROOMSHAPE_LTR] = {Vector(0,0),Vector(1,2), Vector(1,1), Vector(2,2)},
	[RS.ROOMSHAPE_LBL] = {Vector(0,0),Vector(2,1), Vector(1,1), Vector(2,2)},
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
	[RoomType.ROOM_DEFAULT] = nil,
    [RoomType.ROOM_SHOP] = "Shop",
    [RoomType.ROOM_ERROR] = nil,
    [RoomType.ROOM_TREASURE] = "TreasureRoom",
    [RoomType.ROOM_BOSS] = "Boss",
    [RoomType.ROOM_MINIBOSS] = "Miniboss",
    [RoomType.ROOM_SECRET] = "SecretRoom",
    [RoomType.ROOM_SUPERSECRET] = "SuperSecretRoom",
    [RoomType.ROOM_ARCADE] = "Arcade",
    [RoomType.ROOM_CURSE] = "CurseRoom",
    [RoomType.ROOM_CHALLENGE] = "AmbushRoom",
    [RoomType.ROOM_LIBRARY] = "Library",
    [RoomType.ROOM_SACRIFICE] = "SacrificeRoom",
    [RoomType.ROOM_DEVIL] = "DevilRoom",
    [RoomType.ROOM_ANGEL] = "AngelRoom",
    [RoomType.ROOM_DUNGEON] = nil,
    [RoomType.ROOM_BOSSRUSH] = "BossAmbushRoom",
    [RoomType.ROOM_ISAACS] = "IsaacsRoom",
    [RoomType.ROOM_BARREN] = "BarrenRoom",
    [RoomType.ROOM_CHEST] = "ChestRoom",
    [RoomType.ROOM_DICE] = "DiceRoom",
    [RoomType.ROOM_BLACK_MARKET] = nil,
    [RoomType.ROOM_GREED_EXIT] = nil,
}
if MinimapAPI.isRepentance then
	MinimapAPI.RoomTypeIconIDs[RoomType.ROOM_PLANETARIUM] = "Planetarium"
	MinimapAPI.RoomTypeIconIDs[RoomType.ROOM_TELEPORTER] = "TeleporterRoom"
	MinimapAPI.RoomTypeIconIDs[RoomType.ROOM_TELEPORTER_EXIT] = "TeleporterRoom"
	MinimapAPI.RoomTypeIconIDs[RoomType.ROOM_SECRET_EXIT] = nil
	MinimapAPI.RoomTypeIconIDs[RoomType.ROOM_BLUE] = nil
	MinimapAPI.RoomTypeIconIDs[RoomType.ROOM_ULTRASECRET] = "UltraSecretRoom"
end

MinimapAPI.UnknownRoomTypeIconIDs = {
    [RoomType.ROOM_SHOP] = "LockedRoom",
    [RoomType.ROOM_SECRET] = "SecretRoom",
    [RoomType.ROOM_SUPERSECRET] = "SuperSecretRoom",
	[RoomType.ROOM_LIBRARY] = "LockedRoom",
    [RoomType.ROOM_ISAACS] = "LockedRoom",
    [RoomType.ROOM_BARREN] = "LockedRoom",
    [RoomType.ROOM_CHEST] = "LockedRoom",
    [RoomType.ROOM_DICE] = "LockedRoom",
}
if MinimapAPI.isRepentance then
	MinimapAPI.UnknownRoomTypeIconIDs[RoomType.ROOM_ULTRASECRET] = "UltraSecretRoom"
end

MinimapAPI.RoomTypeDisplayFlagsAdjacent = {
	[RoomType.ROOM_SHOP] = 3,
	[RoomType.ROOM_MINIBOSS] = 1,
	[RoomType.ROOM_SECRET] = 0,
	[RoomType.ROOM_SUPERSECRET] = 0,
	[RoomType.ROOM_LIBRARY] = 3,
	[RoomType.ROOM_SACRIFICE] = 1,
	[RoomType.ROOM_ISAACS] = 3,
	[RoomType.ROOM_BARREN] = 3,
	[RoomType.ROOM_CHEST] = 3,
	[RoomType.ROOM_DICE] = 3,
}
if MinimapAPI.isRepentance then
	MinimapAPI.RoomTypeDisplayFlagsAdjacent[RoomType.ROOM_ULTRASECRET] = 0
end

local function notCollected(pickup) return not pickup:GetSprite():IsPlaying("Collect") end
local function chestNotCollected(pickup) return pickup.SubType ~= 0 end
local function slotNotDead(pickup) 
	local sprite = pickup:GetSprite()
	local animations = {"Death", "Broken", "CoinJam", "CoinJam2", "CoinJam3", "CoinJam4"}
	for _,anim in ipairs(animations) do
		if sprite:IsPlaying(anim) or sprite:IsFinished(anim) then
			return false
		end
	end
	return true
end

MinimapAPI.PickupNotCollected = notCollected
MinimapAPI.PickupChestNotCollected = chestNotCollected
MinimapAPI.PickupSlotMachineNotBroken = slotNotDead

MinimapAPI.PickupList = {
	["WhiteHeart"] = {IconID="WhiteHeart",Type=5,Variant=10,SubType=4,Call=notCollected,IconGroup="hearts",Priority=14900},
	["GoldHeart"] = {IconID="GoldHeart",Type=5,Variant=10,SubType=7,Call=notCollected,IconGroup="hearts",Priority=14800},
	["BoneHeart"] = {IconID="BoneHeart",Type=5,Variant=10,SubType=11,Call=notCollected,IconGroup="hearts",Priority=14700},
	["BlackHeart"] = {IconID="BlackHeart",Type=5,Variant=10,SubType=6,Call=notCollected,IconGroup="hearts",Priority=14600},
	["BlueHeart"] = {IconID="BlueHeart",Type=5,Variant=10,SubType=3,Call=notCollected,IconGroup="hearts",Priority=14500},
	["BlendedHeart"] = {IconID="BlendedHeart",Type=5,Variant=10,SubType=10,Call=notCollected,IconGroup="hearts",Priority=14400},
	["HalfBlueHeart"] = {IconID="HalfBlueHeart",Type=5,Variant=10,SubType=8,Call=notCollected,IconGroup="hearts",Priority=14300},
	["RottenHeart"] = {IconID="RottenHeart",Type=5,Variant=10,SubType=12,Call=notCollected,IconGroup="hearts",Priority=14200},
	["ScaredHeart"] = {IconID="Heart",Type=5,Variant=10,SubType=9,Call=notCollected,IconGroup="hearts",Priority=14100},
	["DoubleHeart"] = {IconID="Heart",Type=5,Variant=10,SubType=5,Call=notCollected,IconGroup="hearts",Priority=14100},
	["Heart"] = {IconID="Heart",Type=5,Variant=10,SubType=1,Call=notCollected,IconGroup="hearts",Priority=14100},
	["HalfHeart"] = {IconID="HalfHeart",Type=5,Variant=10,SubType=2,Call=notCollected,IconGroup="hearts",Priority=14000},

	["Item"] = {IconID="Item",Type=5,Variant=100,SubType=-1,Call=function(pickup) return pickup.SubType ~= 0 end,IconGroup="collectibles",Priority=13000},

	["Trinket"] = {IconID="Trinket",Type=5,Variant=350,SubType=-1,IconGroup="trinkets",Priority=12000},

	["MegaChest"] = {IconID="MegaChest",Type=5,Variant=57,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=11900},
	["GoldChest"] = {IconID="GoldChest",Type=5,Variant=60,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=11800},
	["EternalChest"] = {IconID="EternalChest",Type=5,Variant=53,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=11700},
	["WoodenChest"] = {IconID="WoodenChest",Type=5,Variant=56,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=11600},
	["RedChest"] = {IconID="RedChest",Type=5,Variant=360,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=11500},
	["Chest"] = {IconID="Chest",Type=5,Variant=50,SubType=-1,Call=chestNotCollected,IconGroup="chests",Priority=11400},
	["BlackGrabBag"] = {IconID="BlackSack",Type=5,Variant=69,SubType=2,Call=notCollected,IconGroup="chests",Priority=11300},
	["GrabBag"] = {IconID="Sack",Type=5,Variant=69,SubType=1,Call=notCollected,IconGroup="chests",Priority=11200},
	["StoneChest"] = {IconID="StoneChest",Type=5,Variant=51,Call=chestNotCollected,SubType=-1,IconGroup="chests",Priority=11100},
	["SpikedChest"] = {IconID="SpikedChest",Type=5,Variant=52,Call=chestNotCollected,SubType=-1,IconGroup="chests",Priority=11000},
	["HauntedChest"] = {IconID="SpikedChest",Type=5,Variant=58,Call=chestNotCollected,SubType=-1,IconGroup="chests",Priority=11000},
	["MimicChest"] = {IconID="SpikedChest",Type=5,Variant=54,Call=chestNotCollected,SubType=-1,IconGroup="chests",Priority=11000},
	
	["Rune"] = {IconID="Rune",Type=5,Variant=300,SubType=-1,Call=notCollected,IconGroup="runes",Priority=10000,Condition=function(pickup)
		return MinimapAPI.isRepentance and Isaac.GetChallenge() ~= Challenge.CHALLENGE_CANTRIPPED and Isaac.GetItemConfig():GetCard(pickup.SubType):IsRune() or (pickup.SubType > 31 and pickup.SubType < 42)
	end},

	["Card"] = {IconID="Card",Type=5,Variant=300,SubType=-1,Call=notCollected,IconGroup="cards",Priority=9000},

	["GoldenPill"] = {IconID="GoldenPill",Type=5,Variant=70,SubType=14,Call=notCollected,IconGroup="pills",Priority=8100},
	["Pill"] = {IconID="Pill",Type=5,Variant=70,SubType=-1,Call=notCollected,IconGroup="pills",Priority=8000},

	["ChargedKey"] = {IconID="ChargedKey",Type=5,Variant=30,SubType=4,Call=notCollected,IconGroup="keys",Priority=7200},
	["GoldenKey"] = {IconID="GoldenKey",Type=5,Variant=30,SubType=2,Call=notCollected,IconGroup="keys",Priority=7100},
	["Key"] = {IconID="Key",Type=5,Variant=30,SubType=-1,Call=notCollected,IconGroup="keys",Priority=7000},

	["GoldenBomb"] = {IconID="GoldenBomb",Type=5,Variant=40,SubType=4,Call=notCollected,IconGroup="bombs",Priority=6100},
	["Bomb"] = {IconID="Bomb",Type=5,Variant=40,SubType=-1,Call=notCollected,IconGroup="bombs",Priority=6000},

	["Poop"] = {IconID="Poop",Type=5,Variant=42,SubType=-1,Call=notCollected,IconGroup="poops",Priority=5000},

	["GoldenCoin"] = {IconID="GoldenCoin",Type=5,Variant=20,SubType=7,Call=notCollected,IconGroup="coins",Priority=4300},
	["Dime"] = {IconID="Dime",Type=5,Variant=20,SubType=3,Call=notCollected,IconGroup="coins",Priority=4200},
	["Nickel"] = {IconID="Nickel",Type=5,Variant=20,SubType=2,Call=notCollected,IconGroup="coins",Priority=4100},
	["Coin"] = {IconID="Coin",Type=5,Variant=20,SubType=-1,Call=notCollected,IconGroup="coins",Priority=4000},

	["GoldenBattery"] = {IconID="GoldenBattery",Type=5,Variant=90,SubType=4,Call=notCollected,IconGroup="batteries",Priority=3100},
	["Battery"] = {IconID="Battery",Type=5,Variant=90,SubType=-1,Call=notCollected,IconGroup="batteries",Priority=3000},

	["ChargeBeggar"] = {IconID="ChargeBeggar",Type=6,Variant=13,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2500},
	["BombBeggar"] = {IconID="BombBeggar",Type=6,Variant=9,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2400},
	["KeyBeggar"] = {IconID="KeyBeggar",Type=6,Variant=7,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2300},
	["HellGame"] = {IconID="DemonBeggar",Type=6,Variant=15,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2200},
	["DemonBeggar"] = {IconID="DemonBeggar",Type=6,Variant=5,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2200},
	["RottenBeggar"] = {IconID="RottenBeggar",Type=6,Variant=18,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2100},
	["ShellGame"] = {IconID="Beggar",Type=6,Variant=6,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2000},
	["Beggar"] = {IconID="Beggar",Type=6,Variant=4,SubType=-1,Call=slotNotDead,IconGroup="beggars",Priority=2000},

	["ReviveMachine"] = {IconID="ReviveMachine",Type=6,Variant=19,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1800},
	["Confessional"] = {IconID="Confessional",Type=6,Variant=17,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1700},
	["RestockMachine"] = {IconID="RestockMachine",Type=6,Variant=10,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1600},
	["CraneGame"] = {IconID="CraneGame",Type=6,Variant=16,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1500},
	["FortuneMachine"] = {IconID="FortuneMachine",Type=6,Variant=3,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1400},
	["BloodDonationMachine"] = {IconID="BloodDonationMachine",Type=6,Variant=2,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1300},
	["Slot"] = {IconID="Slot",Type=6,Variant=1,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1200},
	["DonationMachine"] = {IconID="DonationMachine",Type=6,Variant=8,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1100},
	["DressingTable"] = {IconID="DressingTable",Type=6,Variant=12,SubType=-1,Call=slotNotDead,IconGroup="slots",Priority=1000},
}

-- IsPrespawnObject can be used for grid entities that exist on room creation. These objects are mostly defined by very big Type IDs
MinimapAPI.GridEntityList = {
	["Ladder"] = {IconID="Ladder",Type=18,Variant=-1,Priority=0},
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
	{ID="DevilRoom",anim="IconDevilRoom",frame=0},
	{ID="AngelRoom",anim="IconAngelRoom",frame=0},
	{ID="BossAmbushRoom",anim="IconBossAmbushRoom",frame=0},
	{ID="IsaacsRoom",anim="IconIsaacsRoom",frame=0},
	{ID="BarrenRoom",anim="IconBarrenRoom",frame=0},
	{ID="ChestRoom",anim="IconChestRoom",frame=0},
	{ID="DiceRoom",anim="IconDiceRoom",frame=0},
	{ID="TreasureRoomGreed",anim="IconTreasureRoomGreed",frame=0},
	--{ID="GreedExit",anim="",frame=0},  --currently no icon
	{ID="Planetarium",anim="IconPlanetarium",frame=0},
	{ID="TeleporterRoom",anim="IconTeleporterRoom",frame=0}, -- unused in vanilla but some mods may use it
	{ID="TreasureRoomRed",anim="IconTreasureRoomRed",frame=0},
	{ID="UltraSecretRoom",anim="IconUltraSecretRoom",frame=0},
	--Quests
	{ID="MirrorRoom",anim="IconMirrorRoom",frame=0},
	{ID="MinecartRoom",anim="IconMinecartRoom",frame=0},
	--Unknowns
	{ID="LockedRoom",anim="IconLockedRoom",frame=0},
	--Pickups
	{ID="RottenHeart",anim="IconHeart",frame=2},
	{ID="WhiteHeart",anim="IconHeart",frame=9},
	{ID="GoldHeart",anim="IconHeart",frame=8},
	{ID="BoneHeart",anim="IconHeart",frame=7},
	{ID="BlackHeart",anim="IconHeart",frame=6},
	{ID="BlueHeart",anim="IconHeart",frame=5},
	{ID="BlendedHeart",anim="IconHeart",frame=4},
	{ID="HalfBlueHeart",anim="IconHeart",frame=3},
	{ID="Heart",anim="IconHeart",frame=1},
	{ID="HalfHeart",anim="IconHeart",frame=0},
	{ID="Item",anim="IconItem",frame=0},
	{ID="Trinket",anim="IconTrinket",frame=0},
	{ID="Pill",anim="IconPill",frame=0},
	{ID="GoldenPill",anim="IconPill",frame=1},
	{ID="Key",anim="IconKey",frame=0},
	{ID="GoldenKey",anim="IconKey",frame=1},
	{ID="ChargedKey",anim="IconKey",frame=2},
	{ID="Bomb",anim="IconBomb",frame=0},
	{ID="GoldenBomb",anim="IconBomb",frame=1},
	{ID="Coin",anim="IconCoin",frame=0},
	{ID="Nickel",anim="IconCoin",frame=1},
	{ID="Dime",anim="IconCoin",frame=2},
	{ID="GoldenCoin",anim="IconCoin",frame=3},
	{ID="Battery",anim="IconBattery",frame=0},
	{ID="GoldenBattery",anim="IconBattery",frame=1},
	{ID="Card",anim="IconCard",frame=0},
	{ID="Rune",anim="IconRune",frame=0},
	{ID="Poop",anim="IconPoop",frame=0},
	--Chests

	{ID="MegaChest",anim="IconChest",frame=9},
	{ID="WoodenChest",anim="IconChest",frame=6},
	{ID="EternalChest",anim="IconChest",frame=7},
	{ID="GoldChest",anim="IconChest",frame=8},
	{ID="RedChest",anim="IconChest",frame=5},
	{ID="Chest",anim="IconChest",frame=4},
	{ID="BlackSack",anim="IconChest",frame=3},
	{ID="Sack",anim="IconChest",frame=2},
	{ID="StoneChest",anim="IconChest",frame=1},
	{ID="SpikedChest",anim="IconChest",frame=0},
	--Slots
	{ID="DressingTable",anim="IconSlot",frame=0},
	{ID="DonationMachine",anim="IconSlot",frame=1},
	{ID="Slot",anim="IconSlot",frame=2},
	{ID="BloodDonationMachine",anim="IconSlot",frame=3},
	{ID="FortuneMachine",anim="IconSlot",frame=4},
	{ID="CraneGame",anim="IconSlot",frame=5},
	{ID="RestockMachine",anim="IconSlot",frame=6},
	{ID="Confessional",anim="IconSlot",frame=7},
	{ID="ReviveMachine",anim="IconSlot",frame=8},
	{ID="Beggar",anim="IconBeggar",frame=0},
	{ID="RottenBeggar",anim="IconBeggar",frame=1},
	{ID="DemonBeggar",anim="IconBeggar",frame=2},
	{ID="KeyBeggar",anim="IconBeggar",frame=3},
	{ID="BombBeggar",anim="IconBeggar",frame=4},
	{ID="ChargeBeggar",anim="IconBeggar",frame=5},
	--Misc
	{ID="Ladder",anim="IconLadder",frame=0},
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

-- Map indicators, Added each flag from custom_mapflags.lua
MinimapAPI.MapFlags = {
	--[[
	id: used to identify the flag
	condition: return true to render the indicator
	sprite: Mods should supply their own Sprite object where they load a custom anm2
	anim: the name of the animation. "icons" for the regular icons
	frame: frame of the icon. Can also be a function that returns a frame for indicators that might change frames (like zodiac indicator)
	--]]
}
