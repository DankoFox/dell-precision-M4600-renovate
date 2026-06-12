# M4600 Hardware Upgrades — Vietnam Purchase Guide

**Generated:** 2026-06-11  
**System:** Dell Precision M4600 (Enterprise-Grade Linux Home Lab Server)  

> **M4600 slot layout**: 2× half mini-PCIe (WLAN + WWAN/mSATA), 1× ExpressCard/54, 1× 2.5" SATA bay, 1× optical bay (9.5mm), 4× DDR3 SO-DIMM slots, 1× MXM 3.0 Type A GPU slot.

---

## RAM (🔴 HIGH — biggest performance gain)

| Config | Model | Est. VND | Source |
|--------|-------|----------|--------|
| 8GB stick (DDR3L-1600) | Kingston KVR16LS11/8 | ~600k-850k new | MemoryZone, Phong Vũ, VTC |
| 8GB stick (DDR3L-1600) | Samsung/Micron/Hynix used | ~180k-300k used | Chợ Tốt, Shopee, LagiHitech |
| **Best: 24GB** (2×8GB used + keep 2×4GB) | Mix Samsung/Hynix/Micron | ~400k-600k | Chợ Tốt, Shopee |
| **Max: 32GB** (4×8GB DDR3L-1600) | Kingston, Crucial or used mix | ~1.0M-1.8M | Mix sources |

- DDR3L **1.35V** mandatory — runs cooler than 1.5V, safer for 24/7 operation
- M4600 supports up to 64GB per dmidecode (4×16GB if sticks exist), 32GB confirmed (4×8GB)
- Used DDR3L is widely available and reliable — buy from sellers with warranty

**Why DDR3L 1.35V:** Laptop RAM shares cooling with CPU. Lower voltage = less heat, critical for 24/7 server. Used DDR3L abundant in Vietnam at 1/3 new price.
**Significance:** More headroom = more containers. 16GB+ lets you add Gitea, Caddy, Fail2ban, Homer without OOM risk. Currently 480MB used out of 8GB — new services push into ZRAM/swap.
**Keywords:** `RAM DDR3L 8GB 1600 laptop`, `DDR3L 1.35V 8GB`, `RAM laptop 8GB DDR3 1600`

---

## Storage (🟡 HIGH)

| Item | Model | Est. VND | Source |
|------|-------|----------|--------|
| **SSD 1TB** 2.5" SATA | Crucial BX500 (CT1000BX500SSD1) | ~1.45M-1.7M | Mai Phương, Khanh Linh PC, Tuanphong |
| **SSD 2TB** 2.5" SATA | Crucial BX500 (CT2000BX500SSD1) | ~2.8M-3.5M | Tuanphong, Khanh Linh PC |
| **SSD 1TB** 2.5" SATA | Samsung 870 EVO (best perf, costs 3x) | ~5.9M-7M | HACOM, Khanh Hân |
| **SSD 2TB** 2.5" SATA | Samsung 870 QVO (QLC, cheap per TB) | ~3.5M-4.5M | Tuanphong, Phong Vũ |
| **Optical bay caddy** | Universal 9.5mm SATA for Dell M4600 | ~80k-200k | Shopee, 4Lap, MHO |
| **Caddy UGREEN 70657** | 9.5mm aluminum, branded quality | ~130k-180k | ugreen.vn, Shopee |
| **mSATA SSD** (WWAN slot) | Lite-On 256GB used (SATA II) | ~300k-500k | Parts-People, Chợ Tốt |

- **Best bang**: BX500 1TB (~1.5M) to replace OS drive + BX500 2TB (~3M) in caddy. Total ~4.5M for 3TB SSD storage
- mSATA slot runs at SATA II (~300MB/s) — fine for swap/cache, not ideal for OS

**Why BX500 over Samsung 870 EVO:** SATA III caps at 560MB/s. For server workloads (media streaming, backups), BX500 matches 870 EVO at 1/3 cost. Samsung only worth it for sustained random writes (databases/VMs) — not your use case.
**Significance:** Replace 120GB OS drive before it fills (Docker images + logs grow fast). Add drive in caddy for backup or media library expansion. mSATA in WWAN slot gives 3-drive setup, no external enclosure.

---

### Optical Bay Caddy — Deep Dive

#### Which size? Definitely 9.5mm

