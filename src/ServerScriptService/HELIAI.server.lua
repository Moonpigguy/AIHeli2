-- make heli functional and add AI

local heli = game:GetService("Workspace")["Hunter Chopper"]
local engine = heli.Required.Engine
local heliForce = Instance.new("BodyForce")
heliForce.Parent = heli.Required.Engine
local heliTorque = Instance.new("BodyGyro")
heliTorque.Parent = heli.Required.Engine
heliTorque.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
heliTorque.P = 1000
local gravity = workspace.Gravity

local FIRING = false

local mainThrottle = 1
local throttleStrength = 100
local dragCoefficient = 800
local tiltMultiplier = 3
local maxPitch = -40 -- degrees
local maxRoll = -10 -- degrees
local velocityLimit = 200 -- m/s
local velocityDistance = 80
local maxDistance = 600
local slowDownHeight = 20
local hoverDistance = 70

local DEBUG = false								-- Whether or not to use debugging features of FastCast, such as cast visualization.
local BULLET_SPEED = 800							-- Studs/second - the speed of the bullet
local BULLET_MAXDIST = 1000							-- The furthest distance the bullet can travel 
local BULLET_GRAVITY = Vector3.new(0, 0, 0)		-- The amount of gravity applied to the bullet in world space (so yes, you can have sideways gravity)
local MIN_BULLET_SPREAD_ANGLE = 0					-- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The least accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. Generally you want to keep this at 0 so there's at least some chance of a 100% accurate shot.
local MAX_BULLET_SPREAD_ANGLE = 1					-- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The most accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. This cannot be less than the value above. A value of 90 will allow the gun to shoot sideways at most, and a value of 180 will allow the gun to shoot backwards at most. Exceeding 180 will not add any more angular varience.
local BULLETS_PER_SHOT = 3							-- The amount of bullets to fire every shot. Make this greater than 1 for a shotgun effect.

local lastMagnitude = 0
local mass = 49832

local FastCast = require(game:GetService("ReplicatedStorage").FastCastRedux)
local Debris = game:GetService("Debris")
local table = require(game:GetService("ReplicatedStorage").FastCastRedux.Table)
local PartCacheModule = require(game:GetService("ReplicatedStorage").PartCache)

local RNG = Random.new()							-- Set up a randomizer.
local TAU = math.pi * 2							-- Set up mathematical constant Tau (pi * 2)
FastCast.DebugLogging = DEBUG
FastCast.VisualizeCasts = DEBUG

local CosmeticBulletsFolder = workspace:FindFirstChild("CosmeticBulletsFolder") or Instance.new("Folder", workspace)
CosmeticBulletsFolder.Name = "CosmeticBulletsFolder"

local Caster = FastCast.new() --Create a new caster object.


local CastParams = RaycastParams.new()
CastParams.IgnoreWater = true
CastParams.FilterType = Enum.RaycastFilterType.Blacklist
CastParams.FilterDescendantsInstances = {heli, workspace.IgnoreList, workspace.TARGET}


local CastBehavior = FastCast.newBehavior()
CastBehavior.RaycastParams = CastParams
CastBehavior.MaxDistance = BULLET_MAXDIST
CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default

--CastBehavior.CosmeticBulletProvider = CosmeticPartProvider

CastBehavior.CosmeticBulletContainer = CosmeticBulletsFolder
CastBehavior.Acceleration = BULLET_GRAVITY
CastBehavior.AutoIgnoreContainer = false

local function doPhysics()
    local mainVelocity = engine.Velocity
    local weight = mass * gravity
    local engineCFrame = engine.CFrame
    if mainVelocity.Z == 0 then
		mainVelocity = Vector3.new(mainVelocity.X,mainVelocity.Y,0.0001)
	end
	if mainVelocity.Y == 0 then
		mainVelocity = Vector3.new(mainVelocity.X,0.0001,mainVelocity.Z)
	end
	if mainVelocity.X == 0 then
        mainVelocity = Vector3.new(0.0001,mainVelocity.Y,mainVelocity.Z)
	end
	local relativeGravity = engineCFrame:VectorToWorldSpace(Vector3.new(0, weight, 0))
	local gravityToWorld = relativeGravity:Dot(Vector3.new(0, 1, 0)) * Vector3.new(0, 1, 0)
	local totalForcePower = engineCFrame:VectorToWorldSpace(Vector3.new(0, mainThrottle * throttleStrength, 0))
	heliForce.Force = totalForcePower + (gravityToWorld + (relativeGravity - gravityToWorld) * tiltMultiplier) + -mainVelocity.Unit * mainVelocity.Magnitude * mainVelocity.Magnitude * 0.5 * dragCoefficient
    
end


