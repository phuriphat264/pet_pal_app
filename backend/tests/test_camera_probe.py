import asyncio

from app.services.camera_probe import probe_camera


def test_probe_camera_succeeds_against_an_open_local_port():
    import socket

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", 0))
    server.listen(1)
    port = server.getsockname()[1]
    try:
        success, error = asyncio.run(probe_camera("127.0.0.1", port))
        assert success is True
        assert error is None
    finally:
        server.close()


def test_probe_camera_fails_against_a_closed_port():
    import socket

    # Bind and immediately close to get a port nothing is listening on.
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()

    success, error = asyncio.run(probe_camera("127.0.0.1", port))
    assert success is False
    assert error
