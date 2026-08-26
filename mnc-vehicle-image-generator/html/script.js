let vehicleCategories = [];
let isCapturing = false;
let isPaused = false;
let selectedVehicles = [];
let isPreviewActive = false;
let originalCameraSettings = {};
let currentCameraSettings = {};
let completedVehicles = new Set();
let chunkSize = 25;
let pendingResumeIndex = null;

let captureStartTime = null;
let etaHistory = [];

// ==================== MESSAGE HANDLER ====================
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        document.body.classList.add('visible');
        vehicleCategories = data.vehicles || [];
        chunkSize = data.chunkSize || 25;

        if (data.completedVehicles && Array.isArray(data.completedVehicles)) {
            completedVehicles = new Set(data.completedVehicles);
        } else {
            completedVehicles = new Set();
        }

        loadVehicles();
        updateDoneCount();

        if (data.webhook) {
            document.getElementById('webhookInput').value = data.webhook;
        }

        if (data.cameraSettings) {
            originalCameraSettings = JSON.parse(JSON.stringify(data.cameraSettings));
            currentCameraSettings = JSON.parse(JSON.stringify(data.cameraSettings));
            loadCameraSettings(currentCameraSettings);
        }

        document.getElementById('chunkSizeInput').value = chunkSize;

    } else if (data.action === 'close') {
        document.body.classList.remove('visible');
    } else if (data.action === 'updateProgress') {
        updateProgress(data.current, data.total, data.vehicleName);
    } else if (data.action === 'captureComplete') {
        captureComplete();
    } else if (data.action === 'chunkComplete') {
        chunkPause(data.nextIndex, data.total);
    } else if (data.action === 'markDone') {
        markVehicleDone(data.model);
    } else if (data.action === 'skipVehicle') {
        const progressText = document.getElementById('progressText');
        if (progressText) progressText.textContent = `⚠️ Skipped: ${data.label}`;
    } else if (data.action === 'previewFailed') {
        const previewBtn = document.getElementById('previewBtn');
        if (previewBtn) {
            previewBtn.classList.remove('active');
            previewBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/></svg> Preview`;
        }
    }
});

// ==================== VEHICLE FUNCTIONS ====================
function loadVehicles() {
    const grid = document.getElementById('vehicleGrid');
    grid.innerHTML = '';

    if (!vehicleCategories || vehicleCategories.length === 0) {
        grid.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; padding: 60px 20px; color: #777;">
                <strong>No vehicles available</strong><br>
                <small>Clear completed vehicles or restart the resource</small>
            </div>`;
        updateBadge();
        return;
    }

    vehicleCategories.forEach(vehicle => {
        const isDone = completedVehicles.has(vehicle.id);
        const div = document.createElement('div');
        div.className = `vehicle-checkbox ${isDone ? 'done' : ''}`;
        
        div.innerHTML = `
            <input type="checkbox" id="vehicle_${vehicle.id}" value="${vehicle.id}" ${isDone ? 'disabled' : ''}>
            <label for="vehicle_${vehicle.id}">${vehicle.label}</label>
        `;
        
        grid.appendChild(div);

        if (!isDone) {
            div.addEventListener('click', function(e) {
                if (e.target.tagName !== 'INPUT') {
                    const input = div.querySelector('input');
                    input.checked = !input.checked;
                }
                updateBadge();
            });
            div.querySelector('input').addEventListener('change', updateBadge);
        }
    });

    updateBadge();
}

function updateBadge() {
    const count = document.querySelectorAll('.vehicle-checkbox input:checked').length;
    const badge = document.getElementById('selectionBadge');
    if (badge) badge.textContent = count === 0 ? '0 selected' : `${count} selected`;
}

function updateDoneCount() {
    const doneEl = document.getElementById('doneBadge');
    if (doneEl) doneEl.textContent = `${completedVehicles.size} done`;
}

function markVehicleDone(model) {
    completedVehicles.add(model);
    const checkbox = document.getElementById('vehicle_' + model);
    if (checkbox) {
        const wrapper = checkbox.closest('.vehicle-checkbox');
        if (wrapper) {
            wrapper.classList.add('done');
            checkbox.disabled = true;
        }
    }
    updateDoneCount();
    updateBadge();
}

