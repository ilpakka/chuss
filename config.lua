-- Configuration settings for Chuss

local config = {
    -- Window settings
    window = {
        title = "Chuss",
        width = 1366,
        height = 768,
        resizable = false,
        vsync = true,
        minWidth = 1366,
        minHeight = 768
    },
    
    -- Board settings
    board = {
        tileSize = 64,
        width = 8,
        height = 8
    },
    
    -- Game settings
    game = {
        initialTurn = "white"
    }
}

return config 