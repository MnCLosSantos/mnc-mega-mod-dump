'use strict';

/* ── State ──────────────────────────────────────────────── */
const state = {
    playing: false,
    paused: false,
    volume: 50,
    radius: 15,
    url: '',
    artwork: '',
    title: 'No song playing',
    playlists: [],
    activePlaylistId: null,
    activePlaylistIndex: null,
    skin: 'silver',

    posBase: 0,
    posBaseAt: Date.now(),
    posPlaying: false,
    duration: null,
    scrubbing: false,
};

/* ── DOM refs ───────────────────────────────────────────── */
const $ = id => document.getElementById(id);

const CP_DEBUG = false;
function cpDebug(...args) {
    if (!CP_DEBUG) return;
    console.log('%c[mnc-carplay]', 'color:#f5a623;font-weight:bold', ...args);
}

/* ── NUI post helper ────────────────────────────────────── */
function nuiFetch(action, data = {}) {
    cpDebug(`nuiFetch -> ${action}`, JSON.parse(JSON.stringify(data)));
    return fetch(`https://mnc-carplay/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(res => {
        cpDebug(`nuiFetch <- ${action} ok=${res && res.ok}`);
        return res;
    }).catch(err => {
        cpDebug(`nuiFetch X ${action} threw`, err);
        return null;
    });
}


function applyCpSkin(skin) {
    const frame = $('cp-frame');
    if (!frame) return;
    frame.dataset.skin = skin || 'silver';
}

/* ── Status bar clock ───────────────────────────────────── */
function updateClock() {
    const el = $('cp-clock');
    if (!el) return;
    const d = new Date();
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    el.textContent = `${h}:${m}`;
}
updateClock();
setInterval(updateClock, 15000);

function updateRadiusBadge(r) {
    const badge = $('cp-radius-badge');
    if (badge) badge.textContent = Math.round(r) + 'm';
    const val = $('cp-radius-val');
    if (val) val.textContent = Math.round(r) + 'm';
    const slider = $('cp-radius-slider');
    if (slider && document.activeElement !== slider) slider.value = r;
}

function updateVolDisplay(vol) {
    const val = $('cp-vol-val');
    if (val) val.textContent = Math.round(vol) + '%';
    const slider = $('cp-vol-slider');
    if (slider && document.activeElement !== slider) slider.value = vol;
}


const SUB_STATUS_HTML = {
    playing: '<i class="fa-solid fa-play"></i> Playing',
    paused:  '<i class="fa-solid fa-pause"></i> Paused',
    loading: '<i class="fa-solid fa-spinner fa-spin"></i> Loading…',
};
function setSubStatus(kind) {
    const sub = $('cp-song-sub');
    if (sub) sub.innerHTML = SUB_STATUS_HTML[kind] || '';
}
function setSubText(text) {
    const sub = $('cp-song-sub');
    if (sub) sub.textContent = text;
}

const _metaCache = new Map();
const _metaInflight = new Map();

function placeholderLabel(url) {
    if (!url) return 'Unknown';
    try {
        const u = new URL(url);
        const host = u.hostname.replace(/^www\./, '');
        if (host.includes('youtu')) return 'YouTube track';
        if (host.includes('soundcloud')) return 'SoundCloud track';
        return host;
    } catch { return url; }
}

async function fetchMeta(url) {
    if (!url) return null;
    if (_metaCache.has(url)) return _metaCache.get(url);
    if (_metaInflight.has(url)) return _metaInflight.get(url);

    let oembedUrl = null;
    const ytId = extractYtId(url);
    if (ytId) {
        oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`;
    } else if (url.includes('soundcloud.com')) {
        oembedUrl = `https://soundcloud.com/oembed?url=${encodeURIComponent(url)}&format=json`;
    }

    if (!oembedUrl) {
        const meta = { title: placeholderLabel(url), creator: '', artwork: '' };
        _metaCache.set(url, meta);
        return meta;
    }

    const promise = fetch(oembedUrl, { method: 'GET', credentials: 'omit' })
        .then(r => {
            if (!r.ok) throw new Error('oEmbed non-ok');
            return r.json();
        })
        .then(d => {
            const artwork = ytId
                ? `https://img.youtube.com/vi/${ytId}/mqdefault.jpg`
                : (d.thumbnail_url || '');
            const meta = { title: d.title || placeholderLabel(url), creator: d.author_name || '', artwork };
            _metaCache.set(url, meta);
            _metaInflight.delete(url);
            return meta;
        })
        .catch(() => {
            const artwork = ytId ? `https://img.youtube.com/vi/${ytId}/mqdefault.jpg` : '';
            const meta = { title: placeholderLabel(url), creator: '', artwork };
            _metaCache.set(url, meta);
            _metaInflight.delete(url);
            return meta;
        });

    _metaInflight.set(url, promise);
    return promise;
}

