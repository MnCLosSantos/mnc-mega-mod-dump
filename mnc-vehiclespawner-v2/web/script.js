// ── GTA V paint colours — correct id→label mapping from Config.Paints ────────
// Each entry is { id, label }; grouped by finish type for <optgroup> dropdowns.
const GTA_PAINT_GROUPS = {
    Classic: [
        { id: 0, label: 'Black' },
        { id: 1, label: 'Graphite' },
        { id: 2, label: 'Black Steel' },
        { id: 3, label: 'Dark Steel' },
        { id: 4, label: 'Silver' },
        { id: 5, label: 'Bluish Silver' },
        { id: 6, label: 'Rolled Steel' },
        { id: 7, label: 'Shadow Silver' },
        { id: 8, label: 'Stone Silver' },
        { id: 9, label: 'Midnight Silver' },
        { id: 10, label: 'Cast Iron Silver' },
        { id: 11, label: 'Anthracite Black' },
        { id: 27, label: 'Red' },
        { id: 28, label: 'Torino Red' },
        { id: 29, label: 'Formula Red' },
        { id: 30, label: 'Blaze Red' },
        { id: 31, label: 'Grace Red' },
        { id: 32, label: 'Garnet Red' },
        { id: 33, label: 'Sunset Red' },
        { id: 34, label: 'Cabernet Red' },
        { id: 35, label: 'Candy Red' },
        { id: 36, label: 'Sunrise Orange' },
        { id: 38, label: 'Orange' },
        { id: 49, label: 'Dark Green' },
        { id: 50, label: 'Racing Green' },
        { id: 51, label: 'Sea Green' },
        { id: 52, label: 'Olive Green' },
        { id: 53, label: 'Bright Green' },
        { id: 54, label: 'Gasoline Green' },
        { id: 61, label: 'Galaxy Blue' },
        { id: 62, label: 'Dark Blue' },
        { id: 63, label: 'Saxon Blue' },
        { id: 64, label: 'Blue' },
        { id: 65, label: 'Mariner Blue' },
        { id: 66, label: 'Harbor Blue' },
        { id: 67, label: 'Diamond Blue' },
        { id: 68, label: 'Surf Blue' },
        { id: 69, label: 'Nautical Blue' },
        { id: 70, label: 'Ultra Blue' },
        { id: 71, label: 'Schafter Purple' },
        { id: 72, label: 'Spinnaker Purple' },
        { id: 73, label: 'Racing Blue' },
        { id: 74, label: 'Light Blue' },
        { id: 88, label: 'Yellow' },
        { id: 89, label: 'Race Yellow' },
        { id: 90, label: 'Bronze' },
        { id: 91, label: 'Dew Yellow' },
        { id: 92, label: 'Lime Green' },
        { id: 94, label: 'Feltzer Brown' },
        { id: 95, label: 'Creeen Brown' },
        { id: 96, label: 'Chocolate Brown' },
        { id: 97, label: 'Maple Brown' },
        { id: 98, label: 'Saddle Brown' },
        { id: 99, label: 'Bleached Brown' },
        { id: 100, label: 'Moss Brown' },
        { id: 101, label: 'Bison Brown' },
        { id: 102, label: 'Woodbeech Brown' },
        { id: 103, label: 'Beechwood Brown' },
        { id: 104, label: 'Sienna Brown' },
        { id: 105, label: 'Sandy Brown' },
        { id: 106, label: 'Bleached Brown 2' },
        { id: 107, label: 'Cream' },
        { id: 111, label: 'Ice White' },
        { id: 112, label: 'Frost White' },
        { id: 135, label: 'Hot Pink' },
        { id: 136, label: 'Salmon Pink' },
        { id: 137, label: 'Pfister Pink' },
        { id: 138, label: 'Bright Orange' },
        { id: 141, label: 'Midnight Blue' },
        { id: 142, label: 'Midnight Purple' },
        { id: 143, label: 'Wine Red' },
        { id: 145, label: 'Bright Purple' },
        { id: 147, label: 'Carbon Black' },
        { id: 150, label: 'Lava Red' },
    ],
    Matte: [
        { id: 12, label: 'Black' },
        { id: 13, label: 'Gray' },
        { id: 14, label: 'Light Gray' },
        { id: 39, label: 'Red' },
        { id: 40, label: 'Dark Red' },
        { id: 41, label: 'Orange' },
        { id: 42, label: 'Yellow' },
        { id: 55, label: 'Lime Green' },
        { id: 82, label: 'Dark Blue' },
        { id: 83, label: 'Blue' },
        { id: 84, label: 'Midnight Blue' },
        { id: 131, label: 'Ice White' },
        { id: 148, label: 'Schafter Purple' },
        { id: 149, label: 'Midnight Purple' },
        { id: 151, label: 'Forest Green' },
        { id: 152, label: 'Olive Darb' },
        { id: 153, label: 'Dark Earth' },
        { id: 154, label: 'Desert Tan' },
        { id: 155, label: 'Foliage Green' },
    ],
    Metal: [
        { id: 117, label: 'Brushed Steel' },
        { id: 118, label: 'Brushed Black Steel' },
        { id: 119, label: 'Brushed Aluminum' },
        { id: 120, label: 'Chrome' },
        { id: 158, label: 'Pure Gold' },
        { id: 159, label: 'Brushed Gold' },
    ],
    Worn: [
        { id: 21, label: 'Black' },
        { id: 22, label: 'Graphite' },
        { id: 23, label: 'Silver Grey' },
        { id: 24, label: 'Silver' },
        { id: 25, label: 'Blue Silver' },
        { id: 26, label: 'Shadow Silver' },
        { id: 46, label: 'Red' },
        { id: 47, label: 'Golden Red' },
        { id: 48, label: 'Dark Red' },
        { id: 58, label: 'Dark Green' },
        { id: 59, label: 'Green' },
        { id: 60, label: 'Sea Wash' },
        { id: 85, label: 'Dark Blue' },
        { id: 86, label: 'Blue' },
        { id: 87, label: 'Light Blue' },
        { id: 113, label: 'Honey Beige' },
        { id: 114, label: 'Brown' },
        { id: 115, label: 'Dark Brown' },
        { id: 116, label: 'Straw Beige' },
        { id: 121, label: 'Off White' },
        { id: 123, label: 'Orange' },
        { id: 124, label: 'Light Orange' },
        { id: 126, label: 'Taxi Yellow' },
        { id: 130, label: 'Orange 2' },
        { id: 132, label: 'White' },
        { id: 133, label: 'Olive Army Green' },
    ],
    Chameleon: [
        { id: 161, label: 'Anodized Red Pearl' },
        { id: 162, label: 'Anodized Wine Pearl' },
        { id: 163, label: 'Anodized Purple Pearl' },
        { id: 164, label: 'Anodized Blue Pearl' },
        { id: 165, label: 'Anodized Green Pearl' },
        { id: 166, label: 'Anodized Lime Pearl' },
        { id: 167, label: 'Anodized Copper Pearl' },
        { id: 168, label: 'Anodized Bronze Pearl' },
        { id: 169, label: 'Anodized Champagne Pearl' },
        { id: 170, label: 'Anodized Gold Pearl' },
        { id: 171, label: 'Green/Blue Flip' },
        { id: 172, label: 'Green/Red Flip' },
        { id: 173, label: 'Green/Brown Flip' },
        { id: 174, label: 'Green/Turquoise Flip' },
        { id: 175, label: 'Green/Purple Flip' },
        { id: 176, label: 'Teal/Purple Flip' },
        { id: 177, label: 'Turquoise/Red Flip' },
        { id: 178, label: 'Turquoise/Purple Flip' },
        { id: 179, label: 'Cyan/Purple Flip' },
        { id: 180, label: 'Blue/Pink Flip' },
        { id: 181, label: 'Blue/Green Flip' },
        { id: 182, label: 'Purple/Red Flip' },
        { id: 183, label: 'Purple/Green Flip' },
        { id: 184, label: 'Magenta/Green Flip' },
        { id: 185, label: 'Magenta/Yellow Flip' },
        { id: 186, label: 'Burgundy/Green Flip' },
        { id: 187, label: 'Magenta/Cyan Flip' },
        { id: 188, label: 'Copper/Purple Flip' },
        { id: 189, label: 'Magenta/Orange Flip' },
        { id: 190, label: 'Red/Orange Flip' },
        { id: 191, label: 'Orange/Purple Flip' },
        { id: 192, label: 'Orange/Blue Flip' },
        { id: 193, label: 'White/Purple Flip' },
        { id: 194, label: 'Red/Rainbow Flip' },
        { id: 195, label: 'Blue/Rainbow Flip' },
        { id: 196, label: 'Dark Green Pearl' },
        { id: 197, label: 'Dark Teal Pearl' },
        { id: 198, label: 'Dark Blue Pearl' },
        { id: 199, label: 'Dark Purple Pearl' },
        { id: 200, label: 'Oil Slick Pearl' },
        { id: 201, label: 'Light Green Pearl' },
        { id: 202, label: 'Light Blue Pearl' },
        { id: 203, label: 'Light Purple Pearl' },
        { id: 204, label: 'Light Pink Pearl' },
        { id: 205, label: 'Off White Pearl' },
        { id: 206, label: 'Cute Pink Pearl' },
        { id: 207, label: 'Baby Yellow Pearl' },
        { id: 208, label: 'Baby Green Pearl' },
        { id: 209, label: 'Baby Blue Pearl' },
        { id: 210, label: 'Cream Pearl' },
        { id: 211, label: 'White Prismatic Pearl' },
        { id: 212, label: 'Graphite Prismatic Pearl' },
        { id: 213, label: 'Blue Prismatic Pearl' },
        { id: 214, label: 'Purple Prismatic Pearl' },
        { id: 215, label: 'Hot Pink Prismatic Pearl' },
        { id: 216, label: 'Red Prismatic Pearl' },
        { id: 217, label: 'Green Prismatic Pearl' },
        { id: 218, label: 'Black Prismatic Pearl' },
        { id: 219, label: 'Oil Spill Prismatic Pearl' },
        { id: 220, label: 'Rainbow Prismatic Pearl' },
        { id: 221, label: 'Black Holographic Pearl' },
        { id: 222, label: 'White Holographic Pearl' },
    ],
};

