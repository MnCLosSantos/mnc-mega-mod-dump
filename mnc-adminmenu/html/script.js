'use strict';

// ── State ──────────────────────────────────────
let allJobs           = [];
let allGarages        = [];   // [{ name, label }] — public garages from qb-garages
let currentMode       = 'admin'; // 'admin' | 'player'
let currentLookupCid  = null;
let currentMoneyCid   = null;
let currentVehicleCid = null;
let currentVehiclePlate = null;
let currentInvCid     = null;
let allInvItems       = [];
let ppSelectedPlate   = null;

// Image sources — same order as valet.js
const ImagePaths = [
    'https://docs.fivem.net/vehicles/{model}.webp',
    'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
];

// ── NUI Message Handler ───────────────────────
window.addEventListener('message', (e) => {
    const data = e.data;
    switch (data.action) {

        case 'setMode':
            currentMode = data.mode || 'admin';
            applyMode();
            break;

        case 'open':
            if (currentMode === 'player') {
                document.getElementById('player-panel').classList.remove('hidden');
                loadOwnVehicles();
            } else {
                document.getElementById('overlay').classList.remove('hidden');
            }
            break;

        case 'close':
            document.getElementById('overlay').classList.add('hidden');
            document.getElementById('player-panel').classList.add('hidden');
            break;

        case 'setJobs':
            allJobs = data.jobs || [];
            populateJobSelect('self-job');
            populateJobSelect('sp-job');
            break;

        case 'setGarages':
            allGarages = data.garages || [];
            populateGarageSelects();
            break;

        case 'setPlayerJobs':
            renderPlayerJobs(data.citizenid, data.jobs);
            break;

        case 'setPlayerMoney':
            renderPlayerMoney(data.citizenid, data.money);
            break;

        case 'setPlayerVehicles':
            renderPlayerVehicles(data.citizenid, data.vehicles);
            break;

        case 'setOwnVehicles':
            renderPlayerOwnVehicles(data.vehicles);
            break;

        case 'setPlayerInventory':
            renderInventory(data.citizenid, data.items);
            break;
    }
});

// ── Mode ──────────────────────────────────────
function applyMode() {
    const isAdmin = currentMode === 'admin';
    document.getElementById('tabs').style.display         = isAdmin ? '' : 'none';
    document.getElementById('header-title').textContent   = isAdmin ? 'Admin Panel' : 'Move Vehicle';
}

// ── Tab Switching ─────────────────────────────
document.querySelectorAll('.tab').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
    });
});

// ── Close ─────────────────────────────────────
function closeMenu() {
    fetch(`https://mnc-adminmenu/close`, { method: 'POST', body: JSON.stringify({}) });
}
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeMenu(); });

// ── Garage Selects ────────────────────────────
function populateGarageSelects() {
    const ids = ['veh-modal-garage-select', 'pp-garage-select'];
    ids.forEach(id => {
        const sel = document.getElementById(id);
        if (!sel) return;
        sel.innerHTML = '<option value="">-- Select Garage --</option>';
        allGarages.forEach(g => {
            const opt = document.createElement('option');
            opt.value       = g.name;
            opt.textContent = g.label;
            sel.appendChild(opt);
        });
    });
}

// ── Job Select Population ─────────────────────
function populateJobSelect(selectId) {
    const sel = document.getElementById(selectId);
    sel.innerHTML = '<option value="">-- Select Job --</option>';
    allJobs.forEach(j => {
        const opt = document.createElement('option');
        opt.value       = j.name;
        opt.textContent = j.label + ' [' + j.name + ']';
        sel.appendChild(opt);
    });
}

function populateGradeSelect(selectId, jobName) {
    const sel = document.getElementById(selectId);
    sel.innerHTML = '<option value="">-- Select Grade --</option>';
    const job = allJobs.find(j => j.name === jobName);
    if (!job) return;
    job.grades.forEach(g => {
        const opt = document.createElement('option');
        opt.value       = g.grade;
        opt.textContent = g.grade + ' – ' + g.label;
        sel.appendChild(opt);
    });
    if (sel.options.length > 1) sel.selectedIndex = 1;
}

