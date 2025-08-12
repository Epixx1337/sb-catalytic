# sb-catalytic
Vibecoded fivem script made in 10mins.


# Catalytic Converter Theft System

A realistic catalytic converter theft script for FiveM servers with ox_lib and ox_inventory integration.

## 📋 Features

- Steal catalytic converters from NPC vehicles using a blowtorch
- Realistic animations and vehicle damage effects
- Multiple dispatch system support (ps-dispatch, lb-phone, cd-dispatch, core-dispatch)
- Sell stolen converters to a black market NPC
- Multi-framework support (QB-Core, QBOX, ESX, OX)
- Advanced security with server-side validation
- Configurable cooldowns and daily limits

## 📦 Dependencies

### Required
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)

### Optional (Framework)
- qb-core OR qbx_core OR es_extended

## 🚀 Installation

### Step 1: Resource Setup
1. Download the resource
2. Extract to your resources folder
3. Rename the folder to `cat_theft` (if needed)

### Step 2: Add Items to ox_inventory
Add these items to your `ox_inventory/data/items.lua`:

```lua
['blowtorch'] = {
    label = 'Blowtorch',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A portable blowtorch for cutting metal'
},

['stolen_converter'] = {
    label = 'Stolen Catalytic Converter',
    weight = 5000,
    stack = true,
    close = true,
    description = 'A catalytic converter removed from a vehicle'
},
```

### Step 3: Database Setup
No additional database tables required. The script uses the existing `player_vehicles` table for ownership checks.

### Step 4: Configure Dispatch System
Edit `config.lua` and set your dispatch system:

```lua
Config.PoliceDispatch = 'ps-dispatch' -- Options: 'ps-dispatch', 'lb-phone', 'cd-dispatch', 'core-dispatch', 'custom'
```

### Step 5: Add to server.cfg
```cfg
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure oxmysql
ensure cat_theft
```

## ⚙️ Configuration

All settings can be modified in `config.lua`:

### Basic Settings
```lua
Config.RequiredItem = 'blowtorch' -- Item needed to steal
Config.StolenItemName = 'stolen_converter' -- Item received
Config.TheftDuration = 15000 -- Time to steal (milliseconds)
Config.TheftCooldown = 60 -- Cooldown between thefts (seconds)
Config.MaxTheftsPerDay = 10 -- Daily limit per player
```

### Selling Settings
```lua
Config.SellPrice = 500 -- Base price per converter
Config.PriceVariance = 50 -- Random price variation (+/- amount)
```

### NPC Buyer Location
```lua
Config.SellNPC = {
    model = 's_m_y_dealer_01',
    coords = vector4(1175.43, -1305.51, 34.89, 90.0), -- x, y, z, heading
    showBlip = true,
    blipSprite = 500,
    blipColor = 2,
    blipScale = 0.8,
    blipName = 'Catalytic Converter Buyer'
}
```

### Police Settings
```lua
Config.AlertPolice = true -- Enable police alerts
Config.PoliceDispatch = 'ps-dispatch' -- Your dispatch system
Config.PoliceJobs = { -- Jobs that receive alerts
    'police',
    'sheriff',
    'bcso',
    'trooper',
    'ranger'
}
```

### Custom Dispatch Setup
If using custom dispatch, modify the function in config:
```lua
Config.PoliceDispatch = 'custom'
Config.CustomPoliceAlert = function(coords, message)
    -- Your custom dispatch trigger here
    exports['your-dispatch']:SendAlert({
        coords = coords,
        message = message,
        -- your additional parameters
    })
end
```

## 🎮 Usage

### For Players
1. Obtain a blowtorch item
2. Approach any NPC vehicle
3. Target the exhaust area (target only appears with blowtorch)
4. Complete the theft animation (15 seconds)
5. Vehicle will be disabled with smoke effects
6. Sell converters at the configured NPC location

### For Admins
- Configure all settings in `config.lua`
- Items must be added to ox_inventory
- Ensure all dependencies are started before cat_theft

## 🔧 Troubleshooting

### Target doesn't appear
- Ensure player has blowtorch item
- Check that ox_target is running
- Verify vehicle is not player-owned

### Can't sell converters
- Check distance from NPC (must be within 5 meters)
- Ensure you have stolen converters in inventory
- Verify NPC spawn location is accessible

### Police alerts not working
- Verify dispatch system is configured correctly
- Check that dispatch resource is running
- Ensure police jobs match your server's job names

### SQL Errors
- Ensure oxmysql is running and connected
- Verify player_vehicles table exists
- Check database connection settings

## 📝 Item Spawning

### For QB-Core/QBOX
```
/giveitem [id] blowtorch 1
/giveitem [id] stolen_converter 1
```

### For ESX
```
/giveitem [id] blowtorch 1
/giveitem [id] stolen_converter 1
```

### For Testing (Server Console)
```lua
exports.ox_inventory:AddItem(playerId, 'blowtorch', 1)
exports.ox_inventory:AddItem(playerId, 'stolen_converter', 1)
```

## 🛡️ Security Features

- Server-side validation for all rewards
- Distance checks (player must be near vehicle)
- Item verification (must have blowtorch)
- Cooldown enforcement (prevents spam)
- Anti-exploit protection on sell events
- Owned vehicle protection

## 📋 Default Controls

- **Target Vehicle**: Alt (ox_target default)
- **Cancel Theft**: X (during progress bar)

## 🆘 Support

- Check console (F8) for any errors
- Ensure all dependencies are up to date
- Verify configuration matches your server setup
- All events are logged with [CAT_THEFT] prefix

## 📄 License

This resource is provided as-is for use on FiveM servers.

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Full ox_lib integration
- Multi-framework support
- Secure event system
- Configurable dispatch systems

---

**Note:** Always backup your server before installing new resources. Test in a development environment first.