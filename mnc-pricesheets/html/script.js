let currentData = null;
let activeDiscounts = {};
let canDiscount = false;
let selectedItem = null;
let confirmCallback = null;

// Listen for messages from client
window.addEventListener('message', (e) => {
  const data = e.data;
  
  if (data.action === 'openSheet') {
    currentData = data;
    activeDiscounts = data.activeDiscounts || {};
    canDiscount = data.canDiscount || false;
    openSheet();
  } else if (data.action === 'updateDiscounts') {
    activeDiscounts = data.activeDiscounts || {};
    refreshItems();
  } else if (data.action === 'updateSpecials') {
    // FIX: Preserve static specials and merge with updated dynamic ones
    const staticSpecials = currentData.specialOffers 
      ? currentData.specialOffers.filter(s => s.type === 'static' || s.type === undefined || !s.id)
      : [];
    
    const updatedDynamics = (data.specials || []).map(s => ({
      ...s,
      type: 'dynamic'
    }));
    
    // Rebuild full specials list: static + updated dynamic
    currentData.specialOffers = [...staticSpecials, ...updatedDynamics];
    
    // Refresh the specials tab (includes auto-discounted items)
    populateSpecialOffers();
  }
});

// Open sheet
function openSheet() {
  const sheet = document.getElementById('priceSheet');
  const title = document.getElementById('sheetTitle');
  const categoryFilter = document.getElementById('categoryFilter');
  
  // Apply theme to sheet and all modals
  const themeClass = `theme-${currentData.theme}`;
  sheet.className = themeClass;
  document.getElementById('discountModal').className = `modal hidden ${themeClass}`;
  document.getElementById('specialModal').className = `modal hidden ${themeClass}`;
  document.getElementById('confirmModal').className = `modal hidden ${themeClass}`;
  
  title.textContent = currentData.sheetName;
  
  addWatermark();
  
  categoryFilter.innerHTML = '<option value="all">All Categories</option>';
  currentData.categories.forEach(cat => {
    const option = document.createElement('option');
    option.value = cat.name;
    option.textContent = cat.name;
    categoryFilter.appendChild(option);
  });
  
  document.getElementById('settingsBtn').style.display = canDiscount ? 'block' : 'none';
  
  switchTab('menu');
  populateItems();
  populateSpecialOffers();
  
  sheet.classList.remove('hidden');
}

function addWatermark() {
  const wrapper = document.querySelector('.sheet-wrapper');
  const existingWatermark = wrapper.querySelector('.sheet-watermark');
  if (existingWatermark) existingWatermark.remove();
  
  if (currentData.watermark) {
    const watermark = document.createElement('img');
    watermark.className = 'sheet-watermark';
    watermark.src = currentData.watermark;
    watermark.alt = 'Watermark';
    wrapper.insertBefore(watermark, wrapper.firstChild);
  }
}

function switchTab(tabName) {
  document.querySelectorAll('.tab-btn').forEach(tab => {
    tab.classList.toggle('active', tab.dataset.tab === tabName);
  });
  
  document.querySelectorAll('.tab-content').forEach(content => {
    content.classList.toggle('active', content.id === `${tabName}Tab`);
  });
}

function populateItems() {
  const grid = document.getElementById('itemsGrid');
  grid.innerHTML = '';

  currentData.categories.forEach(category => {
    category.items.forEach((item, itemIndex) => {
      const card = createItemCard(item, category.name, itemIndex, category.icon);
      grid.appendChild(card);
    });
  });

  filterItems();
}

function refreshItems() {
  populateItems();
  populateSpecialOffers();
}

