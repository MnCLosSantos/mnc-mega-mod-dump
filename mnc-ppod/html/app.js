/* ═══════════════════════════════════════════════════════════
   mnc-ppod  |  app.js
   ═══════════════════════════════════════════════════════════ */

'use strict';

/* ── State ──────────────────────────────────────────────── */
const state = {
    playing: false,
    // True only when a track is genuinely paused (a live, resumable
    // xsound instance exists on the client). Stays false both when
    // nothing is loaded AND when a track never actually started, or
    // had its instance destroyed (e.g. after disconnecting from a
    // speaker) -- those cases need a fresh playUrl() instead of a
    // pause/resume toggle. See ipodCenterPress().
    paused: false,
    volume: 50,
    radius: 20,
    url: '',
    artwork: '',
    title: 'No song playing',
    playlists: [],
    expandedIpodPlaylistId: null,
    activePlaylistId: null,   // playlist the current/last song was pulled from
    activePlaylistIndex: null, // this song's index within that playlist's pool --
                                // kept in sync locally by playRelativeSong() instead
                                // of being re-derived from state.url on every skip
    skin: 'silver',           // current ppod skin/colour
    battery: 100,             // current ppod battery %

    // Scrubber / local playback clock. posBase is the last known
    // position (seconds) as of posBaseAt (a Date.now() timestamp);
    // while posPlaying is true we interpolate forward from there every
    // tick instead of needing a message from Lua every second. This
    // mirrors the same startedAt/pausedDuration clock math server.lua
    // and client.lua already use for their own elapsed-time tracking.
    posBase: 0,
    posBaseAt: Date.now(),
    posPlaying: false,
    duration: null,     // seconds, or null while unknown
    scrubbing: false,   // true while the user is actively dragging a slider
};

/* ── DOM refs ───────────────────────────────────────────── */
const $ = id => document.getElementById(id);

/* ── NUI post helper ────────────────────────────────────── */
function nuiFetch(action, data = {}) {
    return fetch(`https://mnc-ppod/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).catch(() => null);
}

/* ── iPod skin ──────────────────────────────────────────────
   Applied as a data-skin attribute on the ipod frame; style.css maps
   each skin id to a set of CSS custom properties (and, for the 5
   "artwork" skins, a themed background) scoped under that attribute. */
function applyIpodSkin(skin) {
    const frame = $('ipod-frame');
    if (!frame) return;
    frame.dataset.skin = skin || 'silver';
}

/* ── Battery display ─────────────────────────────────────── */
function updateBatteryDisplay(pct) {
    const el = $('ipod-battery');
    if (!el) return;
    const clamped = Math.max(0, Math.min(100, Math.round(pct)));
    el.textContent = clamped + '%';
    el.classList.toggle('battery-low', clamped <= 15);
}

/* ════════════════════════════════════════════════════════════
   SONG METADATA  (title + creator from oEmbed)
   ════════════════════════════════════════════════════════════ */

// In-memory cache: url → { title, creator, artwork }
const _metaCache = new Map();
// In-flight fetches: url → Promise<meta>
const _metaInflight = new Map();

/**
 * Returns a placeholder label while we wait for real metadata.
 * Falls back gracefully for non-YT/SC URLs.
 */
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

/**
 * Fetch oEmbed metadata for a URL.
 * Resolves to { title, creator, artwork }.
 * Safe to call multiple times — deduped and cached.
 */
async function fetchMeta(url) {
    if (!url) return null;
    if (_metaCache.has(url)) return _metaCache.get(url);
    if (_metaInflight.has(url)) return _metaInflight.get(url);

    // Determine oEmbed endpoint
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

    // FiveM's CEF blocks cross-origin requests by default. We attempt
    // the oEmbed fetch with credentials omitted; if it fails (which is
    // normal for SoundCloud in-game) we fall back cleanly to a
    // placeholder. YouTube thumbs are fetched via a direct img src
    // which bypasses the CORS restriction, so artwork still works.
    const promise = fetch(oembedUrl, { method: 'GET', credentials: 'omit' })
        .then(r => {
            if (!r.ok) throw new Error('oEmbed non-ok');
            return r.json();
        })
        .then(d => {
            const artwork = ytId
                ? `https://img.youtube.com/vi/${ytId}/mqdefault.jpg`
                : (d.thumbnail_url || '');
            const meta = {
                title:   d.title        || placeholderLabel(url),
                creator: d.author_name  || '',
                artwork,
            };
            _metaCache.set(url, meta);
            _metaInflight.delete(url);
            return meta;
        })
        .catch(() => {
            // Network blocked in FiveM CEF for external domains — fall back cleanly
            const artwork = ytId ? `https://img.youtube.com/vi/${ytId}/mqdefault.jpg` : '';
            const meta = { title: placeholderLabel(url), creator: '', artwork };
            _metaCache.set(url, meta);
            _metaInflight.delete(url);
            return meta;
        });

    _metaInflight.set(url, promise);
    return promise;
}

