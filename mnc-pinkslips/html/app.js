const soundPlayer = document.getElementById('soundPlayer');

// ---- race HUD ----
const raceHud = document.getElementById('raceHud');
const raceTypeLabel = document.getElementById('raceTypeLabel');
const stakeValue = document.getElementById('stakeValue');
const raceTimeValue = document.getElementById('raceTimeValue');
const raceTimeBar = document.getElementById('raceTimeBar');
const raceCountdown = document.getElementById('raceCountdown');
const raceCountdownValue = document.getElementById('raceCountdownValue');

// ---- pinkslip menu ----
const pinkslipMenu = document.getElementById('pinkslipMenu');
const menuLabel = document.getElementById('menuLabel');
const menuClassChip = document.getElementById('menuClassChip');
const menuCloseBtn = document.getElementById('menuCloseBtn');
const slipsProgressText = document.getElementById('slipsProgressText');
const slipsProgressBar = document.getElementById('slipsProgressBar');
const potProgressBlock = document.getElementById('potProgressBlock');
const potProgressText = document.getElementById('potProgressText');
const potProgressBar = document.getElementById('potProgressBar');
const stockList = document.getElementById('stockList');
const potRaceBtn = document.getElementById('potRaceBtn');

// ---- admin builder ----
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
const spawnList = document.getElementById('spawnList');
const spawnCountLabel = document.getElementById('spawnCountLabel');
const spawnMinLabel = document.getElementById('spawnMinLabel');
const spawnNote = document.getElementById('spawnNote');

const classSelect = document.getElementById('f_class');
const vehiclesField = document.getElementById('f_vehicles');
const vehicleChipList = document.getElementById('vehicleChipList');
const browseVehiclesBtn = document.getElementById('browseVehiclesBtn');
const vehiclesNote = document.getElementById('vehiclesNote');

const vehicleGallery = document.getElementById('vehicleGallery');
const galleryClassChip = document.getElementById('galleryClassChip');
const galleryFilter = document.getElementById('galleryFilter');
const gallerySubtitle = document.getElementById('gallerySubtitle');
const galleryGrid = document.getElementById('galleryGrid');
const galleryCustomInput = document.getElementById('galleryCustomInput');
const galleryCustomAddBtn = document.getElementById('galleryCustomAddBtn');
const gallerySelectedCount = document.getElementById('gallerySelectedCount');
const galleryDoneBtn = document.getElementById('galleryDoneBtn');
const galleryCloseBtn = document.getElementById('galleryCloseBtn');

const testDriveHUD = document.getElementById('testDriveHUD');
const testDriveValue = document.getElementById('testDriveValue');

const placementHUD = document.getElementById('placementHUD');
const placementHintText = document.getElementById('placementHintText');

let totalRaceTime = 1;
let editingDbId = null;
let editingConfigIndex = null;
let timedSnapshot = null;
let spawnPoints = [];
let minSpawnPoints = 6;
let currentMenuData = null;

// ---- vehicle class / lot vehicle picker ----
let vehicleClasses = [];       // e.g. ['muscle', 'sports', ...] - from QBCore.Shared.Vehicles categories
let vehiclesByClass = {};      // { muscle: [{model, label}, ...], ... }
let imageSources = null;       // { fivem, github1, github2 } - from Config.VehicleImageSources
let imageSourceOrder = null;   // e.g. ['fivem', 'github1', 'github2']
let selectedVehicles = [];     // [{model, label}] - the lot vehicle pool being built in the form

function resourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'mnc-pinkslips';
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

function playSoundNow(path) {
    soundPlayer.src = path;
    soundPlayer.currentTime = 0;
    soundPlayer.play().catch((err) => {
        console.warn(`[mnc-pinkslips] play() rejected for ${path}:`, err);
    });
}

function playSound(category, index) {
    // 'go' and 'countdown' each play a single file with no numbered variants
    const file = (category === 'go' || category === 'countdown') ? category : `${category}${index}`;
    const path = `sounds/${file}.mp3`;

    // countdown.mp3's real length isn't always an exact multiple of the visual tick timing -
    // if 'go' arrives while countdown.mp3 is still actually playing, swapping soundPlayer.src
    // immediately would cut it off mid-word. Let it finish naturally first in that case.
    const countdownStillPlaying = category === 'go'
        && !soundPlayer.paused && !soundPlayer.ended
        && soundPlayer.currentSrc && soundPlayer.currentSrc.indexOf('countdown.mp3') !== -1;

    if (countdownStillPlaying) {
        soundPlayer.addEventListener('ended', () => playSoundNow(path), { once: true });
        return;
    }

    playSoundNow(path);
}

