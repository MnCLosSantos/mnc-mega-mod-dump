'use strict';

// ─────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────
let STATE = {
    data:             null,
    currencyLabel:    '$',
    ledgerFilter:     'all',
    pendingInvoiceId: null,
    pendingPayType:   'cash',  // 'cash' or 'bank'
    canSend:          false,   // can invoice other players (set by populateUI)
};

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────
function fmt(amount) {
    return STATE.currencyLabel + Number(amount).toLocaleString();
}

function fmtDate(ts) {
    if (!ts) return '—';
    const d = new Date(ts);
    return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
         + ' · ' + d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
}

function statusIcon(status) {
    return { paid: '✅', pending: '🕐', declined: '❌', expired: '⏱' }[status] || '📄';
}

function statusPill(status) {
    return `<span class="status-pill sp-${status}">${status}</span>`;
}

function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
}

function escAttr(str) {
    return String(str).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function safeJson(str) {
    try { return JSON.parse(str); } catch (_) { return null; }
}

function showError(msg) {
    const el = document.getElementById('send-error');
    el.textContent = msg;
    el.classList.remove('hidden');
    setTimeout(() => el.classList.add('hidden'), 4000);
}

// ─────────────────────────────────────────────
//  Status bar clock
// ─────────────────────────────────────────────
function tickClock() {
    const el = document.getElementById('sb-time');
    if (!el) return;
    const now = new Date();
    el.textContent = now.getHours().toString().padStart(2, '0') + ':'
                   + now.getMinutes().toString().padStart(2, '0');
}
tickClock();
setInterval(tickClock, 10000);

// ─────────────────────────────────────────────
//  Tab navigation
// ─────────────────────────────────────────────
const PAGE_TITLES = {
    send:     'New Invoice',
    inbox:    'Invoices Sent',
    receipts: 'My Receipts',
    ledger:   'Job Ledger',
};

document.getElementById('tab-bar').addEventListener('click', e => {
    const btn = e.target.closest('.tab-btn');
    if (!btn || btn.classList.contains('hidden')) return;
    switchTab(btn.dataset.tab);
});

function switchTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    const activeBtn = document.querySelector(`.tab-btn[data-tab="${tab}"]`);
    if (activeBtn) activeBtn.classList.add('active');

    document.querySelectorAll('.tab').forEach(t => {
        t.classList.remove('active');
        t.classList.add('hidden');
        t.style.display = 'none';
    });
    const panel = document.getElementById('tab-' + tab);
    if (panel) {
        panel.classList.remove('hidden');
        panel.style.display = 'block';
        panel.classList.add('active');
    }

    document.getElementById('page-title').textContent = PAGE_TITLES[tab] || 'Payments';
}

// ─────────────────────────────────────────────
//  Populate UI — called on open and every refresh
// ─────────────────────────────────────────────
function populateUI(data) {
    STATE.data     = data;
    STATE.canSend  = !!data.can_send;   // can invoice OTHER players

    const isRestricted = !data.can_send;

    document.getElementById('sb-job').textContent     = data.job_label || data.job || '—';
    document.getElementById('billing-as').textContent = isRestricted
        ? 'Personal (self-charge only)'
        : (data.job_label || data.job || '—');

    // Button state is managed by the target-select change handler (registered once at init).
    // Just re-evaluate it here on every populate.
    _updateSendBtn();

    // Ledger tab — boss only
    const ledgerBtn = document.getElementById('nav-ledger');
    data.is_boss ? ledgerBtn.classList.remove('hidden') : ledgerBtn.classList.add('hidden');

    // Inbox tab badge — invoices sent by this player that are still pending
    const pendingCount = (data.inbox_invoices || []).filter(i => i.status === 'pending').length;
    const badge = document.getElementById('badge-inbox');
    if (pendingCount > 0) {
        badge.textContent = pendingCount;
        badge.classList.remove('hidden');
    } else {
        badge.classList.add('hidden');
    }

    // Build each tab
    buildInbox(data.inbox_invoices || []);
    buildPendingBar(data.pending || []);
    buildReceipts(data.receipts || []);
    if (data.is_boss) buildLedger(data.ledger || [], STATE.ledgerFilter);
}

