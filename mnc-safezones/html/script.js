let currentZones    = [];
let pendingPoints   = [];
let minPoints       = 4;
let pendingDeleteId = null;
let pendingDeleteName = '';
let editingZoneId   = null; // null = creating a new zone, otherwise the id being edited

// ── Message listener from client.lua ────────────────────────────────────────
window.addEventListener('message', (event) => {
    const { action } = event.data;

    if (action === 'openMenu' || action === 'reopenMenu') {
        currentZones  = event.data.zones || [];
        pendingPoints = event.data.pendingPoints || [];
        minPoints     = event.data.minPoints || 4;
        const minPointsHintEl = document.getElementById('minPointsHint');
        if (minPointsHintEl) minPointsHintEl.textContent = minPoints;
        document.getElementById('container').classList.remove('hidden');
        renderZones();
        renderPoints();
    }

    // Freecam takes over the screen — hide the panel until it's done. The
    // client sends 'reopenMenu' (above) as soon as freecam exits.
    if (action === 'hideMenuForFreecam') {
        document.getElementById('container').classList.add('hidden');
    }

    // Fires whenever the server-side zone list changes for any reason —
    // resource (re)start, another admin adding/removing a zone, this admin's
    // own create/delete, etc. Re-renders the list live, whether or not the
    // panel happens to be open right now, so it's never showing stale data.
    if (action === 'updateZoneList') {
        currentZones = event.data.zones || [];
        renderZones();
    }

    if (action === 'setPendingPoints') {
        pendingPoints = event.data.points || [];
        renderPoints();
    }

    // The client seeded PendingPoints from an existing zone (real points for
    // a polygon, an approximated square for a legacy circle) — load it all
    // into the form and switch the panel into edit mode.
    if (action === 'editZone') {
        editingZoneId = event.data.id;
        document.getElementById('zoneName').value = event.data.name || '';
        document.getElementById('height').value = event.data.height || 20;
        pendingPoints = event.data.points || [];
        renderPoints();
        enterEditMode(event.data.isLegacyCircle);
    }

    // ── Zone HUD ──────────────────────────────────────────────────────────
    if (action === 'showZoneHUD') {
        const hud    = document.getElementById('zoneHUD');
        const icon   = document.getElementById('hudIcon');
        const status = document.getElementById('hudStatus');

        document.getElementById('hudName').textContent = event.data.name;

        if (event.data.exempt) {
            hud.className        = 'hud-visible hud-exempt';
            icon.textContent     = '⚡';
            status.textContent   = 'Exempt · Combat Allowed';
        } else {
            hud.className        = 'hud-visible hud-restricted';
            icon.textContent     = '🛡';
            status.textContent   = 'Combat Restricted';
        }
    }

    if (action === 'hideZoneHUD') {
        const hud = document.getElementById('zoneHUD');
        hud.className = 'hud-hidden';
    }

    // ── Freecam legend ───────────────────────────────────────────────────────
    if (action === 'showFreecamLegend') {
        document.getElementById('freecamLegend').className = 'hud-visible';
        document.getElementById('legendPointCount').textContent = event.data.points || 0;
    }

    if (action === 'hideFreecamLegend') {
        document.getElementById('freecamLegend').className = 'hud-hidden';
    }

    if (action === 'updateFreecamPointCount') {
        document.getElementById('legendPointCount').textContent = event.data.points || 0;
    }
});

// ── Render captured points for the zone currently being marked out ──────────
function renderPoints() {
    const list  = document.getElementById('pointsList');
    const count = document.getElementById('pointsCount');
    count.textContent = pendingPoints.length;
    list.innerHTML = '';

    if (pendingPoints.length === 0) {
        list.innerHTML = '<p class="empty-msg" id="pointsEmptyMsg">No points captured yet.</p>';
        return;
    }

    pendingPoints.forEach((pt, idx) => {
        const div = document.createElement('div');
        div.className = 'point-item';
        div.innerHTML = `
            <span class="point-index">#${idx + 1}</span>
            <span class="point-coords">${pt.x.toFixed(2)}, ${pt.y.toFixed(2)}, ${pt.z.toFixed(2)}</span>
            <button class="btn-remove-point" onclick="removePendingPoint(${idx})">✖</button>
        `;
        list.appendChild(div);
    });
}

function addManualPoint() {
    const x = parseFloat(document.getElementById('mx').value);
    const y = parseFloat(document.getElementById('my').value);
    const z = parseFloat(document.getElementById('mz').value);

    if (isNaN(x) || isNaN(y) || isNaN(z)) { flashInput('mx', 'Enter X, Y and Z, or use the buttons above'); return; }

    fetch(`https://${GetParentResourceName()}/addPendingPoint`, {
        method: 'POST',
        body: JSON.stringify({ x, y, z })
    });

    document.getElementById('mx').value = '';
    document.getElementById('my').value = '';
    document.getElementById('mz').value = '';
}

function removePendingPoint(idx) {
    fetch(`https://${GetParentResourceName()}/removePendingPoint`, {
        method: 'POST',
        body: JSON.stringify({ index: idx })
    });
}

function clearPendingPoints() {
    fetch(`https://${GetParentResourceName()}/clearPendingPoints`, { method: 'POST' });
}

// ── Point capture actions ────────────────────────────────────────────────────
function capturePosition() {
    fetch(`https://${GetParentResourceName()}/capturePosition`, { method: 'POST' });
}

function startFreecam() {
    // The client hides this panel and releases NUI focus as soon as it gets
    // this callback, then brings the panel back automatically when the admin
    // presses Esc in-world.
    fetch(`https://${GetParentResourceName()}/startFreecam`, { method: 'POST' });
}

