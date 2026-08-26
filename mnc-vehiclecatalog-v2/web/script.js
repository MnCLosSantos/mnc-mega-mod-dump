let vehicleModels = {};
let currentCategory = null;
let currentStyle = {};
let currentTitle = '';
let canEditPrices = false;
let isAdmin = false;
let currentZone = null;   // zone name string (or null for "all" in admin)
let zoneList = [];        // [{ name, title }, ...] — populated for admin UI
let imagePaths = {
    primary:        'https://docs.fivem.net/vehicles/{model}.webp',
    fallback:       'https://raw.githubusercontent.com/MnCLosSantos/mnc-vehicle-image-storage/main/mnc-vehicle-image-storage/images/{model}.png',
    local_fallback: './images/fallback.png',
};

document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('searchInput');

    window.addEventListener('message', (event) => {
        if (event.data.action === 'openUI') {
            vehicleModels = event.data.models || {};
            currentStyle  = event.data.uiStyle || {};
            currentTitle  = event.data.title || 'Vehicle Catalog';
            canEditPrices = event.data.canEditPrices || false;
            isAdmin       = event.data.isAdmin || false;
            currentZone   = event.data.zoneName || null;
            zoneList      = event.data.zoneList  || [];
            if (event.data.imagePaths) imagePaths = event.data.imagePaths;

            applyUIStyle();
            renderDealerSwap();   // show/hide the admin dealership bar
            openUI();
            populateCategories();
            const first = document.querySelector('.category-item');
            if (first) first.click();
        }

        if (event.data.action === 'showProximityUI') {
            currentStyle = event.data.uiStyle || {};
            currentTitle = event.data.title || 'Vehicle Catalog';
            applyUIStyle();
            showProximityUI();
        }

        if (event.data.action === 'hideProximityUI') {
            hideProximityUI();
        }
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            const lb = document.getElementById('imgLightbox');
            if (lb && !lb.classList.contains('hidden')) {
                closeLightbox();
            } else {
                closeUI();
            }
        }
    });

    searchInput.addEventListener('input', (e) => {
        const searchTerm = e.target.value.toLowerCase();
        if (searchTerm.length > 0) {
            filterVehicles(searchTerm);
        } else if (currentCategory) {
            if (currentCategory === 'All') showAllVehicles();
            else showVehiclesInCategory(currentCategory);
        }
    });
});

// ── Admin dealership swap bar ─────────────────────────────────────────────────
function renderDealerSwap() {
    const bar = document.getElementById('dealer-swap-bar');
    if (!bar) return;

    if (!isAdmin || zoneList.length === 0) {
        bar.style.display = 'none';
        return;
    }

    bar.style.display = 'flex';

    // Build option list: "All Vehicles" + one per zone
    let options = '<option value="all">— All Vehicles —</option>';
    for (const z of zoneList) {
        const sel = (currentZone === z.name) ? ' selected' : '';
        options += `<option value="${z.name}"${sel}>${z.title}</option>`;
    }
    if (!currentZone) {
        // make sure "all" is pre-selected
        options = options.replace('value="all"', 'value="all" selected');
    }

    bar.innerHTML = `
        <label class="dealer-swap-label"><i class="fas fa-store"></i> Dealership:</label>
        <select class="dealer-swap-select" id="dealer-swap-select" onchange="swapDealership(this.value)">
            ${options}
        </select>
    `;
}

function swapDealership(value) {
    fetch(`https://${GetParentResourceName()}/swapDealership`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ dealership: value }),
    });
    // The NUI callback triggers openAdminCatalog on the client which fires
    // a new openUI message — no further JS action needed here.
}

// ── Image helpers ─────────────────────────────────────────────────────────────
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

