// ── State ─────────────────────────────────────────────
let scratchData  = null;
let currentItem  = null;
let isScratching = false;
let revealDone   = false;
let canvas, ctx;
let tileRects  = [];
let tilesDone  = 0;
let tilesTotal = 0;

const TILE_THRESHOLD = 0.60;
const RESOURCE_NAME  = GetParentResourceName ? GetParentResourceName() : 'mnc-scratchcards';

// ── Icon pools per theme ──────────────────────────────
const ICON_POOLS = {
    basic:    ['🍀','⭐','🎯','🍋','🔔','🍒','🎲','🌈'],
    silver:   ['🥈','🌙','⚡','🎰','🎸','🧲','🦊','🎭'],
    gold:     ['🥇','🔥','💫','🎪','🏆','🦁','🌻','🎠'],
    platinum: ['💠','🌟','🎆','🦋','🔮','🛸','🌊','🎑'],
    diamond:  ['💎','🌠','✨','🚀','⚜️','🏅','🌌','🔷'],
};

// ── NUI ───────────────────────────────────────────────
function nuiFetch(endpoint, body) {
    fetch('https://' + RESOURCE_NAME + '/' + endpoint, {
        method: 'POST',
        body: JSON.stringify(body || {})
    }).catch(function() {});
}

// ── Audio ─────────────────────────────────────────────
var _soundCache = {};

// Pre-load all sounds so they're ready instantly on first use.
// Also satisfies the window.onload call in index.html.
function initSounds() {
    ['scratch', 'small', 'big'].forEach(function(name) {
        if (_soundCache[name]) return;
        var src = 'sounds/' + name;
        var audio = new Audio(src + '.ogg');
        audio.addEventListener('canplaythrough', function() {
            _soundCache[name] = audio;
        });
        audio.addEventListener('error', function() {
            var mp3 = new Audio(src + '.mp3');
            _soundCache[name] = mp3;
        });
        // Kick off the load
        audio.load();
    });
}

function playSound(name, vol) {
    var src = 'sounds/' + name;
    var cached = _soundCache[name];
    if (cached) {
        // Reuse cached element: rewind and play
        cached.volume = (vol !== undefined) ? vol : 1.0;
        cached.currentTime = 0;
        cached.play().catch(function() {});
        return;
    }
    // Not cached yet — load on demand, ogg → mp3 fallback
    var audio = new Audio(src + '.ogg');
    audio.volume = (vol !== undefined) ? vol : 1.0;
    audio.addEventListener('canplaythrough', function() {
        _soundCache[name] = audio;
        audio.play().catch(function() {});
    });
    audio.addEventListener('error', function() {
        var mp3 = new Audio(src + '.mp3');
        mp3.volume = (vol !== undefined) ? vol : 1.0;
        _soundCache[name] = mp3;
        mp3.play().catch(function() {});
    });
    audio.load();
}

// Scratch sound: plays once end-to-end.
// If the user is still scratching when it ends, it restarts automatically.
// Never fires more than once at a time.
var _scratchAudioPlaying = false;

function playScratchSound() {
    if (_scratchAudioPlaying) return;   // already playing — let it finish

    var name   = 'scratch';
    var src    = 'sounds/' + name;
    var cached = _soundCache[name];

    function startPlay(audio) {
        _scratchAudioPlaying = true;
        audio.volume = 0.4;
        audio.currentTime = 0;
        audio.play().catch(function() { _scratchAudioPlaying = false; });
        // When the clip ends, restart only if the user is still scratching
        audio.onended = function() {
            _scratchAudioPlaying = false;
            if (isScratching) playScratchSound();
        };
    }

    if (cached) {
        startPlay(cached);
        return;
    }

    // Load on demand the first time
    var audio = new Audio(src + '.ogg');
    audio.addEventListener('canplaythrough', function() {
        _soundCache[name] = audio;
        startPlay(audio);
    });
    audio.addEventListener('error', function() {
        var mp3 = new Audio(src + '.mp3');
        _soundCache[name] = mp3;
        mp3.addEventListener('canplaythrough', function() {
            startPlay(mp3);
        });
        mp3.load();
    });
    audio.load();
}

