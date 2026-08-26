let itemModels = {};
let currentCategory = null;
let currentStyle = {};
let currentTitle = 'Item Spawner';
let isAdmin = false;
let cart = [];

// Tries image sources in order:
// 1. qb-inventory .png/jpg/jpeg  2. local .png/jpg/jpeg  3. fallback
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
    window.addEventListener('message', (event) => {
        if (event.data.type === 'setItemModels') {
            itemModels = event.data.models;
            currentStyle = event.data.uiStyle || currentStyle;
            currentTitle = event.data.title || 'Item Spawner';
            isAdmin = event.data.hasStaffAccess || false;
            if (!currentCategory) {
                currentCategory = Object.keys(itemModels)[0] || null;
            }

            applyUIStyle();
            populateCategories();

            const activeCategoryElement = Array.from(document.querySelectorAll('.category-item')).find(el => 
                el.textContent.trim().toLowerCase() === currentCategory.charAt(0).toUpperCase() + currentCategory.slice(1) ||
                (currentCategory === 'All' && el.textContent.trim() === 'All')
            );
            if (activeCategoryElement) activeCategoryElement.click();
        }

        if (event.data.action === "openUI") {
            currentStyle = event.data.uiStyle || currentStyle;
            currentTitle = event.data.title || 'Item Spawner';
            isAdmin = event.data.hasStaffAccess || false;
            if (!currentCategory) {
                currentCategory = Object.keys(itemModels)[0] || null;
            }

            applyUIStyle();
            openUI();

            const activeCategoryElement = Array.from(document.querySelectorAll('.category-item')).find(el => 
                el.textContent.trim().toLowerCase() === currentCategory.charAt(0).toUpperCase() + currentCategory.slice(1) ||
                (currentCategory === 'All' && el.textContent.trim() === 'All')
            );
            if (activeCategoryElement) activeCategoryElement.click();
        }
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            closeUI();
        }
    });

    const searchInput = document.getElementById('searchInput');
    searchInput.addEventListener('input', () => {
        const searchTerm = searchInput.value.toLowerCase();
        if (currentCategory === 'All') {
            showAllItems(searchTerm);
        } else if (itemModels[currentCategory]) {
            showItemsInCategory(currentCategory, searchTerm);
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
}

function openUI() {
    document.body.style.display = 'block';
    const dashboard = document.querySelector('.dashboard-container');
    dashboard.classList.add('visible');
    void dashboard.offsetHeight;
    applyUIStyle();
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
        'normal': 'fa-shopping-basket',
        'liquor': 'fa-wine-bottle',
        'tech': 'fa-mobile-alt',
        'hardware': 'fa-tools',
        'driftndrag': 'fa-car',
        'construction': 'fa-hard-hat',
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
    resultsCountElement.textContent = `${count} item${count === 1 ? '' : 's'} available`;
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

        document.getElementById('current-category').innerHTML = `
            <i class="fas fa-layer-group"></i>
            <span>${currentTitle}</span>
        `;
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
                        <p><i class="fas fa-box"></i> <strong>Stock:</strong> ${item.amount.toLocaleString()}</p>
                        <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${item.category}</p>
                    </div>
                    <div class="item-buttons">
                        <button class="cart-btn" onclick="openCartModal('${item.name}', '${item.label}', ${item.amount}, '${item.category}', '${item.image || item.name}')">
                            <i class="fas fa-cart-plus"></i> Add to Cart
                        </button>
                    </div>
                </div>
            `;
            itemList.appendChild(card);
        });
        itemList.style.opacity = '1';
    }, 300);
}

function showItemsInCategory(category, searchTerm = '') {
    const itemList = document.getElementById('item-list');
    itemList.style.opacity = '0';
    setTimeout(() => {
        itemList.innerHTML = '';
        const items = itemModels[category] || [];
        const filteredItems = items.filter(item => 
            item.label.toLowerCase().includes(searchTerm)
        );
        const sortedItems = filteredItems.sort((a, b) => a.label.localeCompare(b.label));

        document.getElementById('current-category').innerHTML = `
            <i class="fas fa-layer-group"></i>
            <span>${category.charAt(0).toUpperCase() + category.slice(1)}</span>
        `;
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
                        <p><i class="fas fa-box"></i> <strong>Stock:</strong> ${item.amount.toLocaleString()}</p>
                        <p><i class="fas fa-tag"></i> <strong>Category:</strong> ${item.category}</p>
                    </div>
                    <div class="item-buttons">
                        <button class="cart-btn" onclick="openCartModal('${item.name}', '${item.label}', ${item.amount}, '${item.category}', '${item.image || item.name}')">
                            <i class="fas fa-cart-plus"></i> Add to Cart
                        </button>
                    </div>
                </div>
            `;
            itemList.appendChild(card);
        });
        itemList.style.opacity = '1';
    }, 300);
}

