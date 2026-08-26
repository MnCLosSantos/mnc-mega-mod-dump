Config = {}

-- Command admins type to open the editor (no leading slash)
Config.Command = 'handui'

-- QBCore.Functions.HasPermission level required to open/use the editor
Config.AdminPermission = 'admin'

-- Allowed vehicle classes/categories/models that can be tuned with this editor.
-- - Integer: vehicle class ID from GetVehicleClass() native (18 = emergency)
-- - String category: from QBCore.Shared.Vehicles[model].category
-- - String model name: exact spawn code like 'secret' for custom vehicles
-- Only these will open the UI. Add more freely.
Config.AllowedClasses = {
    18,                    -- emergency class ID
    'secret',              -- QBCore category
    'military',
    -- 'super',
    -- 'secret',           -- example custom model
}

-- How high above the admin (in metres) ghost preview vehicles are spawned.
-- These are invisible/frozen/non-colliding, but CreateVehicle still needs
-- *somewhere with collision actually streamed in* to place a non-networked
-- entity — a fixed coordinate deep underground (e.g. -3000z) is reliably
-- empty void with nothing streamed there, which makes CreateVehicle fail.
-- Spawning relative to the admin guarantees the area is already loaded.
Config.PreviewHeightOffset = 60.0

-- How far in front of the admin a drivable test vehicle is spawned
Config.TestVehicleSpawnDistance = 4.0

-- Delete any spawned test vehicle automatically when the UI is closed
Config.AutoDespawnTestVehicle = true

-- Warp the admin straight into the driver's seat when a test vehicle is
-- spawned, so they can immediately feel changes instead of having to walk
-- over and get in themselves
Config.AutoEnterTestVehicle = true

