let itemModels = {};
let currentCategory = null;
let currentStyle = {};
let currentTitle = '';
let isAdmin = false;
let cart = [];

// Proximity UI state
let proximityUIVisible = false;
let currentProximityZone = null;
let shopUIOpen = false; // Track if main shop UI is open

// Helper: returns an <img> element that tries .png then .jpg/.jpeg then fallback
function createItemImage(itemName, altText, className) {
    const img = document.createElement('img');
    img.alt = altText;
    img.className = className;
    img.loading = 'lazy';

    const formats = [
        `./images/${itemName}.png`,
        `./images/${itemName}.jpg`,
        `./images/${itemName}.jpeg`,
    ];
    let formatIndex = 0;

    function tryNext() {
        if (formatIndex < formats.length) {
            img.src = formats[formatIndex++];
        } else {
            img.src = './images/fallback.png';
            img.onerror = null; // stop further errors
        }
    }

    img.onerror = tryNext;
    tryNext();
    return img;
}

// Helper: returns the img HTML string that tries sources in order:
// 1. qb-inventory .png  2. qb-inventory .jpg  3. qb-inventory .jpeg
// 4. local .png         5. local .jpg          6. local .jpeg
// 7. local fallback.png
function itemImageHtml(itemName, altText, className) {
    return `<img src="nui://qb-inventory/html/images/${itemName}.png"
                 class="${className}"
                 alt="${altText}"
                 loading="lazy"
                 data-img="${itemName}"
                 onerror="
                    var n=this.dataset.img,s=this.dataset.src||'';
                    if(s===''){this.dataset.src='qi_jpg';this.src='nui://qb-inventory/html/images/'+n+'.jpg';}
                    else if(s==='qi_jpg'){this.dataset.src='qi_jpeg';this.src='nui://qb-inventory/html/images/'+n+'.jpeg';}
                    else if(s==='qi_jpeg'){this.dataset.src='li_png';this.src='./images/'+n+'.png';}
                    else if(s==='li_png'){this.dataset.src='li_jpg';this.src='./images/'+n+'.jpg';}
                    else if(s==='li_jpg'){this.dataset.src='li_jpeg';this.src='./images/'+n+'.jpeg';}
                    else{this.onerror=null;this.src='./images/fallback.png';}
                 ">`;
}

document.addEventListener('DOMContentLoaded', () => {
    // Set up proximity UI click handler
    const proximityUI = document.getElementById('proximity-ui');
    if (proximityUI) {
        proximityUI.addEventListener('click', () => {
            if (proximityUIVisible && currentProximityZone && !shopUIOpen) {
                // Send callback to client to open shop
                fetch(`https://${GetParentResourceName()}/openShopFromProximity`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        zone: currentProximityZone
                    })
                });
            }
        });
    }
    
    window.addEventListener('message', (event) => {
        if (!event.data) {
            return;
        }
        if (event.data.type === 'setItemModels') {
            itemModels = event.data.models || {};
            currentStyle = event.data.uiStyle || currentStyle || Config?.UIStyles['style1'] || {};
            currentTitle = event.data.title || 'Shop Catalog';
            isAdmin = event.data.hasStaffAccess || false;
            currentCategory = event.data.zone || Object.keys(itemModels)[0] || null;
            
            applyUIStyle();
            populateCategories();
            
            const firstCategory = document.querySelector('.category-item');
            if (firstCategory) firstCategory.click();
        } else if (event.data.action === 'openUI') {
            document.querySelectorAll('.modal-overlay').forEach(modal => modal.remove());
            currentStyle = event.data.uiStyle || currentStyle || Config?.UIStyles['style1'] || {};
            currentTitle = event.data.title || 'Shop Catalog';
            isAdmin = event.data.hasStaffAccess || false;
            currentCategory = event.data.categories ? event.data.categories[0] : (event.data.zone || Object.keys(itemModels)[0] || null);
            
            applyUIStyle();
            if (typeof openUI === 'function') {
                openUI();
            } else {
            }
        } else if (event.data.action === 'showProximityUI') {
            if (!shopUIOpen) {
                showProximityUI(event.data.uiStyle, event.data.title, event.data.zoneName);
            }
        } else if (event.data.action === 'hideProximityUI') {
            hideProximityUI();
        }
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            closeUI();
        }
    });

    // Add search input event listener
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('input', () => {
            const searchTerm = searchInput.value.toLowerCase();
            if (currentCategory === 'All') {
                showAllItems(searchTerm);
            } else if (itemModels[currentCategory]) {
                showItemsInCategory(currentCategory, searchTerm);
            } else {
                // Fallback to showing all items if category is invalid
                showAllItems(searchTerm);
            }
        });
    }
});