// ── Shared card builder ───────────────────────────────────────────────────────
function createVehicleCard(vehicle) {
    const card = document.createElement('div');
    card.className = 'vehicle-card';

    const adminEditHTML = canEditPrices ? `
        <div class="price-edit-container" id="price-edit-${vehicle.model}">
            <button class="price-edit-btn" onclick="togglePriceEdit('${vehicle.model}', ${vehicle.price})">
                <i class="fas fa-pencil-alt"></i> Edit Price
            </button>
            <div class="price-edit-form hidden" id="price-form-${vehicle.model}">
                <input type="number" class="price-edit-input" id="price-input-${vehicle.model}"
                    value="${vehicle.price}" min="0" step="100"
                    onkeydown="handlePriceKey(event, '${vehicle.model}', '${vehicle.name}')">
                <div class="price-edit-actions">
                    <button class="price-save-btn" onclick="submitPriceUpdate('${vehicle.model}', '${vehicle.name}')">
                        <i class="fas fa-check"></i>
                    </button>
                    <button class="price-cancel-btn" onclick="cancelPriceEdit('${vehicle.model}')">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
            </div>
            <div class="price-edit-feedback hidden" id="price-feedback-${vehicle.model}"></div>
        </div>
    ` : '';

    // Dealership swap editor — admin only (requires zoneList to be populated)
    const dealerEditHTML = (isAdmin && zoneList.length > 0) ? (() => {
        let opts = '<option value="">— No Dealership —</option>';
        for (const z of zoneList) {
            const sel = (vehicle.shop && vehicle.shop === z.name) ? ' selected' : '';
            opts += `<option value="${z.name}"${sel}>${z.title}</option>`;
        }
        return `
        <div class="price-edit-container" id="dealer-edit-${vehicle.model}">
            <button class="price-edit-btn dealer-edit-btn" onclick="toggleDealerEdit('${vehicle.model}')">
                <i class="fas fa-store"></i> Change Dealership
            </button>
            <div class="price-edit-form hidden" id="dealer-form-${vehicle.model}">
                <select class="price-edit-input dealer-edit-select" id="dealer-select-${vehicle.model}">
                    ${opts}
                </select>
                <div class="price-edit-actions">
                    <button class="price-save-btn" onclick="submitDealerUpdate('${vehicle.model}', '${vehicle.name}')">
                        <i class="fas fa-check"></i>
                    </button>
                    <button class="price-cancel-btn" onclick="cancelDealerEdit('${vehicle.model}')">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
            </div>
            <div class="price-edit-feedback hidden" id="dealer-feedback-${vehicle.model}"></div>
        </div>
        `;
    })() : '';

    card.innerHTML = `
        <div class="vehicle-header">
            <div class="vehicle-name">${vehicle.name}</div>
            <div class="vehicle-category">${vehicle.category}</div>
        </div>
        <div class="vehicle-image-container" onclick="openLightbox(this.querySelector('img'))">
            <img src="${imagePaths.primary.replace('{model}', vehicle.model)}"
                 class="vehicle-image"
                 alt="${vehicle.name}"
                 loading="lazy"
                 onerror="handleVehicleImgError(this, '${vehicle.model}')">
        </div>
        <div class="vehicle-content">
            <div class="vehicle-info">
                <p><i class="fas fa-dollar-sign"></i> <strong>Price:</strong> <span id="price-display-${vehicle.model}">${vehicle.price.toLocaleString()}</span></p>
                <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${vehicle.category}</p>
                <p><i class="fas fa-industry"></i> <strong>Manufacturer:</strong> ${vehicle.brand}</p>
                <p><i class="fas fa-car"></i> <strong>Vehicle Model:</strong> ${vehicle.model}</p>
            </div>
            ${adminEditHTML}
            ${dealerEditHTML}
        </div>
    `;

    // Store current shop on card element for live updates
    card.dataset.shop = vehicle.shop || '';
    return card;
}

// ── Price edit helpers ────────────────────────────────────────────────────────
function togglePriceEdit(model, currentPrice) {
    const btn  = document.querySelector(`#price-edit-${model} .price-edit-btn`);
    const form = document.getElementById(`price-form-${model}`);
    const fb   = document.getElementById(`price-feedback-${model}`);
    fb.classList.add('hidden');
    btn.classList.add('hidden');
    form.classList.remove('hidden');
    const input = document.getElementById(`price-input-${model}`);
    input.value = currentPrice;
    input.focus();
    input.select();
}

