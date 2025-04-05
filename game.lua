-- Game flow and state management for Chuss

local game = {}

-- Game state
local gameState = {
    board = nil,
    selectedPiece = nil,
    currentTurn = "white",
    validMoves = {},
    gameOver = false,
    winner = nil,
    message = "",
    movedPieces = {
        white = {
            king = false,
            rookA = false,
            rookH = false
        },
        black = {
            king = false,
            rookA = false,
            rookH = false
        }
    },
    selectedEffect = nil,
    removeEffectSelected = false,
    lastPawnMove = nil,  -- Track the last pawn that moved two squares for en passant
    promotionPending = nil,  -- Will store {x=x, y=y, color=color} when promotion is pending
}

-- Sound effects
local moveSound = nil
local audioEnabled = false

-- Add this function at the top of the file, after the gameState declaration but before handleMouseClick
local function handleTurnEnd(boardModule, piecesModule)
    -- Check for checkmate or stalemate
    local opponentColor = gameState.currentTurn == "white" and "black" or "white"
    if piecesModule.isCheckmate(boardModule.getBoard(), opponentColor) then
        gameState.gameOver = true
        gameState.winner = gameState.currentTurn
        gameState.message = "Checkmate! " .. gameState.currentTurn .. " wins!"
    elseif piecesModule.isStalemate(boardModule.getBoard(), opponentColor) then
        gameState.gameOver = true
        gameState.winner = "draw"
        gameState.message = "Stalemate! The game is a draw."
    else
        -- Switch turns
        gameState.currentTurn = opponentColor
        gameState.message = gameState.currentTurn .. "'s turn"
    end
    
    -- Clear selection
    gameState.selectedPiece = nil
    gameState.validMoves = {}
end

-- Initialize the game
function game.init(config, boardModule, piecesModule)
    -- Reset all game state variables
    gameState.board = boardModule.init(config)
    gameState.selectedPiece = nil
    gameState.currentTurn = config.game.initialTurn
    gameState.validMoves = {}
    gameState.gameOver = false
    gameState.winner = nil
    gameState.message = config.game.initialTurn .. "'s turn"
    gameState.movedPieces = {
        white = {
            king = false,
            rookA = false,
            rookH = false
        },
        black = {
            king = false,
            rookA = false,
            rookH = false
        }
    }
    gameState.selectedEffect = nil
    gameState.removeEffectSelected = false
    gameState.lastPawnMove = nil  -- Reset last pawn move
    
    -- Initialize the board
    boardModule.setupInitialPosition()
    
    -- Reset moved pieces tracking
    piecesModule.resetMovedPieces()
    
    -- Initialize audio
    initAudio()
    
    return gameState
end

-- Initialize audio
function initAudio()
    -- Check if audio is enabled
    if not love.audio then
        print("Audio system not available")
        audioEnabled = false
        return
    end
    
    -- Try to load the sound
    print("Loading sound effect...")
    local success, result = pcall(function()
        return love.audio.newSource("assets/audio/move.ogg", "static")
    end)
    
    if success and result then
        moveSound = result
        print("Sound loaded successfully!")
        audioEnabled = true
    else
        print("Failed to load sound: " .. tostring(result))
        audioEnabled = false
    end
end

-- Play sound with error handling
function playSound()
    if not audioEnabled or not moveSound then
        print("Cannot play sound: audio not enabled or sound not loaded")
        return
    end
    
    local success, result = pcall(function()
        -- Try to stop any currently playing sound
        if moveSound:isPlaying() then
            moveSound:stop()
        end
        
        -- Reset the sound to the beginning
        moveSound:seek(0)
        
        -- Play the sound
        moveSound:play()
    end)
    
    if success then
        print("Sound played successfully!")
    else
        print("Error playing sound: " .. tostring(result))
    end
end

-- Modify the checkPawnPromotion function to use boardModule
local function checkPawnPromotion(boardModule, x, y)
    local piece = boardModule.getPiece(x, y)
    if piece and piece.type == "pawn" then
        local promotionRank = piece.color == "white" and 1 or 8
        if y == promotionRank then
            return true
        end
    end
    return false
end

-- Modify the promotePawn function to use boardModule
local function promotePawn(boardModule, x, y, newType)
    local piece = boardModule.getPiece(x, y)
    if piece and piece.type == "pawn" then
        piece.type = newType
        return true
    end
    return false
end

