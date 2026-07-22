---
name: pet-camera-streaming
description: Use when implementing, modifying, or reviewing the real-time pet-room camera viewing feature — edge server (RTSP/MediaMTX), Tailscale networking, booking-gated access control backend, WebRTC/HLS client viewer, admin monitoring dashboard, or the "has camera" matching badge. Trigger on mentions of Tapo/RTSP/ONVIF cameras, MediaMTX, camera edge server, or booking-gated stream access in this app.
---

# Pet Room Camera Streaming

Full spec: `references/camera-feature-spec.md` (read it before starting work on any phase below — it has the complete phase-by-phase scope, hardware constraints, and suggested tech stack). **That spec describes the future target architecture (edge server/MediaMTX/WebRTC) — it has not been built.**

Current real implementation, plus everything learned debugging it end-to-end against a physical camera (flutter_vlc_player dead end → media_kit, Tapo Camera Account/stream-path gotchas, ffprobe-based RTSP debugging, technician-offboarding unassignment): `references/implementation-notes.md`. **Read this one first** if you're touching the camera feature at all — it'll save you from re-debugging things already solved once.

## Non-negotiable architecture rules (target — not yet fully implemented, see implementation-notes.md for the gap)

1. Client app never knows the camera's IP or connects to it directly — always through backend + edge server.
2. RTSP credentials live only on the edge server, never reach the client.
3. Edge server dials out to backend via Tailscale (outbound only) — never port-forward a camera to the public internet.
4. Streams are on-demand only — pull from camera only while someone is actively watching, never continuously.
5. Default to the camera's sub-stream (low resolution); let the user opt into main stream.
6. Access is booking-gated: short-lived token (5–10 min, renewable while booking stays active), revoked immediately on checkout — event-driven, not just a timer.
7. No video is ever recorded/stored. Only anonymized access metadata (who/when/duration) with short retention (7–14 days), for dispute resolution only.
8. Multi-tenant from day one — never hardcode assumptions for a single hotel/camera.

## Phases (do one at a time, don't dump all phases into one change)

1. Edge server (RTSP → MediaMTX → WebRTC/HLS, watchdog, heartbeat)
2. Network/access layer (Tailscale mesh, hotel→edge→camera mapping)
3. Backend booking-gated access control (token issuance/revocation, metadata log)
4. Client viewer (WebRTC with HLS fallback, active-booking-only menu, graceful offline handling)
5. Admin dashboard (camera/edge health, alerts, access logs, role-based access)
6. Matching integration (badge + minor scoring boost — camera never viewable pre-booking)

See the reference doc for the detailed checklist per phase before implementing.
