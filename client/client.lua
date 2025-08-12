local QBCore = nil
local ESX = nil
local activeThefts = {}
local cooldownTime = 0
local theftCount = 0
local lastResetTime = 0

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

-- Utility Functions
local function GetPlayerData()
    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:GetPlayerData()
    elseif QBCore then
        return QBCore.Functions.GetPlayerData()
    elseif ESX then
        return ESX.GetPlayerData()
    end
    return {}
end

local function HasItem(item)
    return exports.ox_inventory:Search('count', item) > 0
end

local function NotifyPolice(coords)
    local message = "Catalytic Converter Theft in Progress"
    
    if Config.PoliceDispatch == 'ps-dispatch' then
        exports['ps-dispatch']:CustomAlert({
            coords = coords,
            message = message,
            dispatchCode = '10-54',
            description = 'Catalytic Converter Theft',
            radius = 0,
            sprite = 380,
            color = 1,
            scale = 1.0,
            length = 3,
        })
    elseif Config.PoliceDispatch == 'lb-phone' then
        exports['lb-phone']:SendDispatch({
            message = message,
            coords = coords,
            job = Config.PoliceJobs,
            alert = {
                sprite = 380,
                color = 1,
                scale = 1.0,
                length = 3,
                sound = "Lose_1st",
                sound2 = "GTAO_FM_Events_Soundset",
                flash = false
            }
        })
    elseif Config.PoliceDispatch == 'cd-dispatch' then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = Config.PoliceJobs,
            coords = coords,
            title = '10-54 - Catalytic Converter Theft',
            message = message .. ' at ' .. data.street,
            flash = 0,
            unique_id = tostring(math.random(0000000,9999999)),
            blip = {
                sprite = 380,
                scale = 1.0,
                colour = 1,
                flashes = false,
                text = '10-54 - Theft in Progress',
                time = (5*60*1000),
                sound = 1,
            }
        })
    elseif Config.PoliceDispatch == 'core-dispatch' then
        exports['core_dispatch']:addCall("10-54", message, {
            {icon="fas fa-globe-europe", info=GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))}
        }, {coords.x, coords.y, coords.z}, "police", 3000, 380, 1)
    elseif Config.PoliceDispatch == 'custom' then
        Config.CustomPoliceAlert(coords, message)
    else
        -- Default fallback
        TriggerServerEvent('cat_theft:alertPolice', coords)
    end
end

local function ApplyVehicleEffects(vehicle)
    -- Disable vehicle and apply smoke effects
    SetVehicleEngineHealth(vehicle, 100.0)
    SetVehicleBodyHealth(vehicle, 500.0)
    SetVehicleUndriveable(vehicle, true)
    SetVehicleEngineOn(vehicle, false, true, true)
    
    -- Create smoke effect
    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do
        Wait(100)
    end
    
    CreateThread(function()
        local count = 0
        while count < Config.VehicleEffects.smokeDuration and DoesEntityExist(vehicle) do
            local exhaustBone = GetEntityBoneIndexByName(vehicle, "exhaust")
            local exhaustPos
            if exhaustBone ~= -1 then
                exhaustPos = GetWorldPositionOfEntityBone(vehicle, exhaustBone)
            else
                local vehCoords = GetEntityCoords(vehicle)
                exhaustPos = vector3(vehCoords.x, vehCoords.y - 2.0, vehCoords.z)
            end
            
            UseParticleFxAssetNextCall("core")
            local particle = StartParticleFxLoopedAtCoord(
                "exp_grd_bzgas_smoke",
                exhaustPos.x,
                exhaustPos.y,
                exhaustPos.z,
                0.0, 0.0, 0.0,
                0.5,
                false, false, false
            )
            
            Wait(100)
            StopParticleFxLooped(particle, false)
            count = count + 1
            Wait(1900)
        end
    end)
    
    -- Alter exhaust sound
    SetVehicleAudioBodyDamageFactor(vehicle, 15.0)
end

