if MinimapAPI then return false end

if _VERSION == "Lua 5.3" then
	MinimapAPI = RegisterMod("Minimap API",1)
	require("minimapapi_data")
	require("minimapapi_config")
	require("minimapapi_main")
	require("minimapapi_scripts")
else
	MinimapAPI = RegisterMod("Minimap API",2)
	--repentance code
end

return true