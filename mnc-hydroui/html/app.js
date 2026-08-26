// mnc-hydroui | NUI App
// Receives messages from client Lua and drives the switch panel UI

// Wrapped in an IIFE so every binding below (root, switches, currentlyActive,
// ...) lives in its own function scope instead of the page's top-level scope.
// If the CEF browser ever keeps running across a resource restart instead of
// fully reloading the page (an `ensure`/`restart` can do this without a full
// client reconnect) and this script gets re-injected into that same still-
// alive context, a bare top-level `const root = ...` throws "Identifier
// 'root' has already been declared" and the whole file stops executing —
// which is what silently breaks the panel (nothing lights up, mode changes
// look like they do nothing) until the browser is actually torn down. Each
// run of the IIFE gets its own fresh scope, so a re-injection just sets up
// a second, harmless listener instead of crashing.
(function () {
'use strict';

// ── Element refs ──────────────────────────────────────────────────────────────

const root = document.getElementById('hydroui');

const switches = {
    fl: document.getElementById('sw-fl'),
    fr: document.getElementById('sw-fr'),
    rl: document.getElementById('sw-rl'),
    rr: document.getElementById('sw-rr'),
};

const onBtn = document.getElementById('sw-on');
const modeHint = document.getElementById('hint-mode');

// Arrow keys light up a corner switch directly instead of their own
// on-screen d-pad: Up → FL, Right → FR, Down → RR, Left → RL.
const CORNER_ARROW_KEY = {
    fl: 'forward',
    fr: 'right',
    rr: 'backward',
    rl: 'left',
};

// ── State ─────────────────────────────────────────────────────────────────────

let currentlyActive = new Set();
let cornerModeActive = false;

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Apply held keys + hydro mode from Lua.
 * Also accepts optional mx/my mouse-delta magnitudes for future use.
 *
 * @param {string[]} held        e.g. ['on','fl'] in corner mode, or ['on','forward'] in axle mode
 * @param {boolean}  cornerMode  true = corner mode, false = axle mode
 * @param {number}   mx          raw mouse X delta -1…+1
 * @param {number}   my          raw mouse Y delta -1…+1
 */
function applyHeldKeys(held, cornerMode, mx, my) {
    const next = new Set(held);

    const onActive = next.has('on');
    if (onActive !== currentlyActive.has('on')) {
        onBtn.classList.toggle('active', onActive);
    }

    for (const [corner, el] of Object.entries(switches)) {
        const arrowKey = CORNER_ARROW_KEY[corner];
        const active = next.has(corner) || next.has(arrowKey);
        const wasActive = currentlyActive.has(corner) || currentlyActive.has(arrowKey);
        if (active !== wasActive) {
            el.classList.toggle('active', active);
        }
    }

    currentlyActive = next;

    if (cornerMode !== cornerModeActive) {
        cornerModeActive = cornerMode;
        if (modeHint) modeHint.classList.toggle('active', cornerModeActive);
    }
}

function clearAllActive() {
    onBtn.classList.remove('active');
    for (const el of Object.values(switches)) el.classList.remove('active');
    if (modeHint) modeHint.classList.remove('active');
    currentlyActive.clear();
    cornerModeActive = false;
}

// ── Show / Hide ───────────────────────────────────────────────────────────────

function openUI()  { root.classList.remove('hidden'); root.classList.add('visible'); }
function closeUI() { root.classList.remove('visible'); root.classList.add('hidden'); clearAllActive(); }
function showUI()  { root.classList.remove('hidden'); root.classList.add('visible'); }
function hideUI()  { root.classList.remove('visible'); root.classList.add('hidden'); clearAllActive(); }

// ── Message bus ───────────────────────────────────────────────────────────────

window.addEventListener('message', function (event) {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'open':  openUI();  break;
        case 'close': closeUI(); break;
        case 'show':  showUI();  break;
        case 'hide':  hideUI();  break;

        case 'keys':
            applyHeldKeys(
                Array.isArray(data.held) ? data.held : [],
                !!data.cornerMode,
                data.mx || 0,
                data.my || 0
            );
            break;

        default: break;
    }
});

// ── NUI ready callback ────────────────────────────────────────────────────────

fetch('https://mnc-hydroui/ready', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
}).catch(() => {});

})();