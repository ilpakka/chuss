local rules = {}

-- Check if a move is valid for a specific piece
function rules.isValidMove(board, fromX, fromY, toX, toY, currentTurn, lastPawnMove)
    local piece = board[fromY][fromX]
    
    -- Check if the piece exists and belongs to the current player
    if not piece or piece.color ~= currentTurn then
        return false
    end
    
    -- Check if the destination square is occupied by a piece of the same color
    local destPiece = board[toY][toX]
    if destPiece and destPiece.color == currentTurn then
        return false
    end
    
    -- Check if the move is valid for the piece type
    local valid = false
    
    if piece.type == "pawn" then
        valid = rules.isValidPawnMove(board, fromX, fromY, toX, toY, currentTurn, lastPawnMove)
    elseif piece.type == "rook" then
        valid = rules.isValidRookMove(board, fromX, fromY, toX, toY)
    elseif piece.type == "knight" then
        valid = rules.isValidKnightMove(fromX, fromY, toX, toY)
    elseif piece.type == "bishop" then
        valid = rules.isValidBishopMove(board, fromX, fromY, toX, toY)
    elseif piece.type == "queen" then
        valid = rules.isValidQueenMove(board, fromX, fromY, toX, toY)
    elseif piece.type == "king" then
        -- For king moves, we need to check if the destination square is under attack
        -- This is already handled in isValidKingMove, so we don't need to check again
        valid = rules.isValidKingMove(board, fromX, fromY, toX, toY, currentTurn)
        -- If the move is valid, return true immediately (no need to check if it puts the king in check)
        return valid
    end
    
    -- If the move is valid, check if it would put the king in check
    if valid then
        -- Make a temporary move
        local tempPiece = board[toY][toX]
        board[toY][toX] = piece
        board[fromY][fromX] = nil
        
        -- Check if the king is in check
        local inCheck = rules.isKingInCheck(board, currentTurn)
        
        -- Undo the temporary move
        board[fromY][fromX] = piece
        board[toY][toX] = tempPiece
        
        -- If the move would put the king in check, it's not valid
        if inCheck then
            return false
        end
    end
    
    return valid
end

-- Check if a pawn move is valid
function rules.isValidPawnMove(board, fromX, fromY, toX, toY, currentTurn, lastPawnMove)
    local direction = currentTurn == "white" and -1 or 1
    local startRank = currentTurn == "white" and 7 or 2
    
    -- Check if the pawn is moving forward
    if (currentTurn == "white" and toY >= fromY) or
       (currentTurn == "black" and toY <= fromY) then
        return false
    end
    
    -- Check for en passant capture
    if math.abs(toX - fromX) == 1 and toY - fromY == direction and lastPawnMove then
        -- Check if the destination square is empty (for en passant)
        if not board[toY][toX] then
            -- Check if there's an opponent's pawn that just moved two squares
            local opponentPawnY = currentTurn == "white" and fromY or fromY + 2
            local opponentPawnX = toX
            
            -- Check if the last pawn move matches this position
            if lastPawnMove.x == opponentPawnX and lastPawnMove.y == opponentPawnY then
                -- This is a valid en passant capture
                return true
            end
        end
    end
    
    -- Check if the pawn is moving diagonally to capture a piece
    if math.abs(toX - fromX) == 1 and toY - fromY == direction then
        local destPiece = board[toY][toX]
        return destPiece and destPiece.color ~= currentTurn
    end
    
    -- Check if the pawn is moving forward one square
    if toX == fromX and toY - fromY == direction then
        return not board[toY][toX]
    end
    
    -- Check if the pawn is moving forward two squares from its starting position
    if toX == fromX and toY - fromY == 2 * direction and fromY == startRank then
        return not board[toY][toX] and not board[fromY + direction][fromX]
    end
    
    return false
end

