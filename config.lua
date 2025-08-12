Config = {}

-- General Settings
Config.RequiredItem = 'blowtorch' -- Item required to steal catalytic converters
Config.StolenItemName = 'stolen_converter' -- Name of the stolen catalytic converter item
Config.TheftDuration = 15000 -- Time in milliseconds to steal a converter (15 seconds)
Config.TheftCooldown = 60 -- Cooldown in seconds between thefts
Config.MaxTheftsPerDay = 10 -- Maximum number of thefts per day per player
Config.DailyResetTime = 86400000 -- 24 hours in milliseconds

-- Vehicle Settings
Config.PreventOwnedVehicleTheft = true -- Prevent stealing from player-owned vehicles
Config.AlertPolice = true -- Alert police when theft occurs
Config.PoliceAlertChance = 100 -- Percentage chance to alert police (100 = always)

-- Selling Settings
Config.SellPrice = 500 -- Base price for selling a catalytic converter
Config.PriceVariance = 50 -- Random price variance (+/- this amount)

-- NPC Buyer Location
Config.SellNPC = {
    model = 's_m_y_dealer_01', -- NPC model
    coords = vector4(1175.43, -1305.51, 34.89, 90.0), -- NPC location (x, y, z, heading)
    showBlip = true, -- Show blip on map
    blipSprite = 500, -- Blip sprite
    blipColor = 2, -- Blip color
    blipScale = 0.8, -- Blip scale
    blipName = 'Catalytic Converter Buyer' -- Blip name
}

-- Police Jobs (for alert system)
Config.PoliceJobs = {
    'police',
    'sheriff',
    'bcso',
    'trooper',
    'ranger'
}

-- Police Dispatch Configuration
Config.PoliceDispatch = 'custom' -- Options: 'ps-dispatch', 'lb-phone', 'cd-dispatch', 'core-dispatch', 'custom'

-- Custom dispatch function (modify this based on your dispatch system)
Config.CustomPoliceAlert = function(coords, message)
    -- Example for custom dispatch
    -- TriggerServerEvent('your-dispatch:server:alert', {
    --     coords = coords,
    --     message = message,
    --     code = '10-54',
    --     priority = 2
    -- })
    
    -- Default behavior (native alerts to police jobs)
    TriggerServerEvent('cat_theft:alertPolice', coords)
end

-- Admin Settings
Config.EnableAdminCommands = false -- Enable admin commands (removed by default)

-- Advanced Settings
Config.Debug = false -- Enable debug prints

-- You can add multiple sell locations if desired
Config.AdditionalSellLocations = {
    --[[
    {
        model = 's_m_y_dealer_01',
        coords = vector4(100.0, 200.0, 30.0, 180.0),
        showBlip = false,
        blipSprite = 500,
        blipColor = 2,
        blipScale = 0.8,
        blipName = 'Black Market Dealer'
    }
    ]]
}

-- Vehicle Effect Settings
Config.VehicleEffects = {
    smokeEnabled = true, -- Enable smoke effect
    smokeDuration = 300, -- How long smoke lasts (in seconds)
    disableEngine = true, -- Disable the engine after theft
    reduceEngineHealth = true, -- Reduce engine health
    engineHealthAmount = 100.0, -- Engine health after theft
    makeUndriveable = true -- Make vehicle undriveable
}

-- Notification Messages (customize as needed)
Config.Messages = {
    noItem = 'You need a blowtorch to steal catalytic converters',
    cooldown = 'You must wait before stealing again',
    limitReached = 'You\'ve reached the daily theft limit',
    alreadyStolen = 'This vehicle\'s catalytic converter has already been removed',
    ownedVehicle = 'This vehicle belongs to another player',
    theftSuccess = 'You\'ve successfully removed the catalytic converter',
    theftCancelled = 'You stopped removing the catalytic converter',
    nothingToSell = 'You don\'t have any catalytic converters to sell',
    saleComplete = 'Sale complete!',
    inventoryFull = 'Your inventory is full!'
}