// ---------------------------------------------------------------------
// Race HUD
// ---------------------------------------------------------------------
function showRaceHUD(raceType, stakeLabel, timeLimit) {
    totalRaceTime = timeLimit || 1;
    raceTypeLabel.textContent = raceType === 'pinkslip' ? 'PINKSLIP RACE' : 'POT RACE';
    stakeValue.textContent = stakeLabel || '-';
    updateRaceHUD(timeLimit);
    raceHud.classList.remove('hidden');
}

function updateRaceHUD(timeRemaining) {
    const pct = totalRaceTime > 0 ? Math.max(0, Math.min(100, (timeRemaining / totalRaceTime) * 100)) : 0;
    raceTimeBar.style.width = `${pct}%`;
    raceTimeBar.style.background = pct > 25 ? '#4aa3ff' : '#e0473f';
    raceTimeValue.textContent = formatMMSS(timeRemaining);
}

function hideRaceHUD() {
    raceHud.classList.add('hidden');
}

function showRaceCountdown(value) {
    if (value === null || value === undefined) {
        raceCountdown.classList.add('hidden');
        return;
    }
    raceCountdownValue.textContent = value;
    raceCountdown.classList.remove('hidden');
}

// ---------------------------------------------------------------------
// Pinkslip menu
// ---------------------------------------------------------------------
function renderStockList(stock) {
    stockList.innerHTML = '';
    const unlockedSlots = currentMenuData ? currentMenuData.unlockedSlots : 0;
    const pinkslipsUsed = currentMenuData ? currentMenuData.pinkslipsUsed : 0;
    const canSlip = pinkslipsUsed < unlockedSlots;

    (stock || []).forEach((item) => {
        const li = document.createElement('li');

        const label = document.createElement('span');
        label.textContent = item.label + (item.source === 'captured' ? ' (won from a player)' : '');
        li.appendChild(label);

        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'race-btn';
        const price = (currentMenuData && currentMenuData.buyInPinkslip) || 0;
        btn.textContent = canSlip ? `Race for Pinkslip ($${price.toLocaleString()})` : 'No attempt unlocked';
        btn.disabled = !canSlip;
        btn.addEventListener('click', () => {
            nuiPost('menuStartRace', { raceType: 'pinkslip', slotIndex: item.slotIndex }).catch(() => {});
        });
        li.appendChild(btn);

        // outline the actual parked vehicle in-world while its row is moused over, so it's
        // obvious which car in the lot you'd be racing for
        li.addEventListener('mouseenter', () => {
            nuiPost('menuHoverStock', { slotIndex: item.slotIndex }).catch(() => {});
        });
        li.addEventListener('mouseleave', () => {
            nuiPost('menuHoverStock', { slotIndex: null }).catch(() => {});
        });

        stockList.appendChild(li);
    });

    if (!stock || stock.length === 0) {
        const li = document.createElement('li');
        li.textContent = 'No cars currently on the line - check back soon.';
        stockList.appendChild(li);
    }
}

function renderMenu(data) {
    currentMenuData = data;
    menuLabel.textContent = data.label || 'Pinkslip Races';
    menuClassChip.textContent = data.class || '';

    slipsProgressText.textContent = `${data.pinkslipsUsed} / ${data.unlockedSlots} unlocked (max ${data.maxSlots})`;
    const slipsPct = data.unlockedSlots > 0 ? Math.min(100, (data.pinkslipsUsed / data.unlockedSlots) * 100) : 0;
    slipsProgressBar.style.width = `${slipsPct}%`;

    if (data.unlockedSlots >= data.maxSlots) {
        potProgressBlock.classList.add('hidden');
    } else {
        potProgressBlock.classList.remove('hidden');
        potProgressText.textContent = `${data.potProgress} / ${data.potGoal}`;
        const potPct = data.potGoal > 0 ? Math.min(100, (data.potProgress / data.potGoal) * 100) : 0;
        potProgressBar.style.width = `${potPct}%`;
    }

    potRaceBtn.textContent = `Buy in for Pot Race ($${((data.buyInPot || 0)).toLocaleString()})`;

    renderStockList(data.stock);
}