async function fetchAndDisplayMeta(url) {
    if (!url) return;
    const meta = await fetchMeta(url);
    if (state.url !== url) return;
    state.artwork = meta.artwork;
    state.title = meta.title;
    updateArtwork(meta.artwork, meta.title, meta.creator);

    if (meta.title) nuiFetch('reportTrackMeta', { url, title: meta.title });
}

function prewarmPlaylistMeta() {
    state.playlists.forEach(pl => {
        (pl.songs || []).forEach(url => {
            if (!_metaCache.has(url)) fetchMeta(url);
        });
    });
}


const _durationCache = new Map();
let _ytApiPromise = null;

function loadYoutubeIframeApi() {
    if (_ytApiPromise) return _ytApiPromise;
    _ytApiPromise = new Promise((resolve) => {
        if (window.YT && window.YT.Player) { resolve(window.YT); return; }
        const prevReady = window.onYouTubeIframeAPIReady;
        window.onYouTubeIframeAPIReady = function() {
            if (typeof prevReady === 'function') { try { prevReady(); } catch { /* ignore */ } }
            resolve(window.YT);
        };
        const tag = document.createElement('script');
        tag.src = 'https://www.youtube.com/iframe_api';
        tag.onerror = () => resolve(null);
        document.head.appendChild(tag);
        setTimeout(() => resolve(window.YT && window.YT.Player ? window.YT : null), 8000);
    });
    return _ytApiPromise;
}

function resolveYoutubeDuration(url) {
    const videoId = extractYtId(url);
    if (!videoId) return Promise.resolve(null);
    if (_durationCache.has(videoId)) return Promise.resolve(_durationCache.get(videoId));

    return loadYoutubeIframeApi().then(YT => {
        if (!YT || !YT.Player) return null;

        return new Promise((resolve) => {
            const host = document.createElement('div');
            host.style.cssText = 'position:absolute;width:1px;height:1px;top:-9999px;left:-9999px;opacity:0;pointer-events:none;';
            document.body.appendChild(host);

            let settled = false;
            let player = null;
            const timer = setTimeout(() => finish(null), 8000);

            function finish(dur) {
                if (settled) return;
                settled = true;
                clearTimeout(timer);
                _durationCache.set(videoId, dur);
                try { if (player && player.destroy) player.destroy(); } catch { /* ignore */ }
                if (host.parentNode) host.parentNode.removeChild(host);
                resolve(dur);
            }

            try {
                player = new YT.Player(host, {
                    videoId,
                    playerVars: { autoplay: 0, controls: 0, disablekb: 1 },
                    events: {
                        onReady: (e) => {
                            try {
                                e.target.mute();
                                const d = e.target.getDuration();
                                finish(typeof d === 'number' && d > 0 ? d : null);
                            } catch { finish(null); }
                        },
                        onError: () => finish(null),
                    },
                });
            } catch {
                finish(null);
            }
        });
    }).catch(() => null);
}

function resolveAndPushDuration(url) {
    if (!url) return;
    resolveYoutubeDuration(url).then(dur => {
        if (!dur) return;
        if (state.url !== url) return;
        setTrackMeta({ duration: dur });
    });
}


function getInterpolatedPosition() {
    if (!state.posPlaying) return state.posBase;
    const elapsed = (Date.now() - state.posBaseAt) / 1000;
    let pos = state.posBase + elapsed;
    if (state.duration) pos = Math.min(pos, state.duration);
    return Math.max(0, pos);
}

function formatTime(sec) {
    sec = Math.max(0, Math.floor(sec || 0));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m}:${s < 10 ? '0' : ''}${s}`;
}

function getScrubberMax(pos, dur) {
    if (typeof dur === 'number' && dur > 0) return dur;
    const floor = 180;
    const headroom = Math.ceil((pos + 60) / 30) * 30;
    return Math.max(floor, headroom);
}

function updateScrubberUI(pos, dur) {
    const hasDur = typeof dur === 'number' && dur > 0;
    const max = getScrubberMax(pos, dur);
    const clampedPos = Math.min(pos, max);

    const s = $('cp-scrub');
    if (s) {
        s.max = max;
        s.disabled = false;
        if (!state.scrubbing) s.value = clampedPos;
    }

    if ($('cp-time-elapsed')) $('cp-time-elapsed').textContent = formatTime(pos);
    if ($('cp-time-total')) $('cp-time-total').textContent = hasDur ? formatTime(dur) : '--:--';
}

function setTrackMeta({ position, duration, playing } = {}) {
    if (typeof position === 'number') {
        state.posBase = position;
        state.posBaseAt = Date.now();
    }
    if (typeof duration === 'number') {
        state.duration = duration > 0 ? duration : null;
    }
    if (typeof playing === 'boolean') {
        if (!playing) state.posBase = getInterpolatedPosition();
        state.posBaseAt = Date.now();
        state.posPlaying = playing;
    }
    if (!state.scrubbing) updateScrubberUI(getInterpolatedPosition(), state.duration);
}

setInterval(() => {
    if (state.scrubbing) return;
    updateScrubberUI(getInterpolatedPosition(), state.duration);
}, 500);

function bindScrubber(el) {
    if (!el) return;
    el.addEventListener('input', () => {
        state.scrubbing = true;
        const v = parseFloat(el.value);
        updateScrubberUI(v, state.duration);
    });
    el.addEventListener('change', () => {
        let v = parseFloat(el.value);
        if (typeof state.duration === 'number' && state.duration > 0) {
            v = Math.min(v, state.duration);
        }
        state.posBase = v;
        state.posBaseAt = Date.now();
        state.scrubbing = false;
        nuiFetch('seekTo', { position: v });
        updateScrubberUI(v, state.duration);
    });
}
bindScrubber($('cp-scrub'));

/* ── Show / hide ─────────────────────────────────────────── */
function showFrame() {
    const frame = $('cp-frame');
    if (frame) frame.classList.remove('hidden');
}

/* ── Artwork helpers ────────────────────────────────────── */
function extractYtId(url) {
    const m = url.match(/v=([^&]+)/) || url.match(/youtu\.be\/([^?]+)/);
    return m ? m[1] : null;
}

function thumbFromUrl(url) {
    const ytId = extractYtId(url);
    if (ytId) return `https://img.youtube.com/vi/${ytId}/mqdefault.jpg`;
    if (_metaCache.has(url)) return _metaCache.get(url).artwork || '';
    return '';
}

