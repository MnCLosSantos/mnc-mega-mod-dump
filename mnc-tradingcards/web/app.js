/* ═══════════════════════════════════════════════════════
   MNC TRADING CARDS — Frontend  v1.1
═══════════════════════════════════════════════════════ */
'use strict';

// ── State ──────────────────────────────────────────────
var state = {
    sets:           {},
    rarities:       {},
    storedCards:    [],
    inventoryCards: [],
    binderId:       null,
    pendingCards:   [],
    currentSetId:   null,
    shopCards:      [],
    shopSelected:   {},   // cardid → true
    shopMult:       0.8,
    pendingClaim:   false, // true while a rolled pack hasn't been claimed yet
    previewMode:    false, // true for /cardpreview and /cardgive (read-only catalog browse)
    grantMode:      false, // true for /cardgive only -- shows a "Give to Self" button per card
    imageSources:      null, // { fivem, github1, github2, ... } -- from Config.VehicleImageSources
    imageSourceOrder:  null, // e.g. ['fivem','github1','github2'] -- from Config.VehicleImageSourceOrder
};

// ── Rarity fallbacks ───────────────────────────────────
var RARITY_DEF = {
    common:    { label: 'Common',     holo: false, value: 10   },
    uncommon:  { label: 'Uncommon',   holo: false, value: 50   },
    rare:      { label: 'Rare',       holo: true,  value: 250  },
    ultraRare: { label: 'Ultra Rare', holo: true,  value: 1000 },
    misprint:  { label: 'Misprint',   holo: true,  value: 2500 },
    damaged:   { label: 'Damaged',    holo: false, value: 0    },
};

function getRarity(id) {
    var r = state.rarities && state.rarities[id];
    if (r) return r;
    return RARITY_DEF[id] || RARITY_DEF.common;
}

function getCardValue(data) {
    if (data.value !== undefined && data.value !== null) return data.value;
    return getRarity(data.rarity).value || 0;
}

// ── Image resolution ───────────────────────────────────
// Vehicle-model cards (no custom `image`) resolve their picture from a
// chain of sources instead of one hardcoded CDN: the official FiveM
// docs CDN first, then any GitHub image stores configured in
// Config.VehicleImageSources (config.lua), pushed down to the NUI as
// state.imageSources / state.imageSourceOrder. The first URL that
// actually loads wins -- imgFallback() walks the chain on each <img>
// error. Same defaults are baked in here so nothing breaks if an
// older client.lua hasn't been updated to send them yet.
var DEFAULT_IMAGE_SOURCES = {
    fivem:   'https://docs.fivem.net/vehicles/{model}.webp',
    github1: 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    github2: 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
};
var DEFAULT_IMAGE_SOURCE_ORDER = ['fivem', 'github1', 'github2'];

function getImageSources()     { return state.imageSources || DEFAULT_IMAGE_SOURCES; }
function getImageSourceOrder() {
    var order = state.imageSourceOrder;
    return (order && order.length) ? order : DEFAULT_IMAGE_SOURCE_ORDER;
}

// Every URL worth trying, in order, for a given vehicle model.
function modelImgCandidates(model) {
    if (!model) return [];
    var sources = getImageSources();
    var urls = [];
    getImageSourceOrder().forEach(function(key) {
        var tpl = sources[key];
        if (!tpl) return;
        urls.push(tpl.split('{model}').join(model));
        // The FiveM docs CDN also serves a plain .png at the same path --
        // worth a second try before moving on to the next source.
        if (key === 'fivem' && tpl.indexOf('.webp') !== -1) {
            urls.push(tpl.split('{model}').join(model).replace(/\.webp$/, '.png'));
        }
    });
    return urls;
}

function cardImg(data) {
    if (data.image) return data.image;
    var candidates = modelImgCandidates(data.model);
    return candidates[0] || '';
}
function cardBg(data) {
    return data.background || '';
}
function imgFallback(img, data) {
    if (data.image) { img.onerror = null; img.style.visibility = 'hidden'; return; }
    var candidates = modelImgCandidates(data.model);
    var idx = parseInt(img.dataset.srcIdx || '0', 10) + 1;
    if (idx >= candidates.length) {
        img.onerror = null;
        img.style.visibility = 'hidden';
        return;
    }
    img.dataset.srcIdx = String(idx);
    img.src = candidates[idx];
}

// ── Set icons — emoji or FontAwesome classes (e.g. "fa-solid fa-car") ──
function isFaIcon(icon) {
    return typeof icon === 'string' && /(^|\s)fa-/.test(icon);
}
function sanitizeFaClasses(icon) {
    return icon.replace(/[^a-zA-Z0-9\-\s]/g, '').trim();
}
// For places building innerHTML strings
function iconHTML(icon) {
    if (isFaIcon(icon)) return '<i class="' + sanitizeFaClasses(icon) + '"></i>';
    var span = document.createElement('span');
    span.textContent = icon || '';
    return span.innerHTML;
}
// For places building DOM nodes directly
function makeIconEl(icon) {
    var el;
    if (isFaIcon(icon)) {
        el = document.createElement('i');
        sanitizeFaClasses(icon).split(/\s+/).filter(Boolean).forEach(function(c) { el.classList.add(c); });
    } else {
        el = document.createElement('span');
        el.textContent = icon || '';
    }
    return el;
}

// ── NUI fetch ──────────────────────────────────────────
function nuiFetch(endpoint, body) {
    if (typeof GetParentResourceName !== 'function') return;
    fetch('https://' + GetParentResourceName() + '/' + endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body || {}),
    }).catch(function() {});
}

// ══════════════════════════════════════════════════════
//  SOUNDS
// ══════════════════════════════════════════════════════
var _audioCtx = null;
function getAudioCtx() {
    if (!_audioCtx) _audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    return _audioCtx;
}

var _soundCache = {};
function playSound(name, vol) {
    vol = vol !== undefined ? vol : 0.6;
    var src = 'sounds/' + name;
    if (_soundCache[name]) {
        try {
            var clone = _soundCache[name].cloneNode();
            clone.volume = vol;
            clone.play().catch(function(){});
        } catch(e) {}
        return;
    }
    // Try .ogg first, fall back to .mp3
    var audio = new Audio(src + '.ogg');
    audio.volume = vol;
    audio.addEventListener('canplaythrough', function() {
        _soundCache[name] = audio;
        audio.play().catch(function(){});
    }, { once: true });
    audio.addEventListener('error', function() {
        var mp3 = new Audio(src + '.mp3');
        mp3.volume = vol;
        _soundCache[name] = mp3;
        mp3.play().catch(function(){});
    }, { once: true });
}

function playSoundForRarity(rarity) {
    if (rarity === 'misprint')  { playSound('misprint', 0.8); return; }
    if (rarity === 'damaged')   { playSound('damaged',  0.6); return; }
    if (rarity === 'ultraRare') { playSound('ultraRare', 0.75); return; }
    if (rarity === 'rare')      { playSound('rare',     0.65); return; }
    playSound('reveal', 0.5);
}

// ── Particles ──────────────────────────────────────────
var P_COLORS = ['#fbbf24', '#f43f5e', '#fb923c', '#e2e8f0'];
function spawnParticles(container, extra) {
    if (!container) return;
    var count = extra ? 20 : 10;
    for (var i = 0; i < count; i++) {
        var p = document.createElement('div');
        p.className = 'tc-particle';
        var sz    = (Math.random() * 3 + 1).toFixed(1);
        var left  = (Math.random() * 86 + 7).toFixed(1);
        var dur   = (Math.random() * 2 + 2.5).toFixed(1);
        var delay = (Math.random() * 4).toFixed(1);
        var col   = P_COLORS[Math.floor(Math.random() * P_COLORS.length)];
        p.style.cssText = 'width:' + sz + 'px;height:' + sz + 'px;left:' + left + '%;bottom:4%;background:' + col + ';box-shadow:0 0 ' + (sz * 2) + 'px ' + col + ';--dur:' + dur + 's;--delay:' + delay + 's;';
        container.appendChild(p);
    }
}

// ══════════════════════════════════════════════════════
//  BUILD CARD
//  options: { faceDown, large, tilt, small }
// ══════════════════════════════════════════════════════
function buildCard(data, options) {
    options = options || {};

    var rarity    = data.rarity || 'common';
    var rDef      = getRarity(rarity);
    var setLbl    = data.setLabel || (state.sets[data.setId] && state.sets[data.setId].label) || '';
    var isHolo    = rDef.holo ? true : false;
    var isUltra   = rarity === 'ultraRare';
    var isMisprint = !!(data.isMisprint || data.rarity === 'misprint');
    var isDamaged  = !!(data.isDamaged  || data.rarity === 'damaged');

    // Print number label — custom printNum or sequential #NNN / TOTAL (per-set, starts at 1)
    // Misprints show their base card number but with "MISPRINT" replacing the count
    var setCardCount = state.sets[data.setId] ? state.sets[data.setId].cards.length : 0;
    var numStr = String(data.number || 0);
    while (numStr.length < 3) numStr = '0' + numStr;

    // The printNum from server is the global sequential print (e.g. "#00042 [Military Forces]")
    // We display only the global portion on the card face, and show both numbers on hover
    var globalPrint = data.printNum || '';
    var printLabel;
    if (isMisprint) {
        printLabel = '#' + numStr + ' / MISPRINT';
    } else {
        printLabel = '#' + numStr + (setCardCount > 0 ? ' / ' + setCardCount : '');
    }

    var bgUrl = cardBg(data);

    var wrap = document.createElement('div');
    wrap.className = 'tc-card-perspective' +
        (options.large ? ' large' : '') +
        (options.small ? ' small' : '');

    var card = document.createElement('div');
    card.className = 'tc-card';
    card.dataset.rarity = rarity;
    if (isMisprint) card.classList.add('is-misprint');
    if (isDamaged)  card.classList.add('is-damaged');

    var face = document.createElement('div');
    face.className = 'tc-face';

    // Background image layer
    if (bgUrl) {
        var bgLayer = document.createElement('div');
        bgLayer.className = 'tc-bg-layer';
        bgLayer.style.backgroundImage = 'url(' + bgUrl + ')';
        face.appendChild(bgLayer);
    }

    var header = document.createElement('div');
    header.className = 'tc-header';

    // Print number on left, badge on right
    var printEl = document.createElement('span');
    printEl.className = 'tc-num';
    printEl.textContent = printLabel;
    // Tooltip: show global print number (includes set name)
    if (isMisprint) {
        printEl.title = 'Card #' + (data.number || 0) + ' from the ' + (setLbl || 'set') + ' — this is a rare MISPRINT variant';
    } else if (globalPrint) {
        printEl.title = globalPrint;
    }

    var badge = document.createElement('span');
    badge.className = 'tc-badge';
    badge.textContent = rDef.label;

    header.appendChild(badge);

    // Special overlays for misprint / damaged
    if (isMisprint) {
        var mpStamp = document.createElement('div');
        mpStamp.className = 'tc-misprint-stamp';
        mpStamp.textContent = 'MISPRINT';
        face.appendChild(mpStamp);
    }
    if (isDamaged) {
        var dmgOverlay = document.createElement('div');
        dmgOverlay.className = 'tc-damaged-overlay';
        dmgOverlay.innerHTML = '<div class="tc-damaged-x">✕</div><div class="tc-damaged-label">DAMAGED</div>';
        face.appendChild(dmgOverlay);
    }

    var imgWrap = document.createElement('div');
    imgWrap.className = 'tc-img-wrap';

    var img = document.createElement('img');
    img.className = 'tc-img';
    img.dataset.srcIdx = '0';
    img.src = cardImg(data);
    img.alt = data.name || '';
    img.loading = 'lazy';
    (function(d) { img.onerror = function() { imgFallback(img, d); }; })(data);
    imgWrap.appendChild(img);

    // Value label (hidden from face, kept for shop logic via data attribute)
    var cardVal = getCardValue(data);
    var footer = document.createElement('div');
    footer.className = 'tc-footer';
    footer.innerHTML =
        '<div class="tc-footer-line"></div>' +
        '<div class="tc-name">' + (data.name || '') + '</div>' +
        '<div class="tc-footer-row">' +
            '<div class="tc-set">' + setLbl + '</div>' +
            '<div class="tc-value' + (isDamaged ? ' tc-value-zero' : '') + '" data-value="' + cardVal + '">$' + cardVal.toLocaleString() + '</div>' +
        '</div>' +
        '<div class="tc-print-num" title="' + (printEl.title || '') + '">' + printLabel + '</div>';

    face.appendChild(header);
    face.appendChild(imgWrap);
    face.appendChild(footer);
    card.appendChild(face);

    if (isHolo || isMisprint) {
        var lines = document.createElement('div');
        lines.className = 'tc-holo tc-holo-lines' + (isMisprint ? ' misprint-holo' : '');
        card.appendChild(lines);

        var spot = document.createElement('div');
        spot.className = 'tc-holo tc-holo-spot';
        card.appendChild(spot);

        if (isUltra || isMisprint) {
            var scan = document.createElement('div');
            scan.className = 'tc-holo tc-holo-scan';
            card.appendChild(scan);
        }
    }

    if (isUltra || isMisprint) {
        var pc = document.createElement('div');
        pc.className = 'tc-particles';
        card.appendChild(pc);
        spawnParticles(pc, isMisprint);
    }

    if (options.faceDown) {
        var back = document.createElement('div');
        back.className = 'tc-back';
        back.innerHTML = '<div class="tc-back-circle">&#x1F0CF;</div>';
        card.appendChild(back);

        back.addEventListener('click', function() {
            back.classList.add('revealed');
            playSoundForRarity(rarity);
            if (options.tilt) enableTilt(wrap, card);
        }, { once: true });
    }

    wrap.appendChild(card);
    if (options.tilt && !options.faceDown) enableTilt(wrap, card);

    return wrap;
}

// ══════════════════════════════════════════════════════
//  TILT  — listeners on wrap only, never on document
// ══════════════════════════════════════════════════════
function enableTilt(wrap, card) {
    wrap.addEventListener('mousemove', function(e) {
        var r  = wrap.getBoundingClientRect();
        var dx = (e.clientX - (r.left + r.width  / 2)) / (r.width  / 2);
        var dy = (e.clientY - (r.top  + r.height / 2)) / (r.height / 2);
        card.style.transform =
            'rotateX(' + (-(dy * 14)).toFixed(2) + 'deg) rotateY(' + (dx * 14).toFixed(2) + 'deg) scale(1.04)';
        var sp = card.querySelector('.tc-holo-spot');
        if (sp) {
            sp.style.setProperty('--mx', ((e.clientX - r.left) / r.width  * 100).toFixed(1) + '%');
            sp.style.setProperty('--my', ((e.clientY - r.top)  / r.height * 100).toFixed(1) + '%');
        }
    });
    wrap.addEventListener('mouseleave', function() {
        card.style.transform = 'rotateX(0deg) rotateY(0deg) scale(1)';
    });
}

