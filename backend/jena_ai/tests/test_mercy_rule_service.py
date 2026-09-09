from app.services.mercy_rule_service import MercyRuleService


def test_mercy_rule_partial_achievement() -> None:
    settlement = MercyRuleService().compute_settlement(
        diamond_deposit=10,
        target_distance_km=5.0,
        distance_achieved_km=3.0,
        charity_target="UNICEF",
    )

    assert settlement.achievement_rate == 0.6
    assert settlement.forfeited_diamonds == 4
    assert settlement.returned_diamonds == 6
    assert settlement.charity_target == "UNICEF"


def test_mercy_rule_zero_deposit() -> None:
    settlement = MercyRuleService().compute_settlement(
        diamond_deposit=0,
        target_distance_km=5.0,
        distance_achieved_km=1.0,
        charity_target="UNICEF",
    )

    assert settlement.forfeited_diamonds == 0
    assert settlement.returned_diamonds == 0
