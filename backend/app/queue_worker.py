"""A small async job queue that serializes calls to perform_match().

Requests pile up here instead of all hitting Gemini at once - this keeps
the backend well under Gemini's per-minute rate limit even if several
users tap "วิเคราะห์และค้นหา" at the same time.
"""

import asyncio
from typing import Callable


class MatchQueue:
    def __init__(self, worker_fn: Callable[[str], dict], num_workers: int = 1):
        self._worker_fn = worker_fn
        self._num_workers = max(1, num_workers)
        self._queue: asyncio.Queue[tuple[str, asyncio.Future]] | None = None
        self._tasks: list[asyncio.Task] = []

    def start(self) -> None:
        self._queue = asyncio.Queue()
        self._tasks = [asyncio.create_task(self._worker()) for _ in range(self._num_workers)]

    async def stop(self) -> None:
        for task in self._tasks:
            task.cancel()
        for task in self._tasks:
            try:
                await task
            except asyncio.CancelledError:
                pass
        self._tasks = []
        self._queue = None

    async def _worker(self) -> None:
        assert self._queue is not None
        while True:
            text, future = await self._queue.get()
            if not future.done():
                try:
                    result = await asyncio.to_thread(self._worker_fn, text)
                except Exception as exc:
                    future.set_exception(exc)
                else:
                    future.set_result(result)
            self._queue.task_done()

    async def submit(self, text: str, timeout: float = 25.0) -> dict:
        if self._queue is None:
            raise RuntimeError("MatchQueue is not started")

        future: asyncio.Future = asyncio.get_event_loop().create_future()
        await self._queue.put((text, future))
        return await asyncio.wait_for(future, timeout=timeout)
