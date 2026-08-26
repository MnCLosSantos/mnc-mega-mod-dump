const soundPlayer = document.getElementById('soundPlayer');
const hud = document.getElementById('hud');
const conditionBar = document.getElementById('conditionBar');
const conditionValue = document.getElementById('conditionValue');
const damageHint = document.getElementById('damageHint');
const timeBar = document.getElementById('timeBar');
const timeValue = document.getElementById('timeValue');

const setupPanel = document.getElementById('setup');
const setupForm = document.getElementById('setupForm');
const setupList = document.getElementById('setupList');
const setupCloseBtn = document.getElementById('setupCloseBtn');
const viewRoutesBtn = document.getElementById('viewRoutesBtn');
const startTestDriveBtn = document.getElementById('startTestDriveBtn');
const timerNote = document.getElementById('timerNote');
const saveBtn = document.getElementById('saveBtn');
const editingBanner = document.getElementById('editingBanner');
const editingLabel = document.getElementById('editingLabel');
const cancelEditBtn = document.getElementById('cancelEditBtn');

const testDriveHUD = document.getElementById('testDriveHUD');
const testDriveValue = document.getElementById('testDriveValue');

const placementHUD = document.getElementById('placementHUD');
const placementHintText = document.getElementById('placementHintText');

let totalTime = 1;
let activePosTarget = null;
let editingDbId = null;
let editingConfigIndex = null;
let timedSnapshot = null; // spawn/drop/radius/vehicles values the current f_time is actually valid for

function resourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'mnc-cardelivery';
}

function nuiPost(endpoint, body) {
    return fetch(`https://${resourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(body || {}),
    });
}

function formatMMSS(totalSeconds) {
    const s = Math.max(0, totalSeconds || 0);
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
}

function playSound(category, index) {
    // dropoff has a single file with no numbered variants
    const file = category === 'dropoff' ? 'dropoff' : `${category}${index}`;
    const path = `sounds/${file}.mp3`;
    soundPlayer.src = path;
    soundPlayer.currentTime = 0;

    const finish = () => {
        soundPlayer.onended = null;
        soundPlayer.onerror = null;
        nuiPost('audioEnded', { category, index }).catch(() => {});
    };

    soundPlayer.onended = finish;
    // If the file is missing/misnamed/fails to load, the 'ended' event never
    // fires and the caller (client.lua) is left waiting forever - e.g. the
    // key-prompt flow gets stuck and never plays again for that vehicle.
    // Falling back through 'error' keeps the flow moving and logs why.
    soundPlayer.onerror = () => {
        console.warn(`[mnc-cardelivery] failed to load ${path} - check the file exists and Config.Sounds counts match what's on disk`);
        finish();
    };

    soundPlayer.play().catch((err) => {
        console.warn(`[mnc-cardelivery] play() rejected for ${path}:`, err);
    });
}

function updateHUD(condition, timeRemaining) {
    condition = Math.max(0, Math.min(100, condition));
    conditionBar.style.width = `${condition}%`;
    conditionValue.textContent = `${Math.round(condition)}%`;
    conditionBar.style.background = condition > 60 ? '#3ddc71' : condition > 30 ? '#e8c93a' : '#e0473f';

    const pct = totalTime > 0 ? Math.max(0, Math.min(100, (timeRemaining / totalTime) * 100)) : 0;
    timeBar.style.width = `${pct}%`;
    timeBar.style.background = pct > 25 ? '#4aa3ff' : '#e0473f';

    timeValue.textContent = formatMMSS(timeRemaining);
}

// ---------------------------------------------------------------------
// Route builder (admin /cardeliverysetup UI)
// ---------------------------------------------------------------------
function routeDisplayLabel(loc) {
    if (loc.label) return loc.label;
    if (loc.configIndex != null) return `Config route ${loc.configIndex}`;
    return 'Unnamed route';
}