/**
 * Fetch metadata for a URL and update the "now playing" display
 * immediately.
 */
async function fetchAndDisplayMeta(url) {
    if (!url) return;
    const meta = await fetchMeta(url);
    // Only update if this is still the active track
    if (state.url !== url) return;
    state.artwork = meta.artwork;
    state.title   = meta.title;
    updateArtwork(meta.artwork, meta.title, meta.creator);
}

/**
 * Pre-warm the metadata cache for all songs in every playlist.
 * Called silently in the background so list renders are instant.
 */
function prewarmPlaylistMeta() {
    state.playlists.forEach(pl => {
        (pl.songs || []).forEach(url => {
            if (!_metaCache.has(url)) fetchMeta(url);
        });
    });
}

/* ════════════════════════════════════════════════════════════
   YOUTUBE DURATION PROBE
   ════════════════════════════════════════════════════════════
   client.lua's own duration lookup goes through xsound's getDuration()
   export, which plenty of xsound builds simply don't implement (see
   the comment on resolveTrackDuration in client.lua) — on those builds
   currentTrackDuration just stays 0/unknown forever, which is why the
   scrubber kept using its auto-growing fallback range instead of ever
   capping to the real song length.

   This resolves the ACTUAL duration straight from YouTube itself via a
   second, hidden, muted, never-played YT.Player instance used only to
   read getDuration() off its metadata once cued. It's entirely
   separate from the xsound instance that actually plays the audio, and
   from client.lua's playback/end-watch/auto-advance logic — it only
   ever feeds a number into the same setTrackMeta() path Lua's own
   duration push already uses, so it can only improve what the scrubber
   caps to, never touch how/when songs advance. */

const _durationCache = new Map();   // youtube videoId -> seconds, or null
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
        // In case the CEF context blocks/never loads it, don't hang forever.
        setTimeout(() => resolve(window.YT && window.YT.Player ? window.YT : null), 8000);
    });
    return _ytApiPromise;
}

/**
 * Resolves a YouTube video's real duration in seconds. Resolves null
 * for anything that isn't a YouTube link, or if the lookup fails/times
 * out — callers treat null exactly like "duration unknown" (the
 * existing fallback behaviour), so this can only ever improve on that,
 * never regress it.
 */
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
            let player  = null;
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

/**
 * Looks up the real duration for a URL and, if it's still the active
 * track by the time it resolves, pushes it through setTrackMeta() —
 * the exact same merge point client.lua's own duration push uses — so
 * the scrubber caps to it exactly like a Lua-resolved duration always
 * has.
 */
function resolveAndPushDuration(url) {
    if (!url) return;
    resolveYoutubeDuration(url).then(dur => {
        if (!dur) return;
        if (state.url !== url) return; // track changed while we were looking it up
        setTrackMeta({ duration: dur });
    });
}

/* ════════════════════════════════════════════════════════════
   SCRUBBER  (position/duration clock + draggable seek slider)
   ════════════════════════════════════════════════════════════
   xsound has no push-every-frame position API, so — same trick as the
   server's own getElapsed()/client's ipodElapsed() — we just remember
   the last known position plus when it was accurate, and interpolate
   forward locally while playing. Lua pokes us with fresh anchors
   (position/duration/playing) via the 'open', 'songStarted',
   'playState' and 'trackMeta' NUI messages; everything in between is
   just this client-side clock ticking.

   Duration is best-effort: some xsound builds/versions don't expose a
   getDuration() export at all, in which case Lua's currentTrackDuration
   just stays "unknown" forever. The slider must stay fully USABLE
   either way — a real max is what actually made it draggable in the
   first place (a <input type=range> with min===max simply can't move),
   so when the real duration isn't known we fall back to a generous,
   auto-growing range instead of locking the slider at 0–0. */

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

/**
 * Picks the slider's max. When the real duration is known, use it
 * exactly. Otherwise fall back to a range that always stays a
 * comfortable step ahead of the current position — rounded to the
 * nearest 30s so it doesn't visibly jitter every tick — so the user
 * can always drag forward (or back) instead of the slider being stuck
 * unusable at 0–0 just because xsound never told us how long the
 * track is.
 */
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

    const s = $('ipod-scrub');
    if (s) {
        s.max = max;
        s.disabled = false;
        if (!state.scrubbing) s.value = clampedPos;
    }

    const elapsedText = formatTime(pos);
    const totalText   = hasDur ? formatTime(dur) : '--:--';
    if ($('ipod-time-elapsed')) $('ipod-time-elapsed').textContent = elapsedText;
    if ($('ipod-time-total'))   $('ipod-time-total').textContent   = totalText;
}

