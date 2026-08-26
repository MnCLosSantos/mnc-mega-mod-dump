let currentEngines = [];
let selectedEngine = null;
let isProcessingOrder = false;

const vehicleIcons = {
  // Supercars
  'ADDER': 'fa-car',
  'BANSHEE': 'fa-car',
  'BULLET': 'fa-car',
  'CHEETAH': 'fa-car',
  'ENTITYXF': 'fa-car',
  'INFERNUS': 'fa-car',
  'OSIRIS': 'fa-car',
  'T20': 'fa-car',
  'TURISMOR': 'fa-car',
  'VACCA': 'fa-car',
  'ZENTORNO': 'fa-car',
  'TYRUS': 'fa-car',
  'REAPER': 'fa-car',
  'FMJ': 'fa-car',
  'PFISTER811': 'fa-car',
  'COQUETTE': 'fa-car',
  // Sports Cars
  'F620': 'fa-car',
  'JESTER': 'fa-car',
  'KURUMA': 'fa-car',
  'MASSACRO': 'fa-car',
  'SULTAN': 'fa-car',
  // Muscle Cars
  'GAUNTLET': 'fa-car-side',
  'DOMINATOR': 'fa-car-side',
  'RUINER': 'fa-car-side',
  'SABRETURBO': 'fa-car-side',
  'VIGERO': 'fa-car-side',
  'PHOENIX': 'fa-car-side',
  'TAMPA': 'fa-car-side',
  'DUKES': 'fa-car-side',
  'BLADE': 'fa-car-side',
  'FACTION': 'fa-car-side',
  'NIGHTSHADE': 'fa-car-side',
  'SLAMVAN': 'fa-car-side',
  'VOODOO': 'fa-car-side',
  // Lowriders
  'CHINO': 'fa-car-alt',
  'BUCCANEER': 'fa-car-alt',
  'MANANA': 'fa-car-alt',
  'PEYOTE': 'fa-car-alt',
  'VIRGO': 'fa-car-alt',
  // Motorcycles
  'BATI': 'fa-motorcycle',
  'AKUMA': 'fa-motorcycle',
  'HAKUCHOU': 'fa-motorcycle',
  'DOUBLE': 'fa-motorcycle',
  'VINDICATOR': 'fa-motorcycle',
  'BAGGER': 'fa-motorcycle',
  'CARBONRS': 'fa-motorcycle',
  'SANCHEZ': 'fa-motorcycle',
  'ENDURO': 'fa-motorcycle',
  'FAGGIO': 'fa-motorcycle',
  'PCJ600': 'fa-motorcycle',
  'RUFFIAN': 'fa-motorcycle',
  'NEMESIS': 'fa-motorcycle',
  'DAEMON': 'fa-motorcycle',
  'HEXER': 'fa-motorcycle',
  'INNOVATION': 'fa-motorcycle',
  'SOVEREIGN': 'fa-motorcycle',
  'GARGOYLE': 'fa-motorcycle',
  'THRUST': 'fa-motorcycle',
  'WOLFSBANE': 'fa-motorcycle',
  // Sedans
  'BUFFALO': 'fa-car',
  'SCHAFTER': 'fa-car',
  'TAILGATER': 'fa-car',
  'WARRENER': 'fa-car',
  'STRATUM': 'fa-car',
  'INGOT': 'fa-car',
  'PREMIER': 'fa-car',
  'ASTEROPE': 'fa-car',
  'FUGITIVE': 'fa-car',
  'GLENDALE': 'fa-car',
  'REGINA': 'fa-car',
  'WASHINGTON': 'fa-car',
  'PRIMO': 'fa-car',
  'STANIER': 'fa-car',
  'ASEA': 'fa-car',
  'SURGE': 'fa-car',
  'COGNOSCENTI': 'fa-car',
  'ORACLE': 'fa-car',
  'INTRUDER': 'fa-car',
  'FELON': 'fa-car',
  'JACKAL': 'fa-car'
};

// Listen for messages from client.lua
window.addEventListener('message', (e) => {
  const data = e.data;
  console.log('Received NUI message:', JSON.stringify(data));

  if (data.action === 'openShop') {
    currentEngines = data.engines || [];
    document.getElementById('shop').className = `theme-${data.shopTheme || 'blue'}`;
    document.getElementById('modal').className = `modal theme-${data.shopTheme || 'blue'} hidden`;
    document.getElementById('shopTitle').textContent = data.shopTitle || 'Engine Shop';
    openShop();
  }
});

