local constants = {}

-- It is conventional in the Isaac ecosystem for libraries to take `CallbackPriority.IMPORTANT`.
-- However, MinimapAPI should run before other libraries.
constants.CALLBACK_PRIORITY = CallbackPriority.IMPORTANT - 1

return constants
