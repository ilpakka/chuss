function love.load()
    -- Define base path for pieces
    local piecePath = "assets/img/pieces/"

    -- Define quads for each piece
    pieces = {
        black  = {
            queen = love.graphics.newImage(piecePath .. "black_queen.png"),
            king = love.graphics.newImage(piecePath .. "black_king.png"),
            rook = love.graphics.newImage(piecePath .. "black_rook.png"),
            knight = love.graphics.newImage(piecePath .. "black_knight.png"),
            bishop = love.graphics.newImage(piecePath .. "black_bishop.png"),
            pawn = love.graphics.newImage(piecePath .. "black_pawn.png")
        },
        white = {
            queen = love.graphics.newImage(piecePath .. "white_queen.png"),
            king = love.graphics.newImage(piecePath .. "white_king.png"),
            rook = love.graphics.newImage(piecePath .. "white_rook.png"),
            knight = love.graphics.newImage(piecePath .. "white_knight.png"),
            bishop = love.graphics.newImage(piecePath .. "white_bishop.png"),
            pawn = love.graphics.newImage(piecePath .. "white_pawn.png")
        }
    }

    -- Load images for tiles
    local tilePath = "assets/img/tiles/"
    tiles = {
        light = love.graphics.newImage(tilePath .. "light.png"),
        dark = love.graphics.newImage(tilePath .. "dark.png"),
        hover = love.graphics.newImage(tilePath .. "hover.png") -- Load hover image
    }

    -- Initialize board
    board = {}
    for i = 1, 8 do
        board[i] = {}
        for j = 1, 8 do
            board[i][j] = nil
        end
    end

    -- Place pieces on the board
    setupBoard()

    -- Variables to keep track of the selected piece
    selectedPiece = nil
    selectedPieceX = 0
    selectedPieceY = 0
    originalX = 0
    originalY = 0

    -- Variable to keep track of the current player's turn
    currentPlayer = "white"
end

function setupBoard()
    -- Place pawns
    for i = 1, 8 do
        board[i][2] = {piece = "pawn", color = "black"}
        board[i][7] = {piece = "pawn", color = "white"}
    end

    -- Place other pieces
    local piecesOrder = {"rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"}
    for i = 1, 8 do
        board[i][1] = {piece = piecesOrder[i], color = "black"}
        board[i][8] = {piece = piecesOrder[i], color = "white"}
    end
end

function love.update(dt)
    -- No need to update the position gradually
end

function love.draw()
    drawBoard()
    if selectedPiece then
        drawHighlight()
    end
    drawPieces()
end

function drawBoard()
    local tileSize = 60
    local boardSize = tileSize * 8
    local offsetX = (love.graphics.getWidth() - boardSize) / 2
    local offsetY = (love.graphics.getHeight() - boardSize) / 2

    for i = 1, 8 do
        for j = 1, 8 do
            local tile = (i + j) % 2 == 0 and tiles.light or tiles.dark
            love.graphics.draw(tile, offsetX + (i-1) * tileSize, offsetY + (j-1) * tileSize, 0, 1.4, 1.4)
        end
    end
end

function drawPieces()
    local tileSize = 60
    local boardSize = tileSize * 8
    local offsetX = (love.graphics.getWidth() - boardSize) / 2
    local offsetY = (love.graphics.getHeight() - boardSize) / 2

    for i = 1, 8 do
        for j = 1, 8 do
            local piece = board[i][j]
            if piece then
                local img = pieces[piece.color][piece.piece]
                love.graphics.draw(img, offsetX + (i-1) * tileSize, offsetY + (j-1) * tileSize)
            end
        end
    end

    if selectedPiece then
        local img = pieces[selectedPiece.color][selectedPiece.piece]
        love.graphics.draw(img, selectedPieceX - tileSize / 2, selectedPieceY - tileSize / 2)
    end
end

function drawHighlight()
    local tileSize = 60
    local boardSize = tileSize * 8
    local offsetX = (love.graphics.getWidth() - boardSize) / 2
    local offsetY = (love.graphics.getHeight() - boardSize) / 2

    local i = math.floor((selectedPieceX - offsetX) / tileSize) + 1
    local j = math.floor((selectedPieceY - offsetY) / tileSize) + 1

    if i >= 1 and i <= 8 and j >= 1 and j <= 8 then
        love.graphics.draw(tiles.hover, offsetX + (i-1) * tileSize, offsetY + (j-1) * tileSize, 0, 1.4, 1.4)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        local tileSize = 60
        local boardSize = tileSize * 8
        local offsetX = (love.graphics.getWidth() - boardSize) / 2
        local offsetY = (love.graphics.getHeight() - boardSize) / 2

        for i = 1, 8 do
            for j = 1, 8 do
                local piece = board[i][j]
                if piece and piece.color == currentPlayer then
                    local pieceX = offsetX + (i-1) * tileSize
                    local pieceY = offsetY + (j-1) * tileSize
                    if x >= pieceX and x <= pieceX + tileSize and y >= pieceY and y <= pieceY + tileSize then
                        selectedPiece = piece
                        selectedPieceX = x
                        selectedPieceY = y
                        originalX = i
                        originalY = j
                        board[i][j] = nil
                        return
                    end
                end
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 and selectedPiece then
        local tileSize = 60
        local boardSize = tileSize * 8
        local offsetX = (love.graphics.getWidth() - boardSize) / 2
        local offsetY = (love.graphics.getHeight() - boardSize) / 2

        local i = math.floor((x - offsetX) / tileSize) + 1
        local j = math.floor((y - offsetY) / tileSize) + 1

        if i == originalX and j == originalY then
            -- If the piece is released on the same square, place it back and do not switch turns
            board[originalX][originalY] = selectedPiece
        elseif i >= 1 and i <= 8 and j >= 1 and j <= 8 and isValidMove(selectedPiece, originalX, originalY, i, j) then
            board[i][j] = selectedPiece
            -- Switch turns
            currentPlayer = (currentPlayer == "white") and "black" or "white"
        else
            board[originalX][originalY] = selectedPiece
        end

        selectedPiece = nil
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if selectedPiece then
        selectedPieceX = x
        selectedPieceY = y
    end
end

function isValidMove(piece, startX, startY, endX, endY)
    local dx = math.abs(endX - startX)
    local dy = math.abs(endY - startY)

    if piece.piece == "pawn" then
        if piece.color == "white" then
            return (startY == 7 and endY == 5 and dx == 0) or (endY == startY - 1 and dx == 0)
        else
            return (startY == 2 and endY == 4 and dx == 0) or (endY == startY + 1 and dx == 0)
        end
    elseif piece.piece == "rook" then
        return dx == 0 or dy == 0
    elseif piece.piece == "knight" then
        return (dx == 2 and dy == 1) or (dx == 1 and dy == 2)
    elseif piece.piece == "bishop" then
        return dx == dy
    elseif piece.piece == "queen" then
        return dx == dy or dx == 0 or dy == 0
    elseif piece.piece == "king" then
        return dx <= 1 and dy <= 1
    end

    return false
end