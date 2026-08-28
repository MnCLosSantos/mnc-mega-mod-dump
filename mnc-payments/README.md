# 🧾 MNC Payments

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A job-based invoicing system: any qualifying job member can send a nearby player a payment request for a set amount and reason, the target gets a pop-up to pay or decline, and unanswered invoices auto-expire. Job bosses get a **ledger tab** showing every invoice their job has ever sent, whether it was paid, declined, or expired.

---

## ✨ Key Features

### 💳 Send & Receive Invoices
- Open with `/payments` (default keybind **F10**), or by using the configurable `billingtablet` item
- Sending requires the target player to be within `Config.InvoiceRange` (default 10m)
- The target receives a pop-up with the amount, reason, and sender's name/job to **pay** or **decline**
- Unanswered invoices automatically expire after `Config.InvoiceTimeout` seconds (default 120)

### 🏢 Job-Based Sending Permissions
- `Config.AutoDetect = true` lets **every** QBCore job send invoices with no per-job setup
- Set it to `false` and list only the specific jobs (with per-job `grade` and `boss_grade` overrides) that are allowed to invoice
- `Config.BlockedJobs` is a hard blocklist that always applies, even with AutoDetect on (ships with `unemployed` and `offduty` blocked)

### 📊 Job Ledger (Boss View)
- Any player at or above their job's `boss_grade` (or `Config.DefaultBossGrade` under AutoDetect) sees a **Ledger** tab listing every invoice ever sent by their job — sender, target, amount, reason, and status
- Gives bosses full visibility into what their staff are billing customers, without needing external logging

### 🔒 Amount & Range Guardrails
- `Config.MinAmount` / `Config.MaxAmount` bound what any invoice can request
- Server-side distance re-validation on send and on payment — an invoice can't be paid if the target has since walked out of range at the critical moment

### 🔔 Notifications
- `Config.NotifyOnReceive` pops a notification the instant an invoice arrives, in addition to the in-menu badge

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-payments/
```

### 2️⃣ Database Setup

Import `sql/mnc_payments.sql` — it creates the single `mnc_invoices` table (tracks sender, recipient, amount, reason, status, and timestamps for every invoice).

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-payments
```

### 4️⃣ Add the Item (Optional)

If you want `Config.Item` usable, add `billingtablet` to your `qb-core/shared/items.lua`. Set `Config.Item = nil` to disable item-based access entirely and rely on the command/keybind only.

### 5️⃣ Configure Settings

Edit `config.lua` to set which jobs can invoice, amount limits, invoice range/timeout, and the open command/keybind.

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.AutoDetect = true          -- true = every QBCore job can invoice

Config.Jobs = {
    -- ['police']    = { grade = 0, boss_grade = 3 },
    -- ['mechanic']  = { grade = 0, boss_grade = 2 },
}

Config.BlockedJobs = { 'unemployed', 'offduty' }

Config.DefaultBossGrade = 3       -- boss grade used under AutoDetect with no override

Config.MaxAmount = 1000000
Config.MinAmount = 1

Config.InvoiceRange = 10.0        -- metres the target must be within to receive/pay
Config.InvoiceTimeout = 120       -- seconds before an unanswered invoice expires

Config.CurrencyLabel = '$'
Config.NotifyOnReceive = true

Config.Command = 'payments'
Config.Keybind = 'F10'
Config.Item = 'billingtablet'     -- set to nil to disable item-based access
```

- To restrict invoicing to specific jobs, set `Config.AutoDetect = false` and populate `Config.Jobs` with only those jobs
- `boss_grade` (per job) or `Config.DefaultBossGrade` (AutoDetect fallback) controls who sees the Ledger tab

---

## 🎮 Controls & Usage

| Input | Description |
|---|---|
| `/payments` | Opens the payment menu (send invoice / view your sent & received invoices / ledger if boss) |
| **F10** (default, rebindable) | Same as the command |
| Use **Billing Tablet** item (if enabled) | Opens the same menu |

**Sending an invoice:**
1. Stand within `Config.InvoiceRange` of the target player
2. Open the menu, select "Send Invoice", pick the target, enter an amount and reason
3. The target has `Config.InvoiceTimeout` seconds to pay or decline before it auto-expires

---

## 🔧 Troubleshooting

**"You don't have permission to send invoices":**
- Check `Config.AutoDetect`, `Config.Jobs`, and `Config.BlockedJobs` — your job/grade must clear all three

**Invoice fails right as the target tries to pay:**
- The range check re-validates on payment — if the target moved more than `Config.InvoiceRange` away since the invoice was sent, payment is rejected

**Ledger tab is missing:**
- Your grade must meet or exceed your job's `boss_grade` (or `Config.DefaultBossGrade` under AutoDetect)

**Item doesn't open the menu:**
- Confirm `Config.Item` matches the item name registered in `qb-core/shared/items.lua`, and that the item is marked useable

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.0.0
**Framework**: QBCore
**Collection**: part of the [MNC Mega Mod Dump](https://github.com/MnCLosSantos/mnc-mega-mod-dump)

This resource is licensed under **MNC_LICENSE_NDFTEAU** (*No Distribution, Free To Edit And Use*) — see the [MNC_LICENSE_NDFTEAU license](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md) for the full text.

- ✅ Use and edit this resource freely on your own personal or paid server(s)
- ✅ Modify the code however you need to fit your server
- ❌ Do not redistribute, resell, or re-upload this resource (modified or not) as your own work
- ❌ Do not publish forks or copies of this resource outside of channels authorized by MnCLosSantos / carrot

---

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration Guide and Troubleshooting sections first — most questions are answered above

---

## ⚠️ Important Notes

1. **Database**: Requires oxmysql — import `sql/mnc_payments.sql` before first start
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Bill it, send it, get paid. 🧾**