/**
 * Merges in whatever fresh anchor info Lua just sent (any subset of
 * position/duration/playing — undefined fields are left untouched).
 * duration of 0 means "known to be unresolved yet", surfaced to the
 * rest of the app as null so `if (state.duration)` checks read clean.
 */
function setTrackMeta({ position, duration, playing } = {}) {
    if (typeof position === 'number') {
        state.posBase   = position;
        state.posBaseAt = Date.now();
    }
    if (typeof duration === 'number') {
        state.duration = duration > 0 ? duration : null;
    }
    if (typeof playing === 'boolean') {
        if (!playing) {
            // Freeze the clock at wherever it currently reads, rather
            // than snapping back to the last explicit position anchor.
            state.posBase = getInterpolatedPosition();
        }
        state.posBaseAt  = Date.now();
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
        // The slider's max can go stale mid-drag (its periodic refresh is
        // paused while scrubbing so it doesn't fight the user's mouse —
        // see the setInterval guard above), so a drag that started before
        // the real duration was known could otherwise release past the
        // track's actual length. Clamp here, once, using state.duration
        // directly (kept up to date by setTrackMeta() regardless of
        // scrubbing) rather than touching the dynamic fallback-range in
        // getScrubberMax — seeking past the real end is what trips
        // client.lua's end-of-track stall detector and fires a premature
        // songEnded, which is what broke playlist auto-advance before.
        if (typeof state.duration === 'number' && state.duration > 0) {
            v = Math.min(v, state.duration);
        }
        state.posBase   = v;
        state.posBaseAt = Date.now();
        state.scrubbing = false;
        nuiFetch('seekTo', { position: v });
        // Resync the slider/labels immediately in case max was stale.
        updateScrubberUI(v, state.duration);
    });
}
bindScrubber($('ipod-scrub'));

/* ── Show / hide the frame ──────────────────────────────── */
function showFrame() {
    const frame = $('ipod-frame');
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
    // Check cache for SoundCloud thumbs
    if (_metaCache.has(url)) return _metaCache.get(url).artwork || '';
    return '';
}

function updateArtwork(artworkUrl, titleStr, creatorStr) {
    const ipArt   = $('ipod-artwork');
    const ipPh    = $('ipod-artwork-ph');
    const ipTitle = $('ipod-song-title');
    const ipSub   = $('ipod-song-sub');

    if (ipArt) {
        if (artworkUrl) {
            ipArt.src = artworkUrl;
            ipArt.style.display = 'block';
            if (ipPh) ipPh.style.display = 'none';
        } else {
            ipArt.src = '';
            ipArt.style.display = 'none';
            if (ipPh) ipPh.style.display = 'flex';
        }
    }
    if (ipTitle) { ipTitle.textContent = titleStr || 'Unknown'; setupMarquee(ipTitle); }
    if (ipSub && creatorStr && (ipSub.textContent === '▶ Playing' || ipSub.textContent === '⏸ Paused')) {
        ipSub.textContent = creatorStr;
    }
}

/* ── Marquee ────────────────────────────────────────────────
   Measures how far the title text actually overflows its
   viewport and sets that exact distance as --marquee-dist (px).
   Only animates when there's real overflow, so short titles stay
   put and long titles are always fully reachable — never cut off. */
