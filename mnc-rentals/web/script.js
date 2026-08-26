// script.js
let vehicleModels = {};
let currentCategory = null;
let currentStyle = {};
let currentTitle = '';
let currentLogo = '';
let selectedVehicle = null;

document.addEventListener('DOMContentLoaded', () => {
    window.addEventListener('message', (event) => {
        if (event.data.type === 'setVehicleModels') {
            vehicleModels = event.data.models;
            currentStyle = event.data.uiStyle || {};
            currentTitle = event.data.title || 'Vehicle Rentals';
            currentLogo = event.data.logo || '';
            
            applyUIStyle();
            populateCategories();
            
            const firstCategory = document.querySelector('.category-item');
            if (firstCategory) firstCategory.click();
        }

        if (event.data.action === "openUI") {
            currentStyle = event.data.uiStyle || {};
            currentTitle = event.data.title || 'Vehicle Rentals';
            currentLogo = event.data.logo || '';
            
            applyUIStyle();
            openUI();
        }
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            if (document.getElementById('durationModal').classList.contains('visible')) {
                closeDurationModal();
            } else {
                closeUI();
            }
        }
    });
});

function applyUIStyle() {
    const root = document.documentElement;
    if (currentStyle.primaryBg) root.style.setProperty('--primary-bg', currentStyle.primaryBg);
    if (currentStyle.secondaryBg) root.style.setProperty('--secondary-bg', currentStyle.secondaryBg);
    if (currentStyle.accent) {
        root.style.setProperty('--accent', currentStyle.accent);
        const hex = currentStyle.accent.replace('#', '');
        const r = parseInt(hex.substr(0, 2), 16);
        const g = parseInt(hex.substr(2, 2), 16);
        const b = parseInt(hex.substr(4, 2), 16);
        root.style.setProperty('--accent-rgb', `${r}, ${g}, ${b}`);
    }
    if (currentStyle.textPrimary) root.style.setProperty('--text-primary', currentStyle.textPrimary);
    if (currentStyle.textSecondary) root.style.setProperty('--text-secondary', currentStyle.textSecondary);
    if (currentStyle.borderColor) root.style.setProperty('--border-color', currentStyle.borderColor);
    if (currentStyle.blur) root.style.setProperty('--blur', currentStyle.blur);
    
    document.getElementById('current-category').innerHTML = `
        <i class="fas fa-layer-group"></i>
        <span>${currentTitle}</span>
    `;
    document.getElementById('logo').src = currentLogo;
    document.getElementById('watermark').src = currentLogo;
}

function openUI() {
    document.body.style.display = 'block';
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
        headers: {
            'Content-Type': 'application/json'
        },
    });
}

function populateCategories() {
    const categoryList = document.getElementById('category-list');
    categoryList.innerHTML = '';

    const categoryIcons = {
        'All': 'fa-layer-group',
        'Motorcycles': 'fa-motorcycle',
        'Helicopters': 'fa-helicopter',
        'Planes': 'fa-plane',
        'Boats': 'fa-ship',
        'Trains': 'fa-train',
        'Cycles': 'fa-bicycle',
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
                if (category === 'All') showAllVehicles();
                else showVehiclesInCategory(category);
            });
            categoryList.appendChild(categoryItem);
        }
    });
}

function showAllVehicles() {
    const vehicleList = document.getElementById('vehicle-list');
    vehicleList.style.opacity = '0';
    setTimeout(() => {
        vehicleList.innerHTML = '';
        const allVehicles = Object.entries(vehicleModels).flatMap(([category, vehicles]) =>
            vehicles.map(vehicle => ({
                ...vehicle,
                category: category
            }))
        );
        const sortedVehicles = allVehicles.sort((a, b) => a.name.localeCompare(b.name));

        document.getElementById('current-category').innerHTML = `
            <i class="fas fa-layer-group"></i>
            <span>${currentTitle}</span>
        `;
        updateResultsCount(sortedVehicles.length);

        sortedVehicles.forEach(vehicle => {
            const card = document.createElement('div');
            card.className = 'vehicle-card';
            card.innerHTML = createVehicleCard(vehicle);
            vehicleList.appendChild(card);
        });
        void vehicleList.offsetHeight;
        vehicleList.style.opacity = '1';
    }, 50);
}

