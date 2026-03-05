#!/usr/bin/env bash
# install.sh – Set up the Masjid Display backend on a Raspberry Pi
# Run as: sudo bash scripts/install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_USER="${SUDO_USER:-admin}"
VENV_DIR="/home/${INSTALL_USER}/masjid-display-control/venv"
APP_DIR="/home/${INSTALL_USER}/masjid-display-control/raspberry-backend"
ENV_FILE="/etc/masjid/masjid.env"
SERVICE_SRC="${REPO_DIR}/systemd/masjid-api.service"
SERVICE_DEST="/etc/systemd/system/masjid-api.service"
UPLOAD_DIR="/home/${INSTALL_USER}/masjid_assets/uploads"
STATE_DIR="/home/${INSTALL_USER}"

echo "==> Installing system packages"
apt-get update -qq
apt-get install -y python3 python3-pip python3-venv --no-install-recommends

echo "==> Creating Python virtual environment at ${VENV_DIR}"
mkdir -p "$(dirname "${VENV_DIR}")"
python3 -m venv "${VENV_DIR}"

echo "==> Installing Python dependencies"
"${VENV_DIR}/bin/pip" install --upgrade pip --quiet
"${VENV_DIR}/bin/pip" install -r "${REPO_DIR}/requirements.txt" --quiet

echo "==> Creating upload directory"
mkdir -p "${UPLOAD_DIR}"
chown -R "${INSTALL_USER}:${INSTALL_USER}" "$(dirname "${UPLOAD_DIR}")"

echo "==> Linking app directory"
if [ ! -L "${APP_DIR}" ] && [ ! -d "${APP_DIR}" ]; then
    mkdir -p "$(dirname "${APP_DIR}")"
    ln -s "${REPO_DIR}" "${APP_DIR}"
fi

echo "==> Creating environment file at ${ENV_FILE}"
mkdir -p "$(dirname "${ENV_FILE}")"
if [ ! -f "${ENV_FILE}" ]; then
    cat > "${ENV_FILE}" <<EOF
# Masjid Display API environment variables
# MASJID_API_KEY=change-me-before-going-live
# MASJID_HMAC_SECRET=
# MASJID_STATE_PATH=/home/${INSTALL_USER}/masjid_state.json
# MASJID_UPLOAD_DIR=/home/${INSTALL_USER}/masjid_assets/uploads
EOF
    echo "    Created ${ENV_FILE} (edit to set MASJID_API_KEY)"
else
    echo "    ${ENV_FILE} already exists – skipping"
fi

echo "==> Installing systemd service"
# Patch the service file with the real paths
sed \
    -e "s|/home/admin|/home/${INSTALL_USER}|g" \
    "${SERVICE_SRC}" > "${SERVICE_DEST}"

systemctl daemon-reload
systemctl enable masjid-api.service

echo ""
echo "================================================================"
echo " Installation complete."
echo ""
echo " Before starting the service, edit ${ENV_FILE} and set:"
echo "   MASJID_API_KEY=<your-secret-key>"
echo ""
echo " Then start the service:"
echo "   sudo systemctl start masjid-api"
echo "   sudo systemctl status masjid-api"
echo ""
echo " Kiosk display URL:  http://<raspberry-pi-ip>:8787/display"
echo " API info endpoint:  http://<raspberry-pi-ip>:8787/v1/info"
echo "================================================================"
