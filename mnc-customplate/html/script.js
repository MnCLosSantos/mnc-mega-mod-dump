/* ============================================================
   MNC Custom Plate — script.js
   ============================================================ */

'use strict';

// ── DOM refs ────────────────────────────────────────────────
const overlay     = document.getElementById('overlay');
const plateEl     = document.getElementById('plateEl');
const plateNumber = document.getElementById('plateNumber');
const plateState  = document.getElementById('plateState');
const plateInput  = document.getElementById('plateInput');
const charCount   = document.getElementById('charCount');
const applyBtn    = document.getElementById('applyBtn');
const cancelBtn   = document.getElementById('cancelBtn');
const closeBtn    = document.getElementById('closeBtn');
const stripText   = document.querySelector('.strip-text');

// ── State ───────────────────────────────────────────────────
let maxLen  = 8;
let minLen  = 1;
let isAdmin = false;

// White theme — fixed, no picker needed
const WHITE_THEME = { id: 'default', bg: '#FFFFFF', text: '#1a1a2e', border: '#c9aa71' };

// ── NUI Message handler ─────────────────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || d.action !== 'openUI') return;

    maxLen  = d.maxLen  || 8;
    minLen  = d.minLen  || 1;
    isAdmin = !!d.adminMode;

    plateState.textContent = d.state || 'MNC STATE';
    plateInput.maxLength   = maxLen;

    applyThemeToPlate(WHITE_THEME);
    resetUI();

    overlay.classList.remove('hidden');
    setTimeout(() => plateInput.focus(), 80);
});

// ── Apply white theme to plate ──────────────────────────────
function applyThemeToPlate(t) {
    plateEl.style.background  = t.bg;
    plateEl.style.borderColor = t.border;
    plateNumber.style.color   = t.text;
    plateState.style.color    = t.text;
    if (stripText) stripText.style.color = t.text;
}

// ── Plate input ─────────────────────────────────────────────
plateInput.addEventListener('input', () => {
    let val = plateInput.value
        .toUpperCase()
        .replace(/[^A-Z0-9 ]/g, '')
        .slice(0, maxLen);

    plateInput.value = val;

    charCount.textContent = `${val.length} / ${maxLen}`;

    const display = val.trim() === '' ? 'CUSTOM' : val;
    plateNumber.textContent = display;

    if (val.length > 5) {
        plateNumber.classList.add('long');
    } else {
        plateNumber.classList.remove('long');
    }

    const trimLen = val.trim().length;
    applyBtn.disabled = trimLen < minLen || trimLen > maxLen;
});

// ── Apply ───────────────────────────────────────────────────
applyBtn.addEventListener('click', () => {
    const plate = plateInput.value.trim();
    if (!plate || applyBtn.disabled) return;

    overlay.classList.add('hidden');

    postNUI('applyPlate', { plate, theme: WHITE_THEME.id, adminMode: isAdmin });
});

// ── Close / Cancel ──────────────────────────────────────────
function closeUI() {
    overlay.classList.add('hidden');
    postNUI('closeUI', {});
}

cancelBtn.addEventListener('click', closeUI);
closeBtn.addEventListener('click',  closeUI);

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeUI();
});

// ── Reset ───────────────────────────────────────────────────
function resetUI() {
    plateInput.value        = '';
    plateNumber.textContent = 'CUSTOM';
    plateNumber.classList.remove('long');
    charCount.textContent   = `0 / ${maxLen}`;
    applyBtn.disabled       = true;
}

// ── NUI fetch helper ────────────────────────────────────────
function postNUI(event, data) {
    return fetch(`https://mnc-customplate/${event}`, {
        method  : 'POST',
        headers : { 'Content-Type': 'application/json' },
        body    : JSON.stringify(data),
    }).catch(() => {});
}