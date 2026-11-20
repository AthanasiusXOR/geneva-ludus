# Wittenberg = Red team + GOAD + Microsoft Defender

Forget Geneva for now. This is the path that gives you **stuff to attack** (GOAD) from **your existing red infra**, with **Microsoft Defender left on**.

## What you get

| Piece | Where |
| --- | --- |
| GOAD (3 forests / ADCS / MSSQL / trusts) | VLAN 10 — `range-goad.yml` |
| Your attack stack (kali, C2, redirs, teamshare, ansible) | VLANs 20/30/40 |
| Microsoft **Defender Antivirus** | ON — no `disable_defender` GPO |
| Microsoft **Defender for Endpoint (cloud MDE)** | Optional — needs your M365 onboarding package |

File: **`range-goad.yml`** (replaces the old NONE/EDR matrix).

## 0) Park Geneva (free RAM)

```bash
ludus --user GENEVA power off -n all
free -h
```

## 1) Install GOAD roles (Wittenberg user)

```bash
 export LUDUS_API_KEY='WITTENBERG.…'   # or: ludus --user WITTENBERG …

# Easiest: install everything from BSL source
ludus source add ludus-source-bsl --all

# Or only what GOAD needs:
# ludus ansible collection add badsectorlabs.ludus_windows_utils
# ludus ansible role add badsectorlabs.ludus_adcs
# ludus ansible role add badsectorlabs.ludus_mssql
```

Templates you already have (`win2022`, `ubuntu-22.04`, `kali`) are enough.

## 2) Point Wittenberg at the new config and deploy

**Warning:** this **replaces** the current Wittenberg range definition. Old NONE/EDR VMs will be removed on deploy. Snapshot anything you care about first.

```bash
cd /opt/ranges/wittenberg

ludus --user WITTENBERG range config set -f range-goad.yml
ludus --user WITTENBERG range deploy
ludus --user WITTENBERG range logs -f
```

GOAD role runs take a long time (often 1–3+ hours). If a role fails, re-run:

```bash
ludus --user WITTENBERG range deploy
```

## 3) Microsoft Defender — what “on” means here

### Defender Antivirus (built into Windows)
Already handled in `range-goad.yml`: **no** `disable_defender` GPO. On the VMs:

```powershell
Get-MpComputerStatus | Select AMServiceEnabled, AntispywareEnabled, RealTimeProtectionEnabled
```

### Defender for Endpoint (MDE cloud — optional)
Ludus cannot invent your tenant. You need:

1. [Microsoft 365 Defender](https://security.microsoft.com) → Settings → Endpoints → Onboarding  
2. Download the **onboarding package** for Windows  
3. Copy to a GOAD host (internet required — leave `block_internet: false`)  
4. Run the onboarding script / Local Script as admin  

After that, devices show up in the Defender portal. Without that package, you still have **local Defender AV**, not cloud MDE.

## 4) Attack from your red infra

From Kali (`linattack1`, `kali`/`kali`):

- GOAD DCs/servers are on `10.<WITTENBERG_RANGE#>.10.10–14`
- Classic GOAD creds still apply (e.g. `sevenkingdoms.local\domainadmin` / `password`, north/essos users from GOAD docs)

WireGuard:

```bash
ludus --user WITTENBERG user wireguard > wittenberg.conf
```

## RAM reality (~60 GB host)

| Set | Approx |
| --- | --- |
| GOAD Windows (slim) | ~23 GB |
| Attack stack | ~18 GB |
| **Total** | **~41 GB** |

If deploy OOMs, power off C2/redirs temporarily during GOAD role runs, then power them back on.

## Defender vs old Wittenberg cells

| Old | New |
| --- | --- |
| NONE / EDR INT-NOINT matrix | Removed |
| Fake “EDR” labels | Real GOAD + Defender AV on |
| Separate Ollama (Geneva) | Parked / ignore for now |