function updateArtwork(artworkUrl, titleStr, creatorStr) {
    const art = $('cp-artwork');
    const ph = $('cp-artwork-ph');
    const title = $('cp-song-title');

    if (art) {
        if (artworkUrl) {
            art.src = artworkUrl;
            art.style.display = 'block';
            if (ph) ph.style.display = 'none';
        } else {
            art.src = '';
            art.style.display = 'none';
            if (ph) ph.style.display = 'flex';
        }
    }
    if (title) { title.textContent = titleStr || 'Unknown'; setupMarquee(title); }
}

function setupMarquee(el) {
    if (!el) return;
    const viewport = el.parentElement;
    if (!viewport) return;

    el.classList.remove('marquee-active');
    el.style.removeProperty('--marquee-dist');

    requestAnimationFrame(() => {
        const overflow = el.scrollWidth - viewport.clientWidth;
        if (overflow > 2) {
            el.style.setProperty('--marquee-dist', `-${overflow}px`);
            el.classList.add('marquee-active');
        }
    });
}
window.addEventListener('resize', () => setupMarquee($('cp-song-title')));

/* ── Play/Pause icon ────────────────────────────────────── */
function setPlayPauseIcon(isPlaying) {
    const icon = $('cp-pp-icon');
    if (icon) {
        icon.classList.toggle('fa-play', !isPlaying);
        icon.classList.toggle('fa-pause', isPlaying);
    }
    state.playing = isPlaying;
}

/* ── Skip-pool ──────────────────────────────────────────── */
function getShufflePool() {
    const active = state.playlists.find(p => p.id === state.activePlaylistId);
    if (active && active.songs && active.songs.length) return active.songs;
    return state.playlists.flatMap(p => p.songs || []);
}

/* ── NUI message listener ───────────────────────────────── */
window.addEventListener('message', function(event) {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {

        case 'open': {
            state.playing = data.playing || false;
            state.paused = data.paused || false;
            state.volume = data.volume || 50;
            state.radius = data.radius || 15;
            state.url = data.url || '';
            state.playlists = data.playlists || [];
            state.skin = data.skin || 'silver';

            showFrame();
            applyCpSkin(state.skin);
            updateVolDisplay(state.volume);
            updateRadiusBadge(state.radius);
            setTrackMeta({
                position: data.position || 0,
                duration: typeof data.duration === 'number' ? data.duration : 0,
                playing: state.playing,
            });
            renderCpPlaylists();
            cpShowNowPlaying();
            prewarmPlaylistMeta();

            if (state.url) {
                const art = thumbFromUrl(state.url);
                updateArtwork(art, placeholderLabel(state.url));
                state.artwork = art;
                state.title = placeholderLabel(state.url);
                fetchAndDisplayMeta(state.url);
                resolveAndPushDuration(state.url);
            }

            setPlayPauseIcon(state.playing);
            if (state.playing) setSubStatus('playing');
            else if (state.url) setSubStatus('paused');
            else setSubText('—');
            break;
        }

        case 'close': {
            const frame = $('cp-frame');
            if (frame) frame.classList.add('hidden');
            const modal = $('cp-position-modal');
            if (modal) modal.classList.add('hidden');
            break;
        }

        case 'playState': {
            setPlayPauseIcon(!!data.playing);
            setTrackMeta({ playing: !!data.playing });
            setSubStatus(data.playing ? 'playing' : 'paused');
            break;
        }

        case 'trackMeta': {
            setTrackMeta({ position: data.position, duration: data.duration, playing: data.playing });
            break;
        }

        case 'radius': {
            state.radius = data.radius || state.radius;
            updateRadiusBadge(state.radius);
            break;
        }

        case 'songStarted': {
            state.playing = true;
            state.paused = false;
            state.url = data.url || state.url;
            const initialTitle = data.title && data.title !== data.url ? data.title : placeholderLabel(state.url);
            const initialArt = data.artwork || thumbFromUrl(state.url);
            state.artwork = initialArt;
            state.title = initialTitle;
            updateArtwork(initialArt, initialTitle);
            setPlayPauseIcon(true);
            setTrackMeta({ position: data.position || 0, duration: 0, playing: true });

            setSubStatus('playing');

            fetchAndDisplayMeta(state.url);
            resolveAndPushDuration(state.url);
            break;
        }

        case 'songEnded': {
            if (state.activePlaylistId !== null) {
                playRelativeSong(1);
            } else {
                state.playing = false;
                setPlayPauseIcon(false);
                setTrackMeta({ playing: false });
                setSubStatus('paused');
            }
            break;
        }

        case 'updatePlaylists': {
            state.playlists = data.playlists || [];
            if (state.activePlaylistId !== null) state.activePlaylistIndex = null;
            renderCpPlaylists();
            prewarmPlaylistMeta();
            break;
        }

        case 'nowPlayingHud': {
            const hud = $('cp-nowplaying-hud');
            if (!hud) break;
            if (data.show) {
                const titleEl = $('cp-np-hud-title');
                if (titleEl) titleEl.textContent = data.title || 'Unknown';
                hud.classList.remove('hidden');
            } else {
                hud.classList.add('hidden');
            }
            break;
        }
    }
});

