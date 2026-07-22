local Template = {
    Items = {},
    Options = nil, 
}

local Services = {
	ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage")),
	UserInputService = cloneref(game:GetService("UserInputService")),
	ReplicatedFirst = cloneref(game:GetService("ReplicatedFirst")),
	TweenService = cloneref(game:GetService("TweenService")),
	Players = cloneref(game:GetService("Players")),
	VirtualUser = cloneref(game:GetService("VirtualUser")),
	ProximityPromptService = cloneref(game:GetService("ProximityPromptService")),
	HttpService = cloneref(game:GetService("HttpService")),
    Lighting = cloneref(game:GetService("Lighting")),
    RunService = cloneref(game:GetService("RunService"))
}

local player = Services.Players.LocalPlayer 

local client = {}
local defaults = {}
local connections = {}
local characterAddedConnections = {}
local seedCount = 0 

local function refreshClientData()
	client.Character = player.Character or player.CharacterAdded:Wait()
	client.Humanoid = client.Character:WaitForChild("Humanoid")
	client.HumanoidRootPart = client.Character:WaitForChild("HumanoidRootPart")
    for _, func in characterAddedConnections do 
        func()
    end 
end

player.CharacterAdded:Connect(refreshClientData)
refreshClientData()

function createSeed()
	local seed = "Seed_"..seedCount
	seedCount+=1
	return seed
end

defaults.WalkSpeed = client.Humanoid.WalkSpeed 
defaults.HipHeight = client.Humanoid.HipHeight 
defaults.JumpPower = client.Humanoid.UseJumpPower and client.Humanoid.JumpPower or client.Humanoid.JumpHeight
defaults.ClockTime = Services.Lighting.ClockTime 
defaults.GlobalShadows = Services.Lighting.GlobalShadows
defaults.Brightness = Services.Lighting.Brightness
defaults.FogStart = Services.Lighting.FogStart 
defaults.FogEnd = Services.Lighting.FogEnd 
defaults.Gravity= workspace.Gravity

function Template:Import(item: string, tab)
    if not Template.Items[item] then return end 
    Template.Items[item](tab)
    return true
end

function Template:BuildHomeSection(tab, LRM_TotalExecutions, LRM_SecondsLeft)
    local function secondsToFormattedDate(secondsLeft)
        local t = os.time() + (tonumber(secondsLeft) or 0)
        local hour = tonumber(os.date("%I", t))
        local minute = tonumber(os.date("%M", t))
        local ampm = os.date("%p", t)
        local dateStr = os.date("%B %d, %Y", t):gsub("(%d)", "%1") 
        return string.format("%s %d:%02d %s", dateStr, hour, minute, ampm)
    end

    tab:AddSection("▶ Information")
    local sessionTime = tab:AddParagraph("sessionTime", {Title = "Session Time", Content = "0"})

    tab:AddSection("▶ Key Data")
    tab:AddParagraph("", {Title = "Total Executions", Content =  (LRM_TotalExecutions or 0) .. " Executions"})
    tab:AddParagraph("", {Title = "Key Expiration Date", Content = secondsToFormattedDate(LRM_SecondsLeft or 0)})

    tab:AddSection("▶ Discord")
    tab:AddButton({Title = "Copy Discord Invite", Description = "Copies the Discord invite link to your clipboard.", Callback = function() setclipboard("https://discord.gg/7MJrswRyJX") end})
    
    task.spawn(function()
        local startTime = tick()

        while true do
            local elapsed = tick() - startTime
            sessionTime:SetValue(string.format("%02d:%02d:%02d", 
                math.floor(elapsed / 3600),  
                math.floor((elapsed % 3600) / 60), 
                math.floor(elapsed % 60)
            ))
            task.wait(1)
        end
    end)
end

Template.Items["No Fog"] = function(tab)
    tab:AddToggle(createSeed(), {Title = "No Fog", Default = false, Callback = function(state)
        Services.Lighting.FogStart = state and 999999 or defaults.FogStart 
        Services.Lighting.FogEnd = state and 999999 or defaults.FogEnd 
    end})
end