M4600 uses a **9.5mm** optical drive (NOT 12.7mm found in thicker laptops). This is the standard "slim" size.

How to confirm your laptop's caddy size:
```bash
# Check optical drive model
udevadm info --query=all --name=/dev/sr0 | grep ID_MODEL
# Then google that model + thickness spec

# Or just measure: remove DVD, measure edge thickness with ruler
# 9.5mm ≈ thickness of 2 stacked credit cards
```

**Wrong size won't fit** — 12.7mm caddy is too thick, machine won't close. Always search `"9.5mm"` + `"Dell Precision M4600"`.

#### Are they all the same? Mostly — but 3 gotchas

**Yes, the SATA interface is universal.** Any 9.5mm SATA caddy physically fits the M4600 optical bay. But:

| Gotcha | Detail | Fix |
|--------|--------|-----|
| **Faceplate/bezel** | Caddy comes with a flat generic bezel. Your M4600 has a contoured bezel that matches the chassis curve | **Pop the bezel off your DVD drive** (it clips on) and snap it onto the caddy. Takes 10 seconds |
| **Mounting bracket** | The caddy has screw holes for the metal bracket at the back | **Remove the metal bracket from your DVD drive** (2 screws), attach to caddy. This is what the single bottom screw holds |
| **Drive height limit** | Caddy fits **2.5" drives up to 9.5mm tall**. Common 7mm SSDs fit fine. Some 2TB+ HDDs are 15mm — **too thick** | Stick to SSDs or slim HDDs (7mm). 2.5" HDDs up to 2TB are typically 7mm or 9.5mm |

#### Is it plug and play?

**Yes.** Steps:

1. Remove battery
2. Remove 1x bottom screw holding optical drive
3. Slide DVD drive out
4. Pop bezel off DVD drive, snap onto caddy
5. Transfer metal bracket from DVD to caddy
6. Insert 2.5" SSD/HDD into caddy (4 screws included)
7. Slide caddy into laptop, tighten 1 screw, reinstall battery
8. Boot — BIOS detects as "system device bay." Ubuntu sees it as `/dev/sdc` instantly

Total time: **5-10 minutes.** No drivers, no BIOS settings.

#### Speed: optical bay is SATA 2 (not SATA 3)

Important: the M4600 optical bay runs on **SATA 2 (3 Gbps = ~300 MB/s real-world)** — half of SATA 3 (6 Gbps). This is a hardware limitation of the chipset (Intel QM67), not the caddy.

| Interface | Theoretical | Real-world |
|-----------|-------------|------------|
| Main SATA bay | SATA 3 (6 Gbps) | ~550 MB/s |
| Optical bay | **SATA 2** (3 Gbps) | ~280 MB/s |
| mSATA slot | SATA 2 (3 Gbps) | ~280 MB/s |

**For a backup disk or media storage, SATA 2 is irrelevant.** Even a 7200RPM HDD maxes at ~160 MB/s. An SSD at 280 MB/s is still 2x faster than any HDD. You won't notice the difference for:
- restic backups (I/O is sequential read → hash → write)
- Media streaming (Navidrome/Jellyfin reads at <10 MB/s)
- Samba file transfers (Wi-Fi caps at 30-50 MB/s anyway)

Impact only if you're editing 4K video directly off the caddy drive (you're not on a Sandy Bridge iGPU).

#### What drive to put in it now?

Your use case: **dedicated backup disk** for BK-01 (restic) and/or media library expansion.

| Priority | Drive | Why | Est. VND |
|----------|-------|-----|----------|
| **🔴 Best** | **Crucial BX500 1TB** (7mm) | Cheap, reliable, SATA III. Enough for nightly restic snapshots of /mnt/media + /mnt/data | ~1.45M-1.7M |
| **🟡 Better value** | **Crucial BX500 2TB** (7mm) | Same price/TB, room to grow. Use for backups + extra media | ~2.8M-3.5M |
| **🟢 Budget** | **Samsung 870 QVO 2TB** (7mm) | QLC NAND — slower writes but fine for backup. Cheapest per TB | ~3.5M-4.5M (wait for sale) |
| **⚪ HDD option** | **WD Blue 1TB 2.5"** (7mm) | Cheapest option but 5x slower writes, more heat/vibration for 24/7 server | ~800k-1.2M |

**Don't waste money on Samsung 870 EVO for backup.** You're writing to it nightly and reading rarely. BX500 is faster than your Wi-Fi link.

