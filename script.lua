--[[ 
    ASYLUM ELITE V15.0 (RAYFIELD)
    - UI: Rayfield Library
    - OPTIMIZED: Target Caching & Render Logic
    - FEATURES: Advanced Aim, ESP, and Hitbox Expander
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ASYLUM ELITE V15.0",
   LoadingTitle = "Asylum Hub",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AsylumElite",
      FileName = "Config"
   },
   KeySystem = false
})

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

--// Configuration Table
getgenv().Config = {
    CameraAim = false,
    Method1_Silent = false,
    Method2_Silent = false,
    WallCheck = true,
    TeamCheck = true,
    ShowFOV = true,
    FOVRadius = 150,
    Smoothness = 0.15,
    HitboxEnabled = false,
    HitboxSize = 10,
    ESPEnabled = false,
    NameESP = false,
    TracerEnabled = false,
    ChamsEnabled = false,
    GhostESP = false,
    AimPart = "Head",
    TargetMode = "All",
    ESPColor = Color3.fromRGB(0, 255, 255)
}

--// PERFORMANCE: TARGET CACHE
local TargetCache = {}
local function RefreshTargets()
    local newCache = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v ~= LP.Character then
            table.insert(newCache, v)
        end
    end
    TargetCache = newCache
end
task.spawn(function() while task.wait(1.5) do RefreshTargets() end end)
RefreshTargets()

--// FOV Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = getgenv().Config.ESPColor
FOVCircle.Visible = false

--// UI TABS
local AimTab = Window:CreateTab("Aim Assist", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)
local MiscTab = Window:CreateTab("Miscellaneous", 4483362458)

--// AIM TAB ELEMENTS
AimTab:CreateSection("Targeting")

AimTab:CreateDropdown({
   Name = "Target Mode",
   Options = {"All", "Players", "NPCs"},
   CurrentOption = {"All"},
   MultipleOptions = false,
   Callback = function(Option) getgenv().Config.TargetMode = Option[1] end,
})

AimTab:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "UpperTorso", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Callback = function(Option) getgenv().Config.AimPart = Option[1] end,
})

AimTab:CreateSection("Silent Aim")

AimTab:CreateToggle({
   Name = "Silent Aim (Method 1 - Raycast)",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.Method1_Silent = Value end,
})

AimTab:CreateToggle({
   Name = "Silent Aim (Method 2 - Mouse Hit)",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.Method2_Silent = Value end,
})

AimTab:CreateSection("Camera Aim")

AimTab:CreateToggle({
   Name = "Camera Snap (Right Click)",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.CameraAim = Value end,
})

AimTab:CreateSlider({
   Name = "Aim Smoothness",
   Range = {0.01, 1},
   Increment = 0.01,
   Suffix = "Lerp",
   CurrentValue = 0.15,
   Callback = function(Value) getgenv().Config.Smoothness = Value end,
})

AimTab:CreateSection("Checks & FOV")

AimTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = true,
   Callback = function(Value) getgenv().Config.WallCheck = Value end,
})

AimTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = true,
   Callback = function(Value) getgenv().Config.TeamCheck = Value end,
})

AimTab:CreateSlider({
   Name = "FOV Radius",
   Range = {10, 800},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 150,
   Callback = function(Value) getgenv().Config.FOVRadius = Value end,
})

--// VISUALS TAB ELEMENTS
VisualsTab:CreateSection("ESP Options")

VisualsTab:CreateToggle({
   Name = "Box ESP",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.ESPEnabled = Value end,
})

VisualsTab:CreateToggle({
   Name = "Name & Health ESP",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.NameESP = Value end,
})

VisualsTab:CreateToggle({
   Name = "Tracers",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.TracerEnabled = Value end,
})

VisualsTab:CreateSection("Chams")

VisualsTab:CreateToggle({
   Name = "Enable Chams (Glow)",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.ChamsEnabled = Value end,
})

VisualsTab:CreateToggle({
   Name = "Ghost Mode (Always Visible)",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.GhostESP = Value end,
})

VisualsTab:CreateSection("Settings")

VisualsTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = true,
   Callback = function(Value) getgenv().Config.ShowFOV = Value end,
})

VisualsTab:CreateColorPicker({
    Name = "Visuals Color",
    Color = Color3.fromRGB(0, 255, 255),
    Callback = function(Value) getgenv().Config.ESPColor = Value end
})

--// MISC TAB ELEMENTS
MiscTab:CreateSection("Character Mods")

MiscTab:CreateToggle({
   Name = "Hitbox Expander",
   CurrentValue = false,
   Callback = function(Value) getgenv().Config.HitboxEnabled = Value end,
})

