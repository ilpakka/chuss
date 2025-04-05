-- Piece management and move validation for Chuss

local pieces = {}

-- Load the rules module
local rules = require("scripts.rules")

-- Track which pieces have moved for castling
local movedPieces = {
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

-- Initialize piece images
function pieces.loadImages()
    local pieceImages = {white = {}, black = {}}
    local colors = {"white", "black"}
    local pieceTypes = {"king", "queen", "bishop", "knight", "rook", "pawn"}
    
    for _, color in ipairs(colors) do
        for _, pieceType in ipairs(pieceTypes) do
            local path = string.format("assets/img/pieces/%s_%s.png", color, pieceType)
            pieceImages[color][pieceType] = love.graphics.newImage(path)
        end
    end
    
    return pieceImages
end

-- Get all valid moves for a piece
function pieces.getValidMoves(board, x, y, currentTurn, lastPawnMove)
    local moves = rules.getValidMoves(board, x, y, currentTurn, lastPawnMove)
    
    -- Add castling moves if applicable
    local piece = board[y][x]
    if piece and piece.type == "king" and not movedPieces[currentTurn].king then
        -- Check kingside castling
        if not movedPieces[currentTurn].rookH and 
           pieces.isCastlingPathClear(board, currentTurn, "kingside") and 
           not pieces.isKingInCheckForCastling(board, currentTurn, "kingside") then
            table.insert(moves, {x = x + 2, y = y})
        end
        
        -- Check queenside castling
        if not movedPieces[currentTurn].rookA and 
           pieces.isCastlingPathClear(board, currentTurn, "queenside") and 
           not pieces.isKingInCheckForCastling(board, currentTurn, "queenside") then
            table.insert(moves, {x = x - 2, y = y})
        end
    end
    
    return moves
end

-- Check if a piece can castle
function pieces.canCastle(color, side)
    -- Check if the king or rook has moved
    if color == "white" then
        if side == "kingside" then
            return not movedPieces.white.king and not movedPieces.white.rookH
        else
            return not movedPieces.white.king and not movedPieces.white.rookA
        end
    else
        if side == "kingside" then
            return not movedPieces.black.king and not movedPieces.black.rookH
        else
            return not movedPieces.black.king and not movedPieces.black.rookA
        end
    end
end

-- Check if the path between king and rook is clear for castling
function pieces.isCastlingPathClear(board, color, side)
    local rank = color == "white" and 8 or 1
    if side == "kingside" then
        -- Check squares between king and rook (f1 and g1 for white, f8 and g8 for black)
        for x = 6, 7 do
            if board[rank][x] then
                return false
            end
        end
    else
        -- Check squares between king and rook (b1, c1, d1 for white, b8, c8, d8 for black)
        for x = 2, 4 do
            if board[rank][x] then
                return false
            end
        end
    end
    return true
end

-- Check if the king is in check for castling
function pieces.isKingInCheckForCastling(board, color, side)
    local rank = color == "white" and 8 or 1
    local kingX = 5
    local kingY = rank
    
    -- Determine the squares to check based on the side
    local squaresToCheck = {}
    if side == "kingside" then
        table.insert(squaresToCheck, {x = kingX, y = kingY})
        table.insert(squaresToCheck, {x = kingX + 1, y = kingY})
        table.insert(squaresToCheck, {x = kingX + 2, y = kingY})
    else
        table.insert(squaresToCheck, {x = kingX, y = kingY})
        table.insert(squaresToCheck, {x = kingX - 1, y = kingY})
        table.insert(squaresToCheck, {x = kingX - 2, y = kingY})
    end
    
    -- Check if any opponent's piece can attack any of these squares
    local opponentColor = color == "white" and "black" or "white"
    for _, square in ipairs(squaresToCheck) do
        for y = 1, 8 do
            for x = 1, 8 do
                local piece = board[y][x]
                if piece and piece.color == opponentColor then
                    -- Make a temporary move to check if it would capture the king
                    local tempPiece = board[square.y][square.x]
                    board[square.y][square.x] = nil
                    
                    -- Check if the move is valid (ignoring the check for putting own king in check)
                    local valid = false
                    if piece.type == "pawn" then
                        valid = rules.isValidPawnMove(board, x, y, square.x, square.y, opponentColor, nil)
                    elseif piece.type == "rook" then
                        valid = rules.isValidRookMove(board, x, y, square.x, square.y)
                    elseif piece.type == "knight" then
                        valid = rules.isValidKnightMove(x, y, square.x, square.y)
                    elseif piece.type == "bishop" then
                        valid = rules.isValidBishopMove(board, x, y, square.x, square.y)
                    elseif piece.type == "queen" then
                        valid = rules.isValidQueenMove(board, x, y, square.x, square.y)
                    elseif piece.type == "king" then
                        valid = rules.isValidKingMove(board, x, y, square.x, square.y, opponentColor)
                    end
                    
                    -- Restore the square
                    board[square.y][square.x] = tempPiece
                    
                    if valid then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- Perform castling
function pieces.performCastling(board, color, side)
    local rank = color == "white" and 8 or 1
    local kingX = 5
    local rookX = side == "kingside" and 8 or 1
    local newKingX = side == "kingside" and 7 or 3
    local newRookX = side == "kingside" and 6 or 4
    
    -- Move the king
    board[rank][newKingX] = board[rank][kingX]
    board[rank][kingX] = nil
    
    -- Move the rook
    board[rank][newRookX] = board[rank][rookX]
    board[rank][rookX] = nil
    
    -- Mark the king and rook as moved
    if color == "white" then
        movedPieces.white.king = true
        if side == "kingside" then
            movedPieces.white.rookH = true
        else
            movedPieces.white.rookA = true
        end
    else
        movedPieces.black.king = true
        if side == "kingside" then
            movedPieces.black.rookH = true
        else
            movedPieces.black.rookA = true
        end
    end
end

-- Mark a piece as moved for castling purposes
function pieces.markPieceMoved(board, x, y)
    local piece = board[y][x]
    if piece then
        if piece.type == "king" then
            movedPieces[piece.color].king = true
        elseif piece.type == "rook" then
            if x == 1 then
                movedPieces[piece.color].rookA = true
            elseif x == 8 then
                movedPieces[piece.color].rookH = true
            end
        end
    end
end

-- Check if a king is in check
function pieces.isKingInCheck(board, color)
    return rules.isKingInCheck(board, color)
end

-- Check if a player is in checkmate
function pieces.isCheckmate(board, color)
    return rules.isCheckmate(board, color)
end

-- Check if a player is in stalemate
function pieces.isStalemate(board, color)
    -- First, check if the king is in check (if it is, it's not stalemate)
    if rules.isKingInCheck(board, color) then
        return false
    end
    
    -- Check if any legal move can be made
    for fromY = 1, 8 do
        for fromX = 1, 8 do
            local piece = board[fromY][fromX]
            if piece and piece.color == color then
                for toY = 1, 8 do
                    for toX = 1, 8 do
                        if rules.isValidMove(board, fromX, fromY, toX, toY, color) then
                            -- Make a temporary move
                            local tempPiece = board[toY][toX]
                            board[toY][toX] = piece
                            board[fromY][fromX] = nil
                            
                            -- Check if the king is in check after the move
                            local inCheck = rules.isKingInCheck(board, color)
                            
                            -- Undo the temporary move
                            board[fromY][fromX] = piece
                            board[toY][toX] = tempPiece
                            
                            -- If we found a move that doesn't put the king in check, it's not stalemate
                            if not inCheck then
                                return false
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- If we couldn't find any legal move, it's stalemate
    return true
end

-- Reset moved pieces tracking
function pieces.resetMovedPieces()
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
    }
end

return pieces 