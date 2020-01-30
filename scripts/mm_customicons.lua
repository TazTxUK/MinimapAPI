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