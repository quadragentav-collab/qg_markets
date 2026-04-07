let adminPanelOpen = false;
let adminMarketData = null;
let adminPlayerData = null;
let marketManagementOpen = false;
let currentManagedMarket = null;

// Listen for admin panel messages
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'openAdminPanel':
            adminMarketData = data.marketData;
            openAdminPanel();
            break;
        case 'closeAdminPanel':
            closeAdminPanel();
            break;
        case 'openMarketManagement':
            openMarketManagement(data.marketId, data.locationIndex);
            break;
        case 'closeMarketManagement':
            closeMarketManagement();
            break;
    }
});

function openAdminPanel() {
    console.log('[Admin Panel] Opening admin panel...');
    adminPanelOpen = true;
    document.getElementById('admin-panel-container').classList.remove('hidden');

    // Populate market locations
    if (adminMarketData) {
        populateAdminMarkets();
    }

    setupAdminEventListeners();
    console.log('[Admin Panel] Admin panel opened');
}

function closeAdminPanel() {
    console.log('[Admin Panel] Closing admin panel...');
    adminPanelOpen = false;
    document.getElementById('admin-panel-container').classList.add('hidden');
    console.log('[Admin Panel] Admin panel closed');
}

function populateAdminMarkets() {
    const marketsGrid = document.getElementById('admin-markets-grid');
    marketsGrid.innerHTML = '';

    const supermarkets = adminMarketData.markets.supermarket || {};

    // Sort by location index
    const sortedLocations = Object.entries(supermarkets).sort((a, b) => {
        return parseInt(a[0]) - parseInt(b[0]);
    });

    sortedLocations.forEach(([locationIndex, location]) => {
        const marketCard = createAdminMarketCard(location);
        marketsGrid.appendChild(marketCard);
    });
}

function createAdminMarketCard(location) {
    const card = document.createElement('div');
    card.className = 'admin-market-card';

    const isOwned = location.owner !== null && location.owner !== undefined && location.owner !== false;
    const isOwnedByPlayer = isOwned && location.owner === adminMarketData.playerCitizenId;

    if (isOwned) {
        card.classList.add('owned');
        if (isOwnedByPlayer) {
            card.classList.add('owned-by-player');
        }
    }

    // Header
    const header = document.createElement('div');
    header.className = 'admin-market-header';
    header.innerHTML = `
        <h4>Market #${location.locationIndex}</h4>
        <span class="admin-market-status ${isOwned ? 'status-owned' : 'status-available'}">
            ${isOwned ? 'Sahipli' : 'Satılık'}
        </span>
    `;

    // Price
    const price = document.createElement('div');
    price.className = 'admin-market-price';
    price.textContent = `$${location.price.toLocaleString()}`;

    // Actions
    const actions = document.createElement('div');
    actions.className = 'admin-market-actions';

    if (isOwnedByPlayer) {
        // Manage button for owned markets
        const manageBtn = document.createElement('button');
        manageBtn.className = 'admin-btn admin-btn-primary';
        manageBtn.textContent = 'Marketi Yönet';
        manageBtn.onclick = () => openOwnedMarket(location.marketId, location.locationIndex);
        actions.appendChild(manageBtn);

        // Sell button for owned markets
        const sellBtn = document.createElement('button');
        sellBtn.className = 'admin-btn admin-btn-danger';
        sellBtn.textContent = 'Marketi Sat (50% iade)';
        sellBtn.onclick = () => sellMarket(location.marketId, location.locationIndex);
        actions.appendChild(sellBtn);
    } else if (!isOwned) {
        // Purchase buttons for available markets
        const cashBtn = document.createElement('button');
        cashBtn.className = 'admin-btn admin-btn-cash';
        cashBtn.textContent = 'Nakit ile Al';
        cashBtn.onclick = () => purchaseMarket(location.marketId, location.locationIndex, 'cash');

        const bankBtn = document.createElement('button');
        bankBtn.className = 'admin-btn admin-btn-bank';
        bankBtn.textContent = 'Banka ile Al';
        bankBtn.onclick = () => purchaseMarket(location.marketId, location.locationIndex, 'bank');

        actions.appendChild(cashBtn);
        actions.appendChild(bankBtn);
    } else {
        // Show owned by someone else
        const ownedText = document.createElement('p');
        ownedText.className = 'admin-owned-text';
        ownedText.textContent = 'Başkasına ait';
        actions.appendChild(ownedText);
    }

    card.appendChild(header);
    card.appendChild(price);
    card.appendChild(actions);

    return card;
}

