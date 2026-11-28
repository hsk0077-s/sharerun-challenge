from firebase_admin import messaging


def send_data_push(token: str, title: str, body: str, data: dict) -> None:
    """One push to one device, with a small data payload. Raises on failure."""
    messaging.send(
        messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in data.items()},
            token=token,
        )
    )


def is_invalid_token_error(error: Exception) -> bool:
    """True when Firebase says this token will never work again."""
    return isinstance(
        error, (messaging.UnregisteredError, messaging.SenderIdMismatchError)
    )


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


NEW_DEVICE_TITLE = "새 기기에서 로그인했어요"


def send_new_device_alert(tokens: list[str], model: str) -> int:
    """Tell the account's other devices about a new login. Best effort.

    Returns how many pushes were accepted. A failed push never blocks login.
    """
    name = model.strip() or "새 기기"
    body = (
        f"{name}에서 내 계정으로 로그인했어요. 본인이 아니라면 "
        "보안·프라이버시 센터 > 로그인된 기기에서 모든 기기를 로그아웃해 주세요."
    )
    sent = 0
    for token in tokens:
        try:
            messaging.send(
                messaging.Message(
                    notification=messaging.Notification(
                        title=NEW_DEVICE_TITLE, body=body
                    ),
                    token=token,
                )
            )
            sent += 1
        except Exception:
            continue
    return sent
