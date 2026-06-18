-- LightClient - Sell Lemons Only
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'LightClient                                          (Sell Lemons)',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Notification helper
local function Notify(title, content, duration)
    duration = duration or 5
    Library:Notify(title .. ': ' .. content, duration)
end

-- Tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- Variables
local AutoBuy = false
local AutoUpgrade = false
local AutoFruit = false
local Buying = false

-- Find Tycoon
local userTycoon = nil
task.wait(2)

for _, v in pairs(workspace:GetChildren()) do
    if v:IsA("Folder") and (v.Name:match("Tycoon%d") or v.Name:match("Tycoon")) then
        if v:FindFirstChild("Owner") then
            local owner = v.Owner.Value
            if owner == LocalPlayer then
                userTycoon = v
                print("Found user tycoon:", v.Name)
                break
            end
        end
    end
end

if not userTycoon then
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Folder") and (v.Name:match("Tycoon%d") or v.Name:match("Tycoon")) then
            if v:FindFirstChild("Owner") then
                local owner = v.Owner.Value
                if owner == LocalPlayer then
                    userTycoon = v
                    print("Found user tycoon (deep search):", v.Name)
                    break
                end
            end
        end
    end
end

print("User tycoon found:", userTycoon ~= nil)

--[[ 
    ========================
    MAIN TAB
    ========================
]]

local MainGroup = Tabs.Main:AddLeftGroupbox('🍋 Sell Lemons Automation')

if userTycoon then
    -- Auto Buy (Sell Lemons)
    MainGroup:AddToggle('AutoBuy', {
        Text = 'Auto Sell Lemons',
        Default = false,
        Tooltip = 'Automatically sells lemons from your tycoon',
        Callback = function(Value)
            AutoBuy = Value
            Notify('Auto Sell', Value and 'Enabled ✓' or 'Disabled ✗', 3)
        end
    })

    -- Auto Upgrade
    MainGroup:AddToggle('AutoUpgrade', {
        Text = 'Auto Upgrade',
        Default = false,
        Tooltip = 'Automatically upgrades your machines',
        Callback = function(Value)
            AutoUpgrade = Value
            Notify('Auto Upgrade', Value and 'Enabled ✓' or 'Disabled ✗', 3)
        end
    })

    -- Auto Fruit
    MainGroup:AddToggle('AutoFruit', {
        Text = 'Auto Collect Fruit',
        Default = false,
        Tooltip = 'Automatically collects fruits from lemon trees',
        Callback = function(Value)
            AutoFruit = Value
            Notify('Auto Fruit', Value and 'Enabled ✓' or 'Disabled ✗', 3)
        end
    })

    MainGroup:AddDivider()
    MainGroup:AddLabel('✅ Status: Running - Sell Lemons Mode')
    MainGroup:AddLabel('Tycoon: ' .. userTycoon.Name)
    MainGroup:AddLabel('🍋 Sell lemons to earn cash!')
else
    MainGroup:AddLabel('⚠️ Tycoon not found!')
    MainGroup:AddLabel('Make sure you have a tycoon in the game.')
end

MainGroup:AddDivider()
MainGroup:AddButton({
    Text = 'Destroy GUI',
    Func = function()
        Library:Unload()
    end,
    DoubleClick = false,
    Tooltip = 'Unloads LightClient and destroys the GUI'
})

--[[ 
    ========================
    BACKEND LOGIC
    ========================
]]

