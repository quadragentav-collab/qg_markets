let currentMarket = null;
let currentVending = null;
let currentLanguage = null;
let currentPaymentMethods = null;
let cart = [];
let selectedPaymentMethod = null;
let selectedVendingItem = null;
let selectedVendingPayment = null;
let hasLicense = true;
let currentLocationIndex = null;
let hasCustomStock = false;

// Initialize when market/vending opens
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openMarket':
            currentMarket = data.marketData;
            currentLanguage = data.language;
            currentPaymentMethods = data.paymentMethods;
            hasLicense = data.hasLicense !== undefined ? data.hasLicense : true;
            currentLocationIndex = data.marketData.locationIndex || null;
            hasCustomStock = data.hasCustomStock || false;
            openMarket();
            break;
        case 'openVending':
            currentVending = data.vendingData;
            currentLanguage = data.language;
            currentPaymentMethods = data.paymentMethods;
            openVending();
            break;
        case 'closeMarket':
            closeMarket();
            break;
        case 'closeVending':
            closeVending();
            break;
    }
});

// MARKET FUNCTIONS
function openMarket() {
    document.getElementById('market-container').classList.remove('hidden');
    document.getElementById('vending-container').classList.add('hidden');
    document.getElementById('market-title').textContent = currentMarket.label;
    
    updateLanguage();
    populateItems();
    setupMarketEventListeners();
    updateCartDisplay();
}

function closeMarket() {
    document.getElementById('market-container').classList.add('hidden');
    document.getElementById('market-interface').classList.remove('hidden');
    document.getElementById('payment-interface').classList.add('hidden');
    cart = [];
    selectedPaymentMethod = null;
    
    document.querySelectorAll('.payment-option').forEach(btn => {
        btn.classList.remove('selected');
    });
    
    const confirmBtn = document.getElementById('confirm-payment-btn');
    if (confirmBtn) {
        confirmBtn.disabled = true;
        confirmBtn.textContent = 'Öde';
    }
    
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.value = '';
    }
}

function updateLanguage() {
    document.getElementById('search-input').placeholder = currentLanguage.search_placeholder;
}

function populateItems() {
    const itemsGrid = document.getElementById('items-grid');
    itemsGrid.innerHTML = '';
    
    currentMarket.items.forEach(item => {
        const itemElement = createItemElement(item);
        itemsGrid.appendChild(itemElement);
    });
}

function createItemElement(item) {
    const itemDiv = document.createElement('div');
    itemDiv.className = 'item-card';
    
    const needsLicense = currentMarket.requiresLicense;
    const isDisabled = needsLicense && !hasLicense;
    
    if (isDisabled) {
        itemDiv.classList.add('disabled');
        itemDiv.onclick = () => showLicenseError();
    } else {
        itemDiv.onclick = () => addToCart(item);
    }
    
    itemDiv.setAttribute('data-name', item.label.toLowerCase());
    itemDiv.setAttribute('data-category', item.category || 'general');

    const imageDiv = document.createElement('div');
    imageDiv.className = 'item-image';

    const image = document.createElement('img');
    const imageName = item.image || (item.name + '.png');
    image.src = `nui://ox_inventory/web/images/${imageName}`;
    image.alt = item.label;
    image.onerror = function() {
        this.src = `nui://qb-inventory/html/images/${imageName}`;
        this.onerror = function() {
            this.src = 'https://via.placeholder.com/50x50/666/fff?text=?';
        };
    };

    imageDiv.appendChild(image);

    const nameDiv = document.createElement('div');
    nameDiv.className = 'item-name';
    nameDiv.textContent = item.label;

    const priceDiv = document.createElement('div');
    priceDiv.className = 'item-price';
    priceDiv.textContent = `$${item.price.toFixed(2)}`;

    if (isDisabled) {
        const lockIcon = document.createElement('div');
        lockIcon.className = 'lock-icon';
        lockIcon.innerHTML = '🔒';
        itemDiv.appendChild(lockIcon);
    }

    itemDiv.appendChild(nameDiv);
    itemDiv.appendChild(imageDiv);
    itemDiv.appendChild(priceDiv);

    return itemDiv;
}

function showLicenseError() {
    fetch(`https://${GetParentResourceName()}/showNotification`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            message: currentLanguage.license_required,
            type: 'error'
        })
    });
}

function addToCart(item) {
    const existingItem = cart.find(cartItem => cartItem.name === item.name);

    // Stok kontrolü (eğer custom stock varsa)
    if (hasCustomStock && item.stock !== undefined) {
        const currentQuantity = existingItem ? existingItem.quantity : 0;
        if (currentQuantity >= item.stock) {
            fetch(`https://${GetParentResourceName()}/showNotification`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: 'Yeterli stok yok!',
                    type: 'error'
                })
            });
            return;
        }
    }

    if (existingItem) {
        existingItem.quantity += 1;
    } else {
        cart.push({
            name: item.name,
            label: item.label,
            price: item.price,
            quantity: 1,
            stock: item.stock, // Stok bilgisini tut
            image: item.image // Image bilgisini tut
        });
    }

    updateCartDisplay();
}