// ══════════════════════════════════════════════════════
//  SCREEN MANAGEMENT
// ══════════════════════════════════════════════════════
function hideAll() {
    document.querySelectorAll('.screen').forEach(function(s) { s.classList.add('hidden'); });
    document.body.style.display = 'none';
}
function showScreen(id) {
    document.querySelectorAll('.screen').forEach(function(s) { s.classList.add('hidden'); });
    document.body.style.display = 'block';
    document.getElementById(id).classList.remove('hidden');
}
function closeUI() {
    if (state.pendingClaim) {
        // Tell the server it's safe to write the rolled cards to SQL /
        // the player's inventory now that the reveal has been dismissed.
        nuiFetch('claimPack');
        state.pendingClaim = false;
    }
    hideAll();
    nuiFetch('closeUI');
}
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeUI();
});

// ══════════════════════════════════════════════════════
//  PACK OPENING — TEAR UI
// ══════════════════════════════════════════════════════
var packTearState = { dragging: false, startY: 0, currentY: 0, threshold: 90, opened: false };

function showPackOpen(packLabel, cards) {
    state.pendingCards     = cards;
    packTearState.opened   = false;
    packTearState.dragging = false;
    var flap = document.getElementById('packFlap');
    if (flap) flap.classList.remove('torn');

    var icons = { basic: '🃏', premium: '✨', legendary: '👑' };
    var icon  = '🃏';
    var ll    = (packLabel || '').toLowerCase();
    if (ll.indexOf('premium')   !== -1) icon = '✨';
    if (ll.indexOf('legendary') !== -1) icon = '👑';

    var el;
    el = document.getElementById('packLabelIcon'); if (el) el.textContent = icon;
    el = document.getElementById('packLabelName'); if (el) el.textContent = (packLabel || 'CARD PACK').toUpperCase();
    el = document.getElementById('packOpenTitle'); if (el) el.textContent = (packLabel || 'Card Pack').toUpperCase();

    drawProgress(0);
    showScreen('screen-pack-open');
    initPackDrag();
}

function initPackDrag() {
    var tearZone = document.getElementById('packTearZone');
    var wrapper  = document.getElementById('packWrapper');
    if (!tearZone || !wrapper) return;
    var newZone = tearZone.cloneNode(true);
    tearZone.parentNode.replaceChild(newZone, tearZone);

    function onDragStart(clientY) {
        if (packTearState.opened) return;
        packTearState.dragging = true;
        packTearState.startY   = clientY;
        packTearState.currentY = clientY;
        var prog = document.getElementById('packProgress');
        if (prog) prog.classList.add('visible');
    }
    function onDragMove(clientY) {
        if (!packTearState.dragging || packTearState.opened) return;
        packTearState.currentY = clientY;
        var delta = Math.max(0, packTearState.startY - clientY);
        var pct   = Math.min(1, delta / packTearState.threshold);
        drawProgress(pct);
        var body = document.querySelector('.pack-body');
        if (body) body.style.transform = 'translateY(' + (-delta * 0.08) + 'px)';
        if (pct >= 1) triggerPackOpen();
    }
    function onDragEnd() {
        if (!packTearState.dragging) return;
        packTearState.dragging = false;
        if (!packTearState.opened) {
            drawProgress(0);
            var body = document.querySelector('.pack-body');
            if (body) body.style.transform = '';
            var prog = document.getElementById('packProgress');
            if (prog) prog.classList.remove('visible');
        }
    }
    newZone.addEventListener('mousedown', function(e) { onDragStart(e.clientY); });
    document.addEventListener('mousemove', function(e) { onDragMove(e.clientY); });
    document.addEventListener('mouseup', onDragEnd);
    newZone.addEventListener('touchstart', function(e) { onDragStart(e.touches[0].clientY); }, { passive: true });
    document.addEventListener('touchmove', function(e) { onDragMove(e.touches[0].clientY); }, { passive: true });
    document.addEventListener('touchend', onDragEnd);
}

function drawProgress(pct) {
    var canvas = document.getElementById('packProgress');
    if (!canvas) return;
    var ctx = canvas.getContext('2d'), w = canvas.width, h = canvas.height, r = 18;
    ctx.clearRect(0, 0, w, h);
    ctx.beginPath(); ctx.arc(w/2, h/2, r, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 3; ctx.stroke();
    if (pct > 0) {
        ctx.beginPath();
        ctx.arc(w/2, h/2, r, -Math.PI/2, -Math.PI/2 + Math.PI * 2 * pct);
        var col = pct >= 1 ? '#fbbf24' : '#60a5fa';
        ctx.strokeStyle = col; ctx.lineWidth = 3; ctx.lineCap = 'round'; ctx.stroke();
        ctx.fillStyle = col; ctx.font = 'bold 13px sans-serif';
        ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
        ctx.fillText('↑', w/2, h/2);
    }
}

function triggerPackOpen() {
    if (packTearState.opened) return;
    packTearState.opened = true;
    playSound('tear', 0.75);

    var flap = document.getElementById('packFlap');
    if (flap) flap.classList.add('torn');
    var body = document.querySelector('.pack-body');
    if (body) {
        body.style.transition = 'transform 0.4s cubic-bezier(0.34,1.56,0.64,1)';
        body.style.transform  = 'translateY(6px) scale(1.02)';
    }
    setTimeout(function() { showPackReveal(state.pendingCards); }, 550);
}

// ══════════════════════════════════════════════════════
//  PACK REVEAL
// ══════════════════════════════════════════════════════
function showPackReveal(cards) {
    state.pendingClaim = true;
    var container = document.getElementById('revealCards');
    container.innerHTML = '';
    cards.forEach(function(cardData, idx) {
        var wrap  = buildCard(cardData, { faceDown: true, tilt: true });
        var inner = wrap.querySelector('.tc-card');
        inner.style.animation = 'cardDeal 0.45s cubic-bezier(0.34,1.56,0.64,1) ' + (idx * 0.13) + 's both';
        container.appendChild(wrap);
    });
    showScreen('screen-reveal');
}
document.getElementById('btnRevealClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

// ══════════════════════════════════════════════════════
//  DISCARD CONFIRM MODAL  (window.confirm won't work in NUI/CEF)
// ══════════════════════════════════════════════════════
function showDiscardConfirm(message, onYes) {
    var existing = document.getElementById('discardConfirmModal');
    if (existing) existing.remove();

    var overlay = document.createElement('div');
    overlay.id = 'discardConfirmModal';
    overlay.style.cssText =
        'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;' +
        'background:rgba(0,0,0,0.7);';

    var box = document.createElement('div');
    box.style.cssText =
        'background:linear-gradient(160deg,#1a2035,#111827);border:1px solid rgba(239,83,80,0.35);' +
        'border-radius:12px;padding:28px 32px;max-width:340px;text-align:center;' +
        'box-shadow:0 20px 60px rgba(0,0,0,0.8);color:#f0f4ff;font-family:var(--font-ui);';

    var icon = document.createElement('div');
    icon.style.cssText = 'font-size:2rem;margin-bottom:12px;';
    icon.textContent = '🗑';

    var msg = document.createElement('div');
    msg.style.cssText = 'font-size:0.9rem;margin-bottom:22px;line-height:1.5;color:#cbd5e1;';
    msg.textContent = message;

    var btnRow = document.createElement('div');
    btnRow.style.cssText = 'display:flex;gap:10px;justify-content:center;';

    var cancelBtn = document.createElement('button');
    cancelBtn.style.cssText =
        'padding:8px 24px;border-radius:7px;border:1px solid rgba(255,255,255,0.15);' +
        'background:transparent;color:#7a8fb0;font-family:var(--font-ui);font-size:0.85rem;cursor:pointer;';
    cancelBtn.textContent = 'Keep';
    cancelBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); });

    var yesBtn = document.createElement('button');
    yesBtn.style.cssText =
        'padding:8px 28px;border-radius:7px;border:none;' +
        'background:linear-gradient(135deg,#ef5350,#b71c1c);color:#fff;' +
        'font-family:var(--font-ui);font-size:0.85rem;font-weight:700;cursor:pointer;' +
        'box-shadow:0 3px 14px rgba(239,83,80,0.4);';
    yesBtn.textContent = 'Discard';
    yesBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); onYes(); });

    btnRow.appendChild(cancelBtn);
    btnRow.appendChild(yesBtn);
    box.appendChild(icon);
    box.appendChild(msg);
    box.appendChild(btnRow);
    overlay.appendChild(box);
    document.body.appendChild(overlay);

    overlay.addEventListener('click', function(e) { if (e.target === overlay) overlay.remove(); });
}

