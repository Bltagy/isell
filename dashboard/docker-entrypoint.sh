#!/bin/sh
# Inject runtime env vars into a JS file loaded by the browser.
# Runs at container start — no image rebuild needed when HOST_IP changes.

cat > /app/public/__env.js << JSEOF
window.__ENV__ = {
  NEXT_PUBLIC_API_URL: "${NEXT_PUBLIC_API_URL:-http://localhost}",
  NEXT_PUBLIC_REVERB_HOST: "${NEXT_PUBLIC_REVERB_HOST:-localhost}",
  NEXT_PUBLIC_REVERB_PORT: "${NEXT_PUBLIC_REVERB_PORT:-8060}",
  NEXT_PUBLIC_REVERB_APP_KEY: "${NEXT_PUBLIC_REVERB_APP_KEY:-foodapp-key}"
};
JSEOF

exec node server.js
