/* ── State ───────────────────────────────────────────────────────── */
let state = {
    garages:     [],
    vehicles:    {},   // { [job]: [{...}] }
    roles:       [],
    playerRoles: [],
    jobs:        [],   // [{name, label}]
    checkedOut:  {},   // { [job]: { [model]: { playerName } } }  live snapshot
};

let modalSaveFn = null;
let currentTab  = 'garages';

// Registry: onclick handlers pass a key; actual data lives here, never in HTML attributes
const _vehRegistry  = {};   // key = "job::model" → vehicle object
const _roleRegistry = {};   // key = "job::roleName" → role object

// Image path templates (mirrors Config.ImagePaths)
const IMG_PATHS = [
    'https://docs.fivem.net/vehicles/{model}.webp',
    'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
];
const IMG_FALLBACK = './images/fallback.png';

/* ── GTA V colour name lookup (from Config.Paints, indexed by id) ─────────── */
const GTA_COLORS = (() => {
    const map = {};
    const paints = {
        Classic: [
            {id:0,label:'Black'},{id:1,label:'Graphite'},{id:2,label:'Black Steel'},
            {id:3,label:'Dark Steel'},{id:4,label:'Silver'},{id:5,label:'Bluish Silver'},
            {id:6,label:'Rolled Steel'},{id:7,label:'Shadow Silver'},{id:8,label:'Stone Silver'},
            {id:9,label:'Midnight Silver'},{id:10,label:'Cast Iron Silver'},{id:11,label:'Anthracite Black'},
            {id:27,label:'Red'},{id:28,label:'Torino Red'},{id:29,label:'Formula Red'},
            {id:30,label:'Blaze Red'},{id:31,label:'Grace Red'},{id:32,label:'Garnet Red'},
            {id:33,label:'Sunset Red'},{id:34,label:'Cabernet Red'},{id:35,label:'Candy Red'},
            {id:36,label:'Sunrise Orange'},{id:38,label:'Orange'},{id:49,label:'Dark Green'},
            {id:50,label:'Racing Green'},{id:51,label:'Sea Green'},{id:52,label:'Olive Green'},
            {id:53,label:'Bright Green'},{id:54,label:'Gasoline Green'},{id:61,label:'Galaxy Blue'},
            {id:62,label:'Dark Blue'},{id:63,label:'Saxon Blue'},{id:64,label:'Blue'},
            {id:65,label:'Mariner Blue'},{id:66,label:'Harbor Blue'},{id:67,label:'Diamond Blue'},
            {id:68,label:'Surf Blue'},{id:69,label:'Nautical Blue'},{id:70,label:'Ultra Blue'},
            {id:71,label:'Schafter Purple'},{id:72,label:'Spinnaker Purple'},{id:73,label:'Racing Blue'},
            {id:74,label:'Light Blue'},{id:88,label:'Yellow'},{id:89,label:'Race Yellow'},
            {id:90,label:'Bronze'},{id:91,label:'Dew Yellow'},{id:92,label:'Lime Green'},
            {id:94,label:'Feltzer Brown'},{id:95,label:'Green Brown'},{id:96,label:'Chocolate Brown'},
            {id:97,label:'Maple Brown'},{id:98,label:'Saddle Brown'},{id:99,label:'Bleached Brown'},
            {id:100,label:'Moss Brown'},{id:101,label:'Bison Brown'},{id:102,label:'Woodbeech Brown'},
            {id:103,label:'Beechwood Brown'},{id:104,label:'Sienna Brown'},{id:105,label:'Sandy Brown'},
            {id:106,label:'Bleached Brown'},{id:107,label:'Cream'},{id:111,label:'Ice White'},
            {id:112,label:'Frost White'},{id:135,label:'Hot Pink'},{id:136,label:'Salmon Pink'},
            {id:137,label:'Pfister Pink'},{id:138,label:'Bright Orange'},{id:141,label:'Midnight Blue'},
            {id:142,label:'Midnight Purple'},{id:143,label:'Wine Red'},{id:145,label:'Bright Purple'},
            {id:147,label:'Carbon Black'},{id:150,label:'Lava Red'},
        ],
    };
    // Build flat id→{label, category} map
    for (const [cat, entries] of Object.entries(paints)) {
        for (const e of entries) {
            map[e.id] = { label: e.label, category: cat };
        }
    }
    // Expose grouped structure too for building <optgroup> selects
    map._groups = paints;
    return map;
})();

/** Return "Category — Name (id)" for a colour id, or just the id if unknown */
function gtaColorName(id) {
    if (id == null || id === '') return '—';
    const c = GTA_COLORS[id];
    return c ? `${c.category} — ${c.label} (${id})` : `Unknown (${id})`;
}

/** Build the grouped <select> HTML for a colour picker */
function _buildColorSelect(id, currentVal) {
    const groups = GTA_COLORS._groups;
    let opts = `<option value="">— None —</option>`;
    for (const [cat, entries] of Object.entries(groups)) {
        opts += `<optgroup label="${cat}">`;
        for (const e of entries) {
            const sel = (currentVal != null && parseInt(currentVal) === e.id) ? ' selected' : '';
            opts += `<option value="${e.id}"${sel}>${e.label} (${e.id})</option>`;
        }
        opts += `</optgroup>`;
    }
    return `<select id="${id}" style="flex:1">${opts}</select>`;
}



