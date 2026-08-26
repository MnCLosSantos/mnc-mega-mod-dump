// Default fallback lists (in case QB-Core data is empty)
let brandList = [
  "Albany","Annis","Benefactor","Bravado","Declasse","Dewbauchee","Dinka",
  "Emperor","Grotti","Karin","Lampadati","Maibatsu","Obey","Ocelot",
  "Pfister","Pegassi","Progen","Vapid","Vulcar","Western"
];

let categoryList = [
  "compacts","sedans","suvs","coupes","muscle","sportsclassics","sports",
  "super","motorcycles","offroad","industrial","utility","vans","cycles",
  "boats","helicopters","planes","service","emergency","military","commercial","trains"
];

let typeList = [
  "automobile","bike","boat","heli","plane","train"
];

let shopList = [
  "pdm","luxury","moto","import","boatshop","airshop"
];

// Dynamic pricing configuration
const pricingConfig = {
  basePrices: {
    compacts: 15000,
    sedans: 25000,
    suvs: 35000,
    coupes: 30000,
    muscle: 40000,
    sportsclassics: 50000,
    sports: 60000,
    super: 100000,
    motorcycles: 20000,
    offroad: 30000,
    industrial: 25000,
    utility: 20000,
    vans: 25000,
    cycles: 5000,
    boats: 50000,
    helicopters: 150000,
    planes: 200000,
    service: 20000,
    emergency: 30000,
    military: 50000,
    commercial: 40000,
    trains: 100000
  },
  brandMultipliers: {
    Albany: 0.9,
    Annis: 1.1,
    Benefactor: 1.2,
    Bravado: 1.0,
    Declasse: 0.95,
    Dewbauchee: 1.3,
    Dinka: 1.05,
    Emperor: 0.9,
    Grotti: 1.25,
    Karin: 1.0,
    Lampadati: 1.2,
    Maibatsu: 1.0,
    Obey: 1.1,
    Ocelot: 1.15,
    Pfister: 1.2,
    Pegassi: 1.3,
    Progen: 1.35,
    Vapid: 1.0,
    Vulcar: 0.95,
    Western: 1.0,
    Unknown: 0.9
  },
  typeMultipliers: {
    automobile: 1.0,
    bike: 0.8,
    boat: 1.2,
    heli: 1.5,
    plane: 1.7,
    train: 2.0
  },
  premiumShopMultiplier: {
    luxury: 1.3,
    import: 1.4,
    airshop: 1.5,
    boatshop: 1.2,
    moto: 1.1,
    pdm: 1.0
  }
};

// Calculate dynamic price based on category, brand, type, and shop
function calculateDynamicPrice(category, brand, type, shop) {
  const basePrice = pricingConfig.basePrices[category] || 10000;
  const brandMultiplier = pricingConfig.brandMultipliers[brand] || 1.0;
  const typeMultiplier = pricingConfig.typeMultipliers[type] || 1.0;
  const shopMultiplier = pricingConfig.premiumShopMultiplier[shop] || 1.0;

  // Calculate final price with dynamic adjustments
  let price = basePrice * brandMultiplier * typeMultiplier * shopMultiplier;

  // Apply some randomness for variation (±5%)
  const variation = 1 + (Math.random() * 0.1 - 0.05);
  price *= variation;

  // Round to nearest 100
  return Math.round(price / 100) * 100;
}

// Populate dropdown options dynamically
function populateDropdown(id, list) {
  const dropdown = document.getElementById(id);
  dropdown.innerHTML = "";
  list.forEach(option => {
    const div = document.createElement("div");
    div.textContent = option;
    div.addEventListener("click", () => {
      const input = dropdown.parentElement.querySelector("input");
      input.value = option;
      dropdown.style.display = "none";
      if (input.id === "category" || input.id === "brand" || input.id === "type" || input.id === "shop") {
        updateDynamicPrice();
      }
    });
    dropdown.appendChild(div);
  });
}

// Initialize dropdowns with default values
function initializeDropdowns() {
  populateDropdown("brandOptions", brandList);
  populateDropdown("categoryOptions", categoryList);
  populateDropdown("typeOptions", typeList);
  populateDropdown("shopOptions", shopList);
}

