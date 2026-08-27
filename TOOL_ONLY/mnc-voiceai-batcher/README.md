# 🎙️ MNC Voice AI Batcher

[![Standalone](https://img.shields.io/badge/Type-Standalone%20HTML-green.svg)]()
[![API](https://img.shields.io/badge/API-FineVoice-blue.svg)](https://api.finevoice.ai/)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
MNC Voice AI Batcher is a single self-contained HTML page that turns a script into a batch of ready-to-use audio files through the [FineVoice API](https://api.finevoice.ai/). Paste in an API key, pick a voice, drop up to 25 numbered lines or paragraphs into the numbered text boxes, and generate up to 25 separate `.mp3` files in one pass — each playable, individually downloadable, or grab everything at once as a `.zip`. There's no server, no framework, and nothing to install; it's a plain HTML/JS file that talks directly to FineVoice from the browser.

---

## ✨ Key Features

**API Key Handling**
- Paste and save a FineVoice API key, stored only in the browser's local storage and sent only to FineVoice's own API — never anywhere else
- Built-in warning that client-side keys are readable by anyone with access to the page/source, so the file shouldn't be published anywhere public with a key saved in it

**Voice Selection**
- Type an exact voice name/ID manually, or click **🎭 Browse voices** to open a searchable modal that pulls FineVoice's full voice library with pictures, names, and metadata
- Client-side search matching so voices aren't hidden by quirks in FineVoice's own `keyword` search parameter
- **🔊 Test** any voice (from the top bar or from a voice card) to generate and play a short sample before committing to it

**Batch Script Input**
- Up to 25 numbered text boxes, each becoming one separate output audio file — a box can hold a full paragraph, not just a single line
- **+ Add text box** / **Remove** to grow or shrink the batch; empty boxes are skipped automatically
- Emotion tag dropdown (`[happy]`, `[whispering]`, `[shouting]`, etc.) with **Insert at cursor**, targeting whichever box was last focused

**Output Filenames**
- Configurable filename **Prefix**, **Start number**, and **Zero-pad** style (`1, 2, 3…` or `01, 02…`)
- Adjustable **Concurrent requests** (1–5) to trade off speed against how hard the API gets hit at once

**Generation & Delivery**
- Live per-file status (`queued` → `submitting` → `processing` → `downloading` → `done`/`failed`) for every row
- Inline audio player and direct download link per finished file
- **Download all as ZIP** (via JSZip) to grab every successfully generated file in one archive
- Resilient status/URL parsing that tolerates FineVoice's inconsistent field names and task-status values instead of failing on the first mismatch

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| Modern web browser (Chrome/Edge/Firefox) | Yes |
| FineVoice API key | Yes |
| Internet access (reaches `apis.finevoice.ai` directly) | Yes |
| FiveM / QBCore / any server framework | No |

---

## 🚀 Installation

```bash
# No install needed — it's just one file
mncvoiceaibatcher.html
```

Save the file anywhere and open it directly in a browser (double-click it, or right-click → **Open with** → your browser). There's no resources folder, no `ensure` line, and nothing to build — JSZip is pulled automatically from a CDN the first time the page loads.

---

## ⚙️ Configuration Guide

Everything is configured in the page itself rather than a config file:

```text
Step 1 — API Key      : pasted + saved, kept only in this browser's local storage
Step 2 — Voice         : typed manually, or picked via the 🎭 Browse voices modal
Step 3 — Text boxes    : up to 25, one per output file (defaults to 3 empty boxes)
Step 4 — Prefix         : default "line"
Step 4 — Start number   : default 1
Step 4 — Zero-pad       : default off (1, 2, 3…)
Step 4 — Concurrency    : default 3 simultaneous requests
```

Because the key lives entirely client-side, it's saved only in that browser's local storage and is never sent anywhere except directly to FineVoice — keep that in mind if sharing the file or the machine it's used on.

---

## 🎮 How to Use

1. **Add your API key.** Paste your FineVoice API key into the Step 1 field and click **Save key**. Get a key from [finevoice.ai/usercenter](https://finevoice.ai/usercenter) → API Tokens.
2. **Pick a voice.** Either type the exact voice name/ID into the Step 2 field, or click **🎭 Browse voices** to search FineVoice's library with pictures, hit **🔊 Test** on any card to preview it, and click **Use this** to select it.
3. **Write the script.** In Step 3, fill in the numbered boxes — each one becomes its own audio file and can hold a full paragraph. Use **+ Add text box** for more (up to 25), and optionally click into a box, choose a tag from the emotion dropdown, and click **Insert at cursor** to tag its tone.
4. **Set the output naming.** In Step 4, set the filename **Prefix**, **Start number**, **Zero-pad** style, and how many **Concurrent requests** to run.
5. **Generate.** Click **Generate audio files** and watch each row's status update live as it's submitted, processed, and downloaded.
6. **Grab the results.** Play finished files inline, download them one at a time, or click **Download all as ZIP** once generation finishes to get everything in a single archive.

---

## 🔧 Troubleshooting

- **Test/preview generates but you hear nothing** — browsers block audio that isn't auto-played by a direct, immediate click, and generating a preview involves a short API wait. The player still appears above the **Test voice** button; press its own ▶ once the status line says "ready".
- **Requests fail immediately with a network/CORS error** — FineVoice's API may not allow direct browser (cross-origin) calls. The fix is a small local proxy that forwards requests to `apis.finevoice.ai` and adds the key server-side, then pointing this tool at the proxy instead.
- **401 error** — double-check the API key was pasted correctly and saved.
- **422 error** — the voice name/ID is probably wrong; use **🎭 Browse voices** to confirm the exact API name.
- **"Unexpected task status" error** — FineVoice's status field doesn't always match its own docs. `"completed"`, `"success"`, `"succeeded"`, `"done"`, and `"finished"` are all already treated as success; if it still happens, the error message includes the raw response so the exact status value can be identified.
- **A file times out** — very long lines can take longer than the ~3 minute polling window; try shorter lines.

---

## 📝 Credits & License

**Author**: Stan Leigh
**Version**: 1.0.0
**Framework**: Standalone (no framework required)

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
