import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics
local math = math

-- Game constants
local SCREEN_WIDTH = 400
local SCREEN_HEIGHT = 240
local KABOB_WIDTH = 40
local KABOB_HEIGHT = 10
local KABOB_Y = 220

-- Game state
local kabob = {
    x = SCREEN_WIDTH / 2,
    y = KABOB_Y,
    width = KABOB_WIDTH,
    height = KABOB_HEIGHT,
    speed = 8
}

local ingredients = {}
local score = 0
local gameRunning = true

-- Initialize the game
function init()
    playdate.display.setRefreshRate(30)
    math.randomseed(playdate.getSecondsSinceEpoch())
    
    -- Create initial ingredients
    for i = 1, 3 do
        spawnIngredient()
    end
end

-- Spawn a new ingredient at the top of the screen
function spawnIngredient()
    local ingredient = {
        x = math.random(0, SCREEN_WIDTH - 20),
        y = -20,
        width = 20,
        height = 20,
        speed = 2,
        type = math.random(1, 3) -- Different ingredient types
    }
    table.insert(ingredients, ingredient)
end

-- Update game logic
function update()
    if not gameRunning then return end
    
    -- Handle crank input for kabob movement
    local crankChange = playdate.getCrankChange()
    if crankChange ~= 0 then
        kabob.x = kabob.x + crankChange * 0.5
        -- Clamp kabob position to screen bounds
        if kabob.x < 0 then
            kabob.x = 0
        elseif kabob.x + kabob.width > SCREEN_WIDTH then
            kabob.x = SCREEN_WIDTH - kabob.width
        end
    end
    
    -- Update ingredients
    for i = #ingredients, 1, -1 do
        local ing = ingredients[i]
        ing.y = ing.y + ing.speed
        
        -- Check collision with kabob
        if checkCollision(kabob, ing) then
            table.remove(ingredients, i)
            score = score + 10
        elseif ing.y > SCREEN_HEIGHT then
            -- Ingredient fell off screen
            table.remove(ingredients, i)
        end
    end
    
    -- Spawn new ingredients occasionally
    if #ingredients < 5 and math.random(1, 100) < 5 then
        spawnIngredient()
    end
end

-- Check collision between two rectangles
function checkCollision(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and
           rect1.x + rect1.width > rect2.x and
           rect1.y < rect2.y + rect2.height and
           rect1.y + rect1.height > rect2.y
end

-- Draw the game
function draw()
    gfx.clear()
    
    -- Draw kabob stick
    gfx.fillRect(kabob.x, kabob.y, kabob.width, kabob.height)
    
    -- Draw ingredients
    for i, ing in ipairs(ingredients) do
        drawIngredient(ing)
    end
    
    -- Draw score
    gfx.drawText("Score: " .. score, 10, 10)
    
    -- Draw crank indicator
    gfx.drawText("Crank to move", SCREEN_WIDTH - 150, 10)
end

-- Draw an ingredient based on its type
function drawIngredient(ing)
    local colors = {
        {r = 1, g = 1, b = 0},  -- Yellow (cheese)
        {r = 1, g = 0, b = 0},  -- Red (tomato)
        {r = 0, g = 1, b = 0}   -- Green (pepper)
    }
    
    local color = colors[ing.type]
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(ing.x, ing.y, ing.width, ing.height)
end

-- Main game loop
function playdate.update()
    update()
    draw()
end

-- Initialize game on startup
init()