local function flyToCFrame(cframe)
    -- use dot and cross to yaw towards cframe
    local engineCFrame = engine.CFrame
    local engineVector = engineCFrame.LookVector
    local targetVector = (cframe.Position - engineCFrame.Position)
    
    -- set desiredPitch to the angle needed to face the target
    
    local desiredPitch = -25



    



    -- make desiredPitch less the closer the helicopter is to the target
    local distance = (cframe.Position - engineCFrame.Position).Magnitude
    local velocity = engine.Velocity
    local velocityMagnitude = velocity.Magnitude
    if distance < maxDistance then
        desiredPitch = desiredPitch * (distance / maxDistance)
    end
    if velocityMagnitude > velocityLimit then
        desiredPitch = desiredPitch * (velocityLimit / velocityMagnitude)
    end

    

    -- roll towards the target
    local desiredRoll = 0
    local cross = engineVector:Cross(targetVector)
    if cross.Y > 0 then
        desiredRoll = -maxRoll
    elseif cross.Y < 0 then
        desiredRoll = maxRoll
    end
    -- roll less the closer the helicopter is to the target
    if distance < maxDistance then
        desiredRoll = desiredRoll * (distance / maxDistance)
    end
    -- roll less the faster the helicopter is going
    if velocityMagnitude > velocityLimit then
        desiredRoll = desiredRoll * (velocityLimit / velocityMagnitude)
    end
    -- set the BodyGyro
    
    if distance < hoverDistance then -- hover at cframe
        heliTorque.CFrame = CFrame.new(engineCFrame.Position, engineCFrame.Position + Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z)) * CFrame.Angles(0, 0, math.rad(desiredRoll))
    else
        heliTorque.CFrame = CFrame.new(engineCFrame.Position, Vector3.new(cframe.Position.X, engineCFrame.Position.Y, cframe.Position.Z)) * CFrame.Angles(math.rad(desiredPitch), 0, math.rad(desiredRoll))
    end

    -- get distance between current position and cframe
    local distance = (engine.Position - cframe.p).magnitude
    -- get horizontal distance between current position and cframe
    local horizontalDistance = (Vector3.new(engine.Position.X, 0, engine.Position.Z) - Vector3.new(cframe.p.X, 0, cframe.p.Z)).magnitude
    if horizontalDistance ~= horizontalDistance then
        horizontalDistance = 1
    end
    -- if helicopter is below cframe, fly up
    throttleStrength = -66000000 * math.atan2((engine.Position.Y - cframe.p.Y), 2000) --/ slowDownHeight --* (engine.Position.Y + cframe.p.Y)
    if throttleStrength ~= throttleStrength then
        throttleStrength = heliForce.Force.Y - mass * gravity
    end
    -- calculate throttleStrength needed to hover at cframe
    -- if heli is close enough to target and velocity is below velocityLimit, lerp velocity to 0 and cframe to cframe
    if distance < hoverDistance and velocityMagnitude < velocityDistance then
        if distance > 5 then
            engine.CFrame = engine.CFrame:Lerp(cframe, 0.01)
        end
    end
end

local function spinRotor()
    local rotor = engine.Parent.VentsMain.Rotor
    local rotorSpeed = 0.5
    local Y,X,Z = rotor.C1:ToEulerAnglesYXZ()
    rotor.C1 = CFrame.Angles(Y, X + rotorSpeed, Z)
    engine.Spin.PlaybackSpeed = math.clamp(math.abs(throttleStrength / 6600000) + 1, 0.5, 2)
end

local function createServerCast(origin, direction)
    local modifiedBulletSpeed = (direction * BULLET_SPEED)
    Caster:Fire(origin, direction, modifiedBulletSpeed, CastBehavior)
end

local function FireAtPart(part)
    engine.Parent.GunPart.ChargeUp:Play()
    task.wait(engine.Parent.GunPart.ChargeUp.TimeLength)
    engine.Parent.GunPart.FireLoop:Play()
    for _ = 1,400 do
        -- predict where to aim at based on the target's velocity and bullet velocity (BULLET_SPEED)
        local targetVelocity = part.Velocity
        local targetPosition = part.Position
        local targetDistance = (targetPosition - engine.Position).Magnitude
        local timeToTarget = targetDistance / BULLET_SPEED
        local predictedPosition = targetPosition + targetVelocity * timeToTarget * 1.5
        local direction = (predictedPosition - engine.Position).Unit
        local directionalCF = CFrame.new(Vector3.new(), direction)
        local direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(math.rad(RNG:NextNumber(MIN_BULLET_SPREAD_ANGLE, MAX_BULLET_SPREAD_ANGLE)), 0, 0)).LookVector
        
        for _ = 1, BULLETS_PER_SHOT do
            game:GetService("ReplicatedStorage").ReplicateBullet:FireAllClients(engine.Parent.GunPart, direction)
            createServerCast(engine.Parent.GunPart.Position, direction / 1.5)
        end

        task.wait()
    end
    engine.Parent.GunPart.FireLoop:Stop()
    task.wait(math.random(5,10))
    FIRING = false
end

local function getClosestCharacter(maxDistance)
    local closestCharacter = nil
    local closestDistance = maxDistance
    for _,v in pairs(game.Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (v.Character.HumanoidRootPart.Position - engine.Position).Magnitude
            if distance < closestDistance then
                closestCharacter = v.Character
                closestDistance = distance
            end
        end
    end
    return closestCharacter
end

game:GetService("RunService").Heartbeat:Connect(function()
    flyToCFrame(workspace.TARGET.CFrame)
    doPhysics()
    spinRotor()
    local closestCharacter = getClosestCharacter(400)
    local closestCharacter2 = getClosestCharacter(math.huge)
    if closestCharacter2 then
        workspace.TARGET.CFrame = CFrame.new(closestCharacter2.HumanoidRootPart.Position + Vector3.new(-200, 200, 0), Vector3.new(closestCharacter2.HumanoidRootPart.Position.X, workspace.TARGET.Position.Y, closestCharacter2.HumanoidRootPart.Position.Z))
    end
    if closestCharacter and (closestCharacter.HumanoidRootPart.Position - engine.Position).Magnitude < 400 and not FIRING then
        FIRING = true
        FireAtPart(closestCharacter.HumanoidRootPart)
    end
end)

game:GetService("ReplicatedStorage").UpdateCFrame.OnServerEvent:Connect(function(player, cframe)
    workspace.TARGET.CFrame = cframe
end)

game:GetService("ReplicatedStorage").ReplicateBullet.OnServerEvent:Connect(function(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.Humanoid:TakeDamage(10)
    end
end)