menuCloseBtn.addEventListener('click', () => {
    pinkslipMenu.classList.add('hidden');
    nuiPost('menuClose').catch(() => {});
});

potRaceBtn.addEventListener('click', () => {
    nuiPost('menuStartRace', { raceType: 'pot', slotIndex: null }).catch(() => {});
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !pinkslipMenu.classList.contains('hidden')) {
        pinkslipMenu.classList.add('hidden');
        nuiPost('menuClose').catch(() => {});
    }
});

// ---------------------------------------------------------------------
// Admin: location builder (/setuppinkslips)
// ---------------------------------------------------------------------
function routeDisplayLabel(loc) {
    if (loc.label) return loc.label;
    if (loc.configIndex != null) return `Config location ${loc.configIndex}`;
    return 'Unnamed location';
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

function setRoutesListVisible(visible) {
    setupList.parentElement.classList.toggle('hidden', !visible);
    setupForm.classList.toggle('hidden', visible);
    viewRoutesBtn.textContent = visible ? 'Hide Locations' : 'View Locations';
    viewRoutesBtn.classList.toggle('active', visible);
}

function renderSpawnList() {
    spawnList.innerHTML = '';
    spawnPoints.forEach((pt, idx) => {
        const li = document.createElement('li');

        const label = document.createElement('span');
        label.textContent = `#${idx + 1}: ${pt.x.toFixed(2)}, ${pt.y.toFixed(2)}, ${pt.z.toFixed(2)}, h${pt.w.toFixed(1)}`;
        li.appendChild(label);

        const del = document.createElement('button');
        del.type = 'button';
        del.textContent = 'Remove';
        del.className = 'delete-btn';
        del.addEventListener('click', () => {
            spawnPoints.splice(idx, 1);
            renderSpawnList();
            refreshFormState();
        });
        li.appendChild(del);

        spawnList.appendChild(li);
    });
    spawnCountLabel.textContent = spawnPoints.length;
    spawnMinLabel.textContent = minSpawnPoints;
}

// ---------------------------------------------------------------------
// Vehicle class dropdown + lot vehicle picker
//
// The class list/grid comes straight from QBCore.Shared.Vehicles (see
// client.lua BuildVehicleCatalog), so it always matches what's actually
// spawnable/ownable on this server. Vehicle pictures are resolved the
// same way mnc-tradingcards' card creator resolves a card's vehicle
// image: try the FiveM docs CDN, then any configured GitHub image
// stores, in order, until one actually loads (see modelImgCandidates /
// attachImgFallback below).
// ---------------------------------------------------------------------
const DEFAULT_IMAGE_SOURCES = { fivem: 'https://docs.fivem.net/vehicles/{model}.webp' };
const DEFAULT_IMAGE_SOURCE_ORDER = ['fivem'];

function getImageSources() {
    return imageSources || DEFAULT_IMAGE_SOURCES;
}

function getImageSourceOrder() {
    return (imageSourceOrder && imageSourceOrder.length) ? imageSourceOrder : DEFAULT_IMAGE_SOURCE_ORDER;
}

// Every URL worth trying, in order, for a given vehicle model.
function modelImgCandidates(model) {
    if (!model) return [];
    const sources = getImageSources();
    const urls = [];
    getImageSourceOrder().forEach((key) => {
        const tpl = sources[key];
        if (!tpl) return;
        urls.push(tpl.split('{model}').join(model));
        // The FiveM docs CDN also serves a plain .png at the same path - worth a second try
        // before moving on to the next source.
        if (key === 'fivem' && tpl.indexOf('.webp') !== -1) {
            urls.push(tpl.split('{model}').join(model).replace(/\.webp$/, '.png'));
        }
    });
    return urls;
}

// Wires an <img> to walk modelImgCandidates(model) on each load failure, finally swapping in a
// "No image" placeholder if every source 404s.
function attachImgFallback(img, model) {
    const candidates = modelImgCandidates(model);
    img.dataset.srcIdx = '0';
    img.src = candidates[0] || '';
    img.addEventListener('error', function onError() {
        const idx = parseInt(img.dataset.srcIdx, 10) + 1;
        if (idx >= candidates.length) {
            img.removeEventListener('error', onError);
            const thumb = img.parentElement;
            if (thumb) {
                thumb.classList.add('broken');
                thumb.innerHTML = '';
                const ph = document.createElement('span');
                ph.className = 'gallery-thumb-placeholder';
                ph.textContent = 'No image';
                thumb.appendChild(ph);
            }
            return;
        }
        img.dataset.srcIdx = String(idx);
        img.src = candidates[idx];
    });
}

// Turns a slug like "sportsclassics" or a bare model like "sabre_gt2" into "Sports Classics" /
// "Sabre Gt2" for display.
function prettifyWords(value) {
    const words = String(value).replace(/[_-]+/g, ' ').trim();
    if (!words) return value;
    return words.replace(/\w\S*/g, (w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase());
}

function populateClassSelect(currentValue) {
    classSelect.innerHTML = '';

    const placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.disabled = true;
    placeholder.textContent = 'Select a class...';
    classSelect.appendChild(placeholder);

    let sawCurrent = false;
    vehicleClasses.forEach((cls) => {
        const opt = document.createElement('option');
        opt.value = cls;
        opt.textContent = prettifyWords(cls);
        if (cls === currentValue) sawCurrent = true;
        classSelect.appendChild(opt);
    });

    // Preserve a location's existing class even if it no longer matches any current
    // QBCore.Shared.Vehicles category (e.g. saved before a vehicles.lua edit) - don't silently
    // blank out saved data just because the dropdown can't find a match for it.
    if (currentValue && !sawCurrent) {
        const opt = document.createElement('option');
        opt.value = currentValue;
        opt.textContent = `${currentValue} (not in QBCore.Shared.Vehicles)`;
        classSelect.appendChild(opt);
    }

    classSelect.value = currentValue || '';
    placeholder.selected = !currentValue;
    browseVehiclesBtn.disabled = !currentValue;
}

function syncVehiclesField() {
    vehiclesField.value = selectedVehicles.map((v) => v.model).join(', ');
}

function renderVehicleChips() {
    vehicleChipList.innerHTML = '';

    selectedVehicles.forEach((v, idx) => {
        const li = document.createElement('li');

        const label = document.createElement('span');
        label.textContent = v.label;
        li.appendChild(label);

        const del = document.createElement('button');
        del.type = 'button';
        del.textContent = 'Remove';
        del.className = 'delete-btn';
        del.addEventListener('click', () => {
            selectedVehicles.splice(idx, 1);
            renderVehicleChips();
            syncGalleryGridSelection();
            refreshFormState();
        });
        li.appendChild(del);

        vehicleChipList.appendChild(li);
    });

    if (selectedVehicles.length === 0) {
        const li = document.createElement('li');
        li.className = 'chip-list-empty';
        li.textContent = 'No vehicles added yet - browse vehicles below.';
        vehicleChipList.appendChild(li);
    }

    syncVehiclesField();
}

function isVehicleSelected(model) {
    return selectedVehicles.some((v) => v.model.toLowerCase() === model.toLowerCase());
}

function toggleVehicleSelection(model, label) {
    vehiclesNote.textContent = '';
    const idx = selectedVehicles.findIndex((v) => v.model.toLowerCase() === model.toLowerCase());
    if (idx === -1) {
        selectedVehicles.push({ model, label: label || prettifyWords(model) });
    } else {
        selectedVehicles.splice(idx, 1);
    }
    renderVehicleChips();
    refreshFormState();
}

function renderGalleryGrid(list) {
    galleryGrid.innerHTML = '';

    if (!list || list.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'gallery-empty';
        empty.textContent = 'No vehicles found for this class in QBCore.Shared.Vehicles. Add one by spawn name below.';
        galleryGrid.appendChild(empty);
        return;
    }

    list.forEach((entry) => {
        const item = document.createElement('div');
        item.className = 'gallery-item' + (isVehicleSelected(entry.model) ? ' selected' : '');
        item.dataset.search = `${entry.label} ${entry.model}`.toLowerCase();
        item.dataset.model = entry.model;

        const thumb = document.createElement('div');
        thumb.className = 'gallery-thumb';
        const img = document.createElement('img');
        img.loading = 'lazy';
        img.alt = entry.label;
        attachImgFallback(img, entry.model);
        thumb.appendChild(img);

        const check = document.createElement('span');
        check.className = 'gallery-item-check';
        check.textContent = '✓';
        thumb.appendChild(check);

        const label = document.createElement('div');
        label.className = 'gallery-item-label';
        label.textContent = entry.label;
        label.title = entry.model;

        item.appendChild(thumb);
        item.appendChild(label);

        item.addEventListener('click', () => {
            toggleVehicleSelection(entry.model, entry.label);
            item.classList.toggle('selected', isVehicleSelected(entry.model));
            gallerySelectedCount.textContent = `${selectedVehicles.length} selected`;
        });

        galleryGrid.appendChild(item);
    });
}

// Keeps the grid's highlighted state in sync after a chip is removed directly from the form
// (rather than by clicking its thumbnail again) while the gallery is still open.
function syncGalleryGridSelection() {
    if (vehicleGallery.classList.contains('hidden')) return;
    Array.prototype.forEach.call(galleryGrid.querySelectorAll('.gallery-item'), (item) => {
        item.classList.toggle('selected', isVehicleSelected(item.dataset.model));
    });
    gallerySelectedCount.textContent = `${selectedVehicles.length} selected`;
}

function filterGallery(query) {
    const q = query.trim().toLowerCase();
    Array.prototype.forEach.call(galleryGrid.querySelectorAll('.gallery-item'), (el) => {
        el.classList.toggle('hidden', !!q && el.dataset.search.indexOf(q) === -1);
    });
}

function openVehicleGallery() {
    const cls = classSelect.value;
    if (!cls) return;

    galleryClassChip.textContent = prettifyWords(cls);
    gallerySubtitle.textContent = 'Click a vehicle to add or remove it from this location\'s lot.';
    galleryFilter.value = '';
    renderGalleryGrid(vehiclesByClass[cls] || []);
    gallerySelectedCount.textContent = `${selectedVehicles.length} selected`;
    vehicleGallery.classList.remove('hidden');
    setTimeout(() => galleryFilter.focus(), 0);
}

function closeVehicleGallery() {
    vehicleGallery.classList.add('hidden');
}

browseVehiclesBtn.addEventListener('click', openVehicleGallery);
galleryCloseBtn.addEventListener('click', closeVehicleGallery);
galleryDoneBtn.addEventListener('click', closeVehicleGallery);
galleryFilter.addEventListener('input', () => filterGallery(galleryFilter.value));
vehicleGallery.addEventListener('click', (e) => {
    if (e.target === vehicleGallery) closeVehicleGallery();
});

galleryCustomAddBtn.addEventListener('click', () => {
    const raw = galleryCustomInput.value.trim().toLowerCase();
    if (!raw) return;
    if (!isVehicleSelected(raw)) {
        toggleVehicleSelection(raw, prettifyWords(raw));
    }
    galleryCustomInput.value = '';
    syncGalleryGridSelection();
    galleryCustomInput.focus();
});
galleryCustomInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        e.preventDefault();
        galleryCustomAddBtn.click();
    }
});

