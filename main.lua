local love = require "love"
local button = require "Button"

math.randomseed(os.time())

local game = {
    --difficulty = 1,
    state = {
        menu = true,
        paused = false,
        running = false,
        paused = false,
    },
    --points = 0,
    --levels = {15, 30, 45, 60, 75, 120}
}

local fonts = {
    medium = {
        font = love.graphics.newFont(16),
        size = 16
    },
    large = {
        font = love.graphics.newFont(24),
        size = 16
    },
    massive = {
        font = love.graphics.newFont(60),
        size = 16
    }
}

local player = { --dimensões do bonequinho
    radius = 20,
    x = 30,
    y = 30,
    speed = 300
}

local cursorX, cursorY = 0, 0

local cursorImage = {}

local botao = {
    radius = 5,
    x = 30,
    y = 30
}

local buttons = { --botões do menu
    menu_state = {},
    paused_state = {}
}


local function changeGameState(state)
    game.state["menu"] = state == "menu"
    game.state["ended"] = state == "ended"
    game.state["running"] = state == "running"
    game.state["paused"] = state == "paused"
end

local function startNewGame ()
    changeGameState("running")
    --game.points = 0
end

function love.mousepressed(x, y, button, istouch, presses) --Mouse clicar nos botões
    if not game.state["running"] then
        if button == 1 then
            if game.state["menu"] then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index]:checkPressed(x, y, botao.radius)
                end
            elseif game.state["paused"] then
                for index in pairs(buttons.paused_state) do
                    buttons.paused_state[index]:checkPressed(x, y, botao.radius)
                end
            end
        end
    end
end

function love.load()
    wf = require 'libraries/windfield'
    world = wf.newWorld(0, 0)

    camera = require 'libraries/camera'
    cam = camera()

    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require 'libraries/sti'
    gameMap = sti('maps/testMap.lua')
    menuMap = sti ('maps/menu.lua')

    love.window.setTitle("PETGAME")
    love.mouse.setVisible(false)

    sounds = {}
    sounds.blip = love.audio.newSource('sounds/blip.mp3', 'static')
    sounds.music = love.audio.newSource('sounds/staff_roll.mp3', 'stream')
    sounds.music:setLooping(true)

    sounds.music:play()

    cursorImage = love.graphics.newImage('libraries/cursor/cursor1.png')

    font8bit = love.graphics.newFont('libraries/fonts/8-bit-pusab.ttf')

    player.collider = world:newBSGRectangleCollider(400, 250, 50, 80, 10)
    player.collider:setFixedRotation(true)
    
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png') -- Importando o bonequinho
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.1)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.1)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.1)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.1)

    player.anim = player.animations.left

    walls = {}
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType('static')
            table.insert(walls, wall)
        end
    end

    buttons.menu_state.play_game = button("Jogar", startNewGame, nil, 140, 40)
    buttons.menu_state.settings = button("Ajustes", nil, nil, 140, 40)
    buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 140, 40)

    buttons.paused_state.replay_game = button("Voltar", startNewGame, nil, 140, 40)
    buttons.paused_state.menu = button("Menu", changeGameState, "menu", 140, 40)
    buttons.paused_state.exit_game = button("Sair", love.event.quit, nil, 140, 40)
end

function love.update(dt)

    if game.state["menu"] or game.state["paused"] then
        cursorX, cursorY = love.mouse.getPosition() --cursor aparecer
    end

    local isMoving = false

    if game.state["running"] then
        player.anim:update(dt)

        local vx = 0
        local vy = 0

        if love.keyboard.isDown ("right") then
            vx = player.speed
            player.anim = player.animations.right
            isMoving = true
        end

        if love.keyboard.isDown ("left") then
            vx = player.speed * -1
            player.anim = player.animations.left
            isMoving = true
        end

        if love.keyboard.isDown ("down") then
            vy = player.speed
            player.anim = player.animations.down
            isMoving = true
        end

        if love.keyboard.isDown ("up") then
            vy = player.speed * -1
            player.anim = player.animations.up
            isMoving = true
        end

        player.collider:setLinearVelocity(vx, vy)

        if isMoving == false then
            player.anim:gotoFrame(2)
        end

        world:update(dt)
        player.x = player.collider:getX()
        player.y = player.collider:getY()
    end

    cam:lookAt(player.x, player.y) -- Camera seguir o boneco

    -- Não aparecer bordas pretas
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if cam.x < w/2 then
        cam.x = w/2
    end

    if cam.y < h/2 then
        cam.y = h/2
    end

    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end

    if cam.y > (mapH - h/2) then
        cam.y = (mapH - h/2)
    end
    --
end

function love.draw()
    --[[
    love.graphics.setFont(fonts.medium.font)
    love.graphics.printf( --obter o FPS
        "FPS: " .. love.timer.getFPS(),
        fonts.medium.font,
        10,
        love.graphics.getHeight() - 30,
        love.graphics.getWidth()
    )
    ]]

    --love.graphics.circle ("fill", player.x, player.y, player.radius) --desenhando a bolinha
    love.graphics.setFont(font8bit)

    if game.state["running"] or game.state["paused"] then
        --love.graphics.printf(math.floor(game.points), fonts.large.font, 0, 10, love.graphics.getWidth(), "center")
        cam:attach()
            gameMap:drawLayer(gameMap.layers["Ground"]) --desenhando chão
            gameMap:drawLayer(gameMap.layers["Trees"]) --desenhando árvores
            player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
            --world:draw()
        cam:detach() 
    end

    if game.state["menu"] then
        menuMap:drawLayer(menuMap.layers["default"])
        menuMap:drawLayer(menuMap.layers["trees"])
        buttons.menu_state.play_game:draw(350, 230, 17, 10)
        buttons.menu_state.settings:draw(350, 280, 17, 10)
        buttons.menu_state.exit_game:draw(350, 330, 17, 10)

    elseif game.state["paused"] then
        buttons.paused_state.replay_game:draw(180, 100, 17, 10)
        buttons.paused_state.menu:draw(330, 100, 17, 10)
        buttons.paused_state.exit_game:draw(480, 100, 17, 10)
    end

    -- Desenhando o cursor
    if not game.state["running"] then
        local scale = 0.3
        love.graphics.draw(cursorImage, cursorX, cursorY, nil, scale, scale)
        --love.graphics.circle ("fill", player.x, player.y, botao.radius)
    end
end

-- Teclas de atalho
function love.keypressed(key)
    if key == 'escape' then
        if game.state["paused"] then
            changeGameState("running")
        elseif game.state["running"] then
            changeGameState("paused")
        end
    end

    if key == 'space' then
        sounds.blip:play()
    end
    if key == 'z' then
        sounds.music:stop()
    end
end