function updateCartDisplay() {
    const cartItems = document.getElementById('cart-items');
    const cartTotal = document.getElementById('cart-total');
    
    cartItems.innerHTML = '';
    
    let totalPrice = 0;
    
    cart.forEach(item => {
        const cartItemDiv = createCartItemElement(item);
        cartItems.appendChild(cartItemDiv);
        
        totalPrice += item.price * item.quantity;
    });
    
    cartTotal.textContent = `$${totalPrice.toFixed(2)}`;
}

function createCartItemElement(item) {
    const itemDiv = document.createElement('div');
    itemDiv.className = 'cart-item';

    const imageDiv = document.createElement('div');
    imageDiv.className = 'cart-item-image';

    const image = document.createElement('img');
    const imageName = item.image || (item.name + '.png');
    image.src = `nui://ox_inventory/web/images/${imageName}`;
    image.alt = item.label;
    image.onerror = function() {
        this.src = `nui://qb-inventory/html/images/${imageName}`;
        this.onerror = function() {
            this.src = 'https://via.placeholder.com/40x40/666/fff?text=?';
        };
    };

    imageDiv.appendChild(image);

    const nameDiv = document.createElement('div');
    nameDiv.className = 'cart-item-name';
    nameDiv.textContent = item.label;

    const detailsDiv = document.createElement('div');
    detailsDiv.className = 'cart-item-details';

    const quantityDiv = document.createElement('div');
    quantityDiv.className = 'cart-item-quantity';

    const minusBtn = document.createElement('button');
    minusBtn.className = 'quantity-btn';
    minusBtn.textContent = '-';
    minusBtn.onclick = () => updateQuantity(item.name, -1);

    const quantitySpan = document.createElement('span');
    quantitySpan.textContent = item.quantity;

    const plusBtn = document.createElement('button');
    plusBtn.className = 'quantity-btn';
    plusBtn.textContent = '+';
    plusBtn.onclick = () => updateQuantity(item.name, 1);

    quantityDiv.appendChild(minusBtn);
    quantityDiv.appendChild(quantitySpan);
    quantityDiv.appendChild(plusBtn);

    detailsDiv.appendChild(quantityDiv);

    itemDiv.appendChild(imageDiv);
    itemDiv.appendChild(detailsDiv);

    return itemDiv;
}

function updateQuantity(itemName, change) {
    const item = cart.find(cartItem => cartItem.name === itemName);

    if (item) {
        const newQuantity = item.quantity + change;

        // Stok kontrolü (eğer custom stock varsa)
        if (hasCustomStock && item.stock !== undefined && newQuantity > item.stock) {
            fetch(`https://${GetParentResourceName()}/showNotification`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: 'Yeterli stok yok!',
                    type: 'error'
                })
            });
            return;
        }

        item.quantity = newQuantity;

        if (item.quantity <= 0) {
            cart = cart.filter(cartItem => cartItem.name !== itemName);
        }

        updateCartDisplay();
    }
}

function clearCart() {
    cart = [];
    updateCartDisplay();
}

function openPayment() {
    if (cart.length === 0) {
        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: currentLanguage.cart_empty,
                type: 'error'
            })
        });
        return;
    }
    
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    document.getElementById('market-interface').classList.add('hidden');
    document.getElementById('payment-interface').classList.remove('hidden');
    document.getElementById('payment-total').textContent = `$${total.toFixed(2)}`;
    
    selectedPaymentMethod = null;
    updatePaymentUI();
}

function selectPaymentMethod(method) {
    selectedPaymentMethod = method;
    
    document.querySelectorAll('.payment-option').forEach(btn => {
        btn.classList.remove('selected');
    });
    
    document.querySelector(`[data-method="${method}"]`).classList.add('selected');
    updatePaymentUI();
}

function updatePaymentUI() {
    const confirmBtn = document.getElementById('confirm-payment-btn');
    confirmBtn.disabled = !selectedPaymentMethod;
}