// ─────────────────────────────────────────────
//  INBOX — invoices this staff member has SENT (all statuses)
//  Grouped: pending at top, then history below
// ─────────────────────────────────────────────
function buildInbox(invoices) {
    const list = document.getElementById('inbox-list');

    if (!invoices.length) {
        list.innerHTML = `<div class="empty-state"><div class="empty-icon">📤</div><div class="empty-text">No invoices sent yet</div></div>`;
        return;
    }

    const pending  = invoices.filter(i => i.status === 'pending');
    const history  = invoices.filter(i => i.status !== 'pending');

    let html = '';

    if (pending.length) {
        html += `<div class="list-section-label">Awaiting Payment</div>`;
        html += pending.map(inv => invoiceCard(inv, true)).join('');
    }

    if (history.length) {
        if (pending.length) html += `<div class="list-gap"></div>`;
        html += `<div class="list-section-label">History</div>`;
        html += history.map(inv => invoiceCard(inv, false)).join('');
    }

    list.innerHTML = html;
}

// ─────────────────────────────────────────────
//  Pending bar — invoices THIS player needs to pay
//  Shown as a compact banner at the top of the Send tab
//  when there are pending invoices waiting for this player
// ─────────────────────────────────────────────
function buildPendingBar(pending) {
    let bar = document.getElementById('pending-bar');
    if (!bar) return;

    if (!pending.length) {
        bar.style.display = 'none';
        return;
    }

    bar.style.display = 'block';
    bar.innerHTML = `
        <div class="pbar-label">📬 You have ${pending.length} unpaid invoice${pending.length > 1 ? 's' : ''}</div>
        ${pending.map(inv => `
            <div class="pbar-row" data-id="${inv.id}">
              <div class="pbar-info">
                <span class="pbar-from">${escHtml(inv.from_name)}</span>
                <span class="pbar-reason">${escHtml(inv.reason)}</span>
              </div>
              <div class="pbar-right">
                <span class="pbar-amount">${fmt(inv.amount)}</span>
                <button class="btn-decline" data-action="decline" data-id="${inv.id}">✕</button>
                <button class="btn-pay" data-action="pay" data-id="${inv.id}">Pay</button>
              </div>
            </div>
        `).join('')}
    `;
}

// ─────────────────────────────────────────────
//  RECEIPTS — invoices this player has PAID (they were billed)
// ─────────────────────────────────────────────
function buildReceipts(receipts) {
    const list = document.getElementById('receipts-list');

    if (!receipts.length) {
        list.innerHTML = `<div class="empty-state"><div class="empty-icon">🧾</div><div class="empty-text">No receipts yet</div></div>`;
        return;
    }

    list.innerHTML = receipts.map(inv => `
        <div class="inv-card s-paid receipt-tap" data-inv='${escAttr(JSON.stringify(inv))}'>
          <div class="inv-icon s-paid">✅</div>
          <div class="inv-body">
            <div class="inv-from">${escHtml(inv.from_name)}</div>
            <div class="inv-sub">${escHtml(inv.from_job_label)} · ${escHtml(inv.reason)}</div>
            <div class="inv-date">Paid · ${fmtDate(inv.paid_at)}</div>
          </div>
          <div class="inv-right">
            <div class="inv-amount">${fmt(inv.amount)}</div>
            ${statusPill('paid')}
          </div>
        </div>
    `).join('');
}

