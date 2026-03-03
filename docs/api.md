# API Documentation — Pack Opening (RequestOpenPack)

## Overview

This document describes the **RequestOpenPack RemoteEvent**, which handles pack opening in DojoBlox.

When a player opens a pack, the server:

1. Validates the pack name
2. Retrieves the pack's card list from `ReplicatedStorage.Packs.Series1`
3. Retrieves each card's weight from `ReplicatedStorage.Cards.CardConfig`
4. Uses weighted random selection (gacha system)
5. Adds the selected card to the player’s inventory
6. Removes the opened pack from the inventory
7. Sends the updated inventory back to the client

This system ensures that pack opening is **server-authoritative**.

---

# API Specification

## Name

**RequestOpenPack (RemoteEvent)**

---

## Description

Opens a card pack owned by a player and randomly awards one card based on weighted probability.

The server determines the result and updates the inventory.

---

## Signature / Endpoint

### Client → Server

```lua
ReplicatedStorage.RemoteEvents.RequestOpenPack:FireServer(PackName: string)
```

## Parameters

| Name     | Type   | Source | Description                                                                              |
| -------- | ------ | ------ | ---------------------------------------------------------------------------------------- |
| player   | Player | Server | The player who triggered the RemoteEvent (automatically passed by Roblox).               |
| PackName | string | Client | The name of the pack to open. Must match a key inside `ReplicatedStorage.Packs.Series1`. |

## Return Values

Remote Events do not return values directly and instead send signals to the server to send the information

```lua
ReplicatedStorage.RemoteEvents.SendInventory:FireClient(player, updatedItems)
```

### Result of Server

```lua
Pack1 = {
	id = "p1",
	name = "Origins Pack",
	description = "A balanced pack containing Fire, Water, and Snow cards.",
	image = "temp",
	cost = 200,
	num_cards = 6,
	cards = {
		"BlazeImp",
		"PyroDrake",
		"Frostling",
		"CrystalGolem",
		"AquaSprite",
		"AbyssLeviathan",
	}
}
```

## Errors and Exceptions

The following issues may occur:

1. Invalid Pack Name

If PackName does not exist in:

```lua
ReplicatedStorage.Packs.Series1
```

2. Inventory Not Initialized

If InventoryService.InitPlayer has not run, the player inventory may not exist in memory.

3. Invalid Weights

Weights must be positive numbers. If all weights are zero or invalid, random selection will not work.

## Example Usage

### Client Example (Opening a Pack)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestOpenPack = ReplicatedStorage.RemoteEvents.RequestOpenPack

-- Attempt to open a pack
RequestOpenPack:FireServer("StarterPack")
```

### Client Example (Receiving Updated Inventory)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SendInventory = ReplicatedStorage.RemoteEvents.SendInventory

SendInventory.OnClientEvent:Connect(function(updatedItems)
    print("Inventory updated!")
    print(updatedItems)
end)
```

## Important Notes & Limitations

### Server Authority

All pack opening logic runs on the server. Clients cannot determine card results.

### Inventory Updates

The server currently fires SendInventory after:

Adding the card

Removing the pack

This may result in multiple UI refreshes.