-- ---------------------------------------------------------------------------
-- Handling fields exposed in the editor, grouped into tabs/categories.
-- `key`   must exactly match the handling.meta field name (used directly with
--         SetVehicleHandlingFloat / SetVehicleHandlingInt / their Get equivalents)
-- `type`  'float' or 'int'
-- min/max/step are used for client-side slider ranges and server-side clamping
-- ---------------------------------------------------------------------------
Config.HandlingFields = {
    {
        category = 'Engine & Power',
        icon = 'gauge-high',
        fields = {
            { key = 'fInitialDriveMaxFlatVel',       label = 'Top Speed',           type = 'float', min = 10.0,  max = 325.0, step = 0.5,   hint = 'Raw top speed in m/s before drag is applied. Vanilla cars sit around 35-75.' },
            { key = 'fInitialDriveForce',             label = 'Acceleration Force',  type = 'float', min = 0.05,  max = 5.0,  step = 0.005, hint = 'How hard the engine pulls. Vanilla cars sit around 0.15-0.45.' },
            { key = 'fDriveInertia',                  label = 'Drive Inertia',       type = 'float', min = 0.5,   max = 5.0,   step = 0.01,  hint = 'How quickly the drivetrain responds to throttle input.' },
            { key = 'nInitialDriveGears',              label = 'Gear Count',          type = 'int',   min = 1,     max = 10,    step = 1,     hint = 'Number of forward gears.' },
            { key = 'fClutchChangeRateScaleUpShift',   label = 'Upshift Speed',       type = 'float', min = 0.5,   max = 40.0,  step = 0.1,   class = 'CCarHandlingData', hint = 'How fast the clutch engages on upshifts.' },
            { key = 'fClutchChangeRateScaleDownShift', label = 'Downshift Speed',     type = 'float', min = 0.5,   max = 40.0,  step = 0.1,   class = 'CCarHandlingData', hint = 'How fast the clutch engages on downshifts.' },
        }
    },
    {
        category = 'Braking',
        icon = 'brake-warning',
        fields = {
            { key = 'fBrakeForce',     label = 'Brake Force',        type = 'float', min = 0.1, max = 4.5, step = 0.01, hint = 'Overall braking strength.' },
            { key = 'fBrakeBiasFront', label = 'Brake Bias (Front)', type = 'float', min = 0.0, max = 4.0, step = 0.01, hint = '0 = all rear bias, 1 = all front bias.' },
            { key = 'fHandBrakeForce', label = 'Handbrake Force',    type = 'float', min = 0.0, max = 4.0, step = 0.01, hint = 'Strength of the rear-lock handbrake.' },
        }
    },
    {
        category = 'Traction & Steering',
        icon = 'steering-wheel',
        fields = {
            { key = 'fSteeringLock',             label = 'Steering Lock',           type = 'float', min = 10.0, max = 90.0, step = 0.5,  hint = 'Maximum wheel turn angle in degrees.' },
            { key = 'fTractionCurveMax',         label = 'Traction Curve Max',      type = 'float', min = 0.5,  max = 4.5,  step = 0.01, hint = 'Peak grip available before tyres slide.' },
            { key = 'fTractionCurveMin',         label = 'Traction Curve Min',      type = 'float', min = 0.5,  max = 4.5,  step = 0.01, hint = 'Minimum grip once a slide has started.' },
            { key = 'fTractionCurveLateral',     label = 'Traction Curve Lateral',  type = 'float', min = 1.0,  max = 90.0, step = 0.5,  hint = 'Slip angle the traction curve is centred on.' },
            { key = 'fLowSpeedTractionLossMult', label = 'Low Speed Traction Loss', type = 'float', min = 0.0,  max = 4.0,  step = 0.01, hint = 'Grip lost at low speed (handbrake turns, etc).' },
            { key = 'fTractionBiasFront',        label = 'Traction Bias (Front)',   type = 'float', min = 0.0,  max = 1.0,  step = 0.01, hint = '0 = RWD-style grip bias, 1 = FWD-style.' },
            { key = 'fDriveBiasFront',            label = 'Drive Bias (Front)',      type = 'float', min = 0.0,  max = 1.0,  step = 0.01, hint = 'Which wheels actually get engine power. 0 = rear wheels only (RWD), 1 = front wheels only (FWD), 0.5 = split evenly (AWD). This is what lets a car drift — traction tweaks alone do nothing if power never reaches the rear wheels.' },
            { key = 'fTractionLossMult',         label = 'Traction Loss Mult',      type = 'float', min = 0.0,  max = 4.0,  step = 0.01, hint = 'General grip loss multiplier (e.g. wet surfaces).' },
        }
    },
    {
        category = 'Suspension',
        icon = 'car-shock',
        fields = {
            { key = 'fSuspensionForce',       label = 'Suspension Force',       type = 'float', min = 0.5,  max = 6.0, step = 0.01, hint = 'Stiffness of the springs.' },
            { key = 'fSuspensionCompDamp',    label = 'Compression Damping',    type = 'float', min = 0.0,  max = 5.0, step = 0.01, hint = 'Resistance to compressing.' },
            { key = 'fSuspensionReboundDamp', label = 'Rebound Damping',        type = 'float', min = 0.0,  max = 5.0, step = 0.01, hint = 'Resistance to springing back.' },
            { key = 'fSuspensionUpperLimit',  label = 'Suspension Upper Limit', type = 'float', min = -0.5, max = 0.5, step = 0.01, hint = 'How high the body can rise on the springs.' },
            { key = 'fSuspensionLowerLimit',  label = 'Suspension Lower Limit', type = 'float', min = -0.5, max = 0.5, step = 0.01, hint = 'How low the body can drop on the springs.' },
            { key = 'fAntiRollBarForce',      label = 'Anti-Roll Bar Force',    type = 'float', min = 0.0,  max = 2.0, step = 0.01, hint = 'Resistance to body roll in corners.' },
        }
    },
    {
        category = 'Mass & Damage',
        icon = 'car-burst',
        fields = {
            { key = 'fMass',                  label = 'Mass (kg)',          type = 'float', min = 10.0, max = 5000.0, step = 10.0, hint = 'Vehicle weight. Heavier = more momentum, slower acceleration.' },
            { key = 'fInitialDragCoeff',      label = 'Drag Coefficient',   type = 'float', min = 0.0,   max = 20.0,   step = 0.1,  hint = 'Air resistance. Higher values cap top speed harder.' },
            { key = 'fCollisionDamageMult',   label = 'Collision Damage',   type = 'float', min = 0.0,   max = 5.0,    step = 0.1,  hint = 'How much crash damage the body takes.' },
            { key = 'fWeaponDamageMult',      label = 'Weapon Damage',      type = 'float', min = 0.0,   max = 5.0,    step = 0.1,  hint = 'Vulnerability to gunfire.' },
            { key = 'fDeformationDamageMult', label = 'Deformation Damage', type = 'float', min = 0.0,   max = 5.0,    step = 0.1,  hint = 'How visibly the body deforms when damaged.' },
            { key = 'fEngineDamageMult',      label = 'Engine Damage',      type = 'float', min = 0.0,   max = 5.0,    step = 0.1,  hint = 'How fast the engine takes damage and degrades performance.' },
            { key = 'fPetrolTankVolume',      label = 'Petrol Tank Volume', type = 'float', min = 0.0,   max = 300.0,  step = 1.0,  hint = 'Fuel tank size, affects explosion size and fuel-script range.' },
        }
    },
}

