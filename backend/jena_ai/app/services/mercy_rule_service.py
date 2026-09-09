from dataclasses import dataclass


@dataclass(frozen=True)
class MercySettlement:
    achievement_rate: float
    forfeited_diamonds: int
    returned_diamonds: int
    charity_target: str


class MercyRuleService:
    def compute_settlement(
        self,
        *,
        diamond_deposit: int,
        target_distance_km: float,
        distance_achieved_km: float,
        charity_target: str,
    ) -> MercySettlement:
        if diamond_deposit <= 0:
            return MercySettlement(
                achievement_rate=1.0,
                forfeited_diamonds=0,
                returned_diamonds=0,
                charity_target=charity_target,
            )

        if target_distance_km <= 0:
            achievement_rate = 0.0
        else:
            achievement_rate = min(distance_achieved_km / target_distance_km, 1.0)

        forfeited = int(diamond_deposit * (1.0 - achievement_rate))
        returned = diamond_deposit - forfeited
        return MercySettlement(
            achievement_rate=achievement_rate,
            forfeited_diamonds=forfeited,
            returned_diamonds=returned,
            charity_target=charity_target,
        )
