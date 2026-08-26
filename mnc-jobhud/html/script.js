let currentStyleIndex = 1;
let allStyles = {};

window.addEventListener("message", function(event) {
  const data = event.data;

  if (data.action === "update") {
    const d = data.data;

    // Apply theme - handle both solid colors and gradients
    if (d.style.bg.includes('gradient')) {
      document.documentElement.style.setProperty("--bg", d.style.bg);
    } else {
      document.documentElement.style.setProperty("--bg", d.style.bg);
    }
    document.documentElement.style.setProperty("--text", d.style.text);
    document.documentElement.style.setProperty("--accent", d.style.accent);

    // Apply styles and make HUD elements visible
    document.querySelectorAll(".hud-box").forEach(box => {
      box.style.background = d.style.bg;
      box.style.color = d.style.text;
      box.style.borderColor = d.style.accent + "55";
      box.classList.add("visible"); // Make HUD elements visible after style is applied
    });

    // Toggle fields with smooth transition and apply positioning
    for (const field in d.toggle) {
      const box = document.getElementById(field);
      if (box) {
        if (d.toggle[field].enabled) {
          box.classList.remove("hidden");
          box.style.display = "flex";
          
          // Apply custom positioning
          if (d.toggle[field].position) {
            const pos = d.toggle[field].position;
            // Reset all position properties first
            box.style.top = '';
            box.style.right = '';
            box.style.bottom = '';
            box.style.left = '';
            
            // Apply new positioning
            if (pos.top) box.style.top = pos.top;
            if (pos.right) box.style.right = pos.right;
            if (pos.bottom) box.style.bottom = pos.bottom;
            if (pos.left) box.style.left = pos.left;
          }
        } else {
          box.classList.add("hidden");
          setTimeout(() => {
            if (!d.toggle[field].enabled) {
              box.style.display = "none";
            }
          }, 500);
        }
      }
    }

    // Update values
    document.querySelector("#time .value").innerText = d.time;
    document.querySelector("#id .value").innerText = d.id;
    document.querySelector("#players .value").innerText = d.players;
    document.querySelector("#jobOrGang .value").innerText = d.jobOrGang;
    document.querySelector("#bank .value").innerText = "$" + d.bank.toLocaleString();
    document.querySelector("#cash .value").innerText = "$" + d.cash.toLocaleString();

    // Handle money changes with glow effects
    if (d.bankChange !== undefined && d.bankChange !== 0) {
      const bankBox = document.getElementById("bank");
      const bankChangeEl = document.querySelector("#bank .change");
      
      if (bankChangeEl && bankBox) {
        bankChangeEl.innerText = (d.bankChange >= 0 ? "+" : "") + "$" + d.bankChange.toLocaleString();
        bankChangeEl.className = "change " + (d.bankChange >= 0 ? "added show" : "removed show");
        
        // Add glow effect to the entire bank box
        if (d.bankChange >= 0) {
          bankBox.classList.add("money-gain-glow");
          setTimeout(() => bankBox.classList.remove("money-gain-glow"), 2000);
        } else {
          bankBox.classList.add("money-loss-glow");
          setTimeout(() => bankBox.classList.remove("money-loss-glow"), 2000);
        }
        
        setTimeout(() => {
          bankChangeEl.className = "change";
        }, 10000); // Hide after 10 seconds
      }
    }
    
    if (d.cashChange !== undefined && d.cashChange !== 0) {
      const cashBox = document.getElementById("cash");
      const cashChangeEl = document.querySelector("#cash .change");
      
      if (cashChangeEl && cashBox) {
        cashChangeEl.innerText = (d.cashChange >= 0 ? "+" : "") + "$" + d.cashChange.toLocaleString();
        cashChangeEl.className = "change " + (d.cashChange >= 0 ? "added show" : "removed show");
        
        // Add glow effect to the entire cash box
        if (d.cashChange >= 0) {
          cashBox.classList.add("money-gain-glow");
          setTimeout(() => cashBox.classList.remove("money-gain-glow"), 2000);
        } else {
          cashBox.classList.add("money-loss-glow");
          setTimeout(() => cashBox.classList.remove("money-loss-glow"), 2000);
        }
        
        setTimeout(() => {
          cashChangeEl.className = "change";
        }, 10000); // Hide after 10 seconds
      }
    }

    // Store current style index if provided
    if (d.currentStyleIndex) {
      currentStyleIndex = d.currentStyleIndex;
      selectedStyleIndex = d.currentStyleIndex;
    }
  }

  if (data.action === "effect") {
    const box = document.getElementById(data.field);
    if (box) {
      box.classList.add("effect");
      setTimeout(() => box.classList.remove("effect"), 400);
    }
  }

  if (data.action === "hide") {
    document.querySelectorAll(".hud-box").forEach(box => {
      box.classList.remove("visible");
      box.classList.add("hidden");
      setTimeout(() => {
        box.style.display = "none";
      }, 500);
    });
  }

  if (data.action === "openStyleSelector") {
    // Existing style selector logic (unchanged)
    document.querySelectorAll(".hud-box").forEach(box => {
      if (!box.classList.contains("visible")) {
        box.classList.add("hidden");
        box.style.display = "none";
      }
    });
  }

  if (data.action === "openHudHelp") {
    const modal = document.getElementById("hudHelpModal");
    const stylesList = document.getElementById("stylesList");
    const guide = document.getElementById("hudGuide");

    stylesList.innerHTML = "";
    data.styles.forEach(s => {
      const card = document.createElement("div");
      card.className = "style-card";
      card.style.background = s.bg;
      card.style.color = s.text;
      card.style.borderColor = s.accent;
      card.innerHTML = `<strong>${s.index}. ${s.name}</strong>`;
      stylesList.appendChild(card);
    });

    guide.innerText = data.guide;
    modal.style.display = "flex";
  }

  if (data.action === "showNotification") {
    const notificationContainer = document.getElementById("notificationContainer") || createNotificationContainer();
    const notification = document.createElement("div");
    notification.className = `hud-box notification ${data.type}`;
    notification.style.background = data.style.bg;
    notification.style.color = data.style.text;
    notification.style.borderColor = data.style.accent + "55";
    notification.style.top = "20px";
    notification.style.right = "20px";
    notification.style.opacity = "0";
    notification.innerHTML = `<span class="value">${data.message}</span>`;
    
    notificationContainer.appendChild(notification);
    
    // Fade in
    setTimeout(() => {
      notification.style.opacity = "1";
      notification.style.transition = "opacity 0.5s ease";
    }, 100);

    // Fade out and remove after 5 seconds
    setTimeout(() => {
      notification.style.opacity = "0";
      setTimeout(() => {
        notification.remove();
      }, 500);
    }, 5000);
  }
});

// Create notification container if it doesn't exist
function createNotificationContainer() {
  const container = document.createElement("div");
  container.id = "notificationContainer";
  container.style.position = "fixed";
  container.style.top = "0";
  container.style.right = "0";
  container.style.zIndex = "1000";
  document.body.appendChild(container);
  return container;
}

// Close modal with button
document.getElementById("closeHudHelp").addEventListener("click", () => {
  document.getElementById("hudHelpModal").style.display = "none";
  fetch(`https://${GetParentResourceName()}/closeHudHelp`, { method: "POST" });
});

// Optional: close modal with ESC
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    const modal = document.getElementById("hudHelpModal");
    if (modal.style.display === "flex") {
      modal.style.display = "none";
      fetch(`https://${GetParentResourceName()}/closeHudHelp`, { method: "POST" });
    }
  }
});