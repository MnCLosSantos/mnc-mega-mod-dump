// html/script.js - COMPLETELY FIXED VERSION
// Helper to get parent resource name
function GetParentResourceName() {
    // In FiveM, NUI files are served from nui://game/
    // We need to extract the resource name from the full path
    let resourceName = 'mnc-driftscore'; // Fallback
    
    if (window.location.pathname) {
        const pathParts = window.location.pathname.split('/');
        // Path is usually /@resource_name/html/file.html
        for (let i = 0; i < pathParts.length; i++) {
            if (pathParts[i].startsWith('@')) {
                resourceName = pathParts[i].substring(1);
                break;
            }
        }
    }
    
    return resourceName;
}

let currentStyleIndex = 1;
let currentStyleName = "Classic Green";
let allStyles = {};

// Leaderboard state
let lbData = { weekly: [], monthly: [], alltime: [], resets: {} };
let lbActivePeriod = 'weekly';
let lbCountdownHandle = null;

// Reputation / Drift Coins (persistent, not items - just numbers tracked server-side)
let currentReputation = 0;
let currentCoins = 0;
let storeCatalog = [];


// Main message handler
window.addEventListener("message", function(event) {
  const data = event.data;
  

  if (data.action === "update") {
    const d = data.data || {};

    // Apply style if it exists
    if (d.style && d.style.bg && d.style.text && d.style.accent) {
        
        document.documentElement.style.setProperty("--bg", d.style.bg);
        document.documentElement.style.setProperty("--text", d.style.text);
        document.documentElement.style.setProperty("--accent", d.style.accent);

        const hudBoxes = document.querySelectorAll(".hud-box:not(.notification)");
        hudBoxes.forEach(box => {
            box.style.background = d.style.bg;
            box.style.color = d.style.text;
            box.style.borderColor = d.style.accent + "55";
        });

        if (d.style.name) {
            currentStyleName = d.style.name;
        }
    }

    // Update toggles and positions
    if (d.toggle) {
        for (const field in d.toggle) {
            const box = document.getElementById(field);
            if (box) {
                if (d.toggle[field]?.enabled) {
                    box.classList.remove("hidden");
                    box.style.display = "flex";
                    
                    const pos = d.toggle[field].position || {};
                    box.style.top    = pos.top    || '';
                    box.style.right  = pos.right  || '';
                    box.style.bottom = pos.bottom || '';
                    box.style.left   = pos.left   || '';
                } else {
                    box.classList.add("hidden");
                    setTimeout(() => { 
                        box.style.display = "none"; 
                    }, 500);
                }
            }
        }
    }

    // Update values
    const scoreEl = document.querySelector("#score .value");
    const multEl = document.querySelector("#multiplier .value");
    const comboEl = document.querySelector("#combo .value");
    
    if (scoreEl) scoreEl.innerText = (d.score ?? 0).toLocaleString();
    if (multEl) multEl.innerText = d.multiplier || "x1.0";
    if (comboEl) comboEl.innerText = d.combo || "";

    if (typeof d.reputation === 'number') currentReputation = d.reputation;
    if (typeof d.coins === 'number') currentCoins = d.coins;
    updateCurrencyDisplays();

    if (d.currentStyleIndex) {
        currentStyleIndex = d.currentStyleIndex;
    }
  }

  if (data.action === "currencyUpdate") {
    const d = data.data || {};

    if (typeof d.reputation === 'number') currentReputation = d.reputation;
    if (typeof d.coins === 'number') currentCoins = d.coins;

    updateCurrencyDisplays();
    renderStoreGrid();
  }

  if (data.action === "show") {
    const hudBoxes = document.querySelectorAll(".hud-box:not(.notification)");
    hudBoxes.forEach(box => {
      box.style.display = "flex";
      box.classList.remove("hidden");
      box.offsetHeight;
      box.classList.add("visible");
    });
  }

  if (data.action === "hide") {
    const hudBoxes = document.querySelectorAll(".hud-box:not(.notification)");
    hudBoxes.forEach(box => {
      box.classList.remove("visible");
      box.classList.add("hidden");
      setTimeout(() => {
        box.style.display = "none";
      }, 500);
    });
  }

  if (data.action === "showNotification") {
    const container = document.getElementById("notificationContainer") || createNotificationContainer();
    const notification = document.createElement("div");
    notification.className = `hud-box notification ${data.type}`;
    
    if (data.style) {
        notification.style.background = data.style.bg;
        notification.style.color = data.style.text;
        notification.style.borderColor = data.style.accent + "55";
    }
    
    notification.style.position = "fixed";
    notification.style.top = (20 + container.children.length * 70) + "px";
    notification.style.right = "20px";
    notification.style.opacity = "0";
    notification.style.display = "flex";
    notification.innerHTML = `<span class="value">${data.message}</span>`;
    
    container.appendChild(notification);
    
    setTimeout(() => {
      notification.style.opacity = "1";
      notification.style.transition = "opacity 0.3s ease, top 0.3s ease";
    }, 50);

    setTimeout(() => {
      notification.style.opacity = "0";
      setTimeout(() => {
          notification.remove();
          Array.from(container.children).forEach((notif, index) => {
              notif.style.top = (20 + index * 70) + "px";
          });
      }, 300);
    }, 3000);
  }

  if (data.action === "openHelp") {
    
    if (data.styleName) {
      currentStyleName = data.styleName;
    }
    if (data.allStyles) {
      // Lua sends 1-indexed table, JS receives 0-indexed array
      // We need to convert it to 1-indexed object for consistency
      let convertedStyles = {};
      
      // Check if it's an array (0-indexed) or object (already 1-indexed)
      if (Array.isArray(data.allStyles)) {
        data.allStyles.forEach((style, index) => {
          convertedStyles[index + 1] = style;
        });
      } else {
        convertedStyles = data.allStyles;
      }
      
      allStyles = convertedStyles;
      
      // Verify styles are mapped correctly
      for (let i = 1; i <= 5; i++) {
        if (allStyles[i]) {
        }
      }
    }
    if (data.currentStyleIndex) {
      currentStyleIndex = data.currentStyleIndex;
    }
    openHelpModal();
  }

  if (data.action === "styleChanged") {
    currentStyleIndex = data.newStyle;
    currentStyleName = data.styleName;
    
    const styleNameEl = document.getElementById("currentStyleName");
    if (styleNameEl) {
      styleNameEl.textContent = data.styleName;
    }
    
    // Re-render the grid to update the active indicator
    if (Object.keys(allStyles).length > 0) {
      renderStyleGrid();
    }
  }

  if (data.action === "openLeaderboard") {
    if (data.style) {
      document.documentElement.style.setProperty("--bg", data.style.bg);
      document.documentElement.style.setProperty("--text", data.style.text);
      document.documentElement.style.setProperty("--accent", data.style.accent);
    }

    lbData = normalizeLeaderboardData(data.data || {});

    currentReputation = typeof data.reputation === 'number' ? data.reputation : 0;
    currentCoins = typeof data.coins === 'number' ? data.coins : 0;
    storeCatalog = normalizeStoreCatalog(data.store);

    updateCurrencyDisplays();
    openLeaderboardModal();
  }
});