function purchaseMarket(marketId, locationIndex, paymentMethod) {
    fetch(`https://${GetParentResourceName()}/purchaseMarket`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            marketId: marketId,
            locationIndex: locationIndex,
            paymentMethod: paymentMethod
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success && data.marketData) {
            // Update local data
            adminMarketData = data.marketData;
            populateAdminMarkets();
        }
    })
    .catch(error => {
        console.error('Purchase error:', error);
    });
}

function sellMarket(marketId, locationIndex) {
    fetch(`https://${GetParentResourceName()}/sellMarket`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            marketId: marketId,
            locationIndex: locationIndex
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success && data.marketData) {
            // Update local data
            adminMarketData = data.marketData;
            populateAdminMarkets();
        }
    })
    .catch(error => {
        console.error('Sell error:', error);
    });
}

function formatDate(timestamp) {
    if (!timestamp) return '-';

    const date = new Date(timestamp * 1000);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');

    return `${day}/${month}/${year} ${hours}:${minutes}`;
}

function setupAdminEventListeners() {
    const closeBtn = document.getElementById('admin-close-btn');
    if (closeBtn) {
        closeBtn.onclick = () => {
            fetch(`https://${GetParentResourceName()}/closeAdminPanel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        };
    }

    document.addEventListener('keyup', function (event) {
        if (event.key === 'Escape' && adminPanelOpen) {
            fetch(`https://${GetParentResourceName()}/closeAdminPanel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });
}

function openOwnedMarket(marketId, locationIndex) {
    fetch(`https://${GetParentResourceName()}/openOwnedMarket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ marketId, locationIndex })
    });
    closeAdminPanel();
}

function openMarketManagement(marketId, locationIndex) {
    console.log('[Admin Panel] Opening market management...');

    // Close admin panel properly
    adminPanelOpen = false;
    document.getElementById('admin-panel-container').classList.add('hidden');

    marketManagementOpen = true;
    currentManagedMarket = { marketId, locationIndex };

    document.getElementById('market-management-container').classList.remove('hidden');

    // Update header
    document.getElementById('mgmt-location-title').textContent = `Market #${locationIndex}`;

    setupMarketManagementListeners();
    console.log('[Admin Panel] Market management opened');
}

function closeMarketManagement() {
    console.log('[Admin Panel] Closing market management...');
    marketManagementOpen = false;
    currentManagedMarket = null;
    document.getElementById('market-management-container').classList.add('hidden');
    console.log('[Admin Panel] Market management closed');
}

function setupMarketManagementListeners() {
    const tabs = document.querySelectorAll('.mgmt-tab');
    const sections = document.querySelectorAll('.mgmt-section');

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const targetSection = tab.dataset.section;

            if (targetSection === 'exit') {
                return;
            }

            tabs.forEach(t => t.classList.remove('active'));
            sections.forEach(s => s.classList.remove('active'));

            tab.classList.add('active');
            document.getElementById(`mgmt-${targetSection}`).classList.add('active');

            if (targetSection === 'stock') {
                loadCurrentStock();
            } else if (targetSection === 'sales') {
                loadMarketSales();
            } else if (targetSection === 'market') {
                loadMarketInfo();
            } else if (targetSection === 'employees') {
                loadMarketEmployees();
            }
        });
    });

    const exitBtn = document.getElementById('mgmt-exit-btn');
    if (exitBtn) {
        exitBtn.onclick = () => {
            fetch(`https://${GetParentResourceName()}/closeMarketManagement`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        };
    }

    const refreshStockBtn = document.getElementById('refresh-stock-btn');
    if (refreshStockBtn) {
        refreshStockBtn.onclick = () => loadCurrentStock();
    }

    const loadInventoryBtn = document.getElementById('load-inventory-btn');
    if (loadInventoryBtn) {
        loadInventoryBtn.onclick = () => loadPlayerInventory();
    }

    loadPlayerInventory();
    loadMarketInfo();

    const addEmployeeBtn = document.getElementById('add-employee-btn');
    if (addEmployeeBtn) {
        addEmployeeBtn.onclick = () => showAddEmployeeModal();
    }

    const loadSalesBtn = document.getElementById('load-sales-btn');
    if (loadSalesBtn) {
        loadSalesBtn.onclick = () => loadMarketSales();
    }

    const collectRevenueBtn = document.getElementById('collect-revenue-btn');
    if (collectRevenueBtn) {
        collectRevenueBtn.onclick = () => collectRevenue();
    }

    document.addEventListener('keyup', function(event) {
        if (event.key === 'Escape' && marketManagementOpen) {
            fetch(`https://${GetParentResourceName()}/closeMarketManagement`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });
}

function loadCurrentStock() {
    if (!currentManagedMarket) return;

    fetch(`https://${GetParentResourceName()}/getMarketStock`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex
        })
    })
    .then(response => response.json())
    .then(data => {
        displayCurrentStock(data.stock);
    })
    .catch(error => {
        console.error('Error loading stock:', error);
    });
}

