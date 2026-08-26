local QBCore = exports['qb-core']:GetCoreObject()

---------------------------------------------------------------------------
-- Config
---------------------------------------------------------------------------

local LOWRIDER_MODELS = {
    ['primo2']    = true, ['buccaneer2'] = true, ['chino2']    = true,
    ['faction2']  = true, ['faction3']   = true, ['lowrider']  = true,
    ['moonbeam2'] = true, ['peyote2']    = true, ['picador']   = true,
    ['slamvan3']  = true, ['slamvan4']   = true, ['slamvan5']  = true,
    ['slamvan6']  = true, ['virgo2']     = true, ['virgo3']    = true,
    ['voodoo']    = true, ['voodoo2']    = true, ['tornado']   = true,
    ['tornado2']  = true, ['tornado3']   = true, ['tornado4']  = true,
    ['tornado5']  = true, ['tornado6']   = true, ['sabre2']    = true,
    ['minivan2']  = true, ['rhapsody']   = true, ['chino']     = true,
    ['faction']   = true, ['buccaneer']  = true, ['primo']     = true,
    ['moonbeam']  = true, ['peyote']     = true, ['slamvan']   = true,
    ['slamvan2']  = true, ['virgo']      = true,
}


local CTRL_HYDRO_LEFT   = 174 -- INPUT_CELLPHONE_LEFT   (←)   bounce/tilt left
local CTRL_HYDRO_RIGHT  = 175 -- INPUT_CELLPHONE_RIGHT  (→)   bounce/tilt right
local CTRL_HYDRO_FRONT  = 172 -- INPUT_CELLPHONE_UP     (↑)   bounce front
local CTRL_HYDRO_REAR   = 173 -- INPUT_CELLPHONE_DOWN   (↓)   bounce rear