// Setup filtering and autocomplete behavior
function setupDropdownBehavior() {
  document.querySelectorAll(".combo.searchable input").forEach(input => {
    const dropdown = input.parentElement.querySelector(".dropdown");

    input.addEventListener("focus", () => {
      dropdown.style.display = "block";
    });

    input.addEventListener("input", () => {
      const value = input.value.toLowerCase();
      const options = dropdown.querySelectorAll("div");
      options.forEach(opt => {
        opt.style.display = opt.textContent.toLowerCase().includes(value) ? "block" : "none";
      });
    });

    // Auto-complete on Enter key
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        const visibleOptions = Array.from(dropdown.querySelectorAll("div"))
          .filter(opt => opt.style.display !== "none");
        if (visibleOptions.length > 0) {
          input.value = visibleOptions[0].textContent;
          dropdown.style.display = "none";
          if (input.id === "category" || input.id === "brand" || input.id === "type" || input.id === "shop") {
            updateDynamicPrice();
          }
        } else {
          dropdown.style.display = "none";
        }
      }
    });

    input.addEventListener("blur", () => {
      setTimeout(() => {
        dropdown.style.display = "none";
      }, 150);
    });
  });
}

// Update price based on all factors
function updateDynamicPrice() {
  if (document.getElementById("autoPriceOnBtn").classList.contains("active")) {
    const category = document.getElementById("category").value;
    const brand = document.getElementById("brand").value;
    const type = document.getElementById("type").value;
    const shop = document.getElementById("shop").value;
    if (category && brand && type && shop) {
      const price = calculateDynamicPrice(category, brand, type, shop);
      document.getElementById("price").value = price;
    }
  }
}

// Settings modal functions
function openSettingsModal() {
  document.getElementById("settingsModal").classList.remove("hidden");
  document.body.classList.add("editor-open");
}

function closeSettingsModal() {
  document.getElementById("settingsModal").classList.add("hidden");
  document.body.classList.remove("editor-open");
}

function setTheme(theme) {
  document.body.classList.remove("light-mode");
  if (theme === "light") {
    document.body.classList.add("light-mode");
    document.getElementById("lightThemeBtn").classList.add("active");
    document.getElementById("darkThemeBtn").classList.remove("active");
  } else {
    document.getElementById("darkThemeBtn").classList.add("active");
    document.getElementById("lightThemeBtn").classList.remove("active");
  }
}

// Initialize on load
initializeDropdowns();
setupDropdownBehavior();

// Theme toggle initialization
document.getElementById("darkThemeBtn").classList.add("active");
document.getElementById("autoPriceOnBtn").addEventListener("click", () => {
  document.getElementById("autoPriceOnBtn").classList.add("active");
  document.getElementById("autoPriceOffBtn").classList.remove("active");
  document.getElementById("autoPriceStatus").textContent = "On";
  updateDynamicPrice();
});

document.getElementById("autoPriceOffBtn").addEventListener("click", () => {
  document.getElementById("autoPriceOffBtn").classList.add("active");
  document.getElementById("autoPriceOnBtn").classList.remove("active");
  document.getElementById("autoPriceStatus").textContent = "Off";
});

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    // Update lists if provided from QB-Core
    if (data.lists) {
      if (data.lists.brands && data.lists.brands.length > 0) {
        brandList = data.lists.brands;
        populateDropdown("brandOptions", brandList);
      }
      if (data.lists.categories && data.lists.categories.length > 0) {
        categoryList = data.lists.categories;
        populateDropdown("categoryOptions", categoryList);
      }
      if (data.lists.types && data.lists.types.length > 0) {
        typeList = data.lists.types;
        populateDropdown("typeOptions", typeList);
      }
      if (data.lists.shops && data.lists.shops.length > 0) {
        shopList = data.lists.shops;
        populateDropdown("shopOptions", shopList);
      }
      
      // Re-setup dropdown behavior after updating
      setupDropdownBehavior();
    }
    
    // Show editor and populate form
    document.getElementById('editor').classList.remove('hidden');
    document.body.classList.add("editor-open");
    Object.keys(data.data).forEach((key) => {
      const el = document.getElementById(key);
      if (el) el.value = data.data[key];
    });
    updateDynamicPrice();
  }
});

document.getElementById('saveBtn').addEventListener('click', () => {
  const payload = {
    model: document.getElementById('model').value,
    name: document.getElementById('name').value,
    brand: document.getElementById('brand').value,
    price: parseInt(document.getElementById('price').value) || 0,
    category: document.getElementById('category').value,
    type: document.getElementById('type').value,
    shop: document.getElementById('shop').value,
  };
  fetch(`https://${GetParentResourceName()}/saveVehicle`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  });
  document.getElementById('editor').classList.add('hidden');
  document.body.classList.remove("editor-open");
});

document.getElementById('closeBtn').addEventListener('click', () => {
  fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
  document.getElementById('editor').classList.add('hidden');
  document.body.classList.remove("editor-open");
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    fetch(`https://${GetParentResourceName()}/escape`, { method: 'POST' });
    document.getElementById('editor').classList.add('hidden');
    document.getElementById('settingsModal').classList.add('hidden');
    document.body.classList.remove("editor-open");
  }
});