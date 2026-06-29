#!/usr/bin/env bash
# Deploy index.html to /var/www and serve with nginx.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE="dylanmccapes-systems"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run with sudo:  sudo $ROOT/deploy.sh"
  exit 1
fi

echo "▸ Installing nginx (if needed)…"
export DEBIAN_FRONTEND=noninteractive
if ! command -v nginx >/dev/null; then
  apt-get update -qq
  apt-get install -y nginx
fi

echo "▸ Publishing ${ROOT}/index.html → /var/www/index.html"
install -d /var/www
install -m 644 "${ROOT}/index.html" /var/www/index.html

for page in reflection-feynman.html; do
  if [[ -f "${ROOT}/${page}" ]]; then
    echo "▸ Publishing ${ROOT}/${page} → /var/www/${page}"
    install -m 644 "${ROOT}/${page}" "/var/www/${page}"
  fi
done

if [[ -d "${ROOT}/media" ]]; then
  echo "▸ Publishing ${ROOT}/media → /var/www/media"
  install -d /var/www/media
  install -m 644 "${ROOT}/media/"* /var/www/media/
fi

chown -R www-data:www-data /var/www

echo "▸ Installing nginx site config"
install -m 644 "${ROOT}/nginx-site.conf" "/etc/nginx/sites-available/${SITE}"
ln -sf "/etc/nginx/sites-available/${SITE}" "/etc/nginx/sites-enabled/${SITE}"
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo ""
echo "✓ Live at  http://127.0.0.1/"
echo "  File:    /var/www/index.html"
echo "  Config:  /etc/nginx/sites-available/${SITE}"