// ── Set My Job ────────────────────────────────
function populateSelfGrades() { populateGradeSelect('self-grade', document.getElementById('self-job').value); }

function setSelfJob() {
    const job   = document.getElementById('self-job').value;
    const grade = document.getElementById('self-grade').value;
    if (!job || grade === '') return;
    fetch(`https://mnc-adminmenu/setSelfJob`, { method: 'POST', body: JSON.stringify({ job, grade }) });
}

// ── Set Player Job ────────────────────────────
function populateSpGrades() { populateGradeSelect('sp-grade', document.getElementById('sp-job').value); }

function setPlayerJob() {
    const citizenid = document.getElementById('sp-cid').value.trim();
    const job       = document.getElementById('sp-job').value;
    const grade     = document.getElementById('sp-grade').value;
    if (!citizenid || !job || grade === '') return;
    fetch(`https://mnc-adminmenu/setPlayerJob`, { method: 'POST', body: JSON.stringify({ citizenid, job, grade }) });
}

// ── Player Job Lookup / Remove ────────────────
function lookupPlayer() {
    const cid = document.getElementById('lookup-cid').value.trim();
    if (!cid) return;
    currentLookupCid = cid;
    document.getElementById('lookup-result').classList.add('hidden');
    document.getElementById('lookup-notfound').classList.add('hidden');
    fetch(`https://mnc-adminmenu/lookupPlayer`, { method: 'POST', body: JSON.stringify({ citizenid: cid }) });
}

function renderPlayerJobs(citizenid, jobs) {
    if (!jobs) {
        document.getElementById('lookup-notfound').classList.remove('hidden');
        return;
    }
    currentLookupCid = citizenid;
    document.getElementById('lookup-info').innerHTML = 'Citizen ID: <span>' + escHtml(citizenid) + '</span>';
    const jobsContainer = document.getElementById('lookup-jobs');
    jobsContainer.innerHTML = '';

    if (jobs.length === 0) {
        jobsContainer.innerHTML = '<span class="dim">No jobs found (unemployed).</span>';
    } else {
        jobs.forEach(j => {
            const row = document.createElement('div');
            row.className = 'job-row';
            const onlineBadge = j.online ? '<span class="online-badge">ONLINE</span>' : '';
            const activeBadge = j.active
                ? '<span class="active-badge">ACTIVE</span>'
                : '<span class="multi-badge">MULTIJOB</span>';
            row.innerHTML = `
                <div class="job-row-info">
                    <div class="job-row-name">${escHtml(j.label)} ${activeBadge} ${onlineBadge}</div>
                    <div class="job-row-grade">Grade ${j.grade} – ${escHtml(j.grade_label)} &nbsp;·&nbsp; <span style="color:var(--text-dim)">${escHtml(j.name)}</span></div>
                </div>
                <button class="btn-remove-job" onclick="removeJob('${escHtml(j.name)}')">Remove</button>
            `;
            jobsContainer.appendChild(row);
        });
    }
    document.getElementById('lookup-result').classList.remove('hidden');
}

function removeJob(jobName) {
    if (!currentLookupCid) return;
    fetch(`https://mnc-adminmenu/removePlayerJob`, { method: 'POST', body: JSON.stringify({ citizenid: currentLookupCid, job: jobName }) });
    setTimeout(() => lookupPlayer(), 300);
}

function removeAllJobs() {
    if (!currentLookupCid) return;
    fetch(`https://mnc-adminmenu/removeAllPlayerJobs`, { method: 'POST', body: JSON.stringify({ citizenid: currentLookupCid }) });
    document.getElementById('lookup-result').classList.add('hidden');
    document.getElementById('lookup-jobs').innerHTML = '';
}

