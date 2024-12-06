MinimapAPI = require("scripts.minimapapi")
MinimapAPI.isRepentance = REPENTANCE or REPENTANCE_PLUS -- REPENTANCE variable can be altered by any mod, so we save it early so later changes dont affect it

require("scripts.minimapapi.version")

require("scripts.minimapapi.data")
require("scripts.minimapapi.config")
require("scripts.minimapapi.main")
require("scripts.minimapapi.noalign")
if MinimapAPI.isRepentance then
    require("scripts.minimapapi.custom_icons")
end
require("scripts.minimapapi.custom_mapflags")
require("scripts.minimapapi.nicejourney")
require("scripts.minimapapi.config_menu")
require("scripts.minimapapi.dsscompat")
require("scripts.minimapapi.testfunctions")


Isaac.ConsoleOutput("MinimapAPI "..MinimapAPI.MajorVersion.."."..MinimapAPI.MinorVersion.." ("..MinimapAPI.BranchVersion..") loaded.\n")

return MinimapAPI