function createItemCard(item, categoryName, itemIndex, categoryIcon) {
  const card = document.createElement('div');
  card.className = 'item-card';
  card.setAttribute('data-category', categoryName);
  card.setAttribute('data-name', item.name.toLowerCase());
  card.setAttribute('data-item-index', itemIndex);

  const discount = (activeDiscounts[categoryName] && activeDiscounts[categoryName][itemIndex]) || 0;
  const hasDiscount = discount > 0;

  const originalPrice = item.price;
  const discountedPrice = hasDiscount ? (originalPrice * (1 - discount / 100)).toFixed(2) : originalPrice;
  const imageUrl = `${currentData.imagePath}${item.image}`;

  const escapedCategory = categoryName.replace(/'/g, "\\'").replace(/"/g, '\\"');
  const escapedItemName = item.name.replace(/'/g, "\\'").replace(/"/g, '\\"');

  card.innerHTML = `
    ${hasDiscount ? `<div class="discount-badge">-${discount}%</div>` : ''}
    <img src="${imageUrl}" alt="${item.name}" class="item-image" onerror="this.src='https://via.placeholder.com/200x140?text=No+Image'">
    <div class="item-category-badge">
      <i class="fas ${categoryIcon || 'fa-box'}"></i>
      ${categoryName}
    </div>
    <div class="item-name">${item.name}</div>
    <div class="item-description">${item.description || ''}</div>
    <div class="item-footer">
      <div class="item-price">
        ${hasDiscount ? `<span class="price-original">$${originalPrice.toLocaleString()}</span>` : ''}
        <span class="price-current ${hasDiscount ? 'discounted' : ''}">$${Number(discountedPrice).toLocaleString()}</span>
      </div>
      ${canDiscount ? `
        <div class="discount-actions">
          ${!hasDiscount ? `
            <button class="btn-discount" data-category="${escapedCategory}" data-index="${itemIndex}" data-name="${escapedItemName}" data-price="${originalPrice}">
              <i class="fas fa-percent"></i> Discount
            </button>
          ` : `
            <button class="btn-remove-discount" data-category="${escapedCategory}" data-index="${itemIndex}">
              <i class="fas fa-trash"></i> Remove
            </button>
          `}
        </div>
      ` : ''}
    </div>
  `;

  if (canDiscount) {
    const discountBtn = card.querySelector('.btn-discount');
    const removeBtn = card.querySelector('.btn-remove-discount');
    
    if (discountBtn) {
      discountBtn.addEventListener('click', function() {
        openDiscountModal(
          this.getAttribute('data-category'),
          parseInt(this.getAttribute('data-index')),
          this.getAttribute('data-name'),
          parseFloat(this.getAttribute('data-price'))
        );
      });
    }
    
    if (removeBtn) {
      removeBtn.addEventListener('click', function() {
        const category = this.getAttribute('data-category');
        const index = parseInt(this.getAttribute('data-index'));
        showConfirm('Are you sure you want to remove this discount?', () => {
          removeDiscount(category, index);
        });
      });
    }
  }

  return card;
}

function populateSpecialOffers() {
  const grid = document.getElementById('specialGrid');
  grid.innerHTML = '';

  const discountedItems = getDiscountedItems().map(item => ({ ...item, type: 'discounted' }));
  const allSpecials = [...(currentData.specialOffers || []), ...discountedItems];

  if (allSpecials.length === 0) {
    grid.innerHTML = `<div class="empty-state"><i class="fas fa-tag"></i><p>No special offers available at this time</p></div>`;
    return;
  }

  allSpecials.forEach(offer => grid.appendChild(createSpecialCard(offer)));
}

function getDiscountedItems() {
  const discounted = [];
  currentData.categories.forEach(category => {
    category.items.forEach((item, itemIndex) => {
      const discount = (activeDiscounts[category.name] && activeDiscounts[category.name][itemIndex]) || 0;
      if (discount > 0) {
        const salePrice = (item.price * (1 - discount / 100)).toFixed(2);
        discounted.push({
          name: item.name,
          description: item.description || '',
          originalPrice: item.price,
          salePrice: parseFloat(salePrice),
          image: item.image,
          isDiscounted: true,
          discountPercent: discount
        });
      }
    });
  });
  return discounted;
}

