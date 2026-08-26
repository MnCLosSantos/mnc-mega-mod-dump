let currentSellerData = null;
let currentBuyerData = null;
let currentTransferData = null;
let signatureCanvas = null;
let signatureContext = null;
let isDrawing = false;
let resourceName = null;
let pendingConfirmCallback = null;

// Get resource name on load
function getResourceName() {
    if (resourceName) return resourceName;
    
    let hostname = window.location.hostname;
    
    if (hostname && hostname !== '') {
        if (hostname.startsWith('cfx-nui-')) {
            resourceName = hostname.substring(8);
        } else {
            resourceName = hostname;
        }
    }
    
    if (!resourceName) {
        resourceName = 'mnc-transfervehicle';
    }
    
    console.log('[TRANSFER UI] Resource name detected as:', resourceName);
    return resourceName;
}

// Modal System
function showErrorModal(title, message) {
    const modal = document.getElementById('errorModal');
    const modalTitle = document.getElementById('modalTitle');
    const modalMessage = document.getElementById('modalMessage');
    
    modalTitle.textContent = title || 'Error';
    modalMessage.textContent = message;
    modal.style.display = 'flex';
}

function hideErrorModal() {
    const modal = document.getElementById('errorModal');
    modal.style.display = 'none';
}

function showConfirmModal(title, message, onConfirm) {
    const modal = document.getElementById('confirmModal');
    const confirmTitle = document.getElementById('confirmTitle');
    const confirmMessage = document.getElementById('confirmMessage');
    
    confirmTitle.textContent = title || 'Confirm Action';
    confirmMessage.textContent = message;
    modal.style.display = 'flex';
    
    pendingConfirmCallback = onConfirm;
}

function hideConfirmModal() {
    const modal = document.getElementById('confirmModal');
    modal.style.display = 'none';
    pendingConfirmCallback = null;
}

// Utility function to format currency
function formatMoney(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Send NUI callback
function sendNUICallback(endpoint, data) {
    const resName = getResourceName();
    const url = `https://${resName}/${endpoint}`;
    console.log(`[TRANSFER UI] Sending callback to: ${url}`, data);
    
    return fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data || {})
    }).then(response => {
        console.log(`[TRANSFER UI] Callback ${endpoint} response:`, response.status);
        return response;
    }).catch(error => {
        console.error(`[TRANSFER UI] Callback ${endpoint} error:`, error);
        throw error;
    });
}

// Initialize signature canvas
function initSignatureCanvas() {
    const canvas = document.getElementById('signatureCanvas');
    if (!canvas) return;
    
    const newCanvas = canvas.cloneNode(true);
    canvas.parentNode.replaceChild(newCanvas, canvas);
    
    signatureCanvas = newCanvas;
    signatureContext = signatureCanvas.getContext('2d');
    signatureCanvas.width = signatureCanvas.offsetWidth;
    signatureCanvas.height = 100;
    
    signatureContext.strokeStyle = '#000';
    signatureContext.lineWidth = 2;
    signatureContext.lineCap = 'round';
    
    signatureCanvas.addEventListener('mousedown', startDrawing);
    signatureCanvas.addEventListener('mousemove', draw);
    signatureCanvas.addEventListener('mouseup', stopDrawing);
    signatureCanvas.addEventListener('mouseout', stopDrawing);
    
    signatureCanvas.addEventListener('touchstart', handleTouch);
    signatureCanvas.addEventListener('touchmove', handleTouch);
    signatureCanvas.addEventListener('touchend', stopDrawing);
}

function startDrawing(e) {
    isDrawing = true;
    const rect = signatureCanvas.getBoundingClientRect();
    signatureContext.beginPath();
    signatureContext.moveTo(e.clientX - rect.left, e.clientY - rect.top);
}

function draw(e) {
    if (!isDrawing) return;
    const rect = signatureCanvas.getBoundingClientRect();
    signatureContext.lineTo(e.clientX - rect.left, e.clientY - rect.top);
    signatureContext.stroke();
}

function stopDrawing() {
    isDrawing = false;
}

