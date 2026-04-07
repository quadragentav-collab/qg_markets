let wholesalerData = {
    products: [],
    ownedMarkets: [],
    orders: [],
    config: {},
    selectedMarket: null,
    orderItems: [],
    selectedPaymentMethod: null
};

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openWholesaler') {
        wholesalerData.products = data.products || [];
        wholesalerData.ownedMarkets = data.ownedMarkets || [];
        wholesalerData.orders = data.orders || [];
        wholesalerData.config = data.config || {};
        openWholesaler();
    }
});

function openWholesaler() {
    document.getElementById('wholesaler-container').classList.remove('hidden');
    populateMarketSelect();
    populateProducts();
    populatePendingOrders();
    setupWholesalerEventListeners();
}

function closeWholesaler() {
    document.getElementById('wholesaler-container').classList.add('hidden');
    document.getElementById('wholesaler-main-interface').classList.remove('hidden');
    document.getElementById('wholesaler-payment-interface').classList.add('hidden');
    wholesalerData.orderItems = [];
    wholesalerData.selectedMarket = null;
    wholesalerData.selectedPaymentMethod = null;
    updateOrderDisplay();

    fetch(`https://${GetParentResourceName()}/closeWholesaler`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function populateMarketSelect() {
    const select = document.getElementById('wholesaler-market-select');
    select.innerHTML = '<option value="">Market seçin...</option>';

    wholesalerData.ownedMarkets.forEach((market, index) => {
        const option = document.createElement('option');
        option.value = index;
        option.textContent = `${market.marketId.charAt(0).toUpperCase() + market.marketId.slice(1)} - Market #${market.locationIndex}`;
        option.dataset.marketId = market.marketId;
        option.dataset.locationIndex = market.locationIndex;
        select.appendChild(option);
    });
}

function populateProducts() {
    const grid = document.getElementById('wholesaler-products-grid');
    grid.innerHTML = '';

    wholesalerData.products.forEach(product => {
        const productCard = document.createElement('div');
        productCard.className = 'wholesaler-product-card';

        const imageName = product.image || (product.name + '.png');

        productCard.innerHTML = `
            <div class="product-info">
                <div class="product-image-container">
                    <img class="product-image"
                         src="nui://ox_inventory/web/images/${imageName}"
                         alt="${product.label}"
                         onerror="this.onerror=null; this.src='nui://qb-inventory/html/images/${imageName}'; this.onerror=function(){this.src='https://via.placeholder.com/60x60/666/fff?text=?';}">
                </div>
                <div class="product-details">
                    <div class="product-name">${product.label}</div>
                    <div class="product-price">$${product.price.toFixed(2)}</div>
                    <div class="product-stock-info">Maks. Stok: ${product.maxStock}</div>
                </div>
            </div>
            <div class="product-quantity">
                <button class="qty-btn" onclick="changeProductQty('${product.name}', -10)">-10</button>
                <button class="qty-btn" onclick="changeProductQty('${product.name}', -1)">-</button>
                <input type="number" id="qty-${product.name}" value="0" min="0" max="${product.maxStock}"
                       onchange="validateQty('${product.name}', ${product.maxStock})">
                <button class="qty-btn" onclick="changeProductQty('${product.name}', 1)">+</button>
                <button class="qty-btn" onclick="changeProductQty('${product.name}', 10)">+10</button>
            </div>
            <button class="add-to-order-btn" onclick="addToOrder('${product.name}')">Ekle</button>
        `;

        grid.appendChild(productCard);
    });
}

function changeProductQty(productName, change) {
    const input = document.getElementById(`qty-${productName}`);
    let currentValue = parseInt(input.value) || 0;
    let newValue = currentValue + change;

    const max = parseInt(input.max);
    newValue = Math.max(0, Math.min(newValue, max));

    input.value = newValue;
}

function validateQty(productName, max) {
    const input = document.getElementById(`qty-${productName}`);
    let value = parseInt(input.value) || 0;
    value = Math.max(0, Math.min(value, max));
    input.value = value;
}

function addToOrder(productName) {
    const select = document.getElementById('wholesaler-market-select');
    if (!select.value) {
        showNotification('Lütfen önce bir market seçin!', 'error');
        return;
    }

    const qtyInput = document.getElementById(`qty-${productName}`);
    const quantity = parseInt(qtyInput.value) || 0;

    if (quantity <= 0) {
        showNotification('Lütfen geçerli bir miktar girin!', 'error');
        return;
    }

    const product = wholesalerData.products.find(p => p.name === productName);
    if (!product) return;

    const existingItem = wholesalerData.orderItems.find(item => item.name === productName);
    if (existingItem) {
        existingItem.quantity += quantity;
    } else {
        wholesalerData.orderItems.push({
            name: product.name,
            label: product.label,
            price: product.price,
            quantity: quantity
        });
    }

    qtyInput.value = 0;
    updateOrderDisplay();
    showNotification(`${quantity}x ${product.label} sepete eklendi!`, 'success');
}

function removeFromOrder(productName) {
    wholesalerData.orderItems = wholesalerData.orderItems.filter(item => item.name !== productName);
    updateOrderDisplay();
}

function updateOrderDisplay() {
    const container = document.getElementById('wholesaler-order-items');
    const placeOrderBtn = document.getElementById('wholesaler-place-order-btn');

    if (wholesalerData.orderItems.length === 0) {
        container.innerHTML = '<p class="empty-message">Henüz ürün eklenmedi</p>';
        placeOrderBtn.disabled = true;
        updateOrderSummary(0, 0, 0);
        return;
    }

    container.innerHTML = '';
    wholesalerData.orderItems.forEach(item => {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'order-item';
        itemDiv.innerHTML = `
            <div class="order-item-info">
                <div class="order-item-name">${item.label}</div>
                <div class="order-item-details">${item.quantity}x @ $${item.price.toFixed(2)}</div>
            </div>
            <div class="order-item-right">
                <div class="order-item-total">$${(item.quantity * item.price).toFixed(2)}</div>
                <button class="remove-item-btn" onclick="removeFromOrder('${item.name}')">✕</button>
            </div>
        `;
        container.appendChild(itemDiv);
    });

    const select = document.getElementById('wholesaler-market-select');
    placeOrderBtn.disabled = !select.value || wholesalerData.orderItems.length === 0;

    calculateOrderTotal();
}

function calculateOrderTotal() {
    let subtotal = 0;
    wholesalerData.orderItems.forEach(item => {
        subtotal += item.quantity * item.price;
    });

    const isExpress = document.getElementById('express-delivery-checkbox').checked;
    const expressFee = isExpress ? Math.floor(subtotal * (wholesalerData.config.expressMultiplier - 1)) : 0;
    const total = subtotal + expressFee;

    updateOrderSummary(subtotal, expressFee, total);
}

function updateOrderSummary(subtotal, expressFee, total) {
    document.getElementById('wholesaler-subtotal').textContent = `$${subtotal.toFixed(2)}`;
    document.getElementById('wholesaler-express-fee').textContent = `$${expressFee.toFixed(2)}`;
    document.getElementById('wholesaler-total').textContent = `$${total.toFixed(2)}`;

    const expressFeeRow = document.getElementById('express-fee-row');
    if (expressFee > 0) {
        expressFeeRow.style.display = 'flex';
    } else {
        expressFeeRow.style.display = 'none';
    }

    const isExpress = document.getElementById('express-delivery-checkbox').checked;
    const baseTime = wholesalerData.config.baseDeliveryTime || 3600;
    const deliveryTime = isExpress ? Math.floor(baseTime * 0.5) : baseTime;
    const minutes = Math.floor(deliveryTime / 60);

    document.getElementById('delivery-time-text').textContent = `Teslimat Süresi: ${minutes} dakika`;
}

function populatePendingOrders() {
    const container = document.getElementById('pending-orders-list');

    if (!wholesalerData.orders || wholesalerData.orders.length === 0) {
        container.innerHTML = '<p class="empty-message">Bekleyen sipariş yok</p>';
        return;
    }

    container.innerHTML = '';
    wholesalerData.orders.forEach(order => {
        const remainingTime = order.deliveryAt - Math.floor(Date.now() / 1000);
        const minutes = Math.max(0, Math.floor(remainingTime / 60));
        const isReady = order.status === 'ready';

        const orderDiv = document.createElement('div');
        orderDiv.className = 'pending-order-item';

        let statusText = '';
        let collectButton = '';

        if (isReady) {
            statusText = '<div class="pending-order-status ready">Teslim Almaya Hazır!</div>';
            collectButton = `<button class="collect-order-btn" onclick="collectOrder('${order.orderId}')">Teslim Al</button>`;
        } else {
            statusText = `<div class="pending-order-time">	Hazırlanıyor...</div>`;
        }

        orderDiv.innerHTML = `
            <div class="pending-order-info">
                <div class="pending-order-market">Market #${order.locationIndex}</div>
                <div class="pending-order-cost">Toplam: $${order.totalCost.toFixed(2)}</div>
                ${statusText}
            </div>
            ${collectButton}
        `;
        container.appendChild(orderDiv);
    });
}

function collectOrder(orderId) {
    fetch(`https://${GetParentResourceName()}/collectWholesalerOrder`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId: orderId })
    }).then(resp => resp.json()).then(resp => {
        if (resp.success) {
            // Remove collected order from list
            wholesalerData.orders = wholesalerData.orders.filter(o => o.orderId !== orderId);
            populatePendingOrders();
        }
    }).catch(error => {
        console.error('Collect order error:', error);
    });
}

