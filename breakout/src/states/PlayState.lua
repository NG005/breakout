--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    a = math.random(4,10)
    
    -- check if should appear both key and ball powerups or only ball powerup 
    if keyBrickLevel == true and unbrekable == true then
        self.powerup = PowerUp(math.random(1, 2))
        self.powerup.invisible = false
        self.powerup.dy = math.random(40, 60)
        self.powerup.dx = math.random(50, 60)
    end
    if keyBrickLevel == false then
        self.powerup = PowerUp(1)
        self.powerup.invisible = false
        self.powerup.dy = math.random(40, 60)
        self.powerup.dx = math.random(50, 60)
    end
    
    if recoverPoints == nil then
        recoverPoints = 5000
    end 
    self.recoverPoints = params.recoverPoints

    -- create a table which will contain the balls
    self.balls = {self.ball}

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
    timer = 0
end

function PlayState:update(dt)
    if  self.powerup.dy == 0 and self.powerup.dx == 0 then
        timer = timer + dt
    end
    if timer > a then
        self.powerup.invisible = false
        self.powerup.dy = math.random(40, 60)
        self.powerup.dx = math.random(50, 60)
        self.powerup:render()
        a = math.random(4,10)
        timer = 0
    end

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end
    if love.keyboard.wasPressed('s') then
        gSounds['powerup']:play()
        for j = 0, 1 do
            newBall = Ball()
            newBall.skin = math.random(7)
            newBall.dx = math.random(-200, 200)
            newBall.dy = math.random(-50, -60)
            newBall.x = self.paddle.x + (self.paddle.width / 2) - 4
            newBall.y = self.paddle.y - 8
            table.insert(self.balls, newBall)
            ----------------ATENTION
            ---------------gSounds['pause']:play()
            for i in pairs(self.balls) do
                self.balls[i]:render()
            end
        end
        return
    end
    -- update positions based on velocity
    self.paddle:update(dt)
    self.powerup:update(dt)
    -- update every ball on the table
    for i in ipairs(self.balls) do
        self.balls[i]:update(dt)
    end

    for i in ipairs(self.balls) do 
        if self.balls[i]:collides(self.paddle) then
             -- raise ball above paddle in case it goes below it, then reverse dy
            self.balls[i].y = self.paddle.y - 8
            self.balls[i].dy = -self.balls[i].dy
        
            -- tweak angle of bounce based on where it hits the paddle

            -- if we hit the paddle on its left side while moving left...
            if self.balls[i].x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.balls[i].dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.balls[i].x))
                -- else if we hit the paddle on its right side while moving right...
            elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
            end
    
            gSounds['paddle-hit']:play()
        end
    end

    -- if the powerup collides with the paddle, it should activate
    if self.powerup:collides(self.paddle) then
        gSounds['powerup']:play()
        -- if the skin is one, the ball powerup will be used
        if self.powerup.skin == 1 then
            -- adding 2 new balls to the table
            for j = 0, 1 do
                newBall = Ball()
                newBall.skin = math.random(7)
                newBall.dx = math.random(-200, 200)
                newBall.dy = math.random(-50, -60)
                newBall.x = self.paddle.x + (self.paddle.width / 2) - 4
                newBall.y = self.paddle.y - 8
                table.insert(self.balls, newBall)
                for i in pairs(self.balls) do
                    self.balls[i]:render()
                end
            end
            -- check if both powerups should appear, or if only the ball 
            -- powerup should, depending on the state of the key brick
            if keyBrickLevel == true and unbrekable == true then
                self.powerup = PowerUp(math.random(1,2))
            else 
                self.powerup = PowerUp(1)
            end
        elseif self.powerup.skin == 2 then
            unbrekable = false
            self.powerup = PowerUp(1)
        end
    end   
    
    if self.powerup.y >= VIRTUAL_HEIGHT then
        if keyBrickLevel == true and unbrekable == true then
            self.powerup = PowerUp(math.random(1,2))
        else
            self.powerup = PowerUp(1)
        end
    end


    
    -- detect collision across all bricks with the balls
    for i in ipairs(self.balls) do 
        for k, brick in pairs(self.bricks) do
            -- only check collision if we're in play

            if brick.inPlay and self.balls[i]:collides(brick) then

                -- add to score
                if brick.color == 6 and unbrekable == false then 
                    self.score = self.score + self.recoverPoints
                end
                if brick.color < 6 then
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                end

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)
                    -- also, increase the paddle size
                    if self.paddle.size < 4 then
                        self.paddle.size = self.paddle.size + 1
                        self.paddle:render()
                    end

                    -- multiply recover points by 2
                    z = self.recoverPoints * 2
                    if z > 100000 then
                        self.recoverPoints = self.recoverPoints + 100000
                    else 
                        self.recoverPoints = z
                    end
    
                    -- play recover sound effect
                    gSounds['recover']:play()
                end
            

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --
    
                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if self.balls[i].x + 2 < brick.x and self.balls[i].dx > 0 then
                
                    -- flip x velocity and reset position outside of brick
                    self.balls[i].dx = -self.balls[i].dx
                    self.balls[i].x = brick.x - 8
            
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                elseif self.balls[i].x + 6 > brick.x + brick.width and self.balls[i].dx < 0 then
                
                    -- flip x velocity and reset position outside of brick
                    self.balls[i].dx = -self.balls[i].dx
                    self.balls[i].x = brick.x + 32
            
                    -- top edge if no X collisions, always check
                elseif self.balls[i].y < brick.y then
                
                    -- flip y velocity and reset position outside of brick
                    self.balls[i].dy = -self.balls[i].dy
                    self.balls[i].y = brick.y - 8
            
                    -- bottom edge if no X collisions or top collision, last possibility
                else
                
                    -- flip y velocity and reset position outside of brick
                    self.balls[i].dy = -self.balls[i].dy
                    self.balls[i].y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.balls[i].dy) < 150 then
                    self.balls[i].dy = self.balls[i].dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- if all balls go below bounds, revert to serve state and decrease health
    for i in ipairs(self.balls) do 
        if self.balls[i].y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, i)
            if self.balls[1] == nil then
                self.health = self.health - 1
                if self.paddle.size > 1 then
                    self.paddle.size = self.paddle.size - 1
                    self.paddle:render()
                end
                gSounds['hurt']:play()

                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for i in pairs(self.balls) do
        self.balls[i]:render()
    end
    if self.powerup.invisible == false then
        self.powerup:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end
    -- reduce by 1 the wait for the next key brick 
    if levelsForKeyBrick > 0 then
        levelsForKeyBrick = levelsForKeyBrick - 1
    else 
        levelsForKeyBrick = math.random(4, 6)
    end
    return true
end