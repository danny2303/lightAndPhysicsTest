brickRun = {}

Shadows = require("shadows")
LightWorld = require("shadows.LightWorld")
Light = require("shadows.Light")
Body = require("shadows.Body")
PolygonShadow = require("shadows.ShadowShapes.PolygonShadow")
CircleShadow = require("shadows.ShadowShapes.CircleShadow")

local mapWidth  = 5000
local mapHeight = 5000

newLightWorld = LightWorld:new()
newLightWorld:Resize(mapWidth,mapHeight)
newLightWorld:SetColor(50,50,50)

function brickRun.load()

  digitalFont = love.graphics.newFont("digitalFont.ttf", 64)

  brickImage = love.graphics.newImage("brickImage.png")
  playerImage = love.graphics.newImage("playerImage.png")

  love.physics.setMeter(64) --the height of a meter our worlds will be 64px
  physWorld = love.physics.newWorld(0, 0, true) --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
  physWorld:setCallbacks(manageCollison)

  love.window.setFullscreen(true)

    -- create the components
    world:addComponent("position",  {x=0,y=0})
    world:addComponent("hasInput",  {})
    world:addComponent("physics",  {body,shape,fixture})
    world:addComponent("light",  {})
    world:addComponent("shadow", {shadowObject = nil, shadowBody = nil})
    world:addComponent("image",  {image=brickImage})
    world:addComponent("rectangle",  {width = 42, height = 42})
    world:addComponent("followsPlayer", {speed = 250})
    world:addComponent("stats", {health = 3})

    world:addSystem("updateLight", {
        update = function(self,dt)
            for entity in pairs(world:query("light position")) do
                local color = entity.light.lightColor
                entity.light.lightObject:SetColor(color.r,color.b,color.g)
                entity.light.lightObject:SetPosition(entity.position.x,entity.position.y, 1.1)
            end
        end
    })

    world:addSystem("followPlayer", {
        update = function(self,dt)
            for entity in pairs(world:query("followsPlayer physics")) do
                dir,mag = convertVector({x = player.physics.body:getX() - entity.physics.body:getX(), y = player.physics.body:getY() - entity.physics.body:getY()})
                mag = entity.followsPlayer.speed
                local vector = convertDirection(dir,mag)
                entity.physics.body:applyForce(vector.x,vector.y)
            end
        end
    })

    world:addSystem("updateShadow", {
        update = function(self,dt)
            for entity in pairs(world:query("shadow")) do
                entity.shadow.shadowBody:SetAngle(180/math.pi * entity.physics.body:getAngle())
            end
        end
    })

    world:addSystem("writePhysicsValues",{
        update = function(self,dt)
            for entity in pairs(world:query("physics")) do
                if not(entity.position) then world:attach(entity,{position = {}}) end
                entity.position.x = entity.physics.body:getX()
                entity.position.y = entity.physics.body:getY()
            end
        end
    })
    
    -- add an "input" system with an update callback
    -- this system will handle processing user input
    world:addSystem("input", { 
        speed = 1000, 
        update = function(self, dt)
            for entity in pairs(world:query("hasInput")) do

                local pos = entity.position
                if love.keyboard.isDown("up") then 
                    entity.physics.body:applyForce(0, -self.speed)
                end
                
                if love.keyboard.isDown("down") then
                    entity.physics.body:applyForce(0, self.speed)
                end
                
                if love.keyboard.isDown("left") then
                    entity.physics.body:applyForce(-self.speed, 0)
                end
                
                if love.keyboard.isDown("right") then
                    entity.physics.body:applyForce(self.speed, 0)
                end

            end
        end
    })
    
    -- add a "render" system with a draw callback
    -- this system will handle rendering rectangles
    world:addSystem("render", { 
        draw = function(self)
            for entity in pairs(world:query("image physics")) do

                local x = entity.physics.body:getX()
                local y = entity.physics.body:getY()
                local screenleft = player.physics.body:getX() - love.graphics.getWidth()/2 - 20
                local screenright = player.physics.body:getX() + love.graphics.getWidth()/2 + 20
                local screenup = player.physics.body:getY() - love.graphics.getHeight()/2 -20
                local screendown = player.physics.body:getY() + love.graphics.getHeight()/2 + 20

                if x > screenleft and x < screenright and y > screenup and y < screendown then
                    love.graphics.draw(entity.image.image, x,y, entity.physics.body:getAngle(),  0.5, 0.5, entity.image.image:getWidth()/2, entity.image.image:getHeight()/2)
                end

            end
        end
    })


    --create a player entity

    local body = love.physics.newBody(physWorld, mapWidth/2, mapHeight/2,"dynamic")
    body:setUserData("playerBody")
    body:setLinearDamping(1)
    body:setAngularDamping(1)
    local shape = love.physics.newRectangleShape(50, 50)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setFilterData(1,2,0)

    player = world:addEntity({
        hasInput = {},
        physics = {body = body, shape = shape, fixture = fixture},
        image = {image = playerImage},
        light = {lightObject = Light:new(newLightWorld, 700), lightColor = {r=255,b=255,g=255}},
        stats = {},
        inBrickRun = {}
    })


    --create world boarders

    local body = love.physics.newBody(physWorld,love.graphics.getWidth()/2,mapHeight/2,"static")
    body:setUserData("boarder")
    local shape = love.physics.newRectangleShape(1,mapHeight)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setFilterData(2,1,0)
    world:addEntity({
        inBrickRun = {},
        physics = {body=body,shape=shape,fixture=fixture}
    })

    local body = love.physics.newBody(physWorld,mapWidth/2,love.graphics.getHeight()/2,"static")
    local shape = love.physics.newRectangleShape(mapWidth,1)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setFilterData(2,1,0)
    world:addEntity({
        inBrickRun = {},
        physics = {body=body,shape=shape,fixture=fixture}
    })

    local body = love.physics.newBody(physWorld,mapWidth - love.graphics.getWidth()/2 , mapHeight/2,"static")
    local shape = love.physics.newRectangleShape(1,mapHeight)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setFilterData(2,1,0)
    world:addEntity({
        inBrickRun = {},
        physics = {body=body,shape=shape,fixture=fixture}
    })

    local body = love.physics.newBody(physWorld,mapWidth/2,mapHeight - love.graphics.getHeight()/2,"static")
    local shape = love.physics.newRectangleShape(mapWidth,1)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setFilterData(2,1,0)
    world:addEntity({
        inBrickRun = {},
        physics = {body=body,shape=shape,fixture=fixture}
    })     

    numBricks = 0