// Pearlescent valid ids — Classic + Chrome only
const PEARLESCENT_IDS = new Set([
    ...GTA_PAINT_GROUPS.Classic.map(c => c.id),
    120, // Chrome
]);

// Wheel colour uses all paint groups
const ALL_PAINT_ENTRIES = Object.values(GTA_PAINT_GROUPS).flat();

// Interior / dashboard colour indices (mod slots 22/23)
const INTERIOR_COLOURS = [
    { id: -1, label: 'Stock' },
    { id: 0, label: 'Default' },
    { id: 1, label: 'Black' },
    { id: 2, label: 'Gray' },
    { id: 3, label: 'Light Gray' },
    { id: 4, label: 'Beige' },
    { id: 5, label: 'Red' },
    { id: 6, label: 'Dark Red' },
    { id: 7, label: 'Blue' },
    { id: 8, label: 'Dark Blue' },
    { id: 9, label: 'Green' },
    { id: 10, label: 'Dark Green' },
    { id: 11, label: 'Yellow' },
    { id: 12, label: 'Orange' },
    { id: 13, label: 'Pink' },
];

// Helper: build grouped <optgroup> options into a <select> element
function buildGroupedPaintSelect(selectEl, entries, groupedByFinish, defaultLabel = null) {
    selectEl.innerHTML = '';
    if (defaultLabel !== null) {
        selectEl.appendChild(new Option(defaultLabel, -1));
    }
    if (groupedByFinish) {
        Object.entries(GTA_PAINT_GROUPS).forEach(([group, colours]) => {
            const og = document.createElement('optgroup');
            og.label = group;
            colours.forEach(c => {
                og.appendChild(new Option(`${c.label}`, c.id));
            });
            selectEl.appendChild(og);
        });
    } else {
        entries.forEach(c => selectEl.appendChild(new Option(`${c.label}`, c.id)));
    }
}

// ── Mod definitions — split into performance and visual ───────────────────────
const PERF_MOD_DEFS = [
    { id: 11, label: 'Engine' },
    { id: 12, label: 'Brakes' },
    { id: 13, label: 'Transmission' },
    { id: 15, label: 'Suspension' },
    { id: 16, label: 'Armor' },
    { id: 18, label: 'Turbo', isToggle: true },
];

const VISUAL_MOD_DEFS = [
    { id: 0,  label: 'Spoiler' },
    { id: 1,  label: 'Front Bumper' },
    { id: 2,  label: 'Rear Bumper' },
    { id: 3,  label: 'Side Skirt' },
    { id: 4,  label: 'Exhaust' },
    { id: 5,  label: 'Roll Cage' },
    { id: 6,  label: 'Grille' },
    { id: 7,  label: 'Hood' },
    { id: 8,  label: 'Left Fender' },
    { id: 9,  label: 'Right Fender' },
    { id: 10, label: 'Roof' },
    { id: 19, label: 'Subwoofer' },
    { id: 21, label: 'Hydraulics' },
    { id: 25, label: 'Plate Holder' },
    { id: 26, label: 'Vanity Plates' },
    { id: 27, label: 'Trim A' },
    { id: 28, label: 'Ornaments' },
    { id: 29, label: 'Dashboard' },
    { id: 30, label: 'Dial' },
    { id: 31, label: 'Door Speaker' },
    { id: 32, label: 'Seats' },
    { id: 33, label: 'Steering Wheel' },
    { id: 34, label: 'Shifter Lever' },
    { id: 35, label: 'Plaque' },
    { id: 36, label: 'Speaker' },
    { id: 37, label: 'Trunk' },
    { id: 38, label: 'Hydraulic 2' },
    { id: 39, label: 'Engine Block' },
    { id: 40, label: 'Air Filter' },
    { id: 41, label: 'Strut' },
    { id: 42, label: 'Arch Cover' },
    { id: 43, label: 'Aerial' },
    { id: 44, label: 'Trim B' },
    { id: 45, label: 'Fuel Tank' },
    { id: 46, label: 'Left Door' },
    { id: 47, label: 'Right Door' },
    { id: 49, label: 'Lightbar' },
];

