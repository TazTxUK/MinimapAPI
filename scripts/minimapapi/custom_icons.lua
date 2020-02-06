MinimapAPI.CustomIcons = Sprite()
MinimapAPI.CustomIcons:Load("gfx/ui/minimapapi/custom_icons.anm2",true)

MinimapAPI:AddIcon("DevilRoom", MinimapAPI.CustomIcons, "CustomIconDevilRoom", 0)
MinimapAPI.RoomTypeIconIDs[RoomType.ROOM_DEVIL] = "DevilRoom"

--RUNES

MinimapAPI:AddIcon("Rune", MinimapAPI.CustomIcons, "CustomIconRune", 0)
local cardpriority = 1100
for i,v in pairs(Card) do
	if i:sub(1,5) == "RUNE_" then
		local runetype = i:sub(6,-1)
		MinimapAPI:AddPickup{
			ID = "Rune"..runetype:sub(1,1):upper()..runetype:sub(2,-1):lower(),
			IconID = "Rune",
			Type = 5,
			Variant = 300,
			SubType = v,
			Call = nil,
			IconGroup = "runes",
			Priority = cardpriority,
		}
		cardpriority = cardpriority + 10
	end
end

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

MinimapAPI:AddIcon("DoublePenny", MinimapAPI.CustomIcons, "CustomIconCoinDouble", 0)
MinimapAPI:AddIcon("Nickel", MinimapAPI.CustomIcons, "CustomIconNickel", 0)
MinimapAPI:AddIcon("Dime", MinimapAPI.CustomIcons, "CustomIconDime", 0)
MinimapAPI:AddIcon("LuckyPenny", MinimapAPI.CustomIcons, "CustomIconLuckyPenny", 0)
MinimapAPI:AddIcon("StickyNickel", MinimapAPI.CustomIcons, "CustomIconNickelSticky", 0)
MinimapAPI:AddIcon("GoldenKey", MinimapAPI.CustomIcons, "CustomIconGoldKey", 0)
MinimapAPI:AddIcon("GoldenBomb", MinimapAPI.CustomIcons, "CustomIconGoldBomb", 0)
MinimapAPI:AddIcon("SlotBloodDonation", MinimapAPI.CustomIcons, "CustomIconSlotBlood", 0)
MinimapAPI:AddIcon("SlotFortune", MinimapAPI.CustomIcons, "CustomIconSlotFortune", 0)
MinimapAPI:AddIcon("DonationMachine", MinimapAPI.CustomIcons, "CustomIconDonation", 0)
MinimapAPI:AddIcon("RestockMachine", MinimapAPI.CustomIcons, "CustomIconRestock", 0)
MinimapAPI:AddIcon("GreedDonationMachine", MinimapAPI.CustomIcons, "CustomIconGreedDonation", 0)
MinimapAPI:AddIcon("Dresser", MinimapAPI.CustomIcons, "CustomIconDresser", 0)
MinimapAPI:AddIcon("Trophy", MinimapAPI.CustomIcons, "CustomIconTrophy", 0)
MinimapAPI:AddIcon("CheckeredFlag", MinimapAPI.CustomIcons, "CustomIconFlag", 0)

MinimapAPI:AddIcon("Beggar", MinimapAPI.CustomIcons, "CustomIconBeggar", 0)
MinimapAPI:AddIcon("Devilbeggar", MinimapAPI.CustomIcons, "CustomIconDevilBeggar", 0)
MinimapAPI:AddIcon("ShellGame", MinimapAPI.CustomIcons, "CustomIconShellGame", 0)
MinimapAPI:AddIcon("KeyBeggar", MinimapAPI.CustomIcons, "CustomIconKeyBeggar", 0)
MinimapAPI:AddIcon("Bombbeggar", MinimapAPI.CustomIcons, "CustomIconBombBeggar", 0)

