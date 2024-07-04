-- // BYPASS
function errorLogSpoof()
    local old;old = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        if getnamecallmethod() == "FireServer" and tostring(self) == 'UDPSocket' then
            if args[1]['script'] == 'LocalScript' then -- It's likely that the game knows there are no scripts named "LocalScript" so it bans.
                return nil
            end
        end
        return old(self, ...)
    end)
end

errorLogSpoof()

-- // GLOBALS
getgenv().espObjects = espObjects or { ['Ammo'] = {} }

-- // VARIABLES
local player = game:GetService('Players').LocalPlayer
local espLibrary = loadstring(game:HttpGet('https://raw.githubusercontent.com/mrchigurh/Sirius/request/library/sense/source.lua'))()
local itemSpawnDirectory = game:GetService('Workspace').game_assets.item_spawns

local espData = {
    ['GroundItems'] = {
        ['Ammo'] = {
            Type = 'ApartOfName',
            Contents = 'Ammo'
        }
    }
}

-- // FUNCTIONS
function getAssociation(instance)
    local itemName = instance.Name:gsub("%.item", "")
    local selectedAssocation = nil

    for categoryKey, mainInfo in espData do
        for key, itemInfo in mainInfo do
            if itemInfo['Type'] == 'ApartOfName' then
                if string.find(itemName, itemInfo['Contents'], 1, false) ~= nil then selectedAssocation = key end
            end
        end
    end

    if selectedAssocation == nil then selectedAssocation = 'Misc' end
    return selectedAssocation
end

function createEspHandler(instance, association)
    if instance:IsA('Folder') then return end
    local itemName = instance.Name:gsub("%.item", "")
    local primaryPart = instance:IsA('Model') and instance.PrimaryPart or instance

    if instance.Parent == itemSpawnDirectory then
        association = association or getAssociation(instance)
        if association == 'Ammo' then
            local newEspObject = espLibrary.AddInstance(primaryPart, {
                enabled = true,
                text = itemName .. ' | {distance}', -- Placeholders: {name}, {distance}, {position}
                textColor = { Color3.new(0.419607, 0.788235, 0.529411), 1 },
                textOutline = true,
                textOutlineColor = Color3.new(),
                textSize = 12,
                textFont = 2,
                limitDistance = true,
                maxDistance = 3000,
            })

            table.insert(espObjects[association], newEspObject)

            instance.Destroying:Connect(function()
                if instance.Parent == nil or instance == nil then
                    table.remove(espObjects[association], table.find(espObjects[association], newEspObject))
                    newEspObject:Destruct()
                end
            end)
        end
    end
end

function initEsp()
    for _, ins in itemSpawnDirectory:GetChildren() do
        createEspHandler(ins)
    end

    itemSpawnDirectory.ChildAdded:Connect(function(child)
        createEspHandler(child)
    end)
end

-- // MAIN
errorLogSpoof()
initEsp()