**Recommendation:** Buy caddy (~100k) + Crucial BX500 1TB (~1.5M). Total ~1.6M. Format as ext4, mount at `/mnt/backup`, point restic there. True physical separation from sda — real backup, not false one.

**Keywords:** `SSD Crucial BX500 1TB 2.5`, `SSD 2TB 2.5 SATA III`, `khay ổ cứng 9.5mm Dell Precision M4600`, `caddy HDD 9.5mm SATA`, `SSD mSATA 256GB`

---

## Wi-Fi (🟡 HIGH)

| Option | Model | Est. VND | Notes |
|--------|-------|----------|-------|
| **Drop-in (no adapter)** | Intel AC 7260HMW half mini-PCIe, AC+BT4.0 | ~150k-250k Shopee | Max without adapter, WiFi 5 (867 Mbps) |
| **Best value** | Intel AX210NGW M.2 + mini-PCIe adapter | ~400k-480k + ~50k | WiFi 6E, BT 5.3, 2.4 Gbps |
| **PCIe desktop card** | Intel AX210 PCIe adapters | ~350k-690k | For PC only, not laptop |

- M4600 WLAN slot is **half mini-PCIe** — Centrino 6200 uses PCIe Half MiniCard form factor
- **Intel AX210 is M.2 NGFF** — need **mini-PCIe to M.2 Key A/E adapter** (~50k on Shopee)
- AX210 gives WiFi 6E tri-band (2.4/5/6 GHz) + Bluetooth 5.3 — massive upgrade over Centrino N-6200 (300 Mbps, no BT)
- Check BIOS whitelist: Dell M4600 is pre-whitelist era, should accept any card
- Consider Ethernet instead if running headless — wired is always better for server

**Why AX210 over AC 7260:** WiFi 6E gives 2.4Gbps vs AC's 867Mbps. 6 GHz band avoids neighbor interference on 2.4/5 GHz. Bluetooth 5.3 vs none. AX210 ~500k on Shopee — best future-proofing.
**Significance:** Without Ethernet, WiFi is your only link. N-6200 maxes 300Mbps — real bottleneck for backups, large file transfers, Docker pulls. AX210 gives 8x bandwidth headroom.
**Keywords:** `Intel AX210NGW`, `Intel AX210 card wifi`, `adapter M2 key A E mini PCIE`, `Intel AC 7260 HMW`

---

## CPU (🟡 HIGH — performance gain marginal)

| Upgrade | Specs | Est. VND | TDP | Gain vs current |
|---------|-------|----------|-----|----------------|
| **Current**: i7-2860QM | 2.5-3.6 GHz, 4C/8T, 8MB L3 | — | 45W | Baseline |
| i7-2960XM (Extreme) | 2.7-3.7 GHz, 4C/8T, 8MB L3 | ~500k-800k used | **55W** | +8% |
| i7-2920XM (Extreme) | 2.5-3.5 GHz, 4C/8T, 8MB L3 | ~300k-500k used | **55W** | Minimal |

- **M4600 uses Socket G2 (rPGA988B) — Sandy Bridge only**. Ivy Bridge (3xxx) won't POST.
- Only Extreme Edition XM CPUs (2960XM/2920XM) are upgrades over 2860QM
- 2860QM → 2960XM is **not worth it**: +100-200 MHz, but +10W heat (55W vs 45W). On Sandy Bridge with limited cooling, thermal throttling cancels gains.
- **Recommendation: Skip CPU upgrade.** Current 2860QM is already the best 45W Sandy Bridge quad. Only upgrade if you find a 2960XM for under 300k and are comfortable with higher fan noise/heat.

