if MinimapAPI then return false end

if _VERSION == "Lua 5.3" then
	MinimapAPI = RegisterMod("Minimap API",1)
	require("scripts.minimapapi.version")
	require("scripts.minimapapi.data")
	require("scripts.minimapapi.config")
	require("scripts.minimapapi.main")
	require("scripts.minimapapi.custom_icons")
	require("scripts.minimapapi.wof")
	Isaac.ConsoleOutput("Minimap API loaded, branch: "..MinimapAPI.Version.."\n")
else
	MinimapAPI = RegisterMod("Minimap API",2)
	--repentance code
end

return MinimapAPI