function cancelPriceEdit(model) {
    document.getElementById(`price-form-${model}`).classList.add('hidden');
    document.getElementById(`price-feedback-${model}`).classList.add('hidden');
    document.querySelector(`#price-edit-${model} .price-edit-btn`).classList.remove('hidden');
}

function handlePriceKey(event, model, name) {
    if (event.key === 'Enter')  submitPriceUpdate(model, name);
    if (event.key === 'Escape') cancelPriceEdit(model);
}

function submitPriceUpdate(model, name) {
    const input    = document.getElementById(`price-input-${model}`);
    const newPrice = parseInt(input.value, 10);

    if (isNaN(newPrice) || newPrice < 0) {
        showPriceFeedback(model, 'Invalid price — must be a positive number.', false);
        return;
    }

    const saveBtn = document.querySelector(`#price-form-${model} .price-save-btn`);
    saveBtn.disabled = true;
    saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';

    // Pass the current zone so the server can scope the permission check.
    // For admin UI, currentZone may be null (meaning "all") — server handles that.
    fetch(`https://${GetParentResourceName()}/updateVehiclePrice`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, name, price: newPrice, zone: currentZone || '' }),
    })
    .then(r => r.json())
    .then(res => {
        if (res.success) {
            const displayEl = document.getElementById(`price-display-${model}`);
            if (displayEl) displayEl.textContent = newPrice.toLocaleString();

            for (const cat of Object.values(vehicleModels)) {
                for (const v of cat) {
                    if (v.model === model) { v.price = newPrice; break; }
                }
            }

            cancelPriceEdit(model);
            showPriceFeedback(model, `✓ Price updated to $${newPrice.toLocaleString()}`, true);
        } else {
            saveBtn.disabled = false;
            saveBtn.innerHTML = '<i class="fas fa-check"></i>';
            showPriceFeedback(model, res.error || 'Update failed.', false);
        }
    })
    .catch(() => {
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="fas fa-check"></i>';
        showPriceFeedback(model, 'Request error — check server console.', false);
    });
}

function showPriceFeedback(model, message, success) {
    const fb = document.getElementById(`price-feedback-${model}`);
    fb.textContent = message;
    fb.className   = `price-edit-feedback ${success ? 'feedback-ok' : 'feedback-err'}`;
    setTimeout(() => fb.classList.add('hidden'), success ? 3000 : 5000);
}

// ── Dealership editor helpers ─────────────────────────────────────────────────
function toggleDealerEdit(model) {
    const btn  = document.querySelector(`#dealer-edit-${model} .dealer-edit-btn`);
    const form = document.getElementById(`dealer-form-${model}`);
    const fb   = document.getElementById(`dealer-feedback-${model}`);
    fb.classList.add('hidden');
    btn.classList.add('hidden');
    form.classList.remove('hidden');
    document.getElementById(`dealer-select-${model}`).focus();
}

function cancelDealerEdit(model) {
    document.getElementById(`dealer-form-${model}`).classList.add('hidden');
    document.getElementById(`dealer-feedback-${model}`).classList.add('hidden');
    document.querySelector(`#dealer-edit-${model} .dealer-edit-btn`).classList.remove('hidden');
}

