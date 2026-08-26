// script.js
let brandList = [
    "Albany","Annis","Benefactor","Bravado","Declasse","Dewbauchee","Dinka","Emperor","Grotti","Karin",
    "Lampadati","Maibatsu","Obey","Ocelot","Pfister","Pegassi","Progen","Vapid","Vulcar","Western",
    "Western Motorcycle Company","Übermacht","Schyster","Bolingbroke","Buckingham","Canis","Coil",
    "Enus","Fathom","HVY","Imponte","JoBuilt","LCC","Mammoth","MTL","Nagasaki","Principe","Rune",
    "Shitzu","Speedophile","Stanley","Truffade","Weeny","Willard","Zirconium","Brute","Police",
    "Sheriff","Fire Truck","Lifeguard","Park Ranger","Seashark","Speeder","Submersible","Toro",
    "Tug","Buzzard","Frogger","Maverick","SuperVolito","Valkyrie","Unknown"
];
let categoryList = ["compacts","sedans","suvs","coupes","muscle","sportsclassics","sports","super","motorcycles","offroad","industrial","utility","vans","cycles","boats","helicopters","planes","service","emergency","military","commercial","trains"];
let typeList = ["automobile","bike","boat","heli","plane","train"];
let shopList = ["pdm","luxury","moto","import","boatshop","airshop"];

let fullVehicleList = [];          // vehicles in qb-core
let fullUnavailableVehicleList = []; // vehicles NOT in qb-core

const pricingConfig = {
  basePrices: {
    compacts:15000,sedans:25000,suvs:35000,coupes:30000,muscle:40000,sportsclassics:50000,
    sports:60000,super:100000,motorcycles:20000,offroad:30000,industrial:25000,utility:20000,
    vans:25000,cycles:5000,boats:50000,helicopters:150000,planes:200000,service:20000,
    emergency:30000,military:50000,commercial:40000,trains:100000
  },
  // Case-insensitive: exact + lowercase keys
  brandMultipliers: {
    "Albany":0.9,"albany":0.9,
    "Annis":1.1,"annis":1.1,
    "Benefactor":1.2,"benefactor":1.2,
    "Bravado":1.0,"bravado":1.0,
    "Declasse":0.95,"declasse":0.95,
    "Dewbauchee":1.3,"dewbauchee":1.3,
    "Dinka":1.05,"dinka":1.05,
    "Emperor":0.9,"emperor":0.9,
    "Grotti":1.25,"grotti":1.25,
    "Karin":1.0,"karin":1.0,
    "Lampadati":1.2,"lampadati":1.2,
    "Maibatsu":1.0,"maibatsu":1.0,
    "Obey":1.1,"obey":1.1,
    "Ocelot":1.15,"ocelot":1.15,
    "Pfister":1.2,"pfister":1.2,
    "Pegassi":1.3,"pegassi":1.3,
    "Progen":1.35,"progen":1.35,
    "Vapid":1.0,"vapid":1.0,
    "Vulcar":0.95,"vulcar":0.95,
    "Western":1.0,"western":1.0,
    "Western Motorcycle Company":1.0,"western motorcycle company":1.0,
    "Übermacht":1.25,"übermacht":1.25,
    "Schyster":0.95,"schyster":0.95,
    "Unknown":0.9,"unknown":0.9
  },
  typeMultipliers:{automobile:1.0,bike:0.8,boat:1.2,heli:1.5,plane:1.7,train:2.0},
  premiumShopMultiplier:{luxury:1.3,import:1.4,airshop:1.5,boatshop:1.2,moto:1.1,pdm:1.0}
};

function calculateDynamicPrice(category, brand, type, shop) {
  const base = pricingConfig.basePrices[category] || 10000;
  const bm = pricingConfig.brandMultipliers[brand] || pricingConfig.brandMultipliers[brand.toLowerCase()] || 1.0;
  const tm = pricingConfig.typeMultipliers[type] || 1.0;
  const sm = pricingConfig.premiumShopMultiplier[shop] || 1.0;
  let price = base * bm * tm * sm;
  price *= (1 + (Math.random()*0.1 - 0.05));
  return Math.round(price/100)*100;
}

/* ---------- AUTO-TYPE FROM CATEGORY ---------- */
const categoryToTypeMap = {
  motorcycles:"bike",boats:"boat",helicopters:"heli",planes:"plane",trains:"train",
  compacts:"automobile",sedans:"automobile",suvs:"automobile",coupes:"automobile",
  muscle:"automobile",sportsclassics:"automobile",sports:"automobile",super:"automobile",
  offroad:"automobile",industrial:"automobile",utility:"automobile",vans:"automobile",
  cycles:"bike",service:"automobile",emergency:"automobile",military:"automobile",
  commercial:"automobile",openwheel:"automobile"
};

