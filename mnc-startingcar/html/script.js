(function () {
  const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'mnc-startingcar';

  const app = document.getElementById('app');

  const selectPanel = document.getElementById('selectPanel');
  const vehicleListEl = document.getElementById('vehicleList');
  const selectErrorMsg = document.getElementById('selectErrorMsg');
  const selectCloseBtn = document.getElementById('selectCloseBtn');

  const pinkslip = document.getElementById('pinkslip');
  const vehicleNameEl = document.getElementById('vehicleName');
  const ownerNameInput = document.getElementById('ownerName');
  const errorMsg = document.getElementById('errorMsg');

  const sigTabs = document.querySelectorAll('.sig-tab');
  const drawPane = document.getElementById('drawPane');
  const typePane = document.getElementById('typePane');
  const canvas = document.getElementById('sigCanvas');
  const ctx = canvas.getContext('2d');
  const clearSigBtn = document.getElementById('clearSig');
  const typedSignatureInput = document.getElementById('typedSignature');
  const typedPreview = document.getElementById('typedPreview');

  const backBtn = document.getElementById('backBtn');
  const cancelBtn = document.getElementById('cancelBtn');
  const confirmBtn = document.getElementById('confirmBtn');

  let vehicles = [];
  let currentSlot = null;
  let currentLabel = null;
  let activeSigTab = 'draw';
  let hasDrawn = false;
  let isDrawing = false;

  function playSound(file, volume) {
    if (!file) return;
    const audio = new Audio(file);
    audio.loop = false;
    audio.volume = typeof volume === 'number' ? volume : 0.8;
    audio.play().catch(() => {});
  }

  function post(endpoint, body) {
    return fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {}),
    }).catch(() => {});
  }

  function closeApp() {
    app.classList.add('hidden');
    post('closeUI');
  }

  // ---- Panel switching ----
  function showSelectPanel() {
    selectErrorMsg.textContent = '';
    selectPanel.classList.add('active');
    pinkslip.classList.remove('active');
  }

  function showPinkslipPanel() {
    selectPanel.classList.remove('active');
    pinkslip.classList.add('active');
  }

  // ---- Vehicle selection list (page 1) ----
  function renderVehicleList() {
    vehicleListEl.innerHTML = '';

    vehicles.forEach((v) => {
      const card = document.createElement('button');
      card.type = 'button';
      card.className = 'vehicle-card' + (v.available ? '' : ' unavailable');
      card.disabled = !v.available;

      const name = document.createElement('div');
      name.className = 'vehicle-card-name';
      name.textContent = v.label;

      const status = document.createElement('div');
      status.className = 'vehicle-card-status';
      status.textContent = v.available ? 'Available -- Select to continue' : 'Currently unavailable';

      card.appendChild(name);
      card.appendChild(status);

      if (v.available) {
        card.addEventListener('click', () => selectVehicle(v));
      }

      vehicleListEl.appendChild(card);
    });
  }

  function selectVehicle(v) {
    currentSlot = v.slot;
    currentLabel = v.label;
    resetSignatureForm();
    vehicleNameEl.textContent = currentLabel;
    showPinkslipPanel();
  }

  // ---- Pink slip form (page 2) ----
  function showError(msg) {
    errorMsg.textContent = msg || '';
  }

  function resetSignatureForm() {
    hasDrawn = false;
    ownerNameInput.value = '';
    typedSignatureInput.value = '';
    typedPreview.textContent = '';
    showError('');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    setActiveTab('draw');
  }

  function setActiveTab(tab) {
    activeSigTab = tab;
    sigTabs.forEach((t) => t.classList.toggle('active', t.dataset.tab === tab));
    drawPane.classList.toggle('active', tab === 'draw');
    typePane.classList.toggle('active', tab === 'type');
  }

  sigTabs.forEach((tab) => {
    tab.addEventListener('click', () => setActiveTab(tab.dataset.tab));
  });

  // ---- Canvas signature drawing ----
  function getPos(e) {
    const rect = canvas.getBoundingClientRect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    return {
      x: (clientX - rect.left) * (canvas.width / rect.width),
      y: (clientY - rect.top) * (canvas.height / rect.height),
    };
  }

  function startDraw(e) {
    isDrawing = true;
    hasDrawn = true;
    const p = getPos(e);
    ctx.beginPath();
    ctx.moveTo(p.x, p.y);
    e.preventDefault();
  }

  function moveDraw(e) {
    if (!isDrawing) return;
    const p = getPos(e);
    ctx.lineWidth = 2.2;
    ctx.lineCap = 'round';
    ctx.strokeStyle = '#3a1018';
    ctx.lineTo(p.x, p.y);
    ctx.stroke();
    e.preventDefault();
  }

  function endDraw() {
    isDrawing = false;
  }

  canvas.addEventListener('mousedown', startDraw);
  canvas.addEventListener('mousemove', moveDraw);
  window.addEventListener('mouseup', endDraw);
  canvas.addEventListener('touchstart', startDraw);
  canvas.addEventListener('touchmove', moveDraw);
  canvas.addEventListener('touchend', endDraw);

  clearSigBtn.addEventListener('click', () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    hasDrawn = false;
  });

  typedSignatureInput.addEventListener('input', () => {
    typedPreview.textContent = typedSignatureInput.value;
  });

  // ---- Select panel buttons ----
  selectCloseBtn.addEventListener('click', () => {
    closeApp();
  });

  // ---- Pink slip buttons ----
  backBtn.addEventListener('click', () => {
    showSelectPanel();
  });

  cancelBtn.addEventListener('click', () => {
    closeApp();
  });

  confirmBtn.addEventListener('click', () => {
    if (currentSlot === null) {
      showError('No vehicle selected.');
      return;
    }

    const ownerName = ownerNameInput.value.trim();
    if (!ownerName) {
      showError('Please enter the registered owner name.');
      return;
    }

    let signatureType = activeSigTab;
    let signatureData = '';

    if (activeSigTab === 'draw') {
      if (!hasDrawn) {
        showError('Please draw your signature, or switch to Type Signature.');
        return;
      }
      signatureData = canvas.toDataURL('image/png');
    } else {
      const typed = typedSignatureInput.value.trim();
      if (!typed) {
        showError('Please type your signature.');
        return;
      }
      signatureData = typed;
    }

    confirmBtn.disabled = true;
    app.classList.add('hidden');

    post('confirmClaim', {
      slot: currentSlot,
      label: currentLabel,
      ownerName: ownerName,
      signatureType: signatureType,
      signatureData: signatureData,
    }).finally(() => {
      confirmBtn.disabled = false;
    });
  });

  document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape' || app.classList.contains('hidden')) return;

    if (pinkslip.classList.contains('active')) {
      // Back out to the vehicle list rather than closing outright.
      showSelectPanel();
    } else {
      closeApp();
    }
  });

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
      vehicles = Array.isArray(data.vehicles) ? data.vehicles : [];
      currentSlot = null;
      currentLabel = null;
      renderVehicleList();
      showSelectPanel();
      app.classList.remove('hidden');
      // Only present the very first time this player ever opens the
      // browser -- client.lua only sends this once, ever, per player.
      playSound(data.introSound, data.introVolume);
      return;
    }

    if (data.action === 'boughtSound') {
      // A fresh Audio() per vehicle purchase -- each one only ever fires
      // once, since the claim itself is a one-time event per player.
      playSound(data.file, data.volume);
      return;
    }
  });
})();