function showProximityUI(uiStyle, title, zoneName) {
    if (!proximityUIVisible && !shopUIOpen) {
        proximityUIVisible = true;
        currentProximityZone = zoneName;
        
        const proximityUI = document.getElementById('proximity-ui');
        const proximityTitle = document.getElementById('proximity-title');
        
        // Apply dynamic styling to proximity UI
        if (uiStyle) {
            const root = document.documentElement;
            root.style.setProperty('--proximity-bg', uiStyle.secondaryBg || 'rgba(48, 49, 52, 0.7)');
            root.style.setProperty('--proximity-accent', uiStyle.accent || '#8ab4f8');
            root.style.setProperty('--proximity-text-primary', uiStyle.textPrimary || '#e8eaed');
            root.style.setProperty('--proximity-text-secondary', uiStyle.textSecondary || '#9aa0a6');
            root.style.setProperty('--proximity-border', uiStyle.borderColor || 'rgba(95, 99, 104, 0.5)');
            root.style.setProperty('--proximity-blur', uiStyle.blur || '10px');
        }
        
        if (proximityTitle) {
            proximityTitle.textContent = title || 'Shop';
        }
        
        if (proximityUI) {
            proximityUI.style.display = 'flex';
            proximityUI.style.opacity = '0';
            
            // Show proximity UI even when body is hidden
            document.body.style.display = 'block';
            
            // Animate in
            setTimeout(() => {
                proximityUI.style.opacity = '1';
            }, 10);
        }
    }
}

function hideProximityUI() {
    if (proximityUIVisible) {
        proximityUIVisible = false;
        currentProximityZone = null;
        
        const proximityUI = document.getElementById('proximity-ui');
        const dashboard = document.querySelector('.dashboard-container');
        
        if (proximityUI) {
            proximityUI.style.opacity = '0';
            
            setTimeout(() => {
                proximityUI.style.display = 'none';
                
                // Only hide body if dashboard is not visible
                if (!dashboard.classList.contains('visible')) {
                    document.body.style.display = 'none';
                }
            }, 300);
        }
    }
}

function applyUIStyle() {
    const root = document.documentElement;
    root.style.setProperty('--primary-bg', currentStyle.primaryBg || 'rgba(32, 33, 36, 0.8)');
    root.style.setProperty('--secondary-bg', currentStyle.secondaryBg || 'rgba(48, 49, 52, 0.7)');
    root.style.setProperty('--accent', currentStyle.accent || '#8ab4f8');
    root.style.setProperty('--text-primary', currentStyle.textPrimary || '#e8eaed');
    root.style.setProperty('--text-secondary', currentStyle.textSecondary || '#9aa0a6');
    root.style.setProperty('--border-color', currentStyle.borderColor || 'rgba(95, 99, 104, 0.5)');
    root.style.setProperty('--blur', currentStyle.blur || '10px');
    
    const currentCategoryElement = document.getElementById('current-category');
    if (currentCategoryElement) {
        const displayTitle = currentCategory === 'All' ? 'All Categories' : (currentCategory ? currentCategory.charAt(0).toUpperCase() + currentCategory.slice(1) : currentTitle);
        currentCategoryElement.innerHTML = `
            <i class="fas fa-layer-group"></i>
            <span>${displayTitle}</span>
        `;
    } else {
    }
}