// ═══════════════════════════════════════════════
//  MONEY
// ═══════════════════════════════════════════════
function lookupMoney() {
    const cid = document.getElementById('money-cid').value.trim();
    if (!cid) return;
    currentMoneyCid = cid;
    document.getElementById('money-result').classList.add('hidden');
    document.getElementById('money-notfound').classList.add('hidden');
    fetch(`https://mnc-adminmenu/lookupMoney`, { method: 'POST', body: JSON.stringify({ citizenid: cid }) });
}

function renderPlayerMoney(citizenid, money) {
    if (!money) {
        document.getElementById('money-notfound').classList.remove('hidden');
        return;
    }
    currentMoneyCid = citizenid;
    document.getElementById('money-info').innerHTML = 'Citizen ID: <span>' + escHtml(citizenid) + '</span>';
    document.getElementById('display-cash').textContent = '$' + fmtNum(money.cash);
    document.getElementById('display-bank').textContent = '$' + fmtNum(money.bank);
    document.getElementById('money-result').classList.remove('hidden');
}

function adjustMoney(mode) {
    if (!currentMoneyCid) return;
    const moneytype = document.getElementById('money-type').value;
    const amount    = parseFloat(document.getElementById('money-amount').value);
    if (isNaN(amount) || amount < 0) return;
    const actionMap = { add: 'addMoney', remove: 'removeMoney', set: 'setMoney' };
    fetch(`https://mnc-adminmenu/${actionMap[mode]}`, {
        method: 'POST',
        body: JSON.stringify({ citizenid: currentMoneyCid, moneytype, amount })
    });
    setTimeout(() => {
        fetch(`https://mnc-adminmenu/lookupMoney`, {
            method: 'POST',
            body: JSON.stringify({ citizenid: currentMoneyCid })
        });
    }, 400);
}

// ═══════════════════════════════════════════════
//  ADMIN VEHICLES
// ═══════════════════════════════════════════════
function lookupVehicles() {
    const cid = document.getElementById('veh-cid').value.trim();
    if (!cid) return;
    currentVehicleCid = cid;
    document.getElementById('veh-result').classList.add('hidden');
    document.getElementById('veh-notfound').classList.add('hidden');
    fetch(`https://mnc-adminmenu/lookupVehicles`, { method: 'POST', body: JSON.stringify({ citizenid: cid }) });
}

function renderPlayerVehicles(citizenid, vehicles) {
    currentVehicleCid = citizenid;
    if (!vehicles || vehicles.length === 0) {
        document.getElementById('veh-notfound').classList.remove('hidden');
        return;
    }
    document.getElementById('veh-info').innerHTML =
        'Citizen ID: <span>' + escHtml(citizenid) + '</span>' +
        ' &nbsp;·&nbsp; <span>' + vehicles.length + ' vehicle' + (vehicles.length !== 1 ? 's' : '') + '</span>';

    const list = document.getElementById('veh-list');
    list.innerHTML = '';

    vehicles.forEach(v => {
        const card = document.createElement('div');
        card.className = 'veh-card';
        const stateLabel = v.state === 0
            ? '<span class="veh-badge-out">OUT</span>'
            : '<span class="veh-badge-in">GARAGED</span>';
        const enginePct = Math.round((v.engine / 1000) * 100);
        const bodyPct   = Math.round((v.body   / 1000) * 100);
        const fuelPct   = Math.min(100, Math.round(v.fuel));

        card.innerHTML = `
            <div class="veh-card-img-wrap">
                <img class="veh-card-img" alt="${escHtml(v.label)}" />
            </div>
            <div class="veh-card-body">
                <div class="veh-card-name">${escHtml(v.label)} ${stateLabel}</div>
                <div class="veh-card-plate">${escHtml(v.plate)}</div>
                <div class="veh-card-model dim">${escHtml(v.model)}</div>
                <div class="veh-card-garage dim">${escHtml(v.garage)}</div>
                <div class="veh-bars">
                    ${miniBar('ENG',  enginePct, 'var(--accent-blue)')}
                    ${miniBar('BODY', bodyPct,   'var(--accent-purple)')}
                    ${miniBar('FUEL', fuelPct,   'var(--accent-green)')}
                </div>
            </div>
            <button class="veh-card-btn" onclick="openVehModal(${JSON.stringify(v).split('"').join('&quot;')})">Manage</button>
        `;

        loadVehicleImage(card.querySelector('.veh-card-img'), card.querySelector('.veh-card-img-wrap'), v.model);
        list.appendChild(card);
    });

    document.getElementById('veh-result').classList.remove('hidden');
}

