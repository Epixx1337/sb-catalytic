local QBCore = nil
local ESX = nil
local activeThefts = {} -- Track active thefts server-side

-- Framework Detection
CreateThread(function()
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('qbx_core') == 'started' then
        QBCore = exports['qbx-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
    end
end)

-- Validate theft attempt (BEFORE theft happens)
lib.callback.register('cat_theft:validateTheft', function(source, vehiclePlate, vehicleCoords)
    local src = source
    
    -- Check if player has required item
    local hasItem = exports.ox_inventory:Search(src, 'count', Config.RequiredItem) > 0
    if not hasItem then
        return false
    end
    
    -- Check player position
    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - vehicleCoords)
    
    if distance > 5.0 then
        return false
    end
    
    -- Check cooldown
    if activeThefts[src] and (GetGameTimer() - activeThefts[src]) < (Config.TheftCooldown * 1000) then
        return false
    end
    
    return true
end)

-- Database check for owned vehicles using ox_lib callback
lib.callback.register('cat_theft:checkOwnership', function(source, plate)
    -- Clean the plate (remove spaces and make uppercase)
    plate = string.upper(string.gsub(plate, "%s+", ""))
    
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    
    return result and #result > 0
end)

-- Reward player with stolen converter (SECURED)
RegisterNetEvent('cat_theft:rewardPlayer', function(vehiclePlate, vehicleCoords)
    local src = source
    
    -- Security check 1: Validate inputs
    if not vehiclePlate or not vehicleCoords then
        print(string.format('[CAT_THEFT] Player %s triggered reward without proper data', GetPlayerName(src)))
        return
    end
    
    -- Security check 2: Check player position
    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - vehicleCoords)
    
    -- Player must be near the vehicle they're stealing from
    if distance > 10.0 then
        print(string.format('[CAT_THEFT] Player %s attempted to claim reward from too far (distance: %.2f)', GetPlayerName(src), distance))
        return
    end
    
    -- Security check 3: Check if player has required item
    local hasItem = exports.ox_inventory:Search(src, 'count', Config.RequiredItem) > 0
    if not hasItem then
        print(string.format('[CAT_THEFT] Player %s attempted theft without required item', GetPlayerName(src)))
        return
    end
    
    -- Security check 4: Check cooldown (prevent spam)
    if activeThefts[src] and (GetGameTimer() - activeThefts[src]) < (Config.TheftCooldown * 1000) then
        print(string.format('[CAT_THEFT] Player %s attempted theft during cooldown', GetPlayerName(src)))
        return
    end
    
    -- Update cooldown
    activeThefts[src] = GetGameTimer()
    
    -- Add catalytic converter to inventory
    local success = exports.ox_inventory:AddItem(src, Config.StolenItemName, 1)
    
    if success then
        -- Log the theft
        print(string.format('[CAT_THEFT] Player %s received 1x %s', GetPlayerName(src), Config.StolenItemName))
        
        -- Trigger any additional logging
        TriggerEvent('cat_theft:log', src, 'theft', {
            item = Config.StolenItemName,
            amount = 1,
            plate = vehiclePlate,
            coords = vehicleCoords,
            time = os.date('%Y-%m-%d %H:%M:%S')
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Inventory Full',
            description = 'Your inventory is full!',
            type = 'error'
        })
    end
end)

-- Sell converters with security checks
RegisterNetEvent('cat_theft:sellConverters', function(amount)
    local src = source
    
    -- Security check 1: Validate source
    if not src or src <= 0 then
        return
    end
    
    -- Security check 2: Get player position
    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    
    -- Security check 3: Check distance from NPC
    local npcCoords = vector3(Config.SellNPC.coords.x, Config.SellNPC.coords.y, Config.SellNPC.coords.z)
    local distance = #(playerCoords - npcCoords)
    
    if distance > 5.0 then
        print(string.format('[CAT_THEFT] Player %s attempted to sell from too far away (distance: %.2f)', GetPlayerName(src), distance))
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Too Far',
            description = 'You need to be near the buyer!',
            type = 'error'
        })
        return
    end
    
    -- Security check 4: Validate amount
    if not amount or type(amount) ~= 'number' or amount <= 0 or amount > 100 then
        print(string.format('[CAT_THEFT] Player %s sent invalid amount: %s', GetPlayerName(src), tostring(amount)))
        return
    end
    
    -- Security check 5: Check actual inventory
    local actualCount = exports.ox_inventory:Search(src, 'count', Config.StolenItemName)
    
    if not actualCount or actualCount <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Nothing to Sell',
            description = 'You don\'t have any catalytic converters!',
            type = 'error'
        })
        return
    end
    
    -- Security check 6: Ensure they're not trying to sell more than they have
    if amount > actualCount then
        print(string.format('[CAT_THEFT] Player %s attempted to sell %d but only has %d', GetPlayerName(src), amount, actualCount))
        amount = actualCount -- Adjust to actual amount
    end
    
    -- Remove items
    local removed = exports.ox_inventory:RemoveItem(src, Config.StolenItemName, amount)
    
    if removed then
        -- Calculate payment (with random variance)
        local basePrice = Config.SellPrice
        local variance = math.random(-Config.PriceVariance, Config.PriceVariance)
        local pricePerUnit = basePrice + variance
        local totalPayment = pricePerUnit * amount
        
        -- Security check 7: Validate payment amount
        local maxPayment = (Config.SellPrice + Config.PriceVariance) * amount
        if totalPayment > maxPayment then
            print(string.format('[CAT_THEFT] Suspicious payment calculation: %d (max: %d)', totalPayment, maxPayment))
            totalPayment = Config.SellPrice * amount
        end
        
        -- Give money based on framework
        if GetResourceState('qbx_core') == 'started' then
            -- QBOX support
            local Player = exports.qbx_core:GetPlayer(src)
            if Player then
                Player.Functions.AddMoney('cash', totalPayment)
            end
        elseif QBCore then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                Player.Functions.AddMoney('cash', totalPayment)
            end
        elseif ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addMoney(totalPayment)
            end
        else
            -- For OX framework or standalone
            exports.ox_inventory:AddItem(src, 'money', totalPayment)
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sale Complete',
            description = string.format('You sold %dx converters for $%d', amount, totalPayment),
            type = 'success'
        })
        
        -- Log the sale with player identifier
        local identifier = GetPlayerIdentifier(src, 0)
        print(string.format('[CAT_THEFT] Player %s (%s) sold %dx %s for $%d at coords %.2f, %.2f, %.2f', 
            GetPlayerName(src), identifier, amount, Config.StolenItemName, totalPayment,
            playerCoords.x, playerCoords.y, playerCoords.z))
        
        TriggerEvent('cat_theft:log', src, 'sale', {
            item = Config.StolenItemName,
            amount = amount,
            payment = totalPayment,
            coords = playerCoords,
            identifier = identifier,
            time = os.date('%Y-%m-%d %H:%M:%S')
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sale Failed',
            description = 'Something went wrong with the sale',
            type = 'error'
        })
    end
end)