function syncTypeFromCategory() {
  const cat = document.getElementById("category").value.toLowerCase();
  const mapped = categoryToTypeMap[cat];
  if (mapped) document.getElementById("type").value = mapped;
}

/* ---------- THEME SWITCH (FIXED) ---------- */
function setTheme(theme) {
  if (theme === "dark") {
    document.body.classList.remove("light-mode");
    document.getElementById("darkThemeBtn").classList.add("active");
    document.getElementById("lightThemeBtn").classList.remove("active");
  } else {
    document.body.classList.add("light-mode");
    document.getElementById("lightThemeBtn").classList.add("active");
    document.getElementById("darkThemeBtn").classList.remove("active");
  }
}

/* ---------- DROPDOWN POPULATION ---------- */
function populateDropdown(id, list) {
  const dd = document.getElementById(id);
  dd.innerHTML = "";
  list.forEach(o => {
    const d = document.createElement("div");
    d.textContent = o;
    d.addEventListener("click", () => {
      const inp = dd.parentElement.querySelector("input");
      inp.value = o;
      dd.style.display = "none";
      if (["category","brand","type","shop"].includes(inp.id)) {
        updateDynamicPrice();
        if (inp.id === "category") syncTypeFromCategory();
      }
    });
    dd.appendChild(d);
  });
}

/* ---------- LIST POPULATION ---------- */
function populateVehicleList(vehicles, listId, countId) {
  const list = document.getElementById(listId);
  const cnt = document.getElementById(countId);
  list.innerHTML = ""; cnt.textContent = vehicles.length;

  vehicles.forEach(v => {
    const div = document.createElement("div"); div.className = "vehicle-item";
    div.innerHTML = `
      <div class="vehicle-name">${v.name || v.model}</div>
      <div class="vehicle-details">
        Model: ${v.model}<br>Brand: ${v.brand||"Unknown"}<br>Category: ${v.category||"unknown"}<br>
        Type: ${v.type||"automobile"}<br>Shop: ${v.shop||"luxury"}<br>Price: $${v.price||0}
      </div>`;
    div.addEventListener("click", e => {
      fillMainForm(v);
      document.querySelectorAll(".vehicle-item").forEach(i => i.classList.remove("selected"));
      div.classList.add("selected");
    });
    list.appendChild(div);
  });
}

/* ---------- FILL MAIN FORM ---------- */
function fillMainForm(v) {
  document.getElementById("model").value = v.model?.toLowerCase() || "";
  document.getElementById("name").value = v.name || "";
  document.getElementById("brand").value = v.brand || "Unknown";
  document.getElementById("price").value = v.price || 0;
  document.getElementById("category").value = v.category || "unknown";
  document.getElementById("type").value = v.type || "automobile";
  document.getElementById("shop").value = v.shop || "luxury";

  syncTypeFromCategory();
  updateDynamicPrice();
}

/* ---------- FILTER ---------- */
function filterVehicleList(searchId, listId, full) {
  const term = document.getElementById(searchId).value.toLowerCase();
  const filtered = full.filter(v => 
    (v.name && v.name.toLowerCase().includes(term)) || 
    (v.model && v.model.toLowerCase().includes(term))
  );
  populateVehicleList(filtered, listId, listId === "vehicleList" ? "vehicleCount" : "unavailableVehicleCount");
}

/* ---------- DROPDOWN BEHAVIOR ---------- */
function initializeDropdowns() {
  populateDropdown("brandOptions", brandList);
  populateDropdown("categoryOptions", categoryList);
  populateDropdown("typeOptions", typeList);
  populateDropdown("shopOptions", shopList);
  populateDropdown("fallbackShopOptions", shopList);
}

function setupDropdownBehavior() {
  document.querySelectorAll(".combo.searchable input").forEach(inp => {
    const dd = inp.parentElement.querySelector(".dropdown");
    inp.addEventListener("focus", () => { dd.style.display = "block"; });
    inp.addEventListener("input", () => {
      const f = inp.value.toLowerCase();
      Array.from(dd.querySelectorAll("div")).forEach(o => 
        o.style.display = o.textContent.toLowerCase().includes(f) ? "block" : "none"
      );
    });
    inp.addEventListener("keydown", e => {
      if (e.key === "Enter") {
        e.preventDefault();
        const vis = Array.from(dd.querySelectorAll("div")).filter(o => o.style.display !== "none");
        if (vis.length > 0) {
          inp.value = vis[0].textContent;
          dd.style.display = "none";
          if (["category","brand","type","shop","fallbackShop"].includes(inp.id)) {
            updateDynamicPrice();
            if (inp.id === "category") syncTypeFromCategory();
          }
        }
      }
    });
    inp.addEventListener("blur", () => {
      setTimeout(() => { dd.style.display = "none"; }, 150);
    });
  });

  document.getElementById("category").addEventListener("input", syncTypeFromCategory);
}

