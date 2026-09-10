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
    ingredients = {}
}

local ingredients = {}
local score = 0
local gameRunning = true
local currentCharacter = nil
local characterTimer = 0
local CHARACTER_DURATION = 10

-- Characters and their requests
local characters = {
    {
        name = "Bob",
        requesting = {INGREDIENTS.shrimp, INGREDIENTS.bread}
    },
    {
        name = "Alice",
        requesting = {INGREDIENTS.beef, INGREDIENTS.peppers, INGREDIENTS.onions}
    },
    {
        name = "Charlie",
        requesting = {INGREDIENTS.chicken, INGREDIENTS.onions, INGREDIENTS.bread}
    },
    {
        name = "Diana",
        requesting = {INGREDIENTS.beef, INGREDIENTS.peppers}
    },
    {
        name = "Eve",
        requesting = {INGREDIENTS.shrimp, INGREDIENTS.peppers}
    },
    {
        name = "Frank",
        requesting = {INGREDIENTS.chicken, INGREDIENTS.peppers, INGREDIENTS.onions, INGREDIENTS.bread}
    }
}

function init()
    playdate.display.setRefreshRate(30)
    math.randomseed(playdate.getSecondsSinceEpoch())
    
    kabob.ingredients = {}
    changeCharacter()
    
    for i = 1, 3 do
        spawnIngredient()
    end
end

