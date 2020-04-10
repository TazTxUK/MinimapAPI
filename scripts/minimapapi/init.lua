
local MinimapAPI = require "scripts.minimapapi"

require("scripts.minimapapi.version")
require("scripts.minimapapi.data")
require("scripts.minimapapi.config")
require("scripts.minimapapi.main")
require("scripts.minimapapi.noalign")
require("scripts.minimapapi.custom_icons")
require("scripts.minimapapi.config_menu")
require("scripts.minimapapi.testfunctions")

Isaac.ConsoleOutput("Minimap API loaded, branch: "..MinimapAPI.Version.."\n")

return MinimapAPI