/* ---------- AUTO PRICE ---------- */
function updateDynamicPrice() {
  if (!document.getElementById("autoPriceOnBtn").classList.contains("active")) return;
  const cat = document.getElementById("category").value;
  const br = document.getElementById("brand").value;
  const tp = document.getElementById("type").value || "automobile";
  const sh = document.getElementById("shop").value || "luxury";
  if (cat && br && tp && sh) {
    const p = calculateDynamicPrice(cat, br, tp, sh);
    document.getElementById("price").value = p;
  }
}

/* ---------- SETTINGS MODAL ---------- */
function openSettingsModal() {
  document.getElementById("settingsModal").classList.remove("hidden");
  document.body.classList.add("editor-open");
}

function closeSettingsModal() {
  document.getElementById("settingsModal").classList.add("hidden");
  document.body.classList.remove("editor-open");
}

/* ---------- EXPORT ALL MODAL ---------- */
function openExportAllModal() {
  document.getElementById("exportAllModal").classList.remove("hidden");
  document.body.classList.add("editor-open");
}

function closeExportAllModal() {
  document.getElementById("exportAllModal").classList.add("hidden");
  document.body.classList.remove("editor-open");
}

/* ---------- TOGGLE BUTTONS ---------- */
function toggleBtn(onBtn, offBtn, statusEl, isOn) {
  if (isOn) {
    onBtn.classList.add("active");
    offBtn.classList.remove("active");
    statusEl.textContent = "Yes";
  } else {
    offBtn.classList.add("active");
    onBtn.classList.remove("active");
    statusEl.textContent = "No";
  }
}

/* ---------- EXPORT ALL LOGIC ---------- */
document.getElementById("exportAllBtn").addEventListener("click", async () => {
  const fallbackShop = document.getElementById("fallbackShop").value || "luxury";
  const exclude18 = document.getElementById('exclude18Status').textContent === 'Yes';
  const autoPriceAll = document.getElementById('autoPriceAllStatus').textContent === 'Yes';

  let toExport = [...fullUnavailableVehicleList];

  if (exclude18) {
    toExport = toExport.filter(v => v.category?.toLowerCase() !== 'emergency');
  }

  if (toExport.length === 0) {
    alert('No vehicles to export with the current filters.');
    return;
  }

  const progBar = document.getElementById('exportProgressBar');
  const progText = document.getElementById('exportProgressText');
  document.getElementById('exportProgress').classList.remove('hidden');
  progText.textContent = `0 / ${toExport.length}`;

  const CHUNK_SIZE = 100;
  const CHUNK_DELAY = 5000;

  let exported = 0;

  for (let i = 0; i < toExport.length; i += CHUNK_SIZE) {
    const chunk = toExport.slice(i, i + CHUNK_SIZE).map(v => {
      const shop = fallbackShop;
      const price = autoPriceAll
        ? calculateDynamicPrice(v.category, v.brand, v.type, shop)
        : (v.price || 0);

      return {
        model: v.model,
        name: v.name,
        brand: v.brand,
        price,
        category: v.category,
        type: v.type,
        shop
      };
    });

    await new Promise(res => {
      fetch(`https://${GetParentResourceName()}/exportChunk`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(chunk)
      }).then(r => r.json()).then(data => {
        exported += chunk.length;
        const percent = Math.round((exported / toExport.length) * 100);
        progBar.style.width = percent + '%';
        progText.textContent = `${exported} / ${toExport.length}`;
        res();
      }).catch(err => {
        console.error(err);
        res();
      });
    });

    await new Promise(r => setTimeout(r, CHUNK_DELAY));
  }

  setTimeout(() => {
    document.getElementById('exportProgress').classList.add('hidden');
    closeExportAllModal();
  }, 600);
});

/* ----- TOGGLE BUTTONS (Export modal) ----- */
document.getElementById('exclude18On').addEventListener('click', () => toggleBtn(
  document.getElementById('exclude18On'),
  document.getElementById('exclude18Off'),
  document.getElementById('exclude18Status'), true));

document.getElementById('exclude18Off').addEventListener('click', () => toggleBtn(
  document.getElementById('exclude18Off'),
  document.getElementById('exclude18On'),
  document.getElementById('exclude18Status'), false));

