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


local player = game.Players:WaitForChild("MoonKairiki")
repeat wait() until player.Character
local playerTorso = player.Character.HumanoidRootPart

local mainThrottle = 1
local throttleStrength = 100
local dragCoefficient = 800
local tiltMultiplier = 3
local maxPitch = -40 -- degrees
local maxRoll = -10 -- degrees
local velocityLimit = 1000 -- m/s
local maxDistance = 400
local slowDownHeight = 20

local lastMagnitude = 0
local mass = 49832

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
    

    heliTorque.CFrame = CFrame.new(engineCFrame.Position, Vector3.new(cframe.Position.X, engineCFrame.Position.Y, cframe.Position.Z)) * CFrame.Angles(math.rad(desiredPitch), 0, math.rad(desiredRoll))
    --heliTorque.CFrame = CFrame.new(engineCFrame.Position, Vector3.new(cframe.Position.X, engineCFrame.Position.Y, cframe.Position.Z)) * CFrame.Angles(math.rad(desiredPitch), 0, 0)



    --heliTorque.CFrame = CFrame.Angles(math.rad(desiredPitch), 0, 0)


    --heliTorque.AngularVelocity = Vector3.new(pitch, yaw, roll)




    
    --pitch = math.clamp(pitch, -math.rad(maxPitch), math.rad(maxPitch))

    -- set pitch based on angular velocity

    -- set yaw, pitch, roll
    --heliTorque.AngularVelocity = Vector3.new(pitch, yaw, roll)



    









    


    




    -- apply yaw, pitch, and roll
    --heliTorque.AngularVelocity = Vector3.new(rollPitch.X * maxPitch, yaw, rollPitch.Z * maxRoll)
    
    lastMagnitude = (cframe.Position - engine.Position).Magnitude


    --heliTorque.AngularVelocity = Vector3.new(rollPitch.X, yaw, rollPitch.Z)
    
    -- set torque
    --heliTorque.AngularVelocity = Vector3.new(0, yaw, -0)
    --heliTorque.AngularVelocity = Vector3.new(0, yaw, 0) * 0.5
    --heliTorque.AngularVelocity = Vector3.new(0, yaw, 0)

    -- get distance between current position and cframe
    local distance = (engine.Position - cframe.p).magnitude
    -- get horizontal distance between current position and cframe
    local horizontalDistance = (Vector3.new(engine.Position.X, 0, engine.Position.Z) - Vector3.new(cframe.p.X, 0, cframe.p.Z)).magnitude
    if horizontalDistance ~= horizontalDistance then
        horizontalDistance = 1
    end
    -- if helicopter is below cframe, fly up
    throttleStrength = -66000000 * math.atan2((engine.Position.Y - cframe.p.Y), 10000) / slowDownHeight * (engine.Position.Y + cframe.p.Y)
    if throttleStrength ~= throttleStrength then
        throttleStrength = heliForce.Force.Y - mass * gravity
    end
    -- calculate throttleStrength needed to hover at cframe

    if distance < 10000 then
        
    end
    
end


local function spinRotor()
    local rotor = engine.Parent.VentsMain.Rotor -- this is a motor6d
    local rotorSpeed = 0.5
    local Y,X,Z = rotor.C1:ToEulerAnglesYXZ()
    rotor.C1 = CFrame.Angles(Y, X + rotorSpeed, Z)
end

game:GetService("RunService").Heartbeat:Connect(function()
    flyToCFrame(workspace.TARGET.CFrame)
    doPhysics()
    spinRotor()
end)