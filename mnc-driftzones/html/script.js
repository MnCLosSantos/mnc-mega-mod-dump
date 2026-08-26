// html/script.js

const popup = document.getElementById('zonePopup');
const nameEl = document.getElementById('zoneName');
const enterAudio = document.getElementById('enterSound');
const exitAudio = document.getElementById('exitSound');

const crosshair = document.getElementById('setupCrosshair');
const setupPanel = document.getElementById('setupPanel');
const setupPanelLabel = document.getElementById('setupPanelLabel');
const setupZoneName = document.getElementById('setupZoneName');
const setupPointCount = document.getElementById('setupPointCount');
const setupPointsList = document.getElementById('setupPointsList');

const managementPanel = document.getElementById('managementPanel');
const mgmtZonesList = document.getElementById('mgmtZonesList');
const zoneForm = document.getElementById('zoneForm');
const zoneFormError = document.getElementById('zoneFormError');

let setupMinPoints = 3;
let currentZones = [];
let mgmtDefaults = { thickness: 40, minPoints: 3 };

function postNUI(name, data) {
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

function setVolume(vol) {
  if (typeof vol !== 'number') return;
  enterAudio.volume = vol;
  exitAudio.volume = vol;
}

function playSound(sound) {
  const audio = sound === 'exit' ? exitAudio : enterAudio;
  try {
    audio.pause();
    audio.currentTime = 0;
    audio.play().catch(() => {
      // Autoplay can be blocked before the first user/game interaction -
      // safe to ignore, FiveM's NUI frame counts as interacted after load.
    });
  } catch (e) {
    // no-op
  }
}

//------------------------------------------------------------------
// Zone setup panel (freecam point list)
//------------------------------------------------------------------

function showSetupPanel(name, minPoints, editing) {
  setupMinPoints = typeof minPoints === 'number' ? minPoints : 3;
  setupPanelLabel.textContent = editing ? 'Editing Drift Zone' : 'Building Drift Zone';
  setupZoneName.textContent = name || 'Zone Name';
  setupPanel.classList.add('visible');
  renderSetupPoints([]);
}

function hideSetupPanel() {
  setupPanel.classList.remove('visible');
  setupPointsList.innerHTML = '';
}

function renderSetupPoints(points) {
  points = points || [];

  const remaining = Math.max(0, setupMinPoints - points.length);
  setupPointCount.textContent = remaining > 0
    ? `${points.length} point${points.length === 1 ? '' : 's'} (need ${remaining} more)`
    : `${points.length} point${points.length === 1 ? '' : 's'} - ready to save`;
  setupPointCount.classList.toggle('ready', remaining === 0);

  setupPointsList.innerHTML = '';
  points.forEach((p, i) => {
    const li = document.createElement('li');
    li.className = 'setup-point';

    const idx = document.createElement('span');
    idx.className = 'setup-point-index';
    idx.textContent = i + 1;

    const coords = document.createElement('span');
    coords.className = 'setup-point-coords';
    coords.textContent = `${p.x}, ${p.y}, ${p.z}`;

    li.appendChild(idx);
    li.appendChild(coords);
    setupPointsList.appendChild(li);
  });

  setupPointsList.scrollTop = setupPointsList.scrollHeight;
}

//------------------------------------------------------------------
// /driftzones management panel
//------------------------------------------------------------------

function mgmtBtn(label, onClick, extraClass) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = `mgmt-btn ${extraClass || ''}`.trim();
  btn.textContent = label;
  btn.addEventListener('click', onClick);
  return btn;
}