// ══════════════════════════════════════════════════════
//  SINGLE CARD VIEW
// ══════════════════════════════════════════════════════
function viewCard(cardData) {
    var container = document.getElementById('singleCardContainer');
    container.innerHTML = '';
    var wrap = buildCard(cardData, { tilt: true, large: true });
    container.appendChild(wrap);

    // Damaged — show discard button
    var discardArea = document.getElementById('cardViewDiscard');
    if (discardArea) discardArea.innerHTML = '';
    if (cardData.isDamaged && discardArea) {
        var btn = document.createElement('button');
        btn.className   = 'btn-danger';
        btn.textContent = '🗑 Discard Damaged Card';
        (function(cd) {
            btn.addEventListener('click', function() {
                playSound('click', 0.5);
                showDiscardConfirm('This card is worthless and cannot be sold or stored. Permanently discard it?', function() {
                    nuiFetch('discardDamaged', { cardid: cd.cardid || cd.id });
                    closeUI();
                });
            });
        })(cardData);
        discardArea.appendChild(btn);
    }

    showScreen('screen-card');
}
document.getElementById('btnCardClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

// ══════════════════════════════════════════════════════
//  BINDER
// ══════════════════════════════════════════════════════
function openBinder(data) {
    state.binderId       = data.binderId      || null;
    state.sets           = data.sets          || {};
    state.rarities       = data.rarities      || {};
    state.storedCards    = data.storedCards    || [];
    state.inventoryCards = data.inventoryCards || [];
    state.currentSetId   = null;
    state.previewMode    = !!data.previewMode;
    state.grantMode      = !!data.grantMode;

    buildBinderSidebar();
    var firstSetId = Object.keys(state.sets).sort(function(a, b) {
        return ((state.sets[a].label || '') < (state.sets[b].label || '') ? -1 : 1);
    })[0];
    if (firstSetId) renderBinderSet(firstSetId);
    showScreen('screen-binder');
}

function buildBinderSidebar() {
    var list = document.getElementById('binderSetList');
    list.innerHTML = '';

    // ── Pinned MISPRINTS category at the top ──────────────────
    function _isMp(c) { return !!(c.isMisprint || c.rarity === 'misprint'); }
    var allMisprints = state.storedCards.filter(function(c) { return _isMp(c); })
        .concat(state.inventoryCards.filter(function(c) { return _isMp(c); }));
    var mpCount = allMisprints.length;

    var mpPending = state.inventoryCards.filter(function(c) { return _isMp(c); }).length;

    var mpItem = document.createElement('div');
    mpItem.className = 'binder-set-item binder-misprint-category';
    mpItem.dataset.setId = '__misprints__';
    mpItem.innerHTML =
        '<span class="binder-set-icon">✦</span>' +
        '<div class="binder-set-info">' +
            '<div class="binder-set-name">Misprints</div>' +
            '<div class="binder-set-count">' + mpCount + ' card' + (mpCount === 1 ? '' : 's') + '</div>' +
        '</div>' +
        (mpPending > 0 ? '<span class="binder-pending-badge binder-pending-badge--misprint" title="' + mpPending + ' misprint' + (mpPending === 1 ? '' : 's') + ' in inventory — tap to store">＋' + mpPending + '</span>' : '') +
        '<span class="binder-set-tick ' + (mpCount > 0 ? 'tick-yes' : 'tick-no') + '">' + (mpCount > 0 ? mpCount : '') + '</span>';

    mpItem.addEventListener('click', function() {
        playSound('click', 0.5);
        document.querySelectorAll('.binder-set-item').forEach(function(i) { i.classList.remove('active'); });
        mpItem.classList.add('active');
        state.currentSetId = '__misprints__';
        renderMisprints();
    });
    list.appendChild(mpItem);

    // ── Divider ───────────────────────────────────────────────
    var div = document.createElement('div');
    div.className = 'binder-sidebar-divider';
    list.appendChild(div);

    // ── Sets sorted alphabetically ────────────────────────────
    var sortedEntries = Object.entries(state.sets).sort(function(a, b) {
        var la = (a[1].label || '').toLowerCase();
        var lb = (b[1].label || '').toLowerCase();
        return la < lb ? -1 : la > lb ? 1 : 0;
    });

    sortedEntries.forEach(function(entry) {
        var setId   = entry[0];
        var setData = entry[1];

        var ownedNums = new Set();
        state.storedCards.forEach(function(c)    { if (c.setId === setId && !_isMp(c)) ownedNums.add(c.number); });
        state.inventoryCards.forEach(function(c) { if (c.setId === setId && !_isMp(c)) ownedNums.add(c.number); });
        var owned = ownedNums.size;
        var total = setData.cards.length;
        var done  = owned >= total;

        // Count inventory cards for this set that are NOT yet stored (and not misprints/damaged)
        var storedNums = new Set();
        state.storedCards.forEach(function(c) { if (c.setId === setId && !_isMp(c)) storedNums.add(c.number); });
        var pendingCount = state.inventoryCards.filter(function(c) {
            return c.setId === setId && !_isMp(c) && !c.isDamaged && !storedNums.has(c.number);
        }).length;

        var item = document.createElement('div');
        item.className     = 'binder-set-item';
        item.dataset.setId = setId;

        item.innerHTML =
            '<span class="binder-set-icon">' + iconHTML(setData.icon || '🃏') + '</span>' +
            '<div class="binder-set-info">' +
                '<div class="binder-set-name">' + setData.label + '</div>' +
                '<div class="binder-set-count">' + owned + ' / ' + total + '</div>' +
            '</div>' +
            (pendingCount > 0 ? '<span class="binder-pending-badge" title="' + pendingCount + ' card' + (pendingCount === 1 ? '' : 's') + ' in inventory ready to store">\uFF0B' + pendingCount + '</span>' : '') +
            '<span class="binder-set-tick ' + (done ? 'tick-yes' : 'tick-no') + '">' + (done ? '\u2713' : '') + '</span>';

        item.addEventListener('click', function() {
            playSound('click', 0.5);
            document.querySelectorAll('.binder-set-item').forEach(function(i) { i.classList.remove('active'); });
            item.classList.add('active');
            renderBinderSet(setId);
        });
        list.appendChild(item);
    });
}

function renderBinderSet(setId) {
    var setData = state.sets[setId];
    if (!setData) return;
    state.currentSetId = setId;

    var grid    = document.getElementById('binderGrid');
    var titleEl = document.getElementById('binderSetTitle');
    var progEl  = document.getElementById('binderProgress');
    var tabEl   = document.getElementById('binderPageTab');

    var storedByNum    = {};
    var inventoryByNum = {};

    function _isMisprint(c) { return !!(c.isMisprint || c.rarity === 'misprint'); }

    state.storedCards.forEach(function(c) {
        if (c.setId === setId && !_isMisprint(c) && !c.isDamaged && !storedByNum[c.number]) {
            storedByNum[c.number] = c;
        }
    });
    state.inventoryCards.forEach(function(c) {
        if (c.setId === setId && !_isMisprint(c) && !inventoryByNum[c.number]) {
            inventoryByNum[c.number] = c;
        }
    });

    var ownedCount = Object.keys(storedByNum).length +
        Object.keys(inventoryByNum).filter(function(n) { return !storedByNum[n]; }).length;

    titleEl.textContent = setData.label;
    progEl.textContent  = ownedCount + ' / ' + setData.cards.length + ' collected';
    if (tabEl) {
        tabEl.innerHTML = '';
        tabEl.appendChild(makeIconEl(setData.icon || '🃏'));
        tabEl.appendChild(document.createTextNode(' ' + setData.label.toUpperCase()));
    }
    grid.innerHTML = '';

    var sorted = setData.cards.slice().sort(function(a, b) { return a.number - b.number; });

    sorted.forEach(function(def) {
        var stored = storedByNum[def.number];
        var inInv  = inventoryByNum[def.number];

        if (stored) {
            var cardData = {
                setId: setId, setLabel: setData.label, number: def.number, name: def.name,
                model: def.model, image: def.image || null, background: stored.background || def.background || null,
                rarity: stored.rarity, isMisprint: stored.isMisprint, isDamaged: stored.isDamaged,
                printNum: stored.printNum, value: stored.value,
            };
            var wrap = buildCard(cardData, { tilt: true });
            wrap.dataset.setId  = setId;
            wrap.dataset.number = def.number;

            if (state.previewMode) {
                // Read-only catalog browse (/cardpreview, /cardgive) --
                // these aren't real owned cards, so no drag-to-remove.
                // /cardgive additionally shows a "Give to Self" button.
                if (state.grantMode) {
                    (function(sId, num) {
                        var overlay = document.createElement('div');
                        overlay.className = 'binder-store-overlay';
                        var btn = document.createElement('button');
                        btn.className   = 'binder-store-btn binder-give-btn';
                        btn.textContent = '+ Give to Self';
                        btn.addEventListener('click', function(e) {
                            e.stopPropagation();
                            playSound('click', 0.5);
                            btn.disabled    = true;
                            btn.textContent = 'Granting…';
                            nuiFetch('adminGiveCard', { setId: sId, number: num });
                            setTimeout(function() {
                                btn.disabled    = false;
                                btn.textContent = '+ Give to Self';
                            }, 900);
                        });
                        overlay.appendChild(btn);
                        wrap.style.position = 'relative';
                        wrap.appendChild(overlay);
                    })(setId, def.number);
                }
                grid.appendChild(wrap);

            } else {
                var hint = document.createElement('div');
                hint.className = 'binder-remove-hint';
                hint.textContent = '↑ Drag up to remove';
                wrap.style.position = 'relative';
                wrap.appendChild(hint);

                wrap.dataset.cardid = stored.cardid;
                wrap.dataset.stored = '1';

                addDragToRemove(wrap, stored);
                grid.appendChild(wrap);
            }

        } else if (inInv) {
            var cardData2 = {
                setId: setId, setLabel: setData.label, number: def.number, name: def.name,
                model: def.model, image: def.image || null, background: inInv.background || def.background || null,
                rarity: inInv.rarity, isMisprint: inInv.isMisprint, isDamaged: inInv.isDamaged,
                printNum: inInv.printNum, value: inInv.value,
            };
            var wrap2 = buildCard(cardData2, { tilt: true });

            // Damaged cards get a warning overlay instead of a store button
            if (inInv.isDamaged) {
                var dmgOverlay2 = document.createElement('div');
                dmgOverlay2.className = 'binder-store-overlay binder-damaged-overlay';
                var dmgMsg = document.createElement('div');
                dmgMsg.className = 'binder-damaged-msg';
                dmgMsg.textContent = '⚠ Damaged — cannot store';
                dmgOverlay2.appendChild(dmgMsg);
                wrap2.style.position = 'relative';
                wrap2.appendChild(dmgOverlay2);
            } else {
                var overlay = document.createElement('div');
                overlay.className = 'binder-store-overlay';
                var btn = document.createElement('button');
                btn.className   = 'binder-store-btn';
                btn.textContent = '+ Store in Binder';
                btn.dataset.cardid = inInv.cardid;
                btn.dataset.slot   = inInv.slot || '';

                (function(cardRef, btnEl) {
                    btnEl.addEventListener('click', function(e) {
                        e.stopPropagation();
                        playSound('click', 0.5);
                        btnEl.disabled    = true;
                        btnEl.textContent = 'Storing…';
                        nuiFetch('storeCardInBinder', { cardid: cardRef.cardid, slot: cardRef.slot });
                        btnEl.textContent = 'Stored ✓';
                        overlay.style.display = 'none';

                        state.inventoryCards = state.inventoryCards.filter(function(c) { return c.cardid !== cardRef.cardid; });
                        state.storedCards.push(cardRef);

                        setTimeout(function() {
                            buildBinderSidebar();
                            renderBinderSet(cardRef.setId);
                            document.querySelectorAll('.binder-set-item').forEach(function(i) {
                                i.classList.toggle('active', i.dataset.setId === cardRef.setId);
                            });
                        }, 400);
                    });
                })(inInv, btn);

                overlay.appendChild(btn);
                wrap2.style.position = 'relative';
                wrap2.appendChild(overlay);
            }
            grid.appendChild(wrap2);

        } else {
            var numStr2 = String(def.number);
            while (numStr2.length < 3) numStr2 = '0' + numStr2;
            var slot = document.createElement('div');
            slot.className = 'slot-empty';
            slot.innerHTML = '<div class="slot-empty-num">#' + numStr2 + '</div><div class="slot-empty-name">' + def.name + '</div>';
            grid.appendChild(slot);
        }
    });

    document.querySelectorAll('.binder-set-item').forEach(function(i) {
        i.classList.toggle('active', i.dataset.setId === setId);
    });
}

// ══════════════════════════════════════════════════════
//  MISPRINTS PAGE — standalone category, no set slots
// ══════════════════════════════════════════════════════
function renderMisprints() {
    var grid    = document.getElementById('binderGrid');
    var titleEl = document.getElementById('binderSetTitle');
    var progEl  = document.getElementById('binderProgress');
    var tabEl   = document.getElementById('binderPageTab');

    var storedMisprints    = state.storedCards.filter(function(c)    { return !!(c.isMisprint || c.rarity === 'misprint'); });
    var inventoryMisprints = state.inventoryCards.filter(function(c) { return !!(c.isMisprint || c.rarity === 'misprint'); });
    var total = storedMisprints.length + inventoryMisprints.length;

    titleEl.textContent = 'Misprints';
    progEl.textContent  = total + ' misprint' + (total === 1 ? '' : 's') + ' collected';
    if (tabEl) tabEl.textContent = '✦ MISPRINTS';
    grid.innerHTML = '';

    if (total === 0) {
        var empty = document.createElement('div');
        empty.className = 'slot-empty';
        empty.style.cssText = 'grid-column:1/-1;text-align:center;padding:40px 20px;opacity:0.5;';
        empty.innerHTML = '<div style="font-size:2rem;margin-bottom:8px;">✦</div>' +
            '<div>No misprints found yet.</div>' +
            '<div style="font-size:0.8rem;margin-top:6px;">Misprints are rare errors that drop from packs — keep opening!</div>';
        grid.appendChild(empty);
        return;
    }

    // ── Stored misprints (drag to remove) ──────────────────
    storedMisprints.forEach(function(c) {
        var setData = state.sets[c.setId] || {};
        var mpWrap  = buildCard({
            setId: c.setId, setLabel: c.setLabel || setData.label || '',
            number: c.number, name: c.name,
            model: c.model, image: c.image || null, background: c.background || null,
            rarity: 'misprint', isMisprint: true, isDamaged: false,
            printNum: c.printNum, value: c.value,
        }, { tilt: true });

        var hint = document.createElement('div');
        hint.className  = 'binder-remove-hint';
        hint.textContent = '↑ Drag up to remove';
        mpWrap.style.position = 'relative';
        mpWrap.appendChild(hint);
        addDragToRemove(mpWrap, c);
        grid.appendChild(mpWrap);
    });

    // ── Inventory misprints (store button) ─────────────────
    inventoryMisprints.forEach(function(c) {
        var setData  = state.sets[c.setId] || {};
        var mpWrap2  = buildCard({
            setId: c.setId, setLabel: c.setLabel || setData.label || '',
            number: c.number, name: c.name,
            model: c.model, image: c.image || null, background: c.background || null,
            rarity: 'misprint', isMisprint: true, isDamaged: false,
            printNum: c.printNum, value: c.value,
        }, { tilt: true });

        var mpOverlay = document.createElement('div');
        mpOverlay.className = 'binder-store-overlay';
        var mpBtn = document.createElement('button');
        mpBtn.className   = 'binder-store-btn binder-store-btn-misprint';
        mpBtn.textContent = '+ Store Misprint';
        mpBtn.dataset.cardid = c.cardid;

        (function(cardRef, btnEl, ov) {
            btnEl.addEventListener('click', function(e) {
                e.stopPropagation();
                playSound('click', 0.5);
                btnEl.disabled    = true;
                btnEl.textContent = 'Storing…';
                nuiFetch('storeCardInBinder', { cardid: cardRef.cardid, slot: cardRef.slot });
                btnEl.textContent = 'Stored ✓';
                ov.style.display  = 'none';

                state.inventoryCards = state.inventoryCards.filter(function(c2) { return c2.cardid !== cardRef.cardid; });
                state.storedCards.push(cardRef);

                setTimeout(function() {
                    buildBinderSidebar();
                    renderMisprints();
                    document.querySelectorAll('.binder-set-item').forEach(function(i) {
                        i.classList.toggle('active', i.dataset.setId === '__misprints__');
                    });
                }, 400);
            });
        })(c, mpBtn, mpOverlay);

        mpOverlay.appendChild(mpBtn);
        mpWrap2.style.position = 'relative';
        mpWrap2.appendChild(mpOverlay);
        grid.appendChild(mpWrap2);
    });

    document.querySelectorAll('.binder-set-item').forEach(function(i) {
        i.classList.toggle('active', i.dataset.setId === '__misprints__');
    });
}

// ── DRAG-TO-REMOVE FROM BINDER ─────────────────────────
var dragState = { active: false, wrap: null, cardInfo: null, startX: 0, startY: 0, origRect: null, ghost: null };

function addDragToRemove(wrap, cardInfo) {
    var card = wrap.querySelector('.tc-card');
    if (!card) return;

    function onDragStart(clientX, clientY) {
        if (dragState.active) return;
        dragState.active   = true; dragState.wrap = wrap; dragState.cardInfo = cardInfo;
        dragState.startX   = clientX; dragState.startY = clientY;
        dragState.origRect = wrap.getBoundingClientRect();

        var ghost = wrap.cloneNode(true);
        ghost.style.cssText =
            'position:fixed;top:' + dragState.origRect.top + 'px;left:' + dragState.origRect.left + 'px;' +
            'width:' + dragState.origRect.width + 'px;height:' + dragState.origRect.height + 'px;' +
            'pointer-events:none;z-index:9999;transition:none;box-shadow:0 20px 60px rgba(0,0,0,0.7);filter:brightness(1.15);';
        document.body.appendChild(ghost);
        dragState.ghost = ghost;
        wrap.style.opacity = '0.3';
        var zone = document.getElementById('binderRemoveZone');
        if (zone) zone.classList.add('active');
    }
    function onDragMove(clientX, clientY) {
        if (!dragState.active || dragState.wrap !== wrap) return;
        var dx = clientX - dragState.startX, dy = clientY - dragState.startY;
        if (dragState.ghost) {
            dragState.ghost.style.left = (dragState.origRect.left + dx) + 'px';
            dragState.ghost.style.top  = (dragState.origRect.top  + dy) + 'px';
        }
        var zone = document.getElementById('binderRemoveZone');
        if (zone) {
            var zoneRect = zone.getBoundingClientRect();
            zone.classList.toggle('over', clientY < (zoneRect.top + zoneRect.height + 20));
        }
    }
    function onDragEnd(clientX, clientY) {
        if (!dragState.active || dragState.wrap !== wrap) return;
        var zone     = document.getElementById('binderRemoveZone');
        var zoneRect = zone ? zone.getBoundingClientRect() : null;
        var inZone   = zoneRect && clientY < (zoneRect.top + zoneRect.height + 20);

        if (dragState.ghost) { dragState.ghost.remove(); dragState.ghost = null; }
        wrap.style.opacity = '';
        if (zone) { zone.classList.remove('active'); zone.classList.remove('over'); }

        if (inZone) {
            playSound('click', 0.5);
            nuiFetch('removeCardFromBinder', { cardid: cardInfo.cardid, binderId: state.binderId });
            state.storedCards    = state.storedCards.filter(function(c) { return c.cardid !== cardInfo.cardid; });
            state.inventoryCards.push({
                cardid: cardInfo.cardid, setId: cardInfo.setId, setLabel: cardInfo.setLabel,
                number: cardInfo.number, name: cardInfo.name, model: cardInfo.model,
                image: cardInfo.image || null, background: cardInfo.background || null,
                rarity: cardInfo.rarity, isMisprint: cardInfo.isMisprint, isDamaged: cardInfo.isDamaged,
                printNum: cardInfo.printNum, value: cardInfo.value,
            });
            setTimeout(function() {
                buildBinderSidebar();
                if (state.currentSetId === '__misprints__') {
                    renderMisprints();
                    document.querySelectorAll('.binder-set-item').forEach(function(i) {
                        i.classList.toggle('active', i.dataset.setId === '__misprints__');
                    });
                } else if (state.currentSetId) {
                    renderBinderSet(state.currentSetId);
                    document.querySelectorAll('.binder-set-item').forEach(function(i) {
                        i.classList.toggle('active', i.dataset.setId === state.currentSetId);
                    });
                }
            }, 100);
        }

        dragState.active = false; dragState.wrap = null; dragState.ghost = null;
    }

    card.addEventListener('mousedown', function(e) { e.preventDefault(); onDragStart(e.clientX, e.clientY); });
    document.addEventListener('mousemove', function(e) { onDragMove(e.clientX, e.clientY); });
    document.addEventListener('mouseup',   function(e) { onDragEnd(e.clientX, e.clientY); });
    card.addEventListener('touchstart', function(e) { var t = e.touches[0]; onDragStart(t.clientX, t.clientY); }, { passive: true });
    document.addEventListener('touchmove', function(e) { var t = e.touches[0]; onDragMove(t.clientX, t.clientY); }, { passive: true });
    document.addEventListener('touchend',  function(e) { var t = e.changedTouches[0]; onDragEnd(t.clientX, t.clientY); });
}

document.getElementById('btnBinderClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

// ══════════════════════════════════════════════════════
//  SHOP
// ══════════════════════════════════════════════════════
function openShop(data) {
    state.shopCards    = data.inventoryCards || [];
    state.shopSelected = {};
    state.shopMult     = data.sellMultiplier || 0.8;
    state.sets         = data.sets     || state.sets;
    state.rarities     = data.rarities || state.rarities;
    renderShop();
    showScreen('screen-shop');
}

function renderShop() {
    var mult = state.shopMult;
    var grid = document.getElementById('shopGrid');
    grid.innerHTML = '';
    updateShopTotal();

    if (state.shopCards.length === 0) {
        var empty = document.createElement('div');
        empty.className = 'shop-empty';
        empty.textContent = 'No cards in your inventory.';
        grid.appendChild(empty);
        return;
    }

    // Group by set, sorted alphabetically
    var setGroups = {};
    state.shopCards.forEach(function(c) {
        var key = c.setId || '__unknown__';
        if (!setGroups[key]) setGroups[key] = [];
        setGroups[key].push(c);
    });

    Object.keys(setGroups).sort(function(a, b) {
        var la = ((state.sets[a] && state.sets[a].label) || a).toLowerCase();
        var lb = ((state.sets[b] && state.sets[b].label) || b).toLowerCase();
        return la < lb ? -1 : la > lb ? 1 : 0;
    }).forEach(function(setId) {
        var cards   = setGroups[setId];
        var setData = state.sets[setId] || {};
        var setVal  = cards.reduce(function(s, c) {
            return s + (c.isDamaged ? 0 : Math.floor((c.value || 0) * mult));
        }, 0);

        // Section header
        var hdr = document.createElement('div');
        hdr.className = 'shop-set-header';

        var iconSpan = makeIconEl(setData.icon || '🃏');
        iconSpan.classList.add('shop-set-icon');

        var nameSpan = document.createElement('span');
        nameSpan.className = 'shop-set-name';
        nameSpan.textContent = setData.label || setId;

        var valSpan = document.createElement('span');
        valSpan.className = 'shop-set-val';
        valSpan.textContent = '$' + setVal.toLocaleString();

        var sellSetBtn = document.createElement('button');
        sellSetBtn.className = 'shop-sell-set-btn';
        sellSetBtn.textContent = 'Sell Set';

        hdr.appendChild(iconSpan);
        hdr.appendChild(nameSpan);
        hdr.appendChild(valSpan);
        hdr.appendChild(sellSetBtn);
        grid.appendChild(hdr);

        // Sell-set confirmation inline
        (function(sid, sLabel, sVal, sCards) {
            sellSetBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                playSound('click', 0.5);
                showShopConfirm(
                    'Sell all ' + sLabel + ' cards for $' + sVal.toLocaleString() + '?',
                    function() {
                        nuiFetch('sellSet', { setId: sid });
                        state.shopCards = state.shopCards.filter(function(c) { return c.setId !== sid; });
                        sCards.forEach(function(c) { delete state.shopSelected[c.cardid]; });
                        renderShop();
                    }
                );
            });
        })(setId, setData.label || setId, setVal, cards);

        // Individual card rows
        cards.forEach(function(cardInfo) {
            var sellVal = cardInfo.isDamaged ? 0 : Math.floor((cardInfo.value || 0) * mult);
            var isSelected = !!state.shopSelected[cardInfo.cardid];

            var row = document.createElement('div');
            row.className = 'shop-card-row' + (isSelected ? ' selected' : '');
            row.dataset.cardid = cardInfo.cardid;

            // Rarity colour dot
            var dot = document.createElement('span');
            dot.className = 'shop-rarity-dot';
            dot.dataset.rarity = cardInfo.rarity;

            var nameEl = document.createElement('span');
            nameEl.className = 'shop-card-name';
            nameEl.textContent = cardInfo.name || '';

            var rarityEl = document.createElement('span');
            rarityEl.className = 'shop-card-rarity';
            rarityEl.textContent = getRarity(cardInfo.rarity).label || cardInfo.rarity;

            var priceEl = document.createElement('span');
            priceEl.className = 'shop-card-price' + (cardInfo.isDamaged ? ' price-zero' : '');
            priceEl.textContent = '$' + sellVal.toLocaleString();

            var selBtn = document.createElement('button');
            selBtn.className = 'shop-select-btn';
            selBtn.textContent = isSelected ? '✓' : 'Select';
            if (cardInfo.isDamaged) {
                selBtn.disabled = true;
                selBtn.title    = 'Damaged — no value';
            }

            row.appendChild(dot);
            row.appendChild(nameEl);
            row.appendChild(rarityEl);
            row.appendChild(priceEl);
            row.appendChild(selBtn);
            grid.appendChild(row);

            // Toggle selection — click anywhere on row or the button
            (function(ci, r, sb) {
                function toggle(e) {
                    e.stopPropagation();
                    if (ci.isDamaged) return;
                    playSound('click', 0.5);
                    if (state.shopSelected[ci.cardid]) {
                        delete state.shopSelected[ci.cardid];
                        r.classList.remove('selected');
                        sb.textContent = 'Select';
                    } else {
                        state.shopSelected[ci.cardid] = true;
                        r.classList.add('selected');
                        sb.textContent = '✓';
                    }
                    updateShopTotal();
                }
                r.addEventListener('click', toggle);
            })(cardInfo, row, selBtn);
        });
    });
}