function renderSetupList(locations) {
    setupList.innerHTML = '';
    (locations || []).forEach((loc) => {
        const li = document.createElement('li');

        const label = document.createElement('span');
        label.textContent = routeDisplayLabel(loc);
        if (loc.disabled) {
            const tag = document.createElement('span');
            tag.className = 'disabled-tag';
            tag.textContent = ' (disabled)';
            label.appendChild(tag);
        }
        li.appendChild(label);

        const actions = document.createElement('div');
        actions.className = 'route-actions';

        const edit = document.createElement('button');
        edit.type = 'button';
        edit.textContent = 'Edit';
        edit.className = 'edit-btn';
        edit.addEventListener('click', () => {
            startEditing(loc);
            // jump back to the form page so the fields being edited are visible
            setRoutesListVisible(false);
        });
        actions.appendChild(edit);

        const del = document.createElement('button');
        del.type = 'button';
        del.textContent = 'Delete';
        del.className = 'delete-btn';
        del.addEventListener('click', () => {
            nuiPost('setupDeleteLocation', { dbId: loc.dbId, configIndex: loc.configIndex }).catch(() => {});
        });
        actions.appendChild(del);

        li.appendChild(actions);
        setupList.appendChild(li);
    });
}

function closeSetup() {
    setupPanel.classList.add('hidden');
    nuiPost('setupClose').catch(() => {});
}

// the saved-routes list starts hidden each time the builder opens - "View
// Routes" swaps it in as its own page (hiding the form) instead of just
// unhiding it alongside the old form content, so it reads as a real page change.
function setRoutesListVisible(visible) {
    setupList.parentElement.classList.toggle('hidden', !visible);
    setupForm.classList.toggle('hidden', visible);
    viewRoutesBtn.textContent = visible ? 'Hide Routes' : 'View Routes';
    viewRoutesBtn.classList.toggle('active', visible);
}

// spawn/drop/radius/vehicles only - label and time are deliberately excluded,
// since neither one changes what a test drive would measure
function getFormSnapshot() {
    return [
        'sx', document.getElementById('f_spawn_x').value,
        'sy', document.getElementById('f_spawn_y').value,
        'sz', document.getElementById('f_spawn_z').value,
        'sw', document.getElementById('f_spawn_w').value,
        'dx', document.getElementById('f_drop_x').value,
        'dy', document.getElementById('f_drop_y').value,
        'dz', document.getElementById('f_drop_z').value,
        'r', document.getElementById('f_radius').value,
        'v', document.getElementById('f_vehicles').value.trim().toLowerCase(),
    ].join('|');
}

function canStartTestDrive() {
    const spawnOk = ['f_spawn_x', 'f_spawn_y', 'f_spawn_z', 'f_spawn_w'].every((id) => document.getElementById(id).value !== '');
    const dropOk = ['f_drop_x', 'f_drop_y', 'f_drop_z'].every((id) => document.getElementById(id).value !== '');
    const radius = parseFloat(document.getElementById('f_radius').value);
    const vehicles = document.getElementById('f_vehicles').value.trim();
    return spawnOk && dropOk && radius > 0 && vehicles !== '';
}

function isTimeValid() {
    return timedSnapshot !== null && timedSnapshot === getFormSnapshot() && document.getElementById('f_time').value !== '';
}

function refreshFormState() {
    const timeValid = isTimeValid();
    saveBtn.disabled = !timeValid;

    const canDrive = canStartTestDrive();
    startTestDriveBtn.disabled = !canDrive;
    startTestDriveBtn.title = canDrive ? '' : 'Fill in spawn, dropoff, radius and vehicles first';

    if (timerNote) {
        if (!canDrive) {
            timerNote.textContent = 'Fill in spawn, dropoff, radius and vehicles, then drive the route to set the time.';
        } else if (!timeValid) {
            timerNote.textContent = document.getElementById('f_time').value !== ''
                ? 'Route changed since it was timed - drive it again before saving.'
                : 'Drive the route to set the delivery time before saving.';
        } else {
            timerNote.textContent = 'Time limit set. Change spawn/dropoff/radius/vehicles and you’ll need to drive it again.';
        }
    }
}

['f_spawn_x', 'f_spawn_y', 'f_spawn_z', 'f_spawn_w', 'f_drop_x', 'f_drop_y', 'f_drop_z', 'f_radius', 'f_vehicles'].forEach((id) => {
    document.getElementById(id).addEventListener('input', refreshFormState);
});

