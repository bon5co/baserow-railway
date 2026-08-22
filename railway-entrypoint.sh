#!/usr/bin/env bash
# Railway wrapper entrypoint for Baserow's all-in-one image.
#
# Runs the database migrations and seeds the deployer's administrator account
# BEFORE the supervisor starts Caddy, so the public URL never serves an
# instance whose admin account is still unclaimed. Refuses to boot without
# admin credentials rather than opening an unowned instance.
set -euo pipefail

: "${PORT:=8080}"
PUBLIC_PORT="$PORT"

# Caddy is the only listener that matters on Railway; bind it to the port
# Railway injected. This runs after the injection, so it always wins.
# Caddy turns on automatic HTTPS for any address that is not port 80 or does not
# carry an explicit scheme. Railway terminates TLS at the edge and speaks plain
# HTTP to the container, so a bare ":8080" makes every request fail with
# "Client sent an HTTP request to an HTTPS server". Force the http:// scheme.
export BASEROW_CADDY_ADDRESSES="http://:${PORT}"

# Railway injects PORT into every service, and Baserow's Nuxt/Nitro web frontend
# honours it. Upstream's Caddyfile proxies the frontend at a FIXED
# localhost:3000, so leaving PORT set makes the frontend bind Railway's port
# instead: it collides with Caddy, supervisor restarts it until
# "webfrontend entered FATAL state, too many start retries too quickly", and
# Caddy's upstream is dead the whole time. Caddy is the only process that needs
# the injected port, and it already has it, so take PORT away from the rest.
export NITRO_PORT=3000
export NITRO_HOST=0.0.0.0
unset PORT

# Railway terminates TLS at the edge and forwards plain HTTP, so Django must be
# told to trust X-Forwarded-Proto or every absolute URL it builds (password
# reset links, public grid/form share links, file URLs) comes out as http://.
export BASEROW_ENABLE_SECURE_PROXY_SSL_HEADER="${BASEROW_ENABLE_SECURE_PROXY_SSL_HEADER:-yes}"

if [ -z "${BASEROW_ADMIN_EMAIL:-}" ] || [ -z "${BASEROW_ADMIN_PASSWORD:-}" ]; then
  echo "[railway] BASEROW_ADMIN_EMAIL and BASEROW_ADMIN_PASSWORD are required." >&2
  echo "[railway] refusing to start: an unseeded Baserow gives its admin account" >&2
  echo "[railway] to the first visitor who signs up." >&2
  exit 1
fi

echo "[railway] applying database migrations before opening ${PUBLIC_PORT}"
/baserow.sh backend-cmd manage migrate

echo "[railway] seeding administrator and disabling public sign-up"
/baserow.sh backend-cmd manage shell < /baserow/railway_seed_admin.py

echo "[railway] starting Baserow; caddy on :${PUBLIC_PORT}"
exec /baserow.sh start