classSelect.addEventListener('change', () => {
    browseVehiclesBtn.disabled = !classSelect.value;
    if (selectedVehicles.length > 0) {
        selectedVehicles = [];
        renderVehicleChips();
        vehiclesNote.textContent = 'Lot vehicles were cleared because the class changed - browse vehicles again for the new class.';
    }
    refreshFormState();
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !vehicleGallery.classList.contains('hidden')) {
        closeVehicleGallery();
    }
});

// start/finish/radius/vehicles only - label, class, buy-ins, time and spawns are deliberately
// excluded, since none of them change what a test drive would measure
function getFormSnapshot() {
    return [
        'sx', document.getElementById('f_start_x').value,
        'sy', document.getElementById('f_start_y').value,
        'sz', document.getElementById('f_start_z').value,
        'sw', document.getElementById('f_start_w').value,
        'fx', document.getElementById('f_finish_x').value,
        'fy', document.getElementById('f_finish_y').value,
        'fz', document.getElementById('f_finish_z').value,
        'r', document.getElementById('f_radius').value,
        'v', document.getElementById('f_vehicles').value.trim().toLowerCase(),
    ].join('|');
}

function canStartTestDrive() {
    const startOk = ['f_start_x', 'f_start_y', 'f_start_z', 'f_start_w'].every((id) => document.getElementById(id).value !== '');
    const finishOk = ['f_finish_x', 'f_finish_y', 'f_finish_z'].every((id) => document.getElementById(id).value !== '');
    const radius = parseFloat(document.getElementById('f_radius').value);
    const vehicles = document.getElementById('f_vehicles').value.trim();
    return startOk && finishOk && radius > 0 && vehicles !== '';
}

