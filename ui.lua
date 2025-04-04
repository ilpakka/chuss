-- UI rendering for Chuss

local ui = {}

-- UI state
local tiles = {}
local tileSize = 64
local background = nil
local boardFlipped = false
local buttons = {}
local buttonFont = nil
local statusFont = nil
local effectImages = nil
local selectedEffect = nil

-- Initialize UI
function ui.init(config, boardModule, pieceImages, effectsModule)
    tileSize = config.board.tileSize
    
    -- Load tile images
    tiles = {
        light = love.graphics.newImage("assets/img/tiles/light.png"),
        dark = love.graphics.newImage("assets/img/tiles/dark.png"),
        hover = love.graphics.newImage("assets/img/tiles/hover.png"),
        valid = love.graphics.newImage("assets/img/tiles/valid.png")
    }
    
    -- Load background image
    background = love.graphics.newImage("assets/img/background/background.png")
    
    -- Store piece images
    ui.pieceImages = pieceImages
    
    -- Load effect images
    effectImages = effectsModule.loadImages()
    
    -- Create button font
    buttonFont = love.graphics.newFont(24)
    
    -- Create status font (larger size for emphasis)
    statusFont = love.graphics.newFont(32)
    
    -- Create buttons
    buttons = {
        flip = {
            x = config.window.width - 120,
            y = config.window.height / 2 - 40,
            width = 100,
            height = 80,
            text = "FLIP",
            hover = false
        },
        restart = {
            x = 20,
            y = 20,
            width = 120,
            height = 50,
            text = "RESTART",
            hover = false
        },
        shield = {
            x = 20,
            y = config.window.height / 2 - 100,
            width = 120,
            height = 50,
            text = "SHIELD",
            hover = false,
            effect = effectsModule.TYPES.SHIELD
        },
        attack = {
            x = 20,
            y = config.window.height / 2 - 30,
            width = 120,
            height = 50,
            text = "ATTACK",
            hover = false,
            effect = effectsModule.TYPES.ATTACK
        },
        removeEffect = {
            x = 20,
            y = config.window.height / 2 + 40,
            width = 120,
            height = 50,
            text = "NEGATE",
            hover = false,
            isRemoveButton = true
        }
    }
    
    return true
end

-- Draw the background
function ui.drawBackground()
    if background then
        love.graphics.draw(background, 0, 0, 0, 
            love.graphics.getWidth() / background:getWidth(), 
            love.graphics.getHeight() / background:getHeight())
    end
end

-- Draw the board
function ui.drawBoard(board, selectedPiece, validMoves)
    for y = 1, 8 do
        for x = 1, 8 do
            -- Calculate tile position
            local screenX, screenY = board.boardToScreen(x, y)
            
            -- Choose tile color
            local tile = ((x + y) % 2 == 0) and tiles.light or tiles.dark
            
            -- Draw the tile
            love.graphics.draw(tile, screenX, screenY, 0, 
                tileSize / tile:getWidth(), 
                tileSize / tile:getHeight())
            
            -- Draw valid moves
            if selectedPiece and validMoves then
                for _, move in ipairs(validMoves) do
                    if move.x == x and move.y == y then
                        love.graphics.draw(tiles.valid, screenX, screenY, 0,
                            tileSize / tiles.valid:getWidth(),
                            tileSize / tiles.valid:getHeight())
                    end
                end
            end
            
            -- Draw hover effect for selected piece
            if selectedPiece and selectedPiece.x == x and selectedPiece.y == y then
                love.graphics.draw(tiles.hover, screenX, screenY, 0,
                    tileSize / tiles.hover:getWidth(),
                    tileSize / tiles.hover:getHeight())
            end
            
            -- Draw piece if present
            local piece = board.getPiece(x, y)
            if piece then
                local pieceImg = ui.pieceImages[piece.color][piece.type]
                love.graphics.draw(pieceImg, screenX, screenY, 0,
                    tileSize / pieceImg:getWidth(),
                    tileSize / pieceImg:getHeight())
                
                -- Draw effects if present
                if piece.effects then
                    local effectCount = 0
                    for effectType, _ in pairs(piece.effects) do
                        if effectImages and effectImages[effectType] then
                            -- Draw effect icon in different positions based on count
                            local effectSize = tileSize
                            local offsetX = effectCount * (effectSize / 2)
                            love.graphics.draw(effectImages[effectType], 
                                screenX + tileSize - effectSize - offsetX, 
                                screenY, 
                                0,
                                effectSize / effectImages[effectType]:getWidth(),
                                effectSize / effectImages[effectType]:getHeight())
                            effectCount = effectCount + 1
                        end
                    end
                end
            end
        end
    end
end

-- Draw game status
function ui.drawStatus(message, gameOver, winner)
    -- Draw status message in the top middle of the screen
    love.graphics.setFont(statusFont)
    local textWidth = statusFont:getWidth(message)
    
    -- Draw status text
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.print(message, 
        love.graphics.getWidth() / 2 - textWidth / 2, 
        20)
    
    -- Draw game over message
    if gameOver then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("Game Over! " .. winner .. " wins!", 
            love.graphics.getWidth() / 2 - 100, 
            love.graphics.getHeight() / 2)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw buttons
function ui.drawButtons()
    for _, button in pairs(buttons) do
        -- Draw button background
        if button.hover then
            love.graphics.setColor(0.9, 0.9, 0.9, 1) -- Lighter when hovered
        else
            love.graphics.setColor(0.95, 0.95, 0.95, 1) -- Pearly white
        end
        
        -- Draw button with rounded corners
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Border color
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Draw button text
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(buttonFont)
        local textWidth = buttonFont:getWidth(button.text)
        local textHeight = buttonFont:getHeight()
        love.graphics.print(button.text, 
            button.x + (button.width - textWidth) / 2, 
            button.y + (button.height - textHeight) / 2)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw selected effect indicator
    if selectedEffect then
        love.graphics.setColor(0, 1, 0, 0.5) -- Semi-transparent green
        for _, button in pairs(buttons) do
            if button.effect == selectedEffect then
                love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)
                love.graphics.setLineWidth(3)
                break
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Check if a point is inside a button
function ui.isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

-- Handle mouse hover over buttons
function ui.handleMouseHover(x, y)
    for _, button in pairs(buttons) do
        button.hover = ui.isPointInButton(x, y, button)
    end
end

-- Handle mouse click on buttons
function ui.handleButtonClick(x, y)
    for name, button in pairs(buttons) do
        if ui.isPointInButton(x, y, button) then
            if name == "flip" then
                return "flip"
            elseif name == "restart" then
                return "restart"
            elseif name == "shield" or name == "attack" then
                -- Toggle effect selection
                if selectedEffect == button.effect then
                    selectedEffect = nil
                else
                    selectedEffect = button.effect
                end
                return "effect", button.effect
            elseif name == "removeEffect" then
                return "removeEffect"
            end
        end
    end
    return nil
end

-- Get the currently selected effect
function ui.getSelectedEffect()
    return selectedEffect
end

-- Clear the selected effect
function ui.clearSelectedEffect()
    selectedEffect = nil
end

-- Toggle board flip
function ui.toggleBoardFlip()
    boardFlipped = not boardFlipped
    return boardFlipped
end

-- Get board flip state
function ui.isBoardFlipped()
    return boardFlipped
end

return ui 