// Simple inline confirm modal (window.confirm doesn't work in NUI)
function showShopConfirm(message, onYes) {
    var existing = document.getElementById('shopConfirmModal');
    if (existing) existing.remove();

    var overlay = document.createElement('div');
    overlay.id = 'shopConfirmModal';
    overlay.style.cssText =
        'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;' +
        'background:rgba(0,0,0,0.6);';

    var box = document.createElement('div');
    box.style.cssText =
        'background:linear-gradient(160deg,#1a2035,#111827);border:1px solid rgba(255,255,255,0.12);' +
        'border-radius:12px;padding:28px 32px;max-width:340px;text-align:center;' +
        'box-shadow:0 20px 60px rgba(0,0,0,0.8);color:#f0f4ff;font-family:var(--font-ui);';

    var msg = document.createElement('div');
    msg.style.cssText = 'font-size:0.9rem;margin-bottom:22px;line-height:1.5;';
    msg.textContent = message;

    var btnRow = document.createElement('div');
    btnRow.style.cssText = 'display:flex;gap:10px;justify-content:center;';

    var cancelBtn = document.createElement('button');
    cancelBtn.style.cssText =
        'padding:8px 24px;border-radius:7px;border:1px solid rgba(255,255,255,0.15);' +
        'background:transparent;color:#7a8fb0;font-family:var(--font-ui);font-size:0.85rem;cursor:pointer;';
    cancelBtn.textContent = 'Cancel';
    cancelBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); });

    var yesBtn = document.createElement('button');
    yesBtn.style.cssText =
        'padding:8px 28px;border-radius:7px;border:none;' +
        'background:linear-gradient(135deg,#f43f5e,#dc2626);color:#fff;' +
        'font-family:var(--font-ui);font-size:0.85rem;font-weight:700;cursor:pointer;' +
        'box-shadow:0 3px 14px rgba(244,63,94,0.4);';
    yesBtn.textContent = 'Sell';
    yesBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); onYes(); });

    btnRow.appendChild(cancelBtn);
    btnRow.appendChild(yesBtn);
    box.appendChild(msg);
    box.appendChild(btnRow);
    overlay.appendChild(box);
    document.body.appendChild(overlay);

    overlay.addEventListener('click', function(e) { if (e.target === overlay) overlay.remove(); });
}

function updateShopTotal() {
    var mult  = state.shopMult;
    var total = 0;
    state.shopCards.forEach(function(c) {
        if (state.shopSelected[c.cardid]) {
            total += c.isDamaged ? 0 : Math.floor((c.value || 0) * mult);
        }
    });
    var el = document.getElementById('shopTotal');
    if (el) el.textContent = '$' + total.toLocaleString();
    var sellBtn = document.getElementById('btnShopSell');
    if (sellBtn) sellBtn.disabled = (Object.keys(state.shopSelected).length === 0);
}