function renderZonesList(zones) {
  mgmtZonesList.innerHTML = '';

  if (!zones.length) {
    const li = document.createElement('li');
    li.className = 'mgmt-empty';
    li.textContent = 'No zones yet - create one to get started';
    mgmtZonesList.appendChild(li);
    return;
  }

  zones.forEach((z) => {
    const li = document.createElement('li');
    li.className = 'mgmt-item';

    const info = document.createElement('div');
    info.className = 'mgmt-item-info';

    const title = document.createElement('div');
    title.className = 'mgmt-item-title';
    title.textContent = z.name;

    const meta = document.createElement('div');
    meta.className = 'mgmt-item-meta';
    meta.textContent = `${z.pointCount} pts • thickness ${z.thickness}`;

    info.appendChild(title);
    info.appendChild(meta);

    const actions = document.createElement('div');
    actions.className = 'mgmt-item-actions';
    actions.appendChild(mgmtBtn('Edit Info', () => openZoneForm(z)));
    actions.appendChild(mgmtBtn('Edit Points', () => postNUI('driftzones:editZonePoints', { zoneId: z.id })));
    actions.appendChild(mgmtBtn('Delete', () => {
      if (confirm(`Delete zone "${z.name}"?`)) {
        postNUI('driftzones:deleteZone', { zoneId: z.id });
      }
    }, 'mgmt-btn-danger'));

    li.appendChild(info);
    li.appendChild(actions);
    mgmtZonesList.appendChild(li);
  });
}

function showManagement(data) {
  currentZones = data.zones || [];
  mgmtDefaults = data.defaults || mgmtDefaults;
  renderZonesList(currentZones);
  managementPanel.classList.add('visible');
}

function hideManagement() {
  managementPanel.classList.remove('visible');
  zoneForm.classList.remove('visible');
}

function refreshManagement(data) {
  currentZones = data.zones || [];
  renderZonesList(currentZones);
}

document.getElementById('mgmtClose').addEventListener('click', () => postNUI('driftzones:close'));
document.getElementById('mgmtAddZone').addEventListener('click', () => openZoneForm(null));

//------------------------------------------------------------------
// Create/Edit Zone form
//------------------------------------------------------------------

function openZoneForm(zone) {
  zoneFormError.textContent = '';
  document.getElementById('zoneFormId').value = zone ? zone.id : '';
  document.getElementById('zoneFormTitle').textContent = zone ? `Edit "${zone.name}"` : 'Create Zone';
  document.getElementById('zoneFormName').value = zone ? zone.name : '';
  document.getElementById('zoneFormThickness').value = zone ? zone.thickness : mgmtDefaults.thickness;
  zoneForm.classList.add('visible');
}

document.getElementById('zoneFormCancel').addEventListener('click', () => zoneForm.classList.remove('visible'));

document.getElementById('zoneFormSubmit').addEventListener('click', () => {
  const id = document.getElementById('zoneFormId').value;
  const name = document.getElementById('zoneFormName').value.trim();
  const thickness = document.getElementById('zoneFormThickness').value;

  if (!name) {
    zoneFormError.textContent = 'Name is required';
    return;
  }

  zoneForm.classList.remove('visible');

  if (id) {
    postNUI('driftzones:editZoneInfo', { zoneId: id, name, thickness });
  } else {
    postNUI('driftzones:createZone', { name, thickness });
  }
});

//------------------------------------------------------------------
// Keyboard wiring shared across the zone form / management panel
//------------------------------------------------------------------

document.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;

  if (zoneForm.classList.contains('visible')) {
    zoneForm.classList.remove('visible');
    return;
  }

  if (managementPanel.classList.contains('visible')) {
    postNUI('driftzones:close');
  }
});

//------------------------------------------------------------------
// Message router
//------------------------------------------------------------------

window.addEventListener('message', function (event) {
  const data = event.data || {};

  switch (data.action) {
    case 'showZonePopup':
      nameEl.textContent = data.name || 'Drift Zone';
      popup.classList.add('visible');
      break;

    case 'hideZonePopup':
      popup.classList.remove('visible');
      break;

    case 'playSound':
      playSound(data.sound);
      break;

    case 'setVolume':
      setVolume(data.volume);
      break;

    case 'showSetupPanel':
      showSetupPanel(data.name, data.minPoints, data.editing);
      break;

    case 'hideSetupPanel':
      hideSetupPanel();
      break;

    case 'updateSetupPoints':
      renderSetupPoints(data.points);
      break;

    case 'showCrosshair':
      crosshair.classList.add('visible');
      break;

    case 'hideCrosshair':
      crosshair.classList.remove('visible');
      break;

    case 'showManagement':
      showManagement(data);
      break;

    case 'hideManagement':
      hideManagement();
      break;

    case 'refreshManagement':
      refreshManagement(data);
      break;
  }
});