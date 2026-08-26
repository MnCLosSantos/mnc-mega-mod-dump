(() => {
  const resourceName = (window.GetParentResourceName && window.GetParentResourceName()) || 'mnc-handui';

  async function nuiPost(name, data = {}) {
    try {
      const resp = await fetch(`https://${resourceName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
      });
      return await resp.json();
    } catch (e) {
      return null;
    }
  }

  // ------------------------------------------------------------------
  // State
  // ------------------------------------------------------------------

  const state = {
    fieldGroups: [],
    fieldLookup: {},
    presets: [],
    activeCategory: 0,
    activeView: 'editor',

    currentModel: null,
    currentLabel: null,
    hasOverride: false,
    updatedBy: null,
    updatedAt: null,
    fields: {},
    original: {},
  };

  // ------------------------------------------------------------------
  // DOM refs
  // ------------------------------------------------------------------

  const el = (id) => document.getElementById(id);

  const appEl = el('app');
  const closeBtn = el('closeBtn');

  const modelBanner = el('modelBanner');
  const modelLabel = el('modelLabel');
  const modelCode = el('modelCode');
  const modelBadge = el('modelBadge');
  const modelMeta = el('modelMeta');

  const editorWorkspace = el('editorWorkspace');
  const presetBarEl = el('presetBar');
  const categoryTabsEl = el('categoryTabs');
  const fieldListEl = el('fieldList');

  const revertAllBtn = el('revertAllBtn');
  const saveBtn = el('saveBtn');

  const savedSearch = el('savedSearch');
  const savedTableBody = el('savedTableBody');
  const savedEmpty = el('savedEmpty');

  const confirmModal = el('confirmModal');
  const confirmText = el('confirmText');
  const confirmCancel = el('confirmCancel');
  const confirmOk = el('confirmOk');

  const toastEl = el('toast');

  // ------------------------------------------------------------------
  // Toast
  // ------------------------------------------------------------------

  let toastTimer = null;
  function showToast(message, type = 'info') {
    toastEl.textContent = message;
    toastEl.className = type;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      toastEl.classList.add('hidden');
    }, 3200);
  }

  // ------------------------------------------------------------------
  // Confirm modal (native confirm()/alert() block the NUI thread)
  // ------------------------------------------------------------------

  function askConfirm(message) {
    return new Promise((resolve) => {
      confirmText.textContent = message;
      confirmModal.classList.remove('hidden');

      const cleanup = (result) => {
        confirmModal.classList.add('hidden');
        confirmCancel.removeEventListener('click', onCancel);
        confirmOk.removeEventListener('click', onOk);
        resolve(result);
      };
      const onCancel = () => cleanup(false);
      const onOk = () => cleanup(true);

      confirmCancel.addEventListener('click', onCancel);
      confirmOk.addEventListener('click', onOk);
    });
  }

  // ------------------------------------------------------------------
  // View / nav switching
  // ------------------------------------------------------------------

  document.querySelectorAll('.nav-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.nav-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');

      const view = btn.dataset.view;
      state.activeView = view;
      document.querySelectorAll('.view').forEach((v) => v.classList.remove('active'));
      el(`view-${view}`).classList.add('active');

      if (view === 'saved') {
        loadSavedOverrides();
      }
    });
  });

  // ------------------------------------------------------------------
  // Render the editor with current state
  // ------------------------------------------------------------------

  function renderEditor() {
    renderModelBanner();
    renderPresetBar();
    renderCategoryTabs();
    renderFields();
  }

  function renderModelBanner() {
    modelLabel.textContent = state.currentLabel;
    modelCode.textContent = state.currentModel;
    if (state.hasOverride) {
      modelBadge.textContent = 'Custom';
      modelBadge.classList.add('custom');
      const when = state.updatedAt ? new Date(state.updatedAt).toLocaleString() : '';
      modelMeta.textContent = state.updatedBy
        ? `Last edited by ${state.updatedBy}${when ? ' · ' + when : ''}`
        : '';
    } else {
      modelBadge.textContent = 'Default';
      modelBadge.classList.remove('custom');
      modelMeta.textContent = 'No overrides saved yet';
    }
  }

  // ------------------------------------------------------------------
  // Presets
  // ------------------------------------------------------------------

  function escapeAttr(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function renderPresetBar() {
    if (!presetBarEl) return;
    const presets = state.presets || [];
    if (!state.currentModel || presets.length === 0) {
      presetBarEl.classList.add('hidden');
      presetBarEl.innerHTML = '';
      return;
    }

    presetBarEl.classList.remove('hidden');
    presetBarEl.innerHTML = presets
      .map((p) => `<button class="preset-chip" data-preset="${p.key}" data-tooltip="${escapeAttr(p.description || '')}">${p.label}</button>`)
      .join('');

    presetBarEl.querySelectorAll('[data-preset]').forEach((btn) => {
      btn.addEventListener('click', () => applyPreset(btn.dataset.preset));
    });
  }

  function applyPreset(presetKey) {
    if (!state.currentModel) return;
    const preset = (state.presets || []).find((p) => p.key === presetKey);
    if (!preset) return;

    const multipliers = preset.multipliers || {};
    const absolute = preset.absolute || {};

    // Multipliers apply against the vehicle's own vanilla baseline so
    // presets are repeatable and never compound on top of each other.
    Object.keys(state.fieldLookup).forEach((key) => {
      const field = state.fieldLookup[key];
      let value;

      if (absolute[key] !== undefined) {
        value = Number(absolute[key]);
      } else if (multipliers[key] !== undefined) {
        const base = state.original[key] !== undefined
          ? Number(state.original[key])
          : Number(state.fields[key]);
        if (base === undefined || Number.isNaN(base)) return;
        value = base * multipliers[key];
      } else {
        return; // field untouched by this preset
      }

      if (field.type === 'int') value = Math.round(value);
      if (field.min !== undefined && value < field.min) value = field.min;
      if (field.max !== undefined && value > field.max) value = field.max;

      state.fields[key] = value;
    });

    renderFields();
    pushLiveUpdate(true);

    showToast(`Applied "${preset.label}" preset.`, 'success');
  }

  // ------------------------------------------------------------------
  // Category tabs + field rendering
  // ------------------------------------------------------------------

  function renderCategoryTabs() {
    categoryTabsEl.innerHTML = state.fieldGroups
      .map((g, i) => `<button class="cat-tab${i === state.activeCategory ? ' active' : ''}" data-index="${i}">${g.category}</button>`)
      .join('');

    categoryTabsEl.querySelectorAll('.cat-tab').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.activeCategory = parseInt(btn.dataset.index, 10);
        renderCategoryTabs();
        renderFields();
      });
    });
  }

  function formatValue(field, value) {
    if (value === undefined || value === null) return '—';
    return field.type === 'int' ? String(Math.round(value)) : Number(value).toFixed(3);
  }

  function renderFields() {
    const group = state.fieldGroups[state.activeCategory];
    if (!group) {
      fieldListEl.innerHTML = '';
      return;
    }

    fieldListEl.innerHTML = group.fields
      .map((field) => {
        const value = state.fields[field.key];
        const isDirty = state.original[field.key] !== undefined
          && Number(value) !== Number(state.original[field.key]);
        return `
          <div class="field-row${isDirty ? ' dirty' : ''}" data-key="${field.key}">
            <div class="field-top">
              <span class="field-name">${field.label}<span class="hint-dot" data-tooltip="${escapeAttr(field.hint || '')}">&#9432;</span></span>
              <span class="field-value" data-value-for="${field.key}">${formatValue(field, value)}</span>
            </div>
            <div class="field-controls">
              <input type="range" data-key="${field.key}"
                min="${field.min}" max="${field.max}" step="${field.step}"
                value="${value !== undefined ? value : field.min}">
              <button class="reset-icon" data-reset="${field.key}" data-tooltip="Reset to default">&#8634;</button>
            </div>
          </div>`;
      })
      .join('');

    fieldListEl.querySelectorAll('input[type="range"]').forEach((input) => {
      input.addEventListener('input', () => onFieldChange(input.dataset.key, input.value));
    });
    fieldListEl.querySelectorAll('[data-reset]').forEach((btn) => {
      btn.addEventListener('click', () => resetField(btn.dataset.reset));
    });
  }

  // ------------------------------------------------------------------
  // Live update — sent to the vehicle the admin is sitting in
  // Single batched push instead of one fetch per field.
  // ------------------------------------------------------------------

  let liveUpdateTimer = null;
  let liveUpdateRetryTimer = null;
  function pushLiveUpdate(immediate = false) {
    clearTimeout(liveUpdateTimer);
    clearTimeout(liveUpdateRetryTimer);
    const send = () => nuiPost('handui:liveUpdate', { fields: state.fields });
    if (immediate) {
      send();
      // Re-apply after 150ms: the game's vehicle mod system can overwrite
      // our values a frame or two after we set them.
      liveUpdateRetryTimer = setTimeout(send, 150);
    } else {
      liveUpdateTimer = setTimeout(() => {
        send();
        liveUpdateRetryTimer = setTimeout(send, 150);
      }, 40);
    }
  }

  function onFieldChange(key, rawValue) {
    const field = state.fieldLookup[key];
    if (!field) return;

    const value = field.type === 'int' ? Math.round(Number(rawValue)) : Number(rawValue);
    state.fields[key] = value;

    const valueEl = fieldListEl.querySelector(`[data-value-for="${key}"]`);
    if (valueEl) valueEl.textContent = formatValue(field, value);

    const row = fieldListEl.querySelector(`.field-row[data-key="${key}"]`);
    if (row) {
      const isDirty = state.original[key] !== undefined
        && Number(value) !== Number(state.original[key]);
      row.classList.toggle('dirty', isDirty);
    }

    pushLiveUpdate();
  }

  function resetField(key) {
    const field = state.fieldLookup[key];
    if (!field || state.original[key] === undefined) return;
    const value = state.original[key];
    state.fields[key] = value;

    const input = fieldListEl.querySelector(`input[data-key="${key}"]`);
    if (input) input.value = value;
    onFieldChange(key, value);
  }

  revertAllBtn.addEventListener('click', () => {
    state.fields = Object.assign({}, state.original);
    renderFields();
    pushLiveUpdate(true);
    showToast('All values reverted to default.', 'info');
  });

  // ------------------------------------------------------------------
  // Save
  // ------------------------------------------------------------------

  saveBtn.addEventListener('click', async () => {
    if (!state.currentModel) return;
    saveBtn.disabled = true;
    saveBtn.textContent = 'Saving…';

    await nuiPost('handui:save', {
      model: state.currentModel,
      fields: state.fields,
      original: state.original,
    });
  });

  function onSaveResult(payload) {
    saveBtn.disabled = false;
    saveBtn.textContent = 'Save Changes';

    if (payload.ok) {
      state.hasOverride = true;
      state.original = Object.assign({}, state.fields);
      renderModelBanner();
      renderFields();
    }
  }

  // ------------------------------------------------------------------
  // Saved overrides list
  // ------------------------------------------------------------------

  let savedListCache = [];

  async function loadSavedOverrides() {
    const res = await nuiPost('handui:getOverridesList');
    savedListCache = (res && res.list) || [];
    renderSavedTable(savedSearch.value);
  }

  function renderSavedTable(filter) {
    const q = (filter || '').trim().toLowerCase();
    const rows = savedListCache.filter((r) => !q || r.model.toLowerCase().includes(q));

    if (rows.length === 0) {
      savedTableBody.innerHTML = '';
      savedEmpty.classList.remove('hidden');
      return;
    }
    savedEmpty.classList.add('hidden');

    savedTableBody.innerHTML = rows
      .map((r) => {
        const when = r.updatedAt ? new Date(r.updatedAt).toLocaleString() : '—';
        return `
          <tr>
            <td class="model-code">${r.model}</td>
            <td class="meta">${r.updatedBy || '—'}</td>
            <td class="meta">${when}</td>
            <td>
              <div class="row-actions">
                <button data-revert="${r.model}" class="danger">Revert</button>
              </div>
            </td>
          </tr>`;
      })
      .join('');

    savedTableBody.querySelectorAll('[data-revert]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const model = btn.dataset.revert;
        const ok = await askConfirm(`Revert ${model} back to its default handling? This deletes the saved override.`);
        if (!ok) return;
        await nuiPost('handui:deleteOverride', { model });
        loadSavedOverrides();
      });
    });
  }

  savedSearch.addEventListener('input', () => renderSavedTable(savedSearch.value));

  // ------------------------------------------------------------------
  // Close handling
  // ------------------------------------------------------------------

  async function closeUI() {
    appEl.classList.add('hidden');
    await nuiPost('handui:close');
  }

  closeBtn.addEventListener('click', closeUI);

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (!appEl.classList.contains('hidden')) {
        e.preventDefault();
        closeUI();
      }
      return;
    }

    const tag = document.activeElement && document.activeElement.tagName;
    const inInput = tag === 'INPUT' || tag === 'TEXTAREA';
    if (inInput) return;

    const allow = ['Tab', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'];
    if (allow.includes(e.key)) return;

    e.preventDefault();
    e.stopPropagation();
  }, true);

  // ------------------------------------------------------------------
  // Inbound messages from client/main.lua
  // ------------------------------------------------------------------

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
      // Load field/preset definitions
      state.fieldGroups = data.fieldGroups || [];
      state.fieldLookup = {};
      state.fieldGroups.forEach((g) => g.fields.forEach((f) => { state.fieldLookup[f.key] = f; }));
      state.presets = data.presets || [];

      // Load vehicle data — delivered by the Lua command, no search step needed
      state.currentModel  = data.model;
      state.currentLabel  = data.label;
      state.hasOverride   = !!data.hasOverride;
      state.updatedBy     = data.updatedBy || null;
      state.updatedAt     = data.updatedAt || null;
      state.fields        = Object.assign({}, data.fields);
      state.original      = Object.assign({}, data.original);
      state.activeCategory = 0;

      appEl.classList.remove('hidden');

      // Switch to editor view
      document.querySelectorAll('.nav-btn').forEach((b) => b.classList.remove('active'));
      const editorBtn = document.querySelector('.nav-btn[data-view="editor"]');
      if (editorBtn) editorBtn.classList.add('active');
      document.querySelectorAll('.view').forEach((v) => v.classList.remove('active'));
      const editorView = el('view-editor');
      if (editorView) editorView.classList.add('active');
      state.activeView = 'editor';

      renderEditor();

    } else if (data.action === 'close') {
      appEl.classList.add('hidden');

    } else if (data.action === 'saveResult') {
      onSaveResult(data);
    }
  });
})();