MiscTab:CreateSlider({
   Name = "Hitbox Size",
   Range = {2, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 10,
   Callback = function(Value) getgenv().Config.HitboxSize = Value end,
})

--// CORE ENGINE (ESP / AIM)
local Cache = {}
local function RemoveESP(char)
    if Cache[char] then
        if Cache[char].Box then Cache[char].Box:Remove() end
        if Cache[char].Tracer then Cache[char].Tracer:Remove() end
        if Cache[char].Text then Cache[char].Text:Remove() end
        if Cache[char].Highlight then Cache[char].Highlight:Destroy() end
        Cache[char] = nil
    end
end

local Locked = nil
local IsAiming = false

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Color = getgenv().Config.ESPColor
    
    local pot, dist = nil, getgenv().Config.FOVRadius

    for _, v in pairs(TargetCache) do
        if v.Parent and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local char = v
            local player = Players:GetPlayerFromCharacter(char)
            if getgenv().Config.TeamCheck and player and player.Team == LP.Team then continue end

            if not Cache[char] then
                Cache[char] = {Box = Drawing.new("Square"), Tracer = Drawing.new("Line"), Text = Drawing.new("Text"), Highlight = Instance.new("Highlight", char)}
                Cache[char].Text.Size = 14; Cache[char].Text.Center = true; Cache[char].Text.Outline = true
            end
            
            local esp = Cache[char]
            esp.Highlight.Enabled = (getgenv().Config.ChamsEnabled or getgenv().Config.GhostESP)
            esp.Highlight.DepthMode = getgenv().Config.GhostESP and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            esp.Highlight.FillColor = getgenv().Config.ESPColor

            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                if on then
                    if getgenv().Config.ESPEnabled then
                        local sx, sy = 2000/pos.Z, 3000/pos.Z
                        esp.Box.Visible = true; esp.Box.Size = Vector2.new(sx, sy); esp.Box.Position = Vector2.new(pos.X-sx/2, pos.Y-sy/2); esp.Box.Color = getgenv().Config.ESPColor
                    else esp.Box.Visible = false end

                    if getgenv().Config.NameESP then
                        esp.Text.Visible = true; esp.Text.Position = Vector2.new(pos.X, pos.Y - (3500/pos.Z)/2 - 15)
                        esp.Text.Text = char.Name .. " [" .. math.floor(v.Humanoid.Health) .. "%]"; esp.Text.Color = getgenv().Config.ESPColor
                    else esp.Text.Visible = false end

                    if getgenv().Config.TracerEnabled then
                        esp.Tracer.Visible = true; esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y); esp.Tracer.Color = getgenv().Config.ESPColor
                    else esp.Tracer.Visible = false end
                else
                    esp.Box.Visible = false; esp.Text.Visible = false; esp.Tracer.Visible = false
                end

                -- AIMBOT LOGIC
                local mode = getgenv().Config.TargetMode
                if (mode=="All") or (mode=="Players" and player) or (mode=="NPCs" and not player) then
                    local aim = char:FindFirstChild(getgenv().Config.AimPart) or root
                    local aPos, aOn = Camera:WorldToViewportPoint(aim.Position)
                    if aOn then
                        local mDist = (Vector2.new(aPos.X, aPos.Y) - UIS:GetMouseLocation()).Magnitude
                        if mDist < dist then
                            if not getgenv().Config.WallCheck or #Camera:GetPartsObscuringTarget({aim.Position}, {LP.Character, char}) == 0 then
                                pot = aim; dist = mDist
                            end
                        end
                    end
                end
                
                -- HITBOX LOGIC
                if getgenv().Config.HitboxEnabled then 
                    root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
                    root.Transparency = 0.8; root.CanCollide = false 
                else 
                    root.Size = Vector3.new(2,2,1); root.Transparency = 1 
                end
            end
        else
            RemoveESP(v)
        end
    end
    
    Locked = pot
    if Locked and IsAiming and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Locked.Position), getgenv().Config.Smoothness)
    end
end)

--// Aim Hooks
local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod(); local a = {...}
    if not checkcaller() and getgenv().Config.Method1_Silent and Locked then
        if m == "Raycast" then a[2] = (Locked.Position - a[1]).Unit * 1000; return old(self, unpack(a)) end
    end
    return old(self, ...)
end)
local oldI; oldI = hookmetamethod(game, "__index", function(self, idx)
    if not checkcaller() and getgenv().Config.Method2_Silent and Locked and self == Mouse then
        if idx == "Hit" then return Locked.CFrame elseif idx == "Target" then return Locked end
    end
    return oldI(self, idx)
end)

--// Aim Controls
UIS.InputBegan:Connect(function(i, c)
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = false end
end)

Rayfield:Notify({Title = "Asylum Elite Loaded", Content = "Press Right-Click to Aim. Use the menu to toggle features!", Duration = 5})