-- Modify the helper function to accept piecesModule as a parameter
local function isKingInCheckmate(boardModule, piecesModule, color)
    -- First check if king is in check
    if not piecesModule.isKingInCheck(boardModule.getBoard(), color) then
        return false
    end
    
    -- Try all possible moves for all pieces
    for fromY = 1, 8 do
        for fromX = 1, 8 do
            local piece = boardModule.getPiece(fromX, fromY)
            if piece and piece.color == color then
                -- Get valid moves for this piece
                local validMoves = piecesModule.getValidMoves(boardModule.getBoard(), fromX, fromY, color, gameState.lastPawnMove)
                
                -- Try each move
                for _, move in ipairs(validMoves) do
                    -- Make temporary move
                    local capturedPiece = boardModule.getPiece(move.x, move.y)
                    boardModule.setPiece(move.x, move.y, piece)
                    boardModule.setPiece(fromX, fromY, nil)
                    
                    -- Check if king is still in check
                    local stillInCheck = piecesModule.isKingInCheck(boardModule.getBoard(), color)
                    
                    -- Undo move
                    boardModule.setPiece(fromX, fromY, piece)
                    boardModule.setPiece(move.x, move.y, capturedPiece)
                    
                    -- If we found a move that gets out of check, not checkmate
                    if not stillInCheck then
                        return false
                    end
                end
            end
        end
    end
    
    -- If we get here, no move gets out of check
    return true
end