Template.Items["Fling"] = function(tab)
    local env = {}

    local function FPos(BasePart, Pos, Ang)
        local targetCF = CFrame.new(BasePart.Position) * Pos * Ang
        client.HumanoidRootPart.CFrame = targetCF
        client.Character:SetPrimaryPartCFrame(targetCF)
        client.HumanoidRootPart.Velocity = Vector3.new(9e7, 9e8, 9e7)
        client.HumanoidRootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function SFBasePart(BasePart, THumanoid)
        local start = tick()
        local angle = 0
        env.timeout = env.timeout or 2.5
        repeat
            if client.HumanoidRootPart and THumanoid then
                angle += 100
                for _, offset in ipairs{CFrame.new(0, 1.5, 0),CFrame.new(0, -1.5, 0),CFrame.new(2.25, 1.5, -2.25),CFrame.new(-2.25, -1.5, 2.25)} do
                    FPos(BasePart, offset + THumanoid.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                    task.wait()
                end
            end
        until BasePart.Velocity.Magnitude > 500 or tick() - start > env.timeout
    end

    local function fling(TargetPlayer)
        if not (client.Character and client.Humanoid and client.HumanoidRootPart) then return end
        local TCharacter = TargetPlayer.Character
        if not TCharacter then return end

        local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        local TRootPart = THumanoid and THumanoid.RootPart
        local THead = TCharacter:FindFirstChild("Head")
        local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        local Handle = Accessory and Accessory:FindFirstChild("Handle")
    
        env.OldPos = client.HumanoidRootPart.CFrame

        repeat task.wait()
            workspace.CurrentCamera.CameraSubject = THead or Handle or THumanoid
        until workspace.CurrentCamera.CameraSubject == THead or Handle or THumanoid

        local BV = Instance.new("BodyVelocity")
        BV.Name = ""
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BV.Parent = client.HumanoidRootPart

        client.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        local target = TRootPart or THead or Handle
        if target then SFBasePart(target, THumanoid) end

        BV:Destroy()
        client.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)

        repeat task.wait()
            workspace.CurrentCamera.CameraSubject = client.Humanoid
        until workspace.CurrentCamera.CameraSubject == client.Humanoid

        repeat
            local cf = env.OldPos * CFrame.new(0, .5, 0)
            client.HumanoidRootPart.CFrame = cf
            client.Character:SetPrimaryPartCFrame(cf)
            client.Humanoid:ChangeState("GettingUp")
            for _, part in ipairs(client.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity, part.RotVelocity = Vector3.zero, Vector3.zero
                end
            end
            task.wait()
        until (client.HumanoidRootPart.Position - env.OldPos.p).Magnitude < 25
    end

    local flingPlayerDropdown = tab:CreateDropdown("flingPlayerDropdown", {
        Title = "Player to Fling",
        Description = "",
        Values = Services.Players:GetPlayers(),
        Multi = false,
        Default = nil,
    })

    tab:AddButton({Title = "Fling Player", Description = "", Callback = function()
        pcall(fling, Template.Options.flingPlayerDropdown.Value)
    end})

    Services.Players.PlayerAdded:Connect(function(plr)
        flingPlayerDropdown:SetValues(Services.Players:GetPlayers())
    end)

    Services.Players.PlayerRemoving:Connect(function()
        flingPlayerDropdown:SetValues(Services.Players:GetPlayers())
    end)
end

Template["Instant Interact"] = function(tab)
    tab:AddToggle(createSeed(), {Title = "Instant Interact", Default = false, Callback = function(state)
        if connections["Instant Interact"] then connections["Instant Interact"]:Disconnect() end 
        if not state then return end 
        connections["Instant Interact"] = Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt) 
            prompt.HoldDuration = 0 
        end)
    end})
end

Template.Items["WalkSpeed"] = function(tab)
    local function handleSpeed()
        if connections["WalkSpeed"] then connections["WalkSpeed"]:Disconnect() end
        if not Template.Options.SpeedToggle.Value then return end 
        connections["WalkSpeed"] = client.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            client.Humanoid.WalkSpeed = Template.Options.WalkSpeedSlider.Value
        end)
        client.Humanoid.WalkSpeed = Template.Options.WalkSpeedSlider.Value
    end 
    tab:AddSlider("WalkSpeedSlider", {
        Title = "Walk Speed",
        Description = "",
        Default = defaults.WalkSpeed,
        Min = 0,
        Max = 300,
        Rounding = 1,
        Callback = function(value) 
            if not Template.Options.SpeedToggle.Value then return end 
            client.Humanoid["WalkSpeed"] = value 
        end,
    })
    tab:AddToggle("SpeedToggle", {Title = "Enable Walk Speed", Default = false, Callback = function(state)
        handleSpeed()
        if not state then
            client.Humanoid.WalkSpeed = defaults.WalkSpeed
        end  
    end})
    table.insert(characterAddedConnections, handleSpeed)
