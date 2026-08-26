// mnc-gruppe6 Tablet UI with Lock Screen

(function() {
    // Elements
    const backdrop = document.getElementById('tablet-backdrop');
    const tablet = document.getElementById('tablet');
    const lockScreen = document.getElementById('lock-screen');
    const tabletMain = document.getElementById('tablet-main');
    const fingerprintBtn = document.getElementById('fingerprint-btn');
    const lockTime = document.getElementById('lock-time');
    const lockDate = document.getElementById('lock-date');
    const loanList = document.getElementById('loan-list');
    const cashList = document.getElementById('cash-list');
    const closeBtn = document.getElementById('close-btn');
    const playerNameEl = document.getElementById('player-name');

    // State tracking
    let routeData = { loan: [], cash: [] };
    let completedLoan = [];
    let completedCash = [];
    let isUnlocked = false;

    // -------------------------------------------------------------------
    // FORCE UI HIDDEN ON LOAD
    // -------------------------------------------------------------------
    backdrop.classList.add('hidden');
    tablet.style.opacity = "0";
    tablet.style.pointerEvents = "none";

    // -------------------------------------------------------------------
    // LOCK SCREEN CLOCK
    // -------------------------------------------------------------------
    function updateClock() {
        const now = new Date();
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        lockTime.textContent = `${hours}:${minutes}`;
        
        const options = { weekday: 'long', month: 'long', day: 'numeric' };
        lockDate.textContent = now.toLocaleDateString('en-US', options);
    }

    // Update clock every second
    setInterval(updateClock, 1000);
    updateClock();

    // -------------------------------------------------------------------
    // FINGERPRINT UNLOCK
    // -------------------------------------------------------------------
    fingerprintBtn.addEventListener('click', () => {
        fingerprintBtn.classList.add('scanning');
        
        setTimeout(() => {
            fingerprintBtn.classList.remove('scanning');
            unlockTablet();
        }, 1500);
    });

    function unlockTablet() {
        isUnlocked = true;
        lockScreen.classList.remove('active');
        tabletMain.classList.remove('locked');
    }

    function lockTablet() {
        isUnlocked = false;
        lockScreen.classList.add('active');
        tabletMain.classList.add('locked');
    }

    // -------------------------------------------------------------------
    // NUI MESSAGE HANDLER
    // -------------------------------------------------------------------
    window.addEventListener('message', (ev) => {
        const d = ev.data;
        if (!d || !d.action) return;

        if (d.action === 'openRouteCard') {
            routeData = { 
                loan: d.loan || [], 
                cash: d.cash || [] 
            };
            
            // Use provided completion state, or reset to empty if not provided
            if (d.completedLoan !== undefined) {
                if (Array.isArray(d.completedLoan)) {
                    completedLoan = d.completedLoan;
                } else {
                    completedLoan = [];
                    for (let i = 0; i < routeData.loan.length; i++) {
                        completedLoan[i] = d.completedLoan[i] || false;
                    }
                }
            } else {
                completedLoan = [];
            }
            
            if (d.completedCash !== undefined) {
                if (Array.isArray(d.completedCash)) {
                    completedCash = d.completedCash;
                } else {
                    completedCash = [];
                    for (let i = 0; i < routeData.cash.length; i++) {
                        completedCash[i] = d.completedCash[i] || false;
                    }
                }
            } else {
                completedCash = [];
            }
            
            if (d.playerName) {
                playerNameEl.textContent = `Employee: ${d.playerName}`;
            }
            openRouteCard();
        }

        if (d.action === 'hide') {
            closeRouteCard();
        }

        if (d.action === 'updateLoanStatus') {
            if (d.index !== undefined) {
                completedLoan[d.index] = true;
                renderLoanList();
            }
        }

        if (d.action === 'updateCashStatus') {
            if (d.index !== undefined) {
                completedCash[d.index] = true;
                renderCashList();
            }
        }
    });

    // -------------------------------------------------------------------
    // OPEN ROUTE CARD
    // -------------------------------------------------------------------
    function openRouteCard() {
        renderLoanList();
        renderCashList();

        // Reset to locked state
        lockTablet();

        // Show the backdrop
        backdrop.classList.remove('hidden');

        // Restart animation cleanly
        tablet.classList.remove('slide-in');
        void tablet.offsetWidth; // reflow
        tablet.classList.add('slide-in');

        tablet.style.opacity = "1";
        tablet.style.pointerEvents = "auto";
    }

    // -------------------------------------------------------------------
    // RENDER LOAN LIST
    // -------------------------------------------------------------------
    function renderLoanList() {
        loanList.innerHTML = "";
        
        routeData.loan.forEach((stop, i) => {
            const isComplete = completedLoan[i] === true;
            const el = document.createElement('div');
            el.className = `route-item ${isComplete ? 'complete' : ''}`;
            
            const displayName = stop.name || `${stop.x.toFixed(1)}, ${stop.y.toFixed(1)}`;
            
            el.innerHTML = `
                <div class="left">
                    <div class="idx">${i + 1}</div>
                    <div class="info">
                        <div class="label">Loan Stop ${i+1}</div>
                        <div class="coord">${displayName}</div>
                    </div>
                </div>
                <div class="status ${isComplete ? 'complete' : 'pending'}">
                    ${isComplete ? 'Complete' : 'Pending'}
                </div>
                <button class="waypoint-btn" data-type="loan" data-index="${i}" ${isComplete ? 'disabled' : ''}>
                    📍 Waypoint
                </button>
            `;
            loanList.appendChild(el);
        });
    }

    // -------------------------------------------------------------------
    // RENDER CASH LIST
    // -------------------------------------------------------------------
    function renderCashList() {
        cashList.innerHTML = "";
        
        routeData.cash.forEach((stop, i) => {
            const isComplete = completedCash[i] === true;
            const el = document.createElement('div');
            el.className = `route-item ${isComplete ? 'complete' : ''}`;
            
            const displayName = stop.name || `${stop.x.toFixed(1)}, ${stop.y.toFixed(1)}`;
            
            el.innerHTML = `
                <div class="left">
                    <div class="idx">${i + 1}</div>
                    <div class="info">
                        <div class="label">Cash Stop ${i+1}</div>
                        <div class="coord">${displayName}</div>
                    </div>
                </div>
                <div class="status ${isComplete ? 'complete' : 'pending'}">
                    ${isComplete ? 'Complete' : 'Pending'}
                </div>
                <button class="waypoint-btn" data-type="cash" data-index="${i}" ${isComplete ? 'disabled' : ''}>
                    📍 Waypoint
                </button>
            `;
            cashList.appendChild(el);
        });
    }

    // -------------------------------------------------------------------
    // CLOSE ROUTE CARD
    // -------------------------------------------------------------------
    function closeRouteCard() {
        backdrop.classList.add('hidden');
        tablet.style.opacity = "0";
        tablet.style.pointerEvents = "none";
        tablet.classList.remove("slide-in");
    }

    // -------------------------------------------------------------------
    // BUTTON HANDLERS
    // -------------------------------------------------------------------
    closeBtn.addEventListener('click', () => {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            body: JSON.stringify({})
        });
        closeRouteCard();
    });

    // Handle waypoint button clicks
    document.addEventListener('click', (e) => {
        if (e.target.classList.contains('waypoint-btn')) {
            const type = e.target.getAttribute('data-type');
            const index = parseInt(e.target.getAttribute('data-index'));
            
            if (type && index !== null && !e.target.disabled) {
                fetch(`https://${GetParentResourceName()}/setWaypoint`, {
                    method: 'POST',
                    body: JSON.stringify({ type, index })
                });
            }
        }
    });

    // ESC closes UI
    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            fetch(`https://${GetParentResourceName()}/close`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            closeRouteCard();
        }
    });
})();