function handleTouch(e) {
    e.preventDefault();
    const touch = e.touches[0];
    const mouseEvent = new MouseEvent(e.type === 'touchstart' ? 'mousedown' : 'mousemove', {
        clientX: touch.clientX,
        clientY: touch.clientY
    });
    signatureCanvas.dispatchEvent(mouseEvent);
}

function clearSignature() {
    if (signatureContext && signatureCanvas) {
        signatureContext.clearRect(0, 0, signatureCanvas.width, signatureCanvas.height);
    }
}

// Reset all state and close all UIs
function resetAllState() {
    console.log('[TRANSFER UI] Resetting all state');
    
    const sellerUI = document.getElementById('sellerUI');
    const buyerUI = document.getElementById('buyerUI');
    const viewUI = document.getElementById('viewDocumentUI');
    
    if (sellerUI) sellerUI.style.display = 'none';
    if (buyerUI) buyerUI.style.display = 'none';
    if (viewUI) viewUI.style.display = 'none';
    
    currentSellerData = null;
    currentBuyerData = null;
    currentTransferData = null;
    
    isDrawing = false;
    
    if (signatureCanvas && signatureContext) {
        try {
            signatureContext.clearRect(0, 0, signatureCanvas.width, signatureCanvas.height);
        } catch (e) {}
    }
    signatureCanvas = null;
    signatureContext = null;
    
    const buyerIdInput = document.getElementById('buyerIdInput');
    const amountInput = document.getElementById('amountInput');
    
    if (buyerIdInput) buyerIdInput.value = '';
    if (amountInput) amountInput.value = '';
    
    const fundsWarning = document.getElementById('fundsWarning');
    const buyerInfoDisplay = document.getElementById('buyerInfoDisplay');
    
    if (fundsWarning) fundsWarning.style.display = 'none';
    if (buyerInfoDisplay) buyerInfoDisplay.style.display = 'none';
}

// Close all UIs and notify Lua
function closeUI() {
    console.log('[TRANSFER UI] closeUI() called - Starting close sequence');
    
    sendNUICallback('close', {}).then(() => {
        console.log('[TRANSFER UI] Close callback completed');
        resetAllState();
    }).catch(() => {
        console.error('[TRANSFER UI] Close callback failed, resetting anyway');
        resetAllState();
    });
}

// Message handler from client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    console.log('[TRANSFER UI] Received message:', data.action);
    
    switch(data.action) {
        case 'openSellerUI':
            openSellerUI(data.sellerData, data.buyerId, data.amount);
            break;
        case 'updateBuyerInfo':
            updateBuyerInfo(data.buyerInfo, data.amount);
            break;
        case 'openBuyerUI':
            openBuyerUI(data.transferData);
            break;
        case 'viewDocument':
            viewDocument(data.documentData);
            break;
        case 'forceClose':
            console.log('[TRANSFER UI] Force close received from Lua');
            resetAllState();
            break;
        case 'showError':
            showErrorModal(data.title || 'Error', data.message);
            break;
    }
});

// Open seller UI
function openSellerUI(sellerData, buyerId, amount) {
    resetAllState();
    
    currentSellerData = sellerData;
    
    document.getElementById('sellerName').textContent = `${sellerData.firstname} ${sellerData.lastname}`;
    document.getElementById('sellerPhone').textContent = sellerData.phone;
    document.getElementById('sellerCID').textContent = sellerData.citizenid;
    document.getElementById('vehicleInfo').textContent = `${sellerData.vehicleBrand} ${sellerData.vehicleName}`;
    document.getElementById('vehiclePlate').textContent = sellerData.plate;
    document.getElementById('vehicleMileage').textContent = `${sellerData.mileage} km`;
    
    if (buyerId) {
        document.getElementById('buyerIdInput').value = buyerId;
    }
    
    if (amount) {
        document.getElementById('amountInput').value = amount;
    }
    
    document.getElementById('sendToBuyerBtn').disabled = true;
    document.getElementById('sellerUI').style.display = 'flex';
}