function confirmPayment() {
    if (!selectedPaymentMethod) {
        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: 'Lütfen bir ödeme yöntemi seçin!',
                type: 'error'
            })
        });
        return;
    }

    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);

    const confirmBtn = document.getElementById('confirm-payment-btn');
    const originalText = confirmBtn.textContent;
    confirmBtn.disabled = true;
    confirmBtn.textContent = 'İşleniyor...';

    fetch(`https://${GetParentResourceName()}/purchaseItems`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            paymentMethod: selectedPaymentMethod,
            items: cart,
            total: total,
            purchaseType: 'market',
            locationIndex: currentLocationIndex
        })
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
        if (data.success) {
            cart = [];
            selectedPaymentMethod = null;

            closeMarket();

            fetch(`https://${GetParentResourceName()}/closeMarket`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({})
            }).catch(err => console.log('Close market error:', err));

        } else {
            confirmBtn.disabled = false;
            confirmBtn.textContent = originalText;
            cancelPayment();
        }
    })
    .catch(error => {
        console.error('Purchase error:', error);

        confirmBtn.disabled = false;
        confirmBtn.textContent = originalText;

        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: 'Bir hata oluştu',
                type: 'error'
            })
        }).catch(err => console.log('Notification error:', err));

        cancelPayment();
    });
}

function cancelPayment() {
    document.getElementById('payment-interface').classList.add('hidden');
    document.getElementById('market-interface').classList.remove('hidden');
    selectedPaymentMethod = null;
    
    document.querySelectorAll('.payment-option').forEach(btn => {
        btn.classList.remove('selected');
    });
    
    const confirmBtn = document.getElementById('confirm-payment-btn');
    confirmBtn.disabled = true;
    confirmBtn.textContent = 'Öde';
}

// VENDING MACHINE FUNCTIONS
function openVending() {
    document.getElementById('vending-container').classList.remove('hidden');
    document.getElementById('market-container').classList.add('hidden');
    document.getElementById('vending-title').textContent = currentVending.name;
    
    populateVendingItems();
    setupVendingEventListeners();
    resetVendingSelection();
}

function closeVending() {
    document.getElementById('vending-container').classList.add('hidden');
    resetVendingSelection();
}

function populateVendingItems() {
    const itemsGrid = document.getElementById('vending-items-grid');
    itemsGrid.innerHTML = '';
    
    currentVending.inventory.forEach((item, index) => {
        const itemElement = createVendingItemElement(item, index + 1);
        itemsGrid.appendChild(itemElement);
    });
}

function createVendingItemElement(item, code) {
    const itemDiv = document.createElement('div');
    itemDiv.className = 'vending-item';
    itemDiv.setAttribute('data-item', item.name);
    itemDiv.onclick = () => selectVendingItem(item, itemDiv);

    // Code display
    const codeDiv = document.createElement('div');
    codeDiv.className = 'vending-item-code';
    codeDiv.textContent = 'A' + code;

    // Image
    const imageDiv = document.createElement('div');
    imageDiv.className = 'vending-item-image';

    const image = document.createElement('img');
    const imageName = item.image || (item.name + '.png');
    image.src = `nui://ox_inventory/web/images/${imageName}`;
    image.alt = item.label || item.name;
    image.onerror = function() {
        this.src = `nui://qb-inventory/html/images/${imageName}`;
        this.onerror = function() {
            this.src = 'https://via.placeholder.com/60x60/666/fff?text=?';
        };
    };

    imageDiv.appendChild(image);

    // Name
    const nameDiv = document.createElement('div');
    nameDiv.className = 'vending-item-name';
    nameDiv.textContent = item.label || item.name;

    // Price
    const priceDiv = document.createElement('div');
    priceDiv.className = 'vending-item-price';
    priceDiv.textContent = `$${item.price.toFixed(2)}`;

    itemDiv.appendChild(codeDiv);
    itemDiv.appendChild(imageDiv);
    itemDiv.appendChild(nameDiv);
    itemDiv.appendChild(priceDiv);

    return itemDiv;
}

function selectVendingItem(item, element) {
    // Remove previous selection
    document.querySelectorAll('.vending-item').forEach(el => {
        el.classList.remove('selected');
    });
    
    // Select new item
    element.classList.add('selected');
    selectedVendingItem = item;
    
    // Update display
    document.getElementById('vending-display-text').textContent = item.label || item.name;
    document.getElementById('vending-price-display').textContent = `$${item.price.toFixed(2)}`;
    
    updateVendingBuyButton();
}

function selectVendingPayment(method, element) {
    // Remove previous selection
    document.querySelectorAll('.vending-payment-btn').forEach(el => {
        el.classList.remove('selected');
    });
    
    // Select new payment method
    element.classList.add('selected');
    selectedVendingPayment = method;
    
    updateVendingBuyButton();
}

function updateVendingBuyButton() {
    const buyBtn = document.getElementById('vending-buy-btn');
    buyBtn.disabled = !selectedVendingItem || !selectedVendingPayment;
}