function openUI() {
    shopUIOpen = true;
    hideProximityUI();
    
    document.body.style.display = 'block';
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.add('visible');
    void dashboard.offsetHeight;
    applyUIStyle();
}

function closeUI() {
    shopUIOpen = false;
    
    document.querySelectorAll('.modal-overlay').forEach(modal => modal.remove());
    
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
        'normal': 'fa-shopping-basket',
        'liquor': 'fa-wine-bottle',
        'tech': 'fa-mobile-alt',
        'hardware': 'fa-tools',
        'weedshop': 'fa-cannabis',
        'gearshop': 'fa-anchor',
        'leisureshop': 'fa-umbrella-beach',
        'mechanic': 'fa-wrench',
        'prison': 'fa-lock',
        'blackmarket': 'fa-mask',
    };

    const sortedCategories = ['All', ...Object.keys(itemModels).sort((a, b) => a.localeCompare(b))];

    sortedCategories.forEach(category => {
        if (category === 'All' || itemModels[category]) {
            const categoryItem = document.createElement('div');
            categoryItem.className = 'category-item';
            categoryItem.innerHTML = `
                <i class="fas ${categoryIcons[category] || 'fa-shopping-bag'}"></i>
                ${category.charAt(0).toUpperCase() + category.slice(1)}
            `;
            categoryItem.addEventListener('click', () => {
                currentCategory = category;
                document.querySelectorAll('.category-item').forEach(el => el.classList.remove('active'));
                categoryItem.classList.add('active');
                document.getElementById('searchInput').value = '';
                if (category === 'All') {
                    showAllItems();
                } else {
                    showItemsInCategory(category);
                }
            });
            categoryList.appendChild(categoryItem);
        }
    });
}

function updateResultsCount(count) {
    const resultsCountElement = document.getElementById('results-count');
    if (resultsCountElement) {
        resultsCountElement.textContent = `${count} item${count === 1 ? '' : 's'} available`;
    }
}

function showAllItems(searchTerm = '') {
    const itemList = document.getElementById('item-list');
    itemList.style.opacity = '0';
    setTimeout(() => {
        itemList.innerHTML = '';
        const allItems = Object.entries(itemModels).flatMap(([category, items]) =>
            items.map(item => ({
                ...item,
                category: category
            }))
        );
        const filteredItems = allItems.filter(item => 
            item.label.toLowerCase().includes(searchTerm)
        );
        const sortedItems = filteredItems.sort((a, b) => a.label.localeCompare(b.label));

        const currentCategoryElement = document.getElementById('current-category');
        if (currentCategoryElement) {
            currentCategoryElement.innerHTML = `
                <i class="fas fa-layer-group"></i>
                <span>All Categories</span>
            `;
        } else {
        }
        updateResultsCount(sortedItems.length);

        sortedItems.forEach(item => {
            const card = document.createElement('div');
            card.className = 'item-card';
            card.innerHTML = `
                <div class="item-header">
                    <div class="item-name">${item.label}</div>
                    <div class="item-category">${item.category}</div>
                </div>
                <div class="item-image-container">
                    ${itemImageHtml(item.image || item.name, item.label, 'item-image')}
                </div>
                <div class="item-content">
                    <div class="item-info">
                        <p><i class="fas fa-dollar-sign"></i> <strong>Price:</strong> ${item.price.toLocaleString()}</p>
                        <p><i class="fas fa-box"></i> <strong>Stock:</strong> ${item.amount.toLocaleString()}</p>
                        <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${item.category}</p>
                    </div>
                    <div class="item-buttons">
                        <button class="cart-btn" onclick="openCartModal('${item.name}', '${item.label}', ${item.price}, ${item.amount}, '${item.category}', '${item.image || item.name}')">
                            <i class="fas fa-cart-plus"></i> Add to Cart
                        </button>
                        ${isAdmin ? `
                        <button class="buy-btn" onclick="openBuyModal('${item.name}', '${item.label}', ${item.price}, ${item.amount}, '${item.category}', '${item.image || item.name}')">
                            <i class="fas fa-shopping-cart"></i> Buy
                        </button>
                        ` : ''}
                    </div>
                </div>
            `;
            itemList.appendChild(card);
        });
        void itemList.offsetHeight;
        itemList.style.opacity = '1';
        setTimeout(applyUIStyle, 100);
    }, 50);
}