function submitDealerUpdate(model, name) {
    const select   = document.getElementById(`dealer-select-${model}`);
    const newShop  = select.value;   // empty string = no dealership
    const saveBtn  = document.querySelector(`#dealer-form-${model} .price-save-btn`);
    saveBtn.disabled = true;
    saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';

    fetch(`https://${GetParentResourceName()}/updateVehicleShop`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, name, shop: newShop }),
    })
    .then(r => r.json())
    .then(res => {
        if (res.success) {
            // Update in-memory data so re-renders stay correct
            for (const cat of Object.values(vehicleModels)) {
                for (const v of cat) {
                    if (v.model === model) { v.shop = newShop; break; }
                }
            }
            // Update the card's stored shop value
            const card = document.querySelector(`#dealer-edit-${model}`)?.closest('.vehicle-card');
            if (card) card.dataset.shop = newShop;

            cancelDealerEdit(model);
            const label = newShop
                ? zoneList.find(z => z.name === newShop)?.title || newShop
                : 'None';
            showDealerFeedback(model, `✓ Dealership set to: ${label}`, true);
        } else {
            saveBtn.disabled = false;
            saveBtn.innerHTML = '<i class="fas fa-check"></i>';
            showDealerFeedback(model, res.error || 'Update failed.', false);
        }
    })
    .catch(() => {
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="fas fa-check"></i>';
        showDealerFeedback(model, 'Request error — check server console.', false);
    });
}

function showDealerFeedback(model, message, success) {
    const fb = document.getElementById(`dealer-feedback-${model}`);
    fb.textContent = message;
    fb.className   = `price-edit-feedback ${success ? 'feedback-ok' : 'feedback-err'}`;
    setTimeout(() => fb.classList.add('hidden'), success ? 3000 : 5000);
}

// ── UI style ──────────────────────────────────────────────────────────────────
function applyUIStyle() {
    const root = document.documentElement;
    root.style.setProperty('--primary-bg',    currentStyle.primaryBg);
    root.style.setProperty('--secondary-bg',  currentStyle.secondaryBg);
    root.style.setProperty('--accent',        currentStyle.accent);
    root.style.setProperty('--text-primary',  currentStyle.textPrimary);
    root.style.setProperty('--text-secondary',currentStyle.textSecondary);
    root.style.setProperty('--border-color',  currentStyle.borderColor);
    root.style.setProperty('--blur',          currentStyle.blur);
    document.getElementById('current-category').innerHTML = `
        <i class="fas fa-layer-group"></i>
        <span>${currentTitle}</span>
    `;
    const proximityContainer = document.getElementById('proximity-ui');
    if (proximityContainer) {
        proximityContainer.style.background  = currentStyle.secondaryBg;
        proximityContainer.style.borderColor = currentStyle.borderColor;
        const proximityTitle = document.getElementById('proximity-title');
        if (proximityTitle) {
            proximityTitle.textContent = currentTitle;
            proximityTitle.style.color = currentStyle.textPrimary;
        }
        const proximityIcon = document.querySelector('#proximity-ui i');
        if (proximityIcon) proximityIcon.style.color = currentStyle.accent;
        const proximityText = document.querySelector('#proximity-ui p');
        if (proximityText) proximityText.style.color = currentStyle.textSecondary;
    }
}

// ── Open / close ──────────────────────────────────────────────────────────────
function openUI() {
    document.body.style.display = 'block';
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.add('visible');
    void dashboard.offsetHeight;
    hideProximityUI();
}

