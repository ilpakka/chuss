-- Effects management for Chuss

local effects = {}

-- Effect types
effects.TYPES = {
    SHIELD = "shield",
    ATTACK = "attack"
}

-- Load effect images
function effects.loadImages()
    local effectImages = {}
    
    -- Load shield effect image
    effectImages[effects.TYPES.SHIELD] = love.graphics.newImage("assets/img/effects/shield.png")
    
    -- Load attack effect image
    effectImages[effects.TYPES.ATTACK] = love.graphics.newImage("assets/img/effects/attack.png")
    
    return effectImages
end

-- Apply an effect to a piece
function effects.applyEffect(board, x, y, effectType)
    local piece = board.getPiece(x, y)
    if piece then
        -- Initialize effects table if it doesn't exist
        if not piece.effects then
            piece.effects = {}
        end
        
        -- Add the effect
        piece.effects[effectType] = true
        
        return true
    end
    return false
end

-- Remove an effect from a piece
function effects.removeEffect(board, x, y, effectType)
    local piece = board.getPiece(x, y)
    if piece and piece.effects and piece.effects[effectType] then
        piece.effects[effectType] = nil
        
        -- If no effects left, remove the effects table
        local hasEffects = false
        for _ in pairs(piece.effects) do
            hasEffects = true
            break
        end
        
        if not hasEffects then
            piece.effects = nil
        end
        
        return true
    end
    return false
end

-- Remove a random effect from a piece
function effects.removeRandomEffect(board, x, y)
    local piece = board.getPiece(x, y)
    if piece and piece.effects then
        -- Find all effects on the piece
        local effectTypes = {}
        for effectType, _ in pairs(piece.effects) do
            table.insert(effectTypes, effectType)
        end
        
        -- If there are effects, remove a random one
        if #effectTypes > 0 then
            local randomIndex = math.random(1, #effectTypes)
            local effectToRemove = effectTypes[randomIndex]
            effects.removeEffect(board, x, y, effectToRemove)
            return effectToRemove
        end
    end
    return nil
end

-- Check if a piece has a specific effect
function effects.hasEffect(board, x, y, effectType)
    local piece = board.getPiece(x, y)
    return piece and piece.effects and piece.effects[effectType] == true
end

-- Handle effect interactions during capture
function effects.handleCapture(board, fromX, fromY, toX, toY)
    local attackingPiece = board.getPiece(fromX, fromY)
    local defendingPiece = board.getPiece(toX, toY)
    
    if not attackingPiece or not defendingPiece then
        return false, false -- No capture occurred, piece should move normally
    end
    
    -- Check for shield effect
    local hasShield = effects.hasEffect(board, toX, toY, effects.TYPES.SHIELD)
    local hasAttack = effects.hasEffect(board, fromX, fromY, effects.TYPES.ATTACK)
    
    if hasShield then
        if hasAttack then
            -- Attack effect bypasses shield completely
            effects.removeEffect(board, toX, toY, effects.TYPES.SHIELD)
            -- Remove the attack effect from the attacking piece
            effects.removeEffect(board, fromX, fromY, effects.TYPES.ATTACK)
            return true, true -- Capture occurred, piece should move
        else
            -- Shield protects the piece
            effects.removeEffect(board, toX, toY, effects.TYPES.SHIELD)
            return false, false -- No capture occurred, piece should not move
        end
    end
    
    -- Normal capture
    return true, true
end

return effects 