function placeOrder() {
    const select = document.getElementById('wholesaler-market-select');
    const selectedOption = select.options[select.selectedIndex];

    if (!selectedOption || !selectedOption.value) {
        showNotification('Lütfen bir market seçin!', 'error');
        return;
    }

    if (wholesalerData.orderItems.length === 0) {
        showNotification('Sipariş listesi boş!', 'error');
        return;
    }

    openWholesalerPayment();
}

function openWholesalerPayment() {
    const total = wholesalerData.orderItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const isExpress = document.getElementById('express-delivery-checkbox').checked;
    const expressFee = isExpress ? Math.floor(total * (wholesalerData.config.expressMultiplier - 1)) : 0;
    const finalTotal = total + expressFee;

    document.getElementById('wholesaler-main-interface').classList.add('hidden');
    document.getElementById('wholesaler-payment-interface').classList.remove('hidden');
    document.getElementById('wholesaler-payment-total').textContent = `$${finalTotal.toFixed(2)}`;

    wholesalerData.selectedPaymentMethod = null;
    updateWholesalerPaymentUI();
}

function cancelWholesalerPayment() {
    document.getElementById('wholesaler-payment-interface').classList.add('hidden');
    document.getElementById('wholesaler-main-interface').classList.remove('hidden');
    wholesalerData.selectedPaymentMethod = null;

    document.querySelectorAll('#wholesaler-payment-interface .payment-option').forEach(btn => {
        btn.classList.remove('selected');
    });

    const confirmBtn = document.getElementById('wholesaler-confirm-payment-btn');
    confirmBtn.disabled = true;
}

