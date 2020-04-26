require "scripts.minimapapi.init"

local MinimapAPI = require "scripts.minimapapi"
local json = require "json"

-- SAVING GAME
MinimapAPI:AddCallback(
	ModCallbacks.MC_PRE_GAME_EXIT,
	function(self, menuexit)
		MinimapAPI:SaveData(json.encode(MinimapAPI:GetSaveTable(menuexit)))
	end
)

-- LOADING SAVED GAME
MinimapAPI:AddCallback(
	ModCallbacks.MC_POST_GAME_STARTED,
	function(self, is_save)
		badload = MinimapAPI:IsBadLoad()
		if addRenderCall then
			MinimapAPI:AddCallback(ModCallbacks.MC_POST_RENDER, renderCallbackFunction)
			addRenderCall = false
		end
		if MinimapAPI:HasData() then
			if not MinimapAPI.DisableSaving then
				local saved = json.decode(Isaac.LoadModData(MinimapAPI))
				MinimapAPI:LoadSaveTable(saved,is_save)
			else
				MinimapAPI:LoadDefaultMap()
			end
			MinimapAPI:UpdateExternalMap()
		else
			MinimapAPI:LoadDefaultMap()
		end
	end
)