-- Check if a rook move is valid
function rules.isValidRookMove(board, fromX, fromY, toX, toY)
    -- Rooks can only move horizontally or vertically
    if fromX ~= toX and fromY ~= toY then
        return false
    end
    
    -- Check if there are any pieces blocking the path
    if fromX == toX then
        local startY = math.min(fromY, toY)
        local endY = math.max(fromY, toY)
        for y = startY + 1, endY - 1 do
            -- Check if the coordinates are within the board boundaries
            if y < 1 or y > 8 then
                return false
            end
            
            -- Check if there's a piece blocking the path
            if board[y] and board[y][fromX] then
                return false
            end
        end
    else
        local startX = math.min(fromX, toX)
        local endX = math.max(fromX, toX)
        for x = startX + 1, endX - 1 do
            -- Check if the coordinates are within the board boundaries
            if x < 1 or x > 8 then
                return false
            end
            
            -- Check if there's a piece blocking the path
            if board[fromY] and board[fromY][x] then
                return false
            end
        end
    end
    
    return true
end

-- Check if a knight move is valid
function rules.isValidKnightMove(fromX, fromY, toX, toY)
    local dx = math.abs(toX - fromX)
    local dy = math.abs(toY - fromY)
    return (dx == 2 and dy == 1) or (dx == 1 and dy == 2)
end

-- Check if a bishop move is valid
function rules.isValidBishopMove(board, fromX, fromY, toX, toY)
    -- Bishops can only move diagonally
    if math.abs(toX - fromX) ~= math.abs(toY - fromY) then
        return false
    end
    
    -- Check if there are any pieces blocking the path
    local dx = toX > fromX and 1 or -1
    local dy = toY > fromY and 1 or -1
    local x = fromX + dx
    local y = fromY + dy
    
    while x ~= toX do
        -- Check if the coordinates are within the board boundaries
        if x < 1 or x > 8 or y < 1 or y > 8 then
            return false
        end
        
        -- Check if there's a piece blocking the path
        if board[y] and board[y][x] then
            return false
        end
        
        x = x + dx
        y = y + dy
    end
    
    return true
end

-- Check if a queen move is valid
function rules.isValidQueenMove(board, fromX, fromY, toX, toY)
    -- Queens can move like rooks or bishops
    return rules.isValidRookMove(board, fromX, fromY, toX, toY) or
           rules.isValidBishopMove(board, fromX, fromY, toX, toY)
end

-- Check if a square is under attack by an opponent's piece
function rules.isSquareUnderAttack(board, x, y, currentTurn)
    local opponentColor = currentTurn == "white" and "black" or "white"
    
    -- Check if any opponent's piece can attack the square
    for fromY = 1, 8 do
        for fromX = 1, 8 do
            local piece = board[fromY][fromX]
            if piece and piece.color == opponentColor then
                -- Check if the move is valid (ignoring the check for putting own king in check)
                local valid = false
                if piece.type == "pawn" then
                    -- For pawns, we need to check if they can capture diagonally
                    local direction = opponentColor == "white" and -1 or 1
                    -- Pawns can only attack diagonally forward
                    if math.abs(x - fromX) == 1 and y - fromY == direction then
                        valid = true
                    end
                elseif piece.type == "rook" then
                    valid = rules.isValidRookMove(board, fromX, fromY, x, y)
                elseif piece.type == "knight" then
                    valid = rules.isValidKnightMove(fromX, fromY, x, y)
                elseif piece.type == "bishop" then
                    valid = rules.isValidBishopMove(board, fromX, fromY, x, y)
                elseif piece.type == "queen" then
                    valid = rules.isValidQueenMove(board, fromX, fromY, x, y)
                elseif piece.type == "king" then
                    -- For king vs king, we need to check if the destination is adjacent to the opponent's king
                    local kingDx = math.abs(x - fromX)
                    local kingDy = math.abs(y - fromY)
                    valid = kingDx <= 1 and kingDy <= 1
                end
                
                if valid then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Check if a king move is valid
