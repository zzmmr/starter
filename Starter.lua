local Template = {
    Items = {},
    Options = nil, 
}

local Services = {
	UserInputService = cloneref(game:GetService("UserInputService")),
	Players = cloneref(game:GetService("Players")),
	VirtualUser = cloneref(game:GetService("VirtualUser")),
	ProximityPromptService = cloneref(game:GetService("ProximityPromptService")),
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

defaults.RootSize = client.HumanoidRootPart.Size
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
        local succ, result = pcall(function()
            local t = os.time() + (tonumber(secondsLeft) or 0)
            local hour = tonumber(os.date("%I", t))
            local minute = tonumber(os.date("%M", t))
            local ampm = os.date("%p", t)
            local dateStr = os.date("%B %d, %Y", t):gsub("(%d)", "%1") 
            return string.format("%s %d:%02d %s", dateStr, hour, minute, ampm)
        end)
        return succ and result or "Couldn't format date."
    end

    tab:AddSection("▶ Information")
    local sessionTime = tab:AddParagraph("sessionTime", {Title = "Session Time", Content = "0"})

    tab:AddSection("▶ Key Data")
    tab:AddParagraph("", {Title = "Total Executions", Content =  (LRM_TotalExecutions or 0) .. " Executions"})
    tab:AddParagraph("", {Title = "Key Expiration Date", Content = secondsToFormattedDate(LRM_SecondsLeft)})

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

function Template:BuildNovaHomeSection(Window, tab, LRM_TotalExecutions, LRM_SecondsLeft)
    local function secondsToFormattedDate(secondsLeft)
        local succ, result = pcall(function()
            local t = os.time() + (tonumber(secondsLeft) or 0)
            local hour = tonumber(os.date("%I", t))
            local minute = tonumber(os.date("%M", t))
            local ampm = os.date("%p", t)
            local dateStr = os.date("%B %d, %Y", t):gsub("(%d)", "%1") 
            return string.format("%s %d:%02d %s", dateStr, hour, minute, ampm)
        end)
        return succ and result or "Couldn't format date."
    end

    local InformationSection = tab:AddSection({Title = "Information", Column = 1})
    local SessionTime = InformationSection:AddParagraph({Title = "Session Time", Content = "0s"})
    InformationSection:AddKeybind("MinimizeKeybind", {
        Title = "Minimize Keybind",
        Mode = "Toggle",
        Default = Enum.KeyCode.LeftControl,
        ChangedCallback = function(New)
            Window.MinimizeKey = New 
        end,
    })

    local KeyDataSection = tab:AddSection({Title = "Key Data", Column = 1})
    KeyDataSection:AddParagraph({Title = "Total Executions", Content =  (LRM_TotalExecutions or 0) .. " Executions"})
    KeyDataSection:AddParagraph({Title = "Key Expiration Date", Content = secondsToFormattedDate(LRM_SecondsLeft)})

    local DiscordSection = tab:AddSection({Title = "Discord", Column = 1})
    DiscordSection:AddButton({Title = "Copy Discord Invite", Description = "Copies the Discord invite link to your clipboard.", Callback = function() setclipboard("https://discord.gg/7MJrswRyJX") end})
    
    task.spawn(function()
        local startTime = tick()

        while true do
            local elapsed = tick() - startTime
            SessionTime:SetContent(string.format("%02d:%02d:%02d", 
                math.floor(elapsed / 3600),  
                math.floor((elapsed % 3600) / 60), 
                math.floor(elapsed % 60)
            ))
            task.wait(1)
        end
    end)
end

Template.Items["Hitbox Expander"] = function(tab)
    local DEFAULT_SIZE = typeof(defaults) == "table" and defaults.RootSize or Vector3.new(2, 2, 1)

    local function updateCharacterHitbox(character)
        if not character then return end

        local primaryPart = character.PrimaryPart or character:WaitForChild("HumanoidRootPart", 3)
        if not primaryPart then return end

        local isEnabled = Template.Options.enableHitboxExpander and Template.Options.enableHitboxExpander.Value or false
        local isVisible = Template.Options.showHitboxes and Template.Options.showHitboxes.Value or false
        local sizeValue = Template.Options.hitboxSize and Template.Options.hitboxSize.Value or 3

        local targetSize = isEnabled and Vector3.new(sizeValue, sizeValue, sizeValue) or DEFAULT_SIZE

        primaryPart.Size = targetSize
        primaryPart.Transparency = (isEnabled and isVisible) and 0.7 or 1
        
        primaryPart.CanCollide = false 
    end

    local function updateAllHitboxes()
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player == Services.Players.LocalPlayer then continue end 
            updateCharacterHitbox(player.Character)
        end
    end

    tab:CreateSlider("hitboxSize", {
        Title = "Hitbox Size",
        Description = "Adjusts the size of enemy hitboxes.",
        Default = 3,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Callback = updateAllHitboxes
    })

    tab:AddToggle("showHitboxes", {
        Title = "Show Hitboxes", 
        Default = false, 
        Callback = updateAllHitboxes
    })

    tab:AddToggle("enableHitboxExpander", {
        Title = "Enable Hitbox Expander", 
        Default = false, 
        Callback = updateAllHitboxes
    })

    local function setupPlayer(player)
        if player == Services.Players.LocalPlayer then return end
        
        player.CharacterAdded:Connect(function(char)
            task.defer(function()
                updateCharacterHitbox(char)
            end)
        end)
    end

    for _, player in ipairs(Services.Players:GetPlayers()) do
        setupPlayer(player)
    end

    Services.Players.PlayerAdded:Connect(setupPlayer)
end

Template.Items["No Fog"] = function(tab)
    tab:AddToggle("noFog", {Title = "No Fog", Default = false, Callback = function(state)
        Services.Lighting.FogStart = defaults.FogStart 
        Services.Lighting.FogEnd = defaults.FogEnd 
        if not state then return end 
        while Template.Options.noFog.Value do 
            Services.Lighting.FogStart = 999999
            Services.Lighting.FogEnd = 999999
            task.wait()
        end 
    end})
end

Template.Items["Fling"] = function(tab)
    local function fling(player)
        local t = tick()
        local char = player.Character
        local hrp = char and char.PrimaryPart
        local oldPos = client.HumanoidRootPart.CFrame
        if not char or not hrp then return end 

        while hrp.Velocity.Magnitude < 500 and tick()-t<3 do
            client.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(Vector3.new(0,0,-0.5))
            RunService.Heartbeat:Wait()
            local vel = client.HumanoidRootPart.Velocity
            client.HumanoidRootPart.Velocity = vel * 99999999 + Vector3.new(0, 99999999, 0)
            RunService.RenderStepped:Wait()
            client.HumanoidRootPart.Velocity = vel
            RunService.Stepped:Wait()
            client.HumanoidRootPart.Velocity = vel + Vector3.new(0, 0.1, 0)
            task.wait()
        end 
        task.wait(.3)
        while (client.HumanoidRootPart.Position-oldPos.Position).Magnitude>2 do 
            client.HumanoidRootPart.CFrame = oldPos
            client.Humanoid:ChangeState("GettingUp")
            for _, part in client.Character:GetChildren() do 
                if part:IsA("BasePart") then 
                    part.Velocity, part.RotVelocity = Vector3.zero, Vector3.zero
                end 
            end 
            task.wait()
        end 
        return true 
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

Template.Items["Instant Interact"] = function(tab)
    tab:AddToggle(createSeed(), {Title = "Instant Interact", Default = false, Callback = function(state)
        if connections["Instant Interact"] then connections["Instant Interact"]:Disconnect() end 
        if not state then return end 
        connections["Instant Interact"] = Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt) 
            prompt.HoldDuration = 0 
        end)
    end})
