window.addEventListener("message", (event) => {
    let data = event.data;
    console.log("[mnc-weaponui] Received NUI message:", JSON.stringify(data));

    if (data.action === "show") {
        const ui = document.getElementById("weapon-ui");
        console.log("[mnc-weaponui] Showing UI with data:", data);
        ui.style.display = "flex"; // Ensure display is set to flex
        ui.classList.remove("hidden");
        ui.classList.add("visible");
        document.getElementById("weapon-name").innerText = data.weapon || "Unknown";
        document.getElementById("weapon-ammo").innerText = "Ammo: " + (data.ammo || 0);
        document.getElementById("weapon-img").src = data.image || "";
        
        // Switch style
        const styleIndex = data.style && data.style >= 1 && data.style <= 25 ? data.style : 1;
        console.log("[mnc-weaponui] Setting style to: style" + styleIndex + ".css");
        document.getElementById("theme").setAttribute("href", `style${styleIndex}.css`);

        // Apply position/size
        ui.style.left = '';
        ui.style.right = '';
        ui.style.top = '';
        ui.style.bottom = '';
        ui.style.width = data.ui && data.ui.width ? data.ui.width : '150px';
        ui.style.height = data.ui && data.ui.height ? data.ui.height : 'auto';
        if (data.ui && data.ui.x) ui.style.left = data.ui.x;
        if (data.ui && data.ui.y) ui.style.top = data.ui.y;
        console.log("[mnc-weaponui] UI position set to: x=" + data.ui.x + ", y=" + data.ui.y);
    } else if (data.action === "hide") {
        console.log("[mnc-weaponui] Hiding UI");
        const ui = document.getElementById("weapon-ui");
        ui.classList.remove("visible");
        ui.classList.add("hidden");
        setTimeout(() => {
            ui.style.display = "none";
        }, 500);
    } else if (data.action === "notify") {
        console.log("[mnc-weaponui] Showing notification:", data);
        showNotification(data);
    }
});

function showNotification(data) {
    const notifyUI = document.getElementById("notify-ui");
    const notifyTitle = document.getElementById("notify-title");
    const notifyDescription = document.getElementById("notify-description");
    
    // Set notification content
    notifyTitle.innerText = data.title || "Notification";
    notifyDescription.innerText = data.description || "";
    
    // Apply style from config
    const styleIndex = data.style && data.style >= 1 && data.style <= 25 ? data.style : 1;
    applyNotificationStyle(notifyUI, styleIndex);
    
    // Apply position
    notifyUI.style.left = '';
    notifyUI.style.right = '';
    notifyUI.style.top = '';
    notifyUI.style.bottom = '';
    if (data.ui && data.ui.x) notifyUI.style.left = data.ui.x;
    if (data.ui && data.ui.y) notifyUI.style.top = data.ui.y;
    if (data.ui && data.ui.width) notifyUI.style.width = data.ui.width;
    if (data.ui && data.ui.height) notifyUI.style.height = data.ui.height;
    
    // Set type-specific styling
    notifyUI.classList.remove("success", "error");
    if (data.type === "success") {
        notifyUI.classList.add("success");
    } else if (data.type === "error") {
        notifyUI.classList.add("error");
    }
    
    // Show notification
    notifyUI.style.display = "flex";
    notifyUI.classList.remove("hidden");
    notifyUI.classList.add("visible");
    
    // Auto hide after duration
    const duration = (data.ui && data.ui.duration) ? data.ui.duration : 3000;
    setTimeout(() => {
        notifyUI.classList.remove("visible");
        notifyUI.classList.add("hidden");
        setTimeout(() => {
            notifyUI.style.display = "none";
        }, 500);
    }, duration);
}