function resetSetupForm() {
    setupForm.reset();
    document.getElementById('f_radius').value = 8;
    document.getElementById('f_time').value = '';

    editingDbId = null;
    editingConfigIndex = null;
    editingBanner.classList.add('hidden');
    saveBtn.textContent = 'Save route';
    timedSnapshot = null;
    refreshFormState();
}

function startEditing(loc) {
    document.getElementById('f_label').value = loc.label || '';
    document.getElementById('f_spawn_x').value = loc.spawn.x.toFixed(2);
    document.getElementById('f_spawn_y').value = loc.spawn.y.toFixed(2);
    document.getElementById('f_spawn_z').value = loc.spawn.z.toFixed(2);
    document.getElementById('f_spawn_w').value = loc.spawn.w.toFixed(2);
    document.getElementById('f_drop_x').value = loc.delivery.x.toFixed(2);
    document.getElementById('f_drop_y').value = loc.delivery.y.toFixed(2);
    document.getElementById('f_drop_z').value = loc.delivery.z.toFixed(2);
    document.getElementById('f_radius').value = loc.radius;
    document.getElementById('f_time').value = loc.time;
    document.getElementById('f_vehicles').value = (loc.vehicles || []).join(', ');

    editingDbId = loc.dbId != null ? loc.dbId : null;
    editingConfigIndex = loc.configIndex != null ? loc.configIndex : null;

    editingLabel.textContent = routeDisplayLabel(loc);
    editingBanner.classList.remove('hidden');
    saveBtn.textContent = 'Update route';

    // this route's existing time limit is already valid for its own coords/vehicles
    timedSnapshot = getFormSnapshot();
    refreshFormState();
}

function applyPlacementResult(target, result) {
    if (target === 'spawn') {
        document.getElementById('f_spawn_x').value = result.x.toFixed(2);
        document.getElementById('f_spawn_y').value = result.y.toFixed(2);
        document.getElementById('f_spawn_z').value = result.z.toFixed(2);
        document.getElementById('f_spawn_w').value = result.w.toFixed(2);
    } else if (target === 'drop') {
        document.getElementById('f_drop_x').value = result.x.toFixed(2);
        document.getElementById('f_drop_y').value = result.y.toFixed(2);
        document.getElementById('f_drop_z').value = result.z.toFixed(2);
    }
    refreshFormState();
}

document.querySelectorAll('.pos-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        activePosTarget = btn.dataset.target;
        nuiPost('setupUseMyPosition')
            .then((r) => r.json())
            .then((coords) => {
                if (!coords) return;
                if (activePosTarget === 'spawn') {
                    document.getElementById('f_spawn_x').value = coords.x.toFixed(2);
                    document.getElementById('f_spawn_y').value = coords.y.toFixed(2);
                    document.getElementById('f_spawn_z').value = coords.z.toFixed(2);
                    document.getElementById('f_spawn_w').value = coords.w.toFixed(2);
                } else if (activePosTarget === 'drop') {
                    document.getElementById('f_drop_x').value = coords.x.toFixed(2);
                    document.getElementById('f_drop_y').value = coords.y.toFixed(2);
                    document.getElementById('f_drop_z').value = coords.z.toFixed(2);
                }
                refreshFormState();
            })
            .catch(() => {});
    });
});

document.querySelectorAll('.placement-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        const target = btn.dataset.target;
        const firstVehicle = (document.getElementById('f_vehicles').value || '').split(',')[0].trim();
        // hand control back to the game immediately; the panel reopens itself
        // (via placementDone) once the drive is finished or cancelled
        setupPanel.classList.add('hidden');
        nuiPost('setupStartPlacement', { target, vehicleModel: firstVehicle }).catch(() => {});
    });
});

setupCloseBtn.addEventListener('click', closeSetup);
cancelEditBtn.addEventListener('click', resetSetupForm);

viewRoutesBtn.addEventListener('click', () => {
    const isHidden = setupList.parentElement.classList.contains('hidden');
    setRoutesListVisible(isHidden);
});