function showItemsInCategory(category, searchTerm = '') {
    if (!itemModels[category]) {
        showAllItems(searchTerm);
        return;
    }
    const itemList = document.getElementById('item-list');
    itemList.style.opacity = '0';
    setTimeout(() => {
        itemList.innerHTML = '';
        const filteredItems = itemModels[category].filter(item =>
            item.label.toLowerCase().includes(searchTerm)
        );
        const sortedItems = filteredItems.map(item => ({
            ...item,
            category: category
        }));

        const currentCategoryElement = document.getElementById('current-category');
        if (currentCategoryElement) {
            currentCategoryElement.innerHTML = `
                <i class="fas fa-tag"></i>
                <span>${category.charAt(0).toUpperCase() + category.slice(1)}</span>
            `;
        } else {
        }
        updateResultsCount(sortedItems.length);

        sortedItems.forEach(item => {
            const card = document.createElement('div');
            card.className = 'item-card';
            card.innerHTML = `
                <div class="item-header">
                    <div class="item-name">${item.label}</div>
                    <div class="item-category">${item.category}</div>
                </div>
                <div class="item-image-container">
                    ${itemImageHtml(item.image || item.name, item.label, 'item-image')}
                </div>
                <div class="item-content">
                    <div class="item-info">
                        <p><i class="fas fa-dollar-sign"></i> <strong>Price:</strong> ${item.price.toLocaleString()}</p>
                        <p><i class="fas fa-box"></i> <strong>Stock:</strong> ${item.amount.toLocaleString()}</p>
                        <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${item.category}</p>
                    </div>
                    <div class="item-buttons">
                        <button class="cart-btn" onclick="openCartModal('${item.name}', '${item.label}', ${item.price}, ${item.amount}, '${item.category}', '${item.image || item.name}')">
                            <i class="fas fa-cart-plus"></i> Add to Cart
                        </button>
                        ${isAdmin ? `
                        <button class="buy-btn" onclick="openBuyModal('${item.name}', '${item.label}', ${item.price}, ${item.amount}, '${item.category}', '${item.image || item.name}')">
                            <i class="fas fa-shopping-cart"></i> Buy
                        </button>
                        ` : ''}
                    </div>
                </div>
            `;
            itemList.appendChild(card);
        });
        void itemList.offsetHeight;
        itemList.style.opacity = '1';
        setTimeout(applyUIStyle, 100);
    }, 50);
}