end

Template.Items["WalkSpeed"] = function(tab)
    local firstRun = true 
    local function handleSpeed()
        if connections["WalkSpeed"] then connections["WalkSpeed"]:Disconnect() end
        if not Template.Options.SpeedToggle or not Template.Options.SpeedToggle.Value then return end 
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
            if not Template.Options.SpeedToggle or not Template.Options.SpeedToggle.Value then return end 
            client.Humanoid["WalkSpeed"] = value 
        end,
    })
    tab:AddToggle("SpeedToggle", {Title = "Enable Walk Speed", Default = false, Callback = function(state)
        if firstRun then 
            firstRun = false 
            return 
        end 
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
    local firstRun = true 

    local function handleJump()
        if connections["JumpPower"] then connections["JumpPower"]:Disconnect() end
        if not Template.Options.JumpToggle or not Template.Options.JumpToggle.Value then return end
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
            if not Template.Options.JumpToggle or not Template.Options.JumpToggle.Value then return end 
            client.Humanoid[property] = value 
        end,
    })
    tab:AddToggle("JumpToggle", {Title = "Enable Jump", Default = false, Callback = function(state)
        if firstRun then 
            firstRun = false 
            return 
        end 
        handleJump()
        if not state then
            client.Humanoid[property] = defaults.JumpPower
        end
    end})
    table.insert(characterAddedConnections, handleJump)
