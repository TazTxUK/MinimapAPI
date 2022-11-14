local MinimapAPI = require("scripts.minimapapi")

MinimapAPI.CustomIcons = Sprite()
MinimapAPI.CustomIcons:Load("gfx/ui/minimapapi/custom_icons.anm2",true)

--PILLS

MinimapAPI:AddIcon("PillBlueBlue", MinimapAPI.CustomIcons, "CustomIconPillBlueBlue", 0)
MinimapAPI:AddIcon("PillOrangeOrange", MinimapAPI.CustomIcons, "CustomIconPillOrangeOrange", 0)
MinimapAPI:AddIcon("PillWhiteWhite", MinimapAPI.CustomIcons, "CustomIconPillWhiteWhite", 0)
MinimapAPI:AddIcon("PillReddotsRed", MinimapAPI.CustomIcons, "CustomIconPillReddotsRed", 0)
MinimapAPI:AddIcon("PillPinkRed", MinimapAPI.CustomIcons, "CustomIconPillPinkRed", 0)
MinimapAPI:AddIcon("PillBlueCadetblue", MinimapAPI.CustomIcons, "CustomIconPillBlueCadetBlue", 0)
MinimapAPI:AddIcon("PillYellowOrange", MinimapAPI.CustomIcons, "CustomIconPillYellowOrange", 0)
MinimapAPI:AddIcon("PillOrangedotsWhite", MinimapAPI.CustomIcons, "CustomIconPillOrangedotsWhite", 0)
MinimapAPI:AddIcon("PillWhiteAzure", MinimapAPI.CustomIcons, "CustomIconPillWhiteAzure", 0)
MinimapAPI:AddIcon("PillBlackYellow", MinimapAPI.CustomIcons, "CustomIconPillBlackYellow", 0)
MinimapAPI:AddIcon("PillWhiteBlack", MinimapAPI.CustomIcons, "CustomIconPillWhiteBlack", 0)
MinimapAPI:AddIcon("PillWhiteYellow", MinimapAPI.CustomIcons, "CustomIconPillWhiteYellow", 0)

MinimapAPI:AddIcon("DoubleHeart", MinimapAPI.CustomIcons, "CustomIconDoubleHeart", 0)
MinimapAPI:AddIcon("DoublePenny", MinimapAPI.CustomIcons, "CustomIconCoinDouble", 0)
MinimapAPI:AddIcon("Nickel", MinimapAPI.CustomIcons, "CustomIconNickel", 0)
MinimapAPI:AddIcon("Dime", MinimapAPI.CustomIcons, "CustomIconDime", 0)
MinimapAPI:AddIcon("LuckyPenny", MinimapAPI.CustomIcons, "CustomIconLuckyPenny", 0)
MinimapAPI:AddIcon("StickyNickel", MinimapAPI.CustomIcons, "CustomIconNickelSticky", 0)
MinimapAPI:AddIcon("KeyRing", MinimapAPI.CustomIcons, "CustomIconKeyRing", 0)
MinimapAPI:AddIcon("DoubleBomb", MinimapAPI.CustomIcons, "CustomIconDoubleBomb", 0)
MinimapAPI:AddIcon("Trophy", MinimapAPI.CustomIcons, "CustomIconTrophy", 0)
MinimapAPI:AddIcon("CheckeredFlag", MinimapAPI.CustomIcons, "CustomIconFlag", 0)
MinimapAPI:AddIcon("Shovel", MinimapAPI.CustomIcons, "CustomIconShovel", 0)

MinimapAPI:AddIcon("TarotCard", MinimapAPI.CustomIcons, "CustomIconTarotCard", 0)
MinimapAPI:AddIcon("SuitCard", MinimapAPI.CustomIcons, "CustomIconSuitCard", 0)
MinimapAPI:AddIcon("RuneRight", MinimapAPI.CustomIcons, "CustomIconRuneRight", 0)
MinimapAPI:AddIcon("RuneBlack", MinimapAPI.CustomIcons, "CustomIconRuneBlack", 0)
MinimapAPI:AddIcon("CreditCard", MinimapAPI.CustomIcons, "CustomIconCreditCard", 0)
MinimapAPI:AddIcon("GetOutOfJail", MinimapAPI.CustomIcons, "CustomIconGetOutOfJail", 0)
MinimapAPI:AddIcon("CardAgainstHumanity", MinimapAPI.CustomIcons, "CustomIconCardAgainstHumanity", 0)
MinimapAPI:AddIcon("HolyCard", MinimapAPI.CustomIcons, "CustomIconHolyCard", 0)
MinimapAPI:AddIcon("MomsContract", MinimapAPI.CustomIcons, "CustomIconMomsContract", 0)
MinimapAPI:AddIcon("DiceShard", MinimapAPI.CustomIcons, "CustomIconDiceShard", 0)
MinimapAPI:AddIcon("MagicCard", MinimapAPI.CustomIcons, "CustomIconMagicCard", 0)

