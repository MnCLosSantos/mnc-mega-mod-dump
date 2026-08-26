// MNC Vehicle Placer · app.js · v3.0.0

const app         = document.getElementById('app');
const vehicleList = document.getElementById('vehicleList');
const listMeta    = document.getElementById('listMeta');
const searchBox   = document.getElementById('searchBox');
const emptyState  = document.getElementById('emptyState');
const detailView  = document.getElementById('detailView');
const formView    = document.getElementById('formView');
const placeBanner = document.getElementById('placeBanner');
const statTotal   = document.getElementById('statTotal');
const statLive    = document.getElementById('statLive');

let allPlacements  = [];
let imagePaths     = {};
let selectedKey    = null;
let deleteTargetId = null;
let placingKey     = null;
let placingVeh     = null;

// ── Resource name ─────────────────────────────────────────────
function resourceName() {
  return typeof window.GetParentResourceName === 'function'
    ? window.GetParentResourceName()
    : 'mnc-vehicleplacer';
}

// ── NUI post ──────────────────────────────────────────────────
function post(action, data) {
  return fetch('https://' + resourceName() + '/' + action, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}

// ── Image loading ─────────────────────────────────────────────
function buildSources(model) {
  const m = (model || '').toLowerCase();
  return [
    (imagePaths.primary  || '').replace('{model}', m),
    (imagePaths.github1  || '').replace('{model}', m),
    (imagePaths.github2  || '').replace('{model}', m),
    imagePaths.local_fallback || './images/fallback.png',
  ].filter(Boolean);
}

function loadImg(el, model) {
  if (!el) return;
  const sources = buildSources(model);
  let i = 0;
  el.style.display = '';
  function next() {
    if (i >= sources.length) { el.style.display = 'none'; return; }
    el.src = sources[i++];
  }
  el.onerror = next;
  next();
}

// ── Helpers ───────────────────────────────────────────────────
function esc(s) {
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}
function distLabel(d) {
  if (!d || d >= 9000) return '?';
  return d >= 1000 ? (d / 1000).toFixed(1) + ' km' : d + ' m';
}
function debounce(fn, ms) {
  let t;
  return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); };
}

// ── Stats ─────────────────────────────────────────────────────
function updateStats() {
  statTotal.textContent = allPlacements.length;
  statLive.textContent  = allPlacements.filter(p => p.spawned).length;
}

// ── List render ───────────────────────────────────────────────
function renderList(filter) {
  const q = (filter || '').toLowerCase();
  const filtered = allPlacements.filter(p =>
    p.name.toLowerCase().includes(q) || p.vehicleModel.toLowerCase().includes(q)
  );
  listMeta.textContent = filtered.length + ' / ' + allPlacements.length + ' placements';
  vehicleList.innerHTML = '';

  filtered.forEach(p => {
    const row = document.createElement('div');
    row.className = 'v-row' + (p.key === selectedKey ? ' active' : '');

    // Thumb
    const thumb = document.createElement('div');
    thumb.className = 'v-thumb';
    const img = document.createElement('img');
    img.alt = p.vehicleModel;
    thumb.appendChild(img);
    loadImg(img, p.vehicleModel);
    img.onerror = () => { thumb.innerHTML = '🚗'; };

    // Info
    const info = document.createElement('div');
    info.className = 'v-info';
    const typeBadge  = p.isStatic ? '<span class="badge b-config">Config</span>' : '<span class="badge b-sql">SQL</span>';
    const statBadge  = p.spawned  ? '<span class="badge b-live">Within prox</span>'    : '<span class="badge b-missing">Not within prox</span>';
    info.innerHTML = '<div class="v-name">' + esc(p.name) + '</div>'
      + '<div class="v-model">' + esc(p.vehicleModel) + '</div>'
      + '<div class="v-badges">' + typeBadge + statBadge + '</div>';

    // Dist
    const dist = document.createElement('div');
    dist.className = 'v-dist';
    dist.textContent = distLabel(p.distance);

    row.appendChild(thumb);
    row.appendChild(info);
    row.appendChild(dist);
    row.addEventListener('click', () => selectPlacement(p.key));
    vehicleList.appendChild(row);
  });
}

