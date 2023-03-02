MinimapAPI = require("scripts.minimapapi")
MinimapAPI.isRepentance = getmetatable(Sprite) ~= nil and getmetatable(Sprite).__class ~= nil and getmetatable(Sprite).__class.GetAnimation ~= nil -- REPENTANCE variable can be altered by any mod, so we try alternative method and save the result

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