function showVehiclesInCategory(category) {
    const vehicleList = document.getElementById('vehicle-list');
    vehicleList.style.opacity = '0';
    setTimeout(() => {
        vehicleList.innerHTML = '';
        const sortedVehicles = [...vehicleModels[category]].sort((a, b) => a.name.localeCompare(b.name));

        document.getElementById('current-category').innerHTML = `
            <i class="fas fa-tag"></i>
            <span>${category}</span>
        `;
        updateResultsCount(sortedVehicles.length);

        sortedVehicles.forEach(vehicle => {
            const card = document.createElement('div');
            card.className = 'vehicle-card';
            card.innerHTML = createVehicleCard(vehicle);
            vehicleList.appendChild(card);
        });
        void vehicleList.offsetHeight;
        vehicleList.style.opacity = '1';
    }, 50);
}

function createVehicleCard(vehicle) {
    return `
        <div class="vehicle-header">
            <div class="vehicle-name">${vehicle.name}</div>
            <div class="vehicle-category">${vehicle.category}</div>
        </div>
        <div class="vehicle-image-container">
            <img src="https://docs.fivem.net/vehicles/${vehicle.model}.webp" 
                 class="vehicle-image" 
                 alt="${vehicle.name}"
                 loading="lazy"
                 onerror="this.onerror=null; this.src='images/${vehicle.model}.png'; this.onerror=() => {this.src='images/fallback.png'}">
        </div>
        <div class="vehicle-content">
            <div class="vehicle-info">
                <p><i class="fas fa-dollar-sign"></i> <strong>Base Price:</strong> $${vehicle.rentalPrice.toLocaleString()}/hr</p>
                <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${vehicle.category}</p>
                <p><i class="fas fa-industry"></i> <strong>Manufacturer:</strong> ${vehicle.brand}</p>
                <p><i class="fas fa-car"></i> <strong>Vehicle Model:</strong> ${vehicle.model}</p>
            </div>
            <div class="vehicle-actions">
                <button class="spawn-btn" onclick='openDurationModal(${JSON.stringify(vehicle).replace(/'/g, "&#39;")})'>
                    <i class="fas fa-plus"></i> Rent Vehicle
                </button>
            </div>
        </div>
    `;
}

function updateResultsCount(count) {
    document.getElementById('results-count').textContent = `${count} vehicles available`;
}

function openDurationModal(vehicle) {
    selectedVehicle = vehicle;
    const modal = document.getElementById('durationModal');
    
    // Populate vehicle info
    document.getElementById('durationVehicleInfo').innerHTML = `
        <h4>${vehicle.name}</h4>
        <p><strong>Category:</strong> ${vehicle.category}</p>
        <p><strong>Base Rate:</strong> $${vehicle.rentalPrice.toLocaleString()}/hour</p>
    `;
    
    // Create duration options (1-3 hours)
    const optionsHtml = [];
    for (let hours = 1; hours <= 3; hours++) {
        const totalPrice = vehicle.rentalPrice * hours;
        const refundAmount = Math.floor(totalPrice * 0.1);
        
        optionsHtml.push(`
            <div class="duration-option" onclick="confirmRental(${hours})">
                <div class="duration-option-left">
                    <i class="fas fa-clock"></i>
                    <div class="duration-option-text">
                        <h4>${hours} Hour${hours > 1 ? 's' : ''}</h4>
                        <p>10% refund: $${refundAmount.toLocaleString()}</p>
                    </div>
                </div>
                <div class="duration-option-price">
                    $${totalPrice.toLocaleString()}
                </div>
            </div>
        `);
    }
    
    document.getElementById('durationOptions').innerHTML = optionsHtml.join('');
    modal.classList.add('visible');
}

function closeDurationModal() {
    document.getElementById('durationModal').classList.remove('visible');
    selectedVehicle = null;
}

function confirmRental(hours) {
    if (!selectedVehicle) return;
    
    const totalPrice = selectedVehicle.rentalPrice * hours;
    
    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            model: selectedVehicle.model,
            hours: hours,
            totalPrice: totalPrice
        }),
    });
    
    closeDurationModal();
    closeUI();
}

function spawnVehicle(model) {
    // This function is kept for compatibility but now redirects to duration modal
    const vehicle = findVehicleByModel(model);
    if (vehicle) {
        openDurationModal(vehicle);
    }
}

function findVehicleByModel(model) {
    for (const category in vehicleModels) {
        const vehicle = vehicleModels[category].find(v => v.model === model);
        if (vehicle) return vehicle;
    }
    return null;
}