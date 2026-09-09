from app.services.notification_service import tournament_topic


def test_tournament_topic_prefixes_id() -> None:
    assert tournament_topic("abc123") == "tournament_abc123"
