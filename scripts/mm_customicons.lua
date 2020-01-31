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