// ── Select ────────────────────────────────────────────────────
function selectPlacement(key) {
  if (placingKey) cancelPlace();
  selectedKey = key;
  const p = allPlacements.find(x => x.key === key);
  if (!p) return;

  showPanel('detail');

  // Header
  document.getElementById('dName').textContent  = p.name;
  document.getElementById('dModel').textContent = p.vehicleModel.toUpperCase();
  document.getElementById('dDist').textContent  = '📍 ' + distLabel(p.distance);

  // Hero
  const heroImg = document.getElementById('heroImg');
  heroImg.style.display = '';
  loadImg(heroImg, p.vehicleModel);
  heroImg.onerror = () => { heroImg.style.display = 'none'; };

  // Table
  document.getElementById('dX').textContent     = p.x.toFixed(3);
  document.getElementById('dY').textContent     = p.y.toFixed(3);
  document.getElementById('dZ').textContent     = p.z.toFixed(3);
  document.getElementById('dH').textContent     = p.heading.toFixed(2) + '°';
  document.getElementById('dType').textContent  = p.isStatic ? 'Config (static)' : 'Database (SQL)';
  document.getElementById('dStatus').innerHTML  = p.spawned
    ? '<span style="color:var(--success)">● Live</span>'
    : '<span style="color:var(--danger)">● Missing</span>';

  // Actions
  const actions = document.getElementById('detailActions');
  actions.innerHTML = '';

  const btnTp = mkBtn('btn-ghost', '🚀 Teleport', () => post('teleportTo', { x: p.x, y: p.y, z: p.z }));
  actions.appendChild(btnTp);

  if (!p.isStatic) {
    actions.appendChild(mkBtn('btn-ghost',   '✏ Edit',        () => showForm(p)));
    actions.appendChild(mkBtn('btn-danger',  '🗑 Delete',     () => confirmDel(p)));
  }

  renderList(searchBox.value);
}

function mkBtn(cls, label, fn) {
  const b = document.createElement('button');
  b.className = 'btn ' + cls;
  b.textContent = label;
  b.addEventListener('click', fn);
  return b;
}

// ── Panels ────────────────────────────────────────────────────
function showPanel(which) {
  emptyState.style.display = which === 'empty'  ? 'flex' : 'none';
  detailView.style.display = which === 'detail' ? 'flex' : 'none';
  formView.style.display   = which === 'form'   ? 'flex' : 'none';
}

// ── Form ──────────────────────────────────────────────────────
function showForm(p) {
  showPanel('form');
  document.getElementById('formTitle').textContent = p ? 'Edit Placement' : 'Add Placement';
  document.getElementById('editId').value = p ? p.id  : '';
  document.getElementById('fName').value  = p ? p.name : '';
  document.getElementById('fModel').value = p ? p.vehicleModel : '';
  document.getElementById('fX').value     = p ? p.x : '';
  document.getElementById('fY').value     = p ? p.y : '';
  document.getElementById('fZ').value     = p ? p.z : '';
  document.getElementById('fH').value     = p ? p.heading : '';

  const prev = document.getElementById('previewImg');
  prev.style.display = '';
  if (p) loadImg(prev, p.vehicleModel);
  else    prev.src = '';

  document.getElementById('fModel').addEventListener('input', debounce(() => {
    loadImg(prev, document.getElementById('fModel').value);
  }, 500));
}

document.getElementById('btnSave').addEventListener('click', () => {
  const id    = document.getElementById('editId').value;
  const name  = document.getElementById('fName').value.trim();
  const model = document.getElementById('fModel').value.trim();
  const x     = parseFloat(document.getElementById('fX').value);
  const y     = parseFloat(document.getElementById('fY').value);
  const z     = parseFloat(document.getElementById('fZ').value);
  const h     = parseFloat(document.getElementById('fH').value) || 0;
  if (!name || !model || isNaN(x) || isNaN(y) || isNaN(z)) return;
  if (id) post('editPlacement', { id: parseInt(id), name, vehicleModel: model, x, y, z, heading: h });
  else    post('addPlacement',  { name, vehicleModel: model, x, y, z, heading: h });
  showPanel('empty');
  selectedKey = null;
});