/* ── Shared "play this url" logic ───────────────────────── */
function playUrl(url) {
    if (!url) return;
    _cpSkipBackArmedAt = null;

    const art = thumbFromUrl(url);
    const label = _metaCache.has(url) ? _metaCache.get(url).title : placeholderLabel(url);
    updateArtwork(art, label);
    state.artwork = art;
    state.title = label;
    state.url = url;
    state.paused = false;
    setTrackMeta({ position: 0, duration: 0, playing: true });

    setSubStatus('loading');

    nuiFetch('playUrl', { url, volume: state.volume, radius: state.radius }).then(async res => {
        if (!res) return;
        let payload = null;
        try { payload = await res.json(); } catch { /* not json, ignore */ }
        if (payload && payload.status === 'no_vehicle') {
            state.playing = false;
            setPlayPauseIcon(false);
            setTrackMeta({ playing: false });
            setSubText('No Carplay unit connected');
        }
    });

    fetchAndDisplayMeta(url);
    resolveAndPushDuration(url);
}

/* ── Play from URL input ─────────────────────────────────── */
window.playFromInput = function() {
    const inputEl = $('cp-url-input');
    const url = inputEl ? inputEl.value.trim() : '';
    if (!url) return;

    const finalUrl = url.includes('youtu') || url.includes('soundcloud')
        ? url
        : `https://www.youtube.com/watch?v=${url}`;

    state.activePlaylistId = null;
    state.activePlaylistIndex = null;
    playUrl(finalUrl);
    if (inputEl) inputEl.value = '';
};

/* ── Close ────────────────────────────────────────────────── */
window.closeUI = function() {
    nuiFetch('close');
};


function playPlaylistFromStart(playlistId) {
    const pl = state.playlists.find(p => p.id === playlistId);
    if (!pl || !pl.songs || !pl.songs.length) return;
    state.activePlaylistId = playlistId;
    state.activePlaylistIndex = 0;
    playUrl(pl.songs[0]);
    cpShowNowPlaying();
}

function getDisplayLabel(url) {
    if (!url) return '';
    const meta = _metaCache.get(url);
    if (meta) {
        if (meta.title && meta.creator) return `${meta.title} — ${meta.creator}`;
        if (meta.title) return meta.title;
    }
    return placeholderLabel(url);
}

function escHtml(str) {
    return String(str)
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;');
}

window.cpCenterPress = function() {
    const input = $('cp-url-input');
    const typedUrl = input ? input.value.trim() : '';

    if (typedUrl) {
        playFromInput();
        return;
    }

    if (!state.url) return;

    if (!state.playing && !state.paused) {
        playUrl(state.url);
        return;
    }

    const wasPlaying = state.playing;
    const wasPaused = state.paused;

    state.playing = !state.playing;
    state.paused = !state.paused;
    setPlayPauseIcon(state.playing);
    setTrackMeta({ playing: state.playing });
    setSubStatus(state.playing ? 'playing' : 'paused');

    nuiFetch('pauseResume').then(async res => {
        if (!res) return;
        let payload = null;
        try { payload = await res.json(); } catch { /* not json, ignore */ }
        if (payload && payload.status === 'no_vehicle') {
            state.playing = wasPlaying;
            state.paused = wasPaused;
            setPlayPauseIcon(wasPlaying);
            setTrackMeta({ playing: wasPlaying });
        }
    });
};

