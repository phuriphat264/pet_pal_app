"""Real network connectivity check for a registered camera.

No camera hardware exists yet for this deployment, so this intentionally
stops at "can we open a TCP socket to this IP:port" -- that's the actual,
verifiable signal a technician needs when wiring up a real device, without
pretending to decode an RTSP/ONVIF stream that isn't there.
"""

import asyncio

PROBE_TIMEOUT_SECONDS = 4.0


async def probe_camera(ip_address: str, port: int) -> tuple[bool, str | None]:
    try:
        _, writer = await asyncio.wait_for(
            asyncio.open_connection(ip_address, port), timeout=PROBE_TIMEOUT_SECONDS
        )
    except asyncio.TimeoutError:
        return False, f"หมดเวลาเชื่อมต่อ {ip_address}:{port} (timeout {PROBE_TIMEOUT_SECONDS:.0f}s)"
    except OSError as exc:
        return False, f"เชื่อมต่อ {ip_address}:{port} ไม่สำเร็จ: {exc.strerror or exc}"

    writer.close()
    try:
        await writer.wait_closed()
    except OSError:
        pass
    return True, None