// ── State ────────────────────────────────────────────────────────────────────
let vehicleModels = {};
let currentCategory = null;
let currentStyle = {};
let currentTitle = '';
let imagePaths = {
    primary:        'https://docs.fivem.net/vehicles/{model}.webp',
    fallback:       'https://raw.githubusercontent.com/MnCLosSantos/mnc-vehicle-image-storage/main/mnc-vehicle-image-storage/images/{model}.png',
    local_fallback: './images/fallback.png',
};

let selectedModel = null;
let savedColours = null;
let savedMods = null;
let liveryDataReady = false;
let vehicleModData = {};

// Spawn flow wheel state
let _spawnIsBike = false;   // true = bike (show front + rear), false = car (single All Wheels)

// Standalone state
let sa_modData = {};
let sa_liveryDataReady = false;
let sa_wheelCount = 0;
let sa_backWheelCount = 0;

// ── Initialise ───────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    populateColourDropdowns();

    const searchInput = document.getElementById('searchInput');

    window.addEventListener('message', (event) => {
        if (event.data.type === 'setVehicleModels') {
            vehicleModels = event.data.models;
            currentStyle = event.data.uiStyle || {};
            currentTitle = event.data.title || 'Vehicle Spawner';
            if (event.data.imagePaths) imagePaths = event.data.imagePaths;
            applyUIStyle();
            populateCategories();
            const first = document.querySelector('.category-item');
            if (first) first.click();
        }

        if (event.data.action === 'plateTaken') {
            const customPlate = document.getElementById('customPlate')?.value?.trim();
            if (customPlate && customPlate.length > 0) {
                showPlateError('That plate is already in use. Choose a different one.');
            }
            return;
        }

        if (event.data.action === 'spawnSuccess') {
            setSpawnPending(false);
            closeSpawnModal();
            closeUI();
            return;
        }

        if (event.data.action === 'reopenSpawnModal') {
            showPlateError('That plate is already in use. Choose a different one.');
            return;
        }

        if (event.data.action === 'openUI') {
            currentStyle = event.data.uiStyle || {};
            currentTitle = event.data.title || 'Vehicle Spawner';
            applyUIStyle();
            document.getElementById('spawnModal').classList.add('hidden');
            document.getElementById('colourModal').classList.add('hidden');
            document.getElementById('modsModal').classList.add('hidden');
            document.getElementById('standaloneModsModal').classList.add('hidden');
            openUI();
        }

        if (event.data.action === 'openStandaloneMods') {
            document.body.style.display = 'block';
            openStandaloneModsUI(event.data);
        }

        if (event.data.action === 'standaloneExtraData') {
            const d = event.data;
            if (d.wheelType != null) document.getElementById('sa-wheelTypeSelect').value = d.wheelType;
            saPopulateWheelIndexDropdowns(d.wheelCount, d.backWheelCount, d.isBike);
            if (d.frontWheelIdx != null) document.getElementById('sa-frontWheelSelect').value = d.frontWheelIdx;
            if (d.backWheelIdx != null) document.getElementById('sa-backWheelSelect').value = d.backWheelIdx;

            if (d.bulletproofTyres != null) document.getElementById('sa-bulletproofTyres').checked = d.bulletproofTyres;
            if (d.tyreSmoke != null) document.getElementById('sa-tyreSmokeEnabled').checked = d.tyreSmoke;
            if (d.smokeColor) {
                const smokeVal = `${d.smokeColor.r},${d.smokeColor.g},${d.smokeColor.b}`;
                const smokeSel = document.getElementById('sa-smokeColorSelect');
                let found = false;
                for (const opt of smokeSel.options) {
                    if (opt.value === smokeVal) { smokeSel.value = smokeVal; found = true; break; }
                }
                if (!found) smokeSel.selectedIndex = 0;
            }
            if (d.xenonEnabled != null) document.getElementById('sa-xenonEnabled').checked = d.xenonEnabled;
            if (d.xenonColor != null) document.getElementById('sa-xenonColorSelect').value = d.xenonColor;

            if (d.neon) {
                document.getElementById('sa-neonL').checked = d.neon.l;
                document.getElementById('sa-neonR').checked = d.neon.r;
                document.getElementById('sa-neonF').checked = d.neon.f;
                document.getElementById('sa-neonB').checked = d.neon.b;
            }
            if (d.neonColor) {
                const neonVal = `${d.neonColor.r},${d.neonColor.g},${d.neonColor.b}`;
                const neonSel = document.getElementById('sa-neonColorSelect');
                let found = false;
                for (const opt of neonSel.options) {
                    if (opt.value === neonVal) { neonSel.value = neonVal; found = true; break; }
                }
                if (!found) neonSel.selectedIndex = 0;
            }
            if (d.plateIndex != null) document.getElementById('sa-plateIndexSelect').value = d.plateIndex;
        }

        if (event.data.action === 'spawnWheelMeta') {
            spawnApplyWheelMeta(event.data.isBike, event.data.wheelCount, event.data.backWheelCount);
        }

        if (event.data.action === 'liveryData') {
            populateLiveryDropdown(event.data.mod14, event.data.mod48);
            liveryDataReady = true;
            const colourBtn = document.querySelector('.colour-open-btn');
            if (colourBtn) {
                colourBtn.disabled = false;
                colourBtn.title = '';
                if (!savedColours) colourBtn.innerHTML = '<i class="fas fa-palette"></i> Change Colours';
            }
            saPopulateLivery(event.data.mod14, event.data.mod48);
        }

        if (event.data.action === 'modData') {
            vehicleModData = event.data.mods || {};
            populateModDropdowns(vehicleModData);
            const modsBtn = document.querySelector('.mods-open-btn');
            if (modsBtn) {
                modsBtn.disabled = false;
                modsBtn.title = '';
                if (!savedMods) modsBtn.innerHTML = '<i class="fas fa-wrench"></i> Change Mods';
            }
            saPopulateModDropdowns(event.data.mods || {});
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeUI();
    });

    searchInput.addEventListener('input', (e) => {
        const term = e.target.value.toLowerCase();
        if (term.length > 0) filterVehicles(term);
        else if (currentCategory) {
            if (currentCategory === 'All') showAllVehicles();
            else showVehiclesInCategory(currentCategory);
        }
    });

    document.getElementById('customPlate').addEventListener('input', function () {
        this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
        clearPlateError();
    });
});

