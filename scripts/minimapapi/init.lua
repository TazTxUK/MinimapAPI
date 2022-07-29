
MinimapAPI = require("scripts.minimapapi")

require("scripts.minimapapi.version")

if REPENTANCE then
    require("scripts.minimapapi.rep.data")
    require("scripts.minimapapi.rep.config")
    require("scripts.minimapapi.rep.main")
else --AFTERBIRTH+
    require("scripts.minimapapi.data")
    require("scripts.minimapapi.config")
    require("scripts.minimapapi.main")
end
require("scripts.minimapapi.noalign")

if REPENTANCE then
    require("scripts.minimapapi.rep.custom_icons")
else --AFTERBIRTH+
    require("scripts.minimapapi.custom_icons")
end

require("scripts.minimapapi.custom_mapflags")

if REPENTANCE then
    require("scripts.minimapapi.rep.nicejourney")
    require("scripts.minimapapi.rep.config_menu")
else --AFTERBIRTH+
    require("scripts.minimapapi.config_menu")
end

require("scripts.minimapapi.testfunctions")


Isaac.ConsoleOutput("MinimapAPI "..MinimapAPI.MajorVersion.."."..MinimapAPI.MinorVersion.." ("..MinimapAPI.BranchVersion..") loaded.\n")

return MinimapAPI
