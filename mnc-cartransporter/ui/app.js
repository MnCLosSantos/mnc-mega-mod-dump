const panel = document.getElementById('panel');
const rows = document.getElementById('rows');
const levelBadge = document.getElementById('level-badge');
const attachModal = document.getElementById('attach-modal');
const modalLevel = document.getElementById('modal-level');
const modalConfirmBtn = document.getElementById('modal-confirm');
const modalMoveUpBtn = document.getElementById('modal-moveup');
const modalCancelBtn = document.getElementById('modal-cancel');
const unloadModal = document.getElementById('unload-modal');
const unloadModalLevel = document.getElementById('unload-modal-level');
const unloadModalConfirmBtn = document.getElementById('unload-modal-confirm');
const unloadModalCancelBtn = document.getElementById('unload-modal-cancel');
const liftHud = document.getElementById('lift-hud');
const liftFill = document.getElementById('lift-hud-fill');
const liftLabel = document.getElementById('lift-hud-label');
const liftTrack = document.getElementById('lift-hud-track');
const liftHint = document.getElementById('lift-hud-hint');

let state = {
    nearTrailer: false,
    loadLabel: 'E',
    unloadLabel: 'B',
    toggleUiLabel: 'H',
    maxPerLevel: 3,
    numLevels: 2,
    isTowing: false,
};

function getResourceName() {
    return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'mnc-cartransporter';
}

function postNUI(endpoint, data) {
    fetch(`https://${getResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).catch(() => {});
}

function bind(key, label, desc, variant) {
    return `
        <div class="bind${variant ? ' bind--' + variant : ''}">
            <div class="bind__key">${key}</div>
            <div class="bind__info">
                <div class="bind__label">${label}</div>
                ${desc ? `<div class="bind__desc">${desc}</div>` : ''}
            </div>
        </div>
    `;
}

function divider() {
    return '<div class="divider"></div>';
}

function sectionLabel(text) {
    return `<div class="section-label">${text}</div>`;
}

function render() {
    if (!state.nearTrailer) {
        panel.classList.add('hidden');
        return;
    }

    panel.classList.remove('hidden');

    let html = '';
    html += sectionLabel('Car Transporter');


    if (state.isTowing) {
        html += bind(state.loadLabel, 'Load Vehicle', 'Not available while towing the trailer', 'disabled');
    } else {
        html += bind(state.loadLabel, 'Load Vehicle', 'Attach to the bottom level, then confirm or lift it up');
    }


    if (state.isTowing) {
        html += bind(state.unloadLabel, 'Unload', 'Press to unload the next vehicle', 'danger');
    }

    html += divider();
    html += bind(state.toggleUiLabel, 'Hide UI', 'Toggle this panel');

    html += divider();
    html += sectionLabel(`Slots: ${state.maxPerLevel} per level · ${state.numLevels} levels`);

    rows.innerHTML = html;
}

function showAttachModal(data) {
    modalLevel.textContent = data.level || 1;
    modalMoveUpBtn.classList.toggle('hidden', !data.canMoveUp);
    attachModal.classList.remove('hidden');
}

function hideAttachModal() {
    attachModal.classList.add('hidden');
}

function showUnloadModal(data) {
    unloadModalLevel.textContent = data.level || 2;
    unloadModal.classList.remove('hidden');
}

function hideUnloadModal() {
    unloadModal.classList.add('hidden');
}

function setLiftMode(data) {
    if (!data.active) {
        liftHud.classList.add('hidden');
        return;
    }
    liftHud.classList.remove('hidden');

    if (data.stage === 'positioning') {
        liftLabel.textContent = 'Positioning on Level 2';
        liftTrack.classList.add('hidden');
        liftHint.innerHTML = `Drive into place, then press <b>${state.loadLabel}</b> to secure it &middot; <b>BACKSPACE</b> to cancel`;
        return;
    }

    if (data.stage === 'lowering') {
        liftLabel.textContent = 'Lowering to Level 1';
        liftTrack.classList.remove('hidden');
        liftHint.innerHTML = 'Hold <b>ARROW DOWN</b> to lower &middot; <b>ARROW UP</b> to raise back &middot; press <b>ENTER</b> once it\'s at the height you want &middot; <b>BACKSPACE</b> to cancel';
        const pct = Math.max(0, Math.min(1, data.progress || 0)) * 100;
        liftFill.style.width = `${pct}%`;
        return;
    }

    liftLabel.textContent = 'Lifting to Level 2';
    liftTrack.classList.remove('hidden');
    liftHint.innerHTML = 'Hold <b>ARROW UP</b> to raise &middot; <b>ARROW DOWN</b> to lower &middot; <b>BACKSPACE</b> to cancel';
    const pct = Math.max(0, Math.min(1, data.progress || 0)) * 100;
    liftFill.style.width = `${pct}%`;
}

modalConfirmBtn.addEventListener('click', () => postNUI('attachModalChoice', { choice: 'confirm' }));
modalMoveUpBtn.addEventListener('click', () => postNUI('attachModalChoice', { choice: 'moveUp' }));
modalCancelBtn.addEventListener('click', () => postNUI('attachModalChoice', { choice: 'cancel' }));

unloadModalConfirmBtn.addEventListener('click', () => postNUI('unloadModalChoice', { choice: 'unload' }));
unloadModalCancelBtn.addEventListener('click', () => postNUI('unloadModalChoice', { choice: 'cancel' }));

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'setVisible') {
        if (data.visible) {
            render();
        } else {
            panel.classList.add('hidden');
        }
        return;
    }

    if (data.action === 'setState') {
        state = { ...state, ...data };
        render();
        return;
    }

    if (data.action === 'showAttachModal') {
        showAttachModal(data);
        return;
    }

    if (data.action === 'hideAttachModal') {
        hideAttachModal();
        return;
    }

    if (data.action === 'showUnloadModal') {
        showUnloadModal(data);
        return;
    }

    if (data.action === 'hideUnloadModal') {
        hideUnloadModal();
        return;
    }

    if (data.action === 'setLiftMode') {
        setLiftMode(data);
        return;
    }
});

render();