// ── Colour dropdown population ───────────────────────────────────────────────
function populateColourDropdowns() {
    buildGroupedPaintSelect(document.getElementById('primarySelect'), null, true);
    buildGroupedPaintSelect(document.getElementById('secondarySelect'), null, true);

    const pearl = document.getElementById('pearlescentSelect');
    pearl.innerHTML = '';
    pearl.appendChild(new Option('None', -1));
    Object.entries(GTA_PAINT_GROUPS).forEach(([group, colours]) => {
        const filtered = colours.filter(c => PEARLESCENT_IDS.has(c.id));
        if (!filtered.length) return;
        const og = document.createElement('optgroup');
        og.label = group;
        filtered.forEach(c => og.appendChild(new Option(c.label, c.id)));
        pearl.appendChild(og);
    });

    const wheel = document.getElementById('wheelSelect');
    wheel.innerHTML = '';
    buildGroupedPaintSelect(wheel, null, true);

    const intSel = document.getElementById('interiorSelect');
    const dashSel = document.getElementById('dashboardSelect');
    intSel.innerHTML = '';
    dashSel.innerHTML = '';
    INTERIOR_COLOURS.forEach(c => {
        intSel.appendChild(new Option(c.label, c.id));
        dashSel.appendChild(new Option(c.label, c.id));
    });
}

// ── Mod dropdowns ─────────────────────────────────────────────────────────────
function populateModDropdowns(modData) {
    buildModTab('mod-perf-dropdowns', PERF_MOD_DEFS, modData);
    buildModTab('mod-visual-dropdowns', VISUAL_MOD_DEFS, modData);

    const perfHasAny = PERF_MOD_DEFS.some(m => modData[m.id] || modData[String(m.id)]);
    const visualHasAny = VISUAL_MOD_DEFS.some(m => modData[m.id] || modData[String(m.id)]);

    document.getElementById('mod-tab-perf').style.display = perfHasAny ? '' : 'none';
    document.getElementById('mod-tab-visual').style.display = visualHasAny ? '' : 'none';

    if (perfHasAny) switchModTab('perf');
    else if (visualHasAny) switchModTab('visual');
}

function buildModTab(containerId, defs, modData) {
    const container = document.getElementById(containerId);
    if (!container) return;
    container.innerHTML = '';
    let anyBuilt = false;

    defs.forEach(mod => {
        const slotData = modData[mod.id] || modData[String(mod.id)];
        if (!slotData) return;
        anyBuilt = true;

        const section = document.createElement('div');
        section.className = 'mod-section';
        const label = document.createElement('label');
        label.className = 'colour-section-label';
        label.textContent = mod.label;
        section.appendChild(label);

        const sel = document.createElement('select');
        sel.className = 'colour-select';
        sel.id = `mod-select-${mod.id}`;

        if (slotData.isToggle) {
            sel.appendChild(new Option('Stock (Off)', 0));
            sel.appendChild(new Option('Turbo On', 1));
        } else {
            sel.appendChild(new Option('Stock', -1));
            (slotData.names || []).forEach((name, i) => {
                sel.appendChild(new Option(name, i));
            });
        }
        sel.value = slotData.isToggle ? '0' : '-1';
        section.appendChild(sel);
        container.appendChild(section);
    });

    if (!anyBuilt) {
        container.innerHTML = '<p class="mod-none-msg">No mods available for this vehicle.</p>';
    }
}

function switchModTab(tab) {
    document.getElementById('mod-perf-dropdowns').style.display = tab === 'perf' ? '' : 'none';
    document.getElementById('mod-visual-dropdowns').style.display = tab === 'visual' ? '' : 'none';
    document.getElementById('mod-wheels-tab').style.display = tab === 'wheels' ? '' : 'none';

    document.getElementById('mod-tab-perf').classList.toggle('active', tab === 'perf');
    document.getElementById('mod-tab-visual').classList.toggle('active', tab === 'visual');
    document.getElementById('mod-tab-wheels').classList.toggle('active', tab === 'wheels');
}

// ── Livery dropdown ─────────────────────────────────────────────────────────
function populateLiveryDropdown(mod14Names, mod48Names) {
    const sel = document.getElementById('liverySelect');
    const section = document.getElementById('liverySection');
    sel.innerHTML = '<option value="none">None / Stock</option>';

    const mod14 = Array.isArray(mod14Names) ? mod14Names : [];
    const mod48 = Array.isArray(mod48Names) ? mod48Names : [];

    mod14.forEach((name, i) => {
        sel.appendChild(new Option(name && name !== '' ? name : `Livery ${i + 1}`, `14:${i}`));
    });
    mod48.forEach((name, i) => {
        const label = (name && name !== '' ? name : `Livery ${i + 1}`) + (mod14.length > 0 ? ' (Alt)' : '');
        sel.appendChild(new Option(label, `48:${i}`));
    });

    const hasLiveries = mod14.length > 0 || mod48.length > 0;
    if (section) section.style.display = hasLiveries ? '' : 'none';
    sel.value = 'none';
}

// ── Colour modal ─────────────────────────────────────────────────────────────
function openColourModal() {
    document.getElementById('colourModal').classList.remove('hidden');
}

function closeColourModal() {
    document.getElementById('colourModal').classList.add('hidden');
}

function saveColours() {
    const liveryRaw = document.getElementById('liverySelect').value;
    let livery = -1;
    let liveryMod48 = -1;
    if (liveryRaw !== 'none') {
        const [modType, idx] = liveryRaw.split(':');
        if (modType === '14') livery = parseInt(idx);
        if (modType === '48') liveryMod48 = parseInt(idx);
    }

    savedColours = {
        primary: parseInt(document.getElementById('primarySelect').value),
        secondary: parseInt(document.getElementById('secondarySelect').value),
        pearlescent: parseInt(document.getElementById('pearlescentSelect').value),
        wheel: parseInt(document.getElementById('wheelSelect').value),
        livery,
        liveryMod48,
        interior: parseInt(document.getElementById('interiorSelect').value),
        dashboard: parseInt(document.getElementById('dashboardSelect').value),
        windowTint: parseInt(document.getElementById('windowTintSelect').value),
    };

    closeColourModal();
    const btn = document.querySelector('.colour-open-btn');
    if (btn) {
        btn.innerHTML = '<i class="fas fa-check"></i> Colours Set';
        btn.style.borderColor = 'var(--accent)';
        btn.style.color = 'var(--accent)';
    }
}

