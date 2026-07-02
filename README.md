# puppyride-pages — Cloudflare Pages failover for the PuppyRide tracker

Always-up public copy of the PuppyRide tracker, hosted on **Cloudflare Pages** so a
dead residential internet connection at the Dell no longer takes the public tracker
dark. The Dell stays the **build source** and the **origin** for full-res media +
full track history; Pages serves the frontend globally.

## Architecture

- **Media-light copy** of the tracker deploys here (Wrangler CLI from the Dell).
- **Data fetch = try-Dell-first, fall back to SPOT-direct.** When the Dell's cached
  `data/jim.json` is reachable, use it (full accumulated history, ~1870 pts). When it
  is not (outage), the browser polls the public SPOT feed directly (live dot +
  ~7-day trail, ~51 pts). Both payloads share the identical SPOT message shape, so
  normalization is ~nil.
- **Full-res photos + videos load from the Dell.** When unreachable they 404 to a
  friendly placeholder. Thumbnails/posters + `photos/manifest.json` ship in this
  bundle, so map markers always render.
- **Base map** falls back to raster tiles (satellite / topo) when the 519 MB pmtiles
  base can't be reached, with a "puppies tidying up the map" banner.
- Must **look and behave identically** to the live tracker — only the data-fetch
  layer and the media/base-map fallback change, never layout or styling.

## What ships here vs. stays Dell-origin

| Ships in this bundle (media-light) | Stays on the Dell (fetched cross-origin) |
|---|---|
| `tracker.html`, `index.html`, `protomaps-leaflet.js`, logos | `puppyride-v2.pmtiles` (519M base map) |
| `photos/thumbs/` + `photos/manifest.json` | `photos/full/` (106M full-res) |
| `data/route.medium.gpx` (default route) | `videos/*.mp4` |
| `data/jim.json` (snapshot seed), `data/blog.json` | `data/route.full.gpx`, exclusion/admin endpoints |

See `.gitignore` — heavy assets must never be copied in.

## Commit history = build stages

- **Baseline** — verbatim copy of the live tracker + light same-origin assets, no
  fallback edits. Deployable but still Dell-relative for data/media.
- Subsequent commits = the fallback edits (data Dell-first + SPOT fallback, media
  Dell-origin + placeholder, origin/URL rewrites, raster base-map + banner).

## Deploy

`deploy.sh` (added at deploy time) stages the Wrangler push. Auth is **not** baked in
— run `npx wrangler login` once, interactively, at first deploy.

Source of truth: this git repo (mirror to GitHub). If the Dell disk dies and there's
no repo, the Pages copy can't be rebuilt — hence repo-first.
