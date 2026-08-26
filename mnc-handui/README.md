# mnc-handui

Admin-only, model-based vehicle handling editor for QBCore. Lets admins tune a
vehicle's speed/accel/brakes/traction/suspension/damage live in-game and saves
the result to SQL — no `.meta` file edits, no server restart. Because the
change is stored per **model**, it instantly applies to every vehicle of that
model on the server (existing spawns and all future ones).

## Requirements

- qb-core
- oxmysql
- ox_lib

## Install

1. Drop this folder into your resources as `mnc-handui`.
2. Run `sql/install.sql` against your database (also auto-checked on start,
   but run it manually if your oxmysql user can't `CREATE TABLE`).
3. Add to `server.cfg`, after qb-core/oxmysql/ox_lib:
   ```
   ensure mnc-handui
   ```
4. (Optional) Add an ace permission if you don't already grant `admin` via
   QBCore groups:
   ```
   add_ace group.admin command.handui allow
   ```

## Config

All in `config.lua`:

- `Config.Command` — command to open the editor (default `handui`, so `/handui`)
- `Config.AdminPermission` — permission level checked via `QBCore.Functions.HasPermission`
- `Config.PreviewHeightOffset` — how far above the admin (in metres) ghost
  preview vehicles spawn while reading default handling values. Spawns
  relative to the admin rather than a fixed coordinate, since `CreateVehicle`
  needs collision actually streamed in at the target point to place a
  non-networked entity there.
- `Config.HandlingFields` — the tunable fields, grouped into tabs. Add/remove
  entries here to change what shows up in the UI — `key` must match a real
  `handling.meta` field name and `type` must be `'float'` or `'int'`.

## How it works

- **Editor tab**: search any vehicle (or hop in one and hit "Use My
  Vehicle"), tune sliders across 5 categories (Engine & Power, Braking,
  Traction & Steering, Suspension, Mass & Damage), optionally spawn a
  drivable test vehicle to feel changes live, then Save.
- **Saved Overrides tab**: lists every model with a custom override, who
  last edited it and when. "Edit" reopens it in the editor, "Revert" deletes
  the override and snaps every currently-spawned vehicle of that model back
  to its true default handling.
- The first time a model is saved, the editor captures its vanilla
  `handling.meta` baseline and stores it alongside your changes — that's
  what "Revert" restores you to, even after multiple rounds of edits.
- Overrides are cached server-side and pushed to clients on join/resource
  start; any vehicle of an overridden model gets the saved handling applied
  the moment it streams in (`entityCreated`), no per-vehicle setup needed.

## Notes

- Server-side validation whitelists every handling field against
  `Config.HandlingFields` and clamps to its configured min/max — NUI input is
  never trusted directly.
- **Addon vehicles are fully supported**, not just ones registered in
  `qb-core/shared/vehicles.lua`. "Use My Vehicle" reads the model straight
  off the entity you're sitting in (`GetEntityArchetypeName`, with an
  automatic fallback to the shared-vehicle table on older server builds), and
  saving no longer requires the model to exist in the shop catalog. If an
  addon vehicle doesn't show up in the search dropdown (there's no generic
  way to enumerate every streamed addon on the server), just type its exact
  spawn code and press Enter.
- **Spawning a test vehicle applies whatever is currently on your sliders**,
  including edits you haven't saved yet — not just whatever was last
  persisted to the database — and warps you straight into the driver's seat
  (`Config.AutoEnterTestVehicle`).
- Game input (WASD/controller) keeps working while the editor panel is open
  (`SetNuiFocusKeepInput`), so you can actually drive and feel a test vehicle
  without closing the UI first. The trade-off: keystrokes go to both the
  panel and the game at once, so typing in the search box while sitting in a
  moving vehicle will also move the vehicle — type while stationary.
- Uses `ox_lib`'s `lib.notify` for all feedback toasts.
