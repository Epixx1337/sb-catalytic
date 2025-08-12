# sb-catalytic
Vibecoded fivem script made in 10mins.


# 🔧 Advanced Catalytic Converter Theft System for FiveM

## 📋 Description
A comprehensive and highly optimized catalytic converter theft script for FiveM servers. This system allows players to steal catalytic converters from NPC vehicles using realistic mechanics, complete with police alerts, vehicle damage effects, and a black market selling system. Built with security and performance in mind using ox_lib and ox_inventory.

## ✨ Key Features

### 🎯 Core Functionality
- **Realistic Theft Mechanic** - Target vehicle exhaust bones specifically with a blowtorch
- **Dynamic Targeting** - Target only appears when player has the required tool
- **Smooth Animation System** - Player walks to driver door, positions correctly, then slides under vehicle
- **Vehicle Damage System** - Stolen vehicles emit heavy smoke from exhaust and become undriveable
- **Black Market NPC** - Sell stolen converters to a configurable buyer location
- **Smart Inventory Integration** - Full ox_inventory support with item management

### 🚔 Law Enforcement
- **Multiple Dispatch Support** - Integrated with popular dispatch systems:
  - ✅ ps-dispatch
  - ✅ lb-phone dispatch
  - ✅ cd-dispatch  
  - ✅ core-dispatch
  - ✅ Custom dispatch functions
- **No Double Notifications** - Clean integration without redundant alerts
- **Configurable Police Jobs** - Define which jobs receive theft alerts

### 🛡️ Security Features
- **Anti-Exploit Protection** - Multiple server-side validation checks
- **Secured Events** - All events validated with distance, item, and cooldown checks
- **Distance Verification** - 5-meter radius check for NPC interactions
- **Inventory Validation** - Prevents item duplication and invalid transactions
- **Server-Side Cooldowns** - Prevents spam and exploitation
- **Owned Vehicle Protection** - Cannot steal from player-owned vehicles
- **Detailed Logging** - Complete transaction logs with player identifiers

### ⚖️ Balance & Economy
- **Cooldown System** - Configurable time between thefts (default: 60 seconds)
- **Daily Limits** - Maximum thefts per day per player (default: 10)
- **Price Variance** - Random market fluctuation for converter prices ($450-$550 default)
- **Required Tool** - Players must have blowtorch to steal
- **Weight System** - Converters have realistic weight in inventory (5000g)

### 🎮 Framework Support
- **Multi-Framework Compatible**:
  - ✅ QB-Core
  - ✅ QBOX (qbx_core)
  - ✅ ESX
  - ✅ OX (standalone)
- **Automatic Detection** - Script auto-detects your framework
- **Database Integration** - Works with standard player_vehicles table

### 🔧 Technical Features
- **Optimized Performance** - Uses ox_lib callbacks and efficient threads
- **Clean Code Structure** - Organized client/server architecture
- **Extensive Configuration** - Highly customizable via config.lua
- **Proper Animations** - Uses correct GTA V mechanic animations
- **Particle Effects** - Realistic smoke from damaged vehicles
- **No Unnecessary Features** - Clean, focused functionality

## 📦 Dependencies
**Required:**
- ox_lib
- ox_inventory
- ox_target
- oxmysql

**Optional** (for framework support):
- qb-core / qbx_core / es_extended

## 🎯 Installation

### 1. Add to your resources folder
```
resources/
├── cat_theft/
│   ├── fxmanifest.lua
│   ├── config.lua
│   ├── client/
│   │   └── main.lua
│   └── server/
│       └── main.lua
```

### 2. Add items to ox_inventory
Add to `ox_inventory/data/items.lua`:
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

### 3. Configure your dispatch
Edit `config.lua`:
```lua
Config.PoliceDispatch = 'ps-dispatch' -- Your dispatch system
```

### 4. Start the resource
```cfg
ensure cat_theft
```

## 🎮 How It Works

1. **Player needs blowtorch in inventory** - Target only appears with item
2. **Target exhaust area of NPC vehicle** - Realistic targeting on exhaust bones
3. **Character walks to driver door** - Natural movement to position
4. **15-second theft animation** - Player slides under vehicle realistically
5. **Police receive dispatch alert** - Through your configured dispatch system
6. **Vehicle disabled with smoke** - Realistic damage effects
7. **Receive stolen converter** - Added to inventory with weight
8. **Sell at black market NPC** - Configurable location with price variance

## ⚙️ Configuration Options

- ✅ Theft duration and cooldowns
- ✅ Daily theft limits  
- ✅ Item names and requirements
- ✅ NPC buyer location and model
- ✅ Sell prices with variance
- ✅ Police dispatch system
- ✅ Vehicle damage effects
- ✅ Smoke duration and intensity
- ✅ All notification messages

## 🔒 Security Highlights

- **Server-validated events** - Can't exploit reward events
- **Distance checks** - Must be near vehicle/NPC
- **Item verification** - Server confirms inventory
- **Cooldown enforcement** - Server-tracked per player
- **Anti-spam protection** - Rate limiting built-in

## 📸 Features Showcase

- ✨ **Realistic Animations** - Proper mechanic sliding under vehicle
- 🚗 **Vehicle Effects** - Heavy smoke from exhaust after theft
- 🎯 **Smart Targeting** - Only shows when equipped with blowtorch
- 💰 **Dynamic Economy** - Fluctuating black market prices
- 👮 **Police Integration** - Clean dispatch system support

## 💡 Why This Script?

- **Performance Optimized** - Built with ox_lib for efficiency
- **Secure by Design** - Multiple validation layers
- **Framework Flexible** - Works with all major frameworks
- **Realistic Mechanics** - Proper animations and effects
- **Easy Configuration** - Simple config file setup
- **Active Development** - Regular updates and support

---

**A quality script that brings realistic criminal activity to your server while maintaining balance and security. Perfect for servers looking to expand their criminal economy with engaging mechanics!**

**Download:** [GitHub/Releases Link]  
**Support:** [Discord Server]  
**Preview:** [Video Link]