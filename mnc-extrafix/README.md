# mnc-extrafix

Standalone FiveM resource (no framework dependency) that automatically fixes
and repairs trailers/vehicles when one of their extras is toggled.

## Why

Certain trailer models get visually deformed/glitched when an extra is
toggled — the bug only shows up on clients other than the one who toggled
it. This resource detects the extra change locally on every client and
applies a full fix + repair, syncing the fix across all clients via the
server.

## How it works

1. Each client polls nearby vehicles (`GetGamePool('CVehicle')`) every
   `Config.PollInterval` ms, filtered to the models in `Config.TrackedModels`.
2. For each tracked vehicle, it records a signature of every extra's on/off
   state. If the signature changes since the last poll, that vehicle just had
   an extra toggled.
3. The detecting client immediately fixes its own copy (`SetVehicleFixed`,
   `SetVehicleDeformationFixed`, full health/dirt repair), then tells the
   server.
4. The server broadcasts to all clients, so everyone's locally streamed copy
   of that same vehicle (matched by network ID) also gets fixed — not just
   the player who toggled the extra.
5. A per-vehicle cooldown (`Config.FixCooldown`) prevents repeated fixes if
   extras are toggled rapidly.

## Files

```
mnc-extrafix/
├── fxmanifest.lua
├── config.lua
├── client/
│   └── main.lua
└── server/
    └── main.lua
```

## Configuration

Edit `config.lua`:

- `Config.Debug` — print fix events to console.
- `Config.PollInterval` — how often (ms) each client scans vehicles.
- `Config.FixCooldown` — minimum time (ms) between fixes on the same vehicle.
- `Config.MaxExtraIndex` — highest extra index to check (14 covers all
  standard GTA extras).
- `Config.TrackedModels` — list of vehicle model names to watch. Add or
  remove freely.

## Commands

- `/extrafix` — manually fixes the nearest tracked vehicle within 10 meters
  (useful for testing).

## Installation

1. Drop the `mnc-extrafix` folder into your server's `resources` directory.
2. Add `ensure mnc-extrafix` to your `server.cfg`.
3. Restart the resource or restart your server.

No database, no UI library, and no framework (QBCore/ESX/etc.) required.
