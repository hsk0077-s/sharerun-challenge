"""World Tour decoration prices. Separate pieces sum to 340; the set is 270."""

from app.services.item_price_config import (
    WORLD_TOUR_COUNTRY_SET_ID,
    resolve_item_prices,
    world_tour_catalog_rows,
    world_tour_separate_dia,
)


def test_world_tour_prices_and_the_set_discount() -> None:
    prices = resolve_item_prices(None)
    assert prices["world_tour_costume"] == 120
    assert prices["world_tour_accessory"] == 60
    assert prices["world_tour_background"] == 90
    assert prices["world_tour_passport_cover"] == 70
    assert prices[WORLD_TOUR_COUNTRY_SET_ID] == 270
    assert world_tour_separate_dia(prices) == 340
    assert prices[WORLD_TOUR_COUNTRY_SET_ID] < world_tour_separate_dia(prices)


def test_a_bad_world_tour_override_keeps_the_code_price() -> None:
    prices = resolve_item_prices({"world_tour_costume": 0, "world_tour_country_set": "270"})
    assert prices["world_tour_costume"] == 120
    assert prices["world_tour_country_set"] == 270


def test_catalog_rows_are_dia_prices() -> None:
    rows = {row["id"]: row for row in world_tour_catalog_rows(resolve_item_prices(None))}
    assert rows["world_tour_accessory"]["diamondCost"] == 60
    assert rows["world_tour_accessory"]["shareCost"] == 0
    assert rows["world_tour_country_set"]["diamondCost"] == 270