-- 3-wheel macro: the hydraulics natives (337-341) turned out NOT to be
-- able to isolate a single wheel on their own — /hydrotest swept all four
-- corner combos and only front+right ever actually lifted a wheel; the
-- other three just tilt the whole car with nothing coming off the ground.
-- Not enough to build two distinct presets out of, so the presets don't
-- touch those natives for the pose anymore.
--
-- First replacement attempt was a single ApplyForceToEntity push straight
-- up at the target wheel. That has a real physics bug: a single one-sided
-- force has BOTH a rotational (torque, the tilt we want) component AND a
-- linear (net upward, the whole car) component — there's no way to push
-- up at one point without also just shoving the entire body up some. At
-- force 20 that linear component alone was more than double what's needed
-- to lift the car's ENTIRE weight, so it mostly just floated skyward.
-- Backing the number off (3.0) and capping vertical velocity reduced it
-- but didn't fix it — a sustained force below the velocity cap still
-- accumulates height over several seconds (capped *speed* isn't capped
-- *position*), so the car kept slowly floating regardless of magnitude.
--
-- The actual fix is to cancel the linear component instead of shrinking
-- it: apply the lift force at the target wheel AND an equal, opposite
-- (downward) force at the DIAGONALLY OPPOSITE wheel at the same time —
-- see ApplyWheelTiltForce below. Two equal-and-opposite forces applied at
-- different points is a force couple: their net linear force is exactly
-- zero (so no float, regardless of magnitude or how long it's held) and
-- only the torque survives, which is exactly the tilt/lift look we want.
-- This also happens to be the same corner pairing the real technique
-- describes — "dip the rear corner you're turning away from" while the
-- opposite front corner lifts — so front-right up pairs with rear-left
-- down, and front-left up pairs with rear-right down.
--
-- This is a general system, not just two hardcoded presets: WHEEL_BONES /
-- DIAGONAL_OPPOSITE / ApplyWheelTiltForce below work for any of the 4
-- corners, and /hydrotilt (see near the bottom, alongside /hydrotest) lets
-- you test-lift any single corner on demand to check it in isolation
-- before trusting it inside a preset.
--
-- The magnitude is still a first guess — a couple can't run away into a
-- float the way a single force could, but it can still be too weak (no
-- visible tilt) or too strong (violent/unstable spin). Report back what
-- you see. MACRO_LIFT_MAX_VERTICAL_VEL is kept on as a second safety net
-- regardless (bounds any residual float from imperfect cancellation).
local MACRO_BUILD_MS     = 1200 -- phase 1: hold TOGGLE-only bounce to lock the car up high
local MACRO_LIFT_RAMP_MS = 600  -- phase 2: how long to ramp the tilt force from 0 up to full
local WHEEL_LIFT_FORCE    = 6.0 -- phase 2: full-strength force (world-space Z, mass-scaled) at each end of the couple — see ApplyWheelTiltForce
local MACRO_LIFT_MAX_VERTICAL_VEL = 1.5 -- phase 2: hard cap (m/s) on the car's upward vertical velocity, as a second safety net

-- How far (meters) the player has to physically walk away from a
-- hydraulics vehicle after getting out of it before the script actually
-- lets go. Below this distance the vehicle keeps being treated exactly
-- like the player is still sitting in it — a held 3-wheel pose (or plain
-- raised hydraulics) keeps being asserted every frame against the last
-- vehicle the player drove, so hopping out to look at it doesn't
-- instantly drop the pose. See StartHydroLoop and hydroVeh below.
local HYDRO_EXIT_DISTANCE = 25.0

-- GTA's own hydraulics controls (337-341, see NATIVE_TOGGLE etc. below)
-- turned out to require the REAL PLAYER to be seated to have any effect
-- at all — confirmed by testing, including with an invisible decoy ped
-- warped into the driver seat while the player stood outside, which
-- didn't help. So those natives are only used below while actually
-- seated in hydroVeh. While outside, front/rear/left/right bounce is
-- replicated with the same kind of force couple the 3-wheel presets
-- already use (see AXIS_COUPLES / ApplyAxisBounce below) — that's the
-- one mechanism confirmed to work regardless of who, if anyone, is in
-- the vehicle.
local AXIS_BOUNCE_FORCE = 6.0 -- PEAK force (world-space Z, mass-scaled) at each end of an axis
                               -- couple, reached mid-pulse — see ApplyAxisBounce, which
                               -- modulates this over BOUNCE_CYCLE_MS rather than holding it
                               -- constant. Independent of WHEEL_LIFT_FORCE so the two can be
                               -- tuned to feel different.
local BOUNCE_CYCLE_MS   = 350  -- outside-vehicle axis bounce: length of one full pulse (rise
                               -- then settle) while a direction is held — see ApplyAxisBounce.
                               -- A real hydraulics bounce isn't a steady lean, it's a rhythmic
                               -- series of hops; this is what turns the held force couple into
                               -- that same repeating up/settle rhythm instead of a static tilt.

-- Which two wheels get pushed up and which two get pushed down for each
-- directional bounce/tilt, replicating what the native FRONT/REAR/LEFT/
-- RIGHT hydraulics controls do — nose up for 'front', tail up for
-- 'rear', driver's side up for 'left', passenger's side up for 'right'.
-- Same force-couple principle as ApplyWheelTiltForce (equal and opposite
-- pushes so net linear force is zero and only the torque/lean survives)
-- just spread across two wheels on each side instead of one wheel vs.
-- its diagonal opposite. See ApplyAxisBounce.
local AXIS_COUPLES = {
    front = { up = { 'fl', 'fr' }, down = { 'rl', 'rr' } },
    rear  = { up = { 'rl', 'rr' }, down = { 'fl', 'fr' } },
    left  = { up = { 'fl', 'rl' }, down = { 'fr', 'rr' } },
    right = { up = { 'fr', 'rr' }, down = { 'fl', 'rl' } },
}

-- Standard GTA vehicle wheel bone names, keyed by corner.
local WHEEL_BONES = {
    fl = 'wheel_lf', -- front-left
    fr = 'wheel_rf', -- front-right
    rl = 'wheel_lr', -- rear-left
    rr = 'wheel_rr', -- rear-right
}

-- Diagonally opposite corner for each corner — the one that gets pushed
-- DOWN to cancel the lift corner's push UP (see the big comment above).
local DIAGONAL_OPPOSITE = {
    fl = 'rr',
    fr = 'rl',
    rl = 'fr',
    rr = 'fl',
}

-- Which corner lifts for each preset side. front-right for Numpad3
-- (turning right), front-left for Numpad1 (turning left) — see
-- ApplyWheelTiltForce for what happens at the other end of the couple.
local MACRO_LIFT_CORNER = {
    right = 'fr',
    left  = 'fl',
}

-- Debug logging. Toggle at runtime with /hydrodebugtoggle instead of
-- editing this if it gets too spammy — every line is prefixed [hydroui]
-- so it's easy to filter in the F8 console.
local DEBUG_HYDROUI = true

local function Dbg(fmt, ...)
    if not DEBUG_HYDROUI then return end
    print(('[hydroui] ' .. fmt):format(...))
end

local oHeld = false

RegisterCommand('+hydroui_toggle', function() oHeld = true  end, false)
RegisterCommand('-hydroui_toggle', function() oHeld = false end, false)
RegisterKeyMapping('+hydroui_toggle', 'Hydraulics UI - Toggle / Engage', 'keyboard', 'o')

-- N: toggle UI visibility. Bound as a proper +/- hold pair (like O above)
-- rather than a bare RegisterCommand, so a single physical press always
-- reads as exactly one rising edge in the polled thread below — a bare
-- command fired straight from RegisterKeyMapping is vulnerable to OS key
-- repeat re-firing it several times while the key is held, which is what
-- made "N" toggle visibility on/off an unpredictable number of times per
-- press instead of reliably hiding the UI.
local nHeld = false

RegisterCommand('+hydroui_n', function() nHeld = true  end, false)
RegisterCommand('-hydroui_n', function() nHeld = false end, false)
RegisterKeyMapping('+hydroui_n', 'Hydraulics UI - Toggle Visible', 'keyboard', 'n')

-- 3-wheel presets: Numpad3 runs the trick turning right (lifts the
-- front-right wheel), Numpad1 runs it turning left (lifts the front-left
-- wheel) — see MACRO_LIFT_CORNER and the big comment above it for why
-- this is done with a physics force couple instead of a hydraulics native
-- combo. Each press (re)starts the sequence: phase 1 locks the car up
-- high (same as O), phase 2 ramps in the tilt force and then holds it indefinitely
-- (it doesn't self-release — a real 3-wheel only stays up as long as
-- something keeps leaning it that way) until you press an arrow key
-- yourself to take manual control, or O to drop it.
local preset3Held = false -- raw Numpad3 key state (3-wheel turning right)
local preset1Held = false -- raw Numpad1 key state (3-wheel turning left)

RegisterCommand('+hydro3wheel_right', function() preset3Held = true  end, false)
RegisterCommand('-hydro3wheel_right', function() preset3Held = false end, false)
RegisterKeyMapping('+hydro3wheel_right', 'Hydraulics UI - 3-Wheel (Turning Right)', 'keyboard', 'numpad3')

RegisterCommand('+hydro3wheel_left', function() preset1Held = true  end, false)
RegisterCommand('-hydro3wheel_left', function() preset1Held = false end, false)
RegisterKeyMapping('+hydro3wheel_left', 'Hydraulics UI - 3-Wheel (Turning Left)', 'keyboard', 'numpad1')

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local uiOpen      = false
local uiVisible   = true
local inHydroVeh  = false
local hydroThread = nil
local hydroVeh    = nil     -- vehicle handle StartHydroLoop has latched onto; stays set for up
                             -- to HYDRO_EXIT_DISTANCE meters after the player is no longer
                             -- seated in it, so hydraulics can keep being controlled remotely
                             -- (see the hydroRaised block in StartInputThread) even after they
                             -- step out — see StartHydroLoop. nil whenever inHydroVeh is false.
local hydroRaised = false   -- latched: true while hydraulics are engaged (car up)
local hydroActive = false   -- mirrors hydroRaised (kept for debug / external use)
local oWasHeld    = false   -- previous-frame oHeld for rising-edge detection
local nWasHeld    = false   -- previous-frame nHeld for rising-edge detection

local preset3WasHeld = false -- previous-frame preset3Held for rising-edge detection
local preset1WasHeld = false -- previous-frame preset1Held for rising-edge detection

local macroActive     = false -- true while the scripted 3-wheel sequence is running
local macroSide       = nil   -- 'right' | 'left' — which preset started it
local macroPhase      = 0     -- 0 = inactive, 1 = lock high, 2 = ramp in + hold the corner lift force
local macroPhaseEndAt = 0     -- GetGameTimer() timestamp phase 1 ends at (phase 2 has no end timer)
local macroLiftStartAt = 0    -- GetGameTimer() timestamp phase 2 began at, for the force ramp

local testHeld = nil -- /hydrotest override: nil, or {front=,rear=,left=,right=} held indefinitely

local tiltHeld      = nil -- /hydrotilt override: nil, or a corner key ('fl'/'fr'/'rl'/'rr') to force-tilt indefinitely
local tiltStartAt   = 0   -- GetGameTimer() timestamp /hydrotilt started at, for its own force ramp

-- Last-frame snapshot of the natives actually sent (post axle/corner-mode
-- resolution), kept at file scope purely so /hydrodebug can report them on
-- demand — the locals they're copied from only exist inside
-- StartInputThread's loop.
local lastFrontHeld, lastRearHeld, lastLeftHeld, lastRightHeld = false, false, false, false

local nuiReady     = false  -- true once the NUI page confirms it has loaded and is
                             -- listening for messages (see RegisterNUICallback('ready', ...))

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function GetVehicleModelName(veh)
    return string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
end

local function IsLowriderByModel(veh)
    return LOWRIDER_MODELS[GetVehicleModelName(veh)] == true
end

local function IsLowriderByMod(veh)
    -- Mod type 21 is VMT_HYDRAULICS. This used to check type 18, which is
    -- actually VMT_TURBO — a leftover bug from before I touched this file.
    -- It never blocked whitelisted models like primo2 (HasHydraulics below
    -- short-circuits on the model check first), but it made this function
    -- meaningless for any non-whitelisted vehicle relying on it.
    return IsToggleModOn(veh, 21)
end

local function HasHydraulics(veh)
    return IsLowriderByModel(veh) or IsLowriderByMod(veh)
end

local function SendNUI(action, data)
    local payload = data or {}
    payload.action = action
    SendNUIMessage(payload)
end

-- Looks up a wheel bone's current world position and converts it to a
-- vehicle-local offset. Done every frame (not cached) since the wheel
-- moves slightly with suspension travel, keeping any force applied at it
-- pinned to the actual wheel instead of a fixed guessed offset. Returns
-- nil if the bone doesn't exist on this vehicle.
local function GetWheelLocalOffset(veh, boneName)
    local boneIdx = GetEntityBoneIndexByName(veh, boneName)
    if boneIdx == -1 or boneIdx == nil then return nil end

    local worldPos = GetWorldPositionOfEntityBone(veh, boneIdx)
    return GetOffsetFromEntityGivenWorldCoords(veh, worldPos.x, worldPos.y, worldPos.z)
end

local function ApplyForceAtOffset(veh, offset, forceMag)
    ApplyForceToEntity(
        veh, 0,                              -- APPLY_TYPE_FORCE
        0.0, 0.0, forceMag,                  -- world-space Z (straight up if positive, down if negative)
        offset.x, offset.y, offset.z,        -- applied at this vehicle-local position
        0,                                    -- component: whole body
        false,                                -- bLocalForce: false -> x/y/z above is world-space
        true,                                 -- bLocalOffset: true -> offset above is vehicle-local
        true,                                 -- bScaleByMass
        false,                                -- bPlayAudio
        true                                  -- bScaleByTimeWarp
    )
end

-- General form of the force-couple trick: push UP at every corner in
-- `upCorners` and DOWN by the same amount at every corner in
-- `downCorners` (WHEEL_BONES keys). As long as the two lists balance
-- (same wheelbase geometry on each side), net linear force is ~0 and
-- only the torque — the lean/tilt — comes through, same reasoning as
-- the big comment near the top of the file. ApplyWheelTiltForce (single
-- corner vs. its diagonal opposite, for the 3-wheel presets) and
-- ApplyAxisBounce (two wheels vs. the other two, for front/rear/left/
-- right) are both just this with different corner lists.
local function ApplyCoupleForce(veh, upCorners, downCorners, forceMag)
    for _, corner in ipairs(upCorners) do
        local offset = GetWheelLocalOffset(veh, WHEEL_BONES[corner])
        if offset then ApplyForceAtOffset(veh, offset, forceMag) end
    end
    for _, corner in ipairs(downCorners) do
        local offset = GetWheelLocalOffset(veh, WHEEL_BONES[corner])
        if offset then ApplyForceAtOffset(veh, offset, -forceMag) end
    end
end

-- Tilts the car so `corner` (a WHEEL_BONES key: 'fl'/'fr'/'rl'/'rr') lifts,
-- by applying a translation-cancelling force couple: push UP at that
-- corner's wheel and DOWN by the exact same amount at the diagonally
-- opposite wheel (see DIAGONAL_OPPOSITE and the big comment near the top
-- of the file for why — this is what actually stops the whole car from
-- floating, unlike a single one-sided push). Net linear force is ~0;
-- only the torque (the tilt) comes through.
local function ApplyWheelTiltForce(veh, corner, forceMag)
    local downCorner = DIAGONAL_OPPOSITE[corner]
    if not WHEEL_BONES[corner] or not downCorner then return end
    ApplyCoupleForce(veh, { corner }, { downCorner }, forceMag)
end

-- Safety-net clamp shared by every force-based hydraulics effect: bounds
-- how fast the car can be rising, in case an imperfect couple (uneven
-- wheelbase, a missing bone, whatever) leaves a little residual lift
-- instead of exactly cancelling.
local function ClampVerticalVelocity(veh)
    local vel = GetEntityVelocity(veh)
    if vel.z > MACRO_LIFT_MAX_VERTICAL_VEL then
        SetEntityVelocity(veh, vel.x, vel.y, MACRO_LIFT_MAX_VERTICAL_VEL)
    end
end

-- Shared by the macro's phase 2 and /hydrotilt: ramps the tilt force at
-- `corner` from 0 up to WHEEL_LIFT_FORCE over MACRO_LIFT_RAMP_MS (instead
-- of slamming to full strength instantly) and applies the vertical
-- velocity safety clamp every frame it's held.
local function ApplyRampedWheelTilt(veh, corner, startAt)
    local elapsed  = GetGameTimer() - startAt
    local rampFrac = math.min(elapsed / MACRO_LIFT_RAMP_MS, 1.0)
    ApplyWheelTiltForce(veh, corner, WHEEL_LIFT_FORCE * rampFrac)
    ClampVerticalVelocity(veh)
end

-- Replicates the native FRONT/REAR/LEFT/RIGHT hydraulics bounce/tilt
-- (see AXIS_COUPLES) using the same force-couple mechanism as the
-- 3-wheel presets, instead of SetControlNormal on the hydraulics
-- natives — those turned out to require the real player to be seated to
-- have any effect at all, so they're no substitute once the player is
-- outside the vehicle (see the big comment on AXIS_BOUNCE_FORCE near the
-- top of the file).
--
-- A CONSTANT held force couple just tilts the car and leaves it there —
-- looks like a static lean, not a bounce. Real hydraulics bounce is a
-- rhythmic series of hops: the corner springs up, gravity brings it back
-- down, it springs up again, for as long as the direction is held. To
-- get that instead of a frozen tilt, the force magnitude is modulated
-- every frame by a smooth 0 -> peak -> 0 pulse (half a sine wave) that
-- repeats every BOUNCE_CYCLE_MS: applying sin(phase * pi) for phase 0..1
-- traces exactly one hump per cycle with no snap at the seam between
-- cycles. Runs on the shared game clock rather than a per-press start
-- time, so front/rear/left/right (and combinations of them) all pulse
-- in sync with each other.
local function ApplyAxisBounce(veh, axisKey)
    local axis = AXIS_COUPLES[axisKey]
    if not axis then return end

    local phase = (GetGameTimer() % BOUNCE_CYCLE_MS) / BOUNCE_CYCLE_MS -- 0..1 across one cycle
    local pulse = math.sin(phase * math.pi)                            -- 0 -> 1 -> 0 across it

    ApplyCoupleForce(veh, axis.up, axis.down, AXIS_BOUNCE_FORCE * pulse)
    ClampVerticalVelocity(veh)
end

-- Disengages hydraulics (and cancels any macro/pose in progress) WITHOUT
-- touching the car's actual position/rotation/velocity. This just stops
-- us from actively asserting the TOGGLE control and the tilt force every
-- frame — the car settles from wherever it physically is the moment
-- control stops, instead of being snapped back to level. Used for every
-- O press that drops hydraulics, whether that's plain manual-mode or a
-- 3-wheel pose in progress (see StartInputThread) — 3-wheel is a static
-- pose only, so O always just drops it rather than handing back driving.
local function StopHydroInPlace()
    hydroRaised = false
    hydroActive = false
    macroActive = false
    macroPhase  = 0
end


---------------------------------------------------------------------------
-- Hydraulics control injection
---------------------------------------------------------------------------

-- These are GTA5's OWN native hydraulics controls (by default: X to toggle,
-- A/D to tilt left/right, Shift/Ctrl to bounce front/rear — your client may
-- have these rebound, e.g. to the numpad). SetControlNormal on these IDs is
-- what actually drives the vehicle's real hydraulics — that part is proven
-- to work (it's how O engaging hydraulics has worked all along).
--
-- NOTE: an earlier version of this file also called DisableControlAction on
-- these IDs every frame, intending to block the game's own default key
-- (A/D, numpad, etc.) from also driving them. That broke real engagement
-- entirely — Disable+SetControlNormal does not compose cleanly for this
-- particular native subsystem, so it's been removed. Instead, below we
-- unconditionally assert 1.0 *or* 0.0 every frame for the direction
-- controls (rather than only ever asserting 1.0 and otherwise leaving the
-- control to whatever the raw key state was), which is the same native
-- call in the same place as the version that was proven to work.
local NATIVE_TOGGLE = 337 -- INPUT_VEH_HYDRAULICS_CONTROL_TOGGLE (default X)
local NATIVE_LEFT   = 338 -- INPUT_VEH_HYDRAULICS_CONTROL_LEFT   (default A)
local NATIVE_RIGHT  = 339 -- INPUT_VEH_HYDRAULICS_CONTROL_RIGHT  (default D)
local NATIVE_FRONT  = 340 -- INPUT_VEH_HYDRAULICS_CONTROL_UP     (default Left Shift)
local NATIVE_REAR   = 341 -- INPUT_VEH_HYDRAULICS_CONTROL_DOWN   (default Left Ctrl)

-- Ordinary driving controls. These are disabled every frame while hydraulics
-- are engaged (hydroRaised) so the car can't be driven at the same time.
-- They're separate control IDs from both the hydraulics natives above
-- (337-341) and our custom bounce keys (172-175), so DisableControlAction
-- here doesn't touch the hydraulics input handling at all.
--
-- NOTE: 59/60 (MOVE_LR / MOVE_UD) are the composite/analog steering axes —
-- that's what a controller stick drives, and what GetControlNormal() reads
-- as a smoothed float. On keyboard, A and D don't feed 59 directly: they
-- each drive their OWN discrete digital control (63 / 64) which the game
-- converts into steering internally, independent of 59. Disabling only 59
-- blocks the analog/composite reads but does NOT stop a keyboard A/D press
-- from steering — that's why cars could still be turned with A/D while
-- hydraulics were raised even though 59 was disabled every frame. 63/64
-- must be disabled too to actually block the keys themselves.
local NATIVE_DRIVE_ACCEL       = 71 -- INPUT_VEH_ACCELERATE
local NATIVE_DRIVE_BRAKE       = 72 -- INPUT_VEH_BRAKE / reverse
local NATIVE_DRIVE_STEER_LR    = 59 -- INPUT_VEH_MOVE_LEFT_RIGHT (composite/analog steer)
local NATIVE_DRIVE_STEER_UD    = 60 -- INPUT_VEH_MOVE_UP_DOWN    (composite/analog, unused for cars but harmless to block)
local NATIVE_DRIVE_STEER_LEFT  = 63 -- INPUT_VEH_MOVE_LEFT_ONLY  (keyboard A, discrete)
local NATIVE_DRIVE_STEER_RIGHT = 64 -- INPUT_VEH_MOVE_RIGHT_ONLY (keyboard D, discrete)

---------------------------------------------------------------------------
-- Input + hydraulics drive thread
---------------------------------------------------------------------------

local function StartInputThread()
    CreateThread(function()
        local lastSig = nil -- change-detection so we don't flood the NUI message queue
        oWasHeld = false
        nWasHeld = false

        while uiOpen do
            Wait(0)  -- every frame so quick taps aren't missed

            -- N: rising-edge toggles UI visibility ONLY — purely cosmetic,
            -- doesn't touch hydraulics, the macro, free-drive, or any pose
            -- in progress at all. Checked every frame regardless of
            -- uiVisible so it also fires the show-again edge while hidden.
            if nHeld and not nWasHeld then
                if uiVisible then
                    Dbg('N pressed: hiding UI')
                    HideUI()
                else
                    Dbg('N pressed: showing UI')
                    ShowUI()
                end
            end
            nWasHeld = nHeld

            -- ── Read our custom keys ──
            -- Arrows read via IsControlPressed on INPUT_CELLPHONE_* IDs.
            local upHeld   = IsControlPressed(0, CTRL_HYDRO_FRONT)
            local downHeld = IsControlPressed(0, CTRL_HYDRO_REAR)
            local leftRaw  = IsControlPressed(0, CTRL_HYDRO_LEFT)
            local rightRaw = IsControlPressed(0, CTRL_HYDRO_RIGHT)

            -- Rising edge of O. 3-wheel is a static pose only — the car
            -- can be looked at and held up, but never driven while it's
            -- up on 3 wheels, so O never unblocks steering/gas/brake.
            -- Whether a preset is mid-build, holding, or hydraulics were
            -- just raised manually, O always does the same thing: turn
            -- axle control on if it's off, or stop it exactly where the
            -- car is (via StopHydroInPlace) if it's already on. Doesn't
            -- touch UI visibility — that's N's job, entirely separate.
            if oHeld and not oWasHeld then
                if hydroRaised then
                    StopHydroInPlace()
                    Dbg('O pressed: hydraulics stopped in place')
                else
                    hydroRaised = true
                    Dbg('O pressed: hydroRaised -> true')
                end
            end
            oWasHeld = oHeld

            -- Numpad3 / Numpad1: rising edge (re)starts the 3-wheel
            -- macro for that side and engages hydraulics automatically
            -- if it isn't already on. Pressing either one again (even
            -- mid-sequence) restarts from phase 1 — handy for retrying
            -- if the timing didn't land right.
            if preset3Held and not preset3WasHeld then
                hydroRaised     = true
                macroActive     = true
                macroSide       = 'right'
                macroPhase      = 1
                macroPhaseEndAt = GetGameTimer() + MACRO_BUILD_MS
                tiltHeld        = nil -- a preset press always takes over cleanly from /hydrotilt
                Dbg('Numpad3 pressed: 3-wheel (right) started, phase 1 (lock high)')
            end
            preset3WasHeld = preset3Held

            if preset1Held and not preset1WasHeld then
                hydroRaised     = true
                macroActive     = true
                macroSide       = 'left'
                macroPhase      = 1
                macroPhaseEndAt = GetGameTimer() + MACRO_BUILD_MS
                tiltHeld        = nil -- a preset press always takes over cleanly from /hydrotilt
                Dbg('Numpad1 pressed: 3-wheel (left) started, phase 1 (lock high)')
            end
            preset1WasHeld = preset1Held

            hydroActive = hydroRaised

            local frontHeld, rearHeld, leftHeld, rightHeld
            if testHeld then
                -- /hydrotest override: hold one fixed raw combo
                -- indefinitely so you can look at it for as long as
                -- you want, instead of a scripted sequence blowing
                -- past it in 400ms. See the command below.
                frontHeld = testHeld.front or false
                rearHeld  = testHeld.rear  or false
                leftHeld  = testHeld.left  or false
                rightHeld = testHeld.right or false
            elseif macroActive then
                -- Phase 1 -> phase 2 on elapsed time. Phase 2 has no
                -- end timer — it ramps the lift force in and then
                -- keeps applying it every frame indefinitely, because
                -- a real 3-wheel pose only stays up as long as
                -- something keeps leaning it that way; it doesn't hold
                -- itself once you let go.
                local now = GetGameTimer()
                if macroPhase == 1 and now >= macroPhaseEndAt then
                    macroPhase      = 2
                    macroLiftStartAt = now
                    Dbg('3-wheel (%s): phase 2 (lifting corner %s — press an arrow for manual control, O to drop it)',
                        macroSide, MACRO_LIFT_CORNER[macroSide])
                end

                -- Phase 2: any arrow press hands control back to you
                -- from wherever the pose currently is, so you can make
                -- your own corrections instead of the script holding
                -- it forever.
                if macroPhase == 2 and (upHeld or downHeld or leftRaw or rightRaw) then
                    macroActive = false
                    macroPhase  = 0
                    Dbg('arrow pressed: 3-wheel (%s) hold released to manual control', macroSide)
                end
            end

            if testHeld then
                -- Already set above — /hydrotest wins over everything.
            elseif macroActive then
                -- Neither macro phase asserts the hydraulics axis
                -- natives at all anymore — the pose comes from the
                -- ApplyWheelTiltForce call below instead (see the big
                -- comment on MACRO_LIFT_CORNER near the top for
                -- why). Phase 1 is just plain TOGGLE-only engagement
                -- (confirmed to visibly raise the car on its own);
                -- phase 2 keeps that and layers the corner force on
                -- top, so there's nothing extra to set here either way.
                frontHeld, rearHeld, leftHeld, rightHeld = false, false, false, false
            else
                frontHeld, rearHeld, leftHeld, rightHeld = upHeld, downHeld, leftRaw, rightRaw
            end

            if hydroRaised and hydroVeh and DoesEntityExist(hydroVeh) then
                local seatedInHydroVeh = GetPedInVehicleSeat(hydroVeh, -1) == PlayerPedId()

                if seatedInHydroVeh then
                    -- Driving it: use GTA's own hydraulics natives, same
                    -- as always — this half is proven, unchanged from
                    -- before any of the remote-control work.
                    SetControlNormal(0, NATIVE_TOGGLE, 1.0)

                    -- Assert both the "on" and "off" value every frame
                    -- (instead of only ever asserting 1.0 and otherwise
                    -- leaving the control alone) so our arrow keys are
                    -- the sole source of truth for tilt while hydraulics
                    -- are engaged, overriding whatever the raw
                    -- A/D/Shift/Ctrl (or numpad) state would otherwise
                    -- feed in.
                    SetControlNormal(0, NATIVE_FRONT, frontHeld and 1.0 or 0.0)
                    SetControlNormal(0, NATIVE_REAR,  rearHeld  and 1.0 or 0.0)
                    SetControlNormal(0, NATIVE_LEFT,  leftHeld  and 1.0 or 0.0)
                    SetControlNormal(0, NATIVE_RIGHT, rightHeld and 1.0 or 0.0)
                else
                    -- Outside the vehicle: NATIVE_TOGGLE/FRONT/REAR/LEFT/
                    -- RIGHT are confirmed dead weight here — GTA only
                    -- processes them for a seated driver (tried an
                    -- invisible decoy driver to route around that; didn't
                    -- help, so dropped). Replicate the bounce/tilt
                    -- directly with the same force-couple mechanism the
                    -- 3-wheel presets already use successfully from
                    -- outside — see ApplyAxisBounce / AXIS_COUPLES.
                    -- There's no equivalent for a bare NATIVE_TOGGLE
                    -- "just raise it" with nothing held: that's a
                    -- one-sided lift with no opposing wheel to cancel it
                    -- against, which is exactly the float bug the big
                    -- comment near the top of the file already ruled
                    -- out — so from outside, hydraulics only visibly do
                    -- something while you're actively holding a
                    -- direction (or running the 3-wheel preset below).
                    if frontHeld then ApplyAxisBounce(hydroVeh, 'front') end
                    if rearHeld  then ApplyAxisBounce(hydroVeh, 'rear')  end
                    if leftHeld  then ApplyAxisBounce(hydroVeh, 'left')  end
                    if rightHeld then ApplyAxisBounce(hydroVeh, 'right') end
                end

                -- 3-wheel preset, phase 2: keep applying the tilt
                -- force couple every frame (see ApplyWheelTiltForce /
                -- ApplyRampedWheelTilt above and the big comment near
                -- the top of the file for why it's a couple and not a
                -- single push). /hydrotilt takes priority when it's
                -- active, same relationship testHeld has with the macro
                -- elsewhere in this file. This part never needed a
                -- driver at all — ApplyForceToEntity is entity-direct
                -- and always affects hydroVeh regardless of occupancy,
                -- which is why this is the one mode that already worked
                -- from outside.
                if macroActive and macroPhase == 2 and not testHeld and not tiltHeld then
                    local corner = MACRO_LIFT_CORNER[macroSide]
                    if corner then
                        ApplyRampedWheelTilt(hydroVeh, corner, macroLiftStartAt)
                    end
                elseif tiltHeld then
                    ApplyRampedWheelTilt(hydroVeh, tiltHeld, tiltStartAt)
                end

                -- No driving while hydraulics are engaged — but ONLY for
                -- the vehicle the player is actually sitting in. Since
                -- hydroRaised can stay true while the player is clear
                -- across the 25m radius, blocking these every frame
                -- regardless of seat would also lock the player out of
                -- driving any OTHER vehicle they get into in the
                -- meantime. DisableControlAction is safe on these IDs —
                -- they're plain driving controls, not the hydraulics
                -- subsystem the big comment near NATIVE_TOGGLE warns
                -- about.
                if seatedInHydroVeh then
                    DisableControlAction(0, NATIVE_DRIVE_ACCEL, true)
                    DisableControlAction(0, NATIVE_DRIVE_BRAKE, true)
                    DisableControlAction(0, NATIVE_DRIVE_STEER_LR, true)
                    DisableControlAction(0, NATIVE_DRIVE_STEER_UD, true)
                    DisableControlAction(0, NATIVE_DRIVE_STEER_LEFT, true)
                    DisableControlAction(0, NATIVE_DRIVE_STEER_RIGHT, true)
                end
            end

            -- ── Mirror state into the NUI, only when it actually changes ──
            local held = {}
            if hydroRaised then held[#held+1] = 'on' end
            if frontHeld then held[#held+1] = 'forward'  end
            if rearHeld  then held[#held+1] = 'backward' end
            if leftHeld  then held[#held+1] = 'left'     end
            if rightHeld then held[#held+1] = 'right'    end
            if macroActive then held[#held+1] = 'macro:' .. macroPhase end

            lastFrontHeld, lastRearHeld, lastLeftHeld, lastRightHeld = frontHeld, rearHeld, leftHeld, rightHeld

            local sig = table.concat(held, ',')
            if sig ~= lastSig then
                SendNUI('keys', { held = held })
                lastSig = sig
                Dbg('natives -> hydroRaised=%s macroActive=%s macroPhase=%s | front=%s rear=%s left=%s right=%s',
                    tostring(hydroRaised), tostring(macroActive), tostring(macroPhase),
                    tostring(frontHeld), tostring(rearHeld), tostring(leftHeld), tostring(rightHeld))
            end
        end

        -- Clean up: clear UI state
        SendNUI('keys', { held = {} })
    end)
end

---------------------------------------------------------------------------
-- Open / Close / Show / Hide
---------------------------------------------------------------------------

function OpenUI()
    if uiOpen then return end
    uiOpen      = true
    uiVisible   = true
    hydroRaised = false
    hydroActive = false
    oWasHeld    = false
    nWasHeld    = false
    preset3WasHeld = false
    preset1WasHeld = false
    macroActive = false
    macroPhase  = 0
    testHeld    = nil
    tiltHeld    = nil
    SetNuiFocus(false, false)

    if nuiReady then
        SendNUI('open')
    end
    -- If the NUI page hasn't confirmed it's loaded yet (e.g. we just got
    -- into a hydro vehicle within the first second or two of joining,
    -- before the browser finished loading), sending now would be dropped
    -- since app.js's message listener isn't registered yet. Nothing to
    -- queue here, though — RegisterNUICallback('ready', ...) below always
    -- resyncs the NUI to the live uiOpen/uiVisible state once it fires, so
    -- there's no separate "pending" flag to fall out of sync.

    StartInputThread()
end

function CloseUI()
    if not uiOpen then return end
    uiOpen      = false
    hydroRaised = false
    hydroActive = false
    oWasHeld    = false
    nWasHeld    = false
    preset3WasHeld = false
    preset1WasHeld = false
    macroActive = false
    macroPhase  = 0
    testHeld    = nil
    tiltHeld    = nil
    SetNuiFocus(false, false)
    if nuiReady then
        SendNUI('close')
    end
end

function ShowUI()
    uiVisible = true
    if nuiReady then
        SendNUI('show')
    end
end

function HideUI()
    -- Purely cosmetic — only touches panel visibility. Does NOT stop
    -- hydraulics or cancel the macro; a pose that's actively holding
    -- keeps doing exactly that whether the panel is shown or not. Use O
    -- to actually stop it — see StartInputThread.
    uiVisible = false
    if nuiReady then
        SendNUI('hide')
    end
end

---------------------------------------------------------------------------
-- Vehicle detection loop (500 ms)
---------------------------------------------------------------------------

-- Once the player is actually driving a hydraulics vehicle, hydroVeh
-- latches onto it and the session stays open — pose and all — even after
-- they get out, for as long as they're within HYDRO_EXIT_DISTANCE of it.
-- The vehicle only "forgets" the player (CloseUI, hydroVeh cleared) once
-- they've walked/driven far enough away, or the vehicle itself is gone.
-- This is what lets you hop out and look at a held 3-wheel from outside
-- instead of it dropping the instant you're no longer in the driver seat.
local function StartHydroLoop()
    if hydroThread then return end

    hydroThread = CreateThread(function()
        while true do
            Wait(500)

            local ped          = PlayerPedId()
            local veh          = GetVehiclePedIsIn(ped, false)
            local inDriverSeat = veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped

            if inDriverSeat and HasHydraulics(veh) then
                if inHydroVeh and veh ~= hydroVeh then
                    -- Driver seat swapped to a DIFFERENT hydraulics vehicle
                    -- while the old one's session was still open (still
                    -- within exit distance) — close that one out cleanly
                    -- before latching onto the new one.
                    inHydroVeh = false
                    CloseUI()
                end

                hydroVeh = veh
                if not inHydroVeh then
                    inHydroVeh = true
                    OpenUI()
                end
            elseif inHydroVeh then
                -- Not currently driving hydroVeh (on foot, a passenger
                -- seat, or a different vehicle). Keep the session open —
                -- and keep hydroVeh pointed at the real vehicle, so the
                -- input thread keeps controlling its hydraulics remotely
                -- (see StartInputThread) — until the player has put real
                -- distance between themselves and it, not merely stepped
                -- out of the seat.
                local vehExists = hydroVeh and DoesEntityExist(hydroVeh)
                local dist = vehExists and #(GetEntityCoords(ped) - GetEntityCoords(hydroVeh)) or nil

                if not vehExists or dist >= HYDRO_EXIT_DISTANCE then
                    inHydroVeh = false
                    CloseUI()
                    hydroVeh  = nil
                end
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Debug command (F8 console)
---------------------------------------------------------------------------

RegisterCommand('hydrodebug', function()
    local ped = PlayerPedId()
    -- Prefer the vehicle we're actually seated in; fall back to hydroVeh
    -- so this stays useful for checking the exit-distance grace window
    -- (see StartHydroLoop) after getting out of a hydraulics vehicle.
    local veh = GetVehiclePedIsIn(ped, false)
    local usingHydroVeh = false
    if veh == 0 and hydroVeh and DoesEntityExist(hydroVeh) then
        veh = hydroVeh
        usingHydroVeh = true
    end

    if veh == 0 then print('[hydroui] Not in a vehicle, and no hydroVeh on record.') return end

    local modelName    = GetVehicleModelName(veh)
    local hydraulicsOn = IsToggleModOn(veh, 21)   -- VMT_HYDRAULICS
    local hydraulicsModIndex = GetVehicleMod(veh, 21) -- -1 = not installed, 0+ = installed (tier)
    local inDriver     = GetPedInVehicleSeat(veh, -1) == ped
    local inWhitelist  = LOWRIDER_MODELS[modelName] == true
    local exitDist     = usingHydroVeh and #(GetEntityCoords(ped) - GetEntityCoords(veh)) or 0.0

    print(string.format(
        '[hydroui] model=%s | driver=%s | whitelist=%s | hydraulicsInstalled=%s | hydraulicsModIndex=%s | uiOpen=%s | uiVisible=%s | hydroRaised=%s | macroActive=%s | macroPhase=%s | macroSide=%s | nuiReady=%s',
        modelName, tostring(inDriver), tostring(inWhitelist),
        tostring(hydraulicsOn), tostring(hydraulicsModIndex), tostring(uiOpen), tostring(uiVisible), tostring(hydroRaised),
        tostring(macroActive), tostring(macroPhase), tostring(macroSide or 'none'), tostring(nuiReady)
    ))
    print(string.format(
        '[hydroui] usingHydroVeh=%s (remote control range) | distance to vehicle=%.2f (releases at %.1f) | seated=%s',
        tostring(usingHydroVeh), exitDist, HYDRO_EXIT_DISTANCE, tostring(inDriver)
    ))
    print(string.format(
        '[hydroui] testHeld=%s | tiltHeld=%s | vertical velocity=%.2f (cap=%.2f)',
        tostring(testHeld ~= nil), tostring(tiltHeld or 'none'), GetEntityVelocity(veh).z, MACRO_LIFT_MAX_VERTICAL_VEL
    ))
    print(string.format(
        '[hydroui] last natives sent -> front=%s rear=%s left=%s right=%s',
        tostring(lastFrontHeld), tostring(lastRearHeld), tostring(lastLeftHeld), tostring(lastRightHeld)
    ))
end, false)

RegisterCommand('hydrodebugtoggle', function()
    DEBUG_HYDROUI = not DEBUG_HYDROUI
    print('[hydroui] debug logging: ' .. (DEBUG_HYDROUI and 'ON' or 'OFF'))
end, false)

-- Raw combo tester (F8 console): holds ONE fixed native combo indefinitely
-- so you can walk around the car and actually look at it, instead of a
-- scripted sequence blowing past every position in 400ms. This is for
-- figuring out, empirically, which combo (if any) actually lifts a single
-- wheel — once we know that, the macro's phase 2/3 combos can be set to
-- whatever's actually confirmed instead of what I've been guessing.
--   /hydrotest front | rear | left | right
--   /hydrotest frontleft | frontright | rearleft | rearright
--   /hydrotest all
--   /hydrotest off      -- release, back to normal O/arrow/macro control
local HYDROTEST_COMBOS = {
    front      = { front = true },
    rear       = { rear  = true },
    left       = { left  = true },
    right      = { right = true },
    frontleft  = { front = true, left  = true },
    frontright = { front = true, right = true },
    rearleft   = { rear  = true, left  = true },
    rearright  = { rear  = true, right = true },
    all        = { front = true, rear = true, left = true, right = true },
}

RegisterCommand('hydrotest', function(_, args)
    local key = string.lower(args[1] or 'off')

    if key == 'off' then
        testHeld = nil
        print('[hydroui] hydrotest: released — back to normal O/arrow/macro control')
        return
    end

    local combo = HYDROTEST_COMBOS[key]
    if not combo then
        print('[hydroui] hydrotest: unknown combo "' .. key .. '". Options: front, rear, left, right, frontleft, frontright, rearleft, rearright, all, off')
        return
    end

    if not uiOpen then
        print('[hydroui] hydrotest: get in a hydraulics vehicle first (UI is not open).')
        return
    end

    hydroRaised = true
    macroActive = false
    macroPhase  = 0
    tiltHeld    = nil
    testHeld    = combo
    print('[hydroui] hydrotest: holding "' .. key .. '" indefinitely — /hydrotest off to release')
end, false)

-- Per-wheel tilt-force tester (F8 console): applies the SAME force-couple
-- lift used by the 3-wheel presets (see ApplyWheelTiltForce /
-- ApplyRampedWheelTilt / MACRO_LIFT_CORNER near the top of the file) to
-- any single corner, indefinitely, so you can check how it looks and how
-- strong it feels before trusting it inside Numpad3/Numpad1. This is the
-- "detect + control any wheel individually" system — front-right and
-- front-left are what the presets currently use, but all four corners
-- work here since the couple is corner-generic.
--   /hydrotilt fl | fr | rl | rr
--   /hydrotilt off      -- release, back to normal O/arrow/macro control
RegisterCommand('hydrotilt', function(_, args)
    local key = string.lower(args[1] or 'off')

    if key == 'off' then
        tiltHeld = nil
        print('[hydroui] hydrotilt: released — back to normal O/arrow/macro control')
        return
    end

    if not WHEEL_BONES[key] then
        print('[hydroui] hydrotilt: unknown corner "' .. key .. '". Options: fl, fr, rl, rr, off')
        return
    end

    if not uiOpen then
        print('[hydroui] hydrotilt: get in a hydraulics vehicle first (UI is not open).')
        return
    end

    hydroRaised = true
    macroActive = false
    macroPhase  = 0
    testHeld    = nil
    tiltHeld    = key
    tiltStartAt = GetGameTimer()
    print('[hydroui] hydrotilt: lifting "' .. key .. '" (pushing down its diagonal opposite "' ..
        DIAGONAL_OPPOSITE[key] .. '") indefinitely — /hydrotilt off to release')
end, false)

---------------------------------------------------------------------------
-- NUI Callbacks
---------------------------------------------------------------------------

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true

    -- Resync the NUI to whatever the Lua-side state currently is. This
    -- covers OpenUI() having been called before the browser finished
    -- loading (the common case), and also a NUI reload mid-session (e.g.
    -- a resource restart) where the page resets to its default markup —
    -- previously only 'open' got replayed here, so a hide/close that had
    -- already fired before the reload was never resent and the panel
    -- could end up permanently stuck showing. Checking live state instead
    -- of a one-shot "pending" flag closes that gap.
    if uiOpen then
        SendNUI('open')
        if not uiVisible then
            SendNUI('hide')
        end
    end

    cb('ok')
end)

---------------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------------
exports('IsHydroUIOpen', function()
    return uiOpen
end)

---------------------------------------------------------------------------
-- Resource lifecycle
---------------------------------------------------------------------------

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then CloseUI() end
end)

CreateThread(function()
    Wait(1000)
    StartHydroLoop()
end)

RegisterCommand('hydroui', function()
    if uiOpen then CloseUI() else OpenUI() end
end, false)