// ── Mods modal ───────────────────────────────────────────────────────────────
function openModsModal() {
    if (!selectedModel) return;

    document.getElementById('mod-perf-dropdowns').innerHTML = '<p class="mod-none-msg"><i class="fas fa-spinner fa-spin"></i> Loading...</p>';
    document.getElementById('mod-visual-dropdowns').innerHTML = '<p class="mod-none-msg"><i class="fas fa-spinner fa-spin"></i> Loading...</p>';

    fetch(`https://${GetParentResourceName()}/requestLiveryData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: selectedModel })
    });

    document.getElementById('modsModal').classList.remove('hidden');
}

function closeModsModal() {
    document.getElementById('modsModal').classList.add('hidden');
}

function saveMods() {
    savedMods = {};

    const allDefs = [...PERF_MOD_DEFS, ...VISUAL_MOD_DEFS];
    allDefs.forEach(mod => {
        const sel = document.getElementById(`mod-select-${mod.id}`);
        if (sel) savedMods[mod.id] = parseInt(sel.value);
    });

    // Wheel data
    savedMods._wheelType = parseInt(document.getElementById('spawn-wheelTypeSelect').value);
    savedMods._frontWheelIdx = parseInt(document.getElementById('spawn-frontWheelSelect').value);
    savedMods._backWheelIdx = _spawnIsBike ? parseInt(document.getElementById('spawn-backWheelSelect').value) : -1; // bikes use both
    savedMods._bulletproofTyres = document.getElementById('spawn-bulletproofTyres').checked;
    savedMods._tyreSmoke = document.getElementById('spawn-tyreSmokeEnabled').checked;

    const smokeRaw = document.getElementById('spawn-smokeColorSelect').value.split(',');
    savedMods._smokeColor = { r: parseInt(smokeRaw[0]), g: parseInt(smokeRaw[1]), b: parseInt(smokeRaw[2]) };

    closeModsModal();
    const btn = document.querySelector('.mods-open-btn');
    if (btn) {
        btn.innerHTML = '<i class="fas fa-check"></i> Mods Set';
        btn.style.borderColor = 'var(--accent)';
        btn.style.color = 'var(--accent)';
    }
}

// ── Spawn modal ───────────────────────────────────────────────────────────────
function openSpawnOptions(model) {
    selectedModel = model;
    savedColours = null;
    savedMods = null;
    vehicleModData = {};

    document.getElementById('customPlate').value = '';
    document.getElementById('performanceMods').checked = false;
    document.getElementById('randomVisualMods').checked = false;
    document.getElementById('ownVehicle').checked = false;

    switchSpawnTab('options');

    // Reset wheel UI to default (car style)
    _spawnIsBike = false;
    document.getElementById('spawn-frontRimLabel').textContent = 'All Wheels';
    document.getElementById('spawn-backWheelSection').style.display = 'none';
    document.getElementById('spawn-wheelTypeSelect').value = '0';
    document.getElementById('spawn-bulletproofTyres').checked = false;
    document.getElementById('spawn-tyreSmokeEnabled').checked = false;
    document.getElementById('spawn-smokeColorSelect').selectedIndex = 0;
    spawnUpdateWheelIndexOptions();

    // Reset buttons
    const colourBtn = document.querySelector('.colour-open-btn');
    if (colourBtn) {
        colourBtn.disabled = true;
        colourBtn.title = 'Loading vehicle data...';
        colourBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
    }

    const modsBtn = document.querySelector('.mods-open-btn');
    if (modsBtn) {
        modsBtn.disabled = true;
        modsBtn.title = 'Loading vehicle data...';
        modsBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
    }

    const liverySection = document.getElementById('liverySection');
    if (liverySection) liverySection.style.display = 'none';

    populateLiveryDropdown([], []);
    liveryDataReady = false;

    const tintSel = document.getElementById('windowTintSelect');
    if (tintSel) tintSel.value = '0';

    fetch(`https://${GetParentResourceName()}/requestLiveryData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model })
    });

    document.getElementById('spawnModal').classList.remove('hidden');
}

function closeSpawnModal() {
    document.getElementById('spawnModal').classList.add('hidden');
    selectedModel = null;
    savedColours = null;
    savedMods = null;
}

function switchSpawnTab(tab) {
    document.getElementById('spawn-options-tab').style.display = tab === 'options' ? '' : 'none';
    document.getElementById('spawn-plate-tab').style.display = tab === 'plate' ? '' : 'none';
    document.getElementById('spawn-tab-options').classList.toggle('active', tab === 'options');
    document.getElementById('spawn-tab-plate').classList.toggle('active', tab === 'plate');
}

// ── Spawn Wheel Helpers (as requested: Cars = All Wheels, Bikes = Front + Rear) ───────────────────────────────────────
function spawnApplyWheelMeta(isBike, wheelCount, backWheelCount) {
    _spawnIsBike = !!isBike;   // true = bike → show front + rear

    const frontLabel = document.getElementById('spawn-frontRimLabel');
    const backSection = document.getElementById('spawn-backWheelSection');

    if (_spawnIsBike) {
        // Bike: show Front Rim + Rear Rim
        if (frontLabel) frontLabel.textContent = 'Front Rim';
        if (backSection) backSection.style.display = '';
    } else {
        // Car: single "All Wheels"
        if (frontLabel) frontLabel.textContent = 'All Wheels';
        if (backSection) backSection.style.display = 'none';
    }

    _spawnFillWheelSelect(document.getElementById('spawn-frontWheelSelect'), wheelCount || 50);
    if (_spawnIsBike) {
        _spawnFillWheelSelect(document.getElementById('spawn-backWheelSelect'), backWheelCount || 50);
    }
}

function spawnUpdateWheelIndexOptions() {
    _spawnFillWheelSelect(document.getElementById('spawn-frontWheelSelect'), 50);
    if (_spawnIsBike) {
        _spawnFillWheelSelect(document.getElementById('spawn-backWheelSelect'), 50);
    }
}

function _spawnFillWheelSelect(sel, count) {
    sel.innerHTML = '';
    sel.appendChild(new Option('Stock', -1));
    for (let i = 0; i < count; i++) {
        sel.appendChild(new Option(`Rim ${i + 1}`, i));
    }
}

function confirmSpawn() {
    if (!selectedModel) return;

    const performance = document.getElementById('performanceMods').checked;
    const randomVisual = document.getElementById('randomVisualMods').checked;
    const ownVehicle = document.getElementById('ownVehicle').checked;
    const customPlate = document.getElementById('customPlate').value.trim();
    const plateStyle = parseInt(document.getElementById('spawnPlateIndexSelect').value);

    let modsToSend = null;
    let wheelData = null;

    if (savedMods) {
        modsToSend = {};
        Object.entries(savedMods).forEach(([k, v]) => {
            if (!k.startsWith('_')) modsToSend[k] = v;
        });

        wheelData = {
            wheelType: savedMods._wheelType,
            frontWheelIdx: savedMods._frontWheelIdx,
            backWheelIdx: savedMods._backWheelIdx,
            bulletproofTyres: savedMods._bulletproofTyres,
            tyreSmoke: savedMods._tyreSmoke,
            smokeColor: savedMods._smokeColor,
        };
    }

    clearPlateError();
    setSpawnPending(true);

    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            model: selectedModel,
            customPlate: customPlate,
            plateStyle: plateStyle,
            colours: savedColours,
            mods: modsToSend,
            wheelData: wheelData,
            performanceMods: performance,
            randomVisualMods: randomVisual,
            ownVehicle: ownVehicle,
        }),
    });
}

function setSpawnPending(pending) {
    const btn = document.querySelector('.confirm-btn');
    if (!btn) return;
    if (pending) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Checking plate...';
    } else {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-car"></i> Spawn Vehicle';
    }
}

function showPlateError(message) {
    setSpawnPending(false);
    const plateInput = document.getElementById('customPlate');
    plateInput.style.borderColor = '#ff4444';
    plateInput.style.boxShadow = '0 0 0 2px rgba(255, 68, 68, 0.3)';
    plateInput.focus();

    let errEl = document.getElementById('plate-error-msg');
    if (!errEl) {
        errEl = document.createElement('p');
        errEl.id = 'plate-error-msg';
        errEl.className = 'plate-error';
        plateInput.parentNode.insertBefore(errEl, plateInput.nextSibling);
    }
    errEl.textContent = message;
}