MinimapAPI:AddIcon("ShellGame", MinimapAPI.CustomIcons, "CustomIconShellGame", 0)
if REPENTANCE then -- Repentance exclusive icons
	MinimapAPI:AddIcon("KeyShard", MinimapAPI.CustomIcons, "CustomIconKeyShard", 0)

	MinimapAPI:AddIcon("ReverseCard", MinimapAPI.CustomIcons, "CustomIconReverseCard", 0)
	for i=0,16 do
		MinimapAPI:AddIcon("Soul"..(i + 81), MinimapAPI.CustomIcons, "CustomIconSouls", i)
	end

	MinimapAPI:AddIcon("UnusCard", MinimapAPI.CustomIcons, "CustomIconUnusCard", 0)

	MinimapAPI:AddIcon("RuneShard", MinimapAPI.CustomIcons, "CustomIconRuneShard", 0)

	MinimapAPI:AddIcon("HellGame", MinimapAPI.CustomIcons, "CustomIconHellGame", 0)

	MinimapAPI:AddIcon("BigPoopNugget", MinimapAPI.CustomIcons, "CustomIconPoop", 1)
	MinimapAPI:AddIcon("WhiteFireplace", MinimapAPI.CustomIcons, "CustomIconWhiteFireplace", 0)
	MinimapAPI:AddIcon("AscentExit", MinimapAPI.CustomIcons, "CustomIconAscentExit", 0)
end

MinimapAPI:AddPickup("PillBlueBlue","PillBlueBlue",5,70,PillColor.PILL_BLUE_BLUE,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillOrangeOrange","PillOrangeOrange",5,70,PillColor.PILL_ORANGE_ORANGE,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillWhiteWhite","PillWhiteWhite",5,70,PillColor.PILL_WHITE_WHITE,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillReddotsRed","PillReddotsRed",5,70,PillColor.PILL_REDDOTS_RED,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillPinkRed","PillPinkRed",5,70,PillColor.PILL_PINK_RED,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillBlueCadetblue","PillBlueCadetblue",5,70,PillColor.PILL_BLUE_CADETBLUE,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillYellowOrange","PillYellowOrange",5,70,PillColor.PILL_YELLOW_ORANGE,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillOrangedotsWhite","PillOrangedotsWhite",5,70,PillColor.PILL_ORANGEDOTS_WHITE,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillWhiteAzure","PillWhiteAzure",5,70,PillColor.PILL_WHITE_AZURE,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillBlackYellow","PillBlackYellow",5,70,PillColor.PILL_BLACK_YELLOW,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillWhiteBlack","PillWhiteBlack",5,70,PillColor.PILL_WHITE_BLACK,MinimapAPI.PickupNotCollected,"pills",6100)
MinimapAPI:AddPickup("PillWhiteYellow","PillWhiteYellow",5,70,PillColor.PILL_WHITE_YELLOW,MinimapAPI.PickupNotCollected,"pills",6100)


MinimapAPI:AddPickup("DoubleHeart","DoubleHeart",5,10,5,MinimapAPI.PickupNotCollected,"hearts",10200)
MinimapAPI:AddPickup("DoublePenny","DoublePenny",5,20,4,MinimapAPI.PickupNotCollected,"coins",3200)
MinimapAPI:AddPickup("Nickel","Nickel",5,20,2,MinimapAPI.PickupNotCollected,"coins",3400)
MinimapAPI:AddPickup("StickyNickel","Nickel",5,20,6,MinimapAPI.PickupNotCollected,"coins",3300)
MinimapAPI:AddPickup("Dime","Dime",5,20,3,MinimapAPI.PickupNotCollected,"coins",3600)
MinimapAPI:AddPickup("LuckyPenny","LuckyPenny",5,20,5,MinimapAPI.PickupNotCollected,"coins",3500)
MinimapAPI:AddPickup("KeyRing","KeyRing",5,30,3,MinimapAPI.PickupNotCollected,"keys",5100)
MinimapAPI:AddPickup("DoubleBomb","DoubleBomb",5,40,2,MinimapAPI.PickupNotCollected,"bombs",4100)

MinimapAPI:AddPickup("Card","TarotCard",5,300,-1,MinimapAPI.PickupNotCollected,"cards",1000)
for i=23,31 do
	MinimapAPI:AddPickup("SuitCard"..i,"SuitCard",5,300,i,MinimapAPI.PickupNotCollected,"cards",1100)