end

function brickRun.update(dt)
    world:update(dt)
    physWorld:update(dt)
    newLightWorld:Update()
    if player.stats.health < 1 then
        closeBrickRun()
    end

    if math.random(1,5) == 1 and numBricks < 1000 then
        local x = math.random(0,mapWidth)
        local y =  math.random(0,mapHeight)
        local px = player.physics.body:getX()
        local py = player.physics.body:getY()

        local spacing = 30

        if not((x < px + spacing and x > px - spacing) and (y < py + spacing and y > py-spacing)) then

            numBricks = numBricks + 1

                --create a rectangle entity

            local body = love.physics.newBody(physWorld,x ,y ,"dynamic")
            body:setUserData("brick")
            body:setLinearDamping(1)
            body:setAngularDamping(1)
            local shape = love.physics.newRectangleShape(50, 50)
            local fixture = love.physics.newFixture(body, shape)
            fixture:setFilterData(3,1,0)
            local shadowBody = Body:new(newLightWorld)

            shadowBody:TrackPhysics(body)

            if math.random(1,10) > 1 then
                world:addEntity({
                    inBrickRun = {},
                    physics = {body = body, shape = shape, fixture = fixture},
                    shadow = {shadowObject = PolygonShadow:new(shadowBody, -20, -20, 20, -20, 20, 20, -20, 20), shadowBody = shadowBody},
                    image = {},
                    followsPlayer = {speed = 100}
                })
            else
                world:addEntity({
                    inBrickRun = {},
                    position = {x=math.random(0,mapWidth), y= math.random(0,mapHeight)},
                    image = {},
                    followsPlayer = {},
                    light = {lightObject = Light:new(newLightWorld, 400),lightColor = {r=math.random(0,255),b=math.random(0,255),g=math.random(0,255)}}
                })           
            end

        end

    end

end

function brickRun.draw()

love.graphics.push()

  love.graphics.translate(love.graphics.getWidth()/2-player.physics.body:getX(),love.graphics.getHeight()/2-player.physics.body:getY())
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, mapWidth,mapHeight)
  newLightWorld:Draw()
  world:draw()

  love.graphics.pop()

  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.setFont(digitalFont)
  love.graphics.print(player.stats.health,0,-30,0,2,2)

end

function convertVector(vector)

    if vector.y == 0 then vector.y = 0.00001 end

    mag = math.sqrt(vector.x^2 + vector.y^2)

    if vector.y>0 then
        if vector.x > 0 then
            dir = math.atan(vector.y/vector.x)
        else
            dir = math.atan(-vector.x/vector.y) + (math.pi/2)
        end
    else
        if vector.x < 0 then
            dir = math.atan(-vector.y/-vector.x) + (math.pi)
        else
            dir = math.atan(vector.x/-vector.y) + ((3*math.pi)/2)
        end
    end

    return dir,mag

end

function convertDirection(dir,mag)

    local x = 0
    local y = 0

    if dir < (math.pi/2) then
        x = mag *      math.cos(dir)
        y = mag *      math.sin(dir)
    elseif dir < (math.pi) then 
        x = mag * -1 * math.sin(dir-(math.pi/2))
        y = mag *      math.cos(dir-(math.pi/2))        
    elseif dir < 3*(math.pi)/2 then 
        x = mag * -1 * math.cos(dir-(math.pi))
        y = mag * -1 * math.sin(dir-(math.pi))
    else
        x = mag *      math.sin(dir-(math.pi*3/2))
        y = mag * -1 * math.cos(dir-(math.pi*3/2))
    end

    return {x = x, y = y}

end

function manageCollison(fixture1, fixture2, contact)

    if fixture1:getBody():getUserData() == "playerBody" and fixture2:getBody():getUserData() == "brick" then
        player.stats.health = player.stats.health - 1
    end
end