function clearPlateError() {
    const plateInput = document.getElementById('customPlate');
    plateInput.style.borderColor = '';
    plateInput.style.boxShadow = '';
    const errEl = document.getElementById('plate-error-msg');
    if (errEl) errEl.remove();
}

// ── UI Style ─────────────────────────────────────────────────────────────────
function applyUIStyle() {
    const root = document.documentElement;
    if (currentStyle.primaryBg) root.style.setProperty('--primary-bg', currentStyle.primaryBg);
    if (currentStyle.secondaryBg) root.style.setProperty('--secondary-bg', currentStyle.secondaryBg);
    if (currentStyle.accent) {
        root.style.setProperty('--accent', currentStyle.accent);
        const hex = currentStyle.accent.replace('#', '');
        const r = parseInt(hex.substr(0,2),16);
        const g = parseInt(hex.substr(2,2),16);
        const b = parseInt(hex.substr(4,2),16);
        root.style.setProperty('--accent-rgb', `${r}, ${g}, ${b}`);
    }
    if (currentStyle.textPrimary) root.style.setProperty('--text-primary', currentStyle.textPrimary);
    if (currentStyle.textSecondary) root.style.setProperty('--text-secondary', currentStyle.textSecondary);
    if (currentStyle.borderColor) root.style.setProperty('--border-color', currentStyle.borderColor);
    if (currentStyle.blur) root.style.setProperty('--blur', currentStyle.blur);

    document.getElementById('current-category').innerHTML =
        `<i class="fas fa-layer-group"></i><span>${currentTitle}</span>`;
}

function openUI() {
    document.body.style.display = 'block';
    document.querySelector('.modal-overlay').style.display = '';
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.add('visible');
    void dashboard.offsetHeight;
}

function closeUI() {
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.remove('visible');
    document.body.style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
    });
}

// ── Standalone Vehicle Mods UI ────────────────────────────────────────────────
function openStandaloneModsUI(data) {
    if (data && data.uiStyle) currentStyle = data.uiStyle;
    applyUIStyle();

    document.querySelector('.modal-overlay').style.display = 'none';

    buildGroupedPaintSelect(document.getElementById('sa-primarySelect'), null, true);
    buildGroupedPaintSelect(document.getElementById('sa-secondarySelect'), null, true);
    buildGroupedPaintSelect(document.getElementById('sa-wheelColourSelect'), null, true);

    const saP = document.getElementById('sa-pearlescentSelect');
    saP.innerHTML = '';
    saP.appendChild(new Option('None', -1));
    Object.entries(GTA_PAINT_GROUPS).forEach(([group, colours]) => {
        const filtered = colours.filter(c => PEARLESCENT_IDS.has(c.id));
        if (!filtered.length) return;
        const og = document.createElement('optgroup');
        og.label = group;
        filtered.forEach(c => og.appendChild(new Option(c.label, c.id)));
        saP.appendChild(og);
    });

    const cc = data.currentColours;
    if (cc) {
        if (cc.primary != null) document.getElementById('sa-primarySelect').value = cc.primary;
        if (cc.secondary != null) document.getElementById('sa-secondarySelect').value = cc.secondary;
        if (cc.pearlescent != null) document.getElementById('sa-pearlescentSelect').value = cc.pearlescent;
        if (cc.windowTint != null) document.getElementById('sa-windowTintSelect').value = cc.windowTint;
    }

    document.getElementById('sa-mod-perf-dropdowns').innerHTML = '<p class="mod-none-msg"><i class="fas fa-spinner fa-spin"></i> Loading...</p>';
    document.getElementById('sa-mod-visual-dropdowns').innerHTML = '<p class="mod-none-msg"><i class="fas fa-spinner fa-spin"></i> Loading...</p>';

    document.getElementById('sa-liverySection').style.display = 'none';
    document.getElementById('sa-liverySelect').innerHTML = '<option value="none">None / Stock</option>';
    sa_liveryDataReady = false;

    switchSATab('perf');
    document.getElementById('standaloneModsModal').classList.remove('hidden');
}

function closeStandaloneModsUI() {
    document.getElementById('standaloneModsModal').classList.add('hidden');
    document.querySelector('.modal-overlay').style.display = '';
    fetch(`https://${GetParentResourceName()}/closeStandaloneMods`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
    });
}

function switchSATab(tab) {
    const tabs = ['perf', 'visual', 'colours', 'wheels', 'extras'];
    tabs.forEach(t => {
        document.getElementById(`sa-tab-${t}`).classList.toggle('active', t === tab);
    });
    document.getElementById('sa-mod-perf-dropdowns').style.display = tab === 'perf' ? '' : 'none';
    document.getElementById('sa-mod-visual-dropdowns').style.display = tab === 'visual' ? '' : 'none';
    document.getElementById('sa-colours-tab').style.display = tab === 'colours' ? '' : 'none';
    document.getElementById('sa-wheels-tab').style.display = tab === 'wheels' ? '' : 'none';
    document.getElementById('sa-extras-tab').style.display = tab === 'extras' ? '' : 'none';
}

function saPopulateWheelIndexDropdowns(frontCount, backCount, isBike) {
    sa_wheelCount = frontCount || 0;
    sa_backWheelCount = backCount || 0;

    const frontLabel = document.getElementById('sa-frontRimLabel');
    const backSection = document.getElementById('sa-backWheelSection');

    if (isBike) {
        if (frontLabel) frontLabel.textContent = 'Front Rim';
        if (backSection) backSection.style.display = '';
    } else {
        if (frontLabel) frontLabel.textContent = 'All Wheels';
        if (backSection) backSection.style.display = 'none';
    }

    _saFillWheelSelect(document.getElementById('sa-frontWheelSelect'), sa_wheelCount);
    if (isBike) {
        _saFillWheelSelect(document.getElementById('sa-backWheelSelect'), sa_backWheelCount);
    }
}

function _saFillWheelSelect(sel, count) {
    sel.innerHTML = '';
    sel.appendChild(new Option('Stock', -1));
    for (let i = 0; i < count; i++) sel.appendChild(new Option(`Rim ${i + 1}`, i));
}

function saUpdateWheelIndexOptions() {
    _saFillWheelSelect(document.getElementById('sa-frontWheelSelect'), 50);
    const backSection = document.getElementById('sa-backWheelSection');
    if (backSection && backSection.style.display !== 'none') {
        _saFillWheelSelect(document.getElementById('sa-backWheelSelect'), 50);
    }
}

function saPopulateLivery(mod14Names, mod48Names) {
    const sel = document.getElementById('sa-liverySelect');
    const section = document.getElementById('sa-liverySection');
    sel.innerHTML = '<option value="none">None / Stock</option>';

    const m14 = Array.isArray(mod14Names) ? mod14Names : [];
    const m48 = Array.isArray(mod48Names) ? mod48Names : [];

    m14.forEach((name, i) => sel.appendChild(new Option(name || `Livery ${i+1}`, `14:${i}`)));
    m48.forEach((name, i) => {
        const label = (name || `Livery ${i+1}`) + (m14.length > 0 ? ' (Alt)' : '');
        sel.appendChild(new Option(label, `48:${i}`));
    });

    section.style.display = (m14.length > 0 || m48.length > 0) ? '' : 'none';
}