document.getElementById('autoPriceAllOn').addEventListener('click', () => toggleBtn(
  document.getElementById('autoPriceAllOn'),
  document.getElementById('autoPriceAllOff'),
  document.getElementById('autoPriceAllStatus'), true));

document.getElementById('autoPriceAllOff').addEventListener('click', () => toggleBtn(
  document.getElementById('autoPriceAllOff'),
  document.getElementById('autoPriceAllOn'),
  document.getElementById('autoPriceAllStatus'), false));

/* ---------- INITIALISE ---------- */
initializeDropdowns(); 
setupDropdownBehavior();
document.getElementById("darkThemeBtn").classList.add("active");

// Auto-price toggle
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

// Search filters
document.getElementById("vehicleSearch").addEventListener("input", () => filterVehicleList("vehicleSearch", "vehicleList", fullVehicleList));
document.getElementById("unavailableVehicleSearch").addEventListener("input", () => filterVehicleList("unavailableVehicleSearch", "unavailableVehicleList", fullUnavailableVehicleList));

/* ---------- THEME BUTTONS ---------- */
document.getElementById('darkThemeBtn').addEventListener('click', () => setTheme('dark'));
document.getElementById('lightThemeBtn').addEventListener('click', () => setTheme('light'));

/* ---------- NUI LISTENER ---------- */
window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'open') {
    if (d.lists) {
      if (d.lists.brands && d.lists.brands.length > 0) { brandList = d.lists.brands; populateDropdown("brandOptions", brandList); }
      if (d.lists.categories && d.lists.categories.length > 0) { categoryList = d.lists.categories; populateDropdown("categoryOptions", categoryList); }
      if (d.lists.types && d.lists.types.length > 0) { typeList = d.lists.types; populateDropdown("typeOptions", typeList); }
      if (d.lists.shops && d.lists.shops.length > 0) { shopList = d.lists.shops; populateDropdown("shopOptions", shopList); populateDropdown("fallbackShopOptions", shopList); }
      if (d.lists.vehicles && d.lists.vehicles.length > 0) { fullVehicleList = d.lists.vehicles; populateVehicleList(fullVehicleList, "vehicleList", "vehicleCount"); }
      if (d.lists.unavailableVehicles && d.lists.unavailableVehicles.length > 0) { fullUnavailableVehicleList = d.lists.unavailableVehicles; populateVehicleList(fullUnavailableVehicleList, "unavailableVehicleList", "unavailableVehicleCount"); }
      setupDropdownBehavior();
    }
    document.getElementById('editor').classList.remove('hidden');
    document.body.classList.add("editor-open");
    Object.keys(d.data).forEach(k => {
      const el = document.getElementById(k);
      if (el) {
        if (k === "model") el.value = d.data[k].toLowerCase();
        else if (k === "name") el.value = d.data[k] || d.data.model.charAt(0).toUpperCase() + d.data.model.slice(1).toLowerCase();
        else if (k === "type") el.value = d.data[k] || "automobile";
        else if (k === "shop") el.value = d.data[k] || "luxury";
        else el.value = d.data[k];
      }
    });

    syncTypeFromCategory();
    updateDynamicPrice();
  }
});

/* ---------- SAVE (new vehicle) ---------- */
document.getElementById('saveBtn').addEventListener('click', () => {
  const m = document.getElementById('model').value.toLowerCase();
  const n = document.getElementById('name').value || m.charAt(0).toUpperCase() + m.slice(1).toLowerCase();
  const payload = {
    model: m,
    name: n.charAt(0).toUpperCase() + n.slice(1).toLowerCase(),
    brand: document.getElementById('brand').value || "Unknown",
    price: parseInt(document.getElementById('price').value) || 0,
    category: document.getElementById('category').value || "unknown",
    type: document.getElementById('type').value || "automobile",
    shop: document.getElementById('shop').value || "luxury"
  };
  fetch(`https://${GetParentResourceName()}/saveVehicle`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  });
  document.getElementById('editor').classList.add('hidden');
  document.body.classList.remove('editor-open');
});

/* ---------- CLOSE ---------- */
document.getElementById('closeBtn').addEventListener('click', () => {
  fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
  document.getElementById('editor').classList.add('hidden');
  document.body.classList.remove('editor-open');
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    fetch(`https://${GetParentResourceName()}/escape`, { method: 'POST' });
    document.getElementById('editor').classList.add('hidden');
    document.getElementById('settingsModal').classList.add('hidden');
    document.getElementById('exportAllModal').classList.add('hidden');
    document.body.classList.remove('editor-open');
  }
});