function isTimeValid() {
    return timedSnapshot !== null && timedSnapshot === getFormSnapshot() && document.getElementById('f_time').value !== '';
}

function refreshFormState() {
    const timeValid = isTimeValid();
    const spawnsValid = spawnPoints.length >= minSpawnPoints;
    saveBtn.disabled = !(timeValid && spawnsValid);

    const canDrive = canStartTestDrive();
    startTestDriveBtn.disabled = !canDrive;
    startTestDriveBtn.title = canDrive ? '' : 'Fill in start, finish, radius and vehicles first';

    if (timerNote) {
        if (!canDrive) {
            timerNote.textContent = 'Fill in start, finish, radius and vehicles, then drive the route to set the time.';
        } else if (!timeValid) {
            timerNote.textContent = document.getElementById('f_time').value !== ''
                ? 'Route changed since it was timed - drive it again before saving.'
                : 'Drive the route to set the race time before saving.';
        } else {
            timerNote.textContent = 'Time limit set. Change start/finish/radius/vehicles and you will need to drive it again.';
        }
    }

    if (spawnNote) {
        spawnNote.textContent = spawnsValid ? '' : `Add at least ${minSpawnPoints} spawn points before saving.`;
    }
    spawnCountLabel.textContent = spawnPoints.length;
    spawnMinLabel.textContent = minSpawnPoints;
}

