#!/usr/bin/env bash
set -euo pipefail

echo "===> Setting timezone to America/Chicago"
sudo timedatectl set-timezone America/Chicago

echo "===> Installing chrony"
sudo apt update
sudo apt install -y chrony

# Disable systemd-timesyncd to avoid conflicts
if systemctl list-unit-files | grep -q '^systemd-timesyncd.service'; then
  echo "===> Disabling systemd-timesyncd"
  sudo systemctl disable --now systemd-timesyncd.service || true
fi

echo "===> Writing /etc/chrony/chrony.conf"
sudo tee /etc/chrony/chrony.conf >/dev/null <<'EOF'
# Chrony configuration for a server VM (America/Chicago)
# Use US pool servers (feel free to swap for your ISP/router NTP)
pool 0.us.pool.ntp.org iburst
pool 1.us.pool.ntp.org iburst
pool 2.us.pool.ntp.org iburst
pool 3.us.pool.ntp.org iburst

# Record drift, step quickly on boot if needed, sync RTC, and log
driftfile /var/lib/chrony/chrony.drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony

# Optional: prefer a local NTP source (uncomment & set your gateway/router)
# server 192.168.2.1 iburst prefer
EOF

echo "===> Enabling & starting chrony"
sudo systemctl enable --now chrony.service

echo "===> Current time settings"
timedatectl

echo "===> Chrony status (tracking)"
chronyc tracking || true

echo "===> Chrony sources (verbose)"
chronyc sources -v || true

# If this is a VMware guest, check open-vm-tools timesync (informational)
if systemctl is-active --quiet open-vm-tools.service; then
  if command -v vmware-toolbox-cmd >/dev/null 2>&1; then
    echo "===> VMware tools timesync status:"
    vmware-toolbox-cmd timesync status || true
    echo "Note: If VMware timesync is enabled, it can fight chrony."
    echo "      You can disable it with: sudo vmware-toolbox-cmd timesync disable"
  fi
fi

echo "===> Done. Chrony is installed and syncing time in the America/Chicago timezone."