end

Template.Items["JumpPower"] = function(tab)
    local useJumpPower = client.Humanoid.UseJumpPower
    local property = client.Humanoid.UseJumpPower and "JumpPower" or "JumpHeight"

    local function handleJump()
        if connections["JumpPower"] then connections["JumpPower"]:Disconnect() end
        if not Template.Options.JumpToggle.Value then return end
        connections["JumpPower"] = client.Humanoid:GetPropertyChangedSignal(property):Connect(function()
            client.Humanoid[property] = Template.Options.JumpPowerSlider.Value
        end)
        client.Humanoid[property] = Template.Options.JumpPowerSlider.Value
    end

    tab:AddSlider("JumpPowerSlider", {
        Title = useJumpPower and "Jump Power" or "Jump Height",
        Description = "",
        Default = defaults.JumpPower,
        Min = 0,
        Max = useJumpPower and 500 or 100,
        Rounding = 1,
        Callback = function(value) 
            if not Template.Options.JumpToggle.Value then return end 
            client.Humanoid[property] = value 
        end,
    })
    tab:AddToggle("JumpToggle", {Title = "Enable Jump", Default = false, Callback = function(state)
        handleJump()
        if not state then
            client.Humanoid[property] = defaults.JumpPower
        end
    end})
    table.insert(characterAddedConnections, handleJump)
end

Template.Items["HipHeight"] = function(tab)
    local function handleHipHeight()
        if connections["HipHeight"] then connections["HipHeight"]:Disconnect() end
        if not Template.Options.HipHeightToggle.Value then return end
        connections["HipHeight"] = client.Humanoid:GetPropertyChangedSignal("HipHeight"):Connect(function()
            client.Humanoid.HipHeight = Template.Options.HipHeightSlider.Value
        end)
        client.Humanoid.HipHeight = Template.Options.HipHeightSlider.Value
    end

    tab:AddSlider("HipHeightSlider", {
        Title = "Hip Height",
        Description = "",
        Default = defaults.HipHeight,
        Min = -10,
        Max = 100,
        Rounding = 1,
        Callback = function(value) 
            if not Template.Options.HipHeightToggle.Value then return end 
            client.Humanoid["HipHeight"] = value 
        end,
    })

    tab:AddToggle("HipHeightToggle", {Title = "Enable Hip Height", Default = false, Callback = function(state)
        handleHipHeight()
        if not state then
            client.Humanoid.HipHeight = defaults.HipHeight
        end
    end})
    table.insert(characterAddedConnections, handleHipHeight)
end

Template.Items["Gravity"] = function(tab)
    local function handleGravity()
        if connections["Gravity"] then connections["Gravity"]:Disconnect(); connections["Gravity"] = nil end
        if not Template.Options.GravityToggle.Value then return end
        connections["Gravity"] = workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
            workspace.Gravity = Template.Options.GravitySlider.Value
        end)
        workspace.Gravity = Template.Options.GravitySlider.Value
    end

    tab:AddSlider("GravitySlider", {
        Title = "Gravity",
        Description = "",
        Default = defaults.Gravity,
        Min = 0,
        Max = 500,
        Rounding = 1,
        Callback = function(value)
            if not Template.Options.GravityToggle.Value then return end 
            workspace.Gravity = value
        end,
    })
    tab:AddToggle("GravityToggle", {Title = "Enable Gravity", Default = false, Callback = function(state)
        handleGravity()
        if not state then
            workspace.Gravity = defaults.Gravity
        end
    end})
end

Template.Items["Noclip"] = function(tab)
    tab:AddToggle(createSeed(), {Title = "Fullbright", Default = false, Callback = function(state)
        for i, v in client.Character:GetDescendants() do
            if v:IsA("BasePart") and v.CanCollide == state then
                v.CanCollide = not state
            end
        end
    end})
end

Template.Items["Fullbright"] = function(tab)
    tab:AddToggle(createSeed(), {Title = "Fullbright", Default = false, Callback = function(state)
        Services.Lighting.FogStart = state and 999999 or defaults.FogStart 
        Services.Lighting.FogEnd = state and 999999 or defaults.FogEnd 
        Services.Lighting.ClockTime = state and 12 or defaults.ClockTime
        Services.Lighting.GlobalShadows = not state
        Services.Lighting.Brightness = state and 3 or defaults.ClockTime 
    end})
end

