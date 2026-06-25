#!/bin/bash
# PetPal Production Deployment Script (Ubuntu 22.04 / Debian 12)
# Run this on the server as root or with sudo
# Usage: bash deploy.sh YOUR_DOMAIN.com

set -e
DOMAIN="${1:?Usage: bash deploy.sh YOUR_DOMAIN.com}"

echo "==> [1/6] Install Docker + Certbot"
apt-get update -qq
apt-get install -y -qq docker.io docker-compose-plugin certbot
systemctl enable --now docker

echo "==> [2/6] Clone or pull repo"
if [ -d "/opt/petpal" ]; then
  cd /opt/petpal && git pull
else
  git clone https://github.com/YOUR_USERNAME/pet_pal_app.git /opt/petpal
  cd /opt/petpal
fi

echo "==> [3/6] Configure .env"
if [ ! -f "/opt/petpal/backend/.env" ]; then
  cp /opt/petpal/backend/.env.production /opt/petpal/backend/.env
  echo ""
  echo "  *** EDIT /opt/petpal/backend/.env before continuing ***"
  echo "  Replace all <CHANGE_ME> values, then re-run this script."
  exit 1
fi

# Replace YOUR_DOMAIN in nginx.conf
sed -i "s/YOUR_DOMAIN.com/$DOMAIN/g" /opt/petpal/backend/nginx.conf

echo "==> [4/6] Open firewall ports"
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 7880/tcp
ufw allow 7881/tcp
ufw allow 50000:50019/udp
ufw --force enable
echo "  Firewall rules applied."

echo "==> [5/6] Get SSL certificate (Let's Encrypt)"
# Temporary nginx for certbot ACME challenge
docker run --rm -d --name tmp-nginx -p 80:80 \
  -v /var/www/certbot:/usr/share/nginx/html nginx:alpine 2>/dev/null || true

certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email "admin@$DOMAIN" \
  --agree-tos --no-eff-email \
  -d "$DOMAIN" || {
    echo "  certbot failed -- make sure DNS A record points to this server's IP"
    docker stop tmp-nginx 2>/dev/null || true
    exit 1
  }

docker stop tmp-nginx 2>/dev/null || true

# Auto-renew SSL
echo "0 3 * * * root certbot renew --quiet && docker exec petpal-nginx nginx -s reload" \
  > /etc/cron.d/certbot-renew

echo "==> [6/6] Build and start containers"
cd /opt/petpal/backend
docker compose -f docker-compose.prod.yml pull --quiet
docker compose -f docker-compose.prod.yml up --build -d

echo ""
echo "============================================="
echo "  Deploy complete!"
echo "  API:    https://$DOMAIN/api/v1/health"
echo "  Docs:   https://$DOMAIN/docs"
echo "  Logs:   docker compose -f /opt/petpal/backend/docker-compose.prod.yml logs -f"
echo "============================================="
