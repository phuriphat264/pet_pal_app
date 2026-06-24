import asyncio
import uuid
from unittest.mock import AsyncMock

from app.ws.connection_manager import ConnectionManager


def test_send_to_user_delivers_to_all_their_sockets():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    ws1, ws2 = AsyncMock(), AsyncMock()
    manager.connect(user_id, ws1)
    manager.connect(user_id, ws2)

    asyncio.run(manager.send_to_user(user_id, {"hello": "world"}))

    ws1.send_json.assert_awaited_once_with({"hello": "world"})
    ws2.send_json.assert_awaited_once_with({"hello": "world"})


def test_send_to_user_with_no_connections_is_a_noop():
    manager = ConnectionManager()
    asyncio.run(manager.send_to_user(uuid.uuid4(), {"hello": "world"}))  # should not raise


def test_disconnect_removes_only_that_socket():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    ws1, ws2 = AsyncMock(), AsyncMock()
    manager.connect(user_id, ws1)
    manager.connect(user_id, ws2)

    manager.disconnect(user_id, ws1)

    assert manager.is_online(user_id) is True
    asyncio.run(manager.send_to_user(user_id, {"x": 1}))
    ws1.send_json.assert_not_awaited()
    ws2.send_json.assert_awaited_once()


def test_disconnect_last_socket_marks_user_offline():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    ws = AsyncMock()
    manager.connect(user_id, ws)
    manager.disconnect(user_id, ws)
    assert manager.is_online(user_id) is False


def test_send_to_user_drops_dead_sockets():
    manager = ConnectionManager()
    user_id = uuid.uuid4()
    dead_ws = AsyncMock()
    dead_ws.send_json.side_effect = RuntimeError("connection closed")
    manager.connect(user_id, dead_ws)

    asyncio.run(manager.send_to_user(user_id, {"x": 1}))

    assert manager.is_online(user_id) is False
