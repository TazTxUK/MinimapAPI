MinimapAPI.CustomIcons = Sprite()
MinimapAPI.CustomIcons:Load("gfx/ui/minimapapi/custom_icons.anm2",true)

MinimapAPI:AddCustomIcon("Beggar", MinimapAPI.CustomIcons, "CustomIconBeggar", 0)
MinimapAPI:AddCustomPickup{ --normal beggar only for now. Can add separate sprites for other variants, or just use default.
	ID = "Beggar",
	IconID = "Beggar",
	Type = 6,
	Variant = 4,
	SubType = nil,
	Call = nil,
	IconGroup = "beggars",
	Priority = 100,
}
-- note to modders: equivalent to
-- MinimapAPI:AddCustomPickup("CustomIconBeggar","CustomIconBeggar",6,nil,nil,(function or nil here),"beggars",100)

MinimapAPI:AddCustomIcon("DevilRoom", MinimapAPI.CustomIcons, "CustomIconDevilRoom", 0)
--Todo: Add support for custom room icons

--RUNES

MinimapAPI:AddCustomIcon("Rune", MinimapAPI.CustomIcons, "CustomIconRune", 0)
local cardpriority = 1100
for i,v in pairs(Card) do
	if i:sub(1,5) == "RUNE_" then
		local runetype = i:sub(6,-1)
		MinimapAPI:AddCustomPickup{
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

MinimapAPI:AddCustomIcon("PillBlueBlue", MinimapAPI.CustomIcons, "CustomIconPillBlueBlue", 0)
-- MinimapAPI:AddCustomIcon("PillWhiteBlue", MinimapAPI.CustomIcons, "CustomIconPillWhiteBlue", 0) default
MinimapAPI:AddCustomIcon("PillOrangeOrange", MinimapAPI.CustomIcons, "CustomIconPillOrangeOrange", 0)
MinimapAPI:AddCustomIcon("PillWhiteWhite", MinimapAPI.CustomIcons, "CustomIconPillWhiteWhite", 0)
MinimapAPI:AddCustomIcon("PillReddotsRed", MinimapAPI.CustomIcons, "CustomIconPillReddotsRed", 0)
MinimapAPI:AddCustomIcon("PillPinkRed", MinimapAPI.CustomIcons, "CustomIconPillPinkRed", 0)
MinimapAPI:AddCustomIcon("PillBlueCadetblue", MinimapAPI.CustomIcons, "CustomIconPillBlueCadetBlue", 0)
MinimapAPI:AddCustomIcon("PillYellowOrange", MinimapAPI.CustomIcons, "CustomIconPillYellowOrange", 0)
MinimapAPI:AddCustomIcon("PillOrangedotsWhite", MinimapAPI.CustomIcons, "CustomIconPillOrangedotsWhite", 0)
MinimapAPI:AddCustomIcon("PillWhiteAzure", MinimapAPI.CustomIcons, "CustomIconPillWhiteAzure", 0)
MinimapAPI:AddCustomIcon("PillBlackYellow", MinimapAPI.CustomIcons, "CustomIconPillBlackYellow", 0)
MinimapAPI:AddCustomIcon("PillWhiteBlack", MinimapAPI.CustomIcons, "CustomIconPillWhiteBlack", 0)
MinimapAPI:AddCustomIcon("PillWhiteYellow", MinimapAPI.CustomIcons, "CustomIconPillWhiteYellow", 0)

MinimapAPI:AddCustomIcon("DoublePenny", MinimapAPI.CustomIcons, "CustomIconCoinDouble", 0)
MinimapAPI:AddCustomIcon("GoldenKey", MinimapAPI.CustomIcons, "CustomIconGoldKey", 0)
MinimapAPI:AddCustomIcon("GoldenBomb", MinimapAPI.CustomIcons, "CustomIconGoldBomb", 0)
MinimapAPI:AddCustomIcon("SlotBloodDonation", MinimapAPI.CustomIcons, "CustomIconSlotBlood", 0)
MinimapAPI:AddCustomIcon("SlotFortune", MinimapAPI.CustomIcons, "CustomIconSlotFortune", 0)
MinimapAPI:AddCustomIcon("DonationMachine", MinimapAPI.CustomIcons, "CustomIconDonation", 0)
MinimapAPI:AddCustomIcon("RestockMachine", MinimapAPI.CustomIcons, "CustomIconRestock", 0)
MinimapAPI:AddCustomIcon("GreedDonationMachine", MinimapAPI.CustomIcons, "CustomIconGreedDonation", 0)
MinimapAPI:AddCustomIcon("Dresser", MinimapAPI.CustomIcons, "CustomIconDresser", 0)
MinimapAPI:AddCustomIcon("Trophy", MinimapAPI.CustomIcons, "CustomIconTrophy", 0)
MinimapAPI:AddCustomIcon("CheckeredFlag", MinimapAPI.CustomIcons, "CustomIconFlag", 0)

MinimapAPI:AddCustomIcon("Devilbeggar", MinimapAPI.CustomIcons, "CustomIconDevilBeggar", 0)
MinimapAPI:AddCustomIcon("ShellGame", MinimapAPI.CustomIcons, "CustomIconShellGame", 0)
MinimapAPI:AddCustomIcon("KeyBeggar", MinimapAPI.CustomIcons, "CustomIconKeyBeggar", 0)
MinimapAPI:AddCustomIcon("Bombbeggar", MinimapAPI.CustomIcons, "CustomIconBombBeggar", 0)

MinimapAPI:AddCustomPickup("PillBlueBlue","PillBlueBlue",5,70,PillColor.PILL_BLUE_BLUE,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillOrangeOrange","PillOrangeOrange",5,70,PillColor.PILL_ORANGE_ORANGE,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillWhiteWhite","PillWhiteWhite",5,70,PillColor.PILL_WHITE_WHITE,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillReddotsRed","PillReddotsRed",5,70,PillColor.PILL_REDDOTS_RED,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillPinkRed","PillPinkRed",5,70,PillColor.PILL_PINK_RED,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillBlueCadetblue","PillBlueCadetblue",5,70,PillColor.PILL_BLUE_CADETBLUE,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillYellowOrange","PillYellowOrange",5,70,PillColor.PILL_YELLOW_ORANGE,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillOrangedotsWhite","PillOrangedotsWhite",5,70,PillColor.PILL_ORANGEDOTS_WHITE,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillWhiteAzure","PillWhiteAzure",5,70,PillColor.PILL_WHITE_AZURE,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillBlackYellow","PillBlackYellow",5,70,PillColor.PILL_BLACK_YELLOW,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillWhiteBlack","PillWhiteBlack",5,70,PillColor.PILL_WHITE_BLACK,nil,"pills",6100)
MinimapAPI:AddCustomPickup("PillWhiteYellow","PillWhiteYellow",5,70,PillColor.PILL_WHITE_YELLOW,nil,"pills",6100)

MinimapAPI:AddCustomPickup("DoublePenny","DoublePenny",5,20,4,nil,"coins",3100)
MinimapAPI:AddCustomPickup("GoldenKey","GoldenKey",5,30,2,nil,"keys",5100)
MinimapAPI:AddCustomPickup("GoldenBomb","GoldenBomb",5,40,4,nil,"bombs",4100)
MinimapAPI:AddCustomPickup("SlotBloodDonation","SlotBloodDonation",6,2,-1,nil,"slots",100)
MinimapAPI:AddCustomPickup("SlotFortune","SlotFortune",6,3,-1,nil,"slots",100)
MinimapAPI:AddCustomPickup("DonationMachine","DonationMachine",6,8,-1,nil,"slots",100)
MinimapAPI:AddCustomPickup("RestockMachine","RestockMachine",6,10,-1,nil,"slots",100)
MinimapAPI:AddCustomPickup("GreedDonationMachine","GreedDonationMachine",6,11,-1,nil,"slots",100)
MinimapAPI:AddCustomPickup("Dresser","Dresser",6,12,-1,nil,"slots",100)
MinimapAPI:AddCustomPickup("Trophy","CheckeredFlag",5,370,-1,nil,"trophies",12000)
MinimapAPI:AddCustomPickup("BigChest","CheckeredFlag",5,340,-1,nil,"trophies",12000)

MinimapAPI:AddCustomPickup("Devilbeggar","Devilbeggar",6,5,-1,nil,"beggars",100)
MinimapAPI:AddCustomPickup("ShellGame","ShellGame",6,6,-1,nil,"beggars",100)
MinimapAPI:AddCustomPickup("KeyBeggar","KeyBeggar",6,7,-1,nil,"beggars",100)
MinimapAPI:AddCustomPickup("Bombbeggar","Bombbeggar",6,9,-1,nil,"beggars",100)
