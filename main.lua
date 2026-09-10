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
local CHARACTER_PANEL_WIDTH = 120
local CHARACTER_PANEL_X = SCREEN_WIDTH - CHARACTER_PANEL_WIDTH

-- Ingredient types
local INGREDIENTS = {
    shrimp = 1,
    beef = 2,
    chicken = 3,
    peppers = 4,
    onions = 5,
    bread = 6
}

local INGREDIENT_NAMES = {
    [1] = "Shrimp",
    [2] = "Beef",
    [3] = "Chicken",
    [4] = "Peppers",
    [5] = "Onions",
    [6] = "Bread"
}

-- Game state
local kabob = {
    x = SCREEN_WIDTH / 2,
    y = KABOB_Y,
    width = KABOB_WIDTH,
    height = KABOB_HEIGHT,
    speed = 8,
    ingredients = {} -- Track collected ingredients on kabob
}

local ingredients = {}
local score = 0
local gameRunning = true
local currentCharacter = nil
local characterTimer = 0
local CHARACTER_DURATION = 10 -- Seconds per character

-- Characters and their requests (specific ingredient combinations)
local characters = {
    {
        name = "Bob",
        emoji = "😊",
        requesting = {INGREDIENTS.shrimp, INGREDIENTS.bread}, -- Shrimp kabob
        color = gfx.kColorBlack
    },
    {
        name = "Alice",
        emoji = "😋",
        requesting = {INGREDIENTS.beef, INGREDIENTS.peppers, INGREDIENTS.onions}, -- Beef kabob
        color = gfx.kColorBlack
    },
    {
        name = "Charlie",
        emoji = "🤔",
        requesting = {INGREDIENTS.chicken, INGREDIENTS.onions, INGREDIENTS.bread}, -- Chicken kabob
        color = gfx.kColorBlack
    },
    {
        name = "Diana",
        emoji = "🎉",
        requesting = {INGREDIENTS.beef, INGREDIENTS.peppers}, -- Beef & peppers
        color = gfx.kColorBlack
    },
    {
        name = "Eve",
        emoji = "🧡",
        requesting = {INGREDIENTS.shrimp, INGREDIENTS.peppers}, -- Shrimp & peppers
        color = gfx.kColorBlack
    },
    {
        name = "Frank",
        emoji = "😎",
        requesting = {INGREDIENTS.chicken, INGREDIENTS.peppers, INGREDIENTS.onions, INGREDIENTS.bread}, -- Full chicken
        color = gfx.kColorBlack
    }
}

-- Initialize the game
function init()
    playdate.display.setRefreshRate(30)
    math.randomseed(playdate.getSecondsSinceEpoch())
    
    -- Initialize kabob ingredients
    kabob.ingredients = {}
    
    -- Set first character
    changeCharacter()
    
    -- Create initial ingredients
    for i = 1, 3 do
        spawnIngredient()
    end
end

