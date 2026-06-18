-- LightClient Script using LinoriaLib
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Check Game ID
local TARGET_GAME_ID = 79268393072444
local currentGameId = game.PlaceId or game.GameId or 0
local isTargetGame = (currentGameId == TARGET_GAME_ID) or (tostring(currentGameId) == tostring(TARGET_GAME_ID))

-- Set window title based on game
local windowTitle = isTargetGame and 'LightClient                                          (Sell Lemons)' or 'LightClient'

local Window = Library:CreateWindow({
    Title = windowTitle,
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
    Library:Notify({
        Title = title or 'LightClient',
        Content = content or '',
        Duration = duration
    })
end

-- Debug info
print("Current Game ID:", currentGameId)
print("Target Game ID:", TARGET_GAME_ID)
print("Is Target Game:", isTargetGame)

-- Tabs
local Tabs = {
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- Variables
local AutoBuy = false
local AutoUpgrade = false
local AutoFruit = false
local Buying = false

-- Spoofer Variables (only used if not target game)
local SpoofingEnabled = false
local victimId = 4701284318
local helperName = ""
local spoofLevel = 1746
local spoofStreak = 3456
local spoofElo = 24000
local spoofKeys = 435
local spoofPremium = true
local spoofVerified = true
local platformType = "DESKTOP"
local decodedData = nil
local spoofedPlayer = nil
local spoofRenderConnection = nil
local oldNamecall = nil
local characterAddedConnection = nil
local originalName = nil
local originalUserId = nil
local originalDisplayName = nil
local isSpoofing = false

-- Unlock All Variables (only used if not target game)
local UnlockAllEnabled = false

-- Find Tycoon (only if target game)
local userTycoon = nil
if isTargetGame then
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
end

--[[ 
    ========================
    TAB CREATION (Based on game)
    ========================
]]

-- Always add Main tab
Tabs.Main = Window:AddTab('Main')

-- Only add Spoofer and Unlock All tabs if NOT the target game
if not isTargetGame then
    Tabs.Spoofer = Window:AddTab('Spoofer')
    Tabs.UnlockAll = Window:AddTab('Unlock All')
end

--[[ 
    ========================
    MAIN TAB
    ========================
]]

local MainGroup = Tabs.Main:AddLeftGroupbox(isTargetGame and '🍋 Sell Lemons Automation' or 'Tycoon Automation')

if isTargetGame and userTycoon then
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
    
    -- Add lemon count display
    MainGroup:AddLabel('🍋 Sell lemons to earn cash!')
elseif isTargetGame and not userTycoon then
    MainGroup:AddLabel('⚠️ Tycoon not found!')
    MainGroup:AddLabel('Make sure you have a tycoon in the game.')
    MainGroup:AddLabel(' ')
    MainGroup:AddLabel('Current Game ID: ' .. tostring(currentGameId))
else
    -- Not target game - show info
    MainGroup:AddLabel('⚠️ This is not the Sell Lemons game.')
    MainGroup:AddLabel('Current Game ID: ' .. tostring(currentGameId))
    MainGroup:AddLabel('Target Game ID: ' .. tostring(TARGET_GAME_ID))
    MainGroup:AddLabel(' ')
    MainGroup:AddLabel('Sell Lemons features are disabled.')
    MainGroup:AddLabel('✅ Spoofer and Unlock All are available in the other tabs!')
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
    SPOOFER TAB (Only if NOT target game)
    ========================
]]

if not isTargetGame then
    local MasterGroup = Tabs.Spoofer:AddLeftGroupbox('Master Control')

    MasterGroup:AddToggle('EnableSpoofer', {
        Text = 'Enable Spoofer',
        Default = false,
        Tooltip = 'Enables all LightClient spoofer features',
        Callback = function(Value)
            SpoofingEnabled = Value
            if Value then
                EnableSpoofing()
            else
                DisableSpoofing()
            end
        end
    })

    MasterGroup:AddLabel('Spoofer Status: Disabled')

    local IdentityGroup = Tabs.Spoofer:AddLeftGroupbox('Identity Spoofing')

    IdentityGroup:AddInput('VictimID', {
        Default = '4701284318',
        Numeric = true,
        Finished = true,
        Text = 'Victim User ID',
        Tooltip = 'User ID of the player to spoof',
        Placeholder = 'Enter User ID...',
        Callback = function(Value)
            victimId = tonumber(Value) or 4701284318
        end
    })

    IdentityGroup:AddInput('HelperName', {
        Default = '',
        Numeric = false,
        Finished = true,
        Text = 'Helper Username',
        Tooltip = 'Username to spoof (leave empty for yourself)',
        Placeholder = 'Enter username...',
        Callback = function(Value)
            helperName = Value
        end
    })

    IdentityGroup:AddDivider()

    IdentityGroup:AddToggle('SpoofPremium', {
        Text = 'Spoof Premium',
        Default = true,
        Tooltip = 'Spoofs premium membership',
        Callback = function(Value)
            spoofPremium = Value
        end
    })

    IdentityGroup:AddToggle('SpoofVerified', {
        Text = 'Spoof Verified Badge',
        Default = true,
        Tooltip = 'Spoofs verified badge',
        Callback = function(Value)
            spoofVerified = Value
        end
    })

    local StatsGroup = Tabs.Spoofer:AddRightGroupbox('Stats Spoofing')

    StatsGroup:AddInput('SpoofLevel', {
        Default = '1746',
        Numeric = true,
        Finished = true,
        Text = 'Level',
        Tooltip = 'Level to spoof',
        Placeholder = 'Enter level...',
        Callback = function(Value)
            spoofLevel = tonumber(Value) or 1
        end
    })

    StatsGroup:AddInput('SpoofStreak', {
        Default = '3456',
        Numeric = true,
        Finished = true,
        Text = 'Win Streak',
        Tooltip = 'Win streak to spoof',
        Placeholder = 'Enter win streak...',
        Callback = function(Value)
            spoofStreak = tonumber(Value) or 0
        end
    })

    StatsGroup:AddInput('SpoofELO', {
        Default = '24000',
        Numeric = true,
        Finished = true,
        Text = 'ELO',
        Tooltip = 'ELO to spoof',
        Placeholder = 'Enter ELO...',
        Callback = function(Value)
            spoofElo = tonumber(Value) or 0
        end
    })

    StatsGroup:AddInput('SpoofKeys', {
        Default = '435',
        Numeric = true,
        Finished = true,
        Text = 'Keys',
        Tooltip = 'Keys to spoof',
        Placeholder = 'Enter keys...',
        Callback = function(Value)
            spoofKeys = tonumber(Value) or 0
        end
    })

    local PlatformGroup = Tabs.Spoofer:AddRightGroupbox('Platform Spoofing')

    PlatformGroup:AddDropdown('PlatformType', {
        Values = { 'DESKTOP', 'MOBILE', 'CONSOLE', 'VR' },
        Default = 1,
        Multi = false,
        Text = 'Platform Type',
        Tooltip = 'Spoof your platform type',
        Callback = function(Value)
            platformType = Value
        end
    })

    PlatformGroup:AddLabel('Current Platform: ' .. platformType)

    --[[ 
        ========================
        UNLOCK ALL TAB (Only if NOT target game)
        ========================
    ]]

    local UnlockGroup = Tabs.UnlockAll:AddLeftGroupbox('Unlock All')

    UnlockGroup:AddToggle('EnableUnlockAll', {
        Text = 'Enable Unlock All',
        Default = false,
        Tooltip = 'Unlock all items (use with caution)',
        Callback = function(Value)
            UnlockAllEnabled = Value
            if Value then
                ExecuteUnlockAll()
            end
        end
    })

    UnlockGroup:AddButton({
        Text = 'Execute Unlock All',
        Func = function()
            ExecuteUnlockAll()
        end,
        DoubleClick = false,
        Tooltip = 'Manually execute unlock all'
    })

    UnlockGroup:AddLabel('⚠️ WARNING: Use with caution!')
    UnlockGroup:AddLabel('Status: Ready')

    --[[ 
        ========================
        SPOOFER FUNCTIONS (Only if NOT target game)
        ========================
    ]]

    local imagetable = {
        ["DESKTOP"] = "rbxassetid://17136633356",
        ["MOBILE"] = "rbxassetid://17136633510",
        ["CONSOLE"] = "rbxassetid://17136633629",
        ["VR"] = "rbxassetid://17136765745"
    }

    local function ExecuteUnlockAll()
        if not UnlockAllEnabled then
            Notify('Unlock All', 'Enable Unlock All first!', 4)
            return
        end
        
        pcall(function()
            Notify('Unlock All', 'Executing...', 3)
            task.wait(3)
            local unlockScript = game:HttpGet("https://raw.githubusercontent.com/WEFGQERQEGWGE/a/refs/heads/main/yashitcrack.lua")
            if unlockScript then
                loadstring(unlockScript)()
                Notify('Unlock All', 'Executed Successfully! ✓', 5)
            end
        end)
    end

    local function RestoreOriginalData()
        if not decodedData then return end
        
        local player = Players:FindFirstChild(decodedData.name)
        if not player then return end
        
        if originalName and originalName ~= "" then
            pcall(function()
                player.Name = originalName
            end)
        end
        
        if originalUserId then
            pcall(function()
                player.UserId = originalUserId
            end)
        end
        
        if originalDisplayName and originalDisplayName ~= "" then
            pcall(function()
                player.DisplayName = originalDisplayName
            end)
        end
        
        pcall(function()
            player:SetAttribute("Level", nil)
            player:SetAttribute("StatisticDuelsWinStreak", nil)
            player:SetAttribute("DisplayELO", nil)
        end)
    end

    local function CleanupSpoof()
        pcall(function()
            if spoofRenderConnection then
                spoofRenderConnection:Disconnect()
                spoofRenderConnection = nil
            end
        end)
        
        pcall(function()
            if characterAddedConnection then
                characterAddedConnection:Disconnect()
                characterAddedConnection = nil
            end
        end)
        
        oldNamecall = nil
        isSpoofing = false
        spoofedPlayer = nil
    end

    local function DoSpoof()
        if isSpoofing then
            return true
        end
        
        if not victimId then
            Notify('Spoofer', 'Please enter a valid Victim ID', 5)
            return false
        end
        
        local success, data = pcall(function()
            return game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(victimId), true)
        end)
        
        if not success then
            Notify('Spoofer', 'Failed to fetch user data', 5)
            return false
        end
        
        decodedData = HttpService:JSONDecode(data)
        if not decodedData or not decodedData.id then
            Notify('Spoofer', 'Invalid user data received', 5)
            return false
        end
        
        local friend = helperName ~= "" and Players:FindFirstChild(helperName) or LocalPlayer
        if not friend then
            Notify('Spoofer', 'Helper not found!', 5)
            return false
        end
        
        originalName = friend.Name
        originalUserId = friend.UserId
        originalDisplayName = friend.DisplayName
        
        pcall(function()
            friend.Name = decodedData.name
            friend.UserId = decodedData.id
            friend.CharacterAppearanceId = decodedData.id
            friend.DisplayName = decodedData.displayName
        end)
        
        local char = friend.Character
        if not char then
            local success, newChar = pcall(function()
                return friend.CharacterAdded:Wait()
            end)
            if success then
                char = newChar
            end
        end
        
        if char then
            pcall(function()
                char:WaitForChild("Humanoid")
                char.Name = decodedData.name
                char.Humanoid.DisplayName = decodedData.displayName
            end)
        end
        
        local player = Players:FindFirstChild(decodedData.name)
        if player then
            pcall(function()
                player:SetAttribute("Level", tonumber(spoofLevel))
                player:SetAttribute("StatisticDuelsWinStreak", tonumber(spoofStreak))
                
                local customStats = player:FindFirstChild("CustomLeaderstats")
                if customStats then
                    local levelStat = customStats:FindFirstChild("Level")
                    if levelStat then
                        levelStat.Value = tonumber(spoofLevel)
                    end
                    local streakStat = customStats:FindFirstChild("Win Streak")
                    if streakStat then
                        streakStat.Value = tonumber(spoofStreak)
                    end
                end
                
                if tonumber(spoofElo) > 0 then
                    player:SetAttribute("DisplayELO", tonumber(spoofElo))
                end
            end)
        end
        
        ChangeCharacter()
        SetupMetatableHooks()
        SetupRenderStep()
        SetupCharacterAddedConnection()
        
        isSpoofing = true
        return true
    end

    function ChangeCharacter()
        if not decodedData then return end
        
        local plr = Players:FindFirstChild(decodedData.name)
        if not plr or not plr.Character then return end
        
        pcall(function()
            local appearance = Players:GetCharacterAppearanceAsync(decodedData.id)
            for i,v in pairs(plr.Character:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                    v:Destroy()
                end
            end
            for i,v in pairs(appearance:GetChildren()) do
                if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                    v.Parent = plr.Character
                elseif v:IsA("Accessory") then
                    plr.Character.Humanoid:AddAccessory(v)
                end
            end
            local parent = plr.Character.Parent
            plr.Character.Parent = nil
            plr.Character.Parent = parent
        end)
    end

    function SetupCharacterAddedConnection()
        pcall(function()
            if characterAddedConnection then
                characterAddedConnection:Disconnect()
                characterAddedConnection = nil
            end
        end)
        
        if not decodedData then return end
        
        local player = Players:FindFirstChild(decodedData.name)
        if player then
            characterAddedConnection = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if isSpoofing and SpoofingEnabled then
                    ChangeCharacter()
                end
            end)
        end
    end

    function SetupMetatableHooks()
        if not decodedData then return end
        
        local spoofedPlayer = Players:FindFirstChild(decodedData.name)
        if not spoofedPlayer then return end
        
        pcall(function()
            oldNamecall = hookmetamethod(game, "__index", function(self, key)
                if self == spoofedPlayer then
                    if key == "MembershipType" and spoofPremium then
                        return Enum.MembershipType.Premium
                    end
                    if key == "HasVerifiedBadge" and spoofVerified then
                        return true
                    end
                end
                return oldNamecall(self, key)
            end)
        end)
    end

    function SetupRenderStep()
        pcall(function()
            if spoofRenderConnection then
                spoofRenderConnection:Disconnect()
                spoofRenderConnection = nil
            end
        end)
        
        spoofRenderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                if not decodedData or not isSpoofing then return end
                
                local ctrl = Players:FindFirstChild(decodedData.name)
                    and Players[decodedData.name].Character
                    and Players[decodedData.name].Character:FindFirstChild("HumanoidRootPart")
                    and Players[decodedData.name].Character.HumanoidRootPart:FindFirstChild("Nametag")
                    and Players[decodedData.name].Character.HumanoidRootPart.Nametag:FindFirstChild("Frame")
                    and Players[decodedData.name].Character.HumanoidRootPart.Nametag.Frame:FindFirstChild("Player")
                    and Players[decodedData.name].Character.HumanoidRootPart.Nametag.Frame.Player:FindFirstChild("Controls")

                if ctrl then
                    ctrl.Image = imagetable[platformType]
                end
                
                if spoofKeys and spoofKeys > 0 then
                    for _, v in ipairs(LocalPlayer:FindFirstChild("PlayerGui")
                        and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
                        and LocalPlayer.PlayerGui.MainGui:FindFirstChild("MainFrame")
                        and LocalPlayer.PlayerGui.MainGui.MainFrame:FindFirstChild("Lobby")
                        and LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby:FindFirstChild("Currency")
                        and LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency:FindFirstChild("Container")
                        and LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Container:GetDescendants() or {}) do
                        if v.Name == "Icon" and v.Image == "rbxassetid://17860673529" then
                            local title = v.Parent.Parent:FindFirstChild("Title")
                            if title then
                                title.Text = tostring(spoofKeys)
                            end
                        end
                    end
                end
            end)
        end)
    end

    function EnableSpoofing()
        pcall(function()
            CleanupSpoof()
        end)
        
        local success = pcall(DoSpoof)
        
        if success and isSpoofing then
            Notify('Spoofer', 'Enabled - Spoofing ' .. (decodedData and decodedData.name or "Unknown"), 6)
            pcall(function()
                for _, label in ipairs(MasterGroup:GetChildren()) do
                    if label:IsA("Label") and label.Text and label.Text:match("Spoofer Status:") then
                        label:SetText('Spoofer Status: Enabled - Spoofing ' .. (decodedData and decodedData.name or "Unknown"))
                    end
                end
            end)
        else
            SpoofingEnabled = false
            Notify('Spoofer', 'Failed to enable', 4)
        end
    end

    function DisableSpoofing()
        pcall(function()
            if isSpoofing then
                RestoreOriginalData()
            end
        end)
        
        pcall(function()
            CleanupSpoof()
        end)
        
        decodedData = nil
        spoofedPlayer = nil
        isSpoofing = false
        originalName = nil
        originalUserId = nil
        originalDisplayName = nil
        
        pcall(function()
            for _, label in ipairs(MasterGroup:GetChildren()) do
                if label:IsA("Label") and label.Text and label.Text:match("Spoofer Status:") then
                    label:SetText('Spoofer Status: Disabled')
                end
            end
        end)
        
        Notify('Spoofer', 'Disabled', 3)
    end

    Library:OnUnload(function()
        pcall(function()
            DisableSpoofing()
        end)
    end)
end

--[[ 
    ========================
    BACKEND LOGIC (Main Features - Only if target game)
    ========================
]]

if isTargetGame and userTycoon then
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

    -- Auto Sell Lemons Loop (was Auto Buy)
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
    print("Main features disabled - Not target game or tycoon not found")
    if isTargetGame and not userTycoon then
        print("Target game detected but tycoon not found!")
        Notify('LightClient', 'Tycoon not found! Make sure you have a tycoon.', 6)
    end
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
Library:Notify({
    Title = 'LightClient',
    Content = 'Loaded Successfully! ✓',
    Duration = 5
})

if isTargetGame and userTycoon then
    Library:Notify({
        Title = 'LightClient',
        Content = '🍋 Sell Lemons Mode Activated!',
        Duration = 6
    })
elseif isTargetGame and not userTycoon then
    Library:Notify({
        Title = 'LightClient',
        Content = '⚠️ Tycoon not found! Make sure you have a tycoon.',
        Duration = 6
    })
else
    Library:Notify({
        Title = 'LightClient',
        Content = '⚠️ Not Sell Lemons game - Spoofer & Unlock All available',
        Duration = 5
    })
end