function changeCharacter()
    currentCharacter = characters[math.random(1, #characters)]
    characterTimer = CHARACTER_DURATION
end

function spawnIngredient()
    local ingredient = {
        x = math.random(0, SCREEN_WIDTH - CHARACTER_PANEL_WIDTH - 20),
        y = -20,
        width = 20,
        height = 20,
        speed = 2,
        type = math.random(1, 6)
    }
    table.insert(ingredients, ingredient)
end

function checkCharacterRequest()
    if not currentCharacter then return false end
    
    local kabobIngredients = {}
    for i, ing in ipairs(kabob.ingredients) do
        table.insert(kabobIngredients, ing)
    end
    
    table.sort(kabobIngredients)
    local requestCopy = {}
    for i, ing in ipairs(currentCharacter.requesting) do
        table.insert(requestCopy, ing)
    end
    table.sort(requestCopy)
    
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

function update()
    if not gameRunning then return end
    
    local crankChange = playdate.getCrankChange()
    if crankChange ~= 0 then
        kabob.x = kabob.x + crankChange * 0.5
        if kabob.x < 0 then
            kabob.x = 0
        elseif kabob.x + kabob.width > SCREEN_WIDTH - CHARACTER_PANEL_WIDTH then
            kabob.x = SCREEN_WIDTH - CHARACTER_PANEL_WIDTH - kabob.width
        end
    end
    
    if playdate.buttonJustPressed(playdate.kButtonA) or 
       playdate.buttonJustPressed(playdate.kButtonB) then
        if checkCharacterRequest() then
            score = score + 100
            kabob.ingredients = {}
            changeCharacter()
        else
            score = math.max(0, score - 10)
        end
    end
    
    characterTimer = characterTimer - (1/30)
    if characterTimer <= 0 then
        changeCharacter()
    end
    
    for i = #ingredients, 1, -1 do
        local ing = ingredients[i]
        ing.y = ing.y + ing.speed
        
        if checkCollision(kabob, ing) then
            table.remove(ingredients, i)
            score = score + 5
            table.insert(kabob.ingredients, ing.type)
        elseif ing.y > SCREEN_HEIGHT then
            table.remove(ingredients, i)
        end
    end
    
    if #ingredients < 6 and math.random(1, 100) < 4 then
        spawnIngredient()
    end
end

function checkCollision(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and
           rect1.x + rect1.width > rect2.x and
           rect1.y < rect2.y + rect2.height and
           rect1.y + rect1.height > rect2.y
end

function draw()
    gfx.clear()
    
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(SCREEN_WIDTH - CHARACTER_PANEL_WIDTH, 0, SCREEN_WIDTH - CHARACTER_PANEL_WIDTH, SCREEN_HEIGHT)
    
    gfx.fillRect(kabob.x, kabob.y, kabob.width, kabob.height)
    drawKabobIngredients()
    
    for i, ing in ipairs(ingredients) do
        drawIngredient(ing)
    end
    
    drawCharacterPanel()
    
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Score: " .. score, 10, 10)
end

function drawKabobIngredients()
    local kabobCenterX = kabob.x + kabob.width / 2
    
    for i, ingType in ipairs(kabob.ingredients) do
        local yPos = kabob.y - (i * 5)
        gfx.setColor(gfx.kColorBlack)
        
        if ingType == INGREDIENTS.shrimp then
            gfx.fillCircle(kabobCenterX, yPos, 2)
        elseif ingType == INGREDIENTS.beef then
            gfx.fillRect(kabobCenterX - 4, yPos - 3, 8, 6)
        elseif ingType == INGREDIENTS.chicken then
            gfx.fillCircle(kabobCenterX, yPos, 3)
        elseif ingType == INGREDIENTS.peppers then
            gfx.fillRect(kabobCenterX - 3, yPos - 4, 6, 8)
        elseif ingType == INGREDIENTS.onions then
            gfx.drawCircle(kabobCenterX, yPos, 3)
        elseif ingType == INGREDIENTS.bread then
            gfx.fillRect(kabobCenterX - 5, yPos - 2, 10, 4)
        end
    end
end

function drawIngredient(ing)
    gfx.setColor(gfx.kColorBlack)
    
    if ing.type == INGREDIENTS.shrimp then
        gfx.fillCircle(ing.x + ing.width/2, ing.y + ing.height/2, 2)
    elseif ing.type == INGREDIENTS.beef then
        gfx.fillRect(ing.x, ing.y, ing.width, ing.height)
    elseif ing.type == INGREDIENTS.chicken then
        gfx.fillCircle(ing.x + ing.width/2, ing.y + ing.height/2, ing.width/2)
    elseif ing.type == INGREDIENTS.peppers then
        gfx.fillRect(ing.x, ing.y, ing.width, ing.height)
    elseif ing.type == INGREDIENTS.onions then
        gfx.drawCircle(ing.x + ing.width/2, ing.y + ing.height/2, ing.width/2)
    elseif ing.type == INGREDIENTS.bread then
        gfx.fillRect(ing.x, ing.y, ing.width, ing.height)
    end
end

function drawCharacterPanel()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(CHARACTER_PANEL_X, 0, CHARACTER_PANEL_WIDTH, SCREEN_HEIGHT)
    
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(CHARACTER_PANEL_X, 0, CHARACTER_PANEL_WIDTH, SCREEN_HEIGHT)
    
    if currentCharacter then
        gfx.drawText(currentCharacter.name, CHARACTER_PANEL_X + 5, 15)
        gfx.drawText("Wants:", CHARACTER_PANEL_X + 5, 35)
        
        local yOffset = 50
        for i, ingType in ipairs(currentCharacter.requesting) do
            local ingredientName = INGREDIENT_NAMES[ingType]
            gfx.drawText("* " .. ingredientName, CHARACTER_PANEL_X + 8, yOffset, 105)
            yOffset = yOffset + 12
        end
        
        local timerWidth = (characterTimer / CHARACTER_DURATION) * (CHARACTER_PANEL_WIDTH - 10)
        gfx.drawRect(CHARACTER_PANEL_X + 5, SCREEN_HEIGHT - 50, CHARACTER_PANEL_WIDTH - 10, 8)
        gfx.fillRect(CHARACTER_PANEL_X + 5, SCREEN_HEIGHT - 50, timerWidth, 8)
        
        local timeRemaining = math.ceil(characterTimer)
        gfx.drawText(timeRemaining .. "s", CHARACTER_PANEL_X + 32, SCREEN_HEIGHT - 35)
        
        gfx.drawText("A/B: Serve", CHARACTER_PANEL_X + 5, SCREEN_HEIGHT - 15)
    end
end

function playdate.update()
    update()
    draw()
end

init()
