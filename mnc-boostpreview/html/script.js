let previewOpen = false;
let activeTab = 'presets';

let stylesData = [];
let bezelsData = [];
let presetsData = [];
let stylesCount = 40;
let bezelsCount = 20;

let currentStyle = 1;
let currentBezel = 1;
let bezelThickness = 9;

// The real mnc-boostgauge dial draws one tick per whole PSI of the vehicle's live
// max boost (see html/script.js generateTicks(maxPsi) there), so tick count is normally
// driven by gameplay telemetry. This preview has no vehicle to read from, so it uses a
// representative value instead - 12 matches Config.TurboPSI.turbo_rx280 (a common
// Stage 1 turbo) in mnc-boostgauge/config.lua - purely so the static cards look like a
// real in-game reading.
const PREVIEW_MAX_PSI = 12;

let gaugeStylesInjected = false;
let gaugeStylesFailed = false;

const overlay = document.getElementById('overlay');
const grid = document.getElementById('grid');
const tabButtons = document.querySelectorAll('.tab-btn');
const customSelectors = document.getElementById('customSelectors');
const customPanel = document.getElementById('customPanel');
const customPreview = document.getElementById('customPreview');
const customFaceInfo = document.getElementById('customFaceInfo');
const customBezelInfo = document.getElementById('customBezelInfo');
const bezelLabel = document.getElementById('bezelLabel');
const styleLabel = document.getElementById('styleLabel');
const closeBtn = document.getElementById('closeBtn');
const warningBanner = document.getElementById('warningBanner');

// ==============================
// NUI message handling
// ==============================
window.addEventListener('message', (event) => {
  const d = event.data;
  if (!d || !d.action) return;

  if (d.action === 'open') {
    openPreview(d.data || {});
  } else if (d.action === 'close') {
    closePreview(false);
  }
});

function injectGaugeStyles(resourceName) {
  if (gaugeStylesInjected) return;
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = `nui://${resourceName}/html/style.css`;
  link.onload = () => {
    gaugeStylesInjected = true;
    warningBanner.classList.add('hidden');
    // Tick radius/size math (generateTicks) reads real layout values that only exist
    // once this stylesheet is applied - the very first render usually runs before this
    // async load finishes, so re-render now that the real CSS is actually in effect.
    renderGrid();
  };
  link.onerror = () => {
    gaugeStylesFailed = true;
    warningBanner.classList.remove('hidden');
  };
  document.head.appendChild(link);
}

function openPreview(data) {
  stylesData = data.styles || [];
  bezelsData = data.bezels || [];
  presetsData = data.presets || [];
  stylesCount = data.stylesCount || stylesData.length || 40;
  bezelsCount = data.bezelsCount || bezelsData.length || 20;
  currentStyle = data.defaultStyle || 1;
  currentBezel = data.defaultBezel || 1;

  bezelThickness = data.bezelThickness || 9;
  document.documentElement.style.setProperty('--bezel-thickness', `${bezelThickness}px`);

  injectGaugeStyles(data.gaugeResource || 'mnc-boostgauge');

  previewOpen = true;
  overlay.classList.remove('hidden');
  setActiveTab('presets');
}

function closePreview(notifyClient = true) {
  previewOpen = false;
  overlay.classList.add('hidden');
  grid.innerHTML = '';
  customPreview.innerHTML = '';
  if (notifyClient) sendNui('close', {});
}

closeBtn.addEventListener('click', () => closePreview(true));

document.addEventListener('keyup', (e) => {
  if (previewOpen && e.key === 'Escape') {
    closePreview(true);
  }
});

// ==============================
// Tabs
// ==============================
tabButtons.forEach((btn) => {
  btn.addEventListener('click', () => setActiveTab(btn.dataset.tab));
});

function setActiveTab(tab) {
  activeTab = tab;
  tabButtons.forEach((b) => b.classList.toggle('active', b.dataset.tab === tab));
  customSelectors.classList.toggle('hidden', tab !== 'custom');
  grid.classList.toggle('hidden', tab === 'custom');
  customPanel.classList.toggle('hidden', tab !== 'custom');
  renderGrid();
}

// ==============================
// Face (style) / bezel selectors - drive the custom builder tab
// ==============================
document.getElementById('bezelPrev').addEventListener('click', () => {
  currentBezel = currentBezel <= 1 ? bezelsCount : currentBezel - 1;
  renderGrid();
});
document.getElementById('bezelNext').addEventListener('click', () => {
  currentBezel = currentBezel >= bezelsCount ? 1 : currentBezel + 1;
  renderGrid();
});
document.getElementById('stylePrev').addEventListener('click', () => {
  currentStyle = currentStyle <= 1 ? stylesCount : currentStyle - 1;
  renderGrid();
});
document.getElementById('styleNext').addEventListener('click', () => {
  currentStyle = currentStyle >= stylesCount ? 1 : currentStyle + 1;
  renderGrid();
});