function applyNotificationStyle(element, styleIndex) {
    // Style mapping based on config.lua styles
    const styles = {
        1: { bg: "rgba(30,30,46,0.5)", text: "#ffffff", accent: "rgba(76, 175, 80, 0.3)" },
        2: { bg: "rgba(44,44,84,0.6)", text: "#f1c40f", accent: "rgba(231, 76, 60, 0.3)" },
        3: { bg: "rgba(20,20,20,0.4)", text: "#0be881", accent: "rgba(11, 232, 129, 0.3)" },
        4: { bg: "rgba(47,53,66,0.7)", text: "#70a1ff", accent: "rgba(30, 144, 255, 0.3)" },
        5: { bg: "rgba(87,96,111,0.7)", text: "#ffa502", accent: "rgba(255, 165, 2, 0.3)" },
        6: { bg: "linear-gradient(135deg, rgba(15,15,35,0.9), rgba(25,25,55,0.7))", text: "#00ffff", accent: "rgba(255, 0, 255, 0.3)" },
        7: { bg: "linear-gradient(45deg, rgba(10,10,10,0.95), rgba(30,0,30,0.8))", text: "#b19cd9", accent: "rgba(255, 107, 107, 0.3)" },
        8: { bg: "radial-gradient(circle, rgba(0,20,40,0.9), rgba(0,0,20,0.95))", text: "#64ffda", accent: "rgba(255, 171, 0, 0.3)" },
        9: { bg: "linear-gradient(180deg, rgba(15,0,30,0.9), rgba(30,0,15,0.8))", text: "#ff4081", accent: "rgba(233, 30, 99, 0.3)" },
        10: { bg: "conic-gradient(from 180deg, rgba(0,0,0,0.95), rgba(20,20,80,0.8), rgba(0,0,0,0.95))", text: "#00e676", accent: "rgba(118, 255, 3, 0.3)" },
        11: { bg: "linear-gradient(90deg, rgba(40,0,0,0.9), rgba(80,20,0,0.8))", text: "#ffccbc", accent: "rgba(255, 87, 34, 0.3)" },
        12: { bg: "radial-gradient(ellipse, rgba(0,30,60,0.9), rgba(0,0,30,0.95))", text: "#81d4fa", accent: "rgba(3, 169, 244, 0.3)" },
        13: { bg: "linear-gradient(225deg, rgba(30,30,0,0.9), rgba(60,40,0,0.8))", text: "#fff59d", accent: "rgba(251, 192, 45, 0.3)" },
        14: { bg: "conic-gradient(from 90deg, rgba(20,0,40,0.95), rgba(40,0,80,0.8), rgba(20,0,40,0.95))", text: "#ce93d8", accent: "rgba(156, 39, 176, 0.3)" },
        15: { bg: "linear-gradient(135deg, rgba(0,40,40,0.95), rgba(0,60,60,0.85), rgba(0,20,40,0.9))", text: "#4dd0e1", accent: "rgba(0, 172, 193, 0.3)" },
        16: { bg: "linear-gradient(45deg, rgba(60,0,20,0.9), rgba(100,20,0,0.8), rgba(80,40,0,0.85))", text: "#ffab40", accent: "rgba(255, 109, 0, 0.3)" },
        17: { bg: "radial-gradient(circle at 30% 70%, rgba(0,40,80,0.9), rgba(10,10,40,0.95))", text: "#b3e5fc", accent: "rgba(2, 119, 189, 0.3)" },
        18: { bg: "linear-gradient(180deg, rgba(20,40,0,0.9), rgba(40,60,0,0.8), rgba(60,80,0,0.85))", text: "#c0ff8c", accent: "rgba(118, 255, 3, 0.3)" },
        19: { bg: "conic-gradient(from 270deg, rgba(40,0,60,0.95), rgba(80,20,100,0.8), rgba(60,0,80,0.9))", text: "#e1bee7", accent: "rgba(171, 71, 188, 0.3)" },
        20: { bg: "radial-gradient(ellipse at 80% 20%, rgba(60,0,0,0.95), rgba(40,0,0,0.9), rgba(20,0,0,0.95))", text: "#ffcdd2", accent: "rgba(211, 47, 47, 0.3)" },
        21: { bg: "linear-gradient(135deg, rgba(0,20,40,0.9), rgba(20,0,60,0.8), rgba(40,0,40,0.85))", text: "#64ffda", accent: "rgba(233, 30, 99, 0.3)" },
        22: { bg: "linear-gradient(90deg, rgba(40,40,50,0.9), rgba(60,60,70,0.8), rgba(50,50,60,0.85))", text: "#eceff1", accent: "rgba(96, 125, 139, 0.3)" },
        23: { bg: "radial-gradient(circle at 10% 80%, rgba(60,20,0,0.9), rgba(40,40,0,0.8), rgba(20,60,0,0.85))", text: "#fff8e1", accent: "rgba(255, 143, 0, 0.3)" },
        24: { bg: "conic-gradient(from 0deg, rgba(0,0,20,0.98), rgba(20,0,40,0.85), rgba(0,20,60,0.9))", text: "#b39ddb", accent: "rgba(63, 81, 181, 0.3)" },
        25: { bg: "linear-gradient(225deg, rgba(20,0,40,0.95), rgba(0,40,60,0.8), rgba(40,20,0,0.9))", text: "#80cbc4", accent: "rgba(0, 105, 92, 0.3)" }
    };
    
    const style = styles[styleIndex] || styles[1];
    element.style.setProperty('--bg', style.bg);
    element.style.setProperty('--text', style.text);
    element.style.setProperty('--accent', style.accent);
    element.style.background = style.bg;
    element.style.color = style.text;
    element.style.borderColor = style.accent;
}