function miniBar(label, pct, color) {
    const clamped  = Math.max(0, Math.min(100, pct));
    const barColor = clamped < 25 ? 'var(--accent-red)' : clamped < 60 ? 'var(--accent-yellow)' : color;
    return `<div class="mini-bar-wrap">
        <span class="mini-bar-label">${label}</span>
        <div class="mini-bar-track"><div class="mini-bar-fill" style="width:${clamped}%;background:${barColor}"></div></div>
        <span class="mini-bar-pct">${clamped}%</span>
    </div>`;
}

// ── Image loading — matches valet.js exactly ──
function loadVehicleImage(img, wrap, model) {
    const m = (model || '').toLowerCase();
    let attempt = 0;

    img.style.display = 'none';
    if (wrap) wrap.classList.remove('loaded', 'img-failed');

    function tryNext() {
        if (attempt >= ImagePaths.length) {
            if (wrap) wrap.classList.add('loaded', 'img-failed');
            return;
        }
        img.src = ImagePaths[attempt].replace('{model}', m);
    }

    img.onerror = function () { attempt++; tryNext(); };
    img.onload  = function () {
        img.style.display = 'block';
        if (wrap) wrap.classList.add('loaded');
    };

    tryNext();
}

// ── Admin Vehicle Modal ────────────────────────
let _modalVehicle = null;

function openVehModal(v) {
    _modalVehicle       = v;
    currentVehiclePlate = v.plate;

    document.getElementById('veh-modal-title').textContent = v.label;

    const sel = document.getElementById('veh-modal-garage-select');
    sel.value = v.garage || '';

    const img = document.getElementById('veh-modal-img');
    img.alt = v.label;
    loadVehicleImage(img, null, v.model);

    const enginePct = Math.round((v.engine / 1000) * 100);
    const bodyPct   = Math.round((v.body   / 1000) * 100);
    const fuelPct   = Math.min(100, Math.round(v.fuel));
    const stateStr  = v.state === 0 ? 'Out / Spawned' : 'In Garage';

    document.getElementById('veh-modal-stats').innerHTML = `
        <div class="modal-stat-row"><span>Plate</span><span>${escHtml(v.plate)}</span></div>
        <div class="modal-stat-row"><span>Model</span><span>${escHtml(v.model)}</span></div>
        <div class="modal-stat-row"><span>Garage</span><span>${escHtml(v.garage || '—')}</span></div>
        <div class="modal-stat-row"><span>State</span><span>${stateStr}</span></div>
        <div class="modal-stat-row"><span>Engine</span><span>${enginePct}%</span></div>
        <div class="modal-stat-row"><span>Body</span><span>${bodyPct}%</span></div>
        <div class="modal-stat-row"><span>Fuel</span><span>${fuelPct}%</span></div>
    `;

    document.getElementById('veh-modal').classList.remove('hidden');
}

function closeVehModal() {
    document.getElementById('veh-modal').classList.add('hidden');
    _modalVehicle       = null;
    currentVehiclePlate = null;
}

function moveVehicleGarage() {
    if (!currentVehiclePlate) return;
    const garage = document.getElementById('veh-modal-garage-select').value;
    if (!garage) return;
    fetch(`https://mnc-adminmenu/setVehicleGarage`, {
        method: 'POST',
        body: JSON.stringify({ plate: currentVehiclePlate, garage })
    });
    closeVehModal();
    setTimeout(() => lookupVehicles(), 400);
}