function rules.isValidKingMove(board, fromX, fromY, toX, toY, currentTurn)
    local dx = math.abs(toX - fromX)
    local dy = math.abs(toY - fromY)
    
    -- Check if the king is moving one square in any direction
    if dx > 1 or dy > 1 then
        return false
    end
    
    -- Check if the destination square is under attack
    local isUnderAttack = rules.isSquareUnderAttack(board, toX, toY, currentTurn)
    
    -- If the destination square is under attack, check if it's occupied by an attacking piece
    -- that the king can capture
    if isUnderAttack then
        local destPiece = board[toY][toX]
        if destPiece and destPiece.color ~= currentTurn then
            -- The king can capture the attacking piece
            return true
        end
        
        -- Debug information
        print("King move rejected: Square (" .. toX .. "," .. toY .. ") is under attack")
        
        -- Find which piece is attacking the square
        local opponentColor = currentTurn == "white" and "black" or "white"
        for y = 1, 8 do
            for x = 1, 8 do
                local piece = board[y][x]
                if piece and piece.color == opponentColor then
                    local valid = false
                    if piece.type == "pawn" then
                        local direction = opponentColor == "white" and -1 or 1
                        if math.abs(toX - x) == 1 and toY - y == direction then
                            valid = true
                        end
                    elseif piece.type == "rook" then
                        valid = rules.isValidRookMove(board, x, y, toX, toY)
                    elseif piece.type == "knight" then
                        valid = rules.isValidKnightMove(x, y, toX, toY)
                    elseif piece.type == "bishop" then
                        valid = rules.isValidBishopMove(board, x, y, toX, toY)
                    elseif piece.type == "queen" then
                        valid = rules.isValidQueenMove(board, x, y, toX, toY)
                    elseif piece.type == "king" then
                        local kingDx = math.abs(toX - x)
                        local kingDy = math.abs(toY - y)
                        valid = kingDx <= 1 and kingDy <= 1
                    end
                    
                    if valid then
                        print("  Attacked by " .. opponentColor .. " " .. piece.type .. " at (" .. x .. "," .. y .. ")")
                    end
                end
            end
        end
        
        return false
    end
    
    return true
end

-- Find a king's position on the board
function rules.findKing(board, color)
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board[y][x]
            if piece and piece.type == "king" and piece.color == color then
                return x, y
            end
        end
    end
    return nil
end

-- Check if a king is in check
function rules.isKingInCheck(board, color)
    -- Find the king's position
    local kingX, kingY = rules.findKing(board, color)
    if not kingX then return false end
    
    -- Check if any opponent's piece can capture the king
    local opponentColor = color == "white" and "black" or "white"
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board[y][x]
            if piece and piece.color == opponentColor then
                -- Make a temporary move to check if it would capture the king
                local tempPiece = board[kingY][kingX]
                board[kingY][kingX] = nil
                
                -- Check if the move is valid (ignoring the check for putting own king in check)
                local valid = false
                if piece.type == "pawn" then
                    -- For pawns, we need to check if they can capture diagonally
                    local direction = opponentColor == "white" and -1 or 1
                    if math.abs(kingX - x) == 1 and kingY - y == direction then
                        valid = true
                    end
                elseif piece.type == "rook" then
                    valid = rules.isValidRookMove(board, x, y, kingX, kingY)
                elseif piece.type == "knight" then
                    valid = rules.isValidKnightMove(x, y, kingX, kingY)
                elseif piece.type == "bishop" then
                    valid = rules.isValidBishopMove(board, x, y, kingX, kingY)
                elseif piece.type == "queen" then
                    valid = rules.isValidQueenMove(board, x, y, kingX, kingY)
                elseif piece.type == "king" then
                    -- For king vs king, we need to check if the destination is adjacent to the opponent's king
                    local kingDx = math.abs(kingX - x)
                    local kingDy = math.abs(kingY - y)
                    valid = kingDx <= 1 and kingDy <= 1
                end
                
                -- Restore the king
                board[kingY][kingX] = tempPiece
                
                if valid then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Check if a king is in check for castling