window.playRelativeSong = function(direction) {
    const pool = getShufflePool();
    if (!pool.length) return;

    let idx = state.activePlaylistIndex;
    if (idx === null || idx < 0 || idx >= pool.length) {
        idx = pool.indexOf(state.url);
        if (idx === -1) idx = 0;
    }

    const nextIdx = (idx + direction + pool.length) % pool.length;
    state.activePlaylistIndex = nextIdx;
    playUrl(pool[nextIdx]);
};

let _cpSkipBackArmedAt = null;
window.cpSkipBack = function() {
    const REPEAT_PRESS_WINDOW = 3000;

    if (_cpSkipBackArmedAt !== null && (Date.now() - _cpSkipBackArmedAt) < REPEAT_PRESS_WINDOW) {
        _cpSkipBackArmedAt = null;
        playRelativeSong(-1);
        return;
    }

    _cpSkipBackArmedAt = Date.now();
    state.posBase = 0;
    state.posBaseAt = Date.now();
    if (!state.scrubbing) updateScrubberUI(0, state.duration);
    nuiFetch('seekTo', { position: 0 });
};

$('cp-skip-back') && $('cp-skip-back').addEventListener('click', () => cpSkipBack());
$('cp-skip-fwd') && $('cp-skip-fwd').addEventListener('click', () => playRelativeSong(1));

/* ── Volume slider ──────────────────────────────────────── */
const volSlider = $('cp-vol-slider');
if (volSlider) {
    volSlider.addEventListener('input', () => {
        state.volume = parseInt(volSlider.value, 10);
        updateVolDisplay(state.volume);
    });
    volSlider.addEventListener('change', () => {
        nuiFetch('setVolume', { volume: state.volume });
    });
}

/* ── Radius slider — up to 50m ──────────────────────────── */
const radiusSlider = $('cp-radius-slider');
if (radiusSlider) {
    radiusSlider.addEventListener('input', () => {
        state.radius = parseInt(radiusSlider.value, 10);
        updateRadiusBadge(state.radius);
    });
    radiusSlider.addEventListener('change', () => {
        nuiFetch('setRadius', { radius: state.radius });
    });
}


window.cpShowNowPlaying = function() {
    const np = $('cp-view-nowplaying');
    const pl = $('cp-view-playlists');
    if (np) np.classList.remove('hidden');
    if (pl) pl.classList.add('hidden');
    $('cp-dock-music') && $('cp-dock-music').classList.add('active');
    $('cp-dock-playlists') && $('cp-dock-playlists').classList.remove('active');
};

window.cpShowMenu = function() {
    const np = $('cp-view-nowplaying');
    const pl = $('cp-view-playlists');
    if (np) np.classList.add('hidden');
    if (pl) pl.classList.remove('hidden');
    $('cp-dock-music') && $('cp-dock-music').classList.remove('active');
    $('cp-dock-playlists') && $('cp-dock-playlists').classList.add('active');
    cpShowPlList();
    nuiFetch('getPlaylists');
};

function cpSetSubview(id) {
    ['cp-pl-subview-list', 'cp-pl-subview-new', 'cp-pl-subview-edit'].forEach(v => {
        const el = $(v);
        if (el) el.classList.toggle('hidden', v !== id);
    });
}

window.cpShowPlList = function() {
    renderCpPlaylists();
    cpSetSubview('cp-pl-subview-list');
};

/* ── New playlist ── */
let _cpNewSongs = [];

window.cpShowNewPlaylist = function() {
    _cpNewSongs = [];
    const nameIn = $('cp-pl-name-input');
    const urlIn = $('cp-pl-song-input');
    if (nameIn) nameIn.value = '';
    if (urlIn) urlIn.value = '';
    renderCpNewSongs();
    cpSetSubview('cp-pl-subview-new');
};

window.cpAddSongToNew = function() {
    const input = $('cp-pl-song-input');
    const url = input ? input.value.trim() : '';
    if (!url) return;
    const finalUrl = url.includes('youtu') || url.includes('soundcloud')
        ? url : `https://www.youtube.com/watch?v=${url}`;
    _cpNewSongs.push(finalUrl);
    if (input) input.value = '';
    renderCpNewSongs();
    fetchMeta(finalUrl).then(() => renderCpNewSongs());
};

window.cpSaveNewPlaylist = function() {
    const nameIn = $('cp-pl-name-input');
    const name = nameIn ? nameIn.value.trim() : '';
    if (!name) return;
    if (!_cpNewSongs.length) return;
    nuiFetch('savePlaylist', { name, songs: _cpNewSongs });
    _cpNewSongs = [];
    cpShowPlList();
};

function renderCpNewSongs() {
    const list = $('cp-pl-songs-new');
    if (!list) return;
    list.innerHTML = '';
    _cpNewSongs.forEach((url, i) => {
        const thumb = thumbFromUrl(url);
        const label = getDisplayLabel(url);
        const item = document.createElement('div');
        item.className = 'cp-pl-song-item';
        item.innerHTML = `
            ${thumb
                ? `<img class="cp-song-thumb" src="${escHtml(thumb)}" onerror="this.style.display='none'" />`
                : `<div class="cp-song-thumb cp-song-thumb-ph"></div>`}
            <span class="cp-song-label" title="${escHtml(url)}">${escHtml(label)}</span>
            <button class="cp-pl-song-del" data-index="${i}"><i class="fa-solid fa-xmark"></i></button>
        `;
        list.appendChild(item);
    });
}

