# Phase 4: Hardware Management

**Learning goals**: Kernel modules, hardware monitoring, SMM, systemd oneshot services, power management.

---

## 4.1 Dell SMM Fan Control - BIOS Bypass

**What to do**:
```bash
# Install prerequisites
sudo apt install -y git build-essential

# Clone and compile dell-bios-fan-control
git clone https://github.com/TomFreudenberg/dell-bios-fan-control.git
cd dell-bios-fan-control
make
sudo cp dell-bios-fan-control /usr/local/bin/

# Test: Disable BIOS fan control
sudo dell-bios-fan-control 0
```

**Must NOT do**:
- Don't run without monitoring (fans stay off, CPU can overheat)
- Don't add to startup scripts until i8kmon is configured

**Verification**:
- `sudo dell-bios-fan-control 0` → returns silently (no error)
- `sudo dell-bios-fan-control` → shows `Fan control disabled`
- Re-enable with `sudo dell-bios-fan-control 1`

**Evidence to Capture**:
- [ ] Compilation succeeds
- [ ] Fan control disable works

---

## 4.2 i8kmon Temperature Daemon

**What to do**:
```bash
# Install utilities
sudo apt install -y i8kutils acpi tcl

# Load kernel module at boot
echo 'dell_smm_hwmon' | sudo tee /etc/modules-load.d/dell-smm-hwmon.conf

# Configure module parameters
echo 'options dell_smm_hwmon ignore_dmi=1 restricted=1 power_status=1' | \
  sudo tee /etc/modprobe.d/dell-smm-hwmon.conf

# Load module now
sudo modprobe dell_smm_hwmon ignore_dmi=1 restricted=1

# Configure fan curve
sudo nano /etc/i8kutils/i8kmon.conf
```
**i8kmon.conf content**:
```
set config(0)  {{0 0}  -1  50  -1  50}
set config(1)  {{1 1}  42  68  42  68}
set config(2)  {{2 2}  60 128  60 128}
```
```bash
# Enable and start service
sudo systemctl enable --now i8kmon.service
```

**Learning**: Kernel modules, modprobe, hardware monitoring, Tcl config syntax

**Must NOT do**:
- Don't set fan thresholds too low (fans running constantly = noise)
- Don't set fan thresholds too high (risk of thermal throttling)

**Verification**:
- `systemctl status i8kmon.service` → active
- `sensors` shows CPU temperature being reported
- After some CPU load: fans spin up automatically
- `dmesg | grep dell_smm` shows module loaded

**Evidence to Capture**:
- [ ] sensors output showing temps
- [ ] systemctl status i8kmon

---

## 4.3 Battery Charge Thresholds

**What to do**:
```bash
# Install SMBIOS tools
sudo apt install -y smbios-utils

# Check current charging mode
sudo smbios-battery-ctl --get-charging-mode

# Set custom charging: stop at 80%, resume at 50%
sudo smbios-battery-ctl --set-charging-mode=custom
sudo smbios-battery-ctl --set-custom-charge-interval=50 80

# Verify
sudo smbios-battery-ctl --get-charging-mode
```

**Must NOT do**:
- Don't skip this step - battery swelling is a fire hazard for 24/7 server
- Don't set charging too low (battery may not function as UPS)

**Verification**:
- Command returns "custom" charging mode
- `/sys/class/power_supply/BAT0/charge_control_end_threshold` shows 80
- After testing: battery stops charging at 80%

**Evidence to Capture**:
- [ ] smbios-battery-ctl output
- [ ] Charge threshold confirmation

---

## 4.4 Wake-on-LAN Configuration

**What to do**:
```bash
# Install ethtool
sudo apt install -y ethtool

# Check current WOL status
sudo ethtool eno1 | grep Wake-on

# Enable WOL (g = magic packet)
sudo ethtool -s eno1 wol g

# Persist with systemd service
sudo nano /etc/systemd/system/wol-enable.service
```
**Service file**:
```
[Unit]
Description=Enable Wake-on-LAN on eno1
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -s eno1 wol g
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl enable --now wol-enable.service
```

**Learning**: Magic packets, NIC power states, systemd oneshot services

**Must NOT do**:
- Don't expect WOL to work if Deep Sleep is still enabled in BIOS

**Verification**:
- `sudo ethtool eno1 | grep Wake-on` shows `Wake-on: g`
- From another machine: `wakeonlan <MAC_ADDR>` → M4600 powers on
- `systemctl status wol-enable.service` → active

**Evidence to Capture**:
- [ ] ethtool WOL status
- [ ] WOL test success

---

## 4.5 Lid Management for Headless Operation

**What to do**:
Since the M4600 is a laptop being used as a server, we need to ensure it doesn't suspend when the lid is closed and the screen backlight is turned off.

```bash
# Configure systemd-logind to ignore lid close
sudo nano /etc/systemd/logind.conf
```
**Content**:
```
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```
```bash
# Restart logind to apply
sudo systemctl restart systemd-logind

# Turn off backlight after 60 seconds of inactivity (GRUB)
sudo nano /etc/default/grub
# Change GRUB_CMDLINE_LINUX_DEFAULT to include "consoleblank=60"
# e.g.: GRUB_CMDLINE_LINUX_DEFAULT="maybe-ubiquity consoleblank=60"

sudo update-grub
```

**Learning**: systemd-logind, power states (suspend, hibernate, ignore), GRUB kernel parameters.

**Must NOT do**:
- Don't set `HandleLidSwitch=suspend` (default laptop behavior).

**Verification**:
- Close the lid: server should remain pingable and SSH accessible.
- Wait 60 seconds: screen backlight should turn off.

**Evidence to Capture**:
- [ ] Server accessible with lid closed.
- [ ] consoleblank added to GRUB.

