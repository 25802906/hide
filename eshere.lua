-- Bypass unnecessary logging
function errorLogSpoof()
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        if getnamecallmethod() == "FireServer" and tostring(self) == 'UDPSocket' then
            if args[1]['script'] == 'LocalScript' then
                return nil
            end
        end
        return old(self, ...)
    end)
end

errorLogSpoof()

-- Load ESP library from external URL
local espLibrary = loadstring(game:HttpGet('https://raw.githubusercontent.com/mrchigurh/Sirius/request/library/sense/source.lua'))()

-- Initialize ESP collections
getgenv().espObjects = espObjects or {
    ['Players'] = {},
    ['Ammo'] = {},
    ['WorldModel'] = {},
}
getgenv().plrTrackerObjects = plrTrackerObjects or Instance.new('Folder', gethui()) ; plrTrackerObjects.Name = '_Plrs'

-- Function to create ESP for game objects
local function createEspHandler(instance, category)
    local itemName = instance.Name:gsub("%.item", "")
    if category == 'WorldModel' then
        itemName = "Gun"
    end
    local itemInstance = instance
    local isEnabled = true
    local textColor

    if category == 'Ammo' then
        textColor = { Color3.fromRGB(255, 255, 0), 1 } -- Yellow color for Ammo
    elseif category == 'WorldModel' then
        textColor = { Color3.fromRGB(255, 0, 0), 1 } -- Red color for Gun
    else
        textColor = { Color3.fromRGB(255, 255, 255), 1 } -- Default color for other objects
    end

    local newEspObject = espLibrary.AddInstance(itemInstance, {
        enabled = isEnabled,
        text = itemName .. ' [{distance}]', -- Display text with placeholders for name and distance
        textColor = textColor,
        textOutline = true,
        textOutlineColor = Color3.new(),
        textSize = 10, -- Text size
        textFont = 1,
        limitDistance = true,
        maxDistance = 3000, -- Maximum distance for ESP display
    })

    table.insert(espObjects[category], newEspObject)

    instance.Destroying:Connect(function()
        if instance.Parent == nil or instance == nil then
            table.remove(espObjects[category], table.find(espObjects[category], newEspObject))
            newEspObject:Destruct()
        end
    end)
end

-- Function to set up ESP for pseudo player parts
local function setupPlayerPseudoPart(plr)
    local pseudoPart = Instance.new('Part') ; pseudoPart.Parent = plrTrackerObjects
    pseudoPart.Name = plr.Name
    pseudoPart.Position = plr:GetAttribute('CharacterPosition')
    pseudoPart.Anchored = true
    pseudoPart.CanCollide = false
    pseudoPart.CanQuery = false
    pseudoPart.CanTouch = false

    createEspHandler(pseudoPart, 'Players')

    plr:GetAttributeChangedSignal('CharacterPosition'):Connect(function()
        local pos = plr:GetAttribute('CharacterPosition') + Vector3.new(0,3,0)
        pseudoPart.CFrame = CFrame.new(pos)
    end)
end

-- Set up ESP for all current players
for _, plr in ipairs(game:GetService('Players'):GetPlayers()) do
    if plr.Name == game:GetService('Players').LocalPlayer.Name then continue end
    setupPlayerPseudoPart(plr)
end

-- Track new players joining the game
game:GetService('Players').PlayerAdded:Connect(function(plr)
    if plr.Name == game.Players.LocalPlayer.Name then return end
    setupPlayerPseudoPart(plr)
end)

-- Remove ESP when players leave the game
game:GetService('Players').PlayerRemoving:Connect(function(plr)
    if plrTrackerObjects[plr.Name] then
        plrTrackerObjects[plr.Name]:Destroy()
    end
end)

-- Set up ESP for ammo and worldmodel
local itemSpawnDirectory = game:GetService('Workspace').game_assets.item_spawns

local function AmmoEsp()
    itemSpawnDirectory.ChildAdded:Connect(function(child)
        if string.find(child.Name, "Ammo") then
            createEspHandler(child, 'Ammo')
        end
    end)

    for _, ins in ipairs(itemSpawnDirectory:GetChildren()) do
        if string.find(ins.Name, "Ammo") then
            createEspHandler(ins, 'Ammo')
        end
    end
end

local function GunEsp()
    itemSpawnDirectory.ChildAdded:Connect(function(child)
        if string.find(child.Name, "WorldModel") then
            createEspHandler(child, 'WorldModel')
        end
    end)

    for _, ins in ipairs(itemSpawnDirectory:GetChildren()) do
        if string.find(ins.Name, "WorldModel") then
            createEspHandler(ins, 'WorldModel')
        end
    end
end

-- Initialize ESP
AmmoEsp()
GunEsp()
