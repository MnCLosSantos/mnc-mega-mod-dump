document.addEventListener('DOMContentLoaded', function() {
    let originalModTier = '1';
    let originalIsBusiness = 'false';
    let isCurrentlyInsured = false;
    let isExpired = false;
    let currentVehicleData = {};
    let isCheckMode = false;
    let isRegistered = false;
    let isInspected = false;
    let isCheckInspectionMode = false;
    let isCheckRegistrationMode = false;
    let selectedInsuranceCompany = 'MNC'; // Default insurance company

    // Color mapping for vehicle colors
    const colorNames = {
        0: "Metallic Black", 1: "Metallic Graphite Black", 2: "Metallic Black Steel", 3: "Metallic Dark Silver", 4: "Metallic Silver", 5: "Metallic Blue Silver", 6: "Metallic Steel Gray", 7: "Metallic Shadow Silver", 8: "Metallic Stone Silver", 9: "Metallic Midnight Silver", 10: "Metallic Gun Metal", 11: "Metallic Anthracite Gray",
        12: "Matte Black", 13: "Matte Gray", 14: "Matte Light Gray", 15: "Util Black", 16: "Util Black Poly", 17: "Util Dark Silver", 18: "Util Silver", 19: "Util Gun Metal", 20: "Util Shadow Silver", 21: "Worn Black", 22: "Worn Graphite", 23: "Worn Silver Gray", 24: "Worn Silver", 25: "Worn Blue Silver", 26: "Worn Shadow Silver",
        27: "Metallic Red", 28: "Metallic Torino Red", 29: "Metallic Formula Red", 30: "Metallic Blaze Red", 31: "Metallic Graceful Red", 32: "Metallic Garnet Red", 33: "Metallic Desert Red", 34: "Metallic Cabernet Red", 35: "Metallic Candy Red", 36: "Metallic Sunrise Orange", 37: "Metallic Classic Gold", 38: "Metallic Orange",
        39: "Matte Red", 40: "Matte Dark Red", 41: "Matte Orange", 42: "Matte Yellow", 43: "Util Red", 44: "Util Bright Red", 45: "Util Garnet Red", 46: "Worn Red", 47: "Worn Golden Red", 48: "Worn Dark Red",
        49: "Metallic Dark Green", 50: "Metallic Racing Green", 51: "Metallic Sea Green", 52: "Metallic Olive Green", 53: "Metallic Green", 54: "Metallic Gasoline Blue Green", 55: "Matte Lime Green", 56: "Util Dark Green", 57: "Util Green", 58: "Worn Dark Green", 59: "Worn Green", 60: "Worn Sea Wash",
        61: "Metallic Midnight Blue", 62: "Metallic Dark Blue", 63: "Metallic Saxony Blue", 64: "Metallic Blue", 65: "Metallic Mariner Blue", 66: "Metallic Harbor Blue", 67: "Metallic Diamond Blue", 68: "Metallic Surf Blue", 69: "Metallic Nautical Blue", 70: "Metallic Bright Blue", 71: "Metallic Purple Blue", 72: "Metallic Spinnaker Blue", 73: "Metallic Ultra Blue", 74: "Metallic Bright Blue",
        75: "Util Dark Blue", 76: "Util Midnight Blue", 77: "Util Blue", 78: "Util Sea Foam Blue", 79: "Util Lightning Blue", 80: "Util Maui Blue Poly", 81: "Util Bright Blue", 82: "Matte Dark Blue", 83: "Matte Blue", 84: "Matte Midnight Blue", 85: "Worn Dark Blue", 86: "Worn Blue", 87: "Worn Light Blue",
        88: "Metallic Taxi Yellow", 89: "Metallic Race Yellow", 90: "Metallic Bronze", 91: "Metallic Yellow Bird", 92: "Metallic Lime", 93: "Metallic Champagne", 94: "Metallic Pueblo Beige", 95: "Metallic Dark Ivory", 96: "Metallic Choco Brown", 97: "Metallic Golden Brown", 98: "Metallic Light Brown", 99: "Metallic Straw Beige", 100: "Metallic Moss Brown", 101: "Metallic Biston Brown", 102: "Metallic Beechwood", 103: "Metallic Dark Beechwood", 104: "Metallic Choco Orange", 105: "Metallic Beach Sand", 106: "Metallic Sun Bleeched Sand", 107: "Metallic Cream",
        108: "Util Brown", 109: "Util Medium Brown", 110: "Util Light Brown", 111: "Metallic White", 112: "Metallic Frost White", 113: "Worn Honey Beige", 114: "Worn Brown", 115: "Worn Dark Brown", 116: "Worn Straw Beige",
        117: "Brushed Steel", 118: "Brushed Black Steel", 119: "Brushed Aluminum", 120: "Chrome", 121: "Worn Off White", 122: "Util Off White", 123: "Worn Orange", 124: "Worn Light Orange", 125: "Metallic Securicor Green", 126: "Worn Taxi Yellow", 127: "Police Car Blue", 128: "Matte Green", 129: "Matte Brown", 130: "Worn Orange", 131: "Matte White", 132: "Worn White", 133: "Worn Olive Army Green",
        134: "Pure White", 135: "Hot Pink", 136: "Salmon Pink", 137: "Metallic Vermillion Pink", 138: "Orange", 139: "Green", 140: "Blue", 141: "Mettalic Black Blue", 142: "Metallic Black Purple", 143: "Metallic Black Red", 144: "Hunter Green", 145: "Metallic Purple", 146: "Metaillic V Dark Blue", 147: "MODSHOP BLACK1", 148: "Matte Purple", 149: "Matte Dark Purple",
        150: "Metallic Lava Red", 151: "Matte Forest Green", 152: "Matte Olive Drab", 153: "Matte Desert Brown", 154: "Matte Desert Tan", 155: "Matte Foilage Green", 156: "DEFAULT ALLOY COLOR", 157: "Epsilon Blue", 158: "Unknown"
    };

    // Insurance company mappings with premium rates
    const insuranceCompanies = {
        'MNC': { title: 'MnC Insurance Co', logo: 'logo.png', premium: 0.10 },
        'LSIC': { title: 'Los Santos Insurance Co', logo: 'logo2.png', premium: 0.15 },
        'MAZE': { title: 'Maze Insurance Co', logo: 'logo3.png', premium: 0.20 }
    };

    // Pricing tables (mirroring server.lua)
    const categoryPrices = {
        compacts: 1000, sedans: 1250, suvs: 1500, coupes: 1750, muscle: 2000,
        sportsclassics: 1100, sports: 1800, super: 3500, motorcycles: 750,
        offroad: 1250, industrial: 2250, utility: 2125, vans: 1000,
        boats: 3250, planes: 5750, commercial: 3250, openwheel: 8500
    };
    const modTierPrices = { 1: 0, 2: 250, 3: 500, 4: 750, 5: 1000 };
    const businessFee = 1450;
    const fees = 70;
    const processFee = 125;
    const taxRate = 0.05;

    function getColorName(colorId) {
        if (colorId === undefined || colorId === null || colorId === '') return 'Unknown';
        const id = parseInt(colorId);
        return colorNames[id] || `Color ${id}`;
    }

    function resetCostsAfterPurchase() {
        originalModTier = document.getElementById("modTier")?.value || '1';
        originalIsBusiness = document.getElementById("isBusiness")?.value || 'false';
        isCurrentlyInsured = true;
        isExpired = false;
        let statusText = `Insured (Mod ${originalModTier}${originalIsBusiness === 'true' ? ', Business' : ''})`;
        document.getElementById("insuranceStatus").innerText = statusText;
        document.getElementById("insuranceStatus").className = 'status insured';
        updateCosts();
    }

    function updateCosts() {
        if (!isInspected || !isRegistered) {
            document.getElementById("purchaseBtnBottom")?.classList.add("hidden");
            return;
        }
        let modTier = parseInt(document.getElementById("modTier")?.value) || 1;
        let isBusiness = document.getElementById("isBusiness")?.value === 'true';
        let category = document.getElementById("category")?.innerText || currentVehicleData.category;
        let categoryCost = categoryPrices[category] || 1000;
        let modCost = modTierPrices[modTier] || 0;
        let businessCost = isBusiness ? businessFee : 0;
        if (isCurrentlyInsured && !isExpired) {
            let oldModCost = modTierPrices[parseInt(originalModTier)] || 0;
            let oldBusinessCost = originalIsBusiness === 'true' ? businessFee : 0;
            modCost = modTier !== parseInt(originalModTier) ? modCost : 0;
            businessCost = isBusiness !== (originalIsBusiness === 'true') ? businessCost : 0;
            categoryCost = 0;
            let taxable = modCost + businessCost;
            let tax = taxable * taxRate;
            let subtotal = modCost + businessCost + tax;
            let premium = subtotal * insuranceCompanies[selectedInsuranceCompany].premium;
            let total = Math.floor(subtotal + premium);
            document.getElementById("categoryCost").innerText = '$0';
            document.getElementById("modCost").innerText = `$${modCost}`;
            document.getElementById("businessCost").innerText = `$${businessCost}`;
            document.getElementById("processFee").innerText = '$0';
            document.getElementById("fees").innerText = '$0';
            document.getElementById("tax").innerText = `$${Math.floor(tax)}`;
            document.getElementById("premium").innerText = `$${Math.floor(premium)}`;
            document.getElementById("total").innerText = `$${total}`;
        } else {
            let taxable = categoryCost + modCost + businessCost;
            let tax = taxable * taxRate;
            let subtotal = categoryCost + modCost + businessCost + fees + processFee + tax;
            let premium = subtotal * insuranceCompanies[selectedInsuranceCompany].premium;
            let total = Math.floor(subtotal + premium);
            document.getElementById("categoryCost").innerText = `$${categoryCost}`;
            document.getElementById("modCost").innerText = `$${modCost}`;
            document.getElementById("businessCost").innerText = `$${businessCost}`;
            document.getElementById("processFee").innerText = `$${processFee}`;
            document.getElementById("fees").innerText = `$${fees}`;
            document.getElementById("tax").innerText = `$${Math.floor(tax)}`;
            document.getElementById("premium").innerText = `$${Math.floor(premium)}`;
            document.getElementById("total").innerText = `$${total}`;
        }
        let purchaseBtnBottom = document.getElementById("purchaseBtnBottom");
        if (purchaseBtnBottom) {
            let hasChanges = modTier !== parseInt(originalModTier) || isBusiness !== (originalIsBusiness === 'true');
            let shouldShow = hasChanges || !isCurrentlyInsured || isExpired;
            purchaseBtnBottom.classList.toggle("hidden", !shouldShow);
            if (isExpired) {
                purchaseBtnBottom.innerHTML = '<i class="fas fa-shield-alt"></i> Renew Insurance';
            } else if (hasChanges && isCurrentlyInsured) {
                purchaseBtnBottom.innerHTML = '<i class="fas fa-shield-alt"></i> Update Insurance';
            } else {
                purchaseBtnBottom.innerHTML = '<i class="fas fa-shield-alt"></i> Purchase Insurance';
            }
        }
    }

    function updateUI(d) {
        currentVehicleData = d;
        isCurrentlyInsured = d.isInsured && !d.isExpired;
        isExpired = d.isExpired || false;
        isRegistered = d.isRegistered || false;
        isInspected = d.isInspected || false;
        originalModTier = d.modTier?.toString() || '1';
        originalIsBusiness = d.isBusiness?.toString() || 'false';
        selectedInsuranceCompany = d.insuranceCompany || 'MNC';
        document.getElementById("insuranceContainer").classList.remove("hidden");
        document.getElementById("playerName").innerText = d.playerName || '—';
        document.getElementById("category").innerText = d.category || '—';
        document.getElementById("name").innerText = d.name || '—';
        document.getElementById("plate").innerText = d.plate || '—';
        document.getElementById("color").innerText = getColorName(d.color1) + (d.color2 && d.color2 !== d.color1 ? ` / ${getColorName(d.color2)}` : '');
        document.getElementById("citizenid").innerText = d.citizenid || '—';
        document.getElementById("modTier").value = originalModTier;
        document.getElementById("isBusiness").value = originalIsBusiness;
        document.getElementById("insuranceCompany").value = selectedInsuranceCompany;
        document.getElementById("insuranceDates").innerText = (d.startDate ? d.startDate : '—') + " → " + (d.endDate ? d.endDate : '—');
        document.getElementById("insuranceStatus").innerText = isCurrentlyInsured ? `Insured (Mod ${originalModTier}${originalIsBusiness === 'true' ? ', Business' : ''})` : (isExpired ? 'Expired' : 'Uninsured');
        document.getElementById("insuranceStatus").className = isCurrentlyInsured ? 'status insured' : 'status uninsured';
        document.getElementById("insuranceTitle").innerHTML = `<i class="fas fa-shield-alt"></i> ${insuranceCompanies[selectedInsuranceCompany].title}`;
        document.getElementById("insuranceLogo").src = insuranceCompanies[selectedInsuranceCompany].logo;
        updateCosts();
        // Show purchase button if applicable
        let purchaseBtnBottom = document.getElementById("purchaseBtnBottom");
        if (purchaseBtnBottom) {
            let hasChanges = parseInt(originalModTier) !== parseInt(d.modTier) || (originalIsBusiness === 'true') !== d.isBusiness;
            purchaseBtnBottom.classList.toggle("hidden", isCurrentlyInsured && !isExpired && !hasChanges);
        }
    }

    function updateCheckUI(d) {
        currentVehicleData = d;
        isCurrentlyInsured = d.isInsured && !d.isExpired;
        isExpired = d.isExpired || false;
        isRegistered = d.isRegistered || false;
        isInspected = d.isInspected || false;
        isCheckMode = true;
        selectedInsuranceCompany = d.insuranceCompany || 'MNC';
        document.getElementById("checkInsuranceContainer").classList.remove("hidden");
        document.getElementById("checkPlayerName").innerText = d.playerName || '—';
        document.getElementById("checkCategory").innerText = d.category || '—';
        document.getElementById("checkName").innerText = d.name || '—';
        document.getElementById("checkPlate").innerText = d.plate || '—';
        document.getElementById("checkColor").innerText = getColorName(d.color1) + (d.color2 && d.color2 !== d.color1 ? ` / ${getColorName(d.color2)}` : '');
        document.getElementById("checkCitizenid").innerText = d.citizenid || '—';
        document.getElementById("checkInsuranceDates").innerText = (d.startDate ? d.startDate : '—') + " → " + (d.endDate ? d.endDate : '—');
        document.getElementById("checkInsuranceStatus").innerText = isCurrentlyInsured ? `Insured (Mod ${d.modTier}${d.isBusiness ? ', Business' : ''})` : (isExpired ? 'Expired' : 'Uninsured');
        document.getElementById("checkInsuranceStatus").className = isCurrentlyInsured ? 'status insured' : 'status uninsured';
        document.getElementById("checkInsuranceLogo").src = insuranceCompanies[selectedInsuranceCompany].logo;
    }

    let insuranceCompanySelect = document.getElementById("insuranceCompany");
    if (insuranceCompanySelect) {
        insuranceCompanySelect.addEventListener("change", function() {
            selectedInsuranceCompany = this.value;
            document.getElementById("insuranceTitle").innerHTML = `<i class="fas fa-shield-alt"></i> ${insuranceCompanies[selectedInsuranceCompany].title}`;
            document.getElementById("insuranceLogo").src = insuranceCompanies[selectedInsuranceCompany].logo;
            updateCosts();
        });
    }

    let modTierSelect = document.getElementById("modTier");
    let isBusinessSelect = document.getElementById("isBusiness");
    if (modTierSelect && isBusinessSelect) {
        modTierSelect.addEventListener("change", updateCosts);
        isBusinessSelect.addEventListener("change", updateCosts);
    }

    let closeButtons = document.getElementsByClassName("close-btn");
    for (let i = 0; i < closeButtons.length; i++) {
        closeButtons[i].addEventListener("click", function() {
            document.getElementById("insuranceContainer").classList.add("hidden");
            document.getElementById("checkInsuranceContainer").classList.add("hidden");
            document.getElementById("registrationContainer").classList.add("hidden");
            document.getElementById("inspectionContainer").classList.add("hidden");
            document.getElementById("registrationContainer").classList.remove("checkRegistration");
            document.getElementById("inspectionContainer").classList.remove("checkInspection");
            isCheckMode = false;
            isCheckRegistrationMode = false;
            isCheckInspectionMode = false;
            fetch(`https://${GetParentResourceName()}/close`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({})
            });
        });
    }

    let purchaseBtn = document.getElementById("purchaseBtnBottom");
    if (purchaseBtn) {
        purchaseBtn.addEventListener("click", function() {
            if (!isInspected) {
                fetch(`https://${GetParentResourceName()}/notifyError`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ message: 'Vehicle must be inspected before insuring.' })
                });
                return;
            }
            if (!isRegistered) {
                fetch(`https://${GetParentResourceName()}/notifyError`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ message: 'Vehicle must be registered before insuring.' })
                });
                return;
            }
            let totalText = document.getElementById("total").innerText;
            let total = parseInt(totalText.replace(/[$,]/g, '')) || 0;
            let data = {
                playerName: document.getElementById("playerName").innerText,
                plate: document.getElementById("plate").innerText,
                name: document.getElementById("name").innerText,
                category: document.getElementById("category").innerText,
                color1: currentVehicleData.color1 || '',
                color2: currentVehicleData.color2 || '',
                citizenid: document.getElementById("citizenid").innerText,
                modTier: parseInt(document.getElementById("modTier").value) || 1,
                isBusiness: document.getElementById("isBusiness").value === 'true',
                startDate: document.getElementById("insuranceDates").innerText.split(" → ")[0],
                endDate: document.getElementById("insuranceDates").innerText.split(" → ")[1],
                total: total,
                isInsured: isCurrentlyInsured,
                isExpired: isExpired,
                insuranceCompany: selectedInsuranceCompany
            };
            fetch(`https://${GetParentResourceName()}/purchase`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data)
            }).then(response => response.json()).then(data => {
                if (data === 'ok') {
                    resetCostsAfterPurchase();
                } else {
                    console.error('Purchase callback error:', data);
                }
            }).catch(e => {
                console.error('Purchase error:', e);
                resetCostsAfterPurchase();
            });
        });
    }

    let registerBtn = document.getElementById("registerBtn");
    if (registerBtn) {
        registerBtn.addEventListener("click", function() {
            if (!isInspected) {
                fetch(`https://${GetParentResourceName()}/notifyError`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ message: 'Vehicle must be inspected before registering.' })
                });
                return;
            }
            let totalText = document.getElementById("regTotal").innerText;
            let total = parseInt(totalText.replace(/[$,]/g, '')) || 0;
            let data = {
                playerName: document.getElementById("regPlayerName").innerText,
                plate: document.getElementById("regPlate").innerText,
                name: document.getElementById("regName").innerText,
                category: document.getElementById("regCategory").innerText,
                color1: currentVehicleData.color1 || '',
                color2: currentVehicleData.color2 || '',
                citizenid: document.getElementById("regCitizenid").innerText,
                registrationDate: document.getElementById("registrationDate").innerText,
                total: total,
                isInspected: isInspected
            };
            fetch(`https://${GetParentResourceName()}/register`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data)
            }).then(response => response.json()).then(data => {
                if (data === 'ok') {
                    isRegistered = true;
                    document.getElementById("registrationStatus").innerText = 'Registered';
                    document.getElementById("registrationStatus").className = 'status insured';
                    registerBtn.classList.add("hidden");
                    document.getElementById("registrationCostSection")?.classList.add("hidden");
                    updateCosts();
                } else {
                    console.error('Registration callback error:', data);
                }
            }).catch(e => {
                console.error('Registration error:', e);
            });
        });
    }

    let inspectBtn = document.getElementById("inspectBtn");
    if (inspectBtn) {
        inspectBtn.addEventListener("click", function() {
            let totalText = document.getElementById("inspTotal").innerText;
            let total = parseInt(totalText.replace(/[$,]/g, '')) || 0;
            let data = {
                playerName: document.getElementById("inspPlayerName").innerText,
                plate: document.getElementById("inspPlate").innerText,
                name: document.getElementById("inspName").innerText,
                category: document.getElementById("inspCategory").innerText,
                color1: currentVehicleData.color1 || '',
                color2: currentVehicleData.color2 || '',
                citizenid: document.getElementById("inspCitizenid").innerText,
                inspectionDate: document.getElementById("inspectionDate").innerText,
                total: total
            };
            fetch(`https://${GetParentResourceName()}/inspect`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data)
            }).then(response => response.json()).then(data => {
                if (data === 'ok') {
                    isInspected = true;
                    document.getElementById("inspectionStatus").innerText = 'Inspected';
                    document.getElementById("inspectionStatus").className = 'status insured';
                    inspectBtn.classList.add("hidden");
                    updateCosts();
                } else {
                    console.error('Inspection callback error:', data);
                }
            }).catch(e => {
                console.error('Inspection error:', e);
            });
        });
    }

    window.addEventListener('message', function(event) {
        let data = event.data;
        
        // Reset UI states to avoid lingering check mode classes
        document.getElementById("insuranceContainer").classList.add("hidden");
        document.getElementById("checkInsuranceContainer").classList.add("hidden");
        document.getElementById("registrationContainer").classList.add("hidden");
        document.getElementById("inspectionContainer").classList.add("hidden");
        document.getElementById("registrationContainer").classList.remove("checkRegistration");
        document.getElementById("inspectionContainer").classList.remove("checkInspection");
        isCheckMode = false;
        isCheckRegistrationMode = false;
        isCheckInspectionMode = false;

        if (data.type === "open") {
            document.getElementById("insuranceContainer").classList.remove("hidden");
            updateUI(data.payload);
            // Ensure purchase button is shown if not insured or has changes
            let purchaseBtnBottom = document.getElementById("purchaseBtnBottom");
            if (purchaseBtnBottom) {
                let hasChanges = parseInt(data.payload.modTier) !== parseInt(originalModTier) || data.payload.isBusiness !== (originalIsBusiness === 'true');
                purchaseBtnBottom.classList.toggle("hidden", data.payload.isInsured && !data.payload.isExpired && !hasChanges);
            }
        } else if (data.type === "check") {
            document.getElementById("checkInsuranceContainer").classList.remove("hidden");
            isCheckMode = true;
            updateCheckUI(data.payload);
        } else if (data.type === "register") {
            document.getElementById("registrationContainer").classList.remove("hidden");
            isRegistered = data.payload.isRegistered || false;
            isInspected = data.payload.isInspected || false;
            document.getElementById("regPlayerName").innerText = data.payload.playerName || '—';
            document.getElementById("regCategory").innerText = data.payload.category || '—';
            document.getElementById("regName").innerText = data.payload.name || '—';
            document.getElementById("regPlate").innerText = data.payload.plate || '—';
            document.getElementById("regColor").innerText = getColorName(data.payload.color1) + (data.payload.color2 && data.payload.color2 !== data.payload.color1 ? ` / ${getColorName(data.payload.color2)}` : '');
            document.getElementById("regCitizenid").innerText = data.payload.citizenid || '—';
            document.getElementById("registrationDate").innerText = data.payload.registrationDate || '—';
            document.getElementById("regTotal").innerText = '$' + (data.payload.total || 250);
            document.getElementById("registrationStatus").innerText = isRegistered ? 'Registered' : 'Unregistered';
            document.getElementById("registrationStatus").className = isRegistered ? 'status insured' : 'status uninsured';
            // Show register button and cost section if not registered
            if (!isRegistered) {
                document.getElementById("registerBtn")?.classList.remove("hidden");
                document.getElementById("registrationCostSection")?.classList.remove("hidden");
            } else {
                document.getElementById("registerBtn")?.classList.add("hidden");
                document.getElementById("registrationCostSection")?.classList.add("hidden");
            }
        } else if (data.type === "checkRegistration") {
            document.getElementById("registrationContainer").classList.remove("hidden");
            document.getElementById("registrationContainer").classList.add("checkRegistration");
            isCheckRegistrationMode = true;
            isRegistered = data.payload.isRegistered || false;
            isInspected = data.payload.isInspected || false;
            document.getElementById("regPlayerName").innerText = data.payload.playerName || '—';
            document.getElementById("regCategory").innerText = data.payload.category || '—';
            document.getElementById("regName").innerText = data.payload.name || '—';
            document.getElementById("regPlate").innerText = data.payload.plate || '—';
            document.getElementById("regColor").innerText = getColorName(data.payload.color1) + (data.payload.color2 && data.payload.color2 !== data.payload.color1 ? ` / ${getColorName(data.payload.color2)}` : '');
            document.getElementById("regCitizenid").innerText = data.payload.citizenid || '—';
            document.getElementById("registrationDate").innerText = data.payload.registrationDate || '—';
            document.getElementById("registrationStatus").innerText = isRegistered ? 'Registered' : 'Unregistered';
            document.getElementById("registrationStatus").className = isRegistered ? 'status insured' : 'status uninsured';
            // Hide cost section and button in check mode
            document.getElementById("registrationCostSection")?.classList.add("hidden");
            document.getElementById("registerBtn")?.classList.add("hidden");
        } else if (data.type === "inspect") {
            document.getElementById("inspectionContainer").classList.remove("hidden");
            isInspected = data.payload.isInspected || false;
            document.getElementById("inspPlayerName").innerText = data.payload.playerName || '—';
            document.getElementById("inspCategory").innerText = data.payload.category || '—';
            document.getElementById("inspName").innerText = data.payload.name || '—';
            document.getElementById("inspPlate").innerText = data.payload.plate || '—';
            document.getElementById("inspColor").innerText = getColorName(data.payload.color1) + (data.payload.color2 && data.payload.color2 !== data.payload.color1 ? ` / ${getColorName(data.payload.color2)}` : '');
            document.getElementById("inspCitizenid").innerText = data.payload.citizenid || '—';
            document.getElementById("inspectionDate").innerText = data.payload.inspectionDate || '—';
            document.getElementById("inspTotal").innerText = '$' + (data.payload.total || 350);
            document.getElementById("inspectionStatus").innerText = isInspected ? 'Inspected' : 'Not Inspected';
            document.getElementById("inspectionStatus").className = isInspected ? 'status insured' : 'status uninsured';
            // Show inspect button if not inspected
            if (!isInspected) {
                document.getElementById("inspectBtn")?.classList.remove("hidden");
            } else {
                document.getElementById("inspectBtn")?.classList.add("hidden");
            }
        } else if (data.type === "checkInspection") {
            document.getElementById("inspectionContainer").classList.remove("hidden");
            document.getElementById("inspectionContainer").classList.add("checkInspection");
            isCheckInspectionMode = true;
            isInspected = data.payload.isInspected || false;
            document.getElementById("inspPlayerName").innerText = data.payload.playerName || '—';
            document.getElementById("inspCategory").innerText = data.payload.category || '—';
            document.getElementById("inspName").innerText = data.payload.name || '—';
            document.getElementById("inspPlate").innerText = data.payload.plate || '—';
            document.getElementById("inspColor").innerText = getColorName(data.payload.color1) + (data.payload.color2 && data.payload.color2 !== data.payload.color1 ? ` / ${getColorName(data.payload.color2)}` : '');
            document.getElementById("inspCitizenid").innerText = data.payload.citizenid || '—';
            document.getElementById("inspectionDate").innerText = data.payload.inspectionDate || '—';
            document.getElementById("inspectionStatus").innerText = isInspected ? 'Inspected' : 'Not Inspected';
            document.getElementById("inspectionStatus").className = isInspected ? 'status insured' : 'status uninsured';
            // Hide cost section and button in check mode
            document.getElementById("inspectBtn")?.classList.add("hidden");
        } else if (data.type === "close") {
            document.getElementById("insuranceContainer").classList.add("hidden");
            document.getElementById("checkInsuranceContainer").classList.add("hidden");
            document.getElementById("registrationContainer").classList.add("hidden");
            document.getElementById("inspectionContainer").classList.add("hidden");
            document.getElementById("registrationContainer").classList.remove("checkRegistration");
            document.getElementById("inspectionContainer").classList.remove("checkInspection");
            isCheckMode = false;
            isCheckRegistrationMode = false;
            isCheckInspectionMode = false;
        }
    });

    window.updateCosts = updateCosts;
});