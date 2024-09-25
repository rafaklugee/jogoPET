local love = require "love"
local button = require "Button"

math.randomseed(os.time())

local game = {
    difficulty = 1,
    state = {
        menu = true,
        paused = false,
        running = false,
        ended = false,
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
    speed = 8
}

local botao = {
    radius = 5,
    x = 30,
    y = 30
}

local buttons = { --botões do menu
    menu_state = {},
    ended_state = {}
}


local function changeGameState(state)
    game.state["menu"] = state == "menu"
    game.state["paused"] = state == "paused"
    game.state["running"] = state == "running"
    game.state["ended"] = state == "ended"
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
            elseif game.state["ended"] then
                for index in pairs(buttons.ended_state) do
                    buttons.ended_state[index]:checkPressed(x, y, botao.radius)
                end
            end
        end
    end
end

function love.load()
    camera = require 'libraries/camera'
    cam = camera()

    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require 'libraries/sti'
    gameMap = sti('maps/testMap.lua')

    love.window.setTitle("PETGAME")
    love.mouse.setVisible(false)

    
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png') -- Importando o bonequinho
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.1)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.1)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.1)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.1)

    player.anim = player.animations.left

    buttons.menu_state.play_game = button("Jogar", startNewGame, nil, 140, 40)
    buttons.menu_state.settings = button("Configurações", nil, nil, 140, 40)
    buttons.menu_state.exit_game = button("Sair do Jogo", love.event.quit, nil, 140, 40)

    buttons.ended_state.replay_game = button("Repetir", startNewGame, nil, 100, 50)
    buttons.ended_state.menu = button("Menu", changeGameState, "menu", 100, 50)
    buttons.ended_state.exit_game = button("Sair", love.event.quit, nil, 100, 50)
end

function love.update(dt)

    if game.state["menu"] or game.state["ended"] then
        player.x, player.y = love.mouse.getPosition() --cursor aparecer
    end

    local isMoving = false

    if game.state["running"] then
        if love.keyboard.isDown ("right") then
            player.x = player.x + player.speed
            player.anim = player.animations.right
            isMoving = true
        end

        if love.keyboard.isDown ("left") then
            player.x = player.x - player.speed
            player.anim = player.animations.left
            isMoving = true
        end

        if love.keyboard.isDown ("down") then
            player.y = player.y + player.speed
            player.anim = player.animations.down
            isMoving = true
        end

        if love.keyboard.isDown ("up") then
            player.y = player.y - player.speed
            player.anim = player.animations.up
            isMoving = true
        end

        if isMoving == false then
            player.anim:gotoFrame(2)
        end
    end

    player.anim:update(dt)

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
    love.graphics.setFont(fonts.medium.font)
    love.graphics.printf( --obter o FPS
        "FPS: " .. love.timer.getFPS(),
        fonts.medium.font,
        10,
        love.graphics.getHeight() - 30,
        love.graphics.getWidth()
    )

    --love.graphics.circle ("fill", player.x, player.y, player.radius) --desenhando a bolinha

    if game.state["running"] then
        --love.graphics.printf(math.floor(game.points), fonts.large.font, 0, 10, love.graphics.getWidth(), "center")
        cam:attach()
            gameMap:drawLayer(gameMap.layers["Ground"]) --desenhando chão
            gameMap:drawLayer(gameMap.layers["Trees"]) --desenhando árvores
            player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
        cam:detach()

    elseif game.state["menu"] then
        buttons.menu_state.play_game:draw(10, 20, 17, 10)
        buttons.menu_state.settings:draw(10, 70, 17, 10)
        buttons.menu_state.exit_game:draw(10, 120, 17, 10)

    elseif game.state["ended"] then
        love.graphics.setFont(fonts.large.font)

        buttons.ended_state.replay_game:draw(love.graphics.getWidth() / 2.25, love.graphics.getHeight() / 1.8, 10, 10)
        buttons.ended_state.menu:draw(love.graphics.getWidth() / 2.25, love.graphics.getHeight() / 1.53, 17, 10)
        buttons.ended_state.exit_game:draw(love.graphics.getWidth() / 2.25, love.graphics.getHeight() / 1.33, 22, 10)

        --love.graphics.printf(math.floor(game.points), fonts.massive.font, 0, love.graphics.getHeight() / 2 - fonts.large.size - 50, love.graphics.getWidth(), "center")
    end

    if not game.state["running"] then
        love.graphics.circle ("fill", player.x, player.y, botao.radius)
    end
end