// Lua tables that are empty end up as arrays ([]) instead of objects ({}) once
// JSON-encoded. Normalize everything into predictable shapes for the renderer.
function normalizeLeaderboardData(raw) {
    const normalized = { weekly: [], monthly: [], alltime: [], resets: {} };

    ['weekly', 'monthly', 'alltime'].forEach(period => {
        normalized[period] = Array.isArray(raw[period]) ? raw[period] : Object.values(raw[period] || {});
    });

    normalized.resets = Array.isArray(raw.resets) ? {} : (raw.resets || {});
    return normalized;
}

// Config.Store is a Lua array; empty tables serialize as {} instead of [].
function normalizeStoreCatalog(raw) {
    if (Array.isArray(raw)) return raw;
    if (raw && typeof raw === 'object') return Object.values(raw);
    return [];
}

function createNotificationContainer() {
  const container = document.createElement("div");
  container.id = "notificationContainer";
  container.style.position = "fixed";
  container.style.top = "0";
  container.style.right = "0";
  container.style.zIndex = "1000";
  container.style.pointerEvents = "none";
  document.body.appendChild(container);
  return container;
}

function renderStyleGrid() {
  const styleGrid = document.getElementById("styleGrid");
  if (!styleGrid || Object.keys(allStyles).length === 0) {
    return;
  }
  

  styleGrid.innerHTML = '';
  
  // Lua tables are 1-indexed, so we need to iterate properly
  for (let luaIndex = 1; luaIndex <= Object.keys(allStyles).length; luaIndex++) {
    const style = allStyles[luaIndex];
    if (!style) continue;
    
    const styleCard = document.createElement('div');
    const isActive = currentStyleIndex === luaIndex;
    
    
    styleCard.className = 'style-card';
    styleCard.dataset.styleIndex = luaIndex;
    
    styleCard.style.cssText = `
      padding: 12px;
      border-radius: 8px;
      background: ${style.bg};
      border: 2px solid ${style.accent}55;
      cursor: pointer;
      transition: all 0.2s ease;
      ${isActive ? 'box-shadow: 0 0 20px ' + style.accent + '; border-width: 3px;' : ''}
    `;
    
    styleCard.innerHTML = `
      <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 6px;">
        <span style="font-weight: bold; color: ${style.accent};">#${luaIndex}</span>
        <span style="color: ${style.text}; font-weight: 600;">${style.name}</span>
        ${isActive ? '<span style="color: ' + style.accent + '; margin-left: auto; font-weight: bold;">✓ ACTIVE</span>' : ''}
      </div>
      <div style="color: ${style.text}; font-size: 0.85em; opacity: 0.8;">${style.description || ''}</div>
      <div style="margin-top: 8px; display: flex; gap: 6px;">
        <div style="width: 20px; height: 20px; border-radius: 4px; background: ${style.bg}; border: 1px solid ${style.text}33;" title="Background"></div>
        <div style="width: 20px; height: 20px; border-radius: 4px; background: ${style.text}; border: 1px solid ${style.text}33;" title="Text"></div>
        <div style="width: 20px; height: 20px; border-radius: 4px; background: ${style.accent}; border: 1px solid ${style.text}33;" title="Accent"></div>
      </div>
    `;
    
    // Click handler
    styleCard.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      const styleIndex = parseInt(this.dataset.styleIndex);

      
      const resourceName = GetParentResourceName();
      const url = `https://${resourceName}/changeStyle`;

      
      // Don't try to parse response - FiveM NUI doesn't return proper JSON
      fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ style: styleIndex })
      }).catch(err => {
        // This error is expected in FiveM - the callback still executes

      });
      

    });
    
    // Hover effects
    styleCard.addEventListener('mouseenter', function() {
      this.style.transform = 'scale(1.05)';
      this.style.boxShadow = `0 0 20px ${style.accent}`;
    });
    
    styleCard.addEventListener('mouseleave', function() {
      this.style.transform = 'scale(1)';
      this.style.boxShadow = isActive ? `0 0 20px ${style.accent}` : 'none';
    });
    
    styleGrid.appendChild(styleCard);
  }
  

}

