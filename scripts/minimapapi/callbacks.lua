return {
    -- Ran each time the player position changes in the minimap.
    --
    -- (minimap room, player pos) -> replacement pos
    PLAYER_POS_CHANGED = "MAPI_PLAYER_POS_CHANGED",

    -- Ran when the display flags of a room are read
    --
    -- (minimap room, display flags) -> replacement display flags
    GET_DISPLAY_FLAGS = "MAPI_GET_DISPLAY_FLAGS",

    -- Ran on new room when getting the dimension to use for the minimap. 
    --
    -- (dimension) -> replacement dimension
    GET_DIMENSION = "MAPI_GET_DIMENSION",
}