function setupMarquee(el) {
    if (!el) return;
    const viewport = el.parentElement;
    if (!viewport) return;

    // Reset first so measurements aren't skewed by a previous run
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

window.addEventListener('resize', () => {
    setupMarquee($('ipod-song-title'));
});

/* ── Play/Pause icon ────────────────────────────────────── */
function setPlayPauseIcon(isPlaying) {
    const ipIcon = $('ipod-pp-icon');
    if (ipIcon) {
        ipIcon.innerHTML = isPlaying
            ? '<path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>'
            : '<path d="M8 5v14l11-7z"/>';
    }
    state.playing = isPlaying;
}

/* ── Volume bar ─────────────────────────────────────────── */
function updateIpodVolBar(vol) {
    const fill = $('ipod-vol-fill');
    if (fill) fill.style.width = vol + '%';
}

/* ── Skip-pool: the active playlist, or every song across all
   playlists if none is active. Used for next/previous and for
   auto-advance when a track finishes on its own. ── */
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
            state.playing   = data.playing || false;
            state.paused    = data.paused  || false;
            state.volume    = data.volume  || 50;
            state.radius    = data.radius  || 20;
            state.url       = data.url     || '';
            state.playlists = data.playlists || [];
            state.skin      = data.skin    || 'silver';
            state.battery   = (typeof data.battery === 'number') ? data.battery : 100;

            showFrame();
            applyIpodSkin(state.skin);
            updateBatteryDisplay(state.battery);
            updateIpodVolBar(state.volume);
            setTrackMeta({
                position: data.position || 0,
                duration: typeof data.duration === 'number' ? data.duration : 0,
                playing:  state.playing,
            });
            renderIpodPlaylists();
            ipodShowNowPlaying();

            // Pre-warm metadata for all playlist songs in background
            prewarmPlaylistMeta();

            if (state.url) {
                // Show artwork/placeholder immediately, then resolve real title
                const art = thumbFromUrl(state.url);
                updateArtwork(art, placeholderLabel(state.url));
                state.artwork = art;
                state.title   = placeholderLabel(state.url);
                // Fetch real title async
                fetchAndDisplayMeta(state.url);
                resolveAndPushDuration(state.url);
            }

            setPlayPauseIcon(state.playing);
            const ipSub = $('ipod-song-sub');
            if (ipSub) ipSub.textContent = state.playing ? '▶ Playing' : state.url ? '⏸ Paused' : '—';
            break;
        }

        case 'close': {
            const frame = $('ipod-frame');
            if (frame) frame.classList.add('hidden');
            break;
        }

        case 'battery': {
            state.battery = (typeof data.battery === 'number') ? data.battery : state.battery;
            updateBatteryDisplay(state.battery);
            break;
        }

        case 'playState': {
            // Pushed when the client pauses/resumes the transport on its
            // own (headphones taken off/put back on, a connected speaker
            // being picked up, another in-range listener toggling it,
            // etc.) so the UI — and the scrubber's clock — stay truthful
            // even though no user click on THIS screen caused the change.
            setPlayPauseIcon(!!data.playing);
            setTrackMeta({ playing: !!data.playing });
            const ipSub = $('ipod-song-sub');
            if (ipSub) ipSub.textContent = data.playing ? '▶ Playing' : '⏸ Paused';
            break;
        }

        case 'trackMeta': {
            // Partial position/duration/playing update pushed whenever
            // Lua learns something new mid-session (duration resolving
            // async after a track starts, a relayed seek landing, a
            // speaker relaying a track already in progress).
            setTrackMeta({ position: data.position, duration: data.duration, playing: data.playing });
            break;
        }

        case 'songStarted': {
            state.playing  = true;
            state.paused   = false;
            state.url      = data.url     || state.url;
            // Use server-provided title as initial fallback, then override with real meta
            const initialTitle = data.title && data.title !== data.url ? data.title : placeholderLabel(state.url);
            const initialArt   = data.artwork || thumbFromUrl(state.url);
            state.artwork  = initialArt;
            state.title    = initialTitle;
            updateArtwork(initialArt, initialTitle);
            setPlayPauseIcon(true);
            setTrackMeta({ position: data.position || 0, duration: 0, playing: true });

            const ipSub = $('ipod-song-sub');
            if (ipSub) ipSub.textContent = '▶ Playing';

            // Fetch real metadata and update displays
            fetchAndDisplayMeta(state.url);
            resolveAndPushDuration(state.url);
            break;
        }

        case 'songEnded': {
            // The client detected the current track finished on its own
            // (not a manual stop/pause). If it was pulled from a
            // playlist, auto-advance to the next song — playRelativeSong
            // wraps from the last song back to the first, which is what
            // gives us "repeat the playlist". Outside of a playlist
            // there's nothing to advance into, so just settle into a
            // stopped state.
            if (state.activePlaylistId !== null) {
                playRelativeSong(1);
            } else {
                state.playing = false;
                setPlayPauseIcon(false);
                setTrackMeta({ playing: false });
                const ipSub = $('ipod-song-sub');
                if (ipSub) ipSub.textContent = '⏸ Paused';
            }
            break;
        }

        case 'updatePlaylists': {
            state.playlists = data.playlists || [];
            if (state.activePlaylistId !== null) state.activePlaylistIndex = null;
            renderIpodPlaylists();
            prewarmPlaylistMeta();
            break;
        }
    }
});

