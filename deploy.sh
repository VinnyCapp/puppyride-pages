#!/usr/bin/env bash
# Deploy the media-light PuppyRide tracker to Cloudflare Pages.
#
# AUTH IS NOT HANDLED HERE — run `npx wrangler login` ONCE, interactively, first.
# This script only refreshes the bundled fallback snapshots and pushes the bundle.
#
# First-ever deploy also needs the Pages project to exist:
#   npx wrangler pages project create puppyride-tracker
set -euo pipefail

REPO="/home/vin/puppyride-pages"
SRC="/home/vin/web/puppyride"
PROJECT="puppyride-tracker"          # Cloudflare Pages project name

cd "$REPO"

# 1) Refresh the bundled fallback SNAPSHOTS from the live Dell source, so the Pages copy
#    ships current thumbs/manifest/route for the offline (Dell-down) path.
#    tracker.html and index.html are DELIBERATELY excluded — the repo copies carry the
#    failover edits and must NEVER be overwritten by the unmodified live source.
echo "→ refreshing bundled snapshots (never touches tracker.html / index.html)…"
cp    "$SRC/photos/manifest.json"  photos/manifest.json
rsync -a --delete "$SRC/photos/thumbs/" photos/thumbs/
cp    "$SRC/data/blog.json"        data/blog.json
cp    "$SRC/data/jim.json"         data/jim.json
cp    "$SRC/data/route.medium.gpx" data/route.medium.gpx
cp    "$SRC/protomaps-leaflet.js"  protomaps-leaflet.js
cp    "$SRC/puppyride-logo.png"    puppyride-logo.png
cp    "$SRC/hr-logo-lockup.png"    hr-logo-lockup.png

if ! git diff --quiet; then
  echo "ℹ bundled snapshots changed — commit to keep the repo current:"
  echo "    git add -A && git commit -m 'refresh snapshots'"
fi

# 2) Preflight: confirm wrangler is authenticated. Does NOT log in.
if ! npx --yes wrangler whoami >/dev/null 2>&1; then
  echo "✗ wrangler is not authenticated." >&2
  echo "  Run:  npx wrangler login      (once, interactive), then re-run this script." >&2
  exit 1
fi

# 3) Deploy the media-light bundle.
echo "→ deploying to Cloudflare Pages project '$PROJECT'…"
npx --yes wrangler pages deploy . --project-name="$PROJECT" --commit-dirty=true
echo "✓ done."
