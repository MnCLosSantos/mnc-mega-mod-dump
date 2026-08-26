let vehicleModels = {};
let currentCategory = null;
let currentStyle = {};
let currentTitle = '';

document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('searchInput');

    window.addEventListener('message', (event) => {
        if (event.data.type === 'setVehicleModels') {
            vehicleModels = event.data.models;
            currentStyle = event.data.uiStyle || Config.UIStyles['style1'];
            currentTitle = event.data.title || 'Vehicle Catalog';
            
            applyUIStyle();
            populateCategories();
            
            const firstCategory = document.querySelector('.category-item');
            if (firstCategory) firstCategory.click();
        }

        if (event.data.action === "openUI") {
            currentStyle = event.data.uiStyle || Config.UIStyles['style1'];
            currentTitle = event.data.title || 'Vehicle Catalog';
            
            applyUIStyle();
            openUI();
        }

        if (event.data.action === "showProximityUI") {
            currentStyle = event.data.uiStyle || Config.UIStyles['style1'];
            currentTitle = event.data.title || 'Vehicle Catalog';
            applyUIStyle();
            showProximityUI();
        }

        if (event.data.action === "hideProximityUI") {
            hideProximityUI();
        }
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            closeUI();
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

function applyUIStyle() {
    const root = document.documentElement;
    root.style.setProperty('--primary-bg', currentStyle.primaryBg);
    root.style.setProperty('--secondary-bg', currentStyle.secondaryBg);
    root.style.setProperty('--accent', currentStyle.accent);
    root.style.setProperty('--text-primary', currentStyle.textPrimary);
    root.style.setProperty('--text-secondary', currentStyle.textSecondary);
    root.style.setProperty('--border-color', currentStyle.borderColor);
    root.style.setProperty('--blur', currentStyle.blur);
    document.getElementById('current-category').innerHTML = `
        <i class="fas fa-layer-group"></i>
        <span>${currentTitle}</span>
    `;
    const proximityContainer = document.getElementById('proximity-ui');
    if (proximityContainer) {
        proximityContainer.style.background = currentStyle.secondaryBg;
        proximityContainer.style.borderColor = currentStyle.borderColor;
        const proximityTitle = document.getElementById('proximity-title');
        if (proximityTitle) {
            proximityTitle.textContent = currentTitle;
            proximityTitle.style.color = currentStyle.textPrimary;
        }
        const proximityIcon = document.querySelector('#proximity-ui i');
        if (proximityIcon) {
            proximityIcon.style.color = currentStyle.accent;
        }
        const proximityText = document.querySelector('#proximity-ui p');
        if (proximityText) {
            proximityText.style.color = currentStyle.textSecondary;
        }
    }
    console.log("Applied UI style:", currentStyle);
}

function openUI() {
    document.body.style.display = 'block';
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.add('visible');
    void dashboard.offsetHeight;
    hideProximityUI();
    console.log("UI opened");
}

function closeUI() {
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.remove('visible');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
    });
    fetch(`https://${GetParentResourceName()}/reopenProximityUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
    });
    console.log("UI closed, requesting proximity UI reopen");
}

function showProximityUI() {
    document.body.style.display = 'block';
    const proximityUI = document.getElementById('proximity-ui');
    if (proximityUI) {
        applyUIStyle(); // Ensure style is applied before showing
        proximityUI.style.display = 'flex';
        proximityUI.style.opacity = '0';
        void proximityUI.offsetHeight;
        proximityUI.style.opacity = '1';
        console.log("Proximity UI shown with style:", currentStyle);
    }
}

function hideProximityUI() {
    const proximityUI = document.getElementById('proximity-ui');
    if (proximityUI) {
        proximityUI.style.opacity = '0';
        setTimeout(() => {
            proximityUI.style.display = 'none';
        }, 300); // Match transition duration
        console.log("Proximity UI hidden");
    }
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
                document.getElementById('searchInput').value = '';
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
            card.innerHTML = `
                <div class="vehicle-header">
                    <div class="vehicle-name">${vehicle.name}</div>
                    <div class="vehicle-category">${vehicle.category}</div>
                </div>
                <div class="vehicle-image-container">
                    <img src="https://docs.fivem.net/vehicles/${vehicle.model}.webp" 
                         class="vehicle-image" 
                         alt="${vehicle.name}"
                         loading="lazy"
                         onerror="this.onerror=null; this.src='./images/${vehicle.model}.png'; this.onerror=() => {this.src='./images/fallback.png'}">
                </div>
                <div class="vehicle-content">
                    <div class="vehicle-info">
                        <p><i class="fas fa-dollar-sign"></i> <strong>Price:</strong> ${vehicle.price.toLocaleString()}</p>
                        <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${vehicle.category}</p>
                        <p><i class="fas fa-industry"></i> <strong>Manufacturer:</strong> ${vehicle.brand}</p>
                        <p><i class="fas fa-car"></i> <strong>Vehicle Model:</strong> ${vehicle.model}</p>
                    </div>
                </div>
            `;
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
        const sortedVehicles = [...vehicleModels[category]].map(vehicle => ({
            ...vehicle,
            category: category
        }));

        document.getElementById('current-category').innerHTML = `
            <i class="fas fa-tag"></i>
            <span>${category}</span>
        `;
        updateResultsCount(sortedVehicles.length);

        sortedVehicles.forEach(vehicle => {
            const card = document.createElement('div');
            card.className = 'vehicle-card';
            card.innerHTML = `
                <div class="vehicle-header">
                    <div class="vehicle-name">${vehicle.name}</div>
                    <div class="vehicle-category">${vehicle.category}</div>
                </div>
                <div class="vehicle-image-container">
                    <img src="https://docs.fivem.net/vehicles/${vehicle.model}.webp" 
                         class="vehicle-image" 
                         alt="${vehicle.name}"
                         loading="lazy"
                         onerror="this.onerror=null; this.src='./images/${vehicle.model}.png'; this.onerror=() => {this.src='./images/fallback.png'}">
                </div>
                <div class="vehicle-content">
                    <div class="vehicle-info">
                        <p><i class="fas fa-dollar-sign"></i> <strong>Price:</strong> ${vehicle.price.toLocaleString()}</p>
                        <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${vehicle.category}</p>
                        <p><i class="fas fa-industry"></i> <strong>Maker:</strong> ${vehicle.brand}</p>
                        <p><i class="fas fa-car"></i> <strong>Vehicle Model:</strong> ${vehicle.model}</p>
                    </div>
                </div>
            `;
            vehicleList.appendChild(card);
        });
        void vehicleList.offsetHeight;
        vehicleList.style.opacity = '1';
    }, 50);
}

function updateResultsCount(count) {
    document.getElementById('results-count').textContent = `${count} vehicles available`;
}

function filterVehicles(searchTerm) {
    const vehicleList = document.getElementById('vehicle-list');
    vehicleList.style.opacity = '0';
    setTimeout(() => {
        vehicleList.innerHTML = '';
        const allVehicles = Object.entries(vehicleModels).flatMap(([category, vehicles]) =>
            vehicles.map(vehicle => ({ ...vehicle, category: category})));

        const filteredVehicles = allVehicles
            .filter(vehicle => 
                vehicle.name.toLowerCase().includes(searchTerm) || 
                vehicle.model.toLowerCase().includes(searchTerm) || 
                vehicle.brand.toLowerCase().includes(searchTerm)
            )
            .sort((a, b) => a.name.localeCompare(b.name));

        document.getElementById('current-category').innerHTML = `
            <i class="fas fa-search"></i>
            <span>Search Results</span>
        `;
        updateResultsCount(filteredVehicles.length);

        filteredVehicles.forEach(vehicle => {
            const card = document.createElement('div');
            card.className = 'vehicle-card';
            card.innerHTML = `
                <div class="vehicle-header">
                    <div class="vehicle-name">${vehicle.name}</div>
                    <div class="vehicle-category">${vehicle.category}</div>
                </div>
                <div class="vehicle-image-container">
                    <img src="https://docs.fivem.net/vehicles/${vehicle.model}.webp" 
                         class="vehicle-image" 
                         alt="${vehicle.name}"
                         loading="lazy"
                         onerror="this.onerror=null; this.src='./images/${vehicle.model}.png'; this.onerror=() => {this.src='./images/fallback.png'}">
                </div>
                <div class="vehicle-content">
                    <div class="vehicle-info">
                        <p><i class="fas fa-dollar-sign"></i> <strong>Price:</strong> ${vehicle.price.toLocaleString()}</p>
                        <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${vehicle.category}</p>
                        <p><i class="fas fa-industry"></i> <strong>Maker:</strong> ${vehicle.brand}</p>
                        <p><i class="fas fa-car"></i> <strong>Vehicle Model:</strong> ${vehicle.model}</p>
                    </div>
                </div>
            `;
            vehicleList.appendChild(card);
        });
        void vehicleList.offsetHeight;
        vehicleList.style.opacity = '1';
    }, 50);
}