/* ── Shared "play this url" logic ───────────────────────── */
function playUrl(url) {
    if (!url) return;

    // A real track change cancels any pending "press skip-back again to go
    // to the previous track" arm from ipodSkipBack() -- that arm should only
    // survive across the restart-in-place press, not into whatever song plays
    // next.
    _ipodSkipBackArmedAt = null;

    // Optimistic UI first…
    const art = thumbFromUrl(url);
    const label = _metaCache.has(url) ? _metaCache.get(url).title : placeholderLabel(url);
    updateArtwork(art, label);
    state.artwork = art;
    state.title   = label;
    state.url     = url;
    state.paused  = false;
    setTrackMeta({ position: 0, duration: 0, playing: true });

    const ipSub = $('ipod-song-sub');
    if (ipSub) ipSub.textContent = '⏳ Loading…';

    // …then reconcile with whatever the client actually did. The
    // client can refuse ipod playback (e.g. no headphones/speaker),
    // in which case we roll the "Loading…" state back instead of
    // leaving it stuck.
    nuiFetch('playUrl', { url, volume: state.volume, radius: state.radius }).then(async res => {
        if (!res) return;
        let payload = null;
        try { payload = await res.json(); } catch { /* not json, ignore */ }
        if (payload && payload.status === 'no_headphones') {
            state.playing = false;
            setPlayPauseIcon(false);
            setTrackMeta({ playing: false });
            if (ipSub) ipSub.textContent = 'Plug in headphones or connect a speaker';
        } else if (payload && payload.status === 'unsupported_url') {
            state.playing = false;
            setPlayPauseIcon(false);
            setTrackMeta({ playing: false });
            if (ipSub) ipSub.textContent = "Can't play playlist links — paste a single video link";
        }
    });

    // Fetch real meta async — will update once resolved
    fetchAndDisplayMeta(url);
    resolveAndPushDuration(url);
}

/* ── Play from URL input ─────────────────────────────────── */
window.playFromInput = function() {
    const inputEl = $('ipod-url-input');
    const url = inputEl ? inputEl.value.trim() : '';
    if (!url) return;

    const finalUrl = url.includes('youtu') || url.includes('soundcloud')
        ? url
        : `https://www.youtube.com/watch?v=${url}`;

    state.activePlaylistId = null;
    state.activePlaylistIndex = null;
    playUrl(finalUrl);
};

/* ── Close / Off ─────────────────────────────────────────── */
window.closeUI = function() {
    nuiFetch('close');
};

/* ════════════════════════════════════════════════════════════
   PLAYLISTS
   ════════════════════════════════════════════════════════════ */

/* ── Play a whole playlist, queued from song 1 ──────────────
   Tapping a specific song inside an expanded playlist already sets
   activePlaylistId, which is what lets auto-advance/repeat carry on
   through the rest of it. This is the same thing but triggered
   straight from the playlist card itself — so picking a playlist
   queues the whole thing instead of requiring you to drill into it and
   tap track 1 by hand every time. */
function playPlaylistFromStart(playlistId) {
    const pl = state.playlists.find(p => p.id === playlistId);
    if (!pl || !pl.songs || !pl.songs.length) return;
    state.activePlaylistId = playlistId;
    state.activePlaylistIndex = 0;
    playUrl(pl.songs[0]);
    ipodShowNowPlaying();
}

/**
 * Get a display label for a URL from cache or fallback.
 * Returns "Title — Creator" if both are available.
 */
function getDisplayLabel(url) {
    if (!url) return '';
    const meta = _metaCache.get(url);
    if (meta) {
        if (meta.title && meta.creator) return `${meta.title} — ${meta.creator}`;
        if (meta.title) return meta.title;
    }
    return placeholderLabel(url);
}

/* ── XSS helper ─────────────────────────────────────────── */
function escHtml(str) {
    return String(str)
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;');
}

/* ════════════════════════════════════════════════════════════
   iPod wheel controls
   ════════════════════════════════════════════════════════════ */

window.ipodCenterPress = function() {
    const input = $('ipod-url-input');
    const typedUrl = input ? input.value.trim() : '';

    // Typed URL always wins.
    if (typedUrl) {
        playFromInput();
        return;
    }

    // No URL typed, and nothing loaded at all — nothing to do.
    if (!state.url) return;

    // A track is loaded but never actually playing AND not genuinely
    // paused (e.g. it never started because there was no
    // headphones/speaker connected at the time, or the personal copy
    // was destroyed after disconnecting from a speaker) — (re)start
    // that song fresh instead of toggling pause/resume against a
    // sound instance that doesn't exist. A track that IS paused has a
    // live, resumable xsound instance, so it falls through to the
    // normal toggle below and resumes from exactly where it left off.
    if (!state.playing && !state.paused) {
        playUrl(state.url);
        return;
    }

    const wasPlaying = state.playing;
    const wasPaused  = state.paused;
    const ipSub = $('ipod-song-sub');

    // Optimistic toggle …
    state.playing = !state.playing;
    state.paused  = !state.paused;
    setPlayPauseIcon(state.playing);
    setTrackMeta({ playing: state.playing });
    if (ipSub) ipSub.textContent = state.playing ? '▶ Playing' : '⏸ Paused';

    // … reconciled against the client's actual decision. It can refuse
    // to resume (no headphones/speaker), in which case we roll back
    // instead of showing "Playing" for audio nobody can hear.
    nuiFetch('pauseResume').then(async res => {
        if (!res) return;
        let payload = null;
        try { payload = await res.json(); } catch { /* not json, ignore */ }
        if (payload && payload.status === 'no_headphones') {
            state.playing = wasPlaying;
            state.paused  = wasPaused;
            setPlayPauseIcon(wasPlaying);
            setTrackMeta({ playing: wasPlaying });
            if (ipSub) ipSub.textContent = wasPlaying ? '▶ Playing' : 'Plug in headphones or connect a speaker';
        }
    });
};

