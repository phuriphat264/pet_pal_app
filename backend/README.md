# PetPal backend

FastAPI + PostgreSQL backend for the PetPal app: auth (JWT + Google/Facebook
OAuth), hotels/pets/bookings, partner shop applications with document
upload, AI Smart Match (semantic search), camera registration for
technicians, and chat/notifications over WebSocket.

## Architecture

- **Database**: PostgreSQL via the `pgvector/pgvector:pg16` image (Postgres +
  the `vector` extension in one container). SQLAlchemy 2.0 async ORM,
  Alembic migrations.
- **Auth**: JWT access + refresh tokens (`python-jose`), bcrypt password
  hashing. Roles: `customer | technician | admin`. Partner shops are not a
  4th role -- they're a `partner_profiles` row (pending/approved/rejected)
  owned by a normal customer account.
- **Social login**: Google ID tokens are verified cryptographically
  (`google-auth`) against Google's public certs; Facebook access tokens are
  verified via the Graph API (`/debug_token` + `/me`). See "Social login
  setup" below for where to put credentials.
- **AI Smart Match**: local embeddings via `fastembed`
  (multilingual MiniLM, 384-dim) + pgvector cosine-distance search is the
  *primary* matching engine -- free, instant, no API quota. Gemini
  (`gemini-2.5-flash-lite`) is an optional *enrichment* step that rewrites
  the summary/reasons for the candidates vector search already picked; it
  can never select different hotels, and a timeout/cache/concurrency guard
  means a slow or rate-limited Gemini call always degrades to the plain
  vector-search result instead of failing the request.
- **File storage**: MinIO (S3-compatible). Clients upload directly to MinIO
  via presigned PUT URLs -- the backend never proxies file bytes. The
  bucket is **private**: partner application documents (ID cards, business
  licenses) are real PII, so reads are also presigned, time-limited GET
  URLs generated fresh on every API response, not a public bucket policy.
- **Cameras**: registration/management only (no real camera hardware yet).
  Credentials are encrypted at rest (`cryptography.Fernet`). A technician
  only sees/edits cameras assigned to them or unassigned ones -- never
  another technician's hotels; only an admin can reassign a camera or see
  everything. "Test connection" is a real TCP-reachability probe, not a
  video stream.
- **Chat + notifications**: REST for history (`/chat/threads`,
  `/notifications`), a single WebSocket per user (`/chat/ws?token=...`) for
  live delivery of new messages and push notifications while the recipient
  is online.
- **Rate limiting**: a simple in-memory sliding-window limiter
  (`app/core/rate_limit.py`) caps `/auth/*` at 10 requests/minute per IP to
  slow down credential-stuffing/brute-force attempts.

## Run with Docker (recommended)

```sh
cd backend
cp .env.example .env
# fill in GEMINI_API_KEY, JWT_SECRET, CAMERA_SECRET_KEY (see comments in
# .env.example for how to generate strong values), and the OAuth
# credentials below if you want social login.
docker compose up --build
```

This brings up Postgres (pgvector), MinIO, and the API; runs Alembic
migrations and the idempotent seed script automatically on container start.
The API is reachable at `http://localhost:8001`.

## Run locally (without Docker for the API)

```sh
cd backend
python -m venv .venv && .venv\Scripts\activate   # or source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in values; DATABASE_URL should point at localhost:5433
docker compose up postgres minio -d   # just the infra, not the API
alembic upgrade head
python seed.py
uvicorn app.main:app --reload --port 8001
```

## Tests

```sh
cd backend
pytest
```

CRUD endpoints that need a real database are verified manually against a
running instance (see the curl examples in each router's docstring/PR
history) rather than via a DB test fixture -- there's no test DB
provisioning in this repo yet. Pure-logic modules (cache, rate limiter,
camera probe/crypto, match ranking, connection manager, OAuth token
verification) have real DB-free unit tests.

## Social login setup

Real OAuth credentials can only be created by you in your own Google/
Facebook developer accounts -- this app has the integration code, but
registering an app and obtaining a client ID/secret is something only the
account owner can do.

**Google** (`google_sign_in` on the Flutter side, `google-auth` here):
1. Google Cloud Console → APIs & Services → Credentials → Create
   Credentials → OAuth client ID.
2. Create a **Web application** client. Its client ID goes in:
   - `backend/.env` → `GOOGLE_CLIENT_ID`
   - the Flutter app's root `.env` → `GOOGLE_SERVER_CLIENT_ID` (must match
     exactly -- it's the audience the backend checks the ID token against)
3. Create a second **Android** client: package name
   `com.yourname.pet_pal_app` + your debug/release keystore's SHA-1. This
   one's ID is never copied anywhere; Google Play Services uses it via the
   signing cert at runtime.

**Facebook** (`flutter_facebook_auth` on the Flutter side):
1. developers.facebook.com → your app → Settings → Basic: App ID and App
   Secret go in `backend/.env` → `FACEBOOK_APP_ID` / `FACEBOOK_APP_SECRET`.
2. Settings → Advanced: Client Token goes in
   `android/app/src/main/res/values/strings.xml` (`facebook_client_token`),
   alongside the App ID (`facebook_app_id`) and `fb<APP_ID>` URL scheme.
3. For iOS (needs a Mac + Xcode to build): same App ID/Client Token go in
   `ios/Runner/Info.plist` (`FacebookAppID`/`FacebookClientToken`), plus the
   `fb<APP_ID>` and reversed Google iOS client ID URL schemes.

Leaving these blank disables the corresponding login button server-side
(it returns a clear "not configured" error instead of crashing).

## Production checklist

- [ ] Replace `JWT_SECRET`, `CAMERA_SECRET_KEY`, `POSTGRES_PASSWORD`,
      `S3_ACCESS_KEY`/`S3_SECRET_KEY` with strong, unique values -- the
      defaults in `.env.example` are public (checked into git) and must
      never be used as-is in a real deployment.
- [ ] Put a real domain + TLS in front of the API (a reverse proxy like
      Caddy/nginx, or your hosting platform's built-in HTTPS) -- the
      backend itself only serves plain HTTP.
- [ ] Set `GEMINI_API_KEY` and, if you want billing-tier throughput instead
      of the free tier's ~1,500 requests/day cap, enable billing in Google
      Cloud for that project.
- [ ] Fill in Google/Facebook OAuth credentials (above) if social login
      should be live.
- [ ] Back up the Postgres volume (`petpal-postgres-data`) and the MinIO
      volume (`petpal-minio-data`) on a real schedule -- both are local
      Docker volumes by default with no offsite copy.
- [ ] `docker compose logs -f backend` after first boot to confirm
      migrations + seeding succeeded before pointing the app at it.