-- Handle mouse clicks
function game.handleMouseClick(x, y, button, boardModule, piecesModule, effectsModule, uiModule)
    if gameState.gameOver then return end
    
    -- Handle promotion selection if pending
    if gameState.promotionPending then
        -- Check if a promotion piece was clicked
        local selectedType = uiModule.getPromotionPieceAtPosition(x, y)
        
        if selectedType then
            -- Get the pawn
            local piece = boardModule.getPiece(gameState.promotionPending.x, gameState.promotionPending.y)
            if piece then
                -- Promote the pawn
                piece.type = selectedType
                
                -- Play sound effect if you have one
                playSound()
                
                -- Clear promotion state
                gameState.promotionPending = nil
                
                -- Handle turn switching and end-of-turn logic
                handleTurnEnd(boardModule, piecesModule)
            end
        end
        -- Always return if promotion is pending (block other moves)
        return gameState
    end
    
    if button == 1 then  -- Left click
        local boardX, boardY = boardModule.screenToBoard(x, y)
        if boardX then
            local piece = boardModule.getPiece(boardX, boardY)
            
            -- Check if an effect is selected and the clicked piece belongs to the current player
            if gameState.selectedEffect and piece and piece.color == gameState.currentTurn then
                -- Apply the effect to the piece
                effectsModule.applyEffect(boardModule, boardX, boardY, gameState.selectedEffect)
                gameState.message = "Applied " .. gameState.selectedEffect .. " effect to " .. piece.type
                gameState.selectedEffect = nil
                uiModule.clearSelectedEffect()
                return gameState
            end
            
            -- Check if remove effect is selected and the clicked piece belongs to the current player
            if gameState.removeEffectSelected and piece and piece.color == gameState.currentTurn then
                -- Remove an effect from the piece
                local effectRemoved = effectsModule.removeRandomEffect(boardModule, boardX, boardY)
                if effectRemoved then
                    gameState.message = "Removed " .. effectRemoved .. " effect from " .. piece.type
                else
                    gameState.message = "No effects to remove from " .. piece.type
                end
                gameState.removeEffectSelected = false
                return gameState
            end
            
            -- If a piece is already selected
            if gameState.selectedPiece then
                -- If clicking on the same piece, deselect it
                if gameState.selectedPiece.x == boardX and gameState.selectedPiece.y == boardY then
                    gameState.selectedPiece = nil
                    gameState.validMoves = {}
                -- If clicking on a valid move, make the move
                else
                    local moveValid = false
                    for _, move in ipairs(gameState.validMoves) do
                        if move.x == boardX and move.y == boardY then
                            moveValid = true
                            break
                        end
                    end
                    
                    if moveValid then
                        -- Check for castling
                        if gameState.selectedPiece.piece.type == "king" and 
                           math.abs(boardX - gameState.selectedPiece.x) == 2 then
                            -- Determine which side to castle
                            local side = boardX > gameState.selectedPiece.x and "kingside" or "queenside"
                            
                            -- Check if castling is allowed
                            if piecesModule.canCastle(gameState.currentTurn, side) and 
                               piecesModule.isCastlingPathClear(gameState.board, gameState.currentTurn, side) and 
                               not piecesModule.isKingInCheckForCastling(gameState.board, gameState.currentTurn, side) then
                                piecesModule.performCastling(gameState.board, gameState.currentTurn, side)
                            else
                                -- If castling is not allowed, make a normal move
                                boardModule.setPiece(boardX, boardY, gameState.selectedPiece.piece)
                                boardModule.setPiece(gameState.selectedPiece.x, gameState.selectedPiece.y, nil)
                                
                                -- Mark the piece as moved for castling
                                piecesModule.markPieceMoved(gameState.board, boardX, boardY)
                            end
                        else
                            -- Check for effects during capture
                            local targetPiece = boardModule.getPiece(boardX, boardY)
                            if targetPiece then
                                -- Handle effect interactions
                                local captureOccurred, shouldMove = effectsModule.handleCapture(
                                    boardModule, 
                                    gameState.selectedPiece.x, 
                                    gameState.selectedPiece.y, 
                                    boardX, 
                                    boardY
                                )
                                
                                if captureOccurred then
                                    -- Remove the captured piece and move the capturing piece
                                    boardModule.setPiece(boardX, boardY, gameState.selectedPiece.piece)
                                    boardModule.setPiece(gameState.selectedPiece.x, gameState.selectedPiece.y, nil)
                                    
                                    -- Mark the piece as moved for castling
                                    piecesModule.markPieceMoved(gameState.board, boardX, boardY)
                                    
                                    -- Play move sound
                                    playSound()
                                    
                                    -- Check for pawn promotion after capture
                                    local movedPiece = boardModule.getPiece(boardX, boardY)
                                    if movedPiece and movedPiece.type == "pawn" then
                                        local promotionRank = movedPiece.color == "white" and 1 or 8
                                        if boardY == promotionRank then
                                            gameState.promotionPending = {
                                                x = boardX,
                                                y = boardY,
                                                color = movedPiece.color
                                            }
                                            gameState.message = "Choose promotion piece"
                                            -- Clear selection but don't switch turns yet
                                            gameState.selectedPiece = nil
                                            gameState.validMoves = {}
                                            return gameState
                                        end
                                    end
                                    
                                    -- If no promotion is pending, handle turn switching
                                    handleTurnEnd(boardModule, piecesModule)
                                    return gameState
                                elseif shouldMove then
                                    -- Normal move without capture
                                    boardModule.setPiece(boardX, boardY, gameState.selectedPiece.piece)
                                    boardModule.setPiece(gameState.selectedPiece.x, gameState.selectedPiece.y, nil)
                                    
                                    -- Mark the piece as moved for castling
                                    piecesModule.markPieceMoved(gameState.board, boardX, boardY)
                                    
                                    -- Play move sound
                                    playSound()
                                    
                                    -- Handle turn switching
                                    handleTurnEnd(boardModule, piecesModule)
                                    return gameState
                                end
                            else
                                -- Check for en passant capture
                                local isEnPassant = false
                                local capturedPawnX = nil
                                local capturedPawnY = nil
                                
                                if gameState.selectedPiece.piece.type == "pawn" and 
                                   math.abs(boardX - gameState.selectedPiece.x) == 1 and 
                                   gameState.lastPawnMove and 
                                   gameState.lastPawnMove.x == boardX and 
                                   ((gameState.currentTurn == "white" and gameState.lastPawnMove.y == gameState.selectedPiece.y) or
                                    (gameState.currentTurn == "black" and gameState.lastPawnMove.y == gameState.selectedPiece.y)) then
                                    -- This is an en passant capture
                                    isEnPassant = true
                                    capturedPawnX = boardX
                                    capturedPawnY = gameState.selectedPiece.y
                                end
                                
                                if isEnPassant then
                                    -- Remove the captured pawn
                                    boardModule.setPiece(capturedPawnX, capturedPawnY, nil)
                                    -- Move the capturing pawn
                                    boardModule.setPiece(boardX, boardY, gameState.selectedPiece.piece)
                                    boardModule.setPiece(gameState.selectedPiece.x, gameState.selectedPiece.y, nil)
                                    
                                    -- Mark the piece as moved for castling
                                    piecesModule.markPieceMoved(gameState.board, boardX, boardY)
                                    
                                    -- Play move sound
                                    playSound()
                                    
                                    -- Display en passant message
                                    gameState.message = "En passant capture!"
                                else
                                    -- Normal move without capture
                                    boardModule.setPiece(boardX, boardY, gameState.selectedPiece.piece)
                                    boardModule.setPiece(gameState.selectedPiece.x, gameState.selectedPiece.y, nil)
                                    
                                    -- Mark the piece as moved for castling
                                    piecesModule.markPieceMoved(gameState.board, boardX, boardY)
                                    
                                    -- Play move sound
                                    playSound()
                                end
                                
                                -- Track the last pawn move for en passant
                                if gameState.selectedPiece.piece.type == "pawn" and 
                                   math.abs(boardY - gameState.selectedPiece.y) == 2 then
                                    gameState.lastPawnMove = {x = boardX, y = boardY}
                                else
                                    gameState.lastPawnMove = nil
                                end
                            end
                            
                            -- Check for checkmate or stalemate
                            local opponentColor = gameState.currentTurn == "white" and "black" or "white"
                            if piecesModule.isCheckmate(boardModule.getBoard(), opponentColor) then
                                gameState.gameOver = true
                                gameState.winner = gameState.currentTurn
                                gameState.message = "Checkmate! " .. gameState.currentTurn .. " wins!"
                            elseif piecesModule.isStalemate(boardModule.getBoard(), opponentColor) then
                                gameState.gameOver = true
                                gameState.winner = "draw"
                                gameState.message = "Stalemate! The game is a draw."
                            else
                                -- Switch turns
                                gameState.currentTurn = opponentColor
                                gameState.message = gameState.currentTurn .. "'s turn"
                            end
                            
                            -- Clear selection
                            gameState.selectedPiece = nil
                            gameState.validMoves = {}
                        end
                    end
                end
            else
                -- Select a piece
                if piece and piece.color == gameState.currentTurn then
                    gameState.selectedPiece = {x = boardX, y = boardY, piece = piece}
                    gameState.validMoves = piecesModule.getValidMoves(boardModule.getBoard(), boardX, boardY, gameState.currentTurn, gameState.lastPawnMove)
                end
            end
        else
            -- Clicked outside the board, deselect the piece
            gameState.selectedPiece = nil
            gameState.validMoves = {}
        end
    elseif button == 2 then  -- Right click
        -- Deselect the piece
        gameState.selectedPiece = nil
        gameState.validMoves = {}
    end
    
    return gameState