function createSpecialCard(offer) {
  const card = document.createElement('div');
  card.className = 'special-card';

  const imageUrl = `${currentData.imagePath}${offer.image}`;
  const savings = offer.originalPrice - offer.salePrice;
  const savingsPercent = Math.round((savings / offer.originalPrice) * 100);

  let removeBtn = '';
  if (canDiscount && offer.type === 'dynamic') {
    removeBtn = `<button class="btn-remove-special" data-special-id="${offer.id}">
      <i class="fas fa-trash"></i> Remove
    </button>`;
  }

  card.innerHTML = `
    ${removeBtn}
    <img src="${imageUrl}" alt="${offer.name}" class="special-image" onerror="this.src='https://via.placeholder.com/300x200?text=No+Image'">
    <div class="special-info">
      <div class="special-name">${offer.name}</div>
      ${offer.description ? `<div class="special-description">${offer.description}</div>` : ''}
      <div class="special-pricing">
        <span class="price-original-special">$${offer.originalPrice.toLocaleString()}</span>
        <span class="price-sale">$${offer.salePrice.toLocaleString()}</span>
      </div>
      <div class="savings-badge">Save ${savingsPercent}% ($${savings.toLocaleString()})</div>
    </div>
  `;

  if (canDiscount && offer.type === 'dynamic') {
    card.querySelector('.btn-remove-special').addEventListener('click', function() {
      const id = this.getAttribute('data-special-id');
      showConfirm('Are you sure you want to remove this special offer?', () => {
        removeSpecialOffer(id);
      });
    });
  }

  return card;
}

function filterItems() {
  const category = document.getElementById('categoryFilter').value;
  const search = document.getElementById('searchBar').value.toLowerCase();
  const cards = document.querySelectorAll('.item-card');

  let visibleCount = 0;
  cards.forEach(card => {
    const cardCategory = card.getAttribute('data-category');
    const cardName = card.getAttribute('data-name');
    const categoryMatch = category === 'all' || cardCategory === category;
    const searchMatch = search === '' || cardName.includes(search);

    if (categoryMatch && searchMatch) {
      card.style.display = 'block';
      visibleCount++;
    } else {
      card.style.display = 'none';
    }
  });

  const grid = document.getElementById('itemsGrid');
  const empty = grid.querySelector('.empty-state');
  if (visibleCount === 0 && !empty) {
    grid.innerHTML += `<div class="empty-state"><i class="fas fa-search"></i><p>No items found matching your search</p></div>`;
  } else if (visibleCount > 0 && empty) {
    empty.remove();
  }
}

function openDiscountModal(category, itemIndex, itemName, price) {
  selectedItem = { category, itemIndex, itemName, price };
  document.getElementById('discountItemName').textContent = `Apply discount to: ${itemName} ($${price})`;
  document.getElementById('discountInput').value = '';
  const modal = document.getElementById('discountModal');
  modal.classList.remove('hidden');
  // Ensure theme is applied
  if (currentData && currentData.theme) {
    modal.className = `modal theme-${currentData.theme}`;
  }
}

function closeDiscountModal() {
  document.getElementById('discountModal').classList.add('hidden');
  selectedItem = null;
}

function applyDiscount() {
  const discount = parseInt(document.getElementById('discountInput').value);
  if (isNaN(discount) || discount < 0 || discount > 100) return;

  fetch(`https://${GetParentResourceName()}/applyDiscount`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      category: selectedItem.category, 
      itemIndex: selectedItem.itemIndex, 
      discount: discount 
    })
  });

  closeDiscountModal();
}

function removeDiscount(category, itemIndex) {
  fetch(`https://${GetParentResourceName()}/removeDiscount`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      category: category, 
      itemIndex: itemIndex 
    })
  });
}