startTestDriveBtn.addEventListener('click', () => {
    if (!canStartTestDrive()) return;
    const payload = {
        spawn: {
            x: parseFloat(document.getElementById('f_spawn_x').value),
            y: parseFloat(document.getElementById('f_spawn_y').value),
            z: parseFloat(document.getElementById('f_spawn_z').value),
            w: parseFloat(document.getElementById('f_spawn_w').value),
        },
        delivery: {
            x: parseFloat(document.getElementById('f_drop_x').value),
            y: parseFloat(document.getElementById('f_drop_y').value),
            z: parseFloat(document.getElementById('f_drop_z').value),
        },
        radius: parseFloat(document.getElementById('f_radius').value),
        vehicles: document.getElementById('f_vehicles').value,
    };
    setupPanel.classList.add('hidden');
    nuiPost('setupStartTestDrive', payload).catch(() => {});
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !setupPanel.classList.contains('hidden')) {
        closeSetup();
    }
});

setupForm.addEventListener('submit', (e) => {
    e.preventDefault();
    if (!isTimeValid()) {
        refreshFormState();
        return;
    }
    const payload = {
        label: document.getElementById('f_label').value,
        spawn: {
            x: parseFloat(document.getElementById('f_spawn_x').value),
            y: parseFloat(document.getElementById('f_spawn_y').value),
            z: parseFloat(document.getElementById('f_spawn_z').value),
            w: parseFloat(document.getElementById('f_spawn_w').value),
        },
        delivery: {
            x: parseFloat(document.getElementById('f_drop_x').value),
            y: parseFloat(document.getElementById('f_drop_y').value),
            z: parseFloat(document.getElementById('f_drop_z').value),
        },
        radius: parseFloat(document.getElementById('f_radius').value),
        timeLimit: parseInt(document.getElementById('f_time').value, 10),
        vehicles: document.getElementById('f_vehicles').value,
        dbId: editingDbId,
        configIndex: editingConfigIndex,
    };
    nuiPost('setupSaveLocation', payload).catch(() => {});
    resetSetupForm();
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    switch (data.action) {
        case 'playSound':
            playSound(data.category, data.index);
            break;
        case 'showHUD':
            totalTime = data.timeLimit || 1;
            if (damageHint) {
                damageHint.textContent = `Damage cap: ${data.maxDamagePercent ?? 20}%`;
            }
            updateHUD(100, totalTime);
            hud.classList.remove('hidden');
            break;
        case 'hideHUD':
            hud.classList.add('hidden');
            break;
        case 'updateHUD':
            updateHUD(data.condition, data.timeRemaining);
            break;
        case 'openSetup':
            renderSetupList(data.locations);
            setupPanel.classList.remove('hidden');
            setRoutesListVisible(false);
            refreshFormState();
            break;
        case 'setupLocations':
            renderSetupList(data.locations);
            break;
        case 'testDriveShow':
            if (testDriveHUD) {
                testDriveValue.textContent = '00:00';
                testDriveHUD.classList.remove('hidden');
            }
            break;
        case 'testDriveTick':
            if (testDriveHUD) {
                testDriveValue.textContent = formatMMSS(data.elapsed);
            }
            break;
        case 'testDriveHide':
            if (testDriveHUD) {
                testDriveHUD.classList.add('hidden');
            }
            break;
        case 'testDriveDone':
            setupPanel.classList.remove('hidden');
            if (!data.cancelled && data.result) {
                document.getElementById('f_time').value = data.result.timeLimit;
                timedSnapshot = getFormSnapshot();
                timerNote.textContent = `Timed by driving: ${formatMMSS(data.result.rawElapsed)} raw -> ${formatMMSS(data.result.timeLimit)} with buffer.`;
            }
            refreshFormState();
            break;
        case 'placementShow':
            if (placementHUD) {
                placementHintText.textContent = 'Flying - ENTER to drop the car here.';
                placementHUD.classList.remove('hidden');
            }
            break;
        case 'placementHint':
            if (placementHintText) {
                placementHintText.textContent = data.text || '';
            }
            break;
        case 'placementHide':
            if (placementHUD) {
                placementHUD.classList.add('hidden');
            }
            break;
        case 'placementDone':
            setupPanel.classList.remove('hidden');
            if (!data.cancelled && data.result) {
                applyPlacementResult(data.target, data.result);
            }
            break;
    }
});