/* ── NUI bridge ──────────────────────────────────────────────────── */
function nuiPost(event, data = {}) {
    return fetch(`https://${getResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => ({}));
}

function getResourceName() {
    if (typeof window.GetParentResourceName === 'function') {
        return window.GetParentResourceName();
    }
    try {
        const m = window.location.href.match(/nui:\/\/([^/]+)\//);
        if (m) return m[1];
    } catch(e) {}
    return 'mnc-jobgarage';
}

/* ── Message handler ─────────────────────────────────────────────── */
window.addEventListener('message', async (e) => {
    const { action, data } = e.data || {};
    if (action === 'open') {
        document.getElementById('overlay').classList.remove('hidden');
        await loadData();
    } else if (action === 'openPullout') {
        renderPullout(e.data);
    } else if (action === 'setupOpen') {
        setupHudOpen();
    } else if (action === 'setupHud') {
        setupHudUpdate(e.data);
    } else if (action === 'setupCaptured') {
        setupHudFlash(e.data.which);
    } else if (action === 'setupDone') {
        setupShowDone(e.data.out, e.data.spawn);
    } else if (action === 'setupClose') {
        setupHudClose();
    } else if (action === 'openGarageFormWithCoords') {
        document.getElementById('overlay').classList.remove('hidden');
        await loadData();
        document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        document.querySelector('.tab[data-tab="garages"]').classList.add('active');
        document.getElementById('tab-garages').classList.add('active');
        currentTab = 'garages';
        openGarageForm(null, { out: e.data.out, spawn: e.data.spawn });
    } else if (action === 'checkoutUpdated') {
        // live update from server: one vehicle's checkout state changed
        const { job, model, isOut, playerName } = e.data;
        if (!state.checkedOut[job]) state.checkedOut[job] = {};
        if (isOut) {
            state.checkedOut[job][model] = { playerName };
        } else {
            delete state.checkedOut[job][model];
        }
        // refresh pullout if visible and matches this garage
        const po = document.getElementById('pullout-overlay');
        if (!po.classList.contains('hidden') && _pulloutGarageId === job) {
            // re-render just the grid items to reflect lock state
            _updatePulloutLocks();
        }
    } else if (action === 'myIdResult') {
        // server returned our own citizenid for "Use My ID"
        const fpcid = document.getElementById('f-pcid');
        if (fpcid) fpcid.value = e.data.citizenid || '';
    } else if (action === 'lookupIdResult') {
        // server returned citizenid from server-id lookup
        const fpcid = document.getElementById('f-pcid');
        if (fpcid) {
            if (e.data.citizenid) {
                fpcid.value = e.data.citizenid;
                showToast('Found: ' + (e.data.name || e.data.citizenid));
            } else {
                showToast('Player ID not found', 'error');
            }
        }
    }
});

async function loadData() {
    const result = await nuiPost('getAdminData');
    if (!result) return;
    state.garages     = result.garages     || [];
    state.vehicles    = result.vehicles    || {};
    state.roles       = result.roles       || [];
    state.playerRoles = result.playerRoles || [];
    state.jobs        = result.jobs        || [];
    state.checkedOut  = result.checkedOut  || {};

    populateJobDropdowns();
    renderGarages();
    renderVehicles();
    renderRoles();
    renderPlayerRoles();
}

/* ── Tab switching ───────────────────────────────────────────────── */
document.querySelectorAll('.tab').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        currentTab = btn.dataset.tab;
        document.getElementById('tab-' + currentTab).classList.add('active');
    });
});

/* ── Populate dropdowns ──────────────────────────────────────────── */
function populateJobDropdowns() {
    // ── Vehicle tab: job filter now filters by garageId ──────────────
    // Vehicles are stored under garageId keys, so the filter must list garages.
    const vehJobFilter = document.querySelector('#veh-job-filter');
    if (vehJobFilter) {
        const cur = vehJobFilter.value;
        vehJobFilter.innerHTML = '<option value="">— All Garages —</option>';
        state.garages.forEach(g => {
            const gid = g.garageId || g.job;
            const label = g.label || gid;
            const suffix = g.job && g.job !== gid ? ` (${g.job})` : '';
            const opt = document.createElement('option');
            opt.value = gid;
            opt.textContent = label + suffix;
            vehJobFilter.appendChild(opt);
        });
        vehJobFilter.value = cur;
    }

    // ── Roles & Player Roles tabs: still filter by real QBCore job ───
    const jobsWithLabels = state.jobs.map(j => ({ name: j.name, label: j.label }));
    const roleJobSelectors = ['#role-job-filter', '#pr-job-filter'];
    roleJobSelectors.forEach(sel => {
        const el = document.querySelector(sel);
        if (!el) return;
        const cur = el.value;
        el.innerHTML = '<option value="">— All Jobs —</option>';
        jobsWithLabels.forEach(j => {
            const opt = document.createElement('option');
            opt.value = j.name;
            opt.textContent = j.label + ' (' + j.name + ')';
            el.appendChild(opt);
        });
        el.value = cur;
    });

    // Expose lists for form selects
    state.jobsDisplay    = jobsWithLabels;   // QBCore jobs — used by role/playerrole forms
    state.garagesDisplay = state.garages;    // garage list — used by vehicle form

    // ── Vehicle tab: role filter ─────────────────────────────────────
    // Collect distinct roles across all vehicles in state (deduplicated by job+roleName)
    const vehRoleFilter = document.querySelector('#veh-role-filter');
    if (vehRoleFilter) {
        const cur = vehRoleFilter.value;
        vehRoleFilter.innerHTML = '<option value="">— All Roles —</option>';
        const seen = new Set();
        state.roles.forEach(r => {
            const key = r.job + '::' + r.roleName;
            if (!seen.has(key)) {
                seen.add(key);
                const opt = document.createElement('option');
                opt.value = r.roleName;
                opt.dataset.job = r.job;
                opt.textContent = r.label + ' (' + r.roleName + ')';
                vehRoleFilter.appendChild(opt);
            }
        });
        vehRoleFilter.value = cur;
    }

    // ── Vehicle tab: grade filter ────────────────────────────────────
    // Collect distinct grade values from all vehicles
    const vehGradeFilter = document.querySelector('#veh-grade-filter');
    if (vehGradeFilter) {
        const cur = vehGradeFilter.value;
        const grades = new Set();
        for (const vehs of Object.values(state.vehicles)) {
            vehs.forEach(v => grades.add(v.grade ?? 0));
        }
        vehGradeFilter.innerHTML = '<option value="">— All Grades —</option>';
        [...grades].sort((a, b) => a - b).forEach(g => {
            const opt = document.createElement('option');
            opt.value = String(g);
            opt.textContent = 'Grade ' + g + '+';
            vehGradeFilter.appendChild(opt);
        });
        vehGradeFilter.value = cur;
    }

    // ── Player Roles tab: role filter ────────────────────────────────
    const prRoleFilter = document.querySelector('#pr-role-filter');
    if (prRoleFilter) {
        const cur = prRoleFilter.value;
        prRoleFilter.innerHTML = '<option value="">— All Roles —</option>';
        const seen = new Set();
        state.roles.forEach(r => {
            if (!seen.has(r.roleName)) {
                seen.add(r.roleName);
                const opt = document.createElement('option');
                opt.value = r.roleName;
                opt.textContent = r.label + ' (' + r.roleName + ')';
                prRoleFilter.appendChild(opt);
            }
        });
        prRoleFilter.value = cur;
    }
}

/* ── Image loading with fallback chain ───────────────────────────── */
function loadVehicleImage(imgEl, model) {
    if (!model) { imgEl.src = IMG_FALLBACK; return; }
    const m = model.toLowerCase().replace(/[^a-z0-9_]/g, '');
    const sources = IMG_PATHS.map(p => p.replace('{model}', m));
    sources.push(IMG_FALLBACK);
    let idx = 0;
    const tryNext = () => {
        if (idx >= sources.length) { imgEl.src = IMG_FALLBACK; return; }
        imgEl.src = sources[idx++];
    };
    imgEl.onerror = tryNext;
    tryNext();
}

/* ── Toast ───────────────────────────────────────────────────────── */
let toastTimer = null;
function showToast(msg, type = 'success') {
    const t = document.getElementById('toast');
    t.textContent = msg;
    t.className = 'show ' + type;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.className = '', 2500);
}

/* ── Close UI ────────────────────────────────────────────────────── */
function closeUI() {
    document.getElementById('overlay').classList.add('hidden');
    nuiPost('closeUI');
}
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        if (!document.getElementById('lightbox-overlay').classList.contains('hidden')) {
            closeLightbox();
        } else if (!document.getElementById('modal-overlay').classList.contains('hidden')) {
            closeModal();
        } else {
            closeUI();
        }
    }
});

/* ── Modal helpers ───────────────────────────────────────────────── */
function openModal(title, bodyHTML, saveFn, extraFooterHTML) {
    document.getElementById('modal-title').textContent = title;
    document.getElementById('modal-body').innerHTML = bodyHTML;
    modalSaveFn = saveFn;
    // Restore footer (may have been hidden/rewritten by garage vehicle sub-view)
    const footer = document.getElementById('modal-footer');
    footer.style.display = '';
    footer.innerHTML = `
        ${extraFooterHTML || ''}
        <button class="btn-secondary" onclick="closeModal()">Cancel</button>
        <button class="btn-primary" id="modal-save" onclick="modalSave()">Save</button>
    `;
    document.getElementById('modal-overlay').classList.remove('hidden');
}
function closeModal() {
    document.getElementById('modal-overlay').classList.add('hidden');
    document.getElementById('modal-footer').style.display = '';
    modalSaveFn = null;
    _garageReturnJob = null;
}
function modalSave() {
    if (modalSaveFn) modalSaveFn();
}

/* ═══════════════════════════════════════════════════════════════════
   LIGHTBOX  ──  vehicle image zoom viewer with Sign Out button
═══════════════════════════════════════════════════════════════════ */
let _lbModel   = null;
let _lbJob     = null;
let _lbZoom    = 1.0;
let _lbIsVehicleTab = false; // admin vehicles tab vs pullout

function openLightbox(model, job, fromPullout) {
    _lbModel = model;
    _lbJob   = job;
    _lbZoom  = 1.0;
    _lbIsVehicleTab = !fromPullout;

    const overlay = document.getElementById('lightbox-overlay');
    const img     = document.getElementById('lb-img');
    const title   = document.getElementById('lb-title');
    const signBtn = document.getElementById('lb-signout-btn');

    title.textContent = model;
    img.style.transform = 'scale(1)';
    overlay.classList.remove('hidden');
    loadVehicleImage(img, model);

    // Show sign-out button only in pullout context (player taking vehicle)
    if (fromPullout) {
        signBtn.style.display = 'flex';
    } else {
        signBtn.style.display = 'none';
    }
}

function closeLightbox() {
    document.getElementById('lightbox-overlay').classList.add('hidden');
    _lbModel = null;
    _lbJob   = null;
}

function lbSignOut() {
    const model = _lbModel;   // capture BEFORE closeLightbox nulls _lbModel
    if (!model) return;
    closeLightbox();
    pulloutSpawn(model);
}

// Zoom on scroll wheel inside lightbox
document.getElementById('lightbox-overlay').addEventListener('wheel', e => {
    e.preventDefault();
    _lbZoom += e.deltaY < 0 ? 0.1 : -0.1;
    _lbZoom = Math.min(4, Math.max(0.5, _lbZoom));
    document.getElementById('lb-img').style.transform = `scale(${_lbZoom})`;
}, { passive: false });

// Click outside image to close
document.getElementById('lightbox-overlay').addEventListener('click', e => {
    if (e.target === document.getElementById('lightbox-overlay')) closeLightbox();
});

/* ═══════════════════════════════════════════════════════════════════
   PULL-OUT  ──  in-game vehicle picker (replaces qb-menu/ox_lib)
═══════════════════════════════════════════════════════════════════ */
const CLASS_ICONS = {
    motorcycle: 'fa-motorcycle', 'truck-monster': 'fa-truck-monster', 'truck-front': 'fa-truck-front',
    bicycle: 'fa-bicycle', ship: 'fa-ship', helicopter: 'fa-helicopter', plane: 'fa-plane',
    'kit-medical': 'fa-kit-medical', car: 'fa-car',
};

let _pulloutJob        = null;
let _pulloutPayload    = null;
let _pulloutGrade      = 0;
let _pulloutView       = 'vehicles'; // 'vehicles' | 'roles'
let _pulloutRoleFilter = '';         // '' = all, otherwise required_role value

let _pulloutGarageId   = null;  // garageId for checkout state lookups

function renderPullout(payload) {
    const overlay = document.getElementById('pullout-overlay');
    const body    = document.getElementById('pullout-body');
    _pulloutPayload  = payload;
    _pulloutJob      = payload.job || null;
    _pulloutGarageId = payload.garageId || payload.job || null;
    _pulloutGrade    = payload.playerGrade ?? 0;
    _pulloutView     = 'vehicles';

    document.getElementById('pullout-joblabel').textContent = (payload.jobLabel || 'Job') + ' Garage';

    // Show/hide Roles button (grade 4+, only when not already in a vehicle)
    const rolesBtn = document.getElementById('pullout-roles-btn');
    if (rolesBtn) {
        rolesBtn.style.display = (!payload.isOut && _pulloutGrade >= 4) ? 'flex' : 'none';
    }

    // Reset and populate the pullout role filter from this garage's vehicles
    _pulloutRoleFilter = '';
    _populatePulloutRoleFilter(payload);

    _renderPulloutVehicles(payload, body);
    overlay.classList.remove('hidden');
}

function _populatePulloutRoleFilter(payload) {
    const sel = document.getElementById('pullout-role-filter');
    const bar = document.getElementById('pullout-filter-bar');
    if (!sel || !bar) return;

    const vehicles = payload.vehicles || [];
    // Collect distinct required_role values from vehicles available in this pullout
    const roles = [];
    const seen  = new Set();
    vehicles.forEach(v => {
        if (v.required_role && !seen.has(v.required_role)) {
            seen.add(v.required_role);
            roles.push({ roleName: v.required_role, label: v.required_role });
        }
    });

    sel.innerHTML = '<option value="">— All Roles —</option>';
    roles.forEach(r => {
        const opt = document.createElement('option');
        opt.value = r.roleName;
        opt.textContent = r.roleName;
        sel.appendChild(opt);
    });
    sel.value = '';

    // Only show the filter bar in vehicle view (not when isOut or no roles to filter on)
    bar.classList.toggle('hidden', payload.isOut || roles.length === 0);
}

function applyPulloutRoleFilter() {
    const sel = document.getElementById('pullout-role-filter');
    _pulloutRoleFilter = sel ? sel.value : '';
    // Re-render only the grid, preserving the rest of the pullout UI
    _updatePulloutLocks();
}

function _renderPulloutVehicles(payload, body) {
    body = body || document.getElementById('pullout-body');
    if (payload.isOut) {
        body.innerHTML = `
            <div class="pullout-action-grid">
                <div class="pullout-action-card" onclick="pulloutReturn()">
                    <i class="fas fa-car-burst"></i>
                    <span>Return Vehicle</span>
                    <small>${esc(payload.currentVehName || 'Current vehicle')}</small>
                </div>
                <div class="pullout-action-card" onclick="pulloutBlip()">
                    <i class="fas fa-map-marker-alt"></i>
                    <span>Mark with Blip</span>
                    <small>Toggle GPS route to your vehicle</small>
                </div>
            </div>
        `;
    } else {
        const allVehicles = payload.vehicles || [];
        const vehicles    = _pulloutRoleFilter
            ? allVehicles.filter(v => (v.required_role || '') === _pulloutRoleFilter)
            : allVehicles;
        const coMap = (state.checkedOut[_pulloutGarageId] || {});
        if (allVehicles.length === 0) {
            body.innerHTML = `<div class="empty-state"><i class="fas fa-car"></i><span>No vehicles available for your rank</span></div>`;
        } else if (vehicles.length === 0) {
            body.innerHTML = `<div class="pullout-grid" id="pullout-vehicle-grid"></div><div class="empty-state" style="padding-top:24px"><i class="fas fa-filter"></i><span>No vehicles match this role filter</span></div>`;
        } else {
            body.innerHTML = `<div class="pullout-grid" id="pullout-vehicle-grid">${vehicles.map(v => buildPulloutCard(v, coMap)).join('')}</div>`;
            body.querySelectorAll('.pullout-card-img img').forEach(img => loadVehicleImage(img, img.alt));
        }
    }
}

/* ── Pullout: Roles tab (grade 4+) ──────────────────────────────── */
async function pulloutShowRoles() {
    _pulloutView = 'roles';
    // Hide filter bar while in roles management view
    const bar = document.getElementById('pullout-filter-bar');
    if (bar) bar.classList.add('hidden');
    const body = document.getElementById('pullout-body');
    body.innerHTML = `<div class="pullout-roles-loading"><i class="fas fa-spinner fa-spin"></i> Loading…</div>`;

    const result = await nuiPost('getJobRolesForPullout');
    if (!result || !result.job) {
        body.innerHTML = `<div class="empty-state"><i class="fas fa-lock"></i><span>Access denied — Grade 4+ required</span></div>`;
        return;
    }

    const { job, roles, assignments } = result;

    // Build assignment lookup: citizenid → [roleNames]
    const assignMap = {};
    (assignments || []).forEach(a => {
        if (!assignMap[a.citizenid]) assignMap[a.citizenid] = [];
        assignMap[a.citizenid].push(a.role_name);
    });

    const roleOptions = (roles || []).map(r =>
        `<option value="${esc(r.role_name)}">${esc(r.label)} (${esc(r.role_name)})</option>`
    ).join('');

    const assignRows = (assignments || []).map(a => `
        <div class="pr-row">
            <div class="pr-row-info">
                <span class="pr-cid">${esc(a.citizenid)}</span>
                <span class="pr-role badge amber">${esc(a.role_name)}</span>
            </div>
            <button class="btn-icon del" onclick="pulloutRemoveRole('${esc(a.citizenid)}','${esc(a.role_name)}')">
                <i class="fas fa-user-minus"></i>
            </button>
        </div>
    `).join('') || `<div class="empty-state" style="padding:20px 0"><i class="fas fa-users"></i><span>No assignments yet</span></div>`;

    body.innerHTML = `
        <div class="pullout-roles-panel">
            <div class="pullout-roles-header">
                <button class="btn-secondary" onclick="pulloutShowVehicles()">
                    <i class="fas fa-arrow-left"></i> Back
                </button>
                <span class="pullout-roles-title"><i class="fas fa-id-badge"></i> Role Management — ${esc(job)}</span>
            </div>

            <div class="pullout-roles-assign">
                <div class="form-group">
                    <label>CitizenID</label>
                    <div class="input-row">
                        <input type="text" id="po-cid" placeholder="Player CitizenID">
                        <button class="btn-secondary" onclick="pulloutFillMyId()"><i class="fas fa-user-check"></i> My ID</button>
                    </div>
                </div>
                <div class="form-group" style="margin-top:8px">
                    <label>Lookup by Server ID</label>
                    <div class="input-row">
                        <input type="number" id="po-srvid" placeholder="e.g. 5" min="1">
                        <button class="btn-secondary" onclick="pulloutLookupId()"><i class="fas fa-search"></i> Find</button>
                    </div>
                </div>
                <div class="form-group" style="margin-top:8px">
                    <label>Role</label>
                    <select id="po-role">
                        <option value="">— select role —</option>
                        ${roleOptions}
                    </select>
                </div>
                <button class="btn-primary" style="margin-top:10px;width:100%" onclick="pulloutAssignRole()">
                    <i class="fas fa-user-plus"></i> Assign Role
                </button>
            </div>

            <div class="pullout-roles-divider">Current Assignments</div>
            <div class="pr-list" id="po-assignment-list">
                ${assignRows}
            </div>
        </div>
    `;
}

function pulloutShowVehicles() {
    _pulloutView = 'vehicles';
    // Re-show filter bar if it has options
    const bar = document.getElementById('pullout-filter-bar');
    const sel = document.getElementById('pullout-role-filter');
    if (bar && sel && sel.options.length > 1) bar.classList.remove('hidden');
    _renderPulloutVehicles(_pulloutPayload);
}

async function pulloutFillMyId() {
    const r = await nuiPost('getMyId');
    const el = document.getElementById('po-cid');
    if (el && r && r.citizenid) { el.value = r.citizenid; showToast('Filled with your ID'); }
}

async function pulloutLookupId() {
    const srvId = document.getElementById('po-srvid')?.value;
    if (!srvId) { showToast('Enter a server ID first', 'error'); return; }
    const r = await nuiPost('lookupPlayerId', { serverId: parseInt(srvId) });
    const el = document.getElementById('po-cid');
    if (r && r.citizenid && el) {
        el.value = r.citizenid;
        showToast('Found: ' + (r.name || r.citizenid));
    } else {
        showToast('Player not found', 'error');
    }
}

async function pulloutAssignRole() {
    const citizenid = document.getElementById('po-cid')?.value.trim();
    const roleName  = document.getElementById('po-role')?.value;
    if (!citizenid || !roleName) { showToast('CitizenID and Role required', 'error'); return; }
    const ok = await nuiPost('jobAssignRole', { citizenid, job: _pulloutJob, roleName });
    if (ok) {
        showToast('Role assigned!');
        pulloutShowRoles(); // refresh
    } else {
        showToast('Failed — check rank or role', 'error');
    }
}

async function pulloutRemoveRole(citizenid, roleName) {
    // inline confirm not available in FiveM CEF — ask via toast-level check
    if (!citizenid || !roleName) return;
    const ok = await nuiPost('jobRemoveRole', { citizenid, job: _pulloutJob, roleName });
    if (ok) {
        showToast('Role removed');
        pulloutShowRoles();
    } else {
        showToast('Failed', 'error');
    }
}

function buildPulloutCard(v, coMap) {
    const isOut     = !v.unlimited && coMap[v.model];
    const whoHas    = isOut ? isOut.playerName : null;
    const lockedCls = isOut ? ' pullout-card-locked' : '';
    const clickAct  = isOut
        ? ''
        : `onclick="openLightbox('${esc(v.model)}', '${esc(_pulloutJob)}', true)"`;
    const roleLabel = v.required_role ? getRoleLabel(_pulloutJob, v.required_role) : null;
    return `
        <div class="pullout-card${lockedCls}" ${clickAct} data-model="${esc(v.model)}">
            <div class="pullout-card-img">
                <img alt="${esc(v.model)}" onerror="loadVehicleImage(this, '${esc(v.model)}')">
                <i class="fas ${CLASS_ICONS[v.iconKey] || CLASS_ICONS.car} pullout-class-icon"></i>
                ${isOut ? `<div class="pullout-lock-banner"><i class="fas fa-lock"></i> Signed Out</div>` : ''}
            </div>
            <div class="pullout-card-body">
                <div class="pullout-card-name">${esc(v.name)}</div>
                ${isOut ? `<div class="pullout-card-who"><i class="fas fa-user"></i> ${esc(whoHas)}</div>` : ''}
                <div class="pullout-card-tags">
                    ${v.grade ? `<span class="badge amber"><i class="fas fa-star"></i> Grade ${v.grade}+</span>` : ''}
                    ${(v.maxPerf || v.performance === 'max') ? `<span class="badge green"><i class="fas fa-bolt"></i> Max Perf</span>` : ''}
                    ${v.bulletproof ? `<span class="badge"><i class="fas fa-shield"></i> Armored</span>` : ''}
                    ${roleLabel ? `<span class="badge red"><i class="fas fa-id-badge"></i> ${esc(roleLabel)}</span>` : ''}
                    ${v.unlimited ? `<span class="badge green"><i class="fas fa-infinity"></i> Unlimited</span>` : ''}
                </div>
            </div>
        </div>
    `;
}

function _updatePulloutLocks() {
    const grid  = document.getElementById('pullout-vehicle-grid');
    if (!grid || !_pulloutPayload || _pulloutView !== 'vehicles') return;
    const allVehicles = _pulloutPayload.vehicles || [];
    const vehicles    = _pulloutRoleFilter
        ? allVehicles.filter(v => (v.required_role || '') === _pulloutRoleFilter)
        : allVehicles;
    const coMap    = (state.checkedOut[_pulloutGarageId] || {});
    grid.innerHTML  = vehicles.map(v => buildPulloutCard(v, coMap)).join('');
    grid.querySelectorAll('.pullout-card-img img').forEach(img => loadVehicleImage(img, img.alt));
}

function closePullout() {
    document.getElementById('pullout-overlay').classList.add('hidden');
    _pulloutView       = 'vehicles';
    _pulloutRoleFilter = '';
    nuiPost('pulloutClose');
}
function pulloutSpawn(model) {
    document.getElementById('pullout-overlay').classList.add('hidden');
    _pulloutView = 'vehicles';
    nuiPost('pulloutSpawn', { model });
}
function pulloutReturn() {
    document.getElementById('pullout-overlay').classList.add('hidden');
    _pulloutView = 'vehicles';
    nuiPost('pulloutReturn');
}
function pulloutBlip() {
    document.getElementById('pullout-overlay').classList.add('hidden');
    _pulloutView = 'vehicles';
    nuiPost('pulloutBlip');
}
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !document.getElementById('pullout-overlay').classList.contains('hidden')) {
        closePullout();
    }
});

/* ═══════════════════════════════════════════════════════════════════
   SETUP MODE  ──  walk-to-point vector capture
═══════════════════════════════════════════════════════════════════ */
const SETUP_STEP_TEXT = {
    out:   { label: 'Walk to the OUT point',   desc: 'Stand where the target prop should appear and face the direction it should be approached from.' },
    spawn: { label: 'Walk to the SPAWN point', desc: 'Stand where the vehicle itself should appear and face the direction it should be facing.' },
};
let setupResult = { out: null, spawn: null };

function startSetupMode() {
    document.getElementById('overlay').classList.add('hidden');
    nuiPost('startSetup');
}

function setupHudOpen() {
    document.getElementById('setup-done-overlay').classList.add('hidden');
    document.getElementById('setup-hud').classList.remove('hidden');
    const t = SETUP_STEP_TEXT.out;
    document.getElementById('setup-step-label').textContent = t.label;
    document.getElementById('setup-step-desc').textContent = t.desc;
}

function setupHudUpdate(data) {
    const hud = document.getElementById('setup-hud');
    if (hud.classList.contains('hidden')) return;
    const t = SETUP_STEP_TEXT[data.step];
    if (t) {
        document.getElementById('setup-step-label').textContent = t.label;
        document.getElementById('setup-step-desc').textContent = t.desc;
    }
    const c = data.coords || {};
    document.getElementById('setup-cx').textContent = (c.x ?? 0).toFixed(2);
    document.getElementById('setup-cy').textContent = (c.y ?? 0).toFixed(2);
    document.getElementById('setup-cz').textContent = (c.z ?? 0).toFixed(2);
    document.getElementById('setup-cw').textContent = (c.w ?? 0).toFixed(2);
}

function setupHudFlash(which) {
    const panel = document.getElementById('setup-instructions');
    panel.style.borderColor = 'var(--green)';
    setTimeout(() => { panel.style.borderColor = 'var(--amber)'; }, 350);
}

function setupHudClose() {
    document.getElementById('setup-hud').classList.add('hidden');
    document.getElementById('setup-done-overlay').classList.add('hidden');
}

function vec4Str(v) {
    if (!v) return 'vec4(0.0, 0.0, 0.0, 0.0)';
    return `vec4(${v.x}, ${v.y}, ${v.z}, ${v.w})`;
}

function setupShowDone(out, spawn) {
    setupResult = { out, spawn };
    document.getElementById('setup-hud').classList.add('hidden');
    document.getElementById('setup-result-out').textContent   = vec4Str(out);
    document.getElementById('setup-result-spawn').textContent = vec4Str(spawn);
    document.getElementById('setup-done-overlay').classList.remove('hidden');
}

function closeSetupDone() {
    document.getElementById('setup-done-overlay').classList.add('hidden');
    nuiPost('setupClose');
}

function applySetupToForm() {
    document.getElementById('setup-done-overlay').classList.add('hidden');
    nuiPost('setupApply', { out: setupResult.out, spawn: setupResult.spawn });
}

function copySetupVec(which) {
    const text = vec4Str(setupResult[which]);
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => showToast('Copied ' + which + ' to clipboard'));
    }
}

/* ═══════════════════════════════════════════════════════════════════
   TAB: GARAGES
═══════════════════════════════════════════════════════════════════ */
const _garageRegistry = {};   // key = garageId → garage object

function renderGarages() {
    const query = document.getElementById('garage-search').value.toLowerCase();
    const list  = document.getElementById('garage-list');
    const items = state.garages.filter(g => {
        const gid = (g.garageId || g.job).toLowerCase();
        return gid.includes(query) || (g.job || '').toLowerCase().includes(query) || (g.label || '').toLowerCase().includes(query);
    });

    if (items.length === 0) {
        list.innerHTML = `<div class="empty-state"><i class="fas fa-warehouse"></i><span>No garages found</span></div>`;
        return;
    }

    items.forEach(g => { _garageRegistry[g.garageId || g.job] = g; });

    list.innerHTML = items.map(g => {
        const gid = g.garageId || g.job;
        return `
        <div class="card">
            <div class="card-top">
                <div>
                    <div class="card-name">${esc(g.label || gid)}</div>
                    <div class="card-model">${esc(gid)}${g.job && g.job !== gid ? ` <span style="color:var(--text-dim)">(${esc(g.job)})</span>` : ''}</div>
                </div>
                <div style="display:flex;gap:5px;flex-direction:column;align-items:flex-end">
                    ${g.fromConfig  ? '<span class="badge green"><i class="fas fa-code"></i> Config</span>' : ''}
                    ${g.hasDbOverride ? '<span class="badge amber"><i class="fas fa-database"></i> DB</span>' : ''}
                    ${g.zoneEnable ? '' : '<span class="badge red"><i class="fas fa-eye-slash"></i> Disabled</span>'}
                </div>
            </div>
            <div class="card-meta">
                <span class="badge"><i class="fas fa-location-dot"></i> Out: ${fv(g.out.x)}, ${fv(g.out.y)}, ${fv(g.out.z)}</span>
            </div>
            <div class="card-actions">
                <button class="btn-icon" onclick="openGarageForm(_garageRegistry['${esc(gid)}'])">
                    <i class="fas fa-pen"></i> Edit
                </button>
                ${!g.fromConfig ? `<button class="btn-icon del" onclick="deleteGarage('${esc(gid)}')"><i class="fas fa-trash"></i></button>` : ''}
            </div>
        </div>
    `}).join('');
}

function _buildGarageFormBody(g, prefillCoords) {
    const isNew = !g;
    const sCoords = (g && g.spawn) || (prefillCoords && prefillCoords.spawn) || { x: 0, y: 0, z: 0, w: 0 };
    const oCoords = (g && g.out)   || (prefillCoords && prefillCoords.out)   || { x: 0, y: 0, z: 0, w: 0 };
    const jobList    = state.jobsDisplay || state.jobs;
    const jobOptions = jobList.map(j =>
        `<option value="${esc(j.name)}" ${g && g.job === j.name ? 'selected' : ''}>${esc(j.label)} (${esc(j.name)})</option>`
    ).join('');
    const currentGid = g ? (g.garageId || g.job) : '';

    return `
        <div class="form-grid">
            <div class="form-group">
                <label>Job</label>
                ${isNew
                    ? `<select id="f-job"><option value="">— select —</option>${jobOptions}</select>`
                    : `<input type="text" id="f-job" value="${esc(g.job)}" ${g.fromConfig ? 'readonly' : ''}>`
                }
                ${g && g.fromConfig ? '<span class="hint">Job locked (from config)</span>' : ''}
            </div>
            <div class="form-group">
                <label>Garage ID <span style="color:var(--text-dim)">(unique key)</span></label>
                ${isNew
                    ? `<input type="text" id="f-gid" placeholder="police_airport" oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9_]/g,'')">
                       <span class="hint">Auto-fills from Job if left blank. Use a unique suffix for multiple garages per job, e.g. police_hq, police_sandy</span>`
                    : `<input type="text" id="f-gid" value="${esc(currentGid)}" ${g.fromConfig ? 'readonly' : ''} oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9_]/g,'')">`
                }
                ${g && g.fromConfig ? '<span class="hint">Garage ID locked (from config)</span>' : ''}
            </div>
            <div class="form-group">
                <label>Label</label>
                <input type="text" id="f-label" value="${g ? esc(g.label) : ''}" placeholder="Police Garage">
            </div>

            <div class="form-full form-section-title">Spawn Coords (where vehicle appears)</div>
            <div class="form-full coord-row">
                <div class="form-group"><label>X</label><input type="number" step="0.01" id="f-sx" value="${sCoords.x}"></div>
                <div class="form-group"><label>Y</label><input type="number" step="0.01" id="f-sy" value="${sCoords.y}"></div>
                <div class="form-group"><label>Z</label><input type="number" step="0.01" id="f-sz" value="${sCoords.z}"></div>
                <div class="form-group"><label>W (heading)</label><input type="number" step="0.01" id="f-sw" value="${sCoords.w}"></div>
            </div>

            <div class="form-full form-section-title">Return / Target Prop Coords</div>
            <div class="form-full coord-row">
                <div class="form-group"><label>X</label><input type="number" step="0.01" id="f-ox" value="${oCoords.x}"></div>
                <div class="form-group"><label>Y</label><input type="number" step="0.01" id="f-oy" value="${oCoords.y}"></div>
                <div class="form-group"><label>Z</label><input type="number" step="0.01" id="f-oz" value="${oCoords.z}"></div>
                <div class="form-group"><label>W (heading)</label><input type="number" step="0.01" id="f-ow" value="${oCoords.w}"></div>
            </div>

            <div class="form-full">
                <div class="toggle-row">
                    <input type="checkbox" id="f-zone" ${(!g || g.zoneEnable) ? 'checked' : ''}>
                    <label for="f-zone" style="font-size:12px;font-weight:600;color:var(--text-pri)">Zone Enabled</label>
                </div>
            </div>
        </div>
    `;
}

function openGarageForm(g, prefillCoords) {
    const isNew = !g;
    const title  = isNew ? 'New Garage' : 'Edit Garage — ' + (g.label || g.garageId || g.job);
    const currentGid = g ? (g.garageId || g.job) : null;

    // Build the main form footer with optional "View Vehicles" button
    const extraFooterBtn = (!isNew && currentGid)
        ? `<button class="btn-secondary" style="margin-right:auto" onclick="_garageShowVehicles('${esc(currentGid)}')">
               <i class="fas fa-car"></i> Vehicles
           </button>`
        : '';

    openModal(title, _buildGarageFormBody(g, prefillCoords), async () => {
        const job = document.getElementById('f-job').value.trim();
        if (!job) { showToast('Job is required', 'error'); return; }
        // garageId defaults to job if left blank (single-garage-per-job compat)
        const garageId = (document.getElementById('f-gid').value.trim() || job).toLowerCase().replace(/[^a-z0-9_]/g, '');
        if (!garageId) { showToast('Garage ID is required', 'error'); return; }
        // Warn if this garageId is already used by a different garage
        const conflict = state.garages.find(gg => (gg.garageId || gg.job) === garageId && (gg.garageId || gg.job) !== (currentGid || garageId));
        if (conflict) { showToast(`Garage ID "${garageId}" already exists`, 'error'); return; }
        const payload = {
            job,
            garageId,
            label:     document.getElementById('f-label').value.trim() || job,
            spawn:     { x: +document.getElementById('f-sx').value, y: +document.getElementById('f-sy').value, z: +document.getElementById('f-sz').value, w: +document.getElementById('f-sw').value },
            out:       { x: +document.getElementById('f-ox').value, y: +document.getElementById('f-oy').value, z: +document.getElementById('f-oz').value, w: +document.getElementById('f-ow').value },
            zoneEnable: document.getElementById('f-zone').checked,
        };
        const ok = await nuiPost('saveGarage', payload);
        if (ok) {
            showToast('Garage saved!');
            closeModal();
            await loadData();
        } else {
            showToast('Save failed', 'error');
        }
    }, extraFooterBtn);
}

// Opens a sub-view inside the modal showing vehicles for a given garageId.
function _garageShowVehicles(garageId) {
    const job      = garageId;  // state.vehicles is keyed by garageId (same field in DB)
    const vehicles = (state.vehicles[garageId] || []).slice().sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
    const garage   = state.garages.find(g => (g.garageId || g.job) === garageId);
    const title    = 'Vehicles — ' + (garage ? (garage.label || garageId) : garageId);

    const rows = vehicles.length === 0
        ? `<div class="empty-state" style="padding:24px 0"><i class="fas fa-car"></i><span>No vehicles for this garage</span></div>`
        : vehicles.map(v => {
            const actualJob = garage ? (garage.job || garageId) : garageId;
            const roleLabel = v.required_role ? getRoleLabel(actualJob, v.required_role) : null;
            const coMap  = state.checkedOut[garageId] || {};
            const isOut  = !!coMap[v.model];
            const regKey = garageId + '::' + v.model;   // raw key
            _vehRegistry[regKey] = { ...v, job: garageId };
            return `
                <div class="garage-veh-row">
                    <div class="garage-veh-img">
                        <img alt="${esc(v.model)}" onerror="loadVehicleImage(this,'${esc(v.model)}')">
                    </div>
                    <div class="garage-veh-info">
                        <div class="garage-veh-name">${esc(v.customName)}</div>
                        <div class="garage-veh-model">${esc(v.model)}</div>
                        <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:4px">
                            <span class="badge amber"><i class="fas fa-star"></i> Grade ${v.grade}+</span>
                            ${roleLabel ? `<span class="badge red"><i class="fas fa-lock"></i> ${esc(roleLabel)}</span>` : ''}
                            ${v.unlimited ? `<span class="badge green"><i class="fas fa-infinity"></i> Unlimited</span>` : ''}
                            ${v.performance === 'max' ? `<span class="badge green"><i class="fas fa-bolt"></i> Max Perf</span>` : ''}
                            ${v.color1 != null ? `<span class="badge" title="Primary: ${gtaColorName(v.color1)}${v.color2 != null ? ' / Secondary: ' + gtaColorName(v.color2) : ''}"><i class="fas fa-paint-brush"></i> ${gtaColorName(v.color1)}${v.color2 != null ? ' / ' + gtaColorName(v.color2) : ''}</span>` : ''}
                            ${v.livery != null ? `<span class="badge"><i class="fas fa-layer-group"></i> Livery ${v.livery}</span>` : ''}
                            ${isOut ? `<span class="badge red"><i class="fas fa-user"></i> Out</span>` : ''}
                            ${v.fromConfig ? `<span class="badge green"><i class="fas fa-code"></i> Config</span>` : `<span class="badge"><i class="fas fa-database"></i> DB</span>`}
                        </div>
                    </div>
                    <button class="btn-icon" style="flex-shrink:0" onclick="_garageEditVehicle('${regKey}','${esc(garageId)}')">
                        <i class="fas fa-pen"></i> Edit
                    </button>
                </div>
            `;
        }).join('');

    const body = `
        <div style="margin-bottom:10px">
            <button class="btn-secondary" onclick="_garageBackToForm('${esc(garageId)}')">
                <i class="fas fa-arrow-left"></i> Back to Garage
            </button>
        </div>
        <div class="garage-veh-list">${rows}</div>
        <div style="margin-top:12px">
            <button class="btn-primary" onclick="_garageAddVehicle('${esc(garageId)}')">
                <i class="fas fa-plus"></i> Add Vehicle to this Garage
            </button>
        </div>
    `;

    // Swap modal body in-place (no new modal stack)
    document.getElementById('modal-title').textContent = title;
    document.getElementById('modal-body').innerHTML = body;
    // Hide footer save/cancel — navigation is handled with Back button
    document.getElementById('modal-footer').style.display = 'none';
    modalSaveFn = null;

    // Load images
    document.querySelectorAll('.garage-veh-img img').forEach(img => loadVehicleImage(img, img.alt));
}

function _garageBackToForm(garageId) {
    const g = state.garages.find(g => (g.garageId || g.job) === garageId);
    document.getElementById('modal-footer').style.display = '';
    openGarageForm(g || null);
}

function _garageEditVehicle(regKey, returnJob) {
    const v = _vehRegistry[regKey];
    if (!v) { showToast('Vehicle data not found', 'error'); return; }
    _garageReturnJob = returnJob;
    document.getElementById('modal-footer').style.display = '';
    openVehicleFormWithReturn(v, returnJob);
}

function _garageAddVehicle(garageId) {
    _garageReturnJob = garageId;
    document.getElementById('modal-footer').style.display = '';
    // Pre-select the garage in a new vehicle form
    openVehicleFormWithReturn(null, garageId);
}

// Wrapper that after save goes back to the garage vehicle list
let _garageReturnJob = null;
function openVehicleFormWithReturn(v, returnJob) {
    const isNew = !v;
    // Build garage options — vehicle belongs to a specific garage (by garageId),
    // not just a QBCore job. This allows multiple garages per job.
    const garageOptions = state.garages.map(g => {
        const gid = g.garageId || g.job;
        const selected = (v ? v.job === gid : gid === returnJob) ? 'selected' : '';
        const label = g.label || gid;
        const suffix = g.job && g.job !== gid ? ` (${g.job})` : '';
        return `<option value="${esc(gid)}" ${selected}>${esc(label)}${esc(suffix)}</option>`;
    }).join('');

    const body = `
        <div id="veh-preview-wrap">
            <img id="veh-preview-img" alt="" onerror="loadVehicleImage(document.getElementById('veh-preview-img'), document.getElementById('f-vmodel').value)">
            <div class="no-img" id="veh-preview-icon" style="${v ? 'display:none' : ''}"><i class="fas fa-car"></i></div>
        </div>
        <div class="form-grid">
            <div class="form-group">
                <label>Garage</label>
                <select id="f-vjob" onchange="updateRoleOptions()">${garageOptions}</select>
                <span class="hint">Vehicle belongs to this garage — use the Garage ID</span>
            </div>
            <div class="form-group">
                <label>Model Name</label>
                <input type="text" id="f-vmodel" value="${v ? esc(v.model) : ''}" placeholder="police" oninput="previewVehicleImg(); _liveryModelChanged()" ${v && v.fromConfig ? 'readonly' : ''}>
                ${v && v.fromConfig ? '<span class="hint">Model locked — from config</span>' : ''}
            </div>
            <div class="form-group">
                <label>Display Name</label>
                <input type="text" id="f-vcname" value="${v ? esc(v.customName) : ''}" placeholder="Police Cruiser">
            </div>
            <div class="form-group">
                <label>Minimum Grade</label>
                <input type="number" id="f-vgrade" value="${v ? v.grade : 0}" min="0" max="20">
            </div>
            <div class="form-group">
                <label>Required Role <span style="color:var(--text-dim)">(optional)</span></label>
                <select id="f-vrole">
                    <option value="">None</option>
                </select>
                <span class="hint">Only players with this role can take this vehicle</span>
            </div>
            <div class="form-group">
                <label>Sort Order</label>
                <input type="number" id="f-vorder" value="${v ? (v.sortOrder || 0) : 0}" min="0">
            </div>
            <div class="form-group">
                <label>Livery</label>
                <select id="f-vlivery" disabled>
                    <option value="">Checking…</option>
                </select>
                <span class="hint" id="f-vlivery-hint">Checking livery count…</span>
            </div>
            <div class="form-full">
                <div class="toggle-row">
                    <input type="checkbox" id="f-vunlimited" ${v && v.unlimited ? 'checked' : ''}>
                    <label for="f-vunlimited" style="font-size:12px;font-weight:600;color:var(--text-pri)">
                        Unlimited Checkouts
                        <span style="font-weight:400;color:var(--text-dim);margin-left:6px">Multiple staff can sign out this vehicle simultaneously</span>
                    </label>
                </div>
            </div>
            <div class="form-full">
                <div class="toggle-row">
                    <input type="checkbox" id="f-vperf" ${v && v.performance === 'max' ? 'checked' : ''}>
                    <label for="f-vperf" style="font-size:12px;font-weight:600;color:var(--text-pri)">
                        Max Performance
                        <span style="font-weight:400;color:var(--text-dim);margin-left:6px">Applies SetVehicleModKit + all engine/brake/suspension mods, then re-applies mnc-handui handling on spawn</span>
                    </label>
                </div>
            </div>
            <div class="form-full form-section-title">Paint Override <span style="font-weight:400;text-transform:none;letter-spacing:0;color:var(--text-dim)">— optional. Leave as None for no paint override.</span></div>
            <div class="form-group">
                <label>Primary Colour</label>
                ${_buildColorSelect('f-vcolor1', v && v.color1 != null ? v.color1 : '')}
            </div>
            <div class="form-group">
                <label>Secondary Colour</label>
                ${_buildColorSelect('f-vcolor2', v && v.color2 != null ? v.color2 : '')}
            </div>
        </div>
    `;

    const modalTitle = isNew ? 'Add Vehicle' : 'Edit Vehicle — ' + (v ? v.model : '');
    const backBtn = returnJob
        ? `<button class="btn-secondary" style="margin-right:auto" onclick="_garageShowVehicles('${esc(returnJob)}')">
               <i class="fas fa-arrow-left"></i> Back
           </button>`
        : '';

    modalSaveFn = async () => {
        const job   = document.getElementById('f-vjob').value;
        const model = document.getElementById('f-vmodel').value.trim();
        if (!job || !model) { showToast('Job and model are required', 'error'); return; }
        const c1raw = document.getElementById('f-vcolor1')?.value;
        const c2raw = document.getElementById('f-vcolor2')?.value;
        const payload = {
            job,
            model,
            customName:    document.getElementById('f-vcname').value.trim(),
            grade:         parseInt(document.getElementById('f-vgrade').value) || 0,
            required_role: document.getElementById('f-vrole').value || null,
            sortOrder:     parseInt(document.getElementById('f-vorder').value) || 0,
            unlimited:     document.getElementById('f-vunlimited').checked,
            performance:   document.getElementById('f-vperf')?.checked ? 'max' : null,
            color1:        (c1raw !== '' && c1raw != null) ? parseInt(c1raw) : null,
            color2:        (c2raw !== '' && c2raw != null) ? parseInt(c2raw) : null,
            livery:        (() => { const lv = document.getElementById('f-vlivery')?.value; return (lv !== '' && lv != null) ? parseInt(lv) : null; })(),
        };
        const ok = await nuiPost('saveVehicle', payload);
        if (ok) {
            showToast('Vehicle saved!');
            await loadData();
            if (returnJob) {
                _garageShowVehicles(returnJob);
            } else {
                closeModal();
            }
        } else {
            showToast('Save failed', 'error');
        }
    };

    // Use openModal so the overlay is shown and footer is built consistently
    document.getElementById('modal-title').textContent = modalTitle;
    document.getElementById('modal-body').innerHTML = body;
    const footer = document.getElementById('modal-footer');
    footer.style.display = '';
    footer.innerHTML = `
        ${backBtn}
        <button class="btn-secondary" onclick="closeModal()">Cancel</button>
        <button class="btn-primary" id="modal-save" onclick="modalSave()">Save</button>
    `;
    document.getElementById('modal-overlay').classList.remove('hidden');

    setTimeout(() => {
        updateRoleOptions(v ? v.required_role : null);
        if (v) {
            const img = document.getElementById('veh-preview-img');
            if (img) loadVehicleImage(img, v.model);
        }
        // Auto-populate livery dropdown for the current model,
        // pre-selecting whatever livery index is already saved.
        const modelNow   = document.getElementById('f-vmodel')?.value.trim();
        const preselect  = (v && v.livery != null) ? v.livery : null;
        if (modelNow) fetchLiveryCount(modelNow, preselect);
        else _setLiveryUnavailable();
    }, 50);
}

async function deleteGarage(garageId) {
    openModal('Delete Garage', `<div style="padding:8px 0;line-height:1.6;color:var(--text-sec)">Delete DB garage entry for <b>${esc(garageId)}</b>?<br><br>Config-defined garages cannot be deleted — only disabled via Edit. This removes DB-only entries.</div>`, async () => {
        await nuiPost('deleteGarage', { job: garageId });
        showToast('Garage deleted');
        closeModal();
        await loadData();
    });
    setTimeout(() => { const b = document.getElementById('modal-save'); if(b){b.textContent='Delete';b.className='btn-danger';} }, 0);
}

/* ═══════════════════════════════════════════════════════════════════
   TAB: VEHICLES  ──  with drag-to-reorder
═══════════════════════════════════════════════════════════════════ */
function renderVehicles() {
    const jobFilter  = document.getElementById('veh-job-filter').value;  // now a garageId
    const roleFilter = document.getElementById('veh-role-filter').value;
    const gradeFilter= document.getElementById('veh-grade-filter').value;
    const query      = document.getElementById('veh-search').value.toLowerCase();
    const list       = document.getElementById('vehicle-list');

    // Build a garageId → label map for the badge display
    const garageLabels = {};
    state.garages.forEach(g => { garageLabels[g.garageId || g.job] = g.label || g.garageId || g.job; });

    let items = [];
    for (const [garageId, vehs] of Object.entries(state.vehicles)) {
        if (jobFilter && garageId !== jobFilter) continue;
        vehs.forEach(v => {
            if (roleFilter && (v.required_role || '') !== roleFilter) return;
            if (gradeFilter !== '' && String(v.grade ?? 0) !== gradeFilter) return;
            if (!query || v.model.toLowerCase().includes(query) || v.customName.toLowerCase().includes(query)) {
                items.push({ ...v, job: garageId, garageLabel: garageLabels[garageId] || garageId });
            }
        });
    }

    if (items.length === 0) {
        list.innerHTML = `<div class="empty-state"><i class="fas fa-car"></i><span>No vehicles found</span></div>`;
        return;
    }

    list.innerHTML = items.map((v, idx) => {
        // v.job is garageId; resolve the real QBCore job for role label lookup
        const garage = state.garages.find(g => (g.garageId || g.job) === v.job);
        const actualJob = garage ? (garage.job || v.job) : v.job;
        const roleLabel = v.required_role ? getRoleLabel(actualJob, v.required_role) : null;
        const coMap = state.checkedOut[v.job] || {};
        const isOut = coMap[v.model];
        const isHidden = v.hidden;
        const regKey   = v.job + '::' + v.model;   // raw key, safe to use in onclick single-quote string
        _vehRegistry[regKey] = v;
        return `
            <div class="card veh-card ${isOut ? 'card-checked-out' : ''} ${isHidden ? 'card-hidden-veh' : ''}"
                 data-job="${esc(v.job)}"
                 data-model="${esc(v.model)}"
                 data-idx="${idx}"
                 data-order="${v.sortOrder || 0}">
                <div class="drag-handle" title="Drag to reorder"><i class="fas fa-grip-vertical"></i></div>
                <div class="card-image-wrap" style="cursor:pointer" onclick="openLightbox('${esc(v.model)}','${esc(v.job)}',false)">
                    <img alt="${esc(v.model)}" onerror="imgFallback(this, '${esc(v.model)}')">
                    <div class="lb-hint"><i class="fas fa-search-plus"></i></div>
                </div>
                <div class="card-top">
                    <div>
                        <div class="card-name">${esc(v.customName)}</div>
                        <div class="card-model">${esc(v.model)}</div>
                    </div>
                    <div style="display:flex;flex-direction:column;gap:4px;align-items:flex-end">
                        ${v.fromConfig ? '<span class="badge green"><i class="fas fa-code"></i> Config</span>' : '<span class="badge amber"><i class="fas fa-database"></i> DB</span>'}
                        ${isHidden ? '<span class="badge red"><i class="fas fa-eye-slash"></i> Hidden</span>' : ''}
                        ${isOut && !v.unlimited ? '<span class="badge red"><i class="fas fa-lock"></i> Out</span>' : ''}
                    </div>
                </div>
                <div class="card-meta">
                    <span class="badge"><i class="fas fa-warehouse"></i> ${esc(v.garageLabel || v.job)}</span>
                    <span class="badge amber"><i class="fas fa-star"></i> Grade ${v.grade}+</span>
                    <span class="badge"><i class="fas fa-sort"></i> #${v.sortOrder || 0}</span>
                    ${roleLabel ? `<span class="badge red"><i class="fas fa-lock"></i> ${esc(roleLabel)}</span>` : ''}
                    ${v.unlimited ? `<span class="badge green"><i class="fas fa-infinity"></i> Unlimited</span>` : ''}
                    ${v.performance === 'max' ? `<span class="badge green"><i class="fas fa-bolt"></i> Max Perf</span>` : ''}
                    ${v.color1 != null ? `<span class="badge" title="Primary: ${gtaColorName(v.color1)}${v.color2 != null ? ' / Secondary: ' + gtaColorName(v.color2) : ''}"><i class="fas fa-paint-brush"></i> ${gtaColorName(v.color1)}${v.color2 != null ? ' / ' + gtaColorName(v.color2) : ''}</span>` : ''}
                    ${v.livery != null ? `<span class="badge"><i class="fas fa-layer-group"></i> Livery ${v.livery}</span>` : ''}
                    ${isOut && !v.unlimited ? `<span class="badge red"><i class="fas fa-user"></i> ${esc((isOut).playerName)}</span>` : ''}
                </div>
                <div class="card-actions">
                    <button class="btn-icon" onclick="openVehicleForm(_vehRegistry['${regKey}'])">
                        <i class="fas fa-pen"></i> Edit
                    </button>
                    ${isHidden
                        ? `<button class="btn-icon" onclick="restoreVehicle('${esc(v.job)}','${esc(v.model)}')">
                               <i class="fas fa-eye"></i> Restore
                           </button>`
                        : `<button class="btn-icon del" onclick="deleteVehicleConfirm('${esc(v.job)}','${esc(v.model)}','${v.fromConfig ? 'config' : 'db'}')">
                               <i class="fas fa-trash"></i>
                           </button>`
                    }
                </div>
            </div>
        `;
    }).join('');

    list.querySelectorAll('.card-image-wrap img').forEach(img => {
        loadVehicleImage(img, img.alt);
    });

    initVehicleDragSort(list, items);
}

/* ── Drag-to-reorder: uses dragenter/dragleave to avoid child-element issues ── */
function initVehicleDragSort(container, items) {
    const cards = Array.from(container.querySelectorAll('.veh-card'));
    if (cards.length < 2) return;

    let dragSrcIdx = null;

    cards.forEach(card => {
        card.setAttribute('draggable', 'true');

        card.addEventListener('dragstart', e => {
            dragSrcIdx = parseInt(card.dataset.idx);
            setTimeout(() => card.classList.add('dragging'), 0);
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', String(dragSrcIdx));
        });

        card.addEventListener('dragend', () => {
            card.classList.remove('dragging');
            cards.forEach(c => c.classList.remove('drag-over'));
            dragSrcIdx = null;
        });

        card.addEventListener('dragenter', e => {
            e.preventDefault();
            if (dragSrcIdx !== null && parseInt(card.dataset.idx) !== dragSrcIdx) {
                cards.forEach(c => c.classList.remove('drag-over'));
                card.classList.add('drag-over');
            }
        });

        card.addEventListener('dragover', e => {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
        });

        card.addEventListener('dragleave', e => {
            if (!card.contains(e.relatedTarget)) {
                card.classList.remove('drag-over');
            }
        });

        card.addEventListener('drop', async e => {
            e.preventDefault();
            card.classList.remove('drag-over');
            const fromIdx = dragSrcIdx;
            const toIdx   = parseInt(card.dataset.idx);
            dragSrcIdx = null;
            if (fromIdx === null || fromIdx === toIdx) return;

            const reordered = [...items];
            const [dragged] = reordered.splice(fromIdx, 1);
            reordered.splice(toIdx, 0, dragged);

            const updates = reordered.map((v, i) => ({
                job:       v.job,
                model:     v.model,
                sortOrder: i + 1,
            }));

            const affectedJobs = [...new Set(items.map(v => v.job))];
            affectedJobs.forEach(job => {
                if (!state.vehicles[job]) return;
                updates.forEach(u => {
                    if (u.job !== job) return;
                    const sv = state.vehicles[job].find(v => v.model === u.model);
                    if (sv) sv.sortOrder = u.sortOrder;
                });
                state.vehicles[job].sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
            });
            renderVehicles();

            const ok = await nuiPost('batchUpdateVehicleOrder', { updates });
            if (!ok) {
                showToast('Order save failed', 'error');
                await loadData();
            } else {
                showToast('Order saved!');
            }
        });
    });
}

function imgFallback(img, model) { loadVehicleImage(img, model); }

function getRoleLabel(job, roleName) {
    const r = state.roles.find(r => r.job === job && r.roleName === roleName);
    return r ? r.label : roleName;
}

function deleteVehicleConfirm(job, model, type) {
    const isConfig = type === 'config';
    const msg = isConfig
        ? `Hide <b>${esc(model)}</b> from the <b>${esc(job)}</b> garage?<br><br>Config vehicles can't be permanently deleted — this hides them from players. You can restore them at any time.`
        : `Permanently delete <b>${esc(model)}</b> from <b>${esc(job)}</b>?<br><br>This cannot be undone.`;
    openModal(
        isConfig ? 'Hide Config Vehicle' : 'Delete Vehicle',
        `<div style="padding:8px 0;line-height:1.6;color:var(--text-sec)">${msg}</div>`,
        async () => {
            const ok = await nuiPost('deleteVehicle', { job, model });
            if (ok) {
                showToast(isConfig ? 'Vehicle hidden' : 'Vehicle deleted');
                closeModal();
                await loadData();
            } else {
                showToast('Operation failed', 'error');
            }
        }
    );
    setTimeout(() => {
        const btn = document.getElementById('modal-save');
        if (btn) { btn.textContent = isConfig ? 'Hide Vehicle' : 'Delete'; btn.className = 'btn-danger'; }
    }, 0);
}

async function restoreVehicle(job, model) {
    const ok = await nuiPost('restoreVehicle', { job, model });
    if (ok) { showToast('Vehicle restored!'); await loadData(); }
    else showToast('Restore failed', 'error');
}

async function deleteVehicle(job, model) {
    deleteVehicleConfirm(job, model, 'db');
}

/* ── Livery auto-population ──────────────────────────────────────────────── */
let _liveryFetchTimer = null;
let _pendingLiveryValue = null; // holds index to re-select after list loads

function _setLiveryUnavailable() {
    const sel  = document.getElementById('f-vlivery');
    const hint = document.getElementById('f-vlivery-hint');
    if (!sel) return;
    sel.innerHTML = '<option value="">None available</option>';
    sel.disabled = true;
    if (hint) hint.textContent = 'This model has no liveries.';
}

async function fetchLiveryCount(model, preselect) {
    const sel  = document.getElementById('f-vlivery');
    const hint = document.getElementById('f-vlivery-hint');
    if (!sel) return;

    if (!model || model.trim() === '') { _setLiveryUnavailable(); return; }

    sel.innerHTML = '<option value="">Checking…</option>';
    sel.disabled = true;
    if (hint) hint.textContent = 'Checking livery count…';

    const result   = await nuiPost('getLiveryCount', { model: model.trim().toLowerCase() });
    const count    = (result && result.count) ? result.count : 0;
    const liveries = (result && result.liveries) ? result.liveries : [];

    // Re-check element still in DOM (modal may have been closed)
    const sel2  = document.getElementById('f-vlivery');
    const hint2 = document.getElementById('f-vlivery-hint');
    if (!sel2) return;

    if (count <= 0) {
        sel2.innerHTML = '<option value="">None available</option>';
        sel2.disabled  = true;
        if (hint2) hint2.textContent = 'This model has no liveries.';
    } else {
        sel2.disabled = false;
        let opts = '<option value="">— Default / No livery —</option>';
        liveries.forEach(lv => {
            const sel_ = (preselect != null && preselect === lv.index) ? ' selected' : '';
            opts += `<option value="${lv.index}"${sel_}>${esc(lv.name)} (${lv.index})</option>`;
        });
        sel2.innerHTML = opts;
        if (hint2) hint2.textContent = `${count} liveries available.`;
    }
}

function _liveryModelChanged() {
    // Debounce — wait 600 ms after the user stops typing
    clearTimeout(_liveryFetchTimer);
    const sel = document.getElementById('f-vlivery');
    if (sel) { sel.innerHTML = '<option value="">Loading…</option>'; sel.disabled = true; }
    _liveryFetchTimer = setTimeout(() => {
        const m = document.getElementById('f-vmodel')?.value.trim();
        if (m) fetchLiveryCount(m, null);
        else _setLiveryUnavailable();
    }, 600);
}

function openVehicleForm(v) {
    openVehicleFormWithReturn(v, null);
}

function updateRoleOptions(preselect) {
    const garageId = document.getElementById('f-vjob')?.value;
    const sel  = document.getElementById('f-vrole');
    if (!sel) return;
    // Resolve the real QBCore job from the selected garageId so we find the right roles
    const garage = garageId ? state.garages.find(g => (g.garageId || g.job) === garageId) : null;
    const actualJob = garage ? (garage.job || garageId) : garageId;
    const jobRoles = state.roles.filter(r => r.job === actualJob);
    sel.innerHTML = '<option value="">None</option>' +
        jobRoles.map(r =>
            `<option value="${esc(r.roleName)}" ${preselect === r.roleName ? 'selected' : ''}>${esc(r.label)} (${esc(r.roleName)})</option>`
        ).join('');
}

function previewVehicleImg() {
    const model = document.getElementById('f-vmodel')?.value.trim();
    const img   = document.getElementById('veh-preview-img');
    const icon  = document.getElementById('veh-preview-icon');
    if (!img) return;
    if (!model) { img.src = ''; if (icon) icon.style.display = ''; return; }
    if (icon) icon.style.display = 'none';
    loadVehicleImage(img, model);
}



function renderRoles() {
    const jobFilter = document.getElementById('role-job-filter').value;
    const list = document.getElementById('role-list');
    const items = state.roles.filter(r => !jobFilter || r.job === jobFilter);

    if (items.length === 0) {
        list.innerHTML = `<div class="empty-state"><i class="fas fa-id-badge"></i><span>No roles defined yet</span></div>`;
        return;
    }

    list.innerHTML = items.map(r => {
        const regKey = esc(r.job + '::' + r.roleName);
        _roleRegistry[r.job + '::' + r.roleName] = r;
        return `
        <div class="card">
            <div class="card-top">
                <div>
                    <div class="card-name">${esc(r.label)}</div>
                    <div class="card-model">${esc(r.roleName)}</div>
                </div>
            </div>
            <div class="card-meta">
                <span class="badge"><i class="fas fa-briefcase"></i> ${esc(r.job)}</span>
                <span class="badge amber"><i class="fas fa-users"></i> ${countPlayersWithRole(r.job, r.roleName)} players</span>
            </div>
            <div class="card-actions">
                <button class="btn-icon" onclick="openRoleForm(_roleRegistry['${regKey}'])">
                    <i class="fas fa-pen"></i> Edit
                </button>
                <button class="btn-icon del" onclick="deleteRole('${esc(r.job)}','${esc(r.roleName)}')">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `}).join('');
}

function countPlayersWithRole(job, roleName) {
    return state.playerRoles.filter(pr => pr.job === job && pr.roleName === roleName).length;
}

function openRoleForm(r) {
    const isNew = !r;
    const jobList    = state.jobsDisplay || state.jobs;
    const jobOptions = jobList.map(j =>
        `<option value="${esc(j.name)}" ${r && r.job === j.name ? 'selected' : ''}>${esc(j.label)} (${esc(j.name)})</option>`
    ).join('');

    const body = `
        <div class="form-grid single">
            <div class="form-group">
                <label>Job</label>
                <select id="f-rjob">${jobOptions}</select>
            </div>
            <div class="form-group">
                <label>Role Name <span style="color:var(--text-dim)">(internal key, no spaces)</span></label>
                <input type="text" id="f-rname" value="${r ? esc(r.roleName) : ''}" placeholder="swat" ${r ? 'readonly' : ''}>
                ${r ? '<span class="hint">Role name is locked after creation</span>' : ''}
            </div>
            <div class="form-group">
                <label>Label <span style="color:var(--text-dim)">(displayed in UI)</span></label>
                <input type="text" id="f-rlabel" value="${r ? esc(r.label) : ''}" placeholder="SWAT Team">
            </div>
        </div>
    `;

    openModal(isNew ? 'New Role' : 'Edit Role — ' + (r ? r.roleName : ''), body, async () => {
        const job     = document.getElementById('f-rjob').value;
        const name    = document.getElementById('f-rname').value.trim().replace(/\s+/g,'_');
        const label   = document.getElementById('f-rlabel').value.trim();
        if (!job || !name || !label) { showToast('All fields required', 'error'); return; }
        const ok = await nuiPost('saveRole', { job, roleName: name, label });
        if (ok) {
            showToast('Role saved!');
            closeModal();
            await loadData();
        } else {
            showToast('Save failed', 'error');
        }
    });
}

async function deleteRole(job, roleName) {
    openModal('Delete Role', `<div style="padding:8px 0;line-height:1.6;color:var(--text-sec)">Delete role <b>${esc(roleName)}</b> from <b>${esc(job)}</b>?<br><br>All player assignments for this role will also be removed.</div>`, async () => {
        await nuiPost('deleteRole', { job, roleName });
        showToast('Role deleted');
        closeModal();
        await loadData();
    });
    setTimeout(() => { const b = document.getElementById('modal-save'); if(b){b.textContent='Delete';b.className='btn-danger';} }, 0);
}

/* ═══════════════════════════════════════════════════════════════════
   TAB: PLAYER ROLES
   ─ "Use My ID" button fills citizenid from server
   ─ "Lookup by Server ID" looks up an online player's citizenid
═══════════════════════════════════════════════════════════════════ */
function renderPlayerRoles() {
    const jobFilter  = document.getElementById('pr-job-filter').value;
    const roleFilter = document.getElementById('pr-role-filter').value;
    const query      = document.getElementById('pr-search').value.toLowerCase();
    const list       = document.getElementById('playerrole-list');

    const items = state.playerRoles.filter(pr => {
        if (jobFilter  && pr.job     !== jobFilter)  return false;
        if (roleFilter && pr.roleName !== roleFilter) return false;
        if (query && !pr.citizenid.toLowerCase().includes(query)) return false;
        return true;
    });

    if (items.length === 0) {
        list.innerHTML = `<div class="empty-state"><i class="fas fa-users"></i><span>No player role assignments</span></div>`;
        return;
    }

    list.innerHTML = items.map(pr => {
        const roleLabel = getRoleLabel(pr.job, pr.roleName);
        return `
            <div class="card">
                <div class="card-top">
                    <div>
                        <div class="card-name">${esc(pr.citizenid)}</div>
                        <div class="card-model">${esc(roleLabel)} <span style="color:var(--text-dim)">(${esc(pr.roleName)})</span></div>
                    </div>
                </div>
                <div class="card-meta">
                    <span class="badge"><i class="fas fa-briefcase"></i> ${esc(pr.job)}</span>
                    <span class="badge"><i class="fas fa-user-shield"></i> By ${esc(pr.assignedBy)}</span>
                </div>
                <div class="card-actions">
                    <button class="btn-icon del" onclick="removePlayerRole('${esc(pr.citizenid)}','${esc(pr.job)}','${esc(pr.roleName)}')">
                        <i class="fas fa-user-minus"></i> Remove
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

function openPlayerRoleForm() {
    const jobList    = state.jobsDisplay || state.jobs;
    const jobOptions = jobList.map(j =>
        `<option value="${esc(j.name)}">${esc(j.label)} (${esc(j.name)})</option>`
    ).join('');

    const body = `
        <div class="form-grid single">
            <div class="form-group">
                <label>CitizenID</label>
                <div class="input-row">
                    <input type="text" id="f-pcid" placeholder="ABC12345">
                    <button class="btn-secondary" onclick="fillMyCitizenId()" title="Use your own CitizenID">
                        <i class="fas fa-user-check"></i> My ID
                    </button>
                </div>
                <span class="hint">Exact citizenid from the database</span>
            </div>
            <div class="form-group">
                <label>Lookup by Server ID <span style="color:var(--text-dim)">(online players)</span></label>
                <div class="input-row">
                    <input type="number" id="f-srvid" placeholder="e.g. 12" min="1">
                    <button class="btn-secondary" onclick="lookupByServerId()">
                        <i class="fas fa-search"></i> Find
                    </button>
                </div>
                <span class="hint">Enter a player's server ID to auto-fill their citizenid above</span>
            </div>
            <div class="form-group">
                <label>Job</label>
                <select id="f-pjob" onchange="updatePRoleOptions()">
                    <option value="">— select —</option>
                    ${jobOptions}
                </select>
            </div>
            <div class="form-group">
                <label>Role</label>
                <select id="f-prole">
                    <option value="">— select job first —</option>
                </select>
            </div>
        </div>
    `;

    openModal('Assign Player Role', body, async () => {
        const citizenid = document.getElementById('f-pcid').value.trim();
        const job       = document.getElementById('f-pjob').value;
        const roleName  = document.getElementById('f-prole').value;
        if (!citizenid || !job || !roleName) { showToast('All fields required', 'error'); return; }
        const ok = await nuiPost('assignPlayerRole', { citizenid, job, roleName });
        if (ok) {
            showToast('Role assigned!');
            closeModal();
            await loadData();
        } else {
            showToast('Assignment failed', 'error');
        }
    });
}

async function fillMyCitizenId() {
    // Ask server for our own citizenid
    const result = await nuiPost('getMyId');
    const fpcid = document.getElementById('f-pcid');
    if (fpcid && result && result.citizenid) {
        fpcid.value = result.citizenid;
        showToast('Filled with your CitizenID');
    }
}

async function lookupByServerId() {
    const srvId = document.getElementById('f-srvid')?.value;
    if (!srvId) { showToast('Enter a server ID first', 'error'); return; }
    const result = await nuiPost('lookupPlayerId', { serverId: parseInt(srvId) });
    const fpcid  = document.getElementById('f-pcid');
    if (result && result.citizenid && fpcid) {
        fpcid.value = result.citizenid;
        showToast('Found: ' + (result.name || result.citizenid));
    } else {
        showToast('Player not found (offline or invalid ID)', 'error');
    }
}

function updatePRoleOptions() {
    const job = document.getElementById('f-pjob')?.value;
    const sel = document.getElementById('f-prole');
    if (!sel) return;
    const jobRoles = state.roles.filter(r => r.job === job);
    sel.innerHTML = jobRoles.length
        ? '<option value="">— select role —</option>' + jobRoles.map(r =>
            `<option value="${esc(r.roleName)}">${esc(r.label)} (${esc(r.roleName)})</option>`
          ).join('')
        : '<option value="">No roles for this job</option>';
}

async function removePlayerRole(citizenid, job, roleName) {
    openModal('Remove Role', `<div style="padding:8px 0;line-height:1.6;color:var(--text-sec)">Remove role <b>${esc(roleName)}</b> from <b>${esc(citizenid)}</b>?</div>`, async () => {
        await nuiPost('removePlayerRole', { citizenid, job, roleName });
        showToast('Role removed');
        closeModal();
        await loadData();
    });
    setTimeout(() => { const b = document.getElementById('modal-save'); if(b){b.textContent='Remove';b.className='btn-danger';} }, 0);
}

/* ── Utils ───────────────────────────────────────────────────────── */
function esc(str) {
    if (str == null) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function fv(n) {
    return typeof n === 'number' ? n.toFixed(2) : n;
}