-- ---------------------------------------------------------------------------
-- Presets. Each preset is a SPARSE table of multipliers applied against the
-- vehicle's own vanilla (original) handling values, not flat absolute
-- numbers — a 1.4x top-speed multiplier means something sensible on every
-- vehicle, whereas a flat "top speed = 80" preset would be useless on a
-- Panto and a downgrade on a Zentorno. Fields with no entry in `multipliers`
-- are left untouched. The NUI clamps to each field's min/max for display;
-- the server's SanitizeFields/ClampValue is the real safety net regardless
-- of what the client sends.
-- ---------------------------------------------------------------------------
Config.Presets = {
    {
        key = 'civilian',
        label = 'Civilian',
        description = 'Stock-safe daily driving feel. Minor grip/ride polish, nothing extreme.',
        multipliers = {
            fTractionCurveMax = 1.05,
            fSuspensionForce = 0.95,
            fSuspensionCompDamp = 1.05,
        }
    },
    {
        key = 'police',
        label = 'Police',
        description = 'Pursuit-tuned: faster, harder braking, more durable, stable at speed.',
        multipliers = {
            fInitialDriveMaxFlatVel = 1.50,
            fInitialDriveForce = 1.80,
            fDriveInertia = 1.70,
            fClutchChangeRateScaleUpShift = 2.00,
            fClutchChangeRateScaleDownShift = 1.50,
            fTractionCurveMax = 1.40,
            fLowSpeedTractionLossMult = 0.50,
            fSuspensionForce = 1.20,
            fMass = 0.80,
            fInitialDragCoeff = 0.70,
            fBrakeForce = 1.10,
        }
    },
    {
        key = 'eco',
        label = 'Eco',
        description = 'Softer, more efficient, less aggressive. Bigger tank, calmer throttle.',
        multipliers = {
            fInitialDriveMaxFlatVel = 0.85,
            fInitialDriveForce = 0.75,
            fTractionLossMult = 0.90,
            fSuspensionCompDamp = 1.10,
            fPetrolTankVolume = 1.20,
        }
    },
    {
        key = 'street',
        label = 'Street',
        description = 'Balanced daily-performance bump. Faster and grippier without going extreme.',
        multipliers = {
            fInitialDriveMaxFlatVel = 1.20,
            fInitialDriveForce = 1.25,
            fBrakeForce = 1.15,
            fTractionCurveMax = 1.10,
            fSuspensionForce = 1.10,
            fSteeringLock = 1.05,
        }
    },
    {
        key = 'race',
        label = 'Race',
        description = 'Track-focused: max grip, stiff suspension, fast shifts, lighter weight.',
        multipliers = {
            fInitialDriveMaxFlatVel = 1.35,
            fInitialDriveForce = 1.50,
            fDriveInertia = 0.85,
            fClutchChangeRateScaleUpShift = 1.60,
            fClutchChangeRateScaleDownShift = 1.60,
            fBrakeForce = 1.40,
            fTractionCurveMax = 1.30,
            fTractionCurveMin = 1.20,
            fSuspensionForce = 1.30,
            fSuspensionCompDamp = 1.20,
            fSuspensionReboundDamp = 1.20,
            fAntiRollBarForce = 1.40,
            fMass = 0.90,
            fInitialDragCoeff = 0.85,
        }
    },
    {
        key = 'drag',
        label = 'Drag',
        description = 'Straight-line launch and top-end. Snappy shifts, minimal wheelspin off the line.',
        multipliers = {
            fInitialDriveMaxFlatVel = 1.50,
            fInitialDriveForce = 1.80,
            fDriveInertia = 0.70,
            fClutchChangeRateScaleUpShift = 2.00,
            fClutchChangeRateScaleDownShift = 1.50,
            fTractionCurveMax = 1.40,
            fLowSpeedTractionLossMult = 0.50,
            fSuspensionForce = 1.20,
            fMass = 0.80,
            fInitialDragCoeff = 0.70,
            fBrakeForce = 1.10,
        }
    },
    {
        key = 'drift',
        label = 'Drift',
        description = 'Forces power to the rear wheels with reduced grip and extra steering angle for sliding.',
        multipliers = {
            fInitialDriveMaxFlatVel = 1.20,
            fInitialDriveForce = 1.40,
            fSteeringLock = 1.40,
            fTractionCurveMax = 0.75,
            fTractionCurveMin = 0.60,
            fLowSpeedTractionLossMult = 1.60,
            fHandBrakeForce = 1.50,
            fSuspensionForce = 0.90,
            fAntiRollBarForce = 0.70,
        },
        -- Bias fields are a 0-1 position on a spectrum, not a magnitude — multiplying
        -- them against a vehicle's own baseline doesn't reliably push them in a
        -- meaningful direction (a stock FWD/AWD car never ends up sending power to
        -- the rear wheels). These are set to fixed targets instead.
        absolute = {
            fDriveBiasFront = 0.0,  -- power goes to the rear wheels only — required for the car to drift at all
            fTractionBiasFront = 0.25,
        }
    },
}

-- Flattened key -> field lookup, used for validation/clamping. Do not edit.
Config.FieldLookup = {}
for _, group in ipairs(Config.HandlingFields) do
    for _, field in ipairs(group.fields) do
        Config.FieldLookup[field.key] = field
    end
end