end

-- Set the selected effect
function game.setSelectedEffect(effectType)
    gameState.selectedEffect = effectType
    return gameState
end

-- Get the current game state
function game.getState()
    return gameState
end

-- Make a move
function game.makeMove(toX, toY, boardModule, piecesModule)
    -- Move the piece
    boardModule.movePiece(gameState.selectedPiece.x, gameState.selectedPiece.y, toX, toY)
    
    -- Play move sound
    playSound()
    
    -- Mark the piece as moved for castling
    local piece = gameState.selectedPiece.piece
    if piece.type == "king" then
        gameState.movedPieces[gameState.currentTurn].king = true
    elseif piece.type == "rook" then
        if gameState.selectedPiece.x == 1 then
            gameState.movedPieces[gameState.currentTurn].rookA = true
        elseif gameState.selectedPiece.x == 8 then
            gameState.movedPieces[gameState.currentTurn].rookH = true
        end
    end
    
    -- Check for checkmate
    local opponentColor = gameState.currentTurn == "white" and "black" or "white"
    if piecesModule.isCheckmate(boardModule.getBoard(), opponentColor) then
        gameState.gameOver = true
        gameState.winner = gameState.currentTurn
        gameState.message = gameState.currentTurn .. " wins by checkmate!"
    -- Check for check
    elseif piecesModule.isKingInCheck(boardModule.getBoard(), opponentColor) then
        gameState.message = opponentColor .. " is in check!"
    else
        gameState.message = opponentColor .. "'s turn"
    end
    
    -- Switch turns
    gameState.currentTurn = opponentColor
    
    -- Clear selection
    gameState.selectedPiece = nil
    gameState.validMoves = {}
    
    return gameState
end

-- Handle button clicks
function game.handleButtonClick(action, value, boardModule, piecesModule, effectsModule, uiModule)
    if gameState.gameOver then return gameState end
    
    if action == "flip" then
        -- Flip the board
        boardModule.flipBoard()
        return gameState
    elseif action == "restart" then
        -- Restart the game
        return game.init({board = {tileSize = 64}, game = {initialTurn = "white"}}, boardModule, piecesModule)
    elseif action == "effect" then
        -- Select an effect to apply
        gameState.selectedEffect = value
        gameState.message = "Select a piece to apply " .. value .. " effect"
        return gameState
    elseif action == "removeEffect" then
        -- Select remove effect mode
        gameState.removeEffectSelected = true
        gameState.message = "Select a piece to remove an effect"
        return gameState
    end
    
    return gameState
end

return game 