function openBuyModal(itemName, itemLabel, price, stock, category, itemImage) {
    itemImage = itemImage || itemName;
    if (stock <= 0) {
        openOutOfStockModal(itemLabel);
        return;
    }
    const maxQuantity = Math.min(stock, 25);
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="buy-modal">
            <div class="modal-header">
                <h2><i class="fas fa-shopping-cart"></i> Purchase ${itemLabel}</h2>
                <button class="close-btn" onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-content">
                <div class="modal-image-container">
                    ${itemImageHtml(itemImage, itemLabel, 'modal-item-image')}
                </div>
                <p><i class="fas fa-box"></i> <strong>Stock:</strong> ${stock.toLocaleString()}</p>
                <p><i class="fas fa-dollar-sign"></i> <strong>Price per item:</strong> $${price.toLocaleString()}</p>
                <label for="quantity"><i class="fas fa-list-ol"></i> Quantity:</label>
                <input type="range" id="quantity" min="1" max="${maxQuantity}" value="1">
                <p><i class="fas fa-calculator"></i> <strong>Total Price:</strong> <span id="total-price">$${price.toLocaleString()}</span></p>
                <p><i class="fas fa-list-ol"></i> <strong>Selected Quantity:</strong> <span id="selected-quantity">1</span></p>
                <div class="payment-options">
                    <button onclick="submitPurchase('${itemName}', document.getElementById('quantity').value, 'bank', '${category}')"><i class="fas fa-credit-card"></i> Pay with Bank</button>
                    <button onclick="submitPurchase('${itemName}', document.getElementById('quantity').value, 'cash', '${category}')"><i class="fas fa-money-bill"></i> Pay with Cash</button>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    document.getElementById('quantity').addEventListener('input', (e) => {
        document.getElementById('selected-quantity').textContent = e.target.value;
        updateTotalPrice(e.target.value, price);
    });
    setTimeout(applyUIStyle, 100);
}

function openCartModal(itemName, itemLabel, price, stock, category, itemImage) {
    itemImage = itemImage || itemName;
    if (stock <= 0) {
        openOutOfStockModal(itemLabel);
        return;
    }
    const maxQuantity = Math.min(stock, 25);
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="buy-modal">
            <div class="modal-header">
                <h2><i class="fas fa-cart-plus"></i> Add ${itemLabel} to Cart</h2>
                <button class="close-btn" onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-content">
                <div class="modal-cart-image-container">
                    ${itemImageHtml(itemImage, itemLabel, 'modal-cart-item-image')}
                </div>
                <p><i class="fas fa-box"></i> <strong>Stock:</strong> ${stock.toLocaleString()}</p>
                <p><i class="fas fa-dollar-sign"></i> <strong>Price per item:</strong> $${price.toLocaleString()}</p>
                <label for="cart-quantity"><i class="fas fa-list-ol"></i> Quantity:</label>
                <input type="range" id="cart-quantity" min="1" max="${maxQuantity}" value="1">
                <p><i class="fas fa-calculator"></i> <strong>Total Price:</strong> <span id="cart-total-price">$${price.toLocaleString()}</span></p>
                <p><i class="fas fa-list-ol"></i> <strong>Selected Quantity:</strong> <span id="cart-selected-quantity">1</span></p>
                <div class="payment-options">
                    <button onclick="addToCart('${itemName}', document.getElementById('cart-quantity').value, ${price}, '${itemLabel}', '${category}', '${itemImage}')"><i class="fas fa-cart-plus"></i> Add to Cart</button>
                    <button onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-arrow-left"></i> Back</button>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    document.getElementById('cart-quantity').addEventListener('input', (e) => {
        document.getElementById('cart-selected-quantity').textContent = e.target.value;
        updateCartTotalPrice(e.target.value, price);
    });
    setTimeout(applyUIStyle, 100);
}

function openOutOfStockModal(itemLabel) {
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="buy-modal">
            <div class="modal-header">
                <h2><i class="fas fa-exclamation-circle"></i> Out of Stock</h2>
                <button class="close-btn" onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-content">
                <p><i class="fas fa-box-open"></i> <strong>${itemLabel}</strong> is currently out of stock.</p>
                <div class="payment-options">
                    <button onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-arrow-left"></i> Back</button>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    setTimeout(applyUIStyle, 100);
}

