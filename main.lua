require "brickRun"

Secs = require('secs')

Shadows = require("shadows")
LightWorld = require("shadows.LightWorld")
Light = require("shadows.Light")
Body = require("shadows.Body")
PolygonShadow = require("shadows.ShadowShapes.PolygonShadow")
CircleShadow = require("shadows.ShadowShapes.CircleShadow")


function love.load()

    currentGame = "brickRun"

    world = Secs.new()

    world:addComponent("inBrickRun")

    brickRun.load()

end

function love.update(dt)
   
    if currentGame == "brickRun" then brickRun.update(dt) end

end

function love.draw()

   if currentGame == "brickRun" then  brickRun.draw() end

end

function closeBrickRun()
    currentGame = "menu"
    for entity in pairs(world:query("inBrickRun")) do
        world:delete(entity)
    end
end
