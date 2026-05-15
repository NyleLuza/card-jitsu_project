# DojoBlox Game Documentation

# 1. Setup Instructions

## Prerequisites

Install the following:

1. Roblox Studio
2. Roblox account with publishing permissions
3. Internet connection for DataStore functionality

---

## Opening the Project

### Step 1: Launch Roblox Studio

Open Roblox Studio.

### Step 2: Open the RBXLX File

1. Select:
   - `File` → `Open from File`
2. Choose:
   - `card-jitsu_project.rbxlx`

### Step 3: Allow Asset Loading

Wait for all assets and scripts to load fully.

---

## Enable API Services

1. Open:
   - `Home` → `Game Settings`
2. Select:
   - `Security`
3. Enable:
   - `Enable Studio Access to API Services`

This is required for:

- DataStore saving
- Inventory persistence
- Player progression

---

## Teleport Configuration

The project references a battle place ID:

```lua
local battlePlaceId = 98599794487468
```

To configure teleportation:

1. Publish the main experience
2. Create a secondary battle place
3. Replace the placeholder place ID if necessary
4. Ensure both places belong to the same Roblox universe

---

# 2. Execution Instructions

## Running the Game Locally

### Single Player Test

1. Press:
   - `Play`
2. Verify:
   - UI loads correctly
   - Character spawns
   - Inventory opens
   - Music and menus function properly

---

## Multiplayer Testing

### Recommended Method

1. Open:
   - `Test` tab
2. Select:
   - `Start`
3. Choose:
   - 2 or more players

This allows testing of:

- Matchmaking
- Teleport triggers
- Battle UI
- Shop synchronization

---

## Gameplay Execution Flow

1. Player joins game
2. Currency initializes
3. UI systems load
4. Player opens inventory/shop
5. Player builds deck
6. Player enters matchmaking
7. Match found
8. Players teleport to battle place

---

# 3. Validation Instructions

## Automated Validation

The project includes TestEZ for automated testing.

### Running Tests

1. Open Roblox Studio
2. Run the game
3. Monitor the Output window

The following script executes tests:

```lua
RunTests.server
```

### Expected Output

```text
=== Test Runner STARTED ===
```

Successful tests complete without assertion failures.

---

## Manual Validation Checklist

### Inventory Validation

- Inventory opens successfully
- Cards display correctly
- Pack purchases add items
- Inventory persists after rejoin

### Deck Builder Validation

- Cards can be added
- Cards can be removed
- Deck saves successfully

### Matchmaking Validation

- Multiple players can queue
- Match found event triggers
- Players teleport correctly

### Shop Validation

- Shop UI opens
- Purchases deduct currency
- Rewards are granted

### Currency Validation

- Cash initializes on join
- Rewards increase properly

### UI Validation

- Inventory hotkeys function
- Rules window toggles correctly
- Battle UI appears during matchmaking

---

## Known Validation Risks

### LocalPlayer Errors

Some server scripts reference:

```lua
Players.LocalPlayer
```

This only works on the client side and may cause runtime errors.

### Teleport Testing

Teleportation may fail unless:

- The game is published
- Places belong to the same universe
- TeleportService permissions are enabled

### DataStore Failures

Saving may fail if:

- API Services are disabled
- The game is unpublished
- DataStore request limits are exceeded