function saPopulateModDropdowns(modData) {
    sa_modData = modData;
    _saBuildModTab('sa-mod-perf-dropdowns', PERF_MOD_DEFS, modData);
    _saBuildModTab('sa-mod-visual-dropdowns', VISUAL_MOD_DEFS, modData);

    const perfHasAny = PERF_MOD_DEFS.some(m => modData[m.id] || modData[String(m.id)]);
    const visualHasAny = VISUAL_MOD_DEFS.some(m => modData[m.id] || modData[String(m.id)]);

    document.getElementById('sa-tab-perf').style.display = perfHasAny ? '' : 'none';
    document.getElementById('sa-tab-visual').style.display = visualHasAny ? '' : 'none';
}

function _saBuildModTab(containerId, defs, modData) {
    const container = document.getElementById(containerId);
    if (!container) return;
    container.innerHTML = '';
    let anyBuilt = false;

    defs.forEach(mod => {
        const slotData = modData[mod.id] || modData[String(mod.id)];
        if (!slotData) return;
        anyBuilt = true;

        const section = document.createElement('div');
        section.className = 'mod-section';
        const label = document.createElement('label');
        label.className = 'colour-section-label';
        label.textContent = mod.label;
        section.appendChild(label);

        const sel = document.createElement('select');
        sel.className = 'colour-select';
        sel.id = `sa-mod-select-${mod.id}`;

        if (slotData.isToggle) {
            sel.appendChild(new Option('Stock (Off)', 0));
            sel.appendChild(new Option('Turbo On', 1));
        } else {
            sel.appendChild(new Option('Stock', -1));
            (slotData.names || []).forEach((name, i) => sel.appendChild(new Option(name, i)));
        }
        sel.value = slotData.isToggle ? '0' : '-1';
        section.appendChild(sel);
        container.appendChild(section);
    });

    if (!anyBuilt) container.innerHTML = '<p class="mod-none-msg">No mods available for this vehicle.</p>';
}

function applyStandaloneMods() {
    const liveryRaw = document.getElementById('sa-liverySelect').value;
    let livery = -1, liveryMod48 = -1;
    if (liveryRaw !== 'none') {
        const [modType, idx] = liveryRaw.split(':');
        if (modType === '14') livery = parseInt(idx);
        if (modType === '48') liveryMod48 = parseInt(idx);
    }

    const colours = {
        primary: parseInt(document.getElementById('sa-primarySelect').value),
        secondary: parseInt(document.getElementById('sa-secondarySelect').value),
        pearlescent: parseInt(document.getElementById('sa-pearlescentSelect').value),
        wheel: parseInt(document.getElementById('sa-wheelColourSelect').value),
        windowTint: parseInt(document.getElementById('sa-windowTintSelect').value),
        livery,
        liveryMod48,
    };

    const mods = {};
    [...PERF_MOD_DEFS, ...VISUAL_MOD_DEFS].forEach(mod => {
        const sel = document.getElementById(`sa-mod-select-${mod.id}`);
        if (sel) mods[mod.id] = parseInt(sel.value);
    });

    const wheelType = parseInt(document.getElementById('sa-wheelTypeSelect').value);
    const frontWheelIdx = parseInt(document.getElementById('sa-frontWheelSelect').value);
    const backSection = document.getElementById('sa-backWheelSection');
    const backWheelIdx = (backSection && backSection.style.display !== 'none')
        ? parseInt(document.getElementById('sa-backWheelSelect').value)
        : -1;

    const xenonEnabled = document.getElementById('sa-xenonEnabled').checked;
    const xenonColor = parseInt(document.getElementById('sa-xenonColorSelect').value);

    const neon = {
        l: document.getElementById('sa-neonL').checked,
        r: document.getElementById('sa-neonR').checked,
        f: document.getElementById('sa-neonF').checked,
        b: document.getElementById('sa-neonB').checked,
    };
    const neonColorRaw = document.getElementById('sa-neonColorSelect').value.split(',');
    const neonColor = { r: parseInt(neonColorRaw[0]), g: parseInt(neonColorRaw[1]), b: parseInt(neonColorRaw[2]) };

    const tyreSmoke = document.getElementById('sa-tyreSmokeEnabled').checked;
    const smokeColorRaw = document.getElementById('sa-smokeColorSelect').value.split(',');
    const smokeColor = { r: parseInt(smokeColorRaw[0]), g: parseInt(smokeColorRaw[1]), b: parseInt(smokeColorRaw[2]) };

    const bulletproofTyres = document.getElementById('sa-bulletproofTyres').checked;
    const plateIndex = parseInt(document.getElementById('sa-plateIndexSelect').value);

    const btn = document.querySelector('#standaloneModsModal .confirm-btn');
    if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Applying...'; }

    fetch(`https://${GetParentResourceName()}/applyVehicleMods`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ colours, mods, wheelType, frontWheelIdx, backWheelIdx, xenonEnabled, xenonColor, neon, neonColor, tyreSmoke, smokeColor, bulletproofTyres, plateIndex }),
    }).finally(() => {
        if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-check"></i> Apply to Vehicle'; }
    });
}

// ── Vehicle List & Categories ───────────────────────────────────────────────
function populateCategories() {
    const categoryList = document.getElementById('category-list');
    categoryList.innerHTML = '';

    const categoryIcons = {
        'All': 'fa-layer-group', 'Motorcycles': 'fa-motorcycle',
        'Helicopters': 'fa-helicopter', 'Planes': 'fa-plane',
        'Boats': 'fa-ship', 'Trains': 'fa-train', 'Cycles': 'fa-bicycle',
    };

    const sorted = ['All', ...Object.keys(vehicleModels).sort((a,b) => a.localeCompare(b))];

    sorted.forEach(category => {
        if (category === 'All' || vehicleModels[category]) {
            const item = document.createElement('div');
            item.className = 'category-item';
            item.innerHTML = `<i class="fas ${categoryIcons[category] || 'fa-car'}"></i>${category}`;
            item.addEventListener('click', () => {
                currentCategory = category;
                document.querySelectorAll('.category-item').forEach(el => el.classList.remove('active'));
                item.classList.add('active');
                document.getElementById('searchInput').value = '';
                if (category === 'All') showAllVehicles();
                else showVehiclesInCategory(category);
            });
            categoryList.appendChild(item);
        }
    });
}

function showAllVehicles() {
    const list = document.getElementById('vehicle-list');
    list.style.opacity = '0';
    setTimeout(() => {
        list.innerHTML = '';
        const all = Object.entries(vehicleModels)
            .flatMap(([cat, vehicles]) => vehicles.map(v => ({ ...v, category: cat })))
            .sort((a,b) => a.name.localeCompare(b.name));

        document.getElementById('current-category').innerHTML =
            `<i class="fas fa-layer-group"></i><span>${currentTitle}</span>`;
        updateResultsCount(all.length);
        all.forEach(v => appendVehicleCard(list, v));
        void list.offsetHeight;
        list.style.opacity = '1';
    }, 50);
}