// Modal handling
const helpModal = document.getElementById("helpModal");
const closeModalBtn = document.getElementById("closeModal");

function openHelpModal() {
  if (!helpModal) {

    return;
  }
  

  
  const styleNameEl = document.getElementById("currentStyleName");
  if (styleNameEl) {
    styleNameEl.textContent = currentStyleName;
  }

  renderStyleGrid();

  helpModal.style.display = "flex";
  document.body.style.pointerEvents = "all";
  

}

function closeHelpModal() {
  if (!helpModal) return;
  

  helpModal.style.display = "none";
  document.body.style.pointerEvents = "none";
  
  notifyNuiClosed();
}

function notifyNuiClosed() {
  const resourceName = GetParentResourceName();
  const url = `https://${resourceName}/closeModal`;

  // Tell FiveM to close NUI focus - don't try to parse response
  fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
  }).catch(err => {
      // This error is expected in FiveM - the callback still executes
  });
}

if (closeModalBtn) {
  closeModalBtn.addEventListener('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    closeHelpModal();
  });
}

if (helpModal) {
  helpModal.addEventListener('click', function(e) {
    if (e.target === helpModal) {
      closeHelpModal();
    }
  });
}

//
// ─── LEADERBOARD ────────────────────────────────────────────────────────────
//

const leaderboardModal = document.getElementById("leaderboardModal");
const closeLeaderboardBtn = document.getElementById("closeLeaderboard");
const lbTabs = document.querySelectorAll(".lb-tab");

function openLeaderboardModal() {
  if (!leaderboardModal) return;

  lbActivePeriod = 'weekly';
  lbTabs.forEach(tab => tab.classList.toggle('active', tab.dataset.period === lbActivePeriod));

  showLeaderboardView();
  renderLeaderboardTable(lbActivePeriod);

  leaderboardModal.style.display = "flex";
  document.body.style.pointerEvents = "all";
}