Template.Items["Infinite Jump"] = function(tab)
    tab:AddToggle(createSeed(), {Title = "Infinite Jump", Default = false, Callback = function(state)
        if connections["Infinite Jump"] then connections["Infinite Jump"]:Disconnect() end 
        if not state then return end 
        connections["Infinite Jump"] = Services.UserInputService.JumpRequest:Connect(function()
            client.Humanoid:ChangeState("Jumping")
        end)
    end})
end

Template.Items["Anti Afk"] = function(tab)
    tab:AddToggle(createSeed(), {Title = "Anti-Afk", Default = false, Callback = function(state)
        if connections["Anti-Afk"] then connections["Anti-Afk"]:Disconnect() end 
        if not state then return end 
        connections["Anti-Afk"] = player.Idled:Connect(function()
			Services.VirtualUser:CaptureController()
			Services.VirtualUser:ClickButton2(Vector2.new())
		end)
    end})
end

Template.Items["No Rendering"] = function(tab)
    Services.RunService:Set3dRenderingEnabled(false)
    tab:AddToggle(createSeed(), {Title = "No Rendering", Default = false, Callback = function(state)
        Services.RunService:Set3dRenderingEnabled(not state)
    end})
end

Template.Items["FPS Cap"] = function(tab)
    tab:AddSlider("FpsSlider", {
        Title = "FPS Cap",
        Description = "",
        Default = 120,
        Min = 1,
        Max = 500,
        Rounding = 1,
        Callback = function(value)
            if not Template.Options.FPSToggle.Value then return end 
            setfpscap(value)
        end,
    })
    tab:AddToggle("FPSToggle", {Title = "Enable FPS Cap", Default = false, Callback = function(state)
        if not state then
            setfpscap(120)
            return
        end
        setfpscap(Template.Options.FpsSlider.Value)
    end})
    
end

Template.Items["Fly"] = function(tab)
    local FLY_SPEED = 60

    local attachment, linearVelocity, alignOrientation
    local diedConn
    local lastJumpRequest = 0

    local controls = require(
        player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
    ):GetControls()

    Services.UserInputService.JumpRequest:Connect(function()
        lastJumpRequest = os.clock()
    end)

    local function stopFly()
        if connections["Fly"] then connections["Fly"]:Disconnect(); connections["Fly"] = nil end
        if diedConn then diedConn:Disconnect(); diedConn = nil end
        if linearVelocity then linearVelocity:Destroy(); linearVelocity = nil end
        if alignOrientation then alignOrientation:Destroy(); alignOrientation = nil end
        if attachment then attachment:Destroy(); attachment = nil end

        local humanoid = client.Humanoid
        if humanoid and humanoid.Parent then
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    local function startFly()
        stopFly()

        local humanoid = client.Humanoid
        local rootPart = client.HumanoidRootPart
        if not (humanoid and rootPart) then return end

        attachment = Instance.new("Attachment")
        attachment.Parent = rootPart

        linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Attachment0 = attachment
        linearVelocity.MaxForce = math.huge
        linearVelocity.VectorVelocity = Vector3.zero
        linearVelocity.Parent = rootPart

        -- keeps the character upright/facing the camera instead of tumbling
        alignOrientation = Instance.new("AlignOrientation")
        alignOrientation.Attachment0 = attachment
        alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignOrientation.MaxTorque = math.huge
        alignOrientation.Responsiveness = 60
        alignOrientation.Parent = rootPart

        humanoid.PlatformStand = true
        diedConn = humanoid.Died:Connect(stopFly)

        connections["Fly"] = Services.RunService.RenderStepped:Connect(function()
            local root = client.HumanoidRootPart
            if not (root and root.Parent) then return end

            local camera = workspace.CurrentCamera
            local move = controls:GetMoveVector()

            local direction = (camera.CFrame.RightVector * move.X)
                + (camera.CFrame.LookVector * -move.Z)

            if os.clock() - lastJumpRequest < 0.1 then 
                direction += Vector3.yAxis
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                or Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                direction -= Vector3.yAxis
            end

            if direction.Magnitude > 0 then direction = direction.Unit end
            linearVelocity.VectorVelocity = direction * FLY_SPEED

            local _, yaw = camera.CFrame:ToOrientation()
            alignOrientation.CFrame = CFrame.fromOrientation(0, yaw, 0)
        end)
    end

    tab:AddToggle(createSeed(), {Title = "Fly", Default = false, Callback = function(state)
        if state then startFly() else stopFly() end
    end})
end

return Template