function showVehiclesInCategory(category) {
    const list = document.getElementById('vehicle-list');
    list.style.opacity = '0';
    setTimeout(() => {
        list.innerHTML = '';
        const vehicles = vehicleModels[category].map(v => ({ ...v, category }));
        document.getElementById('current-category').innerHTML =
            `<i class="fas fa-tag"></i><span>${category}</span>`;
        updateResultsCount(vehicles.length);
        vehicles.forEach(v => appendVehicleCard(list, v));
        void list.offsetHeight;
        list.style.opacity = '1';
    }, 50);
}

function filterVehicles(term) {
    const list = document.getElementById('vehicle-list');
    list.style.opacity = '0';
    setTimeout(() => {
        list.innerHTML = '';
        const all = Object.entries(vehicleModels)
            .flatMap(([cat, vs]) => vs.map(v => ({ ...v, category: cat })))
            .filter(v =>
                v.name.toLowerCase().includes(term) ||
                v.model.toLowerCase().includes(term) ||
                v.brand.toLowerCase().includes(term))
            .sort((a,b) => a.name.localeCompare(b.name));

        document.getElementById('current-category').innerHTML =
            `<i class="fas fa-search"></i><span>Search Results</span>`;
        updateResultsCount(all.length);
        all.forEach(v => appendVehicleCard(list, v));
        void list.offsetHeight;
        list.style.opacity = '1';
    }, 50);
}

function appendVehicleCard(list, vehicle) {
    const card = document.createElement('div');
    card.className = 'vehicle-card';
    card.innerHTML = createVehicleCard(vehicle);
    list.appendChild(card);
}

function handleVehicleImgError(img, model) {
    if (typeof img._fallbackIndex === 'undefined') {
        img._fallbackIndex = 0;
    }

    const fallbacks = [
        imagePaths.github1 ? imagePaths.github1.replace('{model}', model) : null,
        imagePaths.github2 ? imagePaths.github2.replace('{model}', model) : null,
        imagePaths.local_fallback
    ].filter(Boolean);

    if (img._fallbackIndex < fallbacks.length) {
        const url = fallbacks[img._fallbackIndex];
        img.src = url;
        img._fallbackIndex++;
    } else {
        img.onerror = null;
        img.src = imagePaths.local_fallback || './images/fallback.png';
    }
}

function createVehicleCard(vehicle) {
    return `
        <div class="vehicle-header">
            <div class="vehicle-name">${vehicle.name}</div>
            <div class="vehicle-category">${vehicle.category}</div>
        </div>
        <div class="vehicle-image-container" onclick="openLightbox(this.querySelector('img'))">
            <img src="${imagePaths.primary.replace('{model}', vehicle.model)}"
                 class="vehicle-image" alt="${vehicle.name}" loading="lazy"
                 onerror="handleVehicleImgError(this, '${vehicle.model}')">
        </div>
        <div class="vehicle-content">
            <div class="vehicle-info">
                <p><i class="fas fa-dollar-sign"></i> <strong>Price:</strong> ${vehicle.price.toLocaleString()}</p>
                <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${vehicle.category}</p>
                <p><i class="fas fa-industry"></i> <strong>Manufacturer:</strong> ${vehicle.brand}</p>
                <p><i class="fas fa-car"></i> <strong>Model:</strong> ${vehicle.model}</p>
            </div>
            <div class="vehicle-actions">
                <button class="spawn-btn" onclick="openSpawnOptions('${vehicle.model}')">
                    <i class="fas fa-plus"></i> Spawn Options
                </button>
            </div>
        </div>
    `;
}

function updateResultsCount(count) {
    document.getElementById('results-count').textContent = `${count} vehicles available`;
}
// ── Image Lightbox ─────────────────────────────────────────────────────────
(function () {
    let _scale = 1, _tx = 0, _ty = 0;
    let _dragging = false, _startX = 0, _startY = 0, _baseX = 0, _baseY = 0;

    function applyTransform(animate) {
        const img = document.getElementById('lightboxImg');
        if (!img) return;
        img.style.transition = animate ? 'transform 0.15s ease' : 'none';
        img.style.transform = `translate(${_tx}px,${_ty}px) scale(${_scale})`;
        document.getElementById('lightboxZoomLabel').textContent = Math.round(_scale * 100) + '%';
    }

    window.openLightbox = function (imgEl) {
        const lb = document.getElementById('imgLightbox');
        const lbImg = document.getElementById('lightboxImg');
        lbImg.src = imgEl.src;
        lbImg.alt = imgEl.alt;
        _scale = 1; _tx = 0; _ty = 0;
        applyTransform(false);
        lb.classList.remove('hidden');
    };

    window.closeLightbox = function () {
        document.getElementById('imgLightbox').classList.add('hidden');
    };

    window.closeLightboxOnBackdrop = function (e) {
        if (e.target === document.getElementById('imgLightbox') ||
            e.target === document.getElementById('lightboxStage')) {
            closeLightbox();
        }
    };

    window.lightboxZoom = function (delta) {
        _scale = Math.min(5, Math.max(0.25, _scale + delta));
        applyTransform(true);
    };

    window.lightboxReset = function () {
        _scale = 1; _tx = 0; _ty = 0;
        applyTransform(true);
    };

    // Wheel zoom
    document.addEventListener('wheel', function (e) {
        if (document.getElementById('imgLightbox').classList.contains('hidden')) return;
        e.preventDefault();
        const delta = e.deltaY < 0 ? 0.15 : -0.15;
        _scale = Math.min(5, Math.max(0.25, _scale + delta));
        applyTransform(false);
    }, { passive: false });

    // Drag to pan
    const stage = () => document.getElementById('lightboxStage');

    document.addEventListener('mousedown', function (e) {
        if (document.getElementById('imgLightbox').classList.contains('hidden')) return;
        if (!stage().contains(e.target) && e.target !== stage()) return;
        _dragging = true;
        _startX = e.clientX; _startY = e.clientY;
        _baseX = _tx; _baseY = _ty;
        stage().classList.add('dragging');
    });

    document.addEventListener('mousemove', function (e) {
        if (!_dragging) return;
        _tx = _baseX + (e.clientX - _startX);
        _ty = _baseY + (e.clientY - _startY);
        applyTransform(false);
    });

    document.addEventListener('mouseup', function () {
        if (!_dragging) return;
        _dragging = false;
        const s = stage();
        if (s) s.classList.remove('dragging');
    });

    // Keyboard: Escape closes, +/- zooms
    document.addEventListener('keydown', function (e) {
        if (document.getElementById('imgLightbox').classList.contains('hidden')) return;
        if (e.key === 'Escape') closeLightbox();
        if (e.key === '+' || e.key === '=') lightboxZoom(0.25);
        if (e.key === '-') lightboxZoom(-0.25);
        if (e.key === '0') lightboxReset();
    });
})();