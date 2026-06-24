"""Tracks live WebSocket connections per user so chat messages and
notifications can be pushed instantly to anyone currently online, while
REST endpoints remain the source of truth for anyone who isn't connected.
"""

import uuid

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._connections: dict[uuid.UUID, set[WebSocket]] = {}

    def connect(self, user_id: uuid.UUID, websocket: WebSocket) -> None:
        self._connections.setdefault(user_id, set()).add(websocket)

    def disconnect(self, user_id: uuid.UUID, websocket: WebSocket) -> None:
        sockets = self._connections.get(user_id)
        if not sockets:
            return
        sockets.discard(websocket)
        if not sockets:
            self._connections.pop(user_id, None)

    def is_online(self, user_id: uuid.UUID) -> bool:
        return bool(self._connections.get(user_id))

    async def send_to_user(self, user_id: uuid.UUID, message: dict) -> None:
        for websocket in list(self._connections.get(user_id, ())):
            try:
                await websocket.send_json(message)
            except Exception:
                self.disconnect(user_id, websocket)


manager = ConnectionManager()