$('cp-pl-songs-new') && $('cp-pl-songs-new').addEventListener('click', e => {
    const btn = e.target.closest('.cp-pl-song-del');
    if (!btn) return;
    _cpNewSongs.splice(parseInt(btn.dataset.index, 10), 1);
    renderCpNewSongs();
});

/* ── Edit existing playlist ── */
let _cpEditId = null;
let _cpEditSongs = [];
let _cpSongDeletePending = null;
let _cpSongDeletePendingTimer = null;

function cpShowEditPlaylist(id) {
    const pl = state.playlists.find(p => p.id === id);
    if (!pl) return;
    _cpEditId = id;
    _cpEditSongs = [...pl.songs];
    _cpSongDeletePending = null;
    clearTimeout(_cpSongDeletePendingTimer);
    const title = $('cp-pl-edit-title');
    if (title) title.textContent = pl.name;
    const urlIn = $('cp-pl-edit-url');
    if (urlIn) urlIn.value = '';
    renderCpEditSongs();
    cpSetSubview('cp-pl-subview-edit');
}

window.cpAddSongToEdit = function() {
    const input = $('cp-pl-edit-url');
    const url = input ? input.value.trim() : '';
    if (!url) return;
    const finalUrl = url.includes('youtu') || url.includes('soundcloud')
        ? url : `https://www.youtube.com/watch?v=${url}`;
    if (_cpEditSongs.includes(finalUrl)) return;
    _cpEditSongs.push(finalUrl);
    if (input) input.value = '';
    renderCpEditSongs();
    fetchMeta(finalUrl).then(() => renderCpEditSongs());
    _cpFlushEdit();
};

function _cpFlushEdit() {
    if (_cpEditId === null) return;
    const pl = state.playlists.find(p => p.id === _cpEditId);
    if (pl) pl.songs = [..._cpEditSongs];
    if (_cpEditId === state.activePlaylistId) state.activePlaylistIndex = null;
    nuiFetch('updatePlaylist', { id: _cpEditId, songs: _cpEditSongs });
}

function renderCpEditSongs() {
    const list = $('cp-pl-songs-edit');
    if (!list) return;
    list.innerHTML = '';
    _cpEditSongs.forEach((url, i) => {
        const thumb = thumbFromUrl(url);
        const label = getDisplayLabel(url);
        const armed = _cpSongDeletePending === i;
        const item = document.createElement('div');
        item.className = 'cp-pl-song-item';
        item.innerHTML = `
            ${thumb
                ? `<img class="cp-song-thumb" src="${escHtml(thumb)}" onerror="this.style.display='none'" />`
                : `<div class="cp-song-thumb cp-song-thumb-ph"></div>`}
            <span class="cp-song-label" title="${escHtml(url)}">${escHtml(label)}</span>
            <button class="cp-pl-song-del ${armed ? 'cp-pl-song-del-armed' : ''}" data-index="${i}"><i class="fa-solid ${armed ? 'fa-check' : 'fa-xmark'}"></i></button>
        `;
        list.appendChild(item);
    });
}

$('cp-pl-songs-edit') && $('cp-pl-songs-edit').addEventListener('click', e => {
    const btn = e.target.closest('.cp-pl-song-del');
    if (!btn) return;
    const idx = parseInt(btn.dataset.index, 10);
    if (_cpSongDeletePending === idx) {
        clearTimeout(_cpSongDeletePendingTimer);
        _cpSongDeletePending = null;
        _cpEditSongs.splice(idx, 1);
        renderCpEditSongs();
        _cpFlushEdit();
    } else {
        _cpSongDeletePending = idx;
        renderCpEditSongs();
        clearTimeout(_cpSongDeletePendingTimer);
        _cpSongDeletePendingTimer = setTimeout(() => {
            _cpSongDeletePending = null;
            renderCpEditSongs();
        }, 3000);
    }
});

$('cp-pl-songs-edit') && $('cp-pl-songs-edit').addEventListener('click', e => {
    if (e.target.closest('.cp-pl-song-del')) return;
    const item = e.target.closest('.cp-pl-song-item');
    if (!item) return;
    const idx = [...item.parentElement.children].indexOf(item);
    if (_cpEditSongs[idx]) {
        state.activePlaylistId = _cpEditId;
        state.activePlaylistIndex = idx;
        playUrl(_cpEditSongs[idx]);
        cpShowNowPlaying();
    }
});

/* ── Playlist list render ── */
let _cpDeletePending = null;
let _cpDeletePendingTimer = null;

