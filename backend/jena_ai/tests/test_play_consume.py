"""A grant that already committed is never undone by a failed Play consume call."""

from app.services import play_billing


class _Response:
    def __init__(self, status_code: int) -> None:
        self.status_code = status_code


class _Session:
    def __init__(self, response=None, error: Exception | None = None) -> None:
        self._response, self._error = response, error
        self.urls: list[str] = []

    def post(self, url: str, timeout: int = 0):
        self.urls.append(url)
        if self._error:
            raise self._error
        return self._response


def _use(monkeypatch, session) -> None:
    monkeypatch.setattr(play_billing, "_play_session", lambda: (session, "com.example.app"))


def test_consume_reports_success(monkeypatch) -> None:
    session = _Session(_Response(204))
    _use(monkeypatch, session)
    assert play_billing.consume_play_product_purchase("dia_pack_1", "tok") is True
    assert session.urls[0].endswith("/tokens/tok:consume")


def test_consume_refusal_is_reported_not_raised(monkeypatch, caplog) -> None:
    _use(monkeypatch, _Session(_Response(400)))
    assert play_billing.consume_play_product_purchase("dia_pack_1", "tok") is False
    assert "Play consume refused" in caplog.text


def test_consume_network_error_is_reported_not_raised(monkeypatch) -> None:
    _use(monkeypatch, _Session(error=ConnectionError("down")))
    assert play_billing.consume_play_product_purchase("dia_pack_1", "tok") is False


def test_consume_without_credentials_does_nothing(monkeypatch) -> None:
    monkeypatch.setattr(play_billing, "_play_session", lambda: None)
    assert play_billing.consume_play_product_purchase("dia_pack_1", "tok") is False