function displayCurrentStock(stock) {
    const stockList = document.getElementById('current-stock-list');
    stockList.innerHTML = '';

    if (!stock || Object.keys(stock).length === 0) {
        stockList.innerHTML = '<p class="mgmt-empty-state">Henüz stok bulunmuyor</p>';
        return;
    }

    for (const [itemName, data] of Object.entries(stock)) {
        const quantity = typeof data === 'object' ? (data.quantity || 0) : data;
        const price = typeof data === 'object' ? (data.price || 10) : 10;

        if (quantity <= 0) continue;

        const stockItem = document.createElement('div');
        stockItem.className = 'mgmt-stock-item-card';

        const topRow = document.createElement('div');
        topRow.className = 'stock-item-top';

        const nameSpan = document.createElement('span');
        nameSpan.className = 'stock-item-name';
        nameSpan.textContent = itemName;

        const quantitySpan = document.createElement('span');
        quantitySpan.className = 'stock-item-quantity';
        quantitySpan.textContent = `${quantity} adet`;

        topRow.appendChild(nameSpan);
        topRow.appendChild(quantitySpan);

        const priceRow = document.createElement('div');
        priceRow.className = 'stock-item-price-row';

        const priceLabel = document.createElement('span');
        priceLabel.className = 'stock-price-label';
        priceLabel.textContent = 'Fiyat:';

        const priceInput = document.createElement('input');
        priceInput.type = 'number';
        priceInput.className = 'stock-price-input';
        priceInput.value = price;
        priceInput.min = '0';
        priceInput.step = '0.01';

        const updateBtn = document.createElement('button');
        updateBtn.className = 'stock-update-btn';
        updateBtn.textContent = 'Güncelle';
        updateBtn.onclick = () => {
            const newPrice = parseFloat(priceInput.value);
            if (isNaN(newPrice) || newPrice < 0) {
                showNotification('Geçerli bir fiyat girin!', 'error');
                return;
            }
            updateItemPrice(itemName, newPrice);
        };

        const removeBtn = document.createElement('button');
        removeBtn.className = 'stock-remove-btn';
        removeBtn.textContent = 'Stok Çıkar';
        removeBtn.onclick = () => showRemoveStockModal(itemName, quantity);

        priceRow.appendChild(priceLabel);
        priceRow.appendChild(priceInput);
        priceRow.appendChild(updateBtn);

        stockItem.appendChild(topRow);
        stockItem.appendChild(priceRow);
        stockItem.appendChild(removeBtn);

        stockList.appendChild(stockItem);
    }
}

function updateItemPrice(itemName, newPrice) {
    fetch(`https://${GetParentResourceName()}/updateItemPrice`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex,
            itemName: itemName,
            price: newPrice
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Fiyat güncellendi!', 'success');
            loadCurrentStock();
        } else {
            showNotification('Fiyat güncellenemedi!', 'error');
        }
    })
    .catch(error => {
        console.error('Error updating price:', error);
        showNotification('Bir hata oluştu!', 'error');
    });
}

function loadPlayerInventory() {
    fetch(`https://${GetParentResourceName()}/getPlayerInventory`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            displayPlayerInventory(data.inventory);
        }
    })
    .catch(error => {
        console.error('Error loading inventory:', error);
    });
}