document.getElementById('btnShopClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

document.getElementById('btnShopSell').addEventListener('click', function() {
    var ids = Object.keys(state.shopSelected);
    if (ids.length === 0) return;
    playSound('click', 0.5);
    var total = 0;
    state.shopCards.forEach(function(c) {
        if (state.shopSelected[c.cardid]) {
            total += c.isDamaged ? 0 : Math.floor((c.value || 0) * state.shopMult);
        }
    });
    showShopConfirm(
        'Sell ' + ids.length + ' card' + (ids.length === 1 ? '' : 's') + ' for $' + total.toLocaleString() + '?',
        function() {
            var cards = ids.map(function(id) { return { cardid: id }; });
            nuiFetch('sellCards', { cards: cards });
            state.shopCards    = state.shopCards.filter(function(c) { return !state.shopSelected[c.cardid]; });
            state.shopSelected = {};
            renderShop();
        }
    );
});

document.getElementById('btnShopSelectAll').addEventListener('click', function() {
    playSound('click', 0.5);
    state.shopCards.forEach(function(c) {
        if (!c.isDamaged) state.shopSelected[c.cardid] = true;
    });
    // Update all rows visually without full re-render
    document.querySelectorAll('.shop-card-row').forEach(function(row) {
        var id = row.dataset.cardid;
        if (state.shopSelected[id]) {
            row.classList.add('selected');
            var sb = row.querySelector('.shop-select-btn');
            if (sb) sb.textContent = '✓';
        }
    });
    updateShopTotal();
});

// ══════════════════════════════════════════════════════
//  CARD CREATOR PANEL  (admin only, /cardcreator)
// ══════════════════════════════════════════════════════
state.cc = { customSetIds: {}, selectedSetId: null, cardMode: 'model', activeTab: 'setup', githubModelCache: {} };

// Curated emoji choices for the icon dropdown. [label, emoji]
var CC_ICON_PRESETS = [
    ['Playing Card',  '🃏'],
    ['Car',           '🚗'],
    ['Racing Car',    '🏎️'],
    ['Police Car',    '🚓'],
    ['Ambulance',     '🚑'],
    ['Fire Truck',    '🚒'],
    ['Delivery Truck','🚚'],
    ['Semi Truck',    '🚛'],
    ['Bus',           '🚌'],
    ['Taxi',          '🚕'],
    ['Motorcycle',    '🏍️'],
    ['Bicycle',       '🚲'],
    ['Speedboat',     '🛥️'],
    ['Airplane',      '✈️'],
    ['Helicopter',    '🚁'],
    ['Military Medal','🎖️'],
    ['Pistol',        '🔫'],
    ['Trophy',        '🏆'],
    ['Gem Stone',     '💎'],
    ['Star',          '⭐'],
    ['Glowing Star',  '🌟'],
    ['Fire',          '🔥'],
    ['Lightning Bolt','⚡'],
    ['Checkered Flag','🏁'],
    ['Target',        '🎯'],
    ['Dice',          '🎲'],
    ['Ice',           '🧊'],
    ['Crown',         '👑'],
];

// Curated FontAwesome (solid) choices -- real selectable entries, not
// just an escape hatch into the Custom field. [label, class string]
var CC_FA_ICON_PRESETS = [
    ['Car',             'fa-solid fa-car'],
    ['Car (side)',       'fa-solid fa-car-side'],
    ['Truck',           'fa-solid fa-truck'],
    ['Truck (monster)', 'fa-solid fa-truck-monster'],
    ['Motorcycle',      'fa-solid fa-motorcycle'],
    ['Bicycle',         'fa-solid fa-bicycle'],
    ['Plane',           'fa-solid fa-plane'],
    ['Helicopter',      'fa-solid fa-helicopter'],
    ['Ship',            'fa-solid fa-ship'],
    ['Anchor',          'fa-solid fa-anchor'],
    ['Rocket',          'fa-solid fa-rocket'],
    ['Gun',             'fa-solid fa-gun'],
    ['Shield',          'fa-solid fa-shield-halved'],
    ['Trophy',          'fa-solid fa-trophy'],
    ['Medal',           'fa-solid fa-medal'],
    ['Crown',           'fa-solid fa-crown'],
    ['Gem',             'fa-solid fa-gem'],
    ['Star',            'fa-solid fa-star'],
    ['Fire',            'fa-solid fa-fire'],
    ['Bolt',            'fa-solid fa-bolt'],
    ['Checkered Flag',  'fa-solid fa-flag-checkered'],
    ['Dice',            'fa-solid fa-dice'],
    ['Wrench',          'fa-solid fa-wrench'],
    ['Gears',           'fa-solid fa-gears'],
    ['Money',           'fa-solid fa-money-bill-wave'],
    ['Skull',           'fa-solid fa-skull'],

    // -- Vehicles & Transport --
    ['Car (rear)',        'fa-solid fa-car-rear'],
    ['Car Crash',         'fa-solid fa-car-burst'],
    ['Taxi',              'fa-solid fa-taxi'],
    ['Truck (fast)',      'fa-solid fa-truck-fast'],
    ['Pickup Truck',      'fa-solid fa-truck-pickup'],
    ['Bus',               'fa-solid fa-bus'],
    ['Shuttle Van',       'fa-solid fa-van-shuttle'],
    ['Tractor',           'fa-solid fa-tractor'],
    ['Plane Departure',   'fa-solid fa-plane-departure'],
    ['Plane Arrival',     'fa-solid fa-plane-arrival'],
    ['Fighter Jet',       'fa-solid fa-fighter-jet'],
    ['Train',             'fa-solid fa-train'],
    ['Subway',            'fa-solid fa-train-subway'],
    ['Satellite',         'fa-solid fa-satellite'],
    ['Satellite Dish',    'fa-solid fa-satellite-dish'],
    ['Gas Pump',          'fa-solid fa-gas-pump'],
    ['Charging Station',  'fa-solid fa-charging-station'],
    ['Road',              'fa-solid fa-road'],
    ['Route',             'fa-solid fa-route'],
    ['Compass',           'fa-solid fa-compass'],
    ['Map',               'fa-solid fa-map'],
    ['Map Pin',           'fa-solid fa-map-location-dot'],
    ['Horse',             'fa-solid fa-horse'],
    ['Horse Head',        'fa-solid fa-horse-head'],
    ['Snowplow',          'fa-solid fa-snowplow'],

    // -- Weapons & Military --
    ['Crosshairs',        'fa-solid fa-crosshairs'],
    ['Shield (plain)',    'fa-solid fa-shield'],
    ['Bomb',              'fa-solid fa-bomb'],
    ['Explosion',         'fa-solid fa-explosion'],
    ['Radiation',         'fa-solid fa-radiation'],
    ['Biohazard',         'fa-solid fa-biohazard'],
    ['Skull & Crossbones','fa-solid fa-skull-crossbones'],
    ['Campground',        'fa-solid fa-campground'],

    // -- Trophies & Achievements --
    ['Star (half)',       'fa-solid fa-star-half-stroke'],
    ['Award',             'fa-solid fa-award'],
    ['Ribbon',            'fa-solid fa-ribbon'],
    ['Certificate',       'fa-solid fa-certificate'],
    ['Stamp',             'fa-solid fa-stamp'],
    ['Coins',             'fa-solid fa-coins'],
    ['Sack of Money',     'fa-solid fa-sack-dollar'],
    ['Cash',              'fa-solid fa-money-bill-1'],
    ['Piggy Bank',        'fa-solid fa-piggy-bank'],
    ['Chess King',        'fa-solid fa-chess-king'],
    ['Chess Queen',       'fa-solid fa-chess-queen'],
    ['Chess Knight',      'fa-solid fa-chess-knight'],
    ['Chess Rook',        'fa-solid fa-chess-rook'],
    ['Chess Bishop',      'fa-solid fa-chess-bishop'],
    ['Die (6-sided)',     'fa-solid fa-dice-d6'],
    ['Die (20-sided)',    'fa-solid fa-dice-d20'],
    ['Cube',              'fa-solid fa-cube'],
    ['Cubes',             'fa-solid fa-cubes'],
    ['Puzzle Piece',      'fa-solid fa-puzzle-piece'],

    // -- Nature & Elements --
    ['Snowflake',         'fa-solid fa-snowflake'],
    ['Sun',               'fa-solid fa-sun'],
    ['Moon',              'fa-solid fa-moon'],
    ['Cloud',             'fa-solid fa-cloud'],
    ['Meteor',            'fa-solid fa-meteor'],
    ['Leaf',              'fa-solid fa-leaf'],
    ['Tree',              'fa-solid fa-tree'],
    ['Mountain',          'fa-solid fa-mountain'],
    ['Water Drop',        'fa-solid fa-droplet'],
    ['Wind',              'fa-solid fa-wind'],
    ['Volcano',           'fa-solid fa-volcano'],

    // -- Animals --
    ['Dog',               'fa-solid fa-dog'],
    ['Cat',               'fa-solid fa-cat'],
    ['Dove',              'fa-solid fa-dove'],
    ['Dragon',            'fa-solid fa-dragon'],
    ['Fish',              'fa-solid fa-fish'],
    ['Spider',            'fa-solid fa-spider'],
    ['Crow',              'fa-solid fa-crow'],
    ['Feather',           'fa-solid fa-feather'],
    ['Paw',               'fa-solid fa-paw'],

    // -- Sports --
    ['Soccer Ball',       'fa-solid fa-futbol'],
    ['Basketball',        'fa-solid fa-basketball'],
    ['Baseball',          'fa-solid fa-baseball'],
    ['Football',          'fa-solid fa-football'],
    ['Volleyball',        'fa-solid fa-volleyball'],
    ['Golf',              'fa-solid fa-golf-ball-tee'],
    ['Bowling',           'fa-solid fa-bowling-ball'],
    ['Stopwatch',         'fa-solid fa-stopwatch'],
    ['Dumbbell',          'fa-solid fa-dumbbell'],

    // -- Buildings & Places --
    ['Building',          'fa-solid fa-building'],
    ['City',              'fa-solid fa-city'],
    ['Landmark',          'fa-solid fa-landmark'],
    ['Warehouse',         'fa-solid fa-warehouse'],
    ['Industry',          'fa-solid fa-industry'],
    ['Store',             'fa-solid fa-store'],
    ['House',             'fa-solid fa-house'],
    ['Archway',           'fa-solid fa-archway'],

    // -- Symbols & Misc --
    ['Heart',                 'fa-solid fa-heart'],
    ['Bell',                  'fa-solid fa-bell'],
    ['Key',                   'fa-solid fa-key'],
    ['Lock',                  'fa-solid fa-lock'],
    ['Unlock',                'fa-solid fa-lock-open'],
    ['Magnifying Glass',      'fa-solid fa-magnifying-glass'],
    ['Bullseye',              'fa-solid fa-bullseye'],
    ['Flag',                  'fa-solid fa-flag'],
    ['Gift',                  'fa-solid fa-gift'],
    ['Box',                   'fa-solid fa-box'],
    ['Box Open',              'fa-solid fa-box-open'],
    ['Boxes',                 'fa-solid fa-boxes-stacked'],
    ['Infinity',              'fa-solid fa-infinity'],
    ['Screwdriver & Wrench',  'fa-solid fa-screwdriver-wrench'],
    ['Toolbox',               'fa-solid fa-toolbox'],
    ['Hammer',                'fa-solid fa-hammer'],
    ['Palette',               'fa-solid fa-palette'],
    ['Paintbrush',            'fa-solid fa-paintbrush'],
    ['Music',                 'fa-solid fa-music'],
    ['Camera',                'fa-solid fa-camera'],
    ['Film',                  'fa-solid fa-film'],
    ['Book',                  'fa-solid fa-book'],
    ['Graduation Cap',        'fa-solid fa-graduation-cap'],
    ['Briefcase',             'fa-solid fa-briefcase'],
];

// ── Generic combo popup plumbing (shared by icon + vehicle pickers) ──
var _ccOpenCombo = null; // currently open popup element, or null

function ccCloseCombo() {
    if (!_ccOpenCombo) return;
    _ccOpenCombo.classList.add('hidden');
    if (_ccOpenCombo._ccTrigger) _ccOpenCombo._ccTrigger.classList.remove('open');
    _ccOpenCombo = null;
}
document.addEventListener('mousedown', function(e) {
    if (!_ccOpenCombo) return;
    var trigger = _ccOpenCombo._ccTrigger;
    if (_ccOpenCombo.contains(e.target) || (trigger && trigger.contains(e.target))) return;
    ccCloseCombo();
});
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') ccCloseCombo();
});

function ccOpenCombo(trigger, popup) {
    if (_ccOpenCombo === popup) { ccCloseCombo(); return; }
    ccCloseCombo();

    var r = trigger.getBoundingClientRect();
    popup.style.left  = Math.round(r.left) + 'px';
    popup.style.top   = Math.round(r.bottom + 6) + 'px';
    popup.style.width = Math.round(Math.max(r.width, 240)) + 'px';
    popup.classList.remove('hidden');

    // Flip above the trigger if it would run off the bottom of the screen
    var pr = popup.getBoundingClientRect();
    if (pr.bottom > window.innerHeight - 10) {
        popup.style.top = Math.round(r.top - pr.height - 6) + 'px';
    }

    trigger.classList.add('open');
    popup._ccTrigger = trigger;
    _ccOpenCombo = popup;

    var filter = popup.querySelector('.cc-combo-filter');
    if (filter) {
        filter.value = '';
        ccFilterComboList(popup.querySelector('.cc-combo-list'), '');
        setTimeout(function() { filter.focus(); }, 0);
    }
}

// Hides rows that don't match the query, then hides any group header
// left with nothing visible underneath it.
function ccFilterComboList(listEl, query) {
    var q = query.trim().toLowerCase();
    var children = Array.prototype.slice.call(listEl.children);
    children.forEach(function(el) {
        if (el.classList.contains('cc-combo-row')) {
            el.classList.toggle('hidden', !!q && el.dataset.search.indexOf(q) === -1);
        }
    });
    children.forEach(function(el, i) {
        if (!el.classList.contains('cc-combo-group')) return;
        var hasVisible = false;
        for (var j = i + 1; j < children.length; j++) {
            var sib = children[j];
            if (sib.classList.contains('cc-combo-group')) break;
            if (sib.classList.contains('cc-combo-row') && !sib.classList.contains('hidden')) { hasVisible = true; break; }
        }
        el.classList.toggle('hidden', !hasVisible);
    });
}

function ccComboRow(value, labelText, searchText) {
    var row = document.createElement('div');
    row.className = 'cc-combo-row';
    row.dataset.value = value;
    row.dataset.search = (searchText || labelText).toLowerCase();
    var label = document.createElement('span');
    label.className = 'cc-combo-row-label';
    label.textContent = labelText;
    row.appendChild(label);
    return row;
}
// ── Icon picker — always-visible searchable grid (not a dropdown) ──
//    Two independent instances share this factory: one for the New Set
//    form (Setup pane), one for the Set Details panel (editing an
//    existing set). Each just needs its own set of DOM ids.
function ccMakeIconPicker(ids, defaultIcon) {
    var picker   = { selected: defaultIcon };
    var gridEl   = document.getElementById(ids.grid);
    var searchEl = document.getElementById(ids.search);
    var customEl = document.getElementById(ids.custom);
    var glyphEl  = document.getElementById(ids.glyph);
    var labelEl  = document.getElementById(ids.label);

    function refreshReadout() {
        var current = picker.selected;
        glyphEl.innerHTML = '';
        if (current) glyphEl.appendChild(makeIconEl(current));
        labelEl.textContent = current || 'Choose an icon below';
    }

    function highlight() {
        var custom = customEl.value.trim();
        var active = custom ? null : picker.selected;
        Array.prototype.forEach.call(gridEl.querySelectorAll('.cc-icon-swatch'), function(sw) {
            sw.classList.toggle('selected', !!active && sw.dataset.icon === active);
        });
    }

    function selectFromGrid(icon) {
        picker.selected = icon;
        customEl.value  = '';
        refreshReadout();
        highlight();
    }

    picker.build = function() {
        if (gridEl.children.length) return; // already built
        CC_ICON_PRESETS.concat(CC_FA_ICON_PRESETS).forEach(function(pair) {
            var sw = document.createElement('button');
            sw.type = 'button';
            sw.className = 'cc-icon-swatch';
            sw.title = pair[0];
            sw.dataset.icon   = pair[1];
            sw.dataset.search = (pair[0] + ' ' + pair[1]).toLowerCase();
            sw.appendChild(makeIconEl(pair[1]));
            sw.addEventListener('click', function() {
                playSound('click', 0.3);
                selectFromGrid(pair[1]);
            });
            gridEl.appendChild(sw);
        });
        highlight();
    };

    picker.reset = function(icon) {
        picker.selected = icon;
        customEl.value  = '';
        searchEl.value  = '';
        Array.prototype.forEach.call(gridEl.querySelectorAll('.cc-icon-swatch'), function(sw) {
            sw.classList.remove('hidden');
        });
        refreshReadout();
        highlight();
    };

    picker.get = function() {
        var custom = customEl.value.trim();
        return custom || picker.selected;
    };

    searchEl.addEventListener('input', function() {
        var q = searchEl.value.trim().toLowerCase();
        Array.prototype.forEach.call(gridEl.querySelectorAll('.cc-icon-swatch'), function(sw) {
            sw.classList.toggle('hidden', !!q && sw.dataset.search.indexOf(q) === -1);
        });
    });

    customEl.addEventListener('input', function() {
        refreshReadout();
        highlight();
    });

    return picker;
}

var ccSetupIconPicker = ccMakeIconPicker({
    grid: 'ccIconGrid', search: 'ccIconSearch', custom: 'ccIconCustom',
    glyph: 'ccIconCurrentGlyph', label: 'ccIconCurrentLabel',
}, CC_ICON_PRESETS[0][1]);

var ccEditIconPicker = ccMakeIconPicker({
    grid: 'ccEditIconGrid', search: 'ccEditIconSearch', custom: 'ccEditIconCustom',
    glyph: 'ccEditIconCurrentGlyph', label: 'ccEditIconCurrentLabel',
}, CC_ICON_PRESETS[0][1]);

function getSelectedIcon()     { return ccSetupIconPicker.get(); }
function getEditSelectedIcon() { return ccEditIconPicker.get(); }

