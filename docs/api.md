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

### Errors and Exceptions