['f_start_x', 'f_start_y', 'f_start_z', 'f_start_w', 'f_finish_x', 'f_finish_y', 'f_finish_z', 'f_radius', 'f_vehicles'].forEach((id) => {
    document.getElementById(id).addEventListener('input', refreshFormState);
});

function resetSetupForm() {
    setupForm.reset();
    document.getElementById('f_radius').value = 10;
    document.getElementById('f_time').value = '';
    spawnPoints = [];
    renderSpawnList();

    populateClassSelect('');
    selectedVehicles = [];
    renderVehicleChips();
    vehiclesNote.textContent = '';

    editingDbId = null;
    editingConfigIndex = null;
    editingBanner.classList.add('hidden');
    saveBtn.textContent = 'Save location';
    timedSnapshot = null;
    refreshFormState();
}

function startEditing(loc) {
    document.getElementById('f_label').value = loc.label || '';

    populateClassSelect(loc.class || '');
    const knownForClass = vehiclesByClass[loc.class] || [];
    selectedVehicles = (loc.vehicles || []).map((model) => {
        const known = knownForClass.find((v) => v.model.toLowerCase() === model.toLowerCase());
        return { model, label: known ? known.label : prettifyWords(model) };
    });
    renderVehicleChips();
    vehiclesNote.textContent = '';

    document.getElementById('f_start_x').value = loc.start.x.toFixed(2);
    document.getElementById('f_start_y').value = loc.start.y.toFixed(2);
    document.getElementById('f_start_z').value = loc.start.z.toFixed(2);
    document.getElementById('f_start_w').value = loc.start.w.toFixed(2);
    document.getElementById('f_finish_x').value = loc.finish.x.toFixed(2);
    document.getElementById('f_finish_y').value = loc.finish.y.toFixed(2);
    document.getElementById('f_finish_z').value = loc.finish.z.toFixed(2);
    document.getElementById('f_radius').value = loc.radius;
    document.getElementById('f_time').value = loc.time;
    document.getElementById('f_buyin_pinkslip').value = loc.buyInPinkslip;
    document.getElementById('f_buyin_pot').value = loc.buyInPot;

    spawnPoints = (loc.spawns || []).map((s) => ({ x: s.x, y: s.y, z: s.z, w: s.w }));
    renderSpawnList();

    editingDbId = loc.dbId != null ? loc.dbId : null;
    editingConfigIndex = loc.configIndex != null ? loc.configIndex : null;

    editingLabel.textContent = routeDisplayLabel(loc);
    editingBanner.classList.remove('hidden');
    saveBtn.textContent = 'Update location';

    timedSnapshot = getFormSnapshot();
    refreshFormState();
}

function applyCoordsToTarget(target, coords) {
    if (target === 'start') {
        document.getElementById('f_start_x').value = coords.x.toFixed(2);
        document.getElementById('f_start_y').value = coords.y.toFixed(2);
        document.getElementById('f_start_z').value = coords.z.toFixed(2);
        document.getElementById('f_start_w').value = coords.w.toFixed(2);
    } else if (target === 'finish') {
        document.getElementById('f_finish_x').value = coords.x.toFixed(2);
        document.getElementById('f_finish_y').value = coords.y.toFixed(2);
        document.getElementById('f_finish_z').value = coords.z.toFixed(2);
    } else if (target === 'spawnpoint') {
        spawnPoints.push({ x: coords.x, y: coords.y, z: coords.z, w: coords.w });
        renderSpawnList();
    }
}