/* The rest of the functions (modals, cart handling, etc.) remain unchanged */
function openCartModal(itemName, itemLabel, maxStock, category, itemImage) {
    itemImage = itemImage || itemName;
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.dataset.category = category;
    modal.innerHTML = `
        <div class="buy-modal">
            <div class="modal-header">
                <h2><i class="fas fa-shopping-cart"></i> ${itemLabel}</h2>
                <button class="close-btn" onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-arrow-left"></i> Back</button>
            </div>
            <div class="modal-content">
                <div class="modal-image-container">
                    ${itemImageHtml(itemImage, itemLabel, 'modal-item-image')}
                </div>
                <label for="quantity">Quantity:</label>
                <input type="range" id="quantity" min="1" max="${Math.min(maxStock, 25)}" value="1" oninput="this.nextElementSibling.value = this.value">
                <output>1</output>
                <p><i class="fas fa-box"></i> <strong>Stock:</strong> ${maxStock.toLocaleString()}</p>
                <div class="payment-options">
                    <button onclick="addToCart('${itemName}', document.getElementById('quantity').value, '${itemLabel}', '${category}', '${itemImage}')"><i class="fas fa-cart-plus"></i> Add to Cart</button>
                    <button onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-arrow-left"></i> Back</button>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    applyUIStyle();
}

/* Removed openSpawnModal entirely since it's no longer needed */

function openOutOfStockModal(itemLabel) {
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="buy-modal">
            <div class="modal-header">
                <h2><i class="fas fa-exclamation-triangle"></i> Out of Stock</h2>
                <button class="close-btn" onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-arrow-left"></i> Back</button>
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
    applyUIStyle();
}

function openCartViewModal() {
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.dataset.category = currentCategory;
    let cartItemsHtml = cart.length === 0 ? '<p><i class="fas fa-shopping-cart"></i> Your cart is empty.</p>' : `
        <div class="cart-table-container">
            <table class="cart-table">
                <thead>
                    <tr>
                        <th><i class="fas fa-box-open"></i> Item</th>
                        <th><i class="fas fa-list-ol"></i> Quantity</th>
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
                <button class="close-btn" onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-arrow-left"></i> Back</button>
            </div>
            <div class="modal-content">
                ${cartItemsHtml}
                <div class="payment-options">
                    <button onclick="submitCartSpawn()"><i class="fas fa-magic"></i> Spawn All</button>
                    <button onclick="this.closest('.modal-overlay').remove()"><i class="fas fa-arrow-left"></i> Cancel</button>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    applyUIStyle();
}

function addToCart(itemName, quantity, itemLabel, category, itemImage) {
    itemImage = itemImage || itemName;
    const parsedQuantity = parseInt(quantity);
    let item = itemModels[category]?.find(i => i.name === itemName);

    if (!item) {
        console.error(`Item ${itemName} not found in category ${category}.`);
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
        zone: category
    });

    fetch(`https://${GetParentResourceName()}/updateStock`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            item: itemName,
            quantity: parsedQuantity
        })
    }).then(() => {
        document.querySelector('.modal-overlay').remove();
        const searchInput = document.getElementById('searchInput');
        if (currentCategory !== 'All') {
            currentCategory = category;
        }
        document.querySelectorAll('.category-item').forEach(el => el.classList.remove('active'));
        const categoryItem = Array.from(document.querySelectorAll('.category-item')).find(el => 
            el.textContent.trim().toLowerCase() === currentCategory.charAt(0).toUpperCase() + currentCategory.slice(1) ||
            (currentCategory === 'All' && el.textContent.trim() === 'All')
        );
        if (categoryItem) categoryItem.classList.add('active');
        if (currentCategory === 'All') {
            showAllItems(searchInput.value);
        } else {
            showItemsInCategory(currentCategory, searchInput.value);
        }
        applyUIStyle();
    });
}

/* Removed submitSpawn function since it's no longer used */

function submitCartSpawn() {
    for (const cartItem of cart) {
        let itemData = itemModels[cartItem.zone]?.find(i => i.name === cartItem.item);
        if (!itemData || itemData.amount < cartItem.quantity || cartItem.quantity > 25) {
            openOutOfStockModal(cartItem.label);
            return;
        }
    }

    fetch(`https://${GetParentResourceName()}/submitCart`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            cart: cart
        })
    }).then(() => {
        const selectedCategory = currentCategory;
        cart = [];
        document.querySelector('.modal-overlay').remove();
        const searchInput = document.getElementById('searchInput');
        document.querySelectorAll('.category-item').forEach(el => el.classList.remove('active'));
        const categoryItem = Array.from(document.querySelectorAll('.category-item')).find(el => 
            el.textContent.trim().toLowerCase() === selectedCategory.charAt(0).toUpperCase() + selectedCategory.slice(1) ||
            (selectedCategory === 'All' && el.textContent.trim() === 'All')
        );
        if (categoryItem) categoryItem.classList.add('active');
        if (selectedCategory === 'All') {
            showAllItems(searchInput.value);
        } else {
            showItemsInCategory(selectedCategory, searchInput.value);
        }
        applyUIStyle();
    });
}