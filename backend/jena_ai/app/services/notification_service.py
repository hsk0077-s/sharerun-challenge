from firebase_admin import messaging


def tournament_topic(tournament_id: str) -> str:
    return f"tournament_{tournament_id}"


def send_tournament_topic_notification(
    tournament_id: str,
    *,
    title: str,
    body: str,
) -> None:
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        topic=tournament_topic(tournament_id),
    )
    messaging.send(message)