// Toggle between the ranking table view and the Store view within the same modal
function showStoreView() {
  const tableWrap = document.getElementById("lbTableWrap");
  const resetTimer = document.getElementById("lbResetTimer");
  const yourRank = document.getElementById("lbYourRank");
  const storeWrap = document.getElementById("lbStoreWrap");

  if (tableWrap) tableWrap.style.display = 'none';
  if (resetTimer) resetTimer.style.display = 'none';
  if (yourRank) yourRank.style.display = 'none';
  if (storeWrap) storeWrap.style.display = 'block';

  stopLbCountdown();
  renderStoreGrid();
}

function showLeaderboardView() {
  const tableWrap = document.getElementById("lbTableWrap");
  const resetTimer = document.getElementById("lbResetTimer");
  const storeWrap = document.getElementById("lbStoreWrap");

  if (tableWrap) tableWrap.style.display = '';
  if (resetTimer) resetTimer.style.display = '';
  if (storeWrap) storeWrap.style.display = 'none';

  startLbCountdown();
}

function closeLeaderboardModal() {
  if (!leaderboardModal) return;

  leaderboardModal.style.display = "none";
  document.body.style.pointerEvents = "none";
  stopLbCountdown();

  notifyNuiClosed();
}

function periodLabel(period) {
  if (period === 'weekly') return 'Weekly';
  if (period === 'monthly') return 'Monthly';
  return 'All-Time';
}

function medalForRank(rank) {
  if (rank === 1) return { emoji: '🥇', cls: 'lb-gold' };
  if (rank === 2) return { emoji: '🥈', cls: 'lb-silver' };
  if (rank === 3) return { emoji: '🥉', cls: 'lb-bronze' };
  return { emoji: '', cls: '' };
}

function renderLeaderboardTable(period) {
  const body = document.getElementById("lbTableBody");
  if (!body) return;

  const rows = lbData[period] || [];

  if (rows.length === 0) {
    body.innerHTML = `<tr><td colspan="3" class="lb-empty">No scores yet — go drift!</td></tr>`;
  } else {
    body.innerHTML = rows.map((row, index) => {
      const rank = index + 1;
      const medal = medalForRank(rank);
      const score = Number(row.score || 0).toLocaleString();
      const name = row.player_name || row.name || 'Unknown';

      return `
        <tr class="${medal.cls}">
          <td class="lb-rank">${medal.emoji || '#' + rank}</td>
          <td class="lb-name">${name}</td>
          <td class="lb-score">${score}</td>
        </tr>
      `;
    }).join('');
  }

  renderYourRank(period);
  renderResetTimer(period);
}

function renderYourRank(period) {
  const el = document.getElementById("lbYourRank");
  if (!el) return;

  const resets = lbData.resets || {};
  const yourRank = resets[period + '_your_rank'];
  const yourScore = resets[period + '_your_score'];

  if (yourRank && yourScore !== undefined && yourScore !== null) {
    el.innerHTML = `Your rank: <strong>#${yourRank}</strong> &nbsp;•&nbsp; Best score: <strong>${Number(yourScore).toLocaleString()}</strong>`;
    el.style.display = 'block';
  } else {
    el.innerHTML = '';
    el.style.display = 'none';
  }
}

function formatCountdown(seconds) {
  if (seconds <= 0) return 'resetting soon...';
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0 || days > 0) parts.push(`${hours}h`);
  parts.push(`${minutes}m`);

  return parts.join(' ');
}

function renderResetTimer(period) {
  const el = document.getElementById("lbResetTimer");
  if (!el) return;

  if (period === 'alltime') {
    el.innerHTML = `<i class="fas fa-infinity"></i> All-Time board never resets`;
    return;
  }

  const resets = lbData.resets || {};
  const resetAt = resets[period + '_reset_at'];

  if (!resetAt) {
    el.innerHTML = '';
    return;
  }

  const secondsLeft = resetAt - Math.floor(Date.now() / 1000);
  el.innerHTML = `<i class="fas fa-clock"></i> ${periodLabel(period)} board resets in ${formatCountdown(secondsLeft)}`;
}

function startLbCountdown() {
  stopLbCountdown();
  lbCountdownHandle = setInterval(() => {
    renderResetTimer(lbActivePeriod);
  }, 1000);
}