// ==============================
// Gauge card builder (mirrors mnc-boostgauge/html/index.html markup)
// ==============================
function buildGaugeEl(styleId, bezelId) {
  const wrap = document.createElement('div');
  wrap.className = `gauge style-${styleId} bezel-${bezelId}`;
  wrap.setAttribute('data-style', styleId);
  wrap.setAttribute('data-bezel', bezelId);
  wrap.setAttribute('data-rpm-high', 'false');
  wrap.setAttribute('data-lights-on', 'false');
  wrap.setAttribute('data-highbeams-on', 'false');
  wrap.setAttribute('data-psi-high', 'false');

  wrap.innerHTML = `
    <div class="gauge-bezel"></div>
    <div class="gauge-inner">
      <div class="gauge-face">
        <div class="gauge-ticks"></div>
        <div class="gauge-center"></div>
        <div class="warning-icon hidden"></div>
        <div class="needle"></div>
        <div class="psi-text">0.0 PSI</div>
        <div class="max-text">PSI</div>
      </div>
    </div>
  `;

  // Ticks are generated after this element is attached to the live DOM
  // (see generateAllTicks) - offsetWidth reads 0 on a detached element,
  // which would silently place every tick at the wrong radius.
  return wrap;
}

// Mirrors mnc-boostgauge/html/script.js's generateTicks(maxPsi) exactly: tick count
// is floor(maxPsi), radius is derived from the rendered gauge-ticks box minus the
// bezel thickness, and each tick's size/color is set inline (not from CSS defaults).
// The preview has no live maxPsi to read, so it calls this with PREVIEW_MAX_PSI.
function generateTicks(container, maxPsi) {
  container.innerHTML = '';
  const tickCount = Math.max(1, Math.floor(parseFloat(maxPsi) || 1));
  const anglePerTick = 360 / tickCount;
  const gaugeInnerSize = container.offsetWidth - (bezelThickness * 2);
  const radius = (gaugeInnerSize / 2) - 2;

  const fragment = document.createDocumentFragment();

  for (let i = 0; i < tickCount; i++) {
    const isMajorTick = i % 3 === 0;
    const tick = document.createElement('div');
    tick.className = isMajorTick ? 'gauge-tick major-tick' : 'gauge-tick';

    const angle = i * anglePerTick;
    const rad = (angle - 90) * (Math.PI / 180);
    const x = radius * Math.cos(rad);
    const y = radius * Math.sin(rad);

    tick.style.position = 'absolute';
    tick.style.left = `calc(50% + ${x}px)`;
    tick.style.top = `calc(50% + ${y}px)`;
    tick.style.width = isMajorTick ? '10px' : '8px';
    tick.style.height = '12px';
    tick.style.background = isMajorTick ? 'rgba(255, 255, 255, 1.0)' : 'rgba(255, 255, 255, 0.7)';
    tick.style.transformOrigin = 'center center';
    tick.style.transform = `translate(-50%, -50%) rotate(${angle}deg)`;

    fragment.appendChild(tick);
  }

  container.appendChild(fragment);
}

// Runs generateTicks for every gauge card currently attached under `root`.
// Must be called AFTER the cards are appended to the document.
function generateAllTicks(root) {
  root.querySelectorAll('.gauge-ticks').forEach((ticksEl) => {
    generateTicks(ticksEl, PREVIEW_MAX_PSI);
  });
}

function findEntry(list, id) {
  return list.find((x) => x.id === id) || { id, label: `#${id}`, item: null };
}

function renderGrid() {
  if (activeTab === 'custom') {
    renderCustom();
    return;
  }

  grid.innerHTML = '';
  const fragment = document.createDocumentFragment();

  presetsData.forEach((p) => {
    fragment.appendChild(makeCard(p.style, p.bezel, p.label));
  });

  grid.appendChild(fragment);
  generateAllTicks(grid);
}

function renderCustom() {
  updateCustomLabels();

  customPreview.innerHTML = '';
  customPreview.appendChild(makeCard(currentStyle, currentBezel, null));
  generateAllTicks(customPreview);
}

function updateCustomLabels() {
  styleLabel.textContent = `${currentStyle} / ${stylesCount}`;
  bezelLabel.textContent = `${currentBezel} / ${bezelsCount}`;

  const styleEntry = findEntry(stylesData, currentStyle);
  const bezelEntry = findEntry(bezelsData, currentBezel);

  customFaceInfo.textContent = `#${currentStyle} — ${styleEntry.label} — Item: ${styleEntry.item || 'n/a'}`;
  customBezelInfo.textContent = `#${currentBezel} — ${bezelEntry.label} — Item: ${bezelEntry.item || 'n/a'}`;
}

function makeCard(styleId, bezelId, labelText) {
  const card = document.createElement('div');
  card.className = 'preview-card';
  card.appendChild(buildGaugeEl(styleId, bezelId));

  if (labelText) {
    const label = document.createElement('div');
    label.className = 'card-label';
    label.textContent = labelText;
    card.appendChild(label);
  }

  return card;
}

// ==============================
// NUI helper
// ==============================
function sendNui(action, data) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {}),
  }).catch(() => {});
}