end
for i=36,40 do
	MinimapAPI:AddPickup("Rune"..i,"RuneRight",5,300,i,MinimapAPI.PickupNotCollected,"runes",1100)
end
MinimapAPI:AddPickup("Rune41","RuneBlack",5,300,41,MinimapAPI.PickupNotCollected,"runes",1200)--Black rune
MinimapAPI:AddPickup("ChaosCard","MagicCard",5,300,42,MinimapAPI.PickupNotCollected,"cards",1100)--Chaos Card
MinimapAPI:AddPickup("RulesCard","SuitCard",5,300,44,MinimapAPI.PickupNotCollected,"cards",1100)--Rules Card
MinimapAPI:AddPickup("SuicideKing","SuitCard",5,300,46,MinimapAPI.PickupNotCollected,"cards",1100)--Suicide King
MinimapAPI:AddPickup("QuestionmarkCard","SuitCard",5,300,48,MinimapAPI.PickupNotCollected,"cards",1100)--?Card 
MinimapAPI:AddPickup("CreditCard","CreditCard",5,300,43,MinimapAPI.PickupNotCollected,"cards",1100)
MinimapAPI:AddPickup("GetOutOfJail","GetOutOfJail",5,300,47,MinimapAPI.PickupNotCollected,"cards",1100)
MinimapAPI:AddPickup("CardAgainstHumanity","CardAgainstHumanity",5,300,45,MinimapAPI.PickupNotCollected,"cards",1100)
MinimapAPI:AddPickup("HolyCard","HolyCard",5,300,51,MinimapAPI.PickupNotCollected,"cards",1100)
MinimapAPI:AddPickup("MomsContract","MomsContract",5,300,50,MinimapAPI.PickupNotCollected,"cards",1100)
MinimapAPI:AddPickup("DiceShard","DiceShard",5,300,49,MinimapAPI.PickupNotCollected,"cards",1100)

MinimapAPI:AddPickup("HugeGrowth","MagicCard",5,300,52,MinimapAPI.PickupNotCollected,"cards",1100)
MinimapAPI:AddPickup("AncientRecall","MagicCard",5,300,53,MinimapAPI.PickupNotCollected,"cards",1100)
MinimapAPI:AddPickup("EraWalk","MagicCard",5,300,54,MinimapAPI.PickupNotCollected,"cards",1100)

MinimapAPI:AddPickup("Trophy","CheckeredFlag",5,370,-1,nil,"trophies",13000)
MinimapAPI:AddPickup("BigChest","CheckeredFlag",5,340,-1,nil,"trophies",13000)
MinimapAPI:AddPickup("Shovel","Shovel",5,110,-1,nil,"trophies",13000)

MinimapAPI:AddPickup("ShellGame","ShellGame",6,6,-1,MinimapAPI.PickupSlotMachineNotBroken,"beggars",100)

if REPENTANCE then -- Repentance exclusive icons
	for i=56,77 do
		MinimapAPI:AddPickup("Reverse"..i,"ReverseCard",5,300,i,MinimapAPI.PickupNotCollected,"cards",1100)
	end

	MinimapAPI:AddPickup("KeyShard","KeyShard",5,300,78,MinimapAPI.PickupNotCollected,"cards",1200)
	MinimapAPI:AddPickup("QueenOfHearts","SuitCard",5,300,79,MinimapAPI.PickupNotCollected,"cards",1200)

	for i=81,97 do
		MinimapAPI:AddPickup("Soul"..i,"Soul"..i,5,300,i,MinimapAPI.PickupNotCollected,"runes",1300)
	end

	MinimapAPI:AddPickup("WildCard","UnusCard",5,300,80,MinimapAPI.PickupNotCollected,"cards",1200)
	MinimapAPI:AddPickup("RuneShard","RuneShard",5,300,55,MinimapAPI.PickupNotCollected,"runes",1100)
	MinimapAPI:AddPickup("HellGame","HellGame",6,15,-1,MinimapAPI.PickupSlotMachineNotBroken,"beggars",300)

	MinimapAPI:AddPickup("BigPoopNugget","BigPoopNugget",5,42,1,MinimapAPI.PickupNotCollected,"bombs",1200)
	MinimapAPI:AddPickup("WhiteFireplace","WhiteFireplace",33,4,-1,nil,"quest",100)
	MinimapAPI:AddPickup("AscentExit","AscentExit",1000,39,-1,function(p) return Game():GetLevel():IsAscent() end,"quest",100)
end