// Every vehicle model already used somewhere in config.lua -- pulled
// straight from the file, so there's zero risk of a made-up spawn name.
// [displayName, model]
var CC_MODEL_PRESETS = [["300R", "r300"], ["Adder", "adder"], ["AirLiner", "jet"], ["Akula", "akula"], ["Akuma", "akuma"], ["Aleutian", "aleutian"], ["Ambulance", "ambulance"], ["Annihilator", "annihilator"], ["Annihilator Stealth", "annihilator2"], ["APC", "apc"], ["Ardent", "ardent"], ["Army Tanker", "armytanker"], ["Army Trailer", "armytrailer"], ["Asea", "asea"], ["Autarch", "autarch"], ["B-11 Strikeforce", "strikeforce"], ["Banshee", "banshee"], ["Banshee 900R", "banshee2"], ["Barracks Semi", "barracks2"], ["Barracks Troop Transport", "barracks"], ["Barrage", "barrage"], ["Bati 801", "bati"], ["Besra", "besra"], ["BF Injection", "bfinjection"], ["Biff", "biff"], ["Bifta", "bifta"], ["Bison", "bison"], ["Bison", "bison2"], ["Blazer Aqua", "blazer5"], ["Blista", "blista"], ["Blista Compact", "blista2"], ["BMX", "bmx"], ["Bobcat XL Open", "bobcatxl"], ["Bodhi", "bodhi2"], ["Boxville", "boxville"], ["BR8", "openwheel1"], ["Brawler", "brawler"], ["Brickade", "brickade"], ["Brioso R/A", "brioso"], ["Brute Riot", "riot"], ["Buffalo", "buffalo"], ["Buffalo S", "buffalo2"], ["Buffalo STX", "buffalo4"], ["Buffalo STX", "buffalo5"], ["Burrito", "burrito3"], ["Burrito", "burrito"], ["Burrito Custom", "gburrito2"], ["Buzzard", "buzzard"], ["Buzzard Attack Chopper", "buzzard2"], ["Caracara 4X4", "caracara2"], ["Carbon RS", "carbonrs"], ["Carbonizzare", "carbonizzare"], ["Cargobob", "cargobob"], ["Cargobob Jetsam", "cargobob3"], ["Casco", "casco"], ["Cerberus", "cerberus3"], ["Cheetah", "cheetah"], ["Cheetah Classic", "cheetah2"], ["Chernobog", "chernobog"], ["Chino Luxe", "chino2"], ["Clique Wagon", "clique2"], ["Cognoscenti 55", "cog55"], ["Coquette Classic", "coquette2"], ["Cruiser", "cruiser"], ["Cuban 800", "cuban800"], ["Cutter", "cutter"], ["Daemon", "daemon"], ["Defiler", "defiler"], ["Deity", "deity"], ["Dilettante", "dilettante"], ["Dinghy", "dinghy2"], ["Dodo", "dodo"], ["Dominator", "dominator"], ["Dominator ASP", "dominator7"], ["Dominator GTT", "dominator8"], ["Dominator Police Package", "poldominator10"], ["Dorado Police Package", "poldorado"], ["Double-T Custom", "double"], ["Draugur", "draugur"], ["Drift Gauntlet", "driftgauntlet4"], ["Dubsta", "dubsta"], ["Dukes", "dukes"], ["Dukes O'Death", "dukes2"], ["Duster", "duster"], ["Dynasty", "dynasty"], ["Elegy Retro Custom", "elegy"], ["Elegy RH8", "elegy2"], ["Emerus", "emerus"], ["Entity MT", "entity3"], ["Entity XF", "entityxf"], ["Entity XXR", "entity2"], ["Euros", "euros"], ["Exemplar", "exemplar"], ["F620", "f620"], ["Faggio", "faggio2"], ["Feltzer", "feltzer2"], ["FIB SUV", "fbi"], ["FIB SUV 2", "fbi2"], ["Fire Truck", "firetruk"], ["Fixter", "fixter"], ["Flash GT", "flashgt"], ["Flatbed", "flatbed"], ["FMJ", "fmj"], ["Frogger", "frogger"], ["Furia", "furia"], ["Gargoyle", "gargoyle"], ["Gauntlet", "gauntlet"], ["Gauntlet Classic", "gauntlet2"], ["Gauntlet Hellfire", "gauntlet3"], ["Gauntlet Police Package", "polgauntlet"], ["Glendale Custom", "glendale2"], ["GP1", "gp1"], ["Granger 3600LX", "granger2"], ["Greenwood Police Package", "polgreenwood"], ["Gresley", "gresley"], ["GT500", "gt500"], ["Hakuchou", "hakuchou"], ["Halftrack", "halftrack"], ["Hauler", "hauler"], ["Havok", "havok"], ["Hellion", "hellion"], ["Hexer", "hexer"], ["Hunter", "hunter"], ["Hydra", "hydra"], ["Imorgon", "imorgon"], ["Impaler LX", "impaler6"], ["Impaler LX Police Package", "polimpaler6"], ["Impaler Police Package", "polimpaler5"], ["Infernus", "infernus"], ["Innovation", "innovation"], ["Insurgent", "insurgent"], ["Insurgent Pick-Up", "insurgent2"], ["Insurgent Pick-Up Custom", "insurgent3"], ["Issi", "issi2"], ["Itali GTB", "italigtb"], ["Itali GTB", "italigtb2"], ["Itali GTO", "italigto"], ["Itali RSX", "italirsx"], ["Jackal", "jackal"], ["JB 700", "jb700"], ["JB 700W", "jb7002"], ["Jester Classic", "jester3"], ["Jester Racecar", "jester2"], ["Jester RR", "jester4"], ["Jet Max", "jetmax"], ["Journey", "journey"], ["Jubilee", "jubilee"], ["Jugular", "jugular"], ["Kalahari", "kalahari"], ["kanjo", "kanjo"], ["Kanjo SJ", "kanjosj"], ["Khanjali", "khanjali"], ["Kosatka Submarine", "kosatka"], ["Krieger", "krieger"], ["KURTZ 31 Patrol Boat", "patrolboat"], ["Lazer", "lazer"], ["Lifeguard", "lguard"], ["Longfin", "longfin"], ["Luxor", "luxor"], ["Luxor Deluxe", "luxor2"], ["Mallard", "stunt"], ["Mammatus", "mammatus"], ["Manana", "manana"], ["Marquis", "marquis"], ["Massacro", "massacro"], ["Massacro Racecar", "massacro2"], ["Maverick", "maverick"], ["Menacer", "menacer"], ["Mesa", "mesa"], ["Mesa Crusader", "crusader"], ["Minivan", "minivan"], ["Mixer", "mixer"], ["Mixer 2", "mixer2"], ["Monroe", "monroe"], ["Mule", "mule"], ["Nagasaki Blazer", "blazer"], ["Nemesis", "nemesis"], ["Nero", "nero"], ["Nero Custom", "nero2"], ["Nightshark", "nightshark"], ["Niobe", "niobe"], ["Oracle", "oracle"], ["Oracle XS", "oracle2"], ["Osiris", "osiris"], ["P-45 Nokota", "nokota"], ["Packer", "packer"], ["Panto", "panto"], ["Paragon", "paragon"], ["Paragon S", "paragon2"], ["Pariah", "pariah"], ["PCJ-600", "pcj"], ["Penetrator", "penetrator"], ["Peyote", "peyote2"], ["Phantom", "phantom"], ["Pipistrello", "pipistrello"], ["Police Bike", "policeb"], ["Police Cruiser", "police"], ["Police Cruiser 2", "police2"], ["Police Cruiser 3", "police3"], ["Police Maverick", "polmav"], ["Police Rancher", "policeold1"], ["Police Roadcruiser", "policeold2"], ["Police Transporter", "policet"], ["Postlude", "postlude"], ["Pounder", "pounder"], ["PR4", "formula"], ["Prairie", "prairie"], ["Predator Police Package", "predator"], ["Prison Bus", "pbus"], ["Prison Bus", "pbus2"], ["Prototipo", "prototipo"], ["R88", "formula2"], ["Rapid GT", "rapidgt"], ["Rapid GT Vert", "rapidgt2"], ["Rat-Loader", "ratloader"], ["Ratel", "ratel"], ["RCV", "riot2"], ["RE-7B", "le7b"], ["Reaper", "reaper"], ["Rebla", "rebla"], ["Remus", "remus"], ["Rhapsody", "rhapsody"], ["Rhinehart", "rhinehart"], ["Rhino Tank", "rhino"], ["RM-10 Bombushka", "bombushka"], ["RO-86 Alkonost", "alkonost"], ["Rogue", "rogue"], ["RT3000", "rt3000"], ["Rubble", "rubble"], ["Ruffian", "ruffian"], ["Rumpo", "rumpo"], ["S80RR", "s80"], ["Sanchez", "sanchez"], ["Sandking XL", "sandking"], ["Savage", "savage"], ["Savestra", "savestra"], ["SC 1", "sc1"], ["Scarab", "scarab"], ["Schlagen", "schlagen"], ["Scorcher", "scorcher"], ["Sea Sparrow", "seasparrow"], ["Sentinel", "sentinel"], ["Sentinel Classic", "sentinel3"], ["Serrano", "serrano"], ["Seven-70", "seven70"], ["Sheriff Cruiser", "sheriff"], ["Sheriff SUV", "sheriff2"], ["Shotaro", "shotaro"], ["Skylift", "skylift"], ["SM722", "sm722"], ["Sovereign", "sovereign"], ["Sparrow", "seasparrow2"], ["Specter", "specter"], ["Specter Custom", "specter2"], ["Speeder", "speeder"], ["Speedo", "speedo"], ["Squalo", "squalo"], ["Stafford", "stafford"], ["Stinger", "stinger"], ["Stinger GT", "stingergt"], ["Stirling GT", "feltzer3"], ["Streamer 216", "streamer216"], ["Stromberg", "stromberg"], ["Sugoi", "sugoi"], ["Suntrap", "suntrap"], ["SuperVolito", "supervolito"], ["Swift", "swift"], ["Swinger", "swinger"], ["T20", "t20"], ["Tahoma Coupe", "tahoma"], ["Tampa", "tampa"], ["Technical", "technical"], ["Technical Aqua", "technical3"], ["Tempesta", "tempesta"], ["Terrorbyte", "terbyte"], ["Tezeract", "tezeract"], ["Thrax", "thrax"], ["Thrust", "thrust"], ["Thruster Jet Pack", "thruster"], ["Tipper", "tiptruck"], ["Tipper 2", "tiptruck2"], ["Titan", "titan"], ["Torero XO", "torero2"], ["Tornado", "tornado"], ["Toro", "toro"], ["Tri-Cycles Race Bike", "tribike"], ["Tri-Cycles Race Bike 2", "tribike2"], ["Tri-Cycles Race Bike 3", "tribike3"], ["Trophy Truck", "trophytruck"], ["Tropic", "tropic2"], ["Turismo R", "turismor"], ["Unmarked Cruiser", "police4"], ["V-65 Molotok", "molotok"], ["Vacca", "vacca"], ["Vader", "vader"], ["Valkyrie", "valkyrie"], ["Velum", "velum"], ["Vetir Troop Transport", "vetir"], ["Vigilante", "vigilante"], ["Virgo", "virgo2"], ["Virtue", "virtue"], ["Volatus", "volatus"], ["Weevil", "weevil"], ["Weevil Custom", "weevil2"], ["Whippet Race Bike", "whippet"], ["XA-21", "xa21"], ["XLS", "xls"], ["Yosemite", "yosemite"], ["Yosemite Drift", "yosemite2"], ["Yosemite Rancher", "yosemite3"], ["Youga", "youga"], ["Youga Classic", "youga2"], ["Youga Classic '69", "youga3"], ["Z-Type", "ztype"], ["Zentorno", "zentorno"], ["Zion", "zion"], ["Zion Classic", "zion3"], ["Zorrusso", "zorrusso"], ["ZR350", "zr350"]];

var _ccSelectedModel = '';

function buildCCModelList() {
    var list = document.getElementById('ccModelList');
    if (list.children.length) return; // already built
    list.innerHTML = '';

    CC_MODEL_PRESETS.forEach(function(pair) {
        var labelText = pair[0] + ' (' + pair[1] + ')';
        var row = ccComboRow(pair[1], labelText, pair[0] + ' ' + pair[1]);
        row.addEventListener('click', function() { ccSelectModel(pair[1], pair[0]); });
        list.appendChild(row);
    });

    var customRow = ccComboRow('__custom__', 'Custom / Type your own…', 'custom type your own spawn model');
    customRow.addEventListener('click', function() { ccSelectModel('__custom__', null); });
    list.appendChild(customRow);
}

function ccSelectModel(value, displayName) {
    _ccSelectedModel = value;
    var customField = document.getElementById('ccCardModel');
    customField.classList.toggle('hidden', value !== '__custom__');
    if (value === '__custom__') {
        customField.value = '';
        setTimeout(function() { customField.focus(); }, 0);
    }
    updateCCModelTrigger(displayName);
    ccCloseCombo();
    renderCCPreview();
}

function getSelectedModel() {
    if (_ccSelectedModel === '__custom__') return document.getElementById('ccCardModel').value.trim();
    return _ccSelectedModel;
}

function updateCCModelTrigger(displayName) {
    var label = document.getElementById('ccCardModelTriggerLabel');
    if (_ccSelectedModel === '__custom__') {
        var current = document.getElementById('ccCardModel').value.trim();
        label.textContent = current || 'Custom / Type your own…';
    } else if (!_ccSelectedModel) {
        label.textContent = '— Select a vehicle —';
    } else {
        label.textContent = displayName || _ccSelectedModel;
    }
}

// ── Vehicle image source toggle + gallery page ─────────────────────
// The "Vehicle" field above normally opens a plain searchable text
// list (ccModelPopup). Switching this pill to a GitHub image source
// instead opens a full gallery page of PNG thumbnails -- one per known
// vehicle model -- pulled straight from that GitHub repo, so whoever's
// building a card set can browse and click the actual picture instead
// of guessing from a spawn name. Picking either way just selects a
// model, same as before; nothing new is sent to the server. The image
// that actually ends up on the finished card is resolved separately at
// render time by cardImg()/imgFallback(), which already tries every
// configured source in order -- this toggle only changes what you're
// previewing while picking.
var _ccImageSourceKey = 'fivem';

var CC_IMAGE_SOURCE_LABELS = {
    fivem:   'FiveM Docs',
    github1: 'GitHub Storage 1',
    github2: 'GitHub Storage 2',
};

function ccSetImageSourceKey(key) {
    _ccImageSourceKey = key;
    var toggle = document.getElementById('ccImageSourceToggle');
    if (toggle) {
        Array.prototype.forEach.call(toggle.querySelectorAll('.cc-source-pill'), function(btn) {
            btn.classList.toggle('active', btn.dataset.source === key);
        });
    }
    var hint = document.getElementById('ccSourceHint');
    if (hint) {
        hint.textContent = (key === 'fivem')
            ? 'Browsing the default FiveM vehicle list. Card images automatically fall back through every configured source (FiveM Docs → GitHub Storage 1 → GitHub Storage 2) wherever this card is shown.'
            : 'Click "Vehicle" below to browse picture thumbnails pulled from ' + (CC_IMAGE_SOURCE_LABELS[key] || key) + '.';
    }
}

function ccImageSourceUrl(key, model) {
    var sources = getImageSources();
    var tpl = sources[key];
    if (!tpl || !model) return '';
    return tpl.split('{model}').join(model);
}

// Turns a bare filename/model like "custom_lambo-2" into "Custom Lambo 2"
// for display. Any folder prefix (shouldn't normally happen, but the repo
// isn't guaranteed to be flat) is dropped for the label -- the full path
// is still what gets used as the actual `model` value.
function ccPrettifyModelName(model) {
    var base = String(model).split('/').pop();
    var words = base.replace(/[_\-]+/g, ' ').trim();
    if (!words) return model;
    return words.replace(/\w\S*/g, function(w) { return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase(); });
}

// Pulls { owner, repo, branch } out of a configured GitHub raw template
// like 'https://github.com/OWNER/REPO/raw/BRANCH/{model}.png' so we can
// hit GitHub's API and list every file actually in that repo.
function ccParseGithubRepo(templateUrl) {
    if (!templateUrl) return null;
    var m = /^https?:\/\/github\.com\/([^\/]+)\/([^\/]+)\/raw\/([^\/]+)\//.exec(templateUrl);
    if (!m) return null;
    return { owner: m[1], repo: m[2], branch: m[3] };
}