-- Change to a random character
function changeCharacter()
    currentCharacter = characters[math.random(1, #characters)]
    characterTimer = CHARACTER_DURATION
end

-- Spawn a new ingredient at the top of the screen
function spawnIngredient()
    local ingredient = {
        x = math.random(0, SCREEN_WIDTH - CHARACTER_PANEL_WIDTH - 20),
        y = -20,
        width = 20,
        height = 20,
        speed = 2,
        type = math.random(1, 6) -- All 6 ingredient types
    }
    table.insert(ingredients, ingredient)
end

-- Check if kabob ingredients match character's request exactly
function checkCharacterRequest()
    if not currentCharacter then return false end
    
    local kabobIngredients = {}
    for i, ing in ipairs(kabob.ingredients) do
        table.insert(kabobIngredients, ing)
    end
    
    -- Sort both lists to compare
    table.sort(kabobIngredients)
    local requestCopy = {}
    for i, ing in ipairs(currentCharacter.requesting) do
        table.insert(requestCopy, ing)
    end
    table.sort(requestCopy)
    
    -- Check if they match
    if #kabobIngredients ~= #requestCopy then
        return false
    end
    
    for i = 1, #kabobIngredients do
        if kabobIngredients[i] ~= requestCopy[i] then
            return false
        end
    end
    
    return true
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
        elseif kabob.x + kabob.width > SCREEN_WIDTH - CHARACTER_PANEL_WIDTH then
            kabob.x = SCREEN_WIDTH - CHARACTER_PANEL_WIDTH - kabob.width
        end
    end
    
    -- Handle button presses to check if kabob matches character request
    if playdate.buttonJustPressed(playdate.kButtonA) or 
       playdate.buttonJustPressed(playdate.kButtonB) then
        if checkCharacterRequest() then
            -- Correct! Award points
            score = score + 100
            kabob.ingredients = {}
            changeCharacter()
        else
            -- Wrong combination - lose some points
            score = math.max(0, score - 10)
        end
    end
    
    -- Update character timer
    characterTimer = characterTimer - (1/30) -- Subtract based on frame time
    if characterTimer <= 0 then
        changeCharacter()
    end
    
    -- Update ingredients
    for i = #ingredients, 1, -1 do
        local ing = ingredients[i]
        ing.y = ing.y + ing.speed
        
        -- Check collision with kabob
        if checkCollision(kabob, ing) then
            table.remove(ingredients, i)
            score = score + 5 -- Small points for catching
            -- Add ingredient to kabob
            table.insert(kabob.ingredients, ing.type)
        elseif ing.y > SCREEN_HEIGHT then
            -- Ingredient fell off screen
            table.remove(ingredients, i)
        end
    end
    
    -- Spawn new ingredients occasionally
    if #ingredients < 6 and math.random(1, 100) < 4 then
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
    
    -- Draw game area divider
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(SCREEN_WIDTH - CHARACTER_PANEL_WIDTH, 0, SCREEN_WIDTH - CHARACTER_PANEL_WIDTH, SCREEN_HEIGHT)
    
    -- Draw kabob stick
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(kabob.x, kabob.y, kabob.width, kabob.height)
    
    -- Draw kabob ingredients collected
    drawKabobIngredients()
    
    -- Draw ingredients falling
    for i, ing in ipairs(ingredients) do
        drawIngredient(ing)
    end
    
    -- Draw character panel
    drawCharacterPanel()
    
    -- Draw score
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Score: " .. score, 10, 10)
end

-- Draw the collected ingredients on the kabob stick
function drawKabobIngredients()
    local kabobCenterX = kabob.x + kabob.width / 2
    
    -- Draw ingredients stacked on the kabob
    for i, ingType in ipairs(kabob.ingredients) do
        local yPos = kabob.y - (i * 5)
        
        gfx.setColor(gfx.kColorBlack)
        -- Draw different patterns for different ingredients
        if ingType == INGREDIENTS.shrimp then
            gfx.drawString("🦐", kabobCenterX - 5, yPos - 4)
        elseif ingType == INGREDIENTS.beef then
            gfx.fillRect(kabobCenterX - 4, yPos - 3, 8, 6) -- Rectangle for beef
        elseif ingType == INGREDIENTS.chicken then
            gfx.fillCircle(kabobCenterX, yPos, 3) -- Circle for chicken
        elseif ingType == INGREDIENTS.peppers then
            gfx.fillRect(kabobCenterX - 3, yPos - 4, 6, 8) -- Vertical rect for peppers
        elseif ingType == INGREDIENTS.onions then
            gfx.drawCircle(kabobCenterX, yPos, 3) -- Circle outline for onions
        elseif ingType == INGREDIENTS.bread then
            gfx.fillRect(kabobCenterX - 5, yPos - 2, 10, 4) -- Wide rect for bread
        end
    end
end

-- Draw an ingredient based on its type
function drawIngredient(ing)
    gfx.setColor(gfx.kColorBlack)
    
    -- Draw different shapes for different ingredients
    if ing.type == INGREDIENTS.shrimp then
        gfx.drawString("🦐", ing.x, ing.y)
    elseif ing.type == INGREDIENTS.beef then
        gfx.fillRect(ing.x, ing.y, ing.width, ing.height) -- Solid square
    elseif ing.type == INGREDIENTS.chicken then
        gfx.fillCircle(ing.x + ing.width/2, ing.y + ing.height/2, ing.width/2) -- Circle
    elseif ing.type == INGREDIENTS.peppers then
        gfx.fillRect(ing.x, ing.y, ing.width, ing.height) -- Vertical rectangle
    elseif ing.type == INGREDIENTS.onions then
        gfx.drawCircle(ing.x + ing.width/2, ing.y + ing.height/2, ing.width/2) -- Circle outline
    elseif ing.type == INGREDIENTS.bread then
        gfx.fillRect(ing.x, ing.y, ing.width, ing.height) -- Wide rectangle
    end
end

-- Draw character panel on right side
function drawCharacterPanel()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(CHARACTER_PANEL_X, 0, CHARACTER_PANEL_WIDTH, SCREEN_HEIGHT)
    
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(CHARACTER_PANEL_X, 0, CHARACTER_PANEL_WIDTH, SCREEN_HEIGHT)
    
    if currentCharacter then
        -- Draw character name
        gfx.drawText(currentCharacter.name, CHARACTER_PANEL_X + 5, 15)
        
        -- Draw "Wants:" label
        gfx.drawText("Wants:", CHARACTER_PANEL_X + 5, 35)
        
        -- Draw requested ingredients list
        local yOffset = 50
        for i, ingType in ipairs(currentCharacter.requesting) do
            local ingredientName = INGREDIENT_NAMES[ingType]
            gfx.drawText("• " .. ingredientName, CHARACTER_PANEL_X + 8, yOffset, 105)
            yOffset = yOffset + 12
        end
        
        -- Draw timer bar
        local timerWidth = (characterTimer / CHARACTER_DURATION) * (CHARACTER_PANEL_WIDTH - 10)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(CHARACTER_PANEL_X + 5, SCREEN_HEIGHT - 50, CHARACTER_PANEL_WIDTH - 10, 8)
        gfx.fillRect(CHARACTER_PANEL_X + 5, SCREEN_HEIGHT - 50, timerWidth, 8)
        
        -- Draw time text
        local timeRemaining = math.ceil(characterTimer)
        gfx.drawText(timeRemaining .. "s", CHARACTER_PANEL_X + 32, SCREEN_HEIGHT - 35)
        
        -- Draw instruction
        gfx.drawText("A/B: Serve", CHARACTER_PANEL_X + 5, SCREEN_HEIGHT - 15)
    end
end

-- Main game loop
function playdate.update()
    update()
    draw()
end

-- Initialize game on startup
init()