document.querySelectorAll('.pos-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        const target = btn.dataset.target;
        nuiPost('setupUseMyPosition')
            .then((r) => r.json())
            .then((coords) => {
                if (!coords) return;
                applyCoordsToTarget(target, coords);
                refreshFormState();
            })
            .catch(() => {});
    });
});

document.querySelectorAll('.placement-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        const target = btn.dataset.target;
        const firstVehicle = (document.getElementById('f_vehicles').value || '').split(',')[0].trim();
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
        start: {
            x: parseFloat(document.getElementById('f_start_x').value),
            y: parseFloat(document.getElementById('f_start_y').value),
            z: parseFloat(document.getElementById('f_start_z').value),
            w: parseFloat(document.getElementById('f_start_w').value),
        },
        finish: {
            x: parseFloat(document.getElementById('f_finish_x').value),
            y: parseFloat(document.getElementById('f_finish_y').value),
            z: parseFloat(document.getElementById('f_finish_z').value),
        },
        radius: parseFloat(document.getElementById('f_radius').value),
        vehicles: document.getElementById('f_vehicles').value,
    };
    setupPanel.classList.add('hidden');
    nuiPost('setupStartTestDrive', payload).catch(() => {});
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !setupPanel.classList.contains('hidden') && vehicleGallery.classList.contains('hidden')) {
        closeSetup();
    }
});

setupForm.addEventListener('submit', (e) => {
    e.preventDefault();
    if (!isTimeValid() || spawnPoints.length < minSpawnPoints) {
        refreshFormState();
        return;
    }
    const payload = {
        label: document.getElementById('f_label').value,
        class: document.getElementById('f_class').value,
        start: {
            x: parseFloat(document.getElementById('f_start_x').value),
            y: parseFloat(document.getElementById('f_start_y').value),
            z: parseFloat(document.getElementById('f_start_z').value),
            w: parseFloat(document.getElementById('f_start_w').value),
        },
        finish: {
            x: parseFloat(document.getElementById('f_finish_x').value),
            y: parseFloat(document.getElementById('f_finish_y').value),
            z: parseFloat(document.getElementById('f_finish_z').value),
        },
        radius: parseFloat(document.getElementById('f_radius').value),
        timeLimit: parseInt(document.getElementById('f_time').value, 10),
        vehicles: document.getElementById('f_vehicles').value,
        buyInPinkslip: parseInt(document.getElementById('f_buyin_pinkslip').value, 10),
        buyInPot: parseInt(document.getElementById('f_buyin_pot').value, 10),
        spawns: spawnPoints,
        dbId: editingDbId,
        configIndex: editingConfigIndex,
    };
    nuiPost('setupSaveLocation', payload).catch(() => {});
    resetSetupForm();
});

// ---------------------------------------------------------------------
// Incoming messages
// ---------------------------------------------------------------------
window.addEventListener('message', (event) => {
    const data = event.data || {};

    switch (data.action) {
        case 'playSound':
            playSound(data.category, data.index);
            break;

        case 'showRaceHUD':
            showRaceHUD(data.raceType, data.stakeLabel, data.timeLimit);
            break;
        case 'updateRaceHUD':
            updateRaceHUD(data.timeRemaining);
            break;
        case 'hideRaceHUD':
            hideRaceHUD();
            break;
        case 'raceCountdown':
            showRaceCountdown(data.value);
            break;

        case 'openMenu':
            renderMenu(data.data);
            pinkslipMenu.classList.remove('hidden');
            break;
        case 'updateStock':
            renderStockList(data.stock);
            break;
        case 'closeMenu':
            pinkslipMenu.classList.add('hidden');
            break;

        case 'openSetup':
            minSpawnPoints = data.minSpawnPoints || minSpawnPoints;
            vehicleClasses = data.vehicleClasses || [];
            vehiclesByClass = data.vehiclesByClass || {};
            imageSources = data.imageSources || null;
            imageSourceOrder = data.imageSourceOrder || null;

            populateClassSelect('');
            selectedVehicles = [];
            renderVehicleChips();
            closeVehicleGallery();

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
                applyCoordsToTarget(data.target, data.result);
                refreshFormState();
            }
            break;
    }
});