// Update buyer info in seller UI
function updateBuyerInfo(buyerInfo, amount) {
    currentBuyerData = buyerInfo;
    
    document.getElementById('buyerName').textContent = `${buyerInfo.firstname} ${buyerInfo.lastname}`;
    document.getElementById('buyerPhone').textContent = buyerInfo.phone;
    document.getElementById('buyerCID').textContent = buyerInfo.citizenid;
    document.getElementById('buyerInfoDisplay').style.display = 'block';
    
    const sellAmount = parseFloat(amount) || 0;
    const fundsWarning = document.getElementById('fundsWarning');
    const sendBtn = document.getElementById('sendToBuyerBtn');
    
    if (sellAmount > 0 && buyerInfo.cash < sellAmount && buyerInfo.bank < sellAmount) {
        fundsWarning.style.display = 'block';
        sendBtn.disabled = true;
    } else {
        fundsWarning.style.display = 'none';
        sendBtn.disabled = false;
    }
}

// Open buyer UI
function openBuyerUI(transferData) {
    resetAllState();
    
    currentTransferData = transferData;
    
    document.getElementById('docID').textContent = transferData.documentID;
    document.getElementById('buyerViewSellerName').textContent = `${transferData.seller.firstname} ${transferData.seller.lastname}`;
    document.getElementById('buyerViewSellerPhone').textContent = transferData.seller.phone;
    document.getElementById('buyerViewSellerCID').textContent = transferData.seller.citizenid;
    document.getElementById('buyerViewVehicle').textContent = `${transferData.seller.vehicleBrand} ${transferData.seller.vehicleName}`;
    document.getElementById('buyerViewPlate').textContent = transferData.seller.plate;
    document.getElementById('buyerViewMileage').textContent = `${transferData.seller.mileage} km`;
    document.getElementById('buyerViewBuyerName').textContent = `${transferData.buyer.firstname} ${transferData.buyer.lastname}`;
    document.getElementById('buyerViewBuyerPhone').textContent = transferData.buyer.phone;
    document.getElementById('buyerViewBuyerCID').textContent = transferData.buyer.citizenid;
    
    const amount = parseFloat(transferData.amount) || 0;
    document.getElementById('buyerViewAmount').textContent = amount === 0 ? 'GIFT' : formatMoney(amount);
    document.getElementById('buyerViewDate').textContent = transferData.timestamp;
    
    document.getElementById('buyerUI').style.display = 'flex';
    
    setTimeout(() => {
        initSignatureCanvas();
    }, 100);
}

// View completed document
function viewDocument(documentData) {
    resetAllState();
    
    document.getElementById('viewDocID').textContent = documentData.documentID;
    document.getElementById('viewSellerName').textContent = `${documentData.seller.firstname} ${documentData.seller.lastname}`;
    document.getElementById('viewSellerPhone').textContent = documentData.seller.phone;
    document.getElementById('viewSellerCID').textContent = documentData.seller.citizenid;
    document.getElementById('viewVehicle').textContent = `${documentData.seller.vehicleBrand} ${documentData.seller.vehicleName}`;
    document.getElementById('viewPlate').textContent = documentData.seller.plate;
    document.getElementById('viewMileage').textContent = `${documentData.seller.mileage} km`;
    document.getElementById('viewBuyerName').textContent = `${documentData.buyer.firstname} ${documentData.buyer.lastname}`;
    document.getElementById('viewBuyerPhone').textContent = documentData.buyer.phone;
    document.getElementById('viewBuyerCID').textContent = documentData.buyer.citizenid;
    
    const amount = parseFloat(documentData.amount) || 0;
    document.getElementById('viewAmount').textContent = amount === 0 ? 'GIFT' : formatMoney(amount);
    document.getElementById('viewPaymentMethod').textContent = documentData.paymentMethod ? documentData.paymentMethod.toUpperCase() : 'N/A';
    document.getElementById('viewCompletedDate').textContent = documentData.completedDate;
    document.getElementById('viewSignature').src = documentData.buyerSignature;
    
    document.getElementById('viewDocumentUI').style.display = 'flex';
}

