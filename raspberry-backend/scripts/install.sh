#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_SRC="$ROOT_DIR/systemd/masjid-api.service"
SERVICE_DST="/etc/systemd/system/masjid-api.service"

sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

python3 -m pip install --upgrade pip
python3 -m pip install -r "$ROOT_DIR/requirements.txt"

sudo mkdir -p /home/admin/masjid_assets/uploads
sudo chown -R admin:admin /home/admin/masjid_assets

sudo cp "$SERVICE_SRC" "$SERVICE_DST"
sudo systemctl daemon-reload
sudo systemctl enable masjid-api.service
sudo systemctl restart masjid-api.service

echo "Masjid API installed. Check status with: sudo systemctl status masjid-api.service"