function displayPlayerInventory(inventory) {
    const inventoryGrid = document.getElementById('inventory-items');
    inventoryGrid.innerHTML = '';

    if (!inventory || inventory.length === 0) {
        inventoryGrid.innerHTML = '<p class="mgmt-empty-state">Envanteriniz boş</p>';
        inventoryGrid.style.display = 'flex';
        return;
    }

    inventoryGrid.style.display = 'grid';

    inventory.forEach(item => {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'mgmt-inventory-item';
        itemDiv.onclick = () => showAddStockModal(item.name, item.label, item.count);

        const img = document.createElement('img');
        img.src = `nui://ox_inventory/web/images/${item.name}.png`;
        img.alt = item.label;
        img.onerror = function() {
            this.src = `nui://qb-inventory/html/images/${item.name}.png`;
            this.onerror = function() {
                this.src = 'https://via.placeholder.com/50x50/666/fff?text=?';
            };
        };

        const nameDiv = document.createElement('div');
        nameDiv.className = 'mgmt-inventory-item-name';
        nameDiv.textContent = item.label;

        const countDiv = document.createElement('div');
        countDiv.className = 'mgmt-inventory-item-count';
        countDiv.textContent = `x${item.count}`;

        itemDiv.appendChild(img);
        itemDiv.appendChild(nameDiv);
        itemDiv.appendChild(countDiv);

        inventoryGrid.appendChild(itemDiv);
    });
}

function showAddStockModal(itemName, itemLabel, maxCount) {
    const existingModal = document.querySelector('.stock-modal');
    if (existingModal) {
        existingModal.remove();
    }

    const modal = document.createElement('div');
    modal.className = 'stock-modal';

    const safeItemName = itemName.replace(/'/g, "\\'");

    modal.innerHTML = `
        <div class="stock-modal-content">
            <div class="stock-modal-header stock-modal-header-add">
                <div class="modal-header-content">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #4CAF50;">
                        <rect x="3" y="3" width="7" height="7"></rect>
                        <rect x="14" y="3" width="7" height="7"></rect>
                        <rect x="14" y="14" width="7" height="7"></rect>
                        <rect x="3" y="14" width="7" height="7"></rect>
                    </svg>
                    <h3>Stok Ekle</h3>
                </div>
                <button class="modal-close-btn modal-close-btn-green" onclick="closeStockModal()">&times;</button>
            </div>
            <div class="stock-modal-body">
                <div class="modal-item-info modal-item-info-add">
                    <div class="modal-info-label">Ürün</div>
                    <div class="modal-item-name">${itemLabel}</div>
                </div>
                <div class="modal-item-stock-info">
                    <div class="stock-badge stock-badge-inventory">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                            <circle cx="12" cy="7" r="4"></circle>
                        </svg>
                        <span>Envanterinizde: <strong>${maxCount}</strong> adet</span>
                    </div>
                </div>
                <div class="modal-quantity-input">
                    <label>Eklenecek Miktar</label>
                    <input type="number" id="modal-add-quantity-input" min="1" max="${maxCount}" value="1" placeholder="Miktar girin..." />
                </div>
            </div>
            <div class="stock-modal-actions">
                <button class="modal-btn modal-btn-cancel" onclick="closeStockModal()">İptal</button>
                <button class="modal-btn modal-btn-confirm" id="confirm-add-btn">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="12" y1="5" x2="12" y2="19"></line>
                        <line x1="5" y1="12" x2="19" y2="12"></line>
                    </svg>
                    Stoğa Ekle
                </button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);

    document.getElementById('confirm-add-btn').addEventListener('click', () => {
        confirmAddStock(itemName, maxCount);
    });

    document.getElementById('modal-add-quantity-input').focus();
}

function confirmAddStock(itemName, maxCount) {
    const quantityInput = document.getElementById('modal-add-quantity-input');
    const qty = parseInt(quantityInput.value);

    if (isNaN(qty) || qty <= 0 || qty > maxCount) {
        showNotification('Geçerli bir miktar girin!', 'error');
        return;
    }

    fetch(`https://${GetParentResourceName()}/addStockToMarket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex,
            itemName: itemName,
            quantity: qty
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Stok eklendi!', 'success');
            loadCurrentStock();
            loadPlayerInventory();
            document.querySelector('.stock-modal').remove();
        } else {
            showNotification('Stok eklenemedi!', 'error');
        }
    })
    .catch(error => {
        console.error('Error adding stock:', error);
        showNotification('Bir hata oluştu!', 'error');
    });
}