// ── Build tiles ───────────────────────────────────────
function buildTiles(gridSize, won, theme) {
    var grid  = document.getElementById('scratch-grid');
    var pool  = ICON_POOLS[theme] ? ICON_POOLS[theme].slice() : ICON_POOLS.basic.slice();
    var total = gridSize * gridSize;

    grid.innerHTML = '';
    grid.style.gridTemplateColumns = 'repeat(' + gridSize + ', 1fr)';

    // Shuffle pool
    for (var s = pool.length - 1; s > 0; s--) {
        var j = Math.floor(Math.random() * (s + 1));
        var tmp = pool[s]; pool[s] = pool[j]; pool[j] = tmp;
    }

    var winEmoji     = null;
    var winPositions = new Set();
    var slicePerTile = 0;

    if (won > 0) {
        winEmoji     = pool[0];
        slicePerTile = Math.floor(won / 3);
        while (winPositions.size < 3) {
            winPositions.add(Math.floor(Math.random() * total));
        }
    }

    var decoys = pool.filter(function(e) { return e !== winEmoji; });
    while (decoys.length < total) { decoys = decoys.concat(decoys); }

    var decoyIdx = 0;

    for (var i = 0; i < total; i++) {
        var isWin = winPositions.has(i);
        var emoji, valueText;

        if (isWin) {
            emoji     = winEmoji;
            valueText = '$' + slicePerTile.toLocaleString();
        } else {
            emoji     = decoys[decoyIdx % decoys.length];
            decoyIdx++;
            valueText = '';
        }

        var tile = document.createElement('div');
        tile.className = 'scratch-tile' + (isWin ? ' winner' : '');
        tile.innerHTML = '<span class="tile-icon">' + emoji + '</span>' +
                         (valueText ? '<span class="tile-value">' + valueText + '</span>' : '');
        grid.appendChild(tile);
    }
}

// ── Canvas foil ───────────────────────────────────────
function initCanvas() {
    var area  = document.getElementById('scratch-area');
    var old   = document.getElementById('scratch-canvas');
    var fresh = old.cloneNode(false);
    old.parentNode.replaceChild(fresh, old);
    canvas = fresh;
    ctx    = canvas.getContext('2d');

    canvas.width  = area.offsetWidth;
    canvas.height = area.offsetHeight;

    drawFoil();

    canvas.addEventListener('mousedown',  onDown);
    canvas.addEventListener('mousemove',  onMove);
    canvas.addEventListener('mouseup',    onUp);
    canvas.addEventListener('mouseleave', onUp);
    canvas.addEventListener('touchstart', onTouchDown, { passive: false });
    canvas.addEventListener('touchmove',  onTouchMove,  { passive: false });
    canvas.addEventListener('touchend',   onUp);

    buildTileRects();
}

function drawFoil() {
    var w = canvas.width, h = canvas.height;
    var color = getComputedStyle(document.documentElement)
                    .getPropertyValue('--foil-color').trim() || '#c0c0c0';

    var g = ctx.createLinearGradient(0, 0, w, h);
    g.addColorStop(0,    lighten(color, 28));
    g.addColorStop(0.35, lighten(color, 10));
    g.addColorStop(0.5,  color);
    g.addColorStop(0.65, darken(color, 10));
    g.addColorStop(1,    darken(color, 28));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);

    ctx.save();
    ctx.globalAlpha = 0.045;
    for (var y = 0; y < h; y += 3) {
        ctx.fillStyle = (y % 6 === 0) ? '#ffffff' : '#000000';
        ctx.fillRect(0, y, w, 1);
    }
    ctx.restore();
}

function lighten(hex, a) { return adjustColor(hex,  a); }
function darken(hex,  a) { return adjustColor(hex, -a); }
function adjustColor(hex, a) {
    hex = hex.replace('#', '');
    if (hex.length === 3) hex = hex.split('').map(function(x) { return x + x; }).join('');
    var n = parseInt(hex, 16);
    var r = Math.min(255, Math.max(0, (n >> 16)         + a));
    var g = Math.min(255, Math.max(0, ((n >> 8) & 0xff) + a));
    var b = Math.min(255, Math.max(0, (n & 0xff)        + a));
    return 'rgb(' + r + ',' + g + ',' + b + ')';
}

// ── Scratch input ─────────────────────────────────────
function getPos(e) {
    var rect = canvas.getBoundingClientRect();
    return {
        x: (e.clientX - rect.left) * (canvas.width  / rect.width),
        y: (e.clientY - rect.top)  * (canvas.height / rect.height)
    };
}

