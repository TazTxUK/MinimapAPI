local constants = {}

-- It is conventional in the Isaac ecosystem for libraries to use `CallbackPriority.IMPORTANT`.
-- However, MinimapAPI should run before other libraries.
constants.CALLBACK_PRIORITY = REPENTANCE and (CallbackPriority.IMPORTANT - 1) or 0
constants.STAGEAPI_CALLBACK_PRIORITY = 0.5 --Most mods use Priority of 1, while StageAPI uses 0, this will run in-between those

return constants