function selectWholesalerPaymentMethod(method) {
    wholesalerData.selectedPaymentMethod = method;

    document.querySelectorAll('#wholesaler-payment-interface .payment-option').forEach(btn => {
        btn.classList.remove('selected');
    });

    document.querySelector(`#wholesaler-payment-interface [data-method="${method}"]`).classList.add('selected');
    updateWholesalerPaymentUI();
}

function updateWholesalerPaymentUI() {
    const confirmBtn = document.getElementById('wholesaler-confirm-payment-btn');
    confirmBtn.disabled = !wholesalerData.selectedPaymentMethod;
}

function confirmWholesalerPayment() {
    if (!wholesalerData.selectedPaymentMethod) {
        showNotification('Lütfen bir ödeme yöntemi seçin!', 'error');
        return;
    }

    const select = document.getElementById('wholesaler-market-select');
    const selectedOption = select.options[select.selectedIndex];
    const marketId = selectedOption.dataset.marketId;
    const locationIndex = parseInt(selectedOption.dataset.locationIndex);
    const isExpress = document.getElementById('express-delivery-checkbox').checked;

    const confirmBtn = document.getElementById('wholesaler-confirm-payment-btn');
    confirmBtn.disabled = true;
    confirmBtn.textContent = 'İşleniyor...';

    fetch(`https://${GetParentResourceName()}/placeWholesalerOrder`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            marketId: marketId,
            locationIndex: locationIndex,
            items: wholesalerData.orderItems,
            expressDelivery: isExpress,
            paymentMethod: wholesalerData.selectedPaymentMethod
        })
    }).then(resp => resp.json()).then(resp => {
        confirmBtn.disabled = false;
        confirmBtn.textContent = 'Öde';

        if (resp.success) {
            wholesalerData.orderItems = [];
            wholesalerData.selectedPaymentMethod = null;
            document.getElementById('express-delivery-checkbox').checked = false;
            updateOrderDisplay();

            setTimeout(() => {
                closeWholesaler();
            }, 1000);
        } else {
            cancelWholesalerPayment();
        }
    }).catch(error => {
        console.error('Order error:', error);
        confirmBtn.disabled = false;
        confirmBtn.textContent = 'Öde';
        cancelWholesalerPayment();
    });
}

function setupWholesalerEventListeners() {
    document.getElementById('wholesaler-close-btn').onclick = closeWholesaler;
    document.getElementById('wholesaler-place-order-btn').onclick = placeOrder;

    document.getElementById('express-delivery-checkbox').onchange = function() {
        calculateOrderTotal();
    };

    document.getElementById('wholesaler-market-select').onchange = function() {
        const placeOrderBtn = document.getElementById('wholesaler-place-order-btn');
        placeOrderBtn.disabled = !this.value || wholesalerData.orderItems.length === 0;
    };

    document.getElementById('wholesaler-cancel-payment-btn').onclick = cancelWholesalerPayment;
    document.getElementById('wholesaler-confirm-payment-btn').onclick = confirmWholesalerPayment;

    document.querySelectorAll('#wholesaler-payment-interface .payment-option').forEach(btn => {
        btn.onclick = () => selectWholesalerPaymentMethod(btn.dataset.method);
    });
}

function showNotification(message, type) {
    fetch(`https://${GetParentResourceName()}/showNotification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: message, type: type })
    });
}

function GetParentResourceName() {
    return window.location.hostname === 'nui-game-internal' ?
           (window.GetParentResourceName ? window.GetParentResourceName() : 'qg_markets') :
           'qg_markets';
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const wholesalerContainer = document.getElementById('wholesaler-container');
        if (!wholesalerContainer.classList.contains('hidden')) {
            closeWholesaler();
        }
    }
});
