"""Small in-memory request limiter for the account-link endpoints.

Per server instance and cleared on restart, so it slows a script that hammers
the link, unlink and preview calls; it is not a hard guarantee across
instances. Cloud Run keeps few instances for this app, which is enough for
the abuse this is meant to slow down.
"""

from collections import defaultdict, deque


class WindowLimiter:
    def __init__(self, limit: int, window_seconds: float) -> None:
        self.limit = limit
        self.window_seconds = window_seconds
        self._hits: dict[str, deque] = defaultdict(deque)

    def allow(self, key: str, now: float) -> bool:
        queue = self._hits[key or "unknown"]
        while queue and now - queue[0] > self.window_seconds:
            queue.popleft()
        if len(queue) >= self.limit:
            return False
        queue.append(now)
        return True

    def clear(self) -> None:
        self._hits.clear()


# One bucket per signed-in account and one per client address, per action group.
LINK_BY_UID = WindowLimiter(limit=10, window_seconds=600)
LINK_BY_IP = WindowLimiter(limit=40, window_seconds=600)
PREVIEW_BY_UID = WindowLimiter(limit=30, window_seconds=600)
PREVIEW_BY_IP = WindowLimiter(limit=90, window_seconds=600)

# A 6-digit code is guessable, so pairing is slow per client and per account.
WATCH_PAIR_BY_IP = WindowLimiter(limit=10, window_seconds=600)
WATCH_CODE_BY_UID = WindowLimiter(limit=5, window_seconds=600)
