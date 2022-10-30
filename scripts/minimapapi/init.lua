MinimapAPI = require("scripts.minimapapi")

require("scripts.minimapapi.version")

require("scripts.minimapapi.data")
require("scripts.minimapapi.config")
require("scripts.minimapapi.main")
require("scripts.minimapapi.noalign")
require("scripts.minimapapi.custom_icons")
require("scripts.minimapapi.custom_mapflags")
require("scripts.minimapapi.nicejourney")
require("scripts.minimapapi.config_menu")
require("scripts.minimapapi.dsscompat")
require("scripts.minimapapi.testfunctions")


Isaac.ConsoleOutput("MinimapAPI "..MinimapAPI.MajorVersion.."."..MinimapAPI.MinorVersion.." ("..MinimapAPI.BranchVersion..") loaded.\n")

return MinimapAPI
