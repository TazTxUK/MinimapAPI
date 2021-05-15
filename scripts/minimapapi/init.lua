
MinimapAPI = RegisterMod("Minimap API",1)

require("scripts.minimapapi.version")
require("scripts.minimapapi.data")
require("scripts.minimapapi.config")
require("scripts.minimapapi.main")
require("scripts.minimapapi.noalign")
require("scripts.minimapapi.custom_icons")
require("scripts.minimapapi.custom_mapflags")
require("scripts.minimapapi.config_menu")
require("scripts.minimapapi.testfunctions")

Isaac.ConsoleOutput("MinimapAPI 1."..MinimapAPI.ReleaseVersion.." ("..MinimapAPI.Version..") loaded.\n")

return MinimapAPI