// ── Edit mode ─────────────────────────────────────────────────────────────────
function editZone(id) {
    fetch(`https://${GetParentResourceName()}/editZone`, {
        method: 'POST',
        body: JSON.stringify({ id })
    });
}

function enterEditMode(isLegacyCircle) {
    document.getElementById('formHeader').textContent = '✏️ Editing Safe Zone';
    document.getElementById('saveZoneBtn').textContent = '💾 Save Changes';
    document.getElementById('cancelEditBtn').classList.remove('hidden');
    // A dedicated element for this notice (rather than overwriting #coordHint's
    // innerHTML) so the <strong id="minPointsHint"> span inside #coordHint is
    // never removed from the DOM — the panel can safely be reopened later
    // without other code crashing on a missing element.
    document.getElementById('legacyCircleNotice').classList.toggle('hidden', !isLegacyCircle);
}

function exitEditMode() {
    editingZoneId = null;
    document.getElementById('formHeader').textContent = '➕ Add New Safe Zone';
    document.getElementById('saveZoneBtn').textContent = '✔ Create Safe Zone';
    document.getElementById('cancelEditBtn').classList.add('hidden');
    document.getElementById('legacyCircleNotice').classList.add('hidden');
    document.getElementById('zoneName').value = '';
    document.getElementById('height').value = '20';
}

function cancelEdit() {
    exitEditMode();
    clearPendingPoints(); // also clears the Lua-side PendingPoints
}

// ── Render zone list ─────────────────────────────────────────────────────────
function renderZones() {
    const list  = document.getElementById('zoneList');
    const badge = document.getElementById('zoneCount');
    badge.textContent = currentZones.length;
    list.innerHTML = '';

    if (currentZones.length === 0) {
        list.innerHTML = '<p class="empty-msg">No safe zones created yet.</p>';
        return;
    }

    currentZones.forEach(zone => {
        const div = document.createElement('div');
        div.className = 'zone-item';

        const shapeMeta = zone.shape === 'circle'
            ? `⭕ Legacy circle · ${zone.radius}m radius`
            : `📐 ${(zone.points || []).length} points`;

        div.innerHTML = `
            <div class="zone-info">
                <strong>${escapeHtml(zone.name)}</strong>
                <span class="zone-meta">
                    ${shapeMeta} &nbsp;|&nbsp; ↕ ${zone.height}m
                    &nbsp;|&nbsp; <span class="zone-id">ID: ${zone.id}</span>
                </span>
            </div>
            <div class="zone-actions">
                <button class="btn-edit" onclick="editZone(${zone.id})">✏️ Edit</button>
                <button class="btn-delete" onclick="promptDelete(${zone.id}, '${escapeHtml(zone.name)}')">🗑 Delete</button>
            </div>
        `;
        list.appendChild(div);
    });
}

// ── Create or save a zone (edit mode is tracked by editingZoneId) ────────────
function saveZone() {
    const name   = document.getElementById('zoneName').value.trim();
    const height = parseFloat(document.getElementById('height').value);

    if (!name)                        { flashInput('zoneName', 'Zone name is required'); return; }
    if (pendingPoints.length < minPoints) {
        flashInput('zoneName', `Capture at least ${minPoints} points first`);
        return;
    }
    if (isNaN(height) || height < 2)  { flashInput('height', 'Minimum height is 2m'); return; }

    if (editingZoneId !== null) {
        fetch(`https://${GetParentResourceName()}/saveZoneEdit`, {
            method: 'POST',
            body: JSON.stringify({ id: editingZoneId, name, height, points: pendingPoints })
        });
        exitEditMode();
    } else {
        fetch(`https://${GetParentResourceName()}/addZone`, {
            method: 'POST',
            body: JSON.stringify({ name, height, points: pendingPoints })
        });
        document.getElementById('zoneName').value = '';
        document.getElementById('height').value  = '20';
    }
}

// ── Delete with confirm modal ────────────────────────────────────────────────
function promptDelete(id, name) {
    pendingDeleteId   = id;
    pendingDeleteName = name;
    document.getElementById('confirmText').textContent = `Delete "${name}"? This cannot be undone.`;
    document.getElementById('confirmModal').classList.remove('hidden');
}

function cancelDelete() {
    pendingDeleteId   = null;
    pendingDeleteName = '';
    document.getElementById('confirmModal').classList.add('hidden');
}

function confirmDelete() {
    if (pendingDeleteId === null) return;
    fetch(`https://${GetParentResourceName()}/removeZone`, {
        method: 'POST',
        body: JSON.stringify({ id: pendingDeleteId })
    });
    document.getElementById('confirmModal').classList.add('hidden');
    pendingDeleteId   = null;
    pendingDeleteName = '';
}

// ── Close menu ───────────────────────────────────────────────────────────────
function closeMenu() {
    document.getElementById('container').classList.add('hidden');
    document.getElementById('confirmModal').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/closeMenu`, { method: 'POST' });
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (!document.getElementById('confirmModal').classList.contains('hidden')) {
            cancelDelete();
        } else {
            closeMenu();
        }
    }
});

// ── Helpers ──────────────────────────────────────────────────────────────────
function escapeHtml(str) {
    return String(str)
        .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;').replace(/'/g,'&#039;');
}

function flashInput(id, msg) {
    const el = document.getElementById(id);
    el.style.borderColor = '#ff4444';
    el.title = msg;
    el.focus();
    setTimeout(() => { el.style.borderColor = ''; el.title = ''; }, 2000);
}