function renderCpPlaylists() {
    const list = $('cp-pl-list');
    if (!list) return;
    list.innerHTML = '';

    if (!state.playlists.length) {
        list.innerHTML = '<p class="cp-pl-empty">No playlists yet.</p>';
        return;
    }

    state.playlists.forEach(pl => {
        const card = document.createElement('div');
        card.className = 'cp-pl-card';
        card.dataset.id = pl.id;

        const delArmed = _cpDeletePending === pl.id;

        card.innerHTML = `
            <div class="cp-pl-card-header">
                <button class="cp-pl-card-play" data-action="playall" data-id="${pl.id}" title="Play whole playlist"><i class="fa-solid fa-play"></i></button>
                <span class="cp-pl-card-name" data-action="edit" data-id="${pl.id}">${escHtml(pl.name)}</span>
                <span class="cp-pl-card-count">${pl.songs.length}</span>
                <button class="cp-pl-card-del ${delArmed ? 'cp-pl-del-armed' : ''}" data-action="delete" data-id="${pl.id}"><i class="fa-solid ${delArmed ? 'fa-check' : 'fa-trash'}"></i></button>
            </div>
        `;
        list.appendChild(card);
    });
}

$('cp-pl-list') && $('cp-pl-list').addEventListener('click', e => {
    const target = e.target.closest('[data-action]');
    if (!target) return;
    const action = target.dataset.action;
    const id = parseInt(target.dataset.id, 10);

    if (action === 'edit') {
        cpShowEditPlaylist(id);
    } else if (action === 'playall') {
        e.stopPropagation();
        playPlaylistFromStart(id);
    } else if (action === 'delete') {
        e.stopPropagation();
        if (_cpDeletePending === id) {
            clearTimeout(_cpDeletePendingTimer);
            _cpDeletePending = null;
            nuiFetch('deletePlaylist', { id });
            state.playlists = state.playlists.filter(p => p.id !== id);
            if (state.activePlaylistId === id) {
                state.activePlaylistId = null;
                state.activePlaylistIndex = null;
            }
            renderCpPlaylists();
        } else {
            _cpDeletePending = id;
            renderCpPlaylists();
            clearTimeout(_cpDeletePendingTimer);
            _cpDeletePendingTimer = setTimeout(() => {
                _cpDeletePending = null;
                renderCpPlaylists();
            }, 3000);
        }
    }
});


const posState = {
    offset:      { x: 0, y: 0, z: 0 },
    rotation:    { x: 0, y: 0, z: 0 },
    propModel:   null,
    propOptions: [],

    propHidden:     false,
    worldUiEnabled: true,
};

const _posSliderIds = {
    offset:   { x: 'cp-pos-x', y: 'cp-pos-y', z: 'cp-pos-z' },
    rotation: { x: 'cp-rot-x', y: 'cp-rot-y', z: 'cp-rot-z' },
};

/* ── Tablet model picker ── */
function cpRenderPropOptions() {
    const container = $('cp-prop-options');
    if (!container) return;
    container.innerHTML = '';

    (posState.propOptions || []).forEach(opt => {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'cp-prop-opt' + (opt.id === posState.propModel ? ' active' : '');
        btn.textContent = opt.label || opt.id;
        btn.dataset.id = opt.id;
        btn.addEventListener('click', () => cpSelectPropModel(opt.id));
        container.appendChild(btn);
    });
}

function cpSelectPropModel(id) {
    if (!id || posState.propModel === id) return;
    cpDebug('cpSelectPropModel', { from: posState.propModel, to: id });
    posState.propModel = id;
    cpRenderPropOptions();
    nuiFetch('previewPropModel', { propModel: id });
}

function cpSyncPosSliders() {
    cpDebug('cpSyncPosSliders() seeding sliders from posState', {
        offset: { ...posState.offset }, rotation: { ...posState.rotation },
    });
    ['x', 'y', 'z'].forEach(axis => {
        const oId = _posSliderIds.offset[axis];
        const oEl = $(oId);
        const oVal = $(oId + '-val');
        if (oEl) oEl.value = posState.offset[axis];
        if (oVal) oVal.textContent = posState.offset[axis].toFixed(2);

        const rId = _posSliderIds.rotation[axis];
        const rEl = $(rId);
        const rVal = $(rId + '-val');
        if (!rEl) {
            cpDebug(`cpSyncPosSliders: rotation slider #${rId} (axis=${axis}) NOT FOUND in DOM`);
        } else {
            rEl.value = posState.rotation[axis];
            cpDebug(`cpSyncPosSliders: set #${rId} (rot.${axis}) element.value=${rEl.value} (wanted ${posState.rotation[axis]})`);
        }
        if (rVal) rVal.textContent = Math.round(posState.rotation[axis]) + '°';
    });
}