document.getElementById('btnCancelForm').addEventListener('click', () => {
  if (selectedKey) selectPlacement(selectedKey);
  else showPanel('empty');
});

document.getElementById('btnUseCoords').addEventListener('click', () => {
  fetch('https://' + resourceName() + '/useCurrentCoords', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}',
  }).then(r => r.json()).then(d => {
    document.getElementById('fX').value = parseFloat(d.x).toFixed(4);
    document.getElementById('fY').value = parseFloat(d.y).toFixed(4);
    document.getElementById('fZ').value = parseFloat(d.z).toFixed(4);
    document.getElementById('fH').value = parseFloat(d.heading).toFixed(2);
  }).catch(() => {});
});

// ── Delete ────────────────────────────────────────────────────
function confirmDel(p) {
  deleteTargetId = p.id;
  document.getElementById('confirmText').textContent =
    'Delete "' + p.name + '" (' + p.vehicleModel + ')? This cannot be undone.';
  document.getElementById('confirmOverlay').classList.add('show');
}
document.getElementById('confirmYes').addEventListener('click', () => {
  if (deleteTargetId !== null) {
    post('deletePlacement', { id: deleteTargetId });
    deleteTargetId = null;
  }
  document.getElementById('confirmOverlay').classList.remove('show');
  selectedKey = null;
  showPanel('empty');
});
document.getElementById('confirmNo').addEventListener('click', () => {
  deleteTargetId = null;
  document.getElementById('confirmOverlay').classList.remove('show');
});

// ── Placement mode ────────────────────────────────────────────
function enterPlace(p) {
  placingKey = p.key;
  placeBanner.style.display = 'flex';
  post('enterPlacementMode', { key: p.key });
}
function cancelPlace() {
  placingKey = null;
  placeBanner.style.display = 'none';
  post('cancelPlacementMode', {});
}

document.getElementById('btnConfirmPlace').addEventListener('click', () => {
  fetch('https://' + resourceName() + '/confirmPlacement', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ key: placingKey }),
  }).then(r => r.json()).then(d => {
    if (!d || d.error) return;
    const idx = allPlacements.findIndex(x => x.key === placingKey);
    if (idx !== -1) { allPlacements[idx].x = d.x; allPlacements[idx].y = d.y; allPlacements[idx].z = d.z; allPlacements[idx].heading = d.heading; }
  }).catch(() => {});
  placingKey = null;
  placeBanner.style.display = 'none';
});
document.getElementById('btnCancelPlace').addEventListener('click', cancelPlace);

// ── Open / close ──────────────────────────────────────────────
document.getElementById('btnClose').addEventListener('click', () => {
  if (placingKey) cancelPlace();
  post('close');
  app.classList.remove('visible');
});

document.getElementById('btnShowAdd').addEventListener('click', () => {
  selectedKey = null;
  renderList(searchBox.value);
  showForm(null);
});

searchBox.addEventListener('input', () => renderList(searchBox.value));

// ── NUI messages ──────────────────────────────────────────────
window.addEventListener('message', function(e) {
  const data = e.data;
  if (!data || !data.action) return;

  if (data.action === 'open') {
    allPlacements = data.placements || [];
    imagePaths    = data.imagePaths  || {};
    selectedKey   = null;
    placingKey    = null;
    placeBanner.style.display = 'none';
    searchBox.value = '';
    updateStats();
    renderList('');
    showPanel('empty');
    app.classList.add('visible');
  }

  if (data.action === 'close') {
    app.classList.remove('visible');
  }

  if (data.action === 'placementConfirmed') {
    const idx = allPlacements.findIndex(x => x.key === data.key);
    if (idx !== -1) { allPlacements[idx].x = data.x; allPlacements[idx].y = data.y; allPlacements[idx].z = data.z; allPlacements[idx].heading = data.heading; }
    if (selectedKey === data.key) selectPlacement(data.key);
  }
});