// ==================== UI BUTTONS ====================
document.getElementById('closeBtn').addEventListener('click', closeUI);

function closeUI() {
    document.body.classList.remove('visible');
    if (isPreviewActive) stopPreview();
    fetch(`https://mnc-vehicle-image-generator/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

document.getElementById('settingsBtn').addEventListener('click', () => {
    document.getElementById('settingsModal').style.display = 'flex';
});

document.getElementById('closeModal').addEventListener('click', () => {
    document.getElementById('settingsModal').style.display = 'none';
});

// Tab switching
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
    });
});


document.getElementById('testWebhook').addEventListener('click', function() {
    const webhook = document.getElementById('webhookInput').value.trim();
    if (!webhook) { alert('Please enter a webhook URL'); return; }
    fetch(`https://mnc-vehicle-image-generator/testWebhook`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ webhook })
    });
});

document.getElementById('selectAll').addEventListener('click', () => {
    document.querySelectorAll('.vehicle-checkbox:not(.done) input[type="checkbox"]').forEach(cb => cb.checked = true);
    updateBadge();
});

document.getElementById('deselectAll').addEventListener('click', () => {
    document.querySelectorAll('.vehicle-checkbox input[type="checkbox"]').forEach(cb => cb.checked = false);
    updateBadge();
});

document.getElementById('selectUndone').addEventListener('click', () => {
    document.querySelectorAll('.vehicle-checkbox input[type="checkbox"]').forEach(cb => cb.checked = false);
    document.querySelectorAll('.vehicle-checkbox:not(.done) input[type="checkbox"]').forEach(cb => cb.checked = true);
    updateBadge();
});

document.getElementById('selectBatch250').addEventListener('click', () => {
    let count = 0;
    document.querySelectorAll('.vehicle-checkbox:not(.done) input[type="checkbox"]').forEach(cb => {
        if (count < 250 && !cb.checked) {
            cb.checked = true;
            count++;
        }
    });
    updateBadge();
});

document.getElementById('chunkSizeInput').addEventListener('change', function() {
    chunkSize = parseInt(this.value) || 25;
    if (chunkSize < 5) chunkSize = 5;
    if (chunkSize > 200) chunkSize = 200;
    this.value = chunkSize;
});

// Capture Controls
document.getElementById('startCapture').addEventListener('click', function() {
    const webhook = document.getElementById('webhookInput').value.trim();
    const checkboxes = document.querySelectorAll('.vehicle-checkbox input[type="checkbox"]:checked');

    if (!webhook || !webhook.includes('discord.com/api/webhooks/')) {
        alert('Please enter a valid Discord webhook URL');
        return;
    }
    if (checkboxes.length === 0) {
        alert('Please select at least one vehicle');
        return;
    }

    if (isPreviewActive) stopPreview();

    selectedVehicles = [];
    checkboxes.forEach(cb => {
        const vehicle = vehicleCategories.find(v => v.id === cb.value);
        if (vehicle) selectedVehicles.push(vehicle);
    });

    isPaused = false;
    pendingResumeIndex = null;
    isCapturing = true;
    captureStartTime = Date.now();
    etaHistory = [];

    document.getElementById('startCapture').disabled = true;
    document.getElementById('stopCapture').disabled = false;
    document.getElementById('progressSection').style.display = 'block';

    const cameraSettings = getCurrentCameraSettings();
    fetch(`https://mnc-vehicle-image-generator/startCapture`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ webhook, vehicles: selectedVehicles, cameraSettings, chunkSize })
    });
});

