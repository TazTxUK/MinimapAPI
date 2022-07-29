
MinimapAPI = require("scripts.minimapapi")

local pre = "scripts.minimapapi.rep."
require("scripts.minimapapi.rep.version")
require("scripts.minimapapi.rep.data")
require("scripts.minimapapi.rep.config")
require("scripts.minimapapi.rep.main")
require("scripts.minimapapi.rep.noalign")
require("scripts.minimapapi.rep.custom_icons")
require("scripts.minimapapi.rep.custom_mapflags")
require("scripts.minimapapi.rep.nicejourney")
require("scripts.minimapapi.rep.config_menu")
require("scripts.minimapapi.rep.testfunctions")

Isaac.ConsoleOutput("MinimapAPI "..MinimapAPI.MajorVersion.."."..MinimapAPI.MinorVersion.." ("..MinimapAPI.BranchVersion..") loaded.\n")

return MinimapAPI
