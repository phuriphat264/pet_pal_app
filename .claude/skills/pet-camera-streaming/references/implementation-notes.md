# Implementation notes: current state vs. the original spec

`camera-feature-spec.md` in this same folder describes a *future* target
architecture (edge server, MediaMTX, Tailscale, WebRTC). That has **not**
been built. What actually exists today is much simpler, and this doc
captures what we learned getting the real, simple version working
end-to-end against a physical TP-Link Tapo camera.

## Real current architecture (as of 2026-07)

- **No edge server.** The backend hands the client app a direct
  `rtsp://user:pass@ip:port/path` URL (see `_build_stream_url` in
  `backend/app/api/cameras.py`). The client connects to the camera
  straight over the local network.
- **This means the two core security principles in the target spec are
  currently violated**: the client app does see the camera's IP and RTSP
  credentials, embedded in the stream URL it gets from `/cameras/{id}/stream`.
  This is a known gap, acceptable for now (per project timeline —
  see memory `project-production-timeline`), but should be fixed
  (real edge-server proxy, or at minimum a short-lived signed token) before
  production.
- Access control (booking-gated for customers, role-gated for
  technicians/admins) is real and already enforced server-side.
- Camera video is rendered with **media_kit** (`Player` + `Video` widget in
  `lib/screens/live_cam_page.dart`), not `flutter_vlc_player` — see below.

## The flutter_vlc_player dead end (don't reintroduce it)

The app originally used `flutter_vlc_player` for the real-camera path
(demo footage used `video_player` instead, for local asset playback only).
On a real device/simulator test (Flutter 3.44.4 stable, first time this
path was actually exercised with real hardware), it failed 100% of the
time with:

```
PlatformException(channel-error, Unable to establish connection on channel.)
```

thrown from `VlcPlayerApi.initialize`/`create` (the plugin's Pigeon-generated
platform channel). We ruled out, in this order, before finding the real
cause:

1. Impeller rendering backend (tried `FLTEnableImpeller: false` in
   `ios/Runner/Info.plist` — no effect, but harmless, left in place)
2. Swift Package Manager plugin integration (tried
   `flutter config --no-enable-swift-package-manager` + removed the
   `.../xcshareddata/swiftpm` folders + full `flutter clean` rebuild — no
   effect)
3. Stale simulator/process state (ruled out via `xcrun simctl erase` and
   verifying fresh PIDs)

None of these fixed it. The plugin's native iOS registration was
confirmed correct in `GeneratedPluginRegistrant.m` — it's a genuine
Dart↔native protocol mismatch bug in `flutter_vlc_player` 7.4.3 against
this Flutter engine version, not a project misconfiguration.

**Fix applied**: replaced `flutter_vlc_player` with **media_kit**
(`media_kit` + `media_kit_video` + `media_kit_libs_video` packages).
Requires `MediaKit.ensureInitialized()` in `main()` before `runApp`.
This worked immediately, no channel errors. If a future Flutter/plugin
upgrade makes `flutter_vlc_player` viable again, there's no need to
switch back — media_kit is actively maintained and has no known issues
here.

## Debugging RTSP without going through the app

When a camera won't connect, don't loop on tapping "ทดสอบการเชื่อมต่อ" in
the app — it only proves TCP reachability (`probe_camera` in
`camera_probe.py` is a bare socket connect, no RTSP handshake at all).
To actually validate the stream, install ffmpeg (`brew install ffmpeg`)
and use `ffprobe` directly against the real stream URL:

```bash
ffprobe -v error -rtsp_transport tcp -timeout 8000000 \
  -select_streams v:0 -show_entries stream=codec_name,width,height \
  -of default=noprint_wrappers=1 "rtsp://user:pass@ip:port/path"
```

This surfaces the *real* RTSP server error immediately:
`401 Unauthorized` (bad username/password), `404 Not Found` (bad/missing
stream path), connection refused (wrong IP or camera not listening on
that port), etc. **Never print the resolved stream URL to a shared
terminal/log/chat** — it contains the plaintext camera password in the
URL itself; capture it into a shell variable and pass it straight to the
tool without echoing it anywhere.

## TP-Link Tapo camera gotchas (applies to the C210 currently in use, and
likely the whole Tapo camera line)

1. **WiFi pairing and the RTSP "Camera Account" are two separate,
   unrelated credential systems.** Connecting the camera to WiFi via the
   Tapo app uses your Tapo cloud login (one cloud account safely manages
   cameras across every hotel/site — no per-site account needed). RTSP
   access requires a *second*, separate step: Tapo app → the camera →
   Advanced Settings → **Camera Account** → set a username/password. RTSP
   port 554 (and ONVIF port 2020) will refuse all connections until this
   Camera Account is created, even after WiFi is fully set up. This was
   the root cause of the very first "connection refused on every port"
   failure we hit.
2. **The RTSP URL needs an explicit stream path** — `rtsp://user:pass@ip:554`
   alone 404s. Tapo cameras serve `/stream1` (main, e.g. 2304x1296) and
   `/stream2` (sub, e.g. 1280x720) as separate paths. Default new cameras
   to `/stream2` (sub-stream) per the bandwidth principle in the main spec
   doc — only bump to `/stream1` if a user explicitly wants higher quality.
3. **Concurrent stream quota is per-camera, shared across every consumer**:
   up to 2 main-stream (`/stream1`) + 2 sub-stream (`/stream2`) connections
   at once, shared between the Tapo app itself, SD card recording, and any
   third-party RTSP/ONVIF client (including our backend). Not usually an
   issue since this app only ever opens one viewer connection per camera
   at a time, but worth knowing if "add camera" testing and a live customer
   view happen simultaneously.
4. **Fixed default RTSP username**: the backend now pre-fills/defaults the
   RTSP username to `petpal` (`camera_default_username` setting in
   `backend/app/core/config.py`, `CAMERA_DEFAULT_USERNAME` env var) so
   technicians only have to remember/type a per-camera *password* when
   setting up each Camera Account, not a username too. Keep using this
   convention when creating Camera Accounts on new cameras.

## Operational note: technician offboarding

When an admin revokes someone's technician role (demotes them back to
`customer`), their assigned cameras are now automatically unassigned
(`assigned_technician_id` set to `NULL` in `update_user_role`,
`backend/app/api/admin.py`) so any other technician can immediately pick
them up — matching the existing "unassigned pool" visibility rule already
used for brand-new cameras. Don't remove this behavior; without it,
cameras get permanently stuck to a departed technician's user ID with no
UI path to reassign them.