function openCartViewModal() {
    const totalCost = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    let cartItemsHtml = cart.length === 0 ? '<p><i class="fas fa-shopping-cart"></i> Your cart is empty.</p>' : `
        <div class="cart-table-container">
            <table class="cart-table">
                <thead>
                    <tr>
                        <th><i class="fas fa-box-open"></i> Item</th>
                        <th><i class="fas fa-list-ol"></i> Quantity</th>
                        <th><i class="fas fa-dollar-sign"></i> Cost</th>
                    </tr>
                </thead>
                <tbody>
                    ${cart.map(item => `
                        <tr>
                            <td>
                                <div class="cart-item-container">
                                    <div class="cart-image-container">
                                        ${itemImageHtml(item.image || item.item, item.label, 'cart-item-image')}
                                    </div>
                                    <span>${item.label}</span>
                                </div>
                            </td>
                            <td>${item.quantity}</td>
                            <td>$${ (item.price * item.quantity).toLocaleString()}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    modal.innerHTML = `
        <div class="buy-modal">
            <div class="modal-header">
                <h2><i class="fas fa-shopping-cart"></i> Shopping Cart</h2>
                <button class="close-btn" onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-content">
                ${cartItemsHtml}
                <p><i class="fas fa-money-bill-wave"></i> <strong>Total Cost:</strong> $${totalCost.toLocaleString()}</p>
                <div class="payment-options">
                    <button onclick="submitCartPurchase('bank')"><i class="fas fa-credit-card"></i> Pay with Bank</button>
                    <button onclick="submitCartPurchase('cash')"><i class="fas fa-money-bill"></i> Pay with Cash</button>
                    <button onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-times"></i> Cancel</button>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    setTimeout(applyUIStyle, 100);
}

function updateTotalPrice(quantity, price) {
    const totalPrice = quantity * price;
    document.getElementById('total-price').textContent = `$${totalPrice.toLocaleString()}`;
}

function updateCartTotalPrice(quantity, price) {
    const totalPrice = quantity * price;
    document.getElementById('cart-total-price').textContent = `$${totalPrice.toLocaleString()}`;
}

function addToCart(itemName, quantity, price, itemLabel, category, itemImage) {
    itemImage = itemImage || itemName;
    const parsedQuantity = parseInt(quantity);
    let item = itemModels[category]?.find(i => i.name === itemName);

    if (!item) {
        return;
    }

    if (parsedQuantity > 25 || item.amount < parsedQuantity) {
        openOutOfStockModal(itemLabel);
        return;
    }

    cart.push({
        item: itemName,
        image: itemImage,
        label: item.label || itemLabel,
        quantity: parsedQuantity,
        price: price,
        zone: category
    });

    fetch(`https://${GetParentResourceName()}/updateStock`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            item: itemName,
            quantity: parsedQuantity,
            zone: category
        })
    }).then(() => {
        document.querySelector('.modal-overlay').remove();
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            if (currentCategory === 'All') {
                showAllItems(searchInput.value);
            } else {
                showItemsInCategory(currentCategory, searchInput.value);
            }
        }
        setTimeout(applyUIStyle, 100);
    });
}

function submitPurchase(item, quantity, paymentType, category) {
    const parsedQuantity = parseInt(quantity);
    let itemData = itemModels[category]?.find(i => i.name === item);

    if (!itemData || itemData.amount < parsedQuantity || parsedQuantity > 25) {
        openOutOfStockModal(itemData ? itemData.label : item);
        return;
    }

    fetch(`https://${GetParentResourceName()}/submitPurchase`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            item: item,
            quantity: parsedQuantity,
            paymentType: paymentType,
            zone: category
        })
    }).then(() => {
        document.querySelector('.modal-overlay').remove();
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            if (currentCategory === 'All') {
                showAllItems(searchInput.value);
            } else {
                showItemsInCategory(currentCategory, searchInput.value);
            }
        }
        setTimeout(applyUIStyle, 100);
    });
}

function submitCartPurchase(paymentType) {
    const bankPercent = paymentType === 'bank' ? 1 : 0;
    fetch(`https://${GetParentResourceName()}/submitCart`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            cart: cart,
            bankPercent: bankPercent
        })
    }).then(() => {
        cart = [];
        document.querySelector('.modal-overlay').remove();
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            if (currentCategory === 'All') {
                showAllItems(searchInput.value);
            } else {
                showItemsInCategory(currentCategory, searchInput.value);
            }
        }
        setTimeout(applyUIStyle, 100);
    });
}