// Open shop and populate engine cards
function openShop() {
  const shop = document.getElementById('shop');
  const grid = document.getElementById('enginesGrid');
  const categoryFilter = document.getElementById('categoryFilter');

  shop.classList.remove('hidden');
  grid.innerHTML = '';
  categoryFilter.innerHTML = '<option value="all">All Categories</option>';

  currentEngines.forEach(category => {
    const option = document.createElement('option');
    option.value = category.category;
    option.textContent = category.category;
    categoryFilter.appendChild(option);
    category.engines.forEach((engine, index) => {
      const card = createEngineCard(engine, index, category.category);
      grid.appendChild(card);
    });
  });

  // Reset search and category filter
  document.getElementById('searchBar').value = '';
  categoryFilter.value = 'all';
  filterEngines();
}

// Create individual engine card
function createEngineCard(engine, index, category) {
  const card = document.createElement('div');
  card.className = 'engine-card';
  card.setAttribute('data-index', index);
  card.setAttribute('data-category', category);

  // Use the sound's icon from vehicleIcons, default to 'fa-car' if not defined
  const iconClass = vehicleIcons[engine.sound] || 'fa-car';

  card.innerHTML = `
    <img src="${engine.image}" alt="${engine.name}" class="engine-image">
    <div class="engine-name">${engine.name}</div>
    <div class="engine-description">${engine.description}</div>
    <div class="engine-footer">
      <span class="engine-price">$${engine.price.toLocaleString()}</span>
      <button class="engine-select-btn"><i class="fas ${iconClass}"></i> Select</button>
    </div>
  `;

  // Add click event to the Select button
  const selectButton = card.querySelector('.engine-select-btn');
  selectButton.addEventListener('click', (event) => {
    event.stopPropagation(); // Prevent the card's click event from firing
    selectedEngine = engine;
    console.log('Selected engine:', selectedEngine.name); // Debug log
    openModal(engine); // Open the confirmation modal
  });

  return card;
}

// Open confirmation modal
function openModal(engine) {
  const modal = document.getElementById('modal');
  const modalTitle = document.getElementById('modalTitle');
  const modalImage = document.getElementById('modalImage');
  const modalDescription = document.getElementById('modalDescription');
  const modalPrice = document.getElementById('modalPrice');

  modalTitle.textContent = `Order ${engine.name} Engine`;
  modalImage.innerHTML = `<img src="${engine.image}" alt="${engine.name}" class="modal-image">`;
  modalDescription.textContent = engine.description;
  modalPrice.textContent = `$${engine.price.toLocaleString()}`;

  modal.classList.remove('hidden');
}

// Close modal
function closeModal() {
    const modal = document.getElementById('modal');
    modal.classList.add('hidden');
    document.getElementById('playerIdInput').value = ''; // Clear input
    selectedEngine = null;
}

// Close shop
function closeShop() {
  const shop = document.getElementById('shop');
  shop.classList.add('hidden');

  fetch(`https://${GetParentResourceName()}/closeShop`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  })
  .then(() => console.log('Sent closeShop message to client'))
  .catch(err => console.error('Failed to send closeShop message:', err));
}

// Confirm engine order
function confirmOrder() {
    if (!selectedEngine) {
        console.error('No engine selected');
        return;
    }

    if (isProcessingOrder) {
        console.log('Order already in progress, ignoring click');
        return;
    }

    isProcessingOrder = true;
    console.log('Ordering engine:', selectedEngine.name);

    const playerIdInput = document.getElementById('playerIdInput').value;
    const targetPlayerId = playerIdInput ? parseInt(playerIdInput) : null;

    fetch(`https://${GetParentResourceName()}/orderEngine`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ engine: selectedEngine, targetPlayerId: targetPlayerId })
    })
    .then(() => {
        console.log('Sent orderEngine message to client');
        closeModal();
        closeShop();
        setTimeout(() => { isProcessingOrder = false; }, 1000);
    })
    .catch(err => {
        console.error('Failed to send orderEngine message:', err);
        isProcessingOrder = false;
    });
}

// Filter engines by category and search
function filterEngines() {
  const category = document.getElementById('categoryFilter').value;
  const search = document.getElementById('searchBar').value.toLowerCase();
  const grid = document.getElementById('enginesGrid');
  grid.innerHTML = '';

  currentEngines.forEach(cat => {
    if (category === 'all' || cat.category === category) {
      cat.engines.forEach((engine, index) => {
        if (engine.name.toLowerCase().includes(search) || engine.description.toLowerCase().includes(search)) {
          const card = createEngineCard(engine, index, cat.category);
          grid.appendChild(card);
        }
      });
    }
  });
}

// Event Listeners
document.getElementById('closeBtn').addEventListener('click', closeShop);
document.getElementById('cancelBtn').addEventListener('click', closeModal);
document.getElementById('confirmBtn').addEventListener('click', confirmOrder);
document.getElementById('categoryFilter').addEventListener('change', filterEngines);
document.getElementById('searchBar').addEventListener('input', filterEngines);

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    const modal = document.getElementById('modal');
    const shop = document.getElementById('shop');

    if (!modal.classList.contains('hidden')) {
      closeModal();
    } else if (!shop.classList.contains('hidden')) {
      closeShop();
    }
  }
});