function showRemoveStockModal(itemName, currentStock) {
    const existingModal = document.querySelector('.stock-modal');
    if (existingModal) {
        existingModal.remove();
    }

    const modal = document.createElement('div');
    modal.className = 'stock-modal';

    const safeItemName = itemName.replace(/'/g, "\\'");

    modal.innerHTML = `
        <div class="stock-modal-content">
            <div class="stock-modal-header">
                <div class="modal-header-content">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #f44336;">
                        <polyline points="3 6 5 6 21 6"></polyline>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                        <line x1="10" y1="11" x2="10" y2="17"></line>
                        <line x1="14" y1="11" x2="14" y2="17"></line>
                    </svg>
                    <h3>Stok Çıkar</h3>
                </div>
                <button class="modal-close-btn" onclick="closeStockModal()">&times;</button>
            </div>
            <div class="stock-modal-body">
                <div class="modal-item-info">
                    <div class="modal-info-label">Ürün</div>
                    <div class="modal-item-name">${itemName}</div>
                </div>
                <div class="modal-item-stock-info">
                    <div class="stock-badge">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="3" y="3" width="7" height="7"></rect>
                            <rect x="14" y="3" width="7" height="7"></rect>
                            <rect x="14" y="14" width="7" height="7"></rect>
                            <rect x="3" y="14" width="7" height="7"></rect>
                        </svg>
                        <span>Mevcut Stok: <strong>${currentStock}</strong> adet</span>
                    </div>
                </div>
                <div class="modal-quantity-input">
                    <label>Çıkarılacak Miktar</label>
                    <input type="number" id="modal-remove-quantity-input" min="1" max="${currentStock}" value="1" placeholder="Miktar girin..." />
                </div>
            </div>
            <div class="stock-modal-actions">
                <button class="modal-btn modal-btn-cancel" onclick="closeStockModal()">İptal</button>
                <button class="modal-btn modal-btn-confirm modal-btn-danger" id="confirm-remove-btn">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="3 6 5 6 21 6"></polyline>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                    </svg>
                    Stoktan Çıkar
                </button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);

    document.getElementById('confirm-remove-btn').addEventListener('click', () => {
        confirmRemoveStock(itemName, currentStock);
    });

    document.getElementById('modal-remove-quantity-input').focus();
}

function confirmRemoveStock(itemName, maxCount) {
    const quantityInput = document.getElementById('modal-remove-quantity-input');
    const qty = parseInt(quantityInput.value);

    if (isNaN(qty) || qty <= 0 || qty > maxCount) {
        showNotification('Geçerli bir miktar girin!', 'error');
        return;
    }

    fetch(`https://${GetParentResourceName()}/removeStockFromMarket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex,
            itemName: itemName,
            quantity: qty
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Stok çıkarıldı!', 'success');
            loadCurrentStock();
            loadPlayerInventory();
            document.querySelector('.stock-modal').remove();
        } else {
            showNotification('Stok çıkarılamadı!', 'error');
        }
    })
    .catch(error => {
        console.error('Error removing stock:', error);
        showNotification('Bir hata oluştu!', 'error');
    });
}

function showNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `stock-notification ${type}`;
    notification.textContent = message;
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.classList.add('show');
    }, 10);

    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

function closeStockModal() {
    const modal = document.querySelector('.stock-modal');
    if (modal) {
        modal.remove();
    }
}

function loadMarketSales() {
    if (!currentManagedMarket) return;

    fetch(`https://${GetParentResourceName()}/getMarketSales`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            displayMarketSales(data.salesData);
        }
    })
    .catch(error => {
        console.error('Error loading sales:', error);
    });
}

function displayMarketSales(salesData) {
    const totalRevenue = salesData.totalRevenue || 0;
    const salesHistory = salesData.salesHistory || [];
    const lastCollected = salesData.lastCollected;

    document.getElementById('total-revenue').textContent = `$${totalRevenue.toLocaleString()}`;

    // Satış geçmişini göster
    displaySalesHistory(salesHistory);

    const collectBtn = document.getElementById('collect-revenue-btn');
    collectBtn.disabled = totalRevenue <= 0;
}