/* ── Skip: next/previous song. Seeking within the current track is now
   the scrubber slider's job (see bindScrubber above) instead of a
   hold-to-fast-forward gesture on these buttons — holding used to fire
   a fresh seek every ~200ms and could visibly glitch/jump if any of
   those landed out of order, and a draggable slider is a much more
   direct way to jump to a specific part of a song anyway. ── */
window.playRelativeSong = function(direction) {
    const pool = getShufflePool();
    if (!pool.length) return;

    // Only fall back to searching by URL when we don't already have a
    // trustworthy index (fresh load, or the pool changed size under us --
    // e.g. a song was added/removed via the edit view). Once we have a
    // valid index we keep incrementing/decrementing it locally instead of
    // re-deriving it from state.url on every single skip.
    //
    // Re-deriving it every time was the actual bug: 'songStarted' can push
    // back a server-normalized copy of the URL that doesn't match the
    // playlist's stored string byte-for-byte, so pool.indexOf(state.url)
    // would silently miss and fall back to idx 0. From then on every skip
    // computed its "next" song relative to index 0 instead of wherever you
    // actually were, so forward skip just bounced between song 1 and song
    // 2 forever and song 3 (and beyond) was never reachable.
    let idx = state.activePlaylistIndex;
    if (idx === null || idx < 0 || idx >= pool.length) {
        idx = pool.indexOf(state.url);
        if (idx === -1) idx = 0;
    }

    const nextIdx = (idx + direction + pool.length) % pool.length;
    state.activePlaylistIndex = nextIdx;
    playUrl(pool[nextIdx]);
};

// Skip-back: first press restarts the current song from 0:00. A second
// press landing within a few seconds of that restart goes to the previous
// song instead, matching classic click-wheel behaviour.
let _ipodSkipBackArmedAt = null;
window.ipodSkipBack = function() {
    const REPEAT_PRESS_WINDOW = 3000; // ms

    if (_ipodSkipBackArmedAt !== null && (Date.now() - _ipodSkipBackArmedAt) < REPEAT_PRESS_WINDOW) {
        _ipodSkipBackArmedAt = null; // playUrl() (via playRelativeSong) will also clear this
        playRelativeSong(-1);
        return;
    }

    _ipodSkipBackArmedAt = Date.now();
    state.posBase   = 0;
    state.posBaseAt = Date.now();
    if (!state.scrubbing) updateScrubberUI(0, state.duration);
    nuiFetch('seekTo', { position: 0 });
};

$('ipod-skip-back') && $('ipod-skip-back').addEventListener('click', () => ipodSkipBack());
$('ipod-skip-fwd')  && $('ipod-skip-fwd').addEventListener('click', () => playRelativeSong(1));

window.ipodVolumeUp = function() {
    state.volume = Math.min(100, state.volume + 5);
    updateIpodVolBar(state.volume);
    nuiFetch('setVolume', { volume: state.volume });
};

window.ipodVolumeDown = function() {
    state.volume = Math.max(1, state.volume - 5);
    updateIpodVolBar(state.volume);
    nuiFetch('setVolume', { volume: state.volume });
};

/* ════════════════════════════════════════════════════════════
   iPod MENU screen (playlists)
   ════════════════════════════════════════════════════════════ */

window.ipodShowNowPlaying = function() {
    const np  = $('ipod-view-nowplaying');
    const pl  = $('ipod-view-playlists');
    const btn = $('ipod-menu-btn');
    if (np)  np.classList.remove('hidden');
    if (pl)  pl.classList.add('hidden');
    if (btn) btn.classList.remove('active');
};

// Show the playlists view and navigate to the list sub-view
window.ipodShowMenu = function() {
    const np  = $('ipod-view-nowplaying');
    const pl  = $('ipod-view-playlists');
    const btn = $('ipod-menu-btn');
    if (np)  np.classList.add('hidden');
    if (pl)  pl.classList.remove('hidden');
    if (btn) btn.classList.add('active');
    ipodShowPlList();
    nuiFetch('getPlaylists');
};

window.ipodToggleMenu = function() {
    const pl = $('ipod-view-playlists');
    if (pl && !pl.classList.contains('hidden')) {
        ipodShowNowPlaying();
    } else {
        ipodShowMenu();
    }
};

/* ── iPod playlist sub-view navigation ── */

function ipodSetSubview(id) {
    ['ipod-pl-subview-list', 'ipod-pl-subview-new', 'ipod-pl-subview-edit'].forEach(v => {
        const el = $(v);
        if (el) el.classList.toggle('hidden', v !== id);
    });
}