**Why skip:** 2860QM is within 8% of 2960XM. Extra 10W TDP (55W vs 45W) causes thermal throttling on M4600's dual-fan cooling under sustained load. Real-world gain: 0-3% for 500-800k.
**Significance:** CPU is not your bottleneck. NAS, media serving, light self-hosted apps barely touch 4C/8T. RAM and storage upgrades give 100x more impact per đồng.
**Keywords:** `CPU i7-2960XM socket G2`, `i7-2920XM rPGA988B`, (search only to confirm pricing — don't buy)

---

## GPU (🟡 MEDIUM — if you need graphics)

| Card | Memory | Est. VND | Notes |
|------|--------|----------|-------|
| Current: Quadro 1000M | 2GB DDR3, Fermi, 45W | — | No driver on Ubuntu 26.04, skip entirely |
| AMD FirePro M5100 | **2GB GDDR5**, GCN, 28nm, 50W | ~1.2M-1.5M VND / $47 eBay | **BEST UPGRADE** |
| AMD FirePro M5950 | 2GB GDDR5, older | ~900k VND Econnect | Weaker than M5100 |
| NVIDIA Quadro K1100M | 2GB GDDR5, Kepler, 45W | ~1.5M VND | OK but M5100 is faster |

- M4600 uses **MXM 3.0 Type A** slot. Quadro 1000M and AMD M5100 are MXM 3.0a
- **AMD FirePro M5100 is the sweet spot** — 640 GCN cores, GDDR5, DirectX 12, ~50W. ~3-4x faster than Quadro 1000M
- **Critical**: AMD M5100 uses different heatsink mounting than NVIDIA Quadro. May need M4800/M4700 heatsink or thermal pad mods.
- **On modern Ubuntu**: AMD FirePro drivers work via open-source `amdgpu` kernel driver (GCN supports amdgpu). NVIDIA Quadro 1000M (Fermi) dropped from NVIDIA driver in 2023.
- **GPU upgrade not needed for a headless server.** Only worth it if you plan to use the M4600 display for graphics work.
- Sources in Vietnam: [Econnect](https://econnect.com.vn) (M5100 ~1.2M), Thành Vinh, TDTECH Shop

**Why M5100 over others:** GCN architecture still supported by open-source `amdgpu` driver in 2026. GDDR5 gives 64GB/s bandwidth vs DDR3's 25.6GB/s. More shaders (640 vs 384) than K1100M.
**Significance:** No GPU upgrade needed for headless server. Only relevant if you use display for media center or local AI UI. Quadro 1000M is e-waste — no Ubuntu 26.04 driver.
**Keywords:** `AMD FirePro M5100`, `card đồ họa AMD M5100 MXM`, `VGA rời MXM 3.0`, `AMD FirePro M5950`

---

## Networking (🟡 HIGH — wired Ethernet)

| Item | Model | Est. VND | Source |
|------|-------|----------|--------|
| **Cat 6 Ethernet cable 5m** | AMP, KingSpec, generic | ~30k-60k | Any electronics shop, Shopee |
| **USB 2.5GbE adapter** | Ugreen 25051 (USB-A, RTL8156BG) | ~490k-550k | HD4K, Quang Toàn, Ugreen VN |
| **Budget USB 2.5GbE** | Generic RTL8156B USB 3.0 | ~200k-350k | Shopee, Lazada |
| **USB-C 2.5GbE** | Ugreen 25052 (USB-C, RTL8156BG) | ~550k | Ugreen VN |

- M4600 has Intel 82579LM Gigabit Ethernet but eno1 shows **NO-CARRIER** — likely cable unplugged or port issue
- Server runs on Wi-Fi (wlp3s0) only. For stable 24/7 operation, wired Ethernet is strongly preferred
- USB 2.5GbE adapter plugs into USB 3.0 port — gives stable wired connection with 2.5x faster networking than 1GbE
- **Recommendation**: Run Cat 6 cable to router + Ugreen 25051. This is the single most impactful upgrade for server reliability.

**Why Ugreen 25051 (RTL8156BG):** USB 3.0 gives 5Gbps — plenty for 2.5GbE. RTL8156BG supported in mainline Linux since kernel 5.x (26.04 on 6.x+). Plug-and-play, no driver. Generic RTL8156B also works but Ugreen has better build quality.
**Significance:** #1 upgrade. Server entirely on WiFi = packet loss, interference, variable latency. Wired = predictable backup throughput, stable Samba transfers, consistent Tailscale/SSH latency.
**Keywords:** `USB 2.5GbE adapter Ugreen 25051`, `Ugreen 25051`, `RTL8156BG USB 3.0 Ethernet`, `Adapter mạng USB 2.5Gbps`, `cáp mạng CAT6 5m`

---

## Thermal (⚪ One-time)

| Item | Model | Est. VND | Source |
|------|-------|----------|--------|
| **Best thermal paste** | Arctic MX-6 4g (7.5 W/mK) | ~300k-320k | GEARVN, Phi Long, APSHOP |
| **Budget thermal paste** | Arctic MX-4 4g (8.5 W/mK) | ~130k | Phi Long, TPassion |
- MX-6 outperforms MX-4 by ~2-3°C despite lower rated W/mK (thicker compound, better fill)
- Single 4g tube enough for CPU + GPU. Buy with MX Cleaner wipes for old paste removal
- Counterfeit MX-4 common on Shopee — verify QR code, buy from major resellers

**Why MX-6 over MX-4:** Rated 7.5 vs 8.5 W/mK on paper, but thicker viscosity fills microscopic gaps better — real-world +2-3°C improvement. Factory paste after 10+ years is dried/cracked. Single tube enough for CPU + GPU.
**Significance:** Lower temps = lower fan speed = less dust = longer component life. CPU fan is only active cooling in M4600 — if it fails, machine thermal-shuts down. Fresh paste reduces thermal strain.
**Keywords:** `keo tản nhiệt Arctic MX-6`, `Arctic MX-4 4g`, `keo tản nhiệt laptop`, `khăn lau keo tản nhiệt Arctic Cleaner`

---

## UPS (🟡 MEDIUM)

| Item | Model | Est. VND | Notes |
|------|-------|----------|-------|
| **Best value AVR** | APC BVX1200LI-MS (1200VA/720W) | ~2.2M-2.8M | AVR for voltage stabilization |
| **Budget UPS** | APC BX650LI-MS (650VA/325W) | ~1.2M-1.5M | No AVR, basic backup |
- UPS with **AVR** strongly recommended for Vietnam — power fluctuations common. BX650 has NO AVR.
- M4600 + router draws ~50-80W at idle — BVX1200 gives ~30+ minutes runtime

**Why AVR (Automatic Voltage Regulation):** Vietnam power fluctuations (brownouts/surges) common. AVR regulates voltage without switching to battery — extends battery life 2-3x vs non-AVR UPS. BX650 has no AVR, cycles battery on every fluctuation.
**Significance:** Without UPS: data corruption on power loss (spinning HDD in vg_data especially vulnerable). With BVX1200 + AVR: server stays up through brownouts, safe shutdown on extended outage.
**Keywords:** `APC BVX1200LI-MS`, `UPS APC 1200VA AVR`, `APC BX650LI-MS`, `UPS cho PC server`

---

## Mechanical & Misc

| Item | Model | Est. VND | Source |
|------|-------|----------|--------|
| **ExpressCard adapter** | ExpressCard to USB 3.0 (adds 2× USB 3 ports) | ~100k-200k | Shopee, Lazada |
| **Laptop cooling pad** | Generic 15.6" with 2 fans | ~200k-400k | Shopee, Phong Vũ |
| **Dell 130W power adapter** | Original Dell DA130PE1-00 | ~300k-500k used | Chợ Tốt, Shopee |

**Why ExpressCard adapter:** M4600 ExpressCard/54 slot is otherwise unused on headless server. Adding USB 3.0 ports via ExpressCard avoids occupying built-in ports. Good for: USB 2.5GbE adapter + extra storage.
**Significance:** Port expansion without dongles sticking out. Cooling pad extends component life in Vietnam's hot climate (30-40°C). Spare power adapter lets you keep one at desk + one at server location.
**Keywords:** `ExpressCard USB 3.0`, `thẻ mở rộng ExpressCard`, `đế tản nhiệt laptop 15.6`, `sạc Dell 130W`

---

## Upgrade Priority Matrix

| Priority | Item | Impact | Cost | Effort |
|----------|------|--------|------|--------|
| 1 | **Cat 6 cable + USB 2.5GbE adapter** | Server stability (wired > Wi-Fi) | ~500k | 5 min |
| 2 | **RAM upgrade → 16GB+** | More headroom for services | ~500k-1M | 2 min |
| 3 | **SSD upgrade** | Faster boots, quieter, cooler | ~1.5M-4.5M | 10 min |
| 4 | **Wi-Fi 6E (AX210 + adapter)** | Faster wireless if no ethernet | ~500k | 10 min |
| 5 | **Thermal repaste (MX-6)** | Lower temps, fan noise | ~300k | 30 min |
| 6 | **UPS (BVX1200)** | Clean shutdown on power loss | ~2.2M-2.8M | 5 min |
| 7 | **GPU (FirePro M5100)** | Graphics capability | ~1.2M-1.5M | 30 min |
| 8 | **CPU (2960XM)** | Marginal gains | ~500k-800k | 20 min |

---

## Buying Tips for Vietnam

- **RAM**: Buy DDR3L (1.35V) — runs cooler, works in all slots. Used DDR3L is widely available on Chợ Tốt and Shopee at 1/3 the price of new.
- **Wi-Fi card (AC 7260)**: Ensure **half-height** bracket (model ends in `HMW`). M4600 does NOT fit full-height. For **AX210**: buy mini-PCIe to M.2 Key A/E adapter separately.
- **SSD**: Crucial BX500 = best bang for buck. Samsung 870 EVO costs 4x more for minimal real-world gain on SATA III.
- **Caddy**: Search `"khay ổ cứng 9.5mm Dell Precision M4600"`. **Only 9.5mm fits** — 12.7mm won't close. Universal Dell caddy works but you MUST transfer the bezel + metal bracket from your DVD drive. Also check UGREEN 70657 (~130k) for branded quality. Caddy only accepts drives up to **9.5mm height** (most SSDs are 7mm, fine). See [Optical Bay Caddy section](#optical-bay-caddy--deep-dive) above.
- **Thermal paste**: MX-6 is better but check for fakes. Buy from GEARVN, Phi Long (Phong Vũ), or TPassion — trusted distributors.
- **UPS**: Models with **AVR** (Automatic Voltage Regulation) strongly recommended for Vietnam's fluctuating power. BVX1200 has AVR; BX650 does not.
- **GPU modding**: AMD FirePro M5100 needs heatsink mod — read forum guides before buying.
- **CPU**: Check current CPU with `cat /proc/cpuinfo` before ordering. If you have i7-2860QM, skip upgrade.

---

## Search Keywords Cheat Sheet (Shopee/Chợ Tốt/Lazada)

| Component | Vietnamese Search | English Search |
|-----------|------------------|----------------|
| **RAM DDR3L 8GB** | `RAM laptop 8GB DDR3L 1600 1.35V` | `DDR3L 8GB 1600MHz SO-DIMM` |
| **SSD Crucial BX500 1TB** | `SSD Crucial BX500 1TB 2.5` | `Crucial BX500 1TB SATA III` |
| **SSD Samsung 870 QVO 2TB** | `SSD Samsung 870 QVO 2TB 2.5` | `Samsung 870 QVO 2TB SATA` |
| **Optical bay caddy** | `khay ổ cứng 9.5mm Dell Precision M4600` | `Dell Precision M4600 9.5mm SATA HDD caddy` |
| **Caddy UGREEN** | `UGREEN 70657 khay ổ cứng 9.5mm` | `UGREEN 70657 9.5mm SATA caddy` |
| **mSATA SSD** | `SSD mSATA 256GB` | `mSATA SSD 256GB` |
| **Intel AX210** | `Intel AX210NGW card wifi` | `Intel AX210NGW WiFi 6E` |
| **Mini-PCIe to M.2 adapter** | `adapter M2 key A E mini PCIE` | `mini PCIe to M.2 Key A/E` |
| **Intel AC 7260** | `card wifi Intel AC 7260` | `Intel AC 7260 HMW half mini` |
| **USB 2.5GbE adapter** | `Adapter mạng USB 2.5 Gbps` | `USB 3.0 to 2.5GbE RTL8156BG` |
| **Cat 6 cable** | `cáp mạng CAT6 5m` | `Cat 6 Ethernet cable 5m` |
| **Arctic MX-6** | `keo tản nhiệt Arctic MX-6` | `Arctic MX-6 thermal paste` |
| **APC BVX1200 UPS** | `APC BVX1200LI UPS 1200VA` | `APC BVX1200 AVR UPS` |
| **ExpressCard USB 3.0** | `thẻ ExpressCard USB 3.0` | `ExpressCard to USB 3.0 adapter` |
| **Laptop cooling pad** | `đế tản nhiệt laptop 15.6` | `laptop cooling pad 15.6` |
| **Dell 130W adapter** | `sạc Dell 130W DA130PE1` | `Dell DA130PE1-00 130W` |
| **AMD FirePro M5100** | `card đồ họa AMD M5100 MXM` | `AMD FirePro M5100 MXM 3.0` |
| **i7-2960XM CPU** | `CPU i7-2960XM socket G2` | `i7-2960XM Extreme Edition` |