function stopLbCountdown() {
  if (lbCountdownHandle) {
    clearInterval(lbCountdownHandle);
    lbCountdownHandle = null;
  }
}

lbTabs.forEach(tab => {
  tab.addEventListener('click', function() {
    lbTabs.forEach(t => t.classList.remove('active'));
    this.classList.add('active');
    lbActivePeriod = this.dataset.period;

    if (lbActivePeriod === 'store') {
      showStoreView();
    } else {
      showLeaderboardView();
      renderLeaderboardTable(lbActivePeriod);
    }
  });
});

if (closeLeaderboardBtn) {
  closeLeaderboardBtn.addEventListener('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    closeLeaderboardModal();
  });
}

if (leaderboardModal) {
  leaderboardModal.addEventListener('click', function(e) {
    if (e.target === leaderboardModal) {
      closeLeaderboardModal();
    }
  });
}

//
// ─── REPUTATION / DRIFT COINS / STORE ──────────────────────────────────────
//

// Keep the HUD boxes and the driftboard currency bar in sync with the latest
// known Reputation/Drift Coin totals.
function updateCurrencyDisplays() {
  const repHud = document.querySelector("#reputation .value");
  const coinHud = document.querySelector("#coins .value");
  if (repHud) repHud.innerText = Number(currentReputation || 0).toLocaleString();
  if (coinHud) coinHud.innerText = Number(currentCoins || 0).toLocaleString();

  const lbRep = document.getElementById("lbRepValue");
  const lbCoin = document.getElementById("lbCoinValue");
  if (lbRep) lbRep.innerText = Number(currentReputation || 0).toLocaleString();
  if (lbCoin) lbCoin.innerText = Number(currentCoins || 0).toLocaleString();
}

function renderStoreGrid() {
  const grid = document.getElementById("lbStoreGrid");
  if (!grid) return;

  if (!storeCatalog || storeCatalog.length === 0) {
    grid.innerHTML = `<div class="lb-empty">No store items configured</div>`;
    return;
  }

  grid.innerHTML = '';

  storeCatalog.forEach(entry => {
    const price = Number(entry.price || 0);
    const affordable = currentCoins >= price;
    const typeLabel = entry.type === 'bank' ? 'Bank Reward' : 'Item';

    const card = document.createElement('div');
    card.className = 'store-card';
    card.innerHTML = `
      <div class="store-card-icon"><i class="fas ${entry.icon || 'fa-gift'}"></i></div>
      <div class="store-card-body">
        <div class="store-card-name">${entry.name || 'Unknown'}</div>
        <div class="store-card-type">${typeLabel}</div>
        <div class="store-card-desc">${entry.description || ''}</div>
      </div>
      <div class="store-card-footer">
        <span class="store-card-price"><i class="fas fa-coins"></i> ${price.toLocaleString()}</span>
        <button class="store-buy-btn" ${affordable ? '' : 'disabled'}>${affordable ? 'Buy' : 'Not enough'}</button>
      </div>
    `;

    const buyBtn = card.querySelector('.store-buy-btn');
    if (buyBtn) {
      buyBtn.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        purchaseStoreItem(entry.id, buyBtn);
      });
    }

    grid.appendChild(card);
  });
}

function purchaseStoreItem(itemId, btnEl) {
  const resourceName = GetParentResourceName();
  const url = `https://${resourceName}/purchaseItem`;

  if (btnEl) {
    btnEl.disabled = true;
    btnEl.innerText = '...';
  }

  fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ itemId })
  })
    .then(res => res.json())
    .then(result => {
      if (result && result.success) {
        if (typeof result.reputation === 'number') currentReputation = result.reputation;
        if (typeof result.coins === 'number') currentCoins = result.coins;
        updateCurrencyDisplays();
      }
      // Re-render regardless of outcome so button state/label reset correctly
      renderStoreGrid();
    })
    .catch(() => {
      renderStoreGrid();
    });
}

// ESC key handling
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' || e.keyCode === 27) {
        if (helpModal && helpModal.style.display === 'flex') {
            e.preventDefault();
            e.stopPropagation();

            closeHelpModal();
        } else if (leaderboardModal && leaderboardModal.style.display === 'flex') {
            e.preventDefault();
            e.stopPropagation();

            closeLeaderboardModal();
        }
    }
});

// Debug - log when document is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {

    });
} else {

}