if userTycoon then
    print("Setting up Sell Lemons automation for:", userTycoon.Name)
    
    local function getButtons()
        local Buttons = {}
        local purchases = userTycoon:FindFirstChild("Purchases")
        if not purchases then
            return Buttons
        end
        
        for _, obj in ipairs(purchases:GetDescendants()) do
            if obj:IsA("Model") then
                local shown = obj:GetAttribute("Shown")
                local purchased = obj:GetAttribute("Purchased")
                if shown == true and purchased ~= true then
                    local buttonPart = obj:FindFirstChild("Button")
                    if buttonPart and buttonPart:IsA("BasePart") then
                        table.insert(Buttons, {
                            Name = obj.Name,
                            Button = buttonPart,
                        })
                    end
                end
            end
        end
        return Buttons
    end

    local function buyButton(buttonData)
        if Buying then return end
        Buying = true
        local character = LocalPlayer.Character
        if not character then Buying = false; return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then Buying = false; return end
        local buttonPart = buttonData.Button
        pcall(function()
            firetouchinterest(hrp, buttonPart, 0)
            firetouchinterest(hrp, buttonPart, 1)
        end)
        Buying = false
    end

    -- Auto Sell Lemons Loop
    task.spawn(function()
        while task.wait(0.5) do
            if AutoBuy then
                local Buttons = getButtons()
                for _, button in ipairs(Buttons) do
                    pcall(function() buyButton(button) end)
                end
            end
        end
    end)

    -- Auto Upgrade Loop
    local function upgradeMachines()
        local purchases = userTycoon:FindFirstChild("Purchases")
        if not purchases then return end
        
        for _, obj in ipairs(purchases:GetDescendants()) do
            if obj:IsA("RemoteFunction") and obj.Name == "Upgrade" then
                pcall(function()
                    for level = 1, 100 do
                        obj:InvokeServer(level)
                    end
                end)
            end
        end
    end

    task.spawn(function()
        while task.wait(1) do
            if AutoUpgrade then
                pcall(function() upgradeMachines() end)
            end
        end
    end)

    -- Auto Fruit Collection Loop
    local Trees = {}

    local function addTree(obj)
        if obj:IsA("Model") and obj.Name == "LemonTree" then
            if not table.find(Trees, obj) then
                table.insert(Trees, obj)
                print("Added tree:", obj.Name)
            end
        end
    end

    local function removeTree(obj)
        local index = table.find(Trees, obj)
        if index then
            table.remove(Trees, index)
        end
    end

    for _, v in ipairs(workspace:GetDescendants()) do
        addTree(v)
    end

    workspace.DescendantAdded:Connect(addTree)
    workspace.DescendantRemoving:Connect(removeTree)

    local function noCollisionTree(tree)
        for _, obj in ipairs(tree:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CanCollide = false
            end
        end
    end

    local function teleportToTree(tree)
        local character = LocalPlayer.Character
        if not character then return false end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local cf = tree:GetPivot()
        hrp.CFrame = cf + Vector3.new(0, 5, 0)
        return true
    end

    local function collectFruit(tree)
        noCollisionTree(tree)
        local success = teleportToTree(tree)
        if not success then return end
        for _, obj in ipairs(tree:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Fruit" then
                obj.CanCollide = false
                local clickPart = obj:FindFirstChild("ClickPart")
                if clickPart then
                    local detector = clickPart:FindFirstChildOfClass("ClickDetector")
                    if detector then
                        task.wait(0.45)
                        pcall(function() fireclickdetector(detector) end)
                    end
                end
            end
        end
    end

    task.spawn(function()
        while task.wait(0.5) do
            if AutoFruit then
                for _, tree in ipairs(Trees) do
                    if not AutoFruit then break end
                    if tree and tree.Parent then
                        pcall(function() collectFruit(tree) end)
                    end
                end
            end
        end
    end)
    
    print("Sell Lemons automation setup complete!")
else
    print("Tycoon not found!")
    Notify('LightClient', 'Tycoon not found! Make sure you have a tycoon.', 6)
end

--[[ 
    ========================
    UI SETTINGS
    ========================
]]

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI = true,
    Text = 'Menu keybind'
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('LightClient')
SaveManager:SetFolder('LightClient')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

-- Initial notifications
Notify('LightClient', 'Loaded Successfully! ✓', 5)

if userTycoon then
    Notify('LightClient', '🍋 Sell Lemons Mode Activated!', 6)
else
    Notify('LightClient', '⚠️ Tycoon not found! Make sure you have a tycoon.', 6)
end