// ─────────────────────────────────────────────
//  LEDGER — every invoice from this job (boss/owner)
//  Shows: sender → recipient, amount, status
// ─────────────────────────────────────────────
function buildLedger(ledger, filter) {
    const list = document.getElementById('ledger-list');
    const rows = filter === 'all' ? ledger : ledger.filter(i => i.status === filter);

    if (!rows.length) {
        list.innerHTML = `<div class="empty-state"><div class="empty-icon">📊</div><div class="empty-text">No entries</div></div>`;
        return;
    }

    list.innerHTML = rows.map(inv => {
        const isSelf = inv.from_citizenid === inv.to_citizenid;
        const arrow  = isSelf
            ? `<span class="ledger-self-tag">self</span>`
            : `<span class="ledger-arrow">→</span> <span class="ledger-to">${escHtml(inv.to_name)}</span>`;
        return `
        <div class="inv-card s-${inv.status} receipt-tap" data-inv='${escAttr(JSON.stringify(inv))}'>
          <div class="inv-icon s-${inv.status}">${statusIcon(inv.status)}</div>
          <div class="inv-body">
            <div class="inv-from ledger-line">${escHtml(inv.from_name)} ${arrow}</div>
            <div class="inv-sub">${escHtml(inv.reason)}</div>
            <div class="inv-date">${fmtDate(inv.created_at)}</div>
          </div>
          <div class="inv-right">
            <div class="inv-amount">${fmt(inv.amount)}</div>
            ${statusPill(inv.status)}
          </div>
        </div>
        `;
    }).join('');
}

// ─────────────────────────────────────────────
//  Shared invoice card builder (inbox rows)
// ─────────────────────────────────────────────
function invoiceCard(inv, showActions) {
    const isSelf = inv.from_citizenid === inv.to_citizenid;
    const toLabel = isSelf ? '(self)' : escHtml(inv.to_name);
    const dateLabel = inv.status === 'paid'
        ? 'Paid · ' + fmtDate(inv.paid_at)
        : fmtDate(inv.created_at);

    if (showActions) {
        // Pending — sender view, no pay/decline (they sent it, waiting on target)
        return `
        <div class="inv-card s-pending">
          <div class="inv-icon s-pending">🕐</div>
          <div class="inv-body">
            <div class="inv-from">→ ${toLabel}</div>
            <div class="inv-sub">${escHtml(inv.reason)}</div>
            <div class="inv-date">Sent · ${fmtDate(inv.created_at)}</div>
          </div>
          <div class="inv-right">
            <div class="inv-amount">${fmt(inv.amount)}</div>
            ${statusPill('pending')}
          </div>
        </div>`;
    }

    return `
    <div class="inv-card s-${inv.status} receipt-tap" data-inv='${escAttr(JSON.stringify(inv))}'>
      <div class="inv-icon s-${inv.status}">${statusIcon(inv.status)}</div>
      <div class="inv-body">
        <div class="inv-from">→ ${toLabel}</div>
        <div class="inv-sub">${escHtml(inv.reason)}</div>
        <div class="inv-date">${dateLabel}</div>
      </div>
      <div class="inv-right">
        <div class="inv-amount">${fmt(inv.amount)}</div>
        ${statusPill(inv.status)}
      </div>
    </div>`;
}