function displaySalesHistory(salesHistory) {
    const salesListContainer = document.querySelector('#mgmt-sales .mgmt-content-area');

    // Mevcut satış listesini kaldır
    let salesList = document.getElementById('sales-history-list');
    if (salesList) {
        salesList.remove();
    }

    // Yeni liste oluştur
    if (salesHistory && salesHistory.length > 0) {
        salesList = document.createElement('div');
        salesList.id = 'sales-history-list';
        salesList.className = 'mgmt-sales-list';
        salesList.style.cssText = 'margin-top: 30px; max-height: 400px; overflow-y: auto;';

        const header = document.createElement('h4');
        header.textContent = 'Son Satışlar';
        header.style.cssText = 'font-size: 16px; font-weight: 600; color: #4CAF50; margin-bottom: 15px; font-family: Poppins, sans-serif;';
        salesList.appendChild(header);

        salesHistory.slice().reverse().forEach((sale, index) => {
            const saleCard = document.createElement('div');
            saleCard.className = 'sales-history-card';
            saleCard.style.cssText = 'background: rgba(50, 50, 60, 0.6); border: 1px solid rgba(76, 175, 80, 0.2); border-radius: 8px; padding: 15px; margin-bottom: 10px;';

            const items = sale.items.map(item => `${item.quantity}x ${item.label}`).join(', ');
            const paymentMethod = sale.paymentMethod === 'cash' ? 'Nakit' : 'Banka Kartı';
            const timestamp = new Date(sale.timestamp * 1000);
            const timeStr = formatDate(sale.timestamp);

            saleCard.innerHTML = `
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <span style="font-size: 14px; font-weight: 600; color: #4CAF50;">Satış #${salesHistory.length - index}</span>
                    <span style="font-size: 12px; color: rgba(255, 255, 255, 0.7);">${timeStr}</span>
                </div>
                <div style="font-size: 13px; color: rgba(255, 255, 255, 0.9); margin-bottom: 8px; line-height: 1.6;">
                    <div style="margin-bottom: 5px;"><strong>Ürünler:</strong> ${items}</div>
                    <div><strong>Ödeme:</strong> ${paymentMethod}</div>
                </div>
                <div style="font-size: 14px; font-weight: 600; color: #4CAF50; text-align: right;">$${sale.total.toFixed(2)}</div>
            `;

            salesList.appendChild(saleCard);
        });

        // Scroll bar styling
        salesList.style.cssText += `
            ::-webkit-scrollbar { width: 6px; }
            ::-webkit-scrollbar-track { background: rgba(20, 20, 20, 0.3); }
            ::-webkit-scrollbar-thumb { background: rgba(76, 175, 80, 0.5); border-radius: 3px; }
        `;

        salesListContainer.appendChild(salesList);
    }
}

function collectRevenue() {
    if (!currentManagedMarket) return;

    const collectBtn = document.getElementById('collect-revenue-btn');
    const originalText = collectBtn.textContent;
    collectBtn.disabled = true;
    collectBtn.textContent = 'Toplanıyor...';

    fetch(`https://${GetParentResourceName()}/collectRevenue`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification(`$${data.amount.toLocaleString()} gelir toplandı!`, 'success');
            displayMarketSales(data.salesData);
        } else {
            showNotification('Gelir toplanamadı!', 'error');
        }
        collectBtn.textContent = originalText;
    })
    .catch(error => {
        console.error('Error collecting revenue:', error);
        showNotification('Bir hata oluştu!', 'error');
        collectBtn.disabled = false;
        collectBtn.textContent = originalText;
    });
}

function loadMarketInfo() {
    if (!currentManagedMarket) return;

    fetch(`https://${GetParentResourceName()}/getMarketSales`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            displayMarketInfo(data.salesData);
        }
    })
    .catch(error => {
        console.error('Error loading market info:', error);
    });
}

function displayMarketInfo(salesData) {
    const totalRevenue = salesData.totalRevenue || 0;
    const salesHistory = salesData.salesHistory || [];
    const lastCollected = salesData.lastCollected;

    document.getElementById('market-total-revenue').textContent = `$${totalRevenue.toLocaleString()}`;
    document.getElementById('market-total-sales').textContent = salesHistory.length;

    if (lastCollected && lastCollected !== false) {
        document.getElementById('market-last-collected').textContent = formatDate(lastCollected);
    } else {
        document.getElementById('market-last-collected').textContent = 'Hiçbir zaman';
    }
}