local function StartTheft(vehicle)
    if not HasItem(Config.RequiredItem) then
        exports.ox_lib:notify({
            title = 'Theft Failed',
            description = 'You need a ' .. Config.RequiredItem .. ' to steal catalytic converters',
            type = 'error'
        })
        return
    end
    
    if cooldownTime > GetGameTimer() then
        local remaining = math.ceil((cooldownTime - GetGameTimer()) / 1000)
        exports.ox_lib:notify({
            title = 'Cooldown',
            description = 'You must wait ' .. remaining .. ' seconds before stealing again',
            type = 'error'
        })
        return
    end
    
    -- Check daily limit
    local currentTime = GetGameTimer()
    if currentTime - lastResetTime > Config.DailyResetTime then
        theftCount = 0
        lastResetTime = currentTime
    end
    
    if theftCount >= Config.MaxTheftsPerDay then
        exports.ox_lib:notify({
            title = 'Limit Reached',
            description = 'You\'ve reached the daily theft limit',
            type = 'error'
        })
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    -- Check if already stolen
    if activeThefts[plate] then
        exports.ox_lib:notify({
            title = 'Already Stolen',
            description = 'This vehicle\'s catalytic converter has already been removed',
            type = 'error'
        })
        return
    end
    
    -- Check ownership
    if Config.PreventOwnedVehicleTheft then
        local isOwned = lib.callback.await('cat_theft:checkOwnership', false, plate)
        if isOwned then
            exports.ox_lib:notify({
                title = 'Cannot Steal',
                description = 'This vehicle belongs to another player',
                type = 'error'
            })
            return
        end
    end
    
    -- Validate theft server-side FIRST
    local vehicleCoords = GetEntityCoords(vehicle)
    local canTheft = lib.callback.await('cat_theft:validateTheft', false, plate, vehicleCoords)
    
    if not canTheft then
        exports.ox_lib:notify({
            title = 'Cannot Steal',
            description = 'Unable to steal from this vehicle',
            type = 'error'
        })
        return
    end
    
    -- Start theft animation and progress
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Alert police
    if Config.AlertPolice then
        NotifyPolice(coords)
    end
    
    -- Animation setup
    RequestAnimDict("amb@world_human_vehicle_mechanic@male@base")
    while not HasAnimDictLoaded("amb@world_human_vehicle_mechanic@male@base") do
        Wait(100)
    end
    
    -- Get driver door position
    local driverDoorBone = GetEntityBoneIndexByName(vehicle, "door_dside_f")
    local driverDoorPos
    
    if driverDoorBone ~= -1 then
        driverDoorPos = GetWorldPositionOfEntityBone(vehicle, driverDoorBone)
    else
        -- Fallback: calculate driver door position manually (left front)
        local vehicleHeading = GetEntityHeading(vehicle)
        local offset = vector3(
            math.cos(math.rad(vehicleHeading + 90)) * 1.0,  -- Left side
            math.sin(math.rad(vehicleHeading + 90)) * 1.0,
            0.0
        )
        driverDoorPos = vehicleCoords + offset
    end
    
    -- Walk to driver door
    TaskGoStraightToCoord(playerPed, driverDoorPos.x, driverDoorPos.y, driverDoorPos.z, 1.0, 3000, GetEntityHeading(vehicle), 0.5)
    Wait(3000)
    
    -- Adjust heading to face the door with head going under first
    local vehicleHeading = GetEntityHeading(vehicle)
    SetEntityHeading(playerPed, vehicleHeading + 90) -- Face the opposite way so head goes toward vehicle
    
    -- Position adjustment for animation
    local finalPos = GetEntityCoords(playerPed)
    SetEntityCoords(playerPed, finalPos.x, finalPos.y, finalPos.z - 0.2)
    
    -- Now play the animation to go under
    TaskPlayAnim(playerPed, "amb@world_human_vehicle_mechanic@male@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Progress bar
    if exports.ox_lib:progressBar({
        duration = Config.TheftDuration,
        label = 'Removing catalytic converter...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- Success - play exit animation
        RequestAnimDict("amb@world_human_vehicle_mechanic@male@exit")
        while not HasAnimDictLoaded("amb@world_human_vehicle_mechanic@male@exit") do
            Wait(100)
        end
        TaskPlayAnim(playerPed, "amb@world_human_vehicle_mechanic@male@exit", "exit", 8.0, -8.0, -1, 0, 0, false, false, false)
        Wait(1500)
        ClearPedTasks(playerPed)
        
        -- Mark as stolen
        activeThefts[plate] = true
        
        -- Apply vehicle effects
        ApplyVehicleEffects(vehicle)
        
        -- Give item and update counts (send vehicle data for validation)
        TriggerServerEvent('cat_theft:rewardPlayer', plate, vehicleCoords)
        theftCount = theftCount + 1
        cooldownTime = GetGameTimer() + (Config.TheftCooldown * 1000)
        
        exports.ox_lib:notify({
            title = 'Success',
            description = 'You\'ve successfully removed the catalytic converter',
            type = 'success'
        })
    else
        -- Cancelled
        ClearPedTasks(playerPed)
        exports.ox_lib:notify({
            title = 'Cancelled',
            description = 'You stopped removing the catalytic converter',
            type = 'error'
        })
    end
end

-- Target System with item check
CreateThread(function()
    local hasTarget = false
    
    while true do
        local hasItem = HasItem(Config.RequiredItem)
        
        if hasItem and not hasTarget then
            -- Add target when player has item
            exports.ox_target:addGlobalVehicle({
                {
                    name = 'steal_catalytic',
                    icon = 'fas fa-wrench',
                    label = 'Steal Catalytic Converter',
                    distance = 2.5,
                    bones = {'exhaust', 'exhaust_2', 'exhaust_3', 'exhaust_4', 'exhaust_5', 'exhaust_6', 'exhaust_7', 'exhaust_8'},
                    onSelect = function(data)
                        StartTheft(data.entity)
                    end,
                    canInteract = function(entity, distance, coords, name)
                        if not DoesEntityExist(entity) then return false end
                        if GetPedInVehicleSeat(entity, -1) ~= 0 then return false end
                        if not IsVehicleStopped(entity) then return false end
                        
                        local plate = GetVehicleNumberPlateText(entity)
                        if activeThefts[plate] then return false end
                        
                        return true
                    end
                }
            })
            hasTarget = true
        elseif not hasItem and hasTarget then
            -- Remove target when player doesn't have item
            exports.ox_target:removeGlobalVehicle({'steal_catalytic'})
            hasTarget = false
        end
        
        Wait(1000) -- Check every second
    end
end)

-- Selling System
local function SetupSellNPC()
    local model = GetHashKey(Config.SellNPC.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    local npc = CreatePed(4, model, Config.SellNPC.coords.x, Config.SellNPC.coords.y, Config.SellNPC.coords.z - 1.0, Config.SellNPC.coords.w, false, true)
    
    SetEntityHeading(npc, Config.SellNPC.coords.w)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    
    -- Add target to NPC
    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'sell_catalytic',
            icon = 'fas fa-dollar-sign',
            label = 'Sell Catalytic Converters',
            distance = 2.5,
            onSelect = function()
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local npcCoords = vector3(Config.SellNPC.coords.x, Config.SellNPC.coords.y, Config.SellNPC.coords.z)
                local distance = #(playerCoords - npcCoords)
                
                -- Client-side distance check
                if distance > 5.0 then
                    exports.ox_lib:notify({
                        title = 'Too Far',
                        description = 'You need to be closer to the buyer',
                        type = 'error'
                    })
                    return
                end
                
                local count = exports.ox_inventory:Search('count', Config.StolenItemName)
                if count > 0 then
                    -- Send sell request with the actual count
                    TriggerServerEvent('cat_theft:sellConverters', count)
                else
                    exports.ox_lib:notify({
                        title = 'Nothing to Sell',
                        description = 'You don\'t have any catalytic converters to sell',
                        type = 'error'
                    })
                end
            end
        }
    })
    
    -- Add blip
    if Config.SellNPC.showBlip then
        local blip = AddBlipForCoord(Config.SellNPC.coords.x, Config.SellNPC.coords.y, Config.SellNPC.coords.z)
        SetBlipSprite(blip, Config.SellNPC.blipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.SellNPC.blipScale)
        SetBlipColour(blip, Config.SellNPC.blipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.SellNPC.blipName)
        EndTextCommandSetBlipName(blip)
    end
end

-- Initialize
CreateThread(function()
    Wait(1000)
    SetupSellNPC()
end)