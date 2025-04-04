-- Board management for Chuss

local board = {}

-- Board state
local gameBoard = {}
local boardOffset = {x = 0, y = 0}
local tileSize = 64
local boardFlipped = false

-- Initialize the board
function board.init(config)
    tileSize = config.board.tileSize
    
    -- Center the board on screen
    boardOffset.x = (config.window.width - config.board.width * tileSize) / 2
    boardOffset.y = (config.window.height - config.board.height * tileSize) / 2
    
    -- Create empty board
    for y = 1, config.board.height do
        gameBoard[y] = {}
        for x = 1, config.board.width do
            gameBoard[y][x] = nil
        end
    end
    
    return gameBoard
end

-- Set up the initial piece positions
function board.setupInitialPosition()
    -- Set up white pieces
    gameBoard[8] = {
        {color = "white", type = "rook"},
        {color = "white", type = "knight"},
        {color = "white", type = "bishop"},
        {color = "white", type = "queen"},
        {color = "white", type = "king"},
        {color = "white", type = "bishop"},
        {color = "white", type = "knight"},
        {color = "white", type = "rook"}
    }
    
    -- Set up white pawns
    for x = 1, 8 do
        gameBoard[7][x] = {color = "white", type = "pawn"}
    end
    
    -- Set up black pieces
    gameBoard[1] = {
        {color = "black", type = "rook"},
        {color = "black", type = "knight"},
        {color = "black", type = "bishop"},
        {color = "black", type = "queen"},
        {color = "black", type = "king"},
        {color = "black", type = "bishop"},
        {color = "black", type = "knight"},
        {color = "black", type = "rook"}
    }
    
    -- Set up black pawns
    for x = 1, 8 do
        gameBoard[2][x] = {color = "black", type = "pawn"}
    end
    
    return gameBoard
end

-- Get the board state
function board.getBoard()
    return gameBoard
end

-- Set a piece on the board
function board.setPiece(x, y, piece)
    if x >= 1 and x <= 8 and y >= 1 and y <= 8 then
        gameBoard[y][x] = piece
        return true
    end
    return false
end

-- Get a piece from the board
function board.getPiece(x, y)
    if x >= 1 and x <= 8 and y >= 1 and y <= 8 then
        return gameBoard[y][x]
    end
    return nil
end

-- Convert screen coordinates to board coordinates
function board.screenToBoard(screenX, screenY)
    local boardX = math.floor((screenX - boardOffset.x) / tileSize) + 1
    local boardY = math.floor((screenY - boardOffset.y) / tileSize) + 1
    
    -- Flip coordinates if board is flipped
    if boardFlipped then
        boardX = 9 - boardX
        boardY = 9 - boardY
    end
    
    if boardX >= 1 and boardX <= 8 and boardY >= 1 and boardY <= 8 then
        return boardX, boardY
    end
    return nil
end

-- Convert board coordinates to screen coordinates
function board.boardToScreen(boardX, boardY)
    -- Flip coordinates if board is flipped
    local displayX = boardX
    local displayY = boardY
    
    if boardFlipped then
        displayX = 9 - boardX
        displayY = 9 - boardY
    end
    
    local screenX = boardOffset.x + (displayX - 1) * tileSize
    local screenY = boardOffset.y + (displayY - 1) * tileSize
    return screenX, screenY
end

-- Move a piece on the board
function board.movePiece(fromX, fromY, toX, toY)
    if fromX >= 1 and fromX <= 8 and fromY >= 1 and fromY <= 8 and
       toX >= 1 and toX <= 8 and toY >= 1 and toY <= 8 then
        gameBoard[toY][toX] = gameBoard[fromY][fromX]
        gameBoard[fromY][fromX] = nil
        return true
    end
    return false
end

-- Toggle board flip
function board.toggleFlip()
    boardFlipped = not boardFlipped
    return boardFlipped
end

-- Get board flip state
function board.isFlipped()
    return boardFlipped
end

-- Get board offset
function board.getOffset()
    return boardOffset
end

-- Get tile size
function board.getTileSize()
    return tileSize
end

return board 