function deleteVehicle() {
    if (!currentVehiclePlate) return;
    fetch(`https://mnc-adminmenu/deleteVehicle`, {
        method: 'POST',
        body: JSON.stringify({ plate: currentVehiclePlate })
    });
    closeVehModal();
    setTimeout(() => lookupVehicles(), 400);
}

// ═══════════════════════════════════════════════
//  INVENTORY
// ═══════════════════════════════════════════════
function lookupInventory(cidOverride) {
    const cid = cidOverride || document.getElementById('inv-cid').value.trim();
    if (!cid) return;
    currentInvCid = cid;
    document.getElementById('inv-result').classList.add('hidden');
    document.getElementById('inv-notfound').classList.add('hidden');
    if (!cidOverride) document.getElementById('inv-search').value = '';
    fetch(`https://mnc-adminmenu/lookupInventory`, { method: 'POST', body: JSON.stringify({ citizenid: cid }) });
}

function renderInventory(citizenid, items) {
    if (!items || items.length === 0) {
        document.getElementById('inv-notfound').classList.remove('hidden');
        document.getElementById('inv-result').classList.add('hidden');
        return;
    }
    currentInvCid = citizenid;
    allInvItems   = items;
    document.getElementById('inv-info').innerHTML =
        'Citizen ID: <span>' + escHtml(citizenid) + '</span>' +
        ' &nbsp;·&nbsp; <span>' + items.length + ' item type' + (items.length !== 1 ? 's' : '') + '</span>';
    renderInvList(items);
    document.getElementById('inv-result').classList.remove('hidden');
    document.getElementById('inv-notfound').classList.add('hidden');
}

function renderInvList(items) {
    const list = document.getElementById('inv-list');
    list.innerHTML = '';
    items.forEach(item => {
        const row = document.createElement('div');
        row.className = 'inv-row';
        // Give each row a stable id so we can update it in place
        row.id = 'inv-row-' + item.name.replace(/[^a-z0-9]/gi, '_');
        row.innerHTML = `
            <div class="inv-row-name">${escHtml(item.label)}</div>
            <div class="inv-row-sub">${escHtml(item.name)}</div>
            <div class="inv-row-amount" id="inv-amt-${escHtml(item.name.replace(/[^a-z0-9]/gi, '_'))}">×${item.amount}</div>
            <button class="btn-remove-inv" onclick="removeInvItem('${escHtml(item.name)}')">−1</button>
            <button class="btn-remove-all-inv" onclick="removeAllInvItem('${escHtml(item.name)}', ${item.amount})">All</button>
        `;
        list.appendChild(row);
    });
}

function removeInvItem(itemName) {
    if (!currentInvCid) return;
    fetch(`https://mnc-adminmenu/removeInventoryItem`, {
        method: 'POST',
        body: JSON.stringify({ citizenid: currentInvCid, item: itemName, amount: 1 })
    });
    // Update local cache and re-render — no server refresh so the UI can't
    // race back to showing the old amount.
    const cached = allInvItems.find(i => i.name === itemName);
    if (cached) {
        cached.amount -= 1;
        if (cached.amount <= 0) {
            allInvItems = allInvItems.filter(i => i.name !== itemName);
        }
    }
    const q = document.getElementById('inv-search').value.toLowerCase();
    const filtered = q
        ? allInvItems.filter(i => i.label.toLowerCase().includes(q) || i.name.toLowerCase().includes(q))
        : allInvItems;
    renderInvList(filtered);
    updateInvHeader();
}

function removeAllInvItem(itemName, amount) {
    if (!currentInvCid) return;
    fetch(`https://mnc-adminmenu/removeInventoryItem`, {
        method: 'POST',
        body: JSON.stringify({ citizenid: currentInvCid, item: itemName, amount: amount })
    });
    allInvItems = allInvItems.filter(i => i.name !== itemName);
    const q = document.getElementById('inv-search').value.toLowerCase();
    const filtered = q
        ? allInvItems.filter(i => i.label.toLowerCase().includes(q) || i.name.toLowerCase().includes(q))
        : allInvItems;
    renderInvList(filtered);
    updateInvHeader();
}

