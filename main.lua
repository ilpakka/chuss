-- Chuss game using LÖVE 2D

-- Load modules
local config = require("config")
local board = require("board")
local pieces = require("pieces")
local ui = require("ui")
local game = require("game")
local effects = require("effects")

-- Initialize the game
function love.load()
    -- Set up window
    love.window.setMode(config.window.width, config.window.height)
    love.window.setTitle(config.window.title)
    
    -- Load piece images
    local pieceImages = pieces.loadImages()
    
    -- Initialize UI
    ui.init(config, board, pieceImages, effects)
    
    -- Initialize game
    game.init(config, board, pieces)
end

-- Handle mouse clicks
function love.mousepressed(x, y, button, istouch, presses)
    -- Check if a UI button was clicked
    local buttonAction, effectType = ui.handleButtonClick(x, y)
    if buttonAction == "flip" then
        -- Toggle board flip
        board.toggleFlip()
        ui.toggleBoardFlip()
        return
    elseif buttonAction == "restart" then
        -- Restart the game
        board.init(config)
        board.setupInitialPosition()
        game.init(config, board, pieces)
        return
    elseif buttonAction == "effect" then
        -- Set the selected effect
        game.setSelectedEffect(effectType)
        return
    elseif buttonAction == "removeEffect" then
        -- Set the remove effect mode
        gameState = game.handleButtonClick(buttonAction, nil, board, pieces, effects, ui)
        return
    end
    
    -- Handle game board clicks
    local gameState = game.handleMouseClick(x, y, button, board, pieces, effects, ui)
end

-- Handle mouse movement
function love.mousemoved(x, y, dx, dy, istouch)
    -- Update button hover states
    ui.handleMouseHover(x, y)
end

-- Handle keyboard input
function love.keypressed(key)
    if key == "f" then
        -- Toggle board flip
        board.toggleFlip()
        ui.toggleBoardFlip()
    elseif key == "escape" then
        love.event.quit()
    end
end

-- Draw the game
function love.draw()
    local gameState = game.getState()
    
    -- Draw background
    ui.drawBackground()
    
    -- Draw the board
    ui.drawBoard(board, gameState.selectedPiece, gameState.validMoves)
    
    -- Draw buttons
    ui.drawButtons()
    
    -- Draw game status
    ui.drawStatus(gameState.message, gameState.gameOver, gameState.winner)
end

-- Update game state
function love.update(dt)
    -- No continuous updates needed for chess yet
end 