end

Template.Items["HipHeight"] = function(tab)
    local firstRun = true 

    local function handleHipHeight()
        if connections["HipHeight"] then connections["HipHeight"]:Disconnect() end
        if not Template.Options.HipHeightToggle or not Template.Options.HipHeightToggle.Value then return end
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
            if not Template.Options.HipHeightToggle or not Template.Options.HipHeightToggle.Value then return end 
            client.Humanoid["HipHeight"] = value 
        end,
    })

    tab:AddToggle("HipHeightToggle", {Title = "Enable Hip Height", Default = false, Callback = function(state)
        if firstRun then 
            firstRun = false 
            return 
        end 
        handleHipHeight()
        if not state then
            client.Humanoid.HipHeight = defaults.HipHeight
        end
    end})
    table.insert(characterAddedConnections, handleHipHeight)
end

Template.Items["Gravity"] = function(tab)
    local firstRun = true 
    local function handleGravity()
        if connections["Gravity"] then connections["Gravity"]:Disconnect(); connections["Gravity"] = nil end
        if not Template.Options.GravityToggle or not Template.Options.GravityToggle.Value then return end
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
            if not Template.Options.GravityToggle or not Template.Options.GravityToggle.Value then return end 
            workspace.Gravity = value
        end,
    })
    tab:AddToggle("GravityToggle", {Title = "Enable Gravity", Default = false, Callback = function(state)
        if firstRun then 
            firstRun = false 
            return 
        end 
        handleGravity()
        if not state then
            workspace.Gravity = defaults.Gravity
        end
    end})
end

Template.Items["Noclip"] = function(tab)
    local firstRun = true 
    tab:AddToggle("Noclip", {Title = "Noclip", Default = false, Callback = function(state)
        if firstRun then 
            firstRun = false 
            return 
        end 
        while Template.Options.Noclip.Value do 
            for i, v in client.Character:GetDescendants() do
                if v:IsA("BasePart") and v.CanCollide == state then
                    v.CanCollide = false
                end
            end
            task.wait()
        end
        for i, v in client.Character:GetDescendants() do
            if v:IsA("BasePart") and v.CanCollide == state then
                v.CanCollide = true
            end
        end
    end})
end

Template.Items["Fullbright"] = function(tab)
    local firstRun = true 
    tab:AddToggle("Fullbright", {Title = "Fullbright", Default = false, Callback = function(state)
        if firstRun then 
            firstRun = false 
            return 
        end 
        Services.Lighting.FogStart = defaults.FogStart 
        Services.Lighting.FogEnd = defaults.FogEnd 
        Services.Lighting.ClockTime = defaults.ClockTime
        Services.Lighting.GlobalShadows = defaults.GlobalShadows
        Services.Lighting.Brightness = defaults.ClockTime 
        if not state then return end 
        while Template.Options.Fullbright.Value do 
            Services.Lighting.FogStart = 999999
            Services.Lighting.FogEnd = 999999
            Services.Lighting.ClockTime = 12
            Services.Lighting.GlobalShadows = false
            Services.Lighting.Brightness = 3
            task.wait()
        end
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
            if not Template.Options.FPSToggle or not Template.Options.FPSToggle.Value then return end 
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