function updateInvHeader() {
    const count = allInvItems.length;
    document.getElementById('inv-info').innerHTML =
        'Citizen ID: <span>' + escHtml(currentInvCid) + '</span>' +
        ' &nbsp;·&nbsp; <span>' + count + ' item type' + (count !== 1 ? 's' : '') + '</span>';
    if (count === 0) {
        document.getElementById('inv-result').classList.add('hidden');
        document.getElementById('inv-notfound').classList.remove('hidden');
    }
}

function filterInventory() {
    const q = document.getElementById('inv-search').value.toLowerCase();
    renderInvList(allInvItems.filter(i =>
        i.label.toLowerCase().includes(q) || i.name.toLowerCase().includes(q)
    ));
}

// ═══════════════════════════════════════════════
//  PLAYER GARAGE (/movegarage)
// ═══════════════════════════════════════════════
function loadOwnVehicles() {
    document.getElementById('pp-loading').style.display = '';
    document.getElementById('pp-vehicles').classList.add('hidden');
    document.getElementById('pp-empty').classList.add('hidden');
    fetch(`https://mnc-adminmenu/lookupOwnVehicles`, { method: 'POST', body: JSON.stringify({}) });
}

function renderPlayerOwnVehicles(vehicles) {
    document.getElementById('pp-loading').style.display = 'none';
    if (!vehicles || vehicles.length === 0) {
        document.getElementById('pp-empty').classList.remove('hidden');
        return;
    }
    const list = document.getElementById('pp-veh-list');
    list.innerHTML = '';
    vehicles.forEach(v => {
        const card = document.createElement('div');
        card.className = 'pp-veh-card';
        const stateLabel = v.state === 0
            ? '<span class="veh-badge-out">OUT</span>'
            : '<span class="veh-badge-in">GARAGED</span>';
        card.innerHTML = `
            <div class="veh-card-img-wrap pp-img-wrap">
                <img class="veh-card-img" alt="${escHtml(v.label)}" />
            </div>
            <div class="veh-card-body">
                <div class="veh-card-name">${escHtml(v.label)} ${stateLabel}</div>
                <div class="veh-card-plate">${escHtml(v.plate)}</div>
                <div class="veh-card-garage dim">${escHtml(v.garage)}</div>
            </div>
            <button class="veh-card-btn" onclick="openPpModal(${JSON.stringify(v).split('"').join('&quot;')})">Move</button>
        `;
        loadVehicleImage(card.querySelector('.veh-card-img'), card.querySelector('.veh-card-img-wrap'), v.model);
        list.appendChild(card);
    });
    document.getElementById('pp-vehicles').classList.remove('hidden');
}

function openPpModal(v) {
    ppSelectedPlate = v.plate;
    document.getElementById('pp-modal-title').textContent = v.label;
    document.getElementById('pp-modal-info').innerHTML =
        '<div class="modal-stat-row"><span>Plate</span><span>' + escHtml(v.plate) + '</span></div>' +
        '<div class="modal-stat-row"><span>Current Garage</span><span>' + escHtml(v.garage || '—') + '</span></div>';
    const sel = document.getElementById('pp-garage-select');
    sel.value = '';
    const img = document.getElementById('pp-modal-img');
    img.alt = v.label;
    loadVehicleImage(img, null, v.model);
    document.getElementById('pp-modal').classList.remove('hidden');
}

function closePpModal() {
    document.getElementById('pp-modal').classList.add('hidden');
    ppSelectedPlate = null;
}

function confirmPlayerMove() {
    if (!ppSelectedPlate) return;
    const garage = document.getElementById('pp-garage-select').value;
    if (!garage) return;
    fetch(`https://mnc-adminmenu/playerMoveVehicle`, {
        method: 'POST',
        body: JSON.stringify({ plate: ppSelectedPlate, garage })
    });
    closePpModal();
    setTimeout(() => loadOwnVehicles(), 600);
}

// ── Util ──────────────────────────────────────
function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function fmtNum(n) {
    return Number(n).toLocaleString('en-US');
}