document.getElementById('stopCapture').addEventListener('click', function() {
    isCapturing = false;
    isPaused = false;
    pendingResumeIndex = null;
    if (chunkResumeInterval) { clearInterval(chunkResumeInterval); chunkResumeInterval = null; }
    document.getElementById('chunkStatus').style.display = 'none';
    document.getElementById('startCapture').disabled = false;
    document.getElementById('stopCapture').disabled = true;
    fetch(`https://mnc-vehicle-image-generator/stopCapture`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.getElementById('resumeCapture').addEventListener('click', triggerResume);

let chunkResumeInterval = null;

function chunkPause(nextIndex, total) {
    isPaused = true;
    pendingResumeIndex = nextIndex;
    const chunksEl = document.getElementById('chunkStatus');
    chunksEl.style.display = 'block';

    // Count down 5 seconds then auto-resume
    let countdown = 5;
    chunksEl.textContent = `Chunk complete — ${nextIndex - 1}/${total}. Resuming in ${countdown}s...`;

    chunkResumeInterval = setInterval(function() {
        countdown--;
        if (countdown <= 0) {
            clearInterval(chunkResumeInterval);
            chunkResumeInterval = null;
            chunksEl.textContent = `Resuming...`;
            triggerResume();
        } else {
            chunksEl.textContent = `Chunk complete — ${nextIndex - 1}/${total}. Resuming in ${countdown}s...`;
        }
    }, 1000);
}

function triggerResume() {
    if (pendingResumeIndex === null) return;
    isPaused = false;
    document.getElementById('chunkStatus').style.display = 'none';
    const webhook = document.getElementById('webhookInput').value.trim();
    fetch(`https://mnc-vehicle-image-generator/resumeCapture`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nextIndex: pendingResumeIndex, webhook: webhook })
    });
    pendingResumeIndex = null;
}

function updateProgress(current, total, vehicleName) {
    const pct = Math.round((current / total) * 100);
    document.getElementById('progressFill').style.width = pct + '%';
    document.getElementById('progressText').textContent = `${current} / ${total} — ${vehicleName}`;
    document.getElementById('progressPct').textContent = pct + '%';

    if (captureStartTime && current > 0) {
        const elapsed = Date.now() - captureStartTime;
        const msPerVehicle = elapsed / current;
        etaHistory.push(msPerVehicle);
        if (etaHistory.length > 10) etaHistory.shift();

        const avgMs = etaHistory.reduce((a, b) => a + b, 0) / etaHistory.length;
        const remaining = avgMs * (total - current);
        document.getElementById('progressEta').textContent = '~' + formatEta(remaining);
    }
}

function formatEta(ms) {
    const totalSec = Math.ceil(ms / 1000);
    if (totalSec < 60) return totalSec + 's';
    const m = Math.floor(totalSec / 60);
    const s = totalSec % 60;
    return s > 0 ? `${m}m ${s}s` : `${m}m`;
}

function captureComplete() {
    isCapturing = false;
    document.getElementById('startCapture').disabled = false;
    document.getElementById('stopCapture').disabled = true;
    document.getElementById('progressEta').textContent = 'Done';
}

// ==================== CAMERA SETTINGS ====================
function loadCameraSettings(settings) {
    setVal('spawnX', 'spawnXSlider', settings.coords.x);
    setVal('spawnY', 'spawnYSlider', settings.coords.y);
    setVal('spawnZ', 'spawnZSlider', settings.coords.z);
    setVal('heading', 'headingSlider', settings.heading);
    setVal('camOffsetX', 'camOffsetXSlider', settings.cameraOffset.x);
    setVal('camOffsetY', 'camOffsetYSlider', settings.cameraOffset.y);
    setVal('camOffsetZ', 'camOffsetZSlider', settings.cameraOffset.z);
    setVal('camRotX', 'camRotXSlider', settings.cameraRotation.x);
    setVal('camRotY', 'camRotYSlider', settings.cameraRotation.y);
    setVal('camRotZ', 'camRotZSlider', settings.cameraRotation.z);
    setVal('fov', 'fovSlider', settings.fov);
}

function setVal(inputId, sliderId, value) {
    const input = document.getElementById(inputId);
    const slider = document.getElementById(sliderId);
    if (input) input.value = value;
    if (slider) slider.value = value;
}