// Lists every image file that actually exists in a configured GitHub
// image source -- this is what surfaces addon/custom vehicles that were
// never in CC_MODEL_PRESETS (that list only covers vehicles already used
// somewhere in config.lua). Successful results are cached for the rest
// of this NUI session; failures are NOT cached so re-opening the gallery
// (or hitting Refresh) retries automatically.
function ccFetchGithubModels(sourceKey, cb) {
    var cached = state.cc.githubModelCache[sourceKey];
    if (cached) { cb(cached.models, cached.error); return; }

    var tpl  = getImageSources()[sourceKey];
    var info = ccParseGithubRepo(tpl);
    if (!info) { cb([], 'Could not figure out the GitHub repo from the configured URL.'); return; }

    if (typeof fetch !== 'function') { cb([], 'This browser build has no fetch() available.'); return; }

    var apiUrl = 'https://api.github.com/repos/' + info.owner + '/' + info.repo + '/git/trees/' + encodeURIComponent(info.branch) + '?recursive=1';

    fetch(apiUrl, { headers: { 'Accept': 'application/vnd.github+json' } })
        .then(function(res) {
            if (!res.ok) throw new Error('GitHub API returned ' + res.status);
            return res.json();
        })
        .then(function(data) {
            var models = [];
            (data.tree || []).forEach(function(entry) {
                if (!entry || entry.type !== 'blob' || !entry.path) return;
                if (!/\.(png|jpe?g|webp)$/i.test(entry.path)) return;
                models.push(entry.path.replace(/\.(png|jpe?g|webp)$/i, ''));
            });
            var err = data.truncated ? 'GitHub truncated this listing (repo is very large) -- some images may be missing.' : null;
            state.cc.githubModelCache[sourceKey] = { models: models, error: err };
            cb(models, err);
        })
        .catch(function(fetchErr) {
            cb([], 'Could not reach GitHub to list images (' + ((fetchErr && fetchErr.message) || 'network error') + ').');
        });
}

// Builds the gallery grid from the union of the known vehicle list
// (CC_MODEL_PRESETS -- nice display names) and whatever GitHub actually
// reports having, so addon vehicles that only exist as an uploaded image
// still show up, labelled from their filename.
function buildCCModelGallery(sourceKey, discoveredModels) {
    var grid = document.getElementById('ccModelGalleryGrid');
    if (!grid) return;
    grid.innerHTML = '';

    var seen = {};
    var combined = [];

    CC_MODEL_PRESETS.forEach(function(pair) {
        var key = pair[1].toLowerCase();
        if (seen[key]) return;
        seen[key] = true;
        combined.push({ model: pair[1], label: pair[0], known: true });
    });

    (discoveredModels || []).forEach(function(model) {
        if (!model) return;
        var key = model.toLowerCase();
        if (seen[key]) return;
        seen[key] = true;
        combined.push({ model: model, label: ccPrettifyModelName(model), known: false });
    });

    combined.sort(function(a, b) {
        if (a.known !== b.known) return a.known ? -1 : 1;
        var la = a.label.toLowerCase(), lb = b.label.toLowerCase();
        return la < lb ? -1 : la > lb ? 1 : 0;
    });

    if (!combined.length) {
        var empty = document.createElement('div');
        empty.className = 'cc-gallery-empty';
        empty.textContent = 'No vehicle images found.';
        grid.appendChild(empty);
        return;
    }

    combined.forEach(function(entry) {
        var url = ccImageSourceUrl(sourceKey, entry.model);

        var item = document.createElement('div');
        item.className = 'cc-gallery-item' + (entry.known ? '' : ' cc-gallery-item-addon');
        item.dataset.search = (entry.label + ' ' + entry.model).toLowerCase();

        var thumb = document.createElement('div');
        thumb.className = 'cc-gallery-thumb';

        if (!entry.known) {
            var tag = document.createElement('span');
            tag.className = 'cc-gallery-item-tag';
            tag.textContent = 'ADDON';
            thumb.appendChild(tag);
        }

        var img = document.createElement('img');
        img.loading = 'lazy';
        img.alt = entry.label;
        img.src = url;
        img.addEventListener('error', function() {
            img.onerror = null;
            thumb.classList.add('broken');
            var ph = document.createElement('span');
            ph.className = 'cc-gallery-thumb-placeholder';
            ph.textContent = 'No image';
            thumb.replaceChild(ph, img);
        });
        thumb.appendChild(img);

        var label = document.createElement('div');
        label.className = 'cc-gallery-item-label';
        label.textContent = entry.label;
        label.title = entry.model;

        item.appendChild(thumb);
        item.appendChild(label);

        item.addEventListener('click', function() {
            playSound('click', 0.4);
            ccSelectModel(entry.model, entry.label);
            ccCloseModelGallery();
        });

        grid.appendChild(item);
    });
}

function ccFilterGallery(query) {
    var q = query.trim().toLowerCase();
    var grid = document.getElementById('ccModelGalleryGrid');
    if (!grid) return;
    Array.prototype.forEach.call(grid.querySelectorAll('.cc-gallery-item'), function(el) {
        el.classList.toggle('hidden', !!q && el.dataset.search.indexOf(q) === -1);
    });
}

function ccOpenModelGallery(sourceKey, forceRefresh) {
    var overlay = document.getElementById('ccModelGallery');
    if (!overlay) return;
    var titleEl = document.getElementById('ccGalleryTitle');
    var subEl   = document.getElementById('ccGallerySubtitle');
    var grid    = document.getElementById('ccModelGalleryGrid');
    var label   = CC_IMAGE_SOURCE_LABELS[sourceKey] || sourceKey;

    if (forceRefresh) delete state.cc.githubModelCache[sourceKey];

    if (titleEl) titleEl.textContent = 'Browse Vehicle Images — ' + label;
    if (subEl)   subEl.textContent   = 'Loading the full image list from GitHub (this includes addon vehicles, not just known ones)…';
    if (grid) {
        grid.innerHTML = '';
        var loading = document.createElement('div');
        loading.className = 'cc-gallery-empty';
        loading.textContent = 'Loading…';
        grid.appendChild(loading);
    }

    var filter = document.getElementById('ccGalleryFilter');
    if (filter) filter.value = '';

    overlay.classList.remove('hidden');

    ccFetchGithubModels(sourceKey, function(discoveredModels, err) {
        // The admin may have switched sources or closed the gallery again
        // before this async call came back -- don't stomp on whatever
        // they're looking at now.
        if (_ccImageSourceKey !== sourceKey || overlay.classList.contains('hidden')) return;

        buildCCModelGallery(sourceKey, discoveredModels);

        if (subEl) {
            if (err) {
                subEl.textContent = err + ' Showing the known vehicle list only -- click Refresh to try again.';
            } else {
                var extra = (discoveredModels || []).length;
                subEl.textContent = 'Click a thumbnail to use that vehicle. Found ' + extra + ' image' + (extra === 1 ? '' : 's') + ' in this repo (addon vehicles included). A "No image" tile just means nothing matched that entry.';
            }
        }
        if (filter) setTimeout(function() { filter.focus(); }, 0);
    });
}

function ccCloseModelGallery() {
    var overlay = document.getElementById('ccModelGallery');
    if (overlay) overlay.classList.add('hidden');
}

(function() {
    var toggle = document.getElementById('ccImageSourceToggle');
    if (toggle) {
        Array.prototype.forEach.call(toggle.querySelectorAll('.cc-source-pill'), function(btn) {
            btn.addEventListener('click', function() {
                playSound('click', 0.3);
                ccSetImageSourceKey(btn.dataset.source);
            });
        });
    }
    var closeBtn = document.getElementById('btnCCGalleryClose');
    if (closeBtn) closeBtn.addEventListener('click', function() { playSound('click', 0.4); ccCloseModelGallery(); });

    var refreshBtn = document.getElementById('btnCCGalleryRefresh');
    if (refreshBtn) refreshBtn.addEventListener('click', function() {
        playSound('click', 0.4);
        ccOpenModelGallery(_ccImageSourceKey, true);
    });

    var overlay = document.getElementById('ccModelGallery');
    if (overlay) overlay.addEventListener('click', function(e) { if (e.target === overlay) ccCloseModelGallery(); });

    var galleryFilter = document.getElementById('ccGalleryFilter');
    if (galleryFilter) galleryFilter.addEventListener('input', function() { ccFilterGallery(this.value); });

    document.addEventListener('keydown', function(e) { if (e.key === 'Escape') ccCloseModelGallery(); });
})();

// The next free card number for a set -- so admins don't have to track
// it by hand while adding a run of cards.
function ccNextCardNumber(setId) {
    var set = state.sets[setId];
    if (!set || !set.cards || !set.cards.length) return 1;
    var max = 0;
    set.cards.forEach(function(c) { if (c.number > max) max = c.number; });
    return max + 1;
}

function openCardCreator(data) {
    ccSetupIconPicker.build();
    ccEditIconPicker.build();
    buildCCModelList();

    // state.sets doubles as the client's copy of Config.Sets everywhere
    // else in the UI (binder/shop/reveal), so the live preview's calls
    // into buildCard() see accurate set labels / card counts too.
    state.sets             = data.sets         || {};
    state.cc.customSetIds  = data.customSetIds || {};
    state.cc.selectedSetId = null;
    if (data.rarities) state.rarities = data.rarities;

    document.getElementById('ccNewSetId').value = '';
    document.getElementById('ccNewSetLabel').value = '';
    ccSetupIconPicker.reset(CC_ICON_PRESETS[0][1]);
    ccSetCardMode('model');
    ccSetImageSourceKey('fivem');
    ccEndEditCard();

    ccSwitchTab('setup');
    renderCCSetList();
    renderCCEditor();
    showCCStatus('', null);
    showScreen('screen-cardcreator');
}

function ccSwitchTab(tab) {
    state.cc.activeTab = tab;
    document.getElementById('ccMainTabSetup').classList.toggle('active', tab === 'setup');
    document.getElementById('ccMainTabEdit').classList.toggle('active', tab === 'edit');
    document.getElementById('ccPaneSetup').classList.toggle('hidden', tab !== 'setup');
    document.getElementById('ccPaneEdit').classList.toggle('hidden', tab !== 'edit');
    if (tab === 'edit') renderCCSetList();
}

document.getElementById('ccMainTabSetup').addEventListener('click', function() {
    playSound('click', 0.4);
    ccSwitchTab('setup');
});
document.getElementById('ccMainTabEdit').addEventListener('click', function() {
    playSound('click', 0.4);
    ccSwitchTab('edit');
});

// ── Edit Sets tab: custom (SQL) sets only -- built-in/config.lua sets
//    are intentionally never listed here, so a chat typo or misclick
//    can never touch them. ──────────────────────────────────────────
function ccCustomSetIdsSorted() {
    return Object.keys(state.cc.customSetIds).filter(function(id) { return state.sets[id]; }).sort(function(a, b) {
        var la = (state.sets[a].label || a).toLowerCase();
        var lb = (state.sets[b].label || b).toLowerCase();
        return la < lb ? -1 : la > lb ? 1 : 0;
    });
}

function renderCCSetList() {
    var list = document.getElementById('ccSetList');
    list.innerHTML = '';
    var ids = ccCustomSetIdsSorted();

    if (ids.length === 0) {
        var empty = document.createElement('div');
        empty.className = 'cc-card-list-empty';
        empty.textContent = 'No custom sets yet -- create one under Setup.';
        list.appendChild(empty);
        return;
    }

    ids.forEach(function(setId) {
        var set = state.sets[setId];

        var row = document.createElement('div');
        row.className = 'cc-set-item' + (state.cc.selectedSetId === setId ? ' active' : '');
        row.dataset.setId = setId;

        var icon = makeIconEl(set.icon || '🃏');
        icon.classList.add('cc-set-icon');

        var name = document.createElement('span');
        name.className = 'cc-set-name';
        name.textContent = set.label || setId;

        var count = document.createElement('span');
        count.className = 'cc-set-count';
        count.textContent = (set.cards || []).length;

        row.appendChild(icon);
        row.appendChild(name);
        row.appendChild(count);

        row.addEventListener('click', function() {
            playSound('click', 0.4);
            state.cc.selectedSetId = setId;
            renderCCSetList();
            renderCCEditor();
        });

        list.appendChild(row);
    });
}

// ── Shared editor panel: card list + add-card form + live preview,
//    used by both tabs (whatever state.cc.selectedSetId currently is) ──
function renderCCEditor() {
    var emptyEl   = document.getElementById('ccPanelEmpty');
    var contentEl = document.getElementById('ccPanelContent');
    var setId     = state.cc.selectedSetId;
    var set       = setId && state.sets[setId];

    if (!set) {
        emptyEl.classList.remove('hidden');
        contentEl.classList.add('hidden');
        return;
    }
    emptyEl.classList.add('hidden');
    contentEl.classList.remove('hidden');

    var titleEl = document.getElementById('ccPanelTitle');
    titleEl.innerHTML = '';
    titleEl.appendChild(makeIconEl(set.icon || '🃏'));
    titleEl.appendChild(document.createTextNode(' ' + (set.label || setId)));
    document.getElementById('ccPanelSub').textContent = setId + ' — ' + (set.cards || []).length + ' card(s)';

    // Set Details — lets an admin change this set's label/icon any time,
    // not just at creation. Always reflects whichever set is selected.
    document.getElementById('ccEditSetLabel').value = set.label || '';
    ccEditIconPicker.reset(set.icon || CC_ICON_PRESETS[0][1]);

    var cardList = document.getElementById('ccCardList');
    cardList.innerHTML = '';
    var cards = (set.cards || []).slice().sort(function(a, b) { return (a.number || 0) - (b.number || 0); });

    if (cards.length === 0) {
        var e = document.createElement('div');
        e.className = 'cc-card-list-empty';
        e.textContent = 'No cards in this set yet -- add the first one below.';
        cardList.appendChild(e);
    }

    cards.forEach(function(c) {
        var row = document.createElement('div');
        row.className = 'cc-card-row';

        var num = document.createElement('span');
        num.className = 'cc-card-num';
        num.textContent = '#' + c.number;

        var dot = document.createElement('span');
        dot.className = 'cc-card-rarity-dot';
        dot.setAttribute('data-rarity', c.rarity);

        var name = document.createElement('span');
        name.className = 'cc-card-name';
        name.textContent = c.name;

        var meta = document.createElement('span');
        meta.className = 'cc-card-meta';
        meta.textContent = getRarity(c.rarity).label +
            (c.value ? (' • $' + c.value) : '') +
            (c.model ? (' • ' + c.model) : '');

        var edit = document.createElement('button');
        edit.className = 'cc-card-edit';
        edit.textContent = '✎';
        edit.title = 'Edit card';
        edit.addEventListener('click', function() {
            playSound('click', 0.4);
            ccBeginEditCard(setId, c);
        });

        var rm = document.createElement('button');
        rm.className = 'cc-card-remove';
        rm.textContent = '✕';
        rm.title = 'Remove card';
        rm.addEventListener('click', function() {
            showDiscardConfirm('Remove card #' + c.number + ' "' + c.name + '" from this set?', function() {
                nuiFetch('ccRemoveCard', { setId: setId, number: c.number });
            });
        });

        row.appendChild(num);
        row.appendChild(dot);
        row.appendChild(name);
        row.appendChild(meta);
        row.appendChild(edit);
        row.appendChild(rm);
        cardList.appendChild(row);
    });

    // Leaving edit-card mode (if any) whenever the editor re-renders --
    // e.g. after switching sets or after a ccResult round-trip -- avoids
    // the form getting stuck pointed at a card number that may no
    // longer exist.
    ccEndEditCard();

    // Reset the add-card form for the next card, keep the mode tab as-is.
    // The number field is pre-filled with the next free number in this
    // set so admins don't have to track it manually.
    document.getElementById('ccCardNumber').value = ccNextCardNumber(setId);
    document.getElementById('ccCardName').value = '';
    document.getElementById('ccCardValue').value = '';
    _ccSelectedModel = '';
    document.getElementById('ccCardModel').value = '';
    document.getElementById('ccCardModel').classList.add('hidden');
    updateCCModelTrigger();
    document.getElementById('ccCardImage').value = '';
    document.getElementById('ccCardBackground').value = '';
    renderCCPreview();
}