let _posPreviewThrottled = false;
let _posPreviewPending = false;
let _posPreviewCallSeq = 0;
function cpPreviewPosition() {
    if (_posPreviewThrottled) {
        _posPreviewPending = true;
        cpDebug('cpPreviewPosition: throttled, queuing trailing call', { rotation: { ...posState.rotation } });
        return;
    }
    const seq = ++_posPreviewCallSeq;
    _posPreviewThrottled = true;
    cpDebug(`cpPreviewPosition #${seq} firing (leading)`, {
        offset: { ...posState.offset }, rotation: { ...posState.rotation },
    });
    nuiFetch('previewPosition', { offset: { ...posState.offset }, rotation: { ...posState.rotation } });
    setTimeout(() => {
        _posPreviewThrottled = false;
        if (_posPreviewPending) {
            _posPreviewPending = false;
            cpDebug(`cpPreviewPosition #${seq} window elapsed, firing queued trailing call`);
            cpPreviewPosition();
        } else {
            cpDebug(`cpPreviewPosition #${seq} window elapsed, nothing queued`);
        }
    }, 16);
}

function cpBindPosSlider(id, group, axis, isRotation) {
    const el = $(id);
    if (!el) {
        cpDebug(`cpBindPosSlider: element #${id} (${group}.${axis}) not found — listener NOT bound`);
        return;
    }
    el.addEventListener('input', () => {
        const v = parseFloat(el.value);
        const prev = posState[group][axis];
        posState[group][axis] = v;
        const valEl = $(id + '-val');
        if (valEl) valEl.textContent = isRotation ? Math.round(v) + '°' : v.toFixed(2);
        if (isRotation) {
            cpDebug(`slider input: rotation.${axis} ${prev} -> ${v} (raw el.value=${el.value})`);
        }
        cpPreviewPosition();
    });
}

Object.entries(_posSliderIds.offset).forEach(([axis, id]) => cpBindPosSlider(id, 'offset', axis, false));
Object.entries(_posSliderIds.rotation).forEach(([axis, id]) => cpBindPosSlider(id, 'rotation', axis, true));

function cpSyncModalToggles() {
    const hiddenEl = $('cp-prop-hidden');
    if (hiddenEl) hiddenEl.checked = !!posState.propHidden;

    const hudHideEl = $('cp-worldui-enabled');
    if (hudHideEl) hudHideEl.checked = !posState.worldUiEnabled;
}

function cpBindToggle(id, stateKey) {
    const el = $(id);
    if (!el) return;
    el.addEventListener('change', () => {
        posState[stateKey] = el.checked;
        nuiFetch('previewToggle', { [stateKey]: el.checked });
    });
}
cpBindToggle('cp-prop-hidden', 'propHidden');

const _hudHideToggleEl = $('cp-worldui-enabled');
if (_hudHideToggleEl) {
    _hudHideToggleEl.addEventListener('change', () => {
        posState.worldUiEnabled = !_hudHideToggleEl.checked;
        nuiFetch('previewToggle', { worldUiEnabled: posState.worldUiEnabled });
    });
}

window.cpOpenPositionModal = async function() {
    const res = await nuiFetch('openPositionModal');
    let payload = null;
    try { payload = res ? await res.json() : null; } catch (err) {
        cpDebug('cpOpenPositionModal: failed to parse JSON response', err);
    }
    cpDebug('cpOpenPositionModal: received payload', payload);
    if (!payload || payload.status !== 'ok') {
        cpDebug(`cpOpenPositionModal: aborting, status=${payload && payload.status}`);
        return;
    }

    posState.offset = { ...payload.offset };
    posState.rotation = { ...payload.rotation };
    posState.propModel = payload.propModel || null;
    posState.propOptions = payload.propOptions || [];

    posState.propHidden = payload.propHidden === true;
    posState.worldUiEnabled = payload.worldUiEnabled !== false;

    cpDebug('cpOpenPositionModal: posState seeded', {
        offset: { ...posState.offset }, rotation: { ...posState.rotation }, propModel: posState.propModel,
        propHidden: posState.propHidden, worldUiEnabled: posState.worldUiEnabled,
    });
    cpSyncPosSliders();
    cpRenderPropOptions();
    cpSyncModalToggles();

    const frame = $('cp-frame');
    const modal = $('cp-position-modal');
    if (frame) frame.classList.add('hidden');
    if (modal) modal.classList.remove('hidden');
};

function cpClosePositionModal() {
    const frame = $('cp-frame');
    const modal = $('cp-position-modal');
    if (modal) modal.classList.add('hidden');
    if (frame) frame.classList.remove('hidden');
}

window.cpSavePosition = function() {
    cpDebug('cpSavePosition: sending final rotation + model', { ...posState.rotation, propModel: posState.propModel });
    nuiFetch('savePosition', {
        offset: posState.offset, rotation: posState.rotation, propModel: posState.propModel,
        propHidden: posState.propHidden, worldUiEnabled: posState.worldUiEnabled,
    });
    cpClosePositionModal();
};

window.cpCancelPosition = function() {
    cpDebug('cpCancelPosition: discarding previews, reverting to last saved position + model');
    nuiFetch('cancelPosition');
    cpClosePositionModal();
};

/* ── Keyboard close (Escape) ────────────────────────────── */
document.addEventListener('keydown', e => {
    if (e.key !== 'Escape') return;
    const modal = $('cp-position-modal');
    if (modal && !modal.classList.contains('hidden')) {
        cpCancelPosition();
    } else {
        closeUI();
    }
});