function buyVendingItem() {
    if (!selectedVendingItem || !selectedVendingPayment) {
        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: 'Lütfen ürün ve ödeme yöntemi seçin!',
                type: 'error'
            })
        });
        return;
    }
    
    const buyBtn = document.getElementById('vending-buy-btn');
    buyBtn.disabled = true;
    buyBtn.textContent = 'İşleniyor...';
    
    // Create cart-like structure for compatibility
    const vendingCart = [{
        name: selectedVendingItem.name,
        label: selectedVendingItem.label || selectedVendingItem.name,
        price: selectedVendingItem.price,
        quantity: 1,
        image: selectedVendingItem.image
    }];
    
    fetch(`https://${GetParentResourceName()}/purchaseItems`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            paymentMethod: selectedVendingPayment,
            items: vendingCart,
            total: selectedVendingItem.price,
            purchaseType: 'vending'
        })
    })
    .then(response => response.json())
    .then(data => {
        buyBtn.disabled = false;
        buyBtn.textContent = 'Satın Al';
        
        if (data.success) {
            // Show success animation
            document.getElementById('vending-display-text').textContent = 'Afiyet Olsun!';
            
            setTimeout(() => {
                closeVending();
                
                fetch(`https://${GetParentResourceName()}/closeVending`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({})
                });
            }, 2000);
            
        } else {
            resetVendingSelection();
        }
    })
    .catch(error => {
        console.error('Vending purchase error:', error);
        
        buyBtn.disabled = false;
        buyBtn.textContent = 'Satın Al';
        
        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: 'Bir hata oluştu: ' + error.message,
                type: 'error'
            })
        });
        
        resetVendingSelection();
    });
}

function resetVendingSelection() {
    selectedVendingItem = null;
    selectedVendingPayment = null;
    
    document.querySelectorAll('.vending-item').forEach(el => {
        el.classList.remove('selected');
    });
    
    document.querySelectorAll('.vending-payment-btn').forEach(el => {
        el.classList.remove('selected');
    });
    
    document.getElementById('vending-display-text').textContent = 'Ürün Seçiniz';
    document.getElementById('vending-price-display').textContent = '$0.00';
    
    const buyBtn = document.getElementById('vending-buy-btn');
    buyBtn.disabled = true;
    buyBtn.textContent = 'Satın Al';
}

function setupMarketEventListeners() {
    const exitBtn = document.getElementById('exit-btn');
    if (exitBtn) {
        exitBtn.onclick = () => {
            fetch(`https://${GetParentResourceName()}/closeMarket`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        };
    }

    const payBtn = document.getElementById('pay-btn');
    if (payBtn) {
        payBtn.onclick = openPayment;
    }

    const clearCartBtn = document.getElementById('clear-cart-btn');
    if (clearCartBtn) {
        clearCartBtn.onclick = clearCart;
    }

    const cancelBtn = document.getElementById('cancel-payment-btn');
    if (cancelBtn) {
        cancelBtn.onclick = cancelPayment;
    }

    const confirmBtn = document.getElementById('confirm-payment-btn');
    if (confirmBtn) {
        confirmBtn.onclick = confirmPayment;
    }

    document.querySelectorAll('.payment-option').forEach(btn => {
        btn.onclick = () => selectPaymentMethod(btn.dataset.method);
    });

    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.removeEventListener('input', filterItems);
        searchInput.removeEventListener('keyup', filterItems);
        
        searchInput.addEventListener('input', filterItems);
        searchInput.addEventListener('keyup', filterItems);
        searchInput.addEventListener('paste', function() {
            setTimeout(filterItems, 10);
        });
    }

    document.addEventListener('keyup', function (event) {
        if (event.key === 'Escape') {
            fetch(`https://${GetParentResourceName()}/closeMarket`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });
}

function setupVendingEventListeners() {
    const cancelBtn = document.getElementById('vending-cancel-btn');
    if (cancelBtn) {
        cancelBtn.onclick = () => {
            fetch(`https://${GetParentResourceName()}/closeVending`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        };
    }

    const buyBtn = document.getElementById('vending-buy-btn');
    if (buyBtn) {
        buyBtn.onclick = buyVendingItem;
    }

    document.querySelectorAll('.vending-payment-btn').forEach(btn => {
        btn.onclick = () => selectVendingPayment(btn.dataset.method, btn);
    });

    document.addEventListener('keyup', function (event) {
        if (event.key === 'Escape') {
            fetch(`https://${GetParentResourceName()}/closeVending`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });
}

function filterItems() {
    const searchInput = document.getElementById('search-input');
    if (!searchInput) return;
    
    const searchTerm = searchInput.value.toLowerCase().trim();
    const itemCards = document.querySelectorAll('.item-card');
    
    itemCards.forEach(card => {
        const itemName = card.getAttribute('data-name') || '';
        
        if (searchTerm === '' || itemName.includes(searchTerm)) {
            card.style.display = 'flex';
        } else {
            card.style.display = 'none';
        }
    });
}

function GetParentResourceName() {
    return 'qg_markets';
}