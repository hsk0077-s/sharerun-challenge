"""Hide the start and finish of a stored run route (usually near home).

Validation and rewards use the full route the phone sent. Only the copy saved
on the activity is trimmed, by distance run, so no home address is needed.
"""

from math import asin, cos, radians, sin, sqrt

ROUTE_TRIM_METERS = 300.0


def _meters(a: dict, b: dict) -> float:
    lat1, lon1 = radians(a["latitude"]), radians(a["longitude"])
    lat2, lon2 = radians(b["latitude"]), radians(b["longitude"])
    h = (
        sin((lat2 - lat1) / 2) ** 2
        + cos(lat1) * cos(lat2) * sin((lon2 - lon1) / 2) ** 2
    )
    return 2 * 6371000.0 * asin(sqrt(h))


def trim_route(points: list[dict], trim_m: float = ROUTE_TRIM_METERS) -> list[dict]:
    """Drop points within `trim_m` metres (along the route) of either end.

    A route too short to keep any middle part is stored empty.
    """
    if len(points) < 2:
        return []
    cumulative = [0.0]
    for previous, current in zip(points, points[1:]):
        cumulative.append(cumulative[-1] + _meters(previous, current))
    total = cumulative[-1]
    return [
        point
        for point, walked in zip(points, cumulative)
        if walked >= trim_m and total - walked >= trim_m
    ]
