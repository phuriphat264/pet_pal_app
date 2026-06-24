import asyncio
import time

import pytest

from app.queue_worker import MatchQueue


def test_submit_returns_worker_result():
    def worker(text: str) -> dict:
        return {"echo": text}

    async def run():
        queue = MatchQueue(worker, num_workers=1)
        queue.start()
        try:
            return await queue.submit("hello")
        finally:
            await queue.stop()

    assert asyncio.run(run()) == {"echo": "hello"}


def test_submit_serializes_concurrent_jobs_with_one_worker():
    active = 0
    max_active = 0

    def worker(text: str) -> dict:
        nonlocal active, max_active
        active += 1
        max_active = max(max_active, active)
        time.sleep(0.05)
        active -= 1
        return {"echo": text}

    async def run():
        queue = MatchQueue(worker, num_workers=1)
        queue.start()
        try:
            return await asyncio.gather(
                queue.submit("a"),
                queue.submit("b"),
                queue.submit("c"),
            )
        finally:
            await queue.stop()

    results = asyncio.run(run())
    assert {r["echo"] for r in results} == {"a", "b", "c"}
    assert max_active == 1


def test_submit_propagates_worker_exception():
    def worker(text: str) -> dict:
        raise ValueError("boom")

    async def run():
        queue = MatchQueue(worker, num_workers=1)
        queue.start()
        try:
            await queue.submit("hello")
        finally:
            await queue.stop()

    with pytest.raises(ValueError, match="boom"):
        asyncio.run(run())