function rules.isKingInCheckForCastling(board, color, side)
    -- Find the king's position
    local kingX, kingY = rules.findKing(board, color)
    if not kingX then return false end
    
    -- Determine which squares to check based on the side
    local squaresToCheck = {}
    if side == "kingside" then
        table.insert(squaresToCheck, {x = kingX, y = kingY})
        table.insert(squaresToCheck, {x = kingX + 1, y = kingY})
        table.insert(squaresToCheck, {x = kingX + 2, y = kingY})
    else -- queenside
        table.insert(squaresToCheck, {x = kingX, y = kingY})
        table.insert(squaresToCheck, {x = kingX - 1, y = kingY})
        table.insert(squaresToCheck, {x = kingX - 2, y = kingY})
    end
    
    -- Check if any opponent's piece can attack any of these squares
    local opponentColor = color == "white" and "black" or "white"
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board[y][x]
            if piece and piece.color == opponentColor then
                for _, square in ipairs(squaresToCheck) do
                    -- Check if the square is within the board boundaries
                    if square.x < 1 or square.x > 8 or square.y < 1 or square.y > 8 then
                        return true
                    end
                    
                    -- Make a temporary move to check if it would capture the square
                    local tempPiece = board[square.y][square.x]
                    board[square.y][square.x] = nil
                    
                    -- Check if the move is valid (ignoring the check for putting own king in check)
                    local valid = false
                    if piece.type == "pawn" then
                        -- For pawns, we need to check if they can capture diagonally
                        local direction = opponentColor == "white" and -1 or 1
                        if math.abs(square.x - x) == 1 and square.y - y == direction then
                            valid = true
                        end
                    elseif piece.type == "rook" then
                        valid = rules.isValidRookMove(board, x, y, square.x, square.y)
                    elseif piece.type == "knight" then
                        valid = rules.isValidKnightMove(x, y, square.x, square.y)
                    elseif piece.type == "bishop" then
                        valid = rules.isValidBishopMove(board, x, y, square.x, square.y)
                    elseif piece.type == "queen" then
                        valid = rules.isValidQueenMove(board, x, y, square.x, square.y)
                    elseif piece.type == "king" then
                        -- For king vs king, we need to check if the destination is adjacent to the opponent's king
                        local kingDx = math.abs(square.x - x)
                        local kingDy = math.abs(square.y - y)
                        valid = kingDx <= 1 and kingDy <= 1
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

-- Check if a player is in checkmate
function rules.isCheckmate(board, color)
    -- First, check if the king is in check
    if not rules.isKingInCheck(board, color) then
        return false
    end
    
    -- Check if any legal move can get the king out of check
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
                            
                            -- Check if the king is still in check
                            local stillInCheck = rules.isKingInCheck(board, color)
                            
                            -- Undo the temporary move
                            board[fromY][fromX] = piece
                            board[toY][toX] = tempPiece
                            
                            -- If we found a move that gets the king out of check, it's not checkmate
                            if not stillInCheck then
                                return false
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- If we couldn't find any move that gets the king out of check, it's checkmate
    return true
end

-- Get all valid moves for a piece
function rules.getValidMoves(board, x, y, currentTurn, lastPawnMove)
    local moves = {}
    local piece = board[y][x]
    
    if not piece or piece.color ~= currentTurn then
        return moves
    end
    
    -- Check all possible destination squares
    for toY = 1, 8 do
        for toX = 1, 8 do
            if rules.isValidMove(board, x, y, toX, toY, currentTurn, lastPawnMove) then
                table.insert(moves, {x = toX, y = toY})
            end
        end
    end
    
    return moves
end

return rules 