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

## Dell-side requirement: CORS

The Pages copy is a different origin from the Dell, so the browser needs the Dell to send
`Access-Control-Allow-Origin` on the cross-origin fetches. Without it the failover still
works — it just degrades everywhere (SPOT for track data, bundled snapshot for photos/blog,
raster for the base map) — but to get the *fresh, full-history, vector* experience when the
Dell is up, add CORS on the Dell nginx (`puppyride.vinnycapp.com`) for:

| Path | Used by | Needs |
|---|---|---|
| `/data/*.json` (jim.json) | track data (2a) | `Access-Control-Allow-Origin` |
| `/photos/manifest.json`, `/data/blog.json` | markers (2b) | `Access-Control-Allow-Origin` |
| `/photos/full/*`, `/videos/*` | full-res media (2b) | none (`<img>`/`<video>` are CORS-free) |
| `/puppyride-v2.pmtiles` | vector base map (2f) | ACAO **+ allow/expose `Range`** (range requests) |

`/photos-api/*` admin POSTs (2e) also need a CORS preflight allowance if admin is used from
the Pages copy — optional (admin is normally done on the Dell origin directly).

## Deploy

Run `./deploy.sh`. It refreshes the bundled fallback snapshots from the live source (never
`tracker.html`/`index.html`) and pushes the bundle via Wrangler. Auth is **not** baked in:

```bash
npx wrangler login                                   # once, interactive
npx wrangler pages project create puppyride-tracker  # first deploy only
./deploy.sh
```

Source of truth: this git repo (mirrored to `github.com/VinnyCapp/puppyride-pages`). If the
Dell disk dies and there's no repo, the Pages copy can't be rebuilt — hence repo-first.
