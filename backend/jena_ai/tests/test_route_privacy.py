from app.services.route_privacy import ROUTE_TRIM_METERS, _meters, trim_route


def _line(km: float, step_m: float = 50.0) -> list[dict]:
    # Straight north-south line, about 111,320 m per degree of latitude.
    count = int(km * 1000 / step_m) + 1
    return [
        {"latitude": 37.0 + i * step_m / 111320.0, "longitude": 127.0, "recordedAt": str(i)}
        for i in range(count)
    ]


def test_start_and_finish_are_cut_by_distance_run() -> None:
    route = _line(2.0)
    kept = trim_route(route)
    assert kept
    assert _meters(route[0], kept[0]) >= ROUTE_TRIM_METERS - 1
    assert _meters(kept[-1], route[-1]) >= ROUTE_TRIM_METERS - 1
    assert len(kept) < len(route)


def test_middle_of_the_route_is_untouched() -> None:
    route = _line(3.0)
    kept = trim_route(route)
    assert all(point in route for point in kept)
    assert kept == route[kept and route.index(kept[0]) : route.index(kept[-1]) + 1]


def test_a_route_with_no_middle_is_stored_empty() -> None:
    assert trim_route(_line(0.5)) == []
    assert trim_route([]) == []
    assert trim_route(_line(2.0)[:1]) == []


def test_a_loop_that_returns_home_hides_both_ends() -> None:
    out = _line(1.0)
    route = out + list(reversed(out))
    kept = trim_route(route)
    assert kept
    assert route[0] not in kept and route[-1] not in kept
    assert len(kept) < len(route)