// ─────────────────────────────────────────────
//  Ledger filter segment
// ─────────────────────────────────────────────
document.getElementById('ledger-segment').addEventListener('click', e => {
    const btn = e.target.closest('.seg-btn');
    if (!btn) return;
    document.querySelectorAll('#ledger-segment .seg-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    STATE.ledgerFilter = btn.dataset.filter;
    if (STATE.data) buildLedger(STATE.data.ledger || [], STATE.ledgerFilter);
});

// ─────────────────────────────────────────────
//  Send button state helper
//  Unemployed players can only use __self__; the button is disabled for other targets.
// ─────────────────────────────────────────────
function _updateSendBtn() {
    const v    = document.getElementById('target-select').value;
    const btn  = document.getElementById('send-btn');
    if (!STATE.canSend && v !== '__self__' && v !== '') {
        btn.disabled = true;
    } else {
        btn.disabled = false;
    }
}

// ─────────────────────────────────────────────
//  Nearby players — populate dropdown
// ─────────────────────────────────────────────
function loadNearby() {
    fetchNUI('getNearby', {}).then(nearby => {
        const sel     = document.getElementById('target-select');
        const wasSelf = sel.value === '__self__';

        sel.innerHTML = '<option value="">Choose recipient…</option><option value="__self__">💳 Charge Myself</option>';

        if (nearby && nearby.length) {
            nearby.forEach(p => {
                const opt = document.createElement('option');
                opt.value       = p.citizenid;
                opt.textContent = p.name + ' [' + p.id + ']';
                sel.appendChild(opt);
            });
        } else {
            const opt = document.createElement('option');
            opt.disabled    = true;
            opt.textContent = '— No players nearby —';
            sel.appendChild(opt);
        }

        if (wasSelf) sel.value = '__self__';
    });
}
document.getElementById('refresh-nearby').addEventListener('click', loadNearby);

// ─────────────────────────────────────────────
//  Pay-type segment listeners
// ─────────────────────────────────────────────
document.getElementById('pay-type-seg').addEventListener('click', e => {
    const btn = e.target.closest('.seg-btn');
    if (!btn) return;
    document.querySelectorAll('#pay-type-seg .seg-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    STATE.pendingPayType = btn.dataset.pt;
});

document.getElementById('self-pay-type-seg').addEventListener('click', e => {
    const btn = e.target.closest('.seg-btn');
    if (!btn) return;
    document.querySelectorAll('#self-pay-type-seg .seg-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    // Selection read at send time from DOM
});

// Show/hide self-pay-type-seg only when __self__ is chosen
document.getElementById('target-select').addEventListener('change', () => {
    _updateSendBtn();
    const v = document.getElementById('target-select').value;
    const selfPayRow = document.getElementById('self-pay-type-row');
    if (selfPayRow) selfPayRow.style.display = (v === '__self__') ? '' : 'none';
    if (!STATE.canSend) {
        if (v !== '__self__' && v !== '') {
            showError('Your job cannot invoice other players — select "Charge Myself".');
        } else {
            document.getElementById('send-error').classList.add('hidden');
        }
    }
});

// ─────────────────────────────────────────────
//  Send invoice
// ─────────────────────────────────────────────
document.getElementById('send-btn').addEventListener('click', () => {
    const amount = parseInt(document.getElementById('amount-input').value);
    const reason = document.getElementById('reason-input').value.trim();
    const toCid  = document.getElementById('target-select').value;
    const isSelf = toCid === '__self__';

    if (isNaN(amount) || amount < 1) { showError('Enter a valid amount.'); return; }
    if (!reason)                      { showError('A reason is required.'); return; }
    if (!toCid)                       { showError('Select a recipient.'); return; }

    // For self-charge, read the pay-type toggle on the send tab
    const selfPayType = isSelf
        ? (document.querySelector('#self-pay-type-seg .seg-btn.active')?.dataset.pt || 'cash')
        : null;

    fetchNUI('sendInvoice', {
        amount,
        reason,
        self_charge:  isSelf,
        to_citizenid: isSelf ? null : toCid,
        payment_type: selfPayType,
    });

    document.getElementById('amount-input').value = '';
    document.getElementById('reason-input').value = '';
    document.getElementById('target-select').value = '';
});

// ─────────────────────────────────────────────
//  Pay / Decline invoice (from pending-bar on send tab OR inbox)
// ─────────────────────────────────────────────
document.addEventListener('click', e => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const id     = parseInt(btn.dataset.id);
    const action = btn.dataset.action;
    if (!id) return;

    if (action === 'pay') {
        const inv = (STATE.data?.pending || []).find(i => i.id == id);
        if (inv) showConfirmSheet(inv);
    } else if (action === 'decline') {
        fetchNUI('respondInvoice', { id, accept: false });
    }
});

// ─────────────────────────────────────────────
//  Receipt sheet — tap any paid/history card
// ─────────────────────────────────────────────
document.addEventListener('click', e => {
    const card = e.target.closest('.receipt-tap');
    if (!card || e.target.closest('button')) return;
    const raw = card.getAttribute('data-inv');
    if (!raw) return;
    const inv = safeJson(raw);
    if (inv) showReceiptSheet(inv);
});

function showReceiptSheet(inv) {
    document.getElementById('receipt-amount-big').textContent = fmt(inv.amount);
    document.getElementById('receipt-status-row').innerHTML   = statusPill(inv.status);

    const isSelf = inv.from_citizenid === inv.to_citizenid;
    const rows = [
        ['Invoice',    '#' + inv.id],
        ['Billed by',  inv.from_name],
        ['Business',   inv.from_job_label],
        ['Charged to', isSelf ? inv.to_name + ' (self)' : inv.to_name],
        ['Reason',     inv.reason],
        inv.payment_type ? ['Paid via', inv.payment_type === 'bank' ? '🏦 Bank Transfer' : '💵 Cash'] : null,
        ['Date',       fmtDate(inv.paid_at || inv.created_at)],
    ].filter(Boolean);

    document.getElementById('receipt-rows').innerHTML = rows.map(([label, val]) => `
        <div class="ios-cell">
          <span class="cell-label">${escHtml(label)}</span>
          <span class="cell-value" style="color:var(--lbl-2)">${escHtml(String(val))}</span>
        </div>
        <div class="ios-cell-divider"></div>
    `).join('').replace(/<div class="ios-cell-divider"><\/div>\s*$/, '');

    document.getElementById('receipt-modal').classList.remove('hidden');
}

document.getElementById('receipt-close').addEventListener('click', () => {
    document.getElementById('receipt-modal').classList.add('hidden');
});

// ─────────────────────────────────────────────
//  Confirm payment sheet
// ─────────────────────────────────────────────
function showConfirmSheet(inv) {
    STATE.pendingInvoiceId = inv.id;
    STATE.pendingPayType   = 'cash';
    document.getElementById('confirm-amount').textContent = fmt(inv.amount);
    document.getElementById('confirm-meta').innerHTML =
        `From <strong>${escHtml(inv.from_name)}</strong> (${escHtml(inv.from_job_label)})<br>${escHtml(inv.reason)}`;

    // Reset pay-type toggle to cash
    document.querySelectorAll('#pay-type-seg .seg-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.pt === 'cash');
    });

    document.getElementById('confirm-modal').classList.remove('hidden');
}

document.getElementById('confirm-pay').addEventListener('click', () => {
    if (!STATE.pendingInvoiceId) return;
    document.getElementById('confirm-modal').classList.add('hidden');
    fetchNUI('respondInvoice', { id: STATE.pendingInvoiceId, accept: true, payment_type: STATE.pendingPayType });
    STATE.pendingInvoiceId = null;
});

document.getElementById('confirm-decline').addEventListener('click', () => {
    if (!STATE.pendingInvoiceId) return;
    document.getElementById('confirm-modal').classList.add('hidden');
    fetchNUI('respondInvoice', { id: STATE.pendingInvoiceId, accept: false });
    STATE.pendingInvoiceId = null;
});

document.getElementById('receipt-modal').addEventListener('click', e => {
    if (e.target === e.currentTarget) e.currentTarget.classList.add('hidden');
});
document.getElementById('confirm-modal').addEventListener('click', e => {
    if (e.target === e.currentTarget) e.currentTarget.classList.add('hidden');
});

// ─────────────────────────────────────────────
//  Close + ESC
// ─────────────────────────────────────────────
document.getElementById('close-btn').addEventListener('click', () => fetchNUI('close', {}));

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        if (!document.getElementById('receipt-modal').classList.contains('hidden')) {
            document.getElementById('receipt-modal').classList.add('hidden'); return;
        }
        if (!document.getElementById('confirm-modal').classList.contains('hidden')) {
            document.getElementById('confirm-modal').classList.add('hidden'); return;
        }
        fetchNUI('close', {});
    }
});

// ─────────────────────────────────────────────
//  NUI message handler
// ─────────────────────────────────────────────
window.addEventListener('message', e => {
    const { action, data } = e.data;

    if (action === 'open') {
        if (data.currency_label) STATE.currencyLabel = data.currency_label;
        document.getElementById('app').classList.remove('hidden');
        populateUI(data);
        switchTab('send');
        loadNearby();
    }
    if (action === 'close') {
        document.getElementById('app').classList.add('hidden');
    }
    if (action === 'refresh') {
        if (data.currency_label) STATE.currencyLabel = data.currency_label;
        populateUI(data);
    }
});

// ─────────────────────────────────────────────
//  NUI fetch
// ─────────────────────────────────────────────
function fetchNUI(endpoint, data) {
    return fetch('https://mnc-payments/' + endpoint, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data),
    }).then(r => r.json()).catch(() => ({}));
}