function getCurrentCameraSettings() {
    return {
        coords: {
            x: parseFloat(document.getElementById('spawnX').value),
            y: parseFloat(document.getElementById('spawnY').value),
            z: parseFloat(document.getElementById('spawnZ').value)
        },
        heading: parseFloat(document.getElementById('heading').value),
        cameraOffset: {
            x: parseFloat(document.getElementById('camOffsetX').value),
            y: parseFloat(document.getElementById('camOffsetY').value),
            z: parseFloat(document.getElementById('camOffsetZ').value)
        },
        cameraRotation: {
            x: parseFloat(document.getElementById('camRotX').value),
            y: parseFloat(document.getElementById('camRotY').value),
            z: parseFloat(document.getElementById('camRotZ').value)
        },
        fov: parseFloat(document.getElementById('fov').value)
    };
}

function syncInputs(inputId, sliderId) {
    const input = document.getElementById(inputId);
    const slider = document.getElementById(sliderId);
    if (!input || !slider) return;

    input.addEventListener('input', () => {
        slider.value = input.value;
        if (isPreviewActive) updatePreview();
    });
    slider.addEventListener('input', () => {
        input.value = slider.value;
        if (isPreviewActive) updatePreview();
    });
}

// Sync all camera inputs
['spawnX','spawnY','spawnZ','heading','camOffsetX','camOffsetY','camOffsetZ','camRotX','camRotY','camRotZ','fov'].forEach(key => {
    syncInputs(key, key + 'Slider');
});

document.getElementById('cameraHeader').addEventListener('click', function() {
    this.classList.toggle('collapsed');
    document.getElementById('cameraContent').classList.toggle('collapsed');
});

document.getElementById('previewBtn').addEventListener('click', function() {
    if (isCapturing) {
        closeUI();
        return;
    }

    isPreviewActive = !isPreviewActive;
    this.classList.toggle('active');
    
    if (isPreviewActive) {
        this.innerHTML = `Stop Preview`;
        document.getElementById('mainContainer').style.display = 'none';
        document.getElementById('previewShowBtn').style.display = 'flex';
        startPreview();
    } else {
        this.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/></svg> Preview`;
        document.getElementById('mainContainer').style.display = 'flex';
        document.getElementById('previewShowBtn').style.display = 'none';
        stopPreview();
    }
});

document.getElementById('previewShowBtn').addEventListener('click', () => {
    document.getElementById('mainContainer').style.display = 'flex';
    document.getElementById('previewShowBtn').style.display = 'none';
});

document.getElementById('resetBtn').addEventListener('click', function() {
    currentCameraSettings = JSON.parse(JSON.stringify(originalCameraSettings));
    loadCameraSettings(currentCameraSettings);
    if (isPreviewActive) updatePreview();
});

document.getElementById('saveConfigBtn').addEventListener('click', function() {
    fetch(`https://mnc-vehicle-image-generator/saveConfig`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cameraSettings: getCurrentCameraSettings() })
    });
});

function startPreview() {
    fetch(`https://mnc-vehicle-image-generator/startPreview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cameraSettings: getCurrentCameraSettings() })
    });
}

function updatePreview() {
    fetch(`https://mnc-vehicle-image-generator/updatePreview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cameraSettings: getCurrentCameraSettings() })
    });
}