MinimapAPI:AddPickup("PillBlueBlue","PillBlueBlue",5,70,PillColor.PILL_BLUE_BLUE,nil,"pills",6100)
MinimapAPI:AddPickup("PillOrangeOrange","PillOrangeOrange",5,70,PillColor.PILL_ORANGE_ORANGE,nil,"pills",6100)
MinimapAPI:AddPickup("PillWhiteWhite","PillWhiteWhite",5,70,PillColor.PILL_WHITE_WHITE,nil,"pills",6100)
MinimapAPI:AddPickup("PillReddotsRed","PillReddotsRed",5,70,PillColor.PILL_REDDOTS_RED,nil,"pills",6100)
MinimapAPI:AddPickup("PillPinkRed","PillPinkRed",5,70,PillColor.PILL_PINK_RED,nil,"pills",6100)
MinimapAPI:AddPickup("PillBlueCadetblue","PillBlueCadetblue",5,70,PillColor.PILL_BLUE_CADETBLUE,nil,"pills",6100)
MinimapAPI:AddPickup("PillYellowOrange","PillYellowOrange",5,70,PillColor.PILL_YELLOW_ORANGE,nil,"pills",6100)
MinimapAPI:AddPickup("PillOrangedotsWhite","PillOrangedotsWhite",5,70,PillColor.PILL_ORANGEDOTS_WHITE,nil,"pills",6100)
MinimapAPI:AddPickup("PillWhiteAzure","PillWhiteAzure",5,70,PillColor.PILL_WHITE_AZURE,nil,"pills",6100)
MinimapAPI:AddPickup("PillBlackYellow","PillBlackYellow",5,70,PillColor.PILL_BLACK_YELLOW,nil,"pills",6100)
MinimapAPI:AddPickup("PillWhiteBlack","PillWhiteBlack",5,70,PillColor.PILL_WHITE_BLACK,nil,"pills",6100)
MinimapAPI:AddPickup("PillWhiteYellow","PillWhiteYellow",5,70,PillColor.PILL_WHITE_YELLOW,nil,"pills",6100)

MinimapAPI:AddPickup("DoublePenny","DoublePenny",5,20,4,nil,"coins",3200)
MinimapAPI:AddPickup("Nickel","Nickel",5,20,2,nil,"coins",3400)
MinimapAPI:AddPickup("StickyNickel","StickyNickel",5,20,6,nil,"coins",3300)
MinimapAPI:AddPickup("Dime","Dime",5,20,3,nil,"coins",3600)
MinimapAPI:AddPickup("LuckyPenny","LuckyPenny",5,20,5,nil,"coins",3500)
MinimapAPI:AddPickup("GoldenKey","GoldenKey",5,30,2,nil,"keys",5100)
MinimapAPI:AddPickup("GoldenBomb","GoldenBomb",5,40,4,nil,"bombs",4100)
MinimapAPI:AddPickup("SlotBloodDonation","SlotBloodDonation",6,2,-1,nil,"slots",100)
MinimapAPI:AddPickup("SlotFortune","SlotFortune",6,3,-1,nil,"slots",100)
MinimapAPI:AddPickup("DonationMachine","DonationMachine",6,8,-1,nil,"slots",100)
MinimapAPI:AddPickup("RestockMachine","RestockMachine",6,10,-1,nil,"slots",100)
MinimapAPI:AddPickup("GreedDonationMachine","GreedDonationMachine",6,11,-1,nil,"slots",100)
MinimapAPI:AddPickup("Dresser","Dresser",6,12,-1,nil,"slots",100)
MinimapAPI:AddPickup("Trophy","CheckeredFlag",5,370,-1,nil,"trophies",12000)
MinimapAPI:AddPickup("BigChest","CheckeredFlag",5,340,-1,nil,"trophies",12000)

MinimapAPI:AddPickup("Beggar","Beggar",6,4,-1,nil,"beggars",200)
MinimapAPI:AddPickup("Devilbeggar","Devilbeggar",6,5,-1,nil,"beggars",100)
MinimapAPI:AddPickup("ShellGame","ShellGame",6,6,-1,nil,"beggars",100)
MinimapAPI:AddPickup("KeyBeggar","KeyBeggar",6,7,-1,nil,"beggars",100)
MinimapAPI:AddPickup("Bombbeggar","Bombbeggar",6,9,-1,nil,"beggars",100)