function scratch(x, y) {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    ctx.arc(x, y, 26, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
    checkTiles(x, y);
    playScratchSound();
}

function onDown(e)      { isScratching = true;  scratch(getPos(e).x, getPos(e).y); }
function onMove(e)      { if (isScratching) scratch(getPos(e).x, getPos(e).y); }
function onUp()         { isScratching = false; }
function onTouchDown(e) { e.preventDefault(); isScratching = true;  var t = e.touches[0]; scratch(getPos(t).x, getPos(t).y); }
function onTouchMove(e) { e.preventDefault(); if (isScratching) { var t = e.touches[0]; scratch(getPos(t).x, getPos(t).y); } }

// ── Per-tile completion tracking ──────────────────────
function buildTileRects() {
    tileRects = [];
    tilesDone = 0;
    var tiles      = document.querySelectorAll('.scratch-tile');
    var canvasRect = canvas.getBoundingClientRect();
    var scaleX     = canvas.width  / canvasRect.width;
    var scaleY     = canvas.height / canvasRect.height;

    tiles.forEach(function(tile) {
        var r = tile.getBoundingClientRect();
        tileRects.push({
            x:    (r.left - canvasRect.left) * scaleX,
            y:    (r.top  - canvasRect.top)  * scaleY,
            w:    r.width  * scaleX,
            h:    r.height * scaleY,
            done: false
        });
    });
    tilesTotal = tileRects.length;
}

function checkTiles(scratchX, scratchY) {
    if (revealDone) return;
    var radius = 30;

    tileRects.forEach(function(tile) {
        if (tile.done) return;
        if (scratchX + radius < tile.x || scratchX - radius > tile.x + tile.w) return;
        if (scratchY + radius < tile.y || scratchY - radius > tile.y + tile.h) return;

        var sx = Math.max(0, Math.round(tile.x));
        var sy = Math.max(0, Math.round(tile.y));
        var sw = Math.min(Math.round(tile.w), canvas.width  - sx);
        var sh = Math.min(Math.round(tile.h), canvas.height - sy);
        if (sw <= 0 || sh <= 0) return;

        var data        = ctx.getImageData(sx, sy, sw, sh).data;
        var transparent = 0;
        for (var i = 3; i < data.length; i += 4) {
            if (data[i] < 128) transparent++;
        }

        if (transparent / (data.length / 4) >= TILE_THRESHOLD) {
            tile.done = true;
            tilesDone++;
        }
    });

    document.getElementById('progress-bar').style.width =
        (tilesTotal > 0 ? (tilesDone / tilesTotal) * 100 : 0) + '%';

    if (tilesDone >= tilesTotal && !revealDone) {
        onAllScratched();
    }
}

function clearCanvas() {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.globalCompositeOperation = 'source-over';
    document.getElementById('progress-bar').style.width = '100%';
}

// ── Reveal result ─────────────────────────────────────
function onAllScratched() {
    revealDone = true;
    clearCanvas();
    canvas.style.pointerEvents = 'none';

    var won = (scratchData && scratchData.won) ? scratchData.won : 0;

    document.getElementById('scratch-hint').classList.add('hidden');
    document.getElementById('result-row').classList.remove('hidden');

    var txt = document.getElementById('result-text');
    if (won > 0) {
        txt.classList.add('win');
        document.getElementById('result-icon').textContent = '🎉';
        document.getElementById('result-msg').textContent  = 'YOU WON $' + won.toLocaleString() + '!';
        playSound(won >= 10000 ? 'big' : 'small', won >= 10000 ? 1.0 : 0.9);
    } else {
        document.getElementById('result-icon').textContent = '😔';
        document.getElementById('result-msg').textContent  = 'No win this time!';
    }
}

// ── Open card ─────────────────────────────────────────
function openScratch(data) {
    currentItem  = data.itemName;
    scratchData  = data.scratchData;
    revealDone   = false;
    isScratching = false;
    tilesDone    = 0;

    var cfg   = data.config || {};
    var theme = cfg.revealType || 'basic';

    document.getElementById('scratch-card').setAttribute('data-theme', theme);

    var root = document.documentElement;
    root.style.setProperty('--foil-color',  cfg.scratchColor || '#c0c0c0');
    root.style.setProperty('--card-accent', cfg.accent       || '#ffffff');

    document.getElementById('scratch-title').textContent = data.label || 'SCRATCH CARD';
    document.getElementById('card-rule').textContent     = 'Match 3 to win';

    document.getElementById('result-row').classList.add('hidden');
    document.getElementById('result-text').classList.remove('win');
    document.getElementById('scratch-hint').classList.remove('hidden');
    document.getElementById('scratch-hint').textContent = 'Scratch every panel to reveal';
    document.getElementById('progress-bar').style.width = '0%';
    if (canvas) canvas.style.pointerEvents = 'auto';

    buildTiles(cfg.gridSize || 3, scratchData.won, theme);

    document.getElementById('scratch-screen').classList.remove('hidden');

    requestAnimationFrame(function() {
        requestAnimationFrame(function() {
            initCanvas();
        });
    });
}

// ── Close ─────────────────────────────────────────────
function closeUI() {
    document.getElementById('scratch-screen').classList.add('hidden');
    nuiFetch('closeUI');
}

// ── NUI messages ──────────────────────────────────────
window.addEventListener('message', function(e) {
    var d = e.data;
    if (!d || !d.type) return;
    if (d.type === 'openScratch')  openScratch(d);
    if (d.type === 'closeScratch') document.getElementById('scratch-screen').classList.add('hidden');
});

// ── Collect button ────────────────────────────────────
document.getElementById('btn-close-scratch').addEventListener('click', function() {
    if (!revealDone) return;
    nuiFetch('scratchFinished', {
        itemName: currentItem,
        won:      (scratchData && scratchData.won) ? scratchData.won : 0
    });
    closeUI();
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && revealDone) closeUI();
});