function stopPreview() {
    fetch(`https://mnc-vehicle-image-generator/stopPreview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Keyboard
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const modal = document.getElementById('settingsModal');
        if (modal.style.display === 'flex') {
            modal.style.display = 'none';
        } else {
            closeUI();
        }
    }
});
// ==================== DRAGGABLE UI ====================
(function() {
    const container = document.getElementById('mainContainer');
    const handle = document.getElementById('dragHandle');
    let isDragging = false;
    let startX, startY, startLeft, startTop;
    let posLeft = null;
    let posTop = null;

    function initPosition() {
        if (posLeft !== null) return;
        const rect = container.getBoundingClientRect();
        posLeft = rect.left;
        posTop = rect.top;
        container.style.transform = 'none';
        container.style.left = posLeft + 'px';
        container.style.top = posTop + 'px';
    }

    // Resolve transform immediately so opacity always works
    window.addEventListener('message', function(e) {
        if (e.data && e.data.action === 'open') {
            setTimeout(initPosition, 50);
        }
    });

    handle.addEventListener('mousedown', function(e) {
        e.preventDefault();
        initPosition();
        isDragging = true;
        container.classList.add('dragging');
        startX = e.clientX;
        startY = e.clientY;
        startLeft = posLeft;
        startTop = posTop;
    });

    document.addEventListener('mousemove', function(e) {
        if (!isDragging) return;
        const dx = e.clientX - startX;
        const dy = e.clientY - startY;
        const vw = window.innerWidth;
        const vh = window.innerHeight;
        const cw = container.offsetWidth;
        const ch = container.offsetHeight;

        posLeft = Math.max(0, Math.min(vw - cw, startLeft + dx));
        posTop  = Math.max(0, Math.min(vh - ch, startTop  + dy));

        container.style.left = posLeft + 'px';
        container.style.top  = posTop  + 'px';
    });

    document.addEventListener('mouseup', function() {
        if (isDragging) {
            isDragging = false;
            container.classList.remove('dragging');
        }
    });
})();

// ==================== OPACITY SLIDER ====================
document.getElementById('opacitySlider').addEventListener('input', function() {
    // Resolve CSS transform before applying opacity to avoid stacking context issues
    const container = document.getElementById('mainContainer');
    if (container.style.transform !== 'none') {
        const rect = container.getBoundingClientRect();
        container.style.transform = 'none';
        container.style.left = rect.left + 'px';
        container.style.top = rect.top + 'px';
    }
    container.style.opacity = this.value / 100;
});

// ==================== RESIZABLE UI ====================
(function() {
    const container = document.getElementById('mainContainer');
    const MIN_W = 420, MIN_H = 300;
    const handles = ['n','s','e','w','nw','ne','sw','se'];

    // Inject resize handle divs
    handles.forEach(dir => {
        const el = document.createElement('div');
        el.className = `resize-handle ${dir}`;
        el.dataset.dir = dir;
        container.appendChild(el);
    });

    let isResizing = false;
    let resizeDir = '';
    let startX, startY, startW, startH, startL, startT;

    container.addEventListener('mousedown', function(e) {
        const handle = e.target.closest('.resize-handle');
        if (!handle) return;
        e.preventDefault();
        e.stopPropagation();

        // Resolve transform to pixel position first
        if (container.style.transform && container.style.transform !== 'none') {
            const rect = container.getBoundingClientRect();
            container.style.transform = 'none';
            container.style.left = rect.left + 'px';
            container.style.top = rect.top + 'px';
        }

        isResizing = true;
        resizeDir = handle.dataset.dir;
        startX = e.clientX;
        startY = e.clientY;
        startW = container.offsetWidth;
        startH = container.offsetHeight;
        startL = parseInt(container.style.left) || container.getBoundingClientRect().left;
        startT = parseInt(container.style.top)  || container.getBoundingClientRect().top;
        document.body.style.userSelect = 'none';
        document.body.style.cursor = handle.style.cursor || `${resizeDir}-resize`;
    });

    document.addEventListener('mousemove', function(e) {
        if (!isResizing) return;
        const dx = e.clientX - startX;
        const dy = e.clientY - startY;
        let newW = startW, newH = startH, newL = startL, newT = startT;

        if (resizeDir.includes('e')) newW = Math.max(MIN_W, startW + dx);
        if (resizeDir.includes('s')) newH = Math.max(MIN_H, startH + dy);
        if (resizeDir.includes('w')) {
            newW = Math.max(MIN_W, startW - dx);
            newL = startL + (startW - newW);
        }
        if (resizeDir.includes('n')) {
            newH = Math.max(MIN_H, startH - dy);
            newT = startT + (startH - newH);
        }

        container.style.width  = newW + 'px';
        container.style.height = newH + 'px';
        container.style.left   = newL + 'px';
        container.style.top    = newT + 'px';
        container.style.maxHeight = 'none';
    });

    document.addEventListener('mouseup', function() {
        if (isResizing) {
            isResizing = false;
            document.body.style.userSelect = '';
            document.body.style.cursor = '';
        }
    });
})();