// Event Listeners
document.addEventListener('DOMContentLoaded', function() {
    console.log('[TRANSFER UI] Script loaded and ready');
    
    getResourceName();
    
    // Modal close button
    document.getElementById('modalCloseBtn')?.addEventListener('click', function() {
        hideErrorModal();
    });
    
    // Confirm modal buttons
    document.getElementById('confirmYesBtn')?.addEventListener('click', function() {
        if (pendingConfirmCallback) {
            pendingConfirmCallback();
        }
        hideConfirmModal();
    });
    
    document.getElementById('confirmNoBtn')?.addEventListener('click', function() {
        hideConfirmModal();
    });
    
    // Fetch buyer info button
    document.getElementById('fetchBuyerBtn')?.addEventListener('click', function() {
        console.log('[TRANSFER UI] Fetch buyer button clicked');
        const buyerId = parseInt(document.getElementById('buyerIdInput').value);
        const amount = parseFloat(document.getElementById('amountInput').value) || 0;
        
        if (!buyerId || buyerId <= 0) {
            showErrorModal('Invalid Input', 'Please enter a valid buyer ID');
            return;
        }
        
        sendNUICallback('getBuyerInfo', {
            buyerId: buyerId,
            sellerData: currentSellerData,
            amount: amount
        });
    });
    
    // Send to buyer button
    document.getElementById('sendToBuyerBtn')?.addEventListener('click', function() {
        console.log('[TRANSFER UI] Send to buyer button clicked');
        const amount = parseFloat(document.getElementById('amountInput').value) || 0;
        
        const amountText = amount === 0 ? 'as a gift' : `for ${formatMoney(amount)}`;
        const buyerName = `${currentBuyerData.firstname} ${currentBuyerData.lastname}`;
        
        showConfirmModal(
            'Confirm Transfer',
            `Send vehicle transfer document to ${buyerName} ${amountText}?`,
            function() {
                sendNUICallback('sendToBuyer', {
                    transferData: {
                        seller: currentSellerData,
                        buyer: currentBuyerData,
                        amount: amount
                    }
                });
                closeUI();
            }
        );
    });
    
    // Cancel seller button
    document.getElementById('cancelSellerBtn')?.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        console.log('[TRANSFER UI] Cancel button clicked');
        closeUI();
    });
    
    // Clear signature button
    document.getElementById('clearSignatureBtn')?.addEventListener('click', function() {
        console.log('[TRANSFER UI] Clear signature clicked');
        clearSignature();
    });
    
    // Accept transfer button
    document.getElementById('acceptBtn')?.addEventListener('click', function() {
        console.log('[TRANSFER UI] Accept button clicked');
        if (!signatureCanvas || !signatureContext) {
            showErrorModal('No Signature', 'Signature canvas not initialized');
            return;
        }
        
        const imageData = signatureContext.getImageData(0, 0, signatureCanvas.width, signatureCanvas.height);
        const hasSignature = imageData.data.some(channel => channel !== 0);
        
        if (!hasSignature) {
            showErrorModal('Signature Required', 'Please provide your signature before accepting');
            return;
        }
        
        const signature = signatureCanvas.toDataURL();
        const amount = parseFloat(currentTransferData.amount) || 0;
        const amountText = amount === 0 ? 'as a gift' : `for ${formatMoney(amount)}`;
        
        showConfirmModal(
            'Confirm Purchase',
            `Accept this vehicle transfer ${amountText}?`,
            function() {
                sendNUICallback('acceptTransfer', {
                    documentID: currentTransferData.documentID,
                    signature: signature
                });
                closeUI();
            }
        );
    });
    
    // Deny transfer button
    document.getElementById('denyBtn')?.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        console.log('[TRANSFER UI] Deny button clicked');
        if (!currentTransferData) return;
        
        showConfirmModal(
            'Deny Transfer',
            'Are you sure you want to deny this vehicle transfer?',
            function() {
                sendNUICallback('denyTransfer', {
                    documentID: currentTransferData.documentID
                });
                closeUI();
            }
        );
    });
    
    // Close view button
    document.getElementById('closeViewBtn')?.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        console.log('[TRANSFER UI] Close view button clicked');
        closeUI();
    });
    
    // ESC key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' || e.keyCode === 27) {
            e.preventDefault();
            e.stopPropagation();
            console.log('[TRANSFER UI] ESC key pressed');
            
            // Close modals first if they're open
            if (document.getElementById('errorModal').style.display === 'flex') {
                hideErrorModal();
            } else if (document.getElementById('confirmModal').style.display === 'flex') {
                hideConfirmModal();
            } else {
                closeUI();
            }
        }
    });
});