window.ipodShowPlList = function() {
    renderIpodPlaylists();
    ipodSetSubview('ipod-pl-subview-list');
};

/* ── iPod new playlist ── */
let _ipodNewSongs = [];

window.ipodShowNewPlaylist = function() {
    _ipodNewSongs = [];
    const nameIn = $('ipod-pl-name-input');
    const urlIn  = $('ipod-pl-song-input');
    if (nameIn) nameIn.value = '';
    if (urlIn)  urlIn.value  = '';
    renderIpodNewSongs();
    ipodSetSubview('ipod-pl-subview-new');
};

window.ipodAddSongToNew = function() {
    const input = $('ipod-pl-song-input');
    const url   = input ? input.value.trim() : '';
    if (!url) return;
    const finalUrl = url.includes('youtu') || url.includes('soundcloud')
        ? url : `https://www.youtube.com/watch?v=${url}`;
    _ipodNewSongs.push(finalUrl);
    if (input) input.value = '';
    renderIpodNewSongs();
    fetchMeta(finalUrl).then(() => renderIpodNewSongs());
};

window.ipodSaveNewPlaylist = function() {
    const nameIn = $('ipod-pl-name-input');
    const name   = nameIn ? nameIn.value.trim() : '';
    if (!name)            { return; }
    if (!_ipodNewSongs.length) { return; }
    nuiFetch('savePlaylist', { name, songs: _ipodNewSongs });
    _ipodNewSongs = [];
    ipodShowPlList();
};

function renderIpodNewSongs() {
    const list = $('ipod-pl-songs-new');
    if (!list) return;
    list.innerHTML = '';
    _ipodNewSongs.forEach((url, i) => {
        const thumb = thumbFromUrl(url);
        const label = getDisplayLabel(url);
        const item  = document.createElement('div');
        item.className = 'ipod-pl-song-item';
        item.innerHTML = `
            ${thumb
                ? `<img class="ipod-song-thumb" src="${escHtml(thumb)}" onerror="this.style.display='none'" />`
                : `<div class="ipod-song-thumb ipod-song-thumb-ph"></div>`}
            <span class="ipod-song-label" title="${escHtml(url)}">${escHtml(label)}</span>
            <button class="ipod-pl-song-del" data-index="${i}">✕</button>
        `;
        list.appendChild(item);
    });
}

$('ipod-pl-songs-new') && $('ipod-pl-songs-new').addEventListener('click', e => {
    const btn = e.target.closest('.ipod-pl-song-del');
    if (!btn) return;
    _ipodNewSongs.splice(parseInt(btn.dataset.index, 10), 1);
    renderIpodNewSongs();
});

/* ── iPod edit existing playlist ── */
let _ipodEditId   = null;
let _ipodEditSongs = [];

// Tap-to-arm / tap-again-to-confirm for removing a song from an
// EXISTING playlist via this edit view. Keyed by index within the edit
// view's own list.
let _ipodSongDeletePending = null;
let _ipodSongDeletePendingTimer = null;

function ipodShowEditPlaylist(id) {
    const pl = state.playlists.find(p => p.id === id);
    if (!pl) return;
    _ipodEditId    = id;
    _ipodEditSongs = [...pl.songs];
    _ipodSongDeletePending = null;
    clearTimeout(_ipodSongDeletePendingTimer);
    const title = $('ipod-pl-edit-title');
    if (title) title.textContent = pl.name;
    const urlIn = $('ipod-pl-edit-url');
    if (urlIn) urlIn.value = '';
    renderIpodEditSongs();
    ipodSetSubview('ipod-pl-subview-edit');
}

window.ipodAddSongToEdit = function() {
    const input = $('ipod-pl-edit-url');
    const url   = input ? input.value.trim() : '';
    if (!url) return;
    const finalUrl = url.includes('youtu') || url.includes('soundcloud')
        ? url : `https://www.youtube.com/watch?v=${url}`;
    if (_ipodEditSongs.includes(finalUrl)) return;
    _ipodEditSongs.push(finalUrl);
    if (input) input.value = '';
    renderIpodEditSongs();
    fetchMeta(finalUrl).then(() => renderIpodEditSongs());
    // Flush to server immediately
    _ipodFlushEdit();
};

function _ipodFlushEdit() {
    if (_ipodEditId === null) return;
    // Update local state
    const pl = state.playlists.find(p => p.id === _ipodEditId);
    if (pl) pl.songs = [..._ipodEditSongs];
    if (_ipodEditId === state.activePlaylistId) state.activePlaylistIndex = null;
    nuiFetch('updatePlaylist', { id: _ipodEditId, songs: _ipodEditSongs });
}