function openSpecialModal() {
  document.getElementById('specialName').value = '';
  document.getElementById('specialDesc').value = '';
  document.getElementById('specialOriginal').value = '';
  document.getElementById('specialSale').value = '';

  const imageMap = new Map();
  currentData.categories.forEach(cat => {
    cat.items.forEach(item => {
      if (!imageMap.has(item.image)) {
        imageMap.set(item.image, item.name);
      }
    });
  });
  
  const container = document.getElementById('imageGridContainer');
  container.innerHTML = '';
  
  let selectedImage = null;
  
  [...imageMap.entries()].sort((a, b) => a[0].localeCompare(b[0])).forEach(([img, name]) => {
    const option = document.createElement('div');
    option.className = 'image-option';
    option.setAttribute('data-image', img);
    
    option.innerHTML = `
      <img src="${currentData.imagePath}${img}" alt="${name}" onerror="this.style.display='none'">
      <span class="image-name">${name}</span>
      <span class="image-filename">${img}</span>
    `;
    
    option.addEventListener('click', function() {
      document.querySelectorAll('.image-option').forEach(opt => opt.classList.remove('selected'));
      this.classList.add('selected');
      selectedImage = img;
    });
    
    container.appendChild(option);
  });

  document.getElementById('specialModal').selectedImageGetter = () => selectedImage;
  const modal = document.getElementById('specialModal');
  modal.classList.remove('hidden');
  // Ensure theme is applied
  if (currentData && currentData.theme) {
    modal.className = `modal theme-${currentData.theme}`;
  }
}

function closeSpecialModal() {
  document.getElementById('specialModal').classList.add('hidden');
}

function createSpecial() {
  const name = document.getElementById('specialName').value.trim();
  const desc = document.getElementById('specialDesc').value.trim();
  const orig = parseFloat(document.getElementById('specialOriginal').value);
  const sale = parseFloat(document.getElementById('specialSale').value);
  const imageGetter = document.getElementById('specialModal').selectedImageGetter;
  const image = imageGetter ? imageGetter() : null;


  fetch(`https://${GetParentResourceName()}/createSpecial`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, description: desc, originalPrice: orig, salePrice: sale, image })
  });

  closeSpecialModal();
}

function showConfirm(message, callback) {
  document.getElementById('confirmMessage').textContent = message;
  confirmCallback = callback;
  const modal = document.getElementById('confirmModal');
  modal.classList.remove('hidden');
  // Ensure theme is applied
  if (currentData && currentData.theme) {
    modal.className = `modal theme-${currentData.theme}`;
  }
}

function closeConfirmModal() {
  document.getElementById('confirmModal').classList.add('hidden');
  confirmCallback = null;
}

function removeSpecialOffer(id) {
  fetch(`https://${GetParentResourceName()}/removeSpecial`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ specialId: id })
  });
}

function closeSheet() {
  document.getElementById('priceSheet').classList.add('hidden');
  document.getElementById('searchBar').value = '';
  document.getElementById('categoryFilter').value = 'all';
  currentData = null;
  activeDiscounts = {};

  fetch(`https://${GetParentResourceName()}/closeSheet`, { method: 'POST', headers: { 'Content-Type': 'application/json' } });
}

// Event Listeners
document.getElementById('closeBtn')?.addEventListener('click', closeSheet);
document.getElementById('categoryFilter')?.addEventListener('change', filterItems);
document.getElementById('searchBar')?.addEventListener('input', filterItems);

document.querySelectorAll('.tab-btn').forEach(btn => btn.addEventListener('click', () => switchTab(btn.dataset.tab)));

document.getElementById('discountCancelBtn')?.addEventListener('click', closeDiscountModal);
document.getElementById('discountConfirmBtn')?.addEventListener('click', applyDiscount);

document.getElementById('specialCancelBtn')?.addEventListener('click', closeSpecialModal);
document.getElementById('specialConfirmBtn')?.addEventListener('click', createSpecial);

document.getElementById('settingsBtn')?.addEventListener('click', openSpecialModal);

document.getElementById('confirmCancelBtn')?.addEventListener('click', closeConfirmModal);
document.getElementById('confirmRemoveBtn')?.addEventListener('click', () => {
  if (confirmCallback) confirmCallback();
  closeConfirmModal();
});

document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  const d = document.getElementById('discountModal');
  const s = document.getElementById('specialModal');
  const c = document.getElementById('confirmModal');
  const sheet = document.getElementById('priceSheet');
  if (d && !d.classList.contains('hidden')) closeDiscountModal();
  else if (s && !s.classList.contains('hidden')) closeSpecialModal();
  else if (c && !c.classList.contains('hidden')) closeConfirmModal();
  else if (sheet && !sheet.classList.contains('hidden')) closeSheet();
});