function showCCStatus(msg, ok) {
    var el = document.getElementById('ccStatus');
    el.textContent = msg || '';
    el.className = 'cc-status' + (ok === true ? ' ok' : ok === false ? ' error' : '');
}

function applyCCResult(data) {
    if (data.removedSetId) {
        delete state.sets[data.removedSetId];
        delete state.cc.customSetIds[data.removedSetId];
        if (state.cc.selectedSetId === data.removedSetId) state.cc.selectedSetId = null;
    }
    if (data.sets) {
        for (var id in data.sets) { state.sets[id] = data.sets[id]; }
    }
    if (data.customSetIds) state.cc.customSetIds = data.customSetIds;
    if (data.selectedSetId !== undefined && data.selectedSetId !== null) state.cc.selectedSetId = data.selectedSetId;

    showCCStatus(data.message || '', !!data.ok);
    renderCCSetList();
    renderCCEditor();
}

// ── Live card preview ────────────────────────────────────────────
function renderCCPreview() {
    var container = document.getElementById('ccCardPreview');
    if (!container) return;
    container.innerHTML = '';

    var setId = state.cc.selectedSetId;
    if (!setId) return;

    var number = parseInt(document.getElementById('ccCardNumber').value, 10);
    var name   = document.getElementById('ccCardName').value.trim();
    var rarity = document.getElementById('ccCardRarity').value;
    var valRaw = document.getElementById('ccCardValue').value.trim();
    var value  = valRaw ? parseInt(valRaw, 10) : undefined;

    var previewData = {
        setId:      setId,
        number:     number || 0,
        name:       name || 'New Card',
        rarity:     rarity,
        value:      value,
        background: document.getElementById('ccCardBackground').value, // independent of model/image mode
    };

    if (state.cc.cardMode === 'model') {
        previewData.model = getSelectedModel();
    } else {
        previewData.image = document.getElementById('ccCardImage').value.trim();
    }

    container.appendChild(buildCard(previewData, { small: true }));
}

['ccCardNumber', 'ccCardName', 'ccCardValue', 'ccCardImage'].forEach(function(id) {
    document.getElementById(id).addEventListener('input', renderCCPreview);
});
document.getElementById('ccCardModel').addEventListener('input', function() {
    updateCCModelTrigger();
    renderCCPreview();
});
document.getElementById('ccCardRarity').addEventListener('change', renderCCPreview);
document.getElementById('ccCardBackground').addEventListener('change', renderCCPreview);
document.getElementById('ccCardModelTrigger').addEventListener('click', function() {
    playSound('click', 0.3);
    if (_ccImageSourceKey === 'fivem') {
        ccOpenCombo(this, document.getElementById('ccModelPopup'));
    } else {
        ccOpenModelGallery(_ccImageSourceKey);
    }
});
document.getElementById('ccModelFilter').addEventListener('input', function() {
    ccFilterComboList(document.getElementById('ccModelList'), this.value);
});

document.getElementById('btnCCCreateSet').addEventListener('click', function() {
    playSound('click', 0.5);
    var setId = document.getElementById('ccNewSetId').value.trim();
    var icon  = getSelectedIcon();
    var label = document.getElementById('ccNewSetLabel').value.trim();
    if (!setId || !icon || !label) { showCCStatus('Fill in set ID, icon and label.', false); return; }
    nuiFetch('ccNewSet', { setId: setId, icon: icon, label: label });
    document.getElementById('ccNewSetId').value = '';
    document.getElementById('ccNewSetLabel').value = '';
});

document.getElementById('btnCCSaveSet').addEventListener('click', function() {
    playSound('click', 0.5);
    var setId = state.cc.selectedSetId;
    if (!setId) return;
    var icon  = getEditSelectedIcon();
    var label = document.getElementById('ccEditSetLabel').value.trim();
    if (!icon || !label) { showCCStatus('Icon and label are required.', false); return; }
    nuiFetch('ccEditSet', { setId: setId, icon: icon, label: label });
});

// Single source of truth for which "Card Image" tab is active -- keeps
// state.cc.cardMode and the visible fields from ever drifting apart
// (previously openCardCreator() reset the mode variable but not the
// DOM, so re-opening the panel after using Custom Image would still
// *show* the image field while silently submitting as Vehicle Model,
// wiping out whatever image URL had been typed).
function ccSetCardMode(mode) {
    state.cc.cardMode = mode;
    document.getElementById('ccTabModel').classList.toggle('active', mode === 'model');
    document.getElementById('ccTabImage').classList.toggle('active', mode === 'image');
    document.getElementById('ccModelFields').classList.toggle('hidden', mode !== 'model');
    document.getElementById('ccImageFields').classList.toggle('hidden', mode !== 'image');
}

document.getElementById('ccTabModel').addEventListener('click', function() {
    ccSetCardMode('model');
    renderCCPreview();
});
document.getElementById('ccTabImage').addEventListener('click', function() {
    ccSetCardMode('image');
    renderCCPreview();
});

// ── Edit an existing card: reuses the same Add-Card form, just in a
//    different mode. The card number is fixed (it's part of the primary
//    key alongside setId server-side) so it's locked while editing.
var _ccEditingCardNumber = null; // null = "add" mode, otherwise the card number being edited

function ccBeginEditCard(setId, cardDef) {
    _ccEditingCardNumber = cardDef.number;
    document.getElementById('ccAddCardFormTitle').textContent = 'Edit Card #' + cardDef.number;
    document.getElementById('btnCCAddCard').textContent = 'Save Changes';
    document.getElementById('btnCCCancelEdit').classList.remove('hidden');

    var numberField = document.getElementById('ccCardNumber');
    numberField.value    = cardDef.number;
    numberField.disabled = true;

    document.getElementById('ccCardName').value       = cardDef.name || '';
    document.getElementById('ccCardRarity').value      = cardDef.rarity || 'common';
    document.getElementById('ccCardValue').value       = cardDef.value || '';
    document.getElementById('ccCardBackground').value  = cardDef.background || '';

    if (cardDef.model) {
        ccSetCardMode('model');
        ccSelectModel(cardDef.model, cardDef.model);
    } else {
        ccSetCardMode('image');
        document.getElementById('ccCardImage').value = cardDef.image || '';
    }

    renderCCPreview();
    var form = document.getElementById('ccAddCardForm');
    if (form && form.scrollIntoView) form.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

function ccEndEditCard() {
    _ccEditingCardNumber = null;
    document.getElementById('ccAddCardFormTitle').textContent = '+ Add Card';
    document.getElementById('btnCCAddCard').textContent = 'Add Card';
    document.getElementById('btnCCCancelEdit').classList.add('hidden');
    document.getElementById('ccCardNumber').disabled = false;
}

document.getElementById('btnCCCancelEdit').addEventListener('click', function() {
    playSound('click', 0.4);
    ccEndEditCard();
    renderCCEditor();
});

document.getElementById('btnCCAddCard').addEventListener('click', function() {
    playSound('click', 0.5);
    var setId = state.cc.selectedSetId;
    if (!setId) return;

    var editing = _ccEditingCardNumber !== null;
    var number  = editing ? _ccEditingCardNumber : parseInt(document.getElementById('ccCardNumber').value, 10);
    var name    = document.getElementById('ccCardName').value.trim();
    var rarity  = document.getElementById('ccCardRarity').value;
    var valRaw  = document.getElementById('ccCardValue').value.trim();
    var value   = valRaw ? parseInt(valRaw, 10) : undefined;

    if (!number || number <= 0) { showCCStatus('Card number must be a positive number.', false); return; }
    if (!name) { showCCStatus('Card needs a name.', false); return; }

    var background = document.getElementById('ccCardBackground').value;
    var payload = { setId: setId, number: number, name: name, rarity: rarity, value: value, background: background };

    if (state.cc.cardMode === 'model') {
        var model = getSelectedModel();
        if (!model) { showCCStatus('Pick a vehicle, or choose Custom and type a spawn model.', false); return; }
        payload.model = model;
    } else {
        var image = document.getElementById('ccCardImage').value.trim();
        if (!image) { showCCStatus('Enter an image URL or path.', false); return; }
        payload.image = image;
    }

    if (editing) {
        nuiFetch('ccEditCard', payload);
        ccEndEditCard();
    } else {
        nuiFetch('ccAddCard', payload);
    }
});

document.getElementById('btnCCRemoveSet').addEventListener('click', function() {
    var setId = state.cc.selectedSetId;
    if (!setId) return;
    var set = state.sets[setId];
    showDiscardConfirm('Delete the entire set "' + (set ? set.label : setId) + '" and all its cards? This cannot be undone.', function() {
        nuiFetch('ccRemoveSet', { setId: setId });
    });
});

document.getElementById('btnCCClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

// ══════════════════════════════════════════════════════
//  NUI MESSAGE HANDLER
// ══════════════════════════════════════════════════════
window.addEventListener('message', function(event) {
    var data = event.data;
    if (!data || !data.type) return;
    if (data.rarities) state.rarities = data.rarities;
    if (data.imageSources) state.imageSources = data.imageSources;
    if (data.imageSourceOrder) state.imageSourceOrder = data.imageSourceOrder;

    switch (data.type) {

        case 'showPackReveal':
            if (data.sets) state.sets = data.sets;
            if (data.packLabel) {
                showPackOpen(data.packLabel, data.cards || []);
            } else {
                showPackReveal(data.cards || []);
            }
            break;

        case 'viewCard':
            viewCard(data.card || {});
            break;

        case 'openBinder':
            openBinder({
                binderId:       data.binderId       || null,
                sets:           data.sets           || {},
                rarities:       data.rarities       || {},
                storedCards:    data.storedCards     || [],
                inventoryCards: data.inventoryCards  || [],
                previewMode:    data.previewMode     || false,
                grantMode:      data.grantMode       || false,
            });
            break;

        case 'openShop':
            openShop({
                inventoryCards: data.inventoryCards || [],
                sets:           data.sets           || {},
                rarities:       data.rarities       || {},
                sellMultiplier: data.sellMultiplier  || 0.8,
            });
            break;

        case 'cardStoredInBinder':
            if (data.cardInfo) {
                var ci = data.cardInfo;
                state.inventoryCards = state.inventoryCards.filter(function(c) { return c.cardid !== ci.cardid; });
                if (!state.storedCards.some(function(c) { return c.cardid === ci.cardid; })) state.storedCards.push(ci);
                buildBinderSidebar();
                var ciIsMp = !!(ci.isMisprint || ci.rarity === 'misprint');
                if (state.currentSetId === '__misprints__') renderMisprints();
                else if (ciIsMp) { /* stored a misprint while viewing a set — stay on set, sidebar count updated */ renderMisprints(); /* switch view */ state.currentSetId = '__misprints__'; document.querySelectorAll('.binder-set-item').forEach(function(i){ i.classList.toggle('active', i.dataset.setId === '__misprints__'); }); }
                else if (state.currentSetId) renderBinderSet(state.currentSetId);
            }
            break;

        case 'cardRemovedFromBinder':
            if (data.cardInfo) {
                var ri = data.cardInfo;
                state.storedCards    = state.storedCards.filter(function(c) { return c.cardid !== ri.cardid; });
                if (!state.inventoryCards.some(function(c) { return c.cardid === ri.cardid; })) state.inventoryCards.push(ri);
                buildBinderSidebar();
                if (state.currentSetId === '__misprints__') renderMisprints();
                else if (state.currentSetId) renderBinderSet(state.currentSetId);
            }
            break;

        case 'cardDiscarded':
            if (data.cardId) {
                state.inventoryCards = state.inventoryCards.filter(function(c) { return c.cardid !== data.cardId; });
            }
            break;

        case 'sellComplete':
            // Cards already removed optimistically; sidebar refresh if binder was open
            if (state.currentSetId) buildBinderSidebar();
            break;

        // An admin deleted a custom set (see ccRemoveSet on the server).
        // Covers three UIs at once since they all reuse screen-binder:
        // a player's real binder (their cards from that set are already
        // gone server-side), and the admin /cardpreview or /cardgive
        // catalog browsers (which need to drop the set immediately
        // rather than keep showing cards that no longer exist).
        case 'setRemoved':
            if (data.setId) {
                var removedSetId = data.setId;
                delete state.sets[removedSetId];
                state.storedCards    = state.storedCards.filter(function(c)    { return c.setId !== removedSetId; });
                state.inventoryCards = state.inventoryCards.filter(function(c) { return c.setId !== removedSetId; });

                var binderScreen = document.getElementById('screen-binder');
                if (binderScreen && !binderScreen.classList.contains('hidden')) {
                    buildBinderSidebar();
                    if (state.currentSetId === removedSetId) {
                        state.currentSetId = null;
                        var grid = document.getElementById('binderGrid');
                        if (grid) grid.innerHTML = '';
                        var t = document.getElementById('binderSetTitle');
                        var p = document.getElementById('binderProgress');
                        if (t) t.textContent = 'Select a Set';
                        if (p) p.textContent = '';
                    } else if (state.currentSetId === '__misprints__') {
                        renderMisprints();
                    } else if (state.currentSetId) {
                        renderBinderSet(state.currentSetId);
                    }
                }
            }
            break;

        case 'openCardCreator':
            openCardCreator({
                sets:         data.sets         || {},
                customSetIds: data.customSetIds || {},
                rarities:     data.rarities      || {},
            });
            break;

        case 'ccResult':
            applyCCResult(data);
            break;

        case 'closeUI':
            hideAll();
            break;
    }
});