function loadMarketEmployees() {
    if (!currentManagedMarket) return;

    fetch(`https://${GetParentResourceName()}/getMarketEmployees`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            displayMarketEmployees(data.employees);
        }
    })
    .catch(error => {
        console.error('Error loading employees:', error);
    });
}

function displayMarketEmployees(employees) {
    const employeeList = document.getElementById('employee-list');
    employeeList.innerHTML = '';

    if (!employees || Object.keys(employees).length === 0) {
        employeeList.innerHTML = '<p class="mgmt-empty-state">Henüz çalışan eklenmedi</p>';
        return;
    }

    for (const [citizenId, employee] of Object.entries(employees)) {
        const employeeCard = document.createElement('div');
        employeeCard.className = 'employee-card';

        employeeCard.innerHTML = `
            <div class="employee-info">
                <div class="employee-name">${employee.name}</div>
                <div class="employee-id">ID: ${employee.citizenId}</div>
                <div class="employee-date">Ekleme: ${formatDate(employee.addedAt)}</div>
            </div>
            <button class="employee-remove-btn" onclick="removeEmployee('${citizenId}')">
                Çıkar
            </button>
        `;

        employeeList.appendChild(employeeCard);
    }
}

function showAddEmployeeModal() {
    const existingModal = document.querySelector('.employee-modal');
    if (existingModal) {
        existingModal.remove();
    }

    fetch(`https://${GetParentResourceName()}/getNearbyPlayers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (!data.success || !data.players || data.players.length === 0) {
            showNotification('Yakında kimse yok!', 'error');
            return;
        }

        const modal = document.createElement('div');
        modal.className = 'employee-modal';

        const playerOptions = data.players.map(player =>
            `<div class="nearby-player-item" onclick="selectNearbyPlayer('${player.serverId}', '${player.name.replace(/'/g, "\\'")}')">
                <div class="player-info">
                    <div class="player-name">${player.name}</div>
                    <div class="player-distance">${player.distance.toFixed(1)}m uzakta</div>
                </div>
            </div>`
        ).join('');

        modal.innerHTML = `
            <div class="employee-modal-content">
                <div class="employee-modal-header">
                    <h3>Çalışan Ekle - Yakındaki Oyuncular</h3>
                    <button class="modal-close-btn" onclick="closeEmployeeModal()">&times;</button>
                </div>
                <div class="employee-modal-body">
                    <div class="nearby-players-list">
                        ${playerOptions}
                    </div>
                </div>
                <div class="employee-modal-actions">
                    <button class="modal-btn modal-btn-cancel" onclick="closeEmployeeModal()">İptal</button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
    })
    .catch(error => {
        console.error('Error getting nearby players:', error);
        showNotification('Bir hata oluştu!', 'error');
    });
}

function selectNearbyPlayer(serverId, playerName) {
    fetch(`https://${GetParentResourceName()}/addEmployeeByServerId`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex,
            targetServerId: parseInt(serverId)
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification(`${playerName} çalışan olarak eklendi!`, 'success');
            loadMarketEmployees();
            document.querySelector('.employee-modal').remove();
        } else {
            showNotification(data.message || 'Çalışan eklenemedi!', 'error');
        }
    })
    .catch(error => {
        console.error('Error adding employee:', error);
        showNotification('Bir hata oluştu!', 'error');
    });
}


function removeEmployee(citizenId) {
    if (!confirm('Bu çalışanı çıkarmak istediğinizden emin misiniz?')) {
        return;
    }

    fetch(`https://${GetParentResourceName()}/removeEmployee`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: currentManagedMarket.marketId,
            locationIndex: currentManagedMarket.locationIndex,
            targetCitizenId: citizenId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Çalışan çıkarıldı!', 'success');
            loadMarketEmployees();
        } else {
            showNotification('Çalışan çıkarılamadı!', 'error');
        }
    })
    .catch(error => {
        console.error('Error removing employee:', error);
        showNotification('Bir hata oluştu!', 'error');
    });
}

function closeEmployeeModal() {
    const modal = document.querySelector('.employee-modal');
    if (modal) {
        modal.remove();
    }
}

function GetParentResourceName() {
    return 'qg_markets';
}
