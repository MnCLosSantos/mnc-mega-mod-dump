const panelForklift = document.getElementById('panel-forklift');
const panelStack    = document.getElementById('panel-stack');
const forkliftRows  = document.getElementById('forklift-rows');
const stackRows     = document.getElementById('stack-rows');
const modeBadge     = document.getElementById('mode-badge');

let state = {
    mode: 'idle',
    showForkliftControls: false,
    showStackControls: false,
    toggleLabel: 'E',
    forkliftAttachLabel: 'O',
    liftLabel: 'UP',
    lowerLabel: 'DOWN',
    stackLabel: 'K',
    detachLabel: 'B',
};

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

function renderForklift() {
    if (!forkliftRows) return;

    const { mode, toggleLabel, forkliftAttachLabel, liftLabel, lowerLabel } = state;

    modeBadge.className = 'panel__mode-badge';
    modeBadge.textContent = '';

    let html = '';

    if (mode === 'forks') {
        modeBadge.classList.add('active');
        modeBadge.textContent = 'Lifting';

        html += sectionLabel('Active — vehicle or prop on forks');
        html += bind(liftLabel,   'Lift',   'Raise the vehicle or prop higher, use arrow keys to finetune', 'success');
        html += bind(lowerLabel,  'Lower',  'Bring the vehicle or prop down, use arrow keys to finetune', 'success');
        html += divider();
        html += bind(toggleLabel, 'Detach', 'Release vehicle or prop from forks', 'danger');

    } else if (mode === 'liftplatform') {
        modeBadge.classList.add('platform');
        modeBadge.textContent = 'Platform';

        html += sectionLabel('Active — forklift on platform');
        html += bind(liftLabel,          'Raise',  'Lift the forklift upward', 'success');
        html += bind(lowerLabel,         'Lower',  'Bring the forklift down', 'success');
        html += divider();
        html += bind(forkliftAttachLabel, 'Detach', 'Remove forklift from platform', 'danger');

    } else {
        html += sectionLabel('Get close to a vehicle or prop if its a vehicle loaded press K when in a vehicle on top of a vehicle/trailer to attach it');
        html += bind(toggleLabel,         'Attach to forks',    'Pick up a nearby vehicle or prop');
        html += divider();
        html += bind(forkliftAttachLabel, 'Platform mode',      'Attach this forklift onto a larger vehicle or trailer');
    }

    forkliftRows.innerHTML = html;
}

function renderStack() {
    if (!stackRows) return;

    const { stackLabel, detachLabel } = state;

    let html = '';

    html += sectionLabel('Vehicle Attachment');
    html += bind(stackLabel,  'Attach',  'Attach a nearby vehicle on top of this one');
    html += divider();
    html += bind(detachLabel, 'Detach', 'Tap to detach most recent or Hold to peel off stacked levels one at a time', 'danger');

    stackRows.innerHTML = html;
}

function render() {
    panelForklift.classList.toggle('hidden', !state.showForkliftControls);
    panelStack.classList.toggle('hidden',    !state.showStackControls);

    if (state.showForkliftControls) renderForklift();
    if (state.showStackControls)    renderStack();
}

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'setVisible') {
        if (!data.visible) {
            panelForklift.classList.add('hidden');
            panelStack.classList.add('hidden');
        } else {
            render();
        }
        return;
    }

    if (data.action === 'setState') {
        state = { ...state, ...data };
        render();
    }
});

render();

fetch(`https://${window.location.hostname}/nuiReady`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({})
}).catch(() => {});