function renderIpodEditSongs() {
    const list = $('ipod-pl-songs-edit');
    if (!list) return;
    list.innerHTML = '';
    _ipodEditSongs.forEach((url, i) => {
        const thumb = thumbFromUrl(url);
        const label = getDisplayLabel(url);
        const armed = _ipodSongDeletePending === i;
        const item  = document.createElement('div');
        item.className = 'ipod-pl-song-item';
        item.innerHTML = `
            ${thumb
                ? `<img class="ipod-song-thumb" src="${escHtml(thumb)}" onerror="this.style.display='none'" />`
                : `<div class="ipod-song-thumb ipod-song-thumb-ph"></div>`}
            <span class="ipod-song-label" title="${escHtml(url)}">${escHtml(label)}</span>
            <button class="ipod-pl-song-del ${armed ? 'ipod-pl-song-del-armed' : ''}" data-index="${i}">${armed ? '✓' : '✕'}</button>
        `;
        list.appendChild(item);
    });
}

$('ipod-pl-songs-edit') && $('ipod-pl-songs-edit').addEventListener('click', e => {
    const btn = e.target.closest('.ipod-pl-song-del');
    if (!btn) return;
    const idx = parseInt(btn.dataset.index, 10);
    if (_ipodSongDeletePending === idx) {
        clearTimeout(_ipodSongDeletePendingTimer);
        _ipodSongDeletePending = null;
        _ipodEditSongs.splice(idx, 1);
        renderIpodEditSongs();
        _ipodFlushEdit();
    } else {
        _ipodSongDeletePending = idx;
        renderIpodEditSongs();
        clearTimeout(_ipodSongDeletePendingTimer);
        _ipodSongDeletePendingTimer = setTimeout(() => {
            _ipodSongDeletePending = null;
            renderIpodEditSongs();
        }, 3000);
    }
});

// Also allow playing a song from the edit view
$('ipod-pl-songs-edit') && $('ipod-pl-songs-edit').addEventListener('click', e => {
    if (e.target.closest('.ipod-pl-song-del')) return;
    const item = e.target.closest('.ipod-pl-song-item');
    if (!item) return;
    const idx = [...item.parentElement.children].indexOf(item);
    if (_ipodEditSongs[idx]) {
        state.activePlaylistId = _ipodEditId;
        state.activePlaylistIndex = idx;
        playUrl(_ipodEditSongs[idx]);
        ipodShowNowPlaying();
    }
});

/* ── iPod playlist list render ── */

let _ipodDeletePending = null;
let _ipodDeletePendingTimer = null;

function renderIpodPlaylists() {
    const list = $('ipod-pl-list');
    if (!list) return;
    list.innerHTML = '';

    if (!state.playlists.length) {
        list.innerHTML = '<p class="ipod-pl-empty">No playlists yet.</p>';
        return;
    }

    state.playlists.forEach(pl => {
        const card = document.createElement('div');
        card.className = 'ipod-pl-card';
        card.dataset.id = pl.id;

        const delArmed = _ipodDeletePending === pl.id;

        card.innerHTML = `
            <div class="ipod-pl-card-header">
                <button class="ipod-pl-card-play" data-action="playall" data-id="${pl.id}" title="Play whole playlist">▶</button>
                <span class="ipod-pl-card-name" data-action="edit" data-id="${pl.id}">${escHtml(pl.name)}</span>
                <span class="ipod-pl-card-count">${pl.songs.length}</span>
                <button class="ipod-pl-card-del ${delArmed ? 'ipod-pl-del-armed' : ''}" data-action="delete" data-id="${pl.id}">${delArmed ? '✓' : '🗑'}</button>
            </div>
        `;
        list.appendChild(card);
    });
}

$('ipod-pl-list') && $('ipod-pl-list').addEventListener('click', e => {
    const target = e.target.closest('[data-action]');
    if (!target) return;
    const action = target.dataset.action;
    const id = parseInt(target.dataset.id, 10);

    if (action === 'edit') {
        ipodShowEditPlaylist(id);
    } else if (action === 'playall') {
        e.stopPropagation();
        playPlaylistFromStart(id);
    } else if (action === 'delete') {
        e.stopPropagation();
        if (_ipodDeletePending === id) {
            clearTimeout(_ipodDeletePendingTimer);
            _ipodDeletePending = null;
            nuiFetch('deletePlaylist', { id });
            state.playlists = state.playlists.filter(p => p.id !== id);
            if (state.activePlaylistId === id) {
                state.activePlaylistId = null;
                state.activePlaylistIndex = null;
            }
            renderIpodPlaylists();
        } else {
            _ipodDeletePending = id;
            renderIpodPlaylists();
            clearTimeout(_ipodDeletePendingTimer);
            _ipodDeletePendingTimer = setTimeout(() => {
                _ipodDeletePending = null;
                renderIpodPlaylists();
            }, 3000);
        }
    }
});

/* ── Keyboard close (Escape) ────────────────────────────── */
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeUI();
});