function closeUI() {
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.remove('visible');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
    });
    fetch(`https://${GetParentResourceName()}/reopenProximityUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
    });
}

function showProximityUI() {
    document.body.style.display = 'block';
    const proximityUI = document.getElementById('proximity-ui');
    if (proximityUI) {
        applyUIStyle();
        proximityUI.style.display = 'flex';
        proximityUI.style.opacity = '0';
        void proximityUI.offsetHeight;
        proximityUI.style.opacity = '1';
    }
}

function hideProximityUI() {
    const proximityUI = document.getElementById('proximity-ui');
    if (proximityUI) {
        proximityUI.style.opacity = '0';
        setTimeout(() => { proximityUI.style.display = 'none'; }, 300);
    }
}

// ── Categories ────────────────────────────────────────────────────────────────
function populateCategories() {
    const categoryList = document.getElementById('category-list');
    categoryList.innerHTML = '';

    const categoryIcons = {
        'All':         'fa-layer-group',
        'Motorcycles': 'fa-motorcycle',
        'Helicopters': 'fa-helicopter',
        'Planes':      'fa-plane',
        'Boats':       'fa-ship',
        'Trains':      'fa-train',
        'Cycles':      'fa-bicycle',
    };

    const sortedCategories = ['All', ...Object.keys(vehicleModels).sort((a, b) => a.localeCompare(b))];

    sortedCategories.forEach(category => {
        if (category === 'All' || vehicleModels[category]) {
            const categoryItem = document.createElement('div');
            categoryItem.className = 'category-item';
            categoryItem.innerHTML = `
                <i class="fas ${categoryIcons[category] || 'fa-car'}"></i>
                ${category}
            `;
            categoryItem.addEventListener('click', () => {
                currentCategory = category;
                document.querySelectorAll('.category-item').forEach(el => el.classList.remove('active'));
                categoryItem.classList.add('active');
                document.getElementById('searchInput').value = '';
                if (category === 'All') showAllVehicles();
                else showVehiclesInCategory(category);
            });
            categoryList.appendChild(categoryItem);
        }
    });
}

// ── Vehicle lists ─────────────────────────────────────────────────────────────
function renderVehicleList(vehicles, headerHTML) {
    const vehicleList = document.getElementById('vehicle-list');
    vehicleList.style.opacity = '0';
    setTimeout(() => {
        vehicleList.innerHTML = '';
        document.getElementById('current-category').innerHTML = headerHTML;
        updateResultsCount(vehicles.length);
        vehicles.forEach(v => vehicleList.appendChild(createVehicleCard(v)));
        void vehicleList.offsetHeight;
        vehicleList.style.opacity = '1';
    }, 50);
}

function showAllVehicles() {
    const all = Object.entries(vehicleModels)
        .flatMap(([cat, vs]) => vs.map(v => ({ ...v, category: cat })))
        .sort((a, b) => a.name.localeCompare(b.name));
    renderVehicleList(all, `<i class="fas fa-layer-group"></i><span>${currentTitle}</span>`);
}

function showVehiclesInCategory(category) {
    const vehicles = vehicleModels[category].map(v => ({ ...v, category }));
    renderVehicleList(vehicles, `<i class="fas fa-tag"></i><span>${category}</span>`);
}

function filterVehicles(searchTerm) {
    const all = Object.entries(vehicleModels)
        .flatMap(([cat, vs]) => vs.map(v => ({ ...v, category: cat })))
        .filter(v =>
            v.name.toLowerCase().includes(searchTerm)  ||
            v.model.toLowerCase().includes(searchTerm) ||
            v.brand.toLowerCase().includes(searchTerm))
        .sort((a, b) => a.name.localeCompare(b.name));
    renderVehicleList(all, `<i class="fas fa-search"></i><span>Search Results</span>`);
}

function updateResultsCount(count) {
    document.getElementById('results-count').textContent = `${count} vehicles available`;
}

// ── Image Lightbox ────────────────────────────────────────────────────────────
(function () {
    let _scale = 1, _tx = 0, _ty = 0;
    let _dragging = false, _startX = 0, _startY = 0, _baseX = 0, _baseY = 0;

    function applyTransform(animate) {
        const img = document.getElementById('lightboxImg');
        if (!img) return;
        img.style.transition = animate ? 'transform 0.15s ease' : 'none';
        img.style.transform  = `translate(${_tx}px,${_ty}px) scale(${_scale})`;
        document.getElementById('lightboxZoomLabel').textContent = Math.round(_scale * 100) + '%';
    }

    window.openLightbox = function (imgEl) {
        const lb    = document.getElementById('imgLightbox');
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

    document.addEventListener('wheel', function (e) {
        const lb = document.getElementById('imgLightbox');
        if (!lb || lb.classList.contains('hidden')) return;
        e.preventDefault();
        _scale = Math.min(5, Math.max(0.25, _scale + (e.deltaY < 0 ? 0.15 : -0.15)));
        applyTransform(false);
    }, { passive: false });

    const stage = () => document.getElementById('lightboxStage');

    document.addEventListener('mousedown', function (e) {
        const lb = document.getElementById('imgLightbox');
        if (!lb || lb.classList.contains('hidden')) return;
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
})();