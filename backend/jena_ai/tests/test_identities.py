import pytest
from fastapi import HTTPException
from google.api_core.exceptions import AlreadyExists

from app.services import identities


class _Snap:
    def __init__(self, store, id_):
        self.id = id_
        self._data = store.get(id_)
        self.exists = self._data is not None
        self.reference = _Doc(store, id_)

    def to_dict(self):
        return dict(self._data) if self._data is not None else None


class _Doc:
    def __init__(self, store, id_):
        self.store, self.id = store, id_

    def get(self):
        return _Snap(self.store, self.id)

    def set(self, data, merge=False):
        if merge and self.id in self.store:
            self.store[self.id].update(data)
        else:
            self.store[self.id] = dict(data)

    def create(self, data):
        if self.id in self.store:
            raise AlreadyExists("exists")
        self.store[self.id] = dict(data)

    def delete(self):
        self.store.pop(self.id, None)


class _Query:
    def __init__(self, store, filters):
        self.store, self.filters = store, filters

    def where(self, field, op, value):
        assert op == "=="
        return _Query(self.store, self.filters + [(field, value)])

    def limit(self, _n):
        return self

    def get(self):
        return [
            _Snap(self.store, id_)
            for id_, row in list(self.store.items())
            if all(row.get(f) == v for f, v in self.filters)
        ]


class _Db:
    def __init__(self):
        self.stores = {identities.IDENTITIES: {}, identities.LOG: {}}

    def collection(self, name):
        store = self.stores[name]

        class C:
            def document(self, id_=None):
                return _Doc(store, id_ or f"auto{len(store)}")

            def where(self, field, op, value):
                return _Query(store, []).where(field, op, value)

        return C()


class _NotFound(Exception):
    pass


class _FbAuth:
    UserNotFoundError = _NotFound

    def __init__(self, providers=()):
        self.users = {}
        self.providers = list(providers)
        self.next = 1

    def create_user(self):
        uid = f"fb{self.next}"
        self.next += 1
        self.users[uid] = True
        return type("U", (), {"uid": uid})()

    def get_user(self, uid):
        if uid not in self.users:
            raise _NotFound()
        info = [type("P", (), {"provider_id": p})() for p in self.providers]
        return type("U", (), {"uid": uid, "provider_data": info})()

    def delete_user(self, uid):
        self.users.pop(uid, None)

    def create_custom_token(self, uid, claims=None):
        return f"custom-for-{uid}".encode()


def _verify(pid):
    return lambda token: pid


def test_first_kakao_login_makes_one_account_and_a_token() -> None:
    db, fb = _Db(), _FbAuth()
    out = identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    assert out == {"custom_token": "custom-for-fb1", "new_account": True}
    assert db.stores[identities.IDENTITIES]["kakao:777"]["uid"] == "fb1"
    log = list(db.stores[identities.LOG].values())
    assert [r["action"] for r in log] == ["login_new"]
    assert "t" * 20 not in str(log) and "777" not in str(log)


def test_second_login_reuses_the_same_account() -> None:
    db, fb = _Db(), _FbAuth()
    identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    out = identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    assert out == {"custom_token": "custom-for-fb1", "new_account": False}
    assert len(fb.users) == 1


def test_a_deleted_account_gets_a_fresh_one() -> None:
    db, fb = _Db(), _FbAuth()
    identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    fb.delete_user("fb1")
    out = identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    assert out["new_account"] is True
    assert db.stores[identities.IDENTITIES]["kakao:777"]["uid"] == "fb2"


def test_link_attaches_kakao_to_the_signed_in_account() -> None:
    db = _Db()
    out = identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("777"))
    assert out == {"linked": True, "already": False}
    assert db.stores[identities.IDENTITIES]["kakao:777"]["uid"] == "u1"
    again = identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("777"))
    assert again == {"linked": True, "already": True}


def test_link_is_refused_when_kakao_belongs_to_someone_else() -> None:
    db = _Db()
    identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("777"))
    with pytest.raises(HTTPException) as caught:
        identities.link(db, "u2", "kakao", "t" * 20, verify=_verify("777"))
    assert caught.value.status_code == 409
    assert caught.value.detail == "identity_belongs_to_another_account"
    assert db.stores[identities.IDENTITIES]["kakao:777"]["uid"] == "u1"
    assert [r["action"] for r in db.stores[identities.LOG].values()][-1] == "link_refused"


def test_an_account_takes_one_kakao_only() -> None:
    db = _Db()
    identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("777"))
    with pytest.raises(HTTPException) as caught:
        identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("888"))
    assert caught.value.detail == "provider_already_linked"


def test_login_after_link_opens_the_linked_account() -> None:
    db, fb = _Db(), _FbAuth(providers=["google.com"])
    fb.users["g1"] = True
    identities.link(db, "g1", "kakao", "t" * 20, verify=_verify("777"))
    out = identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    assert out == {"custom_token": "custom-for-g1", "new_account": False}


def test_unlink_needs_another_way_to_sign_in() -> None:
    db, fb = _Db(), _FbAuth()
    out = identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    uid = out["custom_token"].removeprefix("custom-for-")
    with pytest.raises(HTTPException) as caught:
        identities.unlink(db, uid, "kakao", fb_auth=fb)
    assert caught.value.detail == "last_login_method"
    assert "kakao:777" in db.stores[identities.IDENTITIES]

    fb2 = _FbAuth(providers=["google.com"])
    fb2.users["g1"] = True
    identities.link(db, "g1", "kakao", "t" * 20, verify=_verify("999"))
    assert identities.unlink(db, "g1", "kakao", fb_auth=fb2) == {"unlinked": True}
    assert "kakao:999" not in db.stores[identities.IDENTITIES]
    with pytest.raises(HTTPException) as again:
        identities.unlink(db, "g1", "kakao", fb_auth=fb2)
    assert again.value.status_code == 404


def test_the_list_shows_google_and_kakao() -> None:
    db, fb = _Db(), _FbAuth(providers=["google.com", "password"])
    fb.users["g1"] = True
    identities.link(db, "g1", "kakao", "t" * 20, verify=_verify("777"))
    assert identities.list_providers(db, "g1", fb_auth=fb) == {
        "providers": ["google", "email", "kakao"]
    }


def test_deleting_an_account_frees_the_kakao_id() -> None:
    db = _Db()
    identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("777"))
    identities.forget_account(db, "u1")
    assert db.stores[identities.IDENTITIES] == {}


def test_unknown_provider_is_refused() -> None:
    with pytest.raises(HTTPException) as caught:
        identities.login(_Db(), "apple", "t" * 20, verify=_verify("1"), fb_auth=_FbAuth())
    assert caught.value.detail == "unknown_provider"


def test_custom_token_failure_is_reported_not_hidden() -> None:
    class Broken(_FbAuth):
        def create_custom_token(self, uid, claims=None):
            raise RuntimeError("iam")

    with pytest.raises(HTTPException) as caught:
        identities.login(_Db(), "kakao", "t" * 20, verify=_verify("1"), fb_auth=Broken())
    assert caught.value.detail == "custom_token_unavailable"


def test_login_attempts_are_limited_per_client() -> None:
    identities._attempts.clear()
    results = [identities.allow_login_attempt("1.2.3.4", 100.0) for _ in range(31)]
    assert results[:30] == [True] * 30 and results[30] is False
    assert identities.allow_login_attempt("5.6.7.8", 100.0) is True
    assert identities.allow_login_attempt("1.2.3.4", 100.0 + 601) is True
    identities._attempts.clear()


class _Resp:
    def __init__(self, body):
        self._body = body

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False

    def read(self):
        return self._body


def test_kakao_token_must_belong_to_this_app(monkeypatch) -> None:
    monkeypatch.setenv("KAKAO_APP_ID", "1234")
    monkeypatch.setattr(
        identities.urllib.request,
        "urlopen",
        lambda req, timeout=0: _Resp(b'{"id": 55, "app_id": 1234}'),
    )
    assert identities.verify_kakao_token("t" * 20) == "55"
    monkeypatch.setattr(
        identities.urllib.request,
        "urlopen",
        lambda req, timeout=0: _Resp(b'{"id": 55, "app_id": 9999}'),
    )
    with pytest.raises(HTTPException) as caught:
        identities.verify_kakao_token("t" * 20)
    assert caught.value.detail == "provider_token_for_other_app"


def test_kakao_is_refused_until_the_app_id_is_set(monkeypatch) -> None:
    monkeypatch.delenv("KAKAO_APP_ID", raising=False)
    with pytest.raises(HTTPException) as caught:
        identities.verify_kakao_token("t" * 20)
    assert caught.value.status_code == 503
    assert caught.value.detail == "kakao_not_configured"


def test_kakao_rejects_a_bad_token(monkeypatch) -> None:
    import urllib.error

    monkeypatch.setenv("KAKAO_APP_ID", "1234")

    def boom(req, timeout=0):
        raise urllib.error.HTTPError(req.full_url, 401, "no", {}, None)

    monkeypatch.setattr(identities.urllib.request, "urlopen", boom)
    with pytest.raises(HTTPException) as caught:
        identities.verify_kakao_token("t" * 20)
    assert caught.value.status_code == 401


def test_routes_are_wired_and_only_login_is_open() -> None:
    from fastapi.testclient import TestClient

    from app.main import app

    client = TestClient(app)
    # Login needs no Firebase token; a short token is a validation error.
    assert client.post("/auth/kakao/login", json={"access_token": "x"}).status_code == 422
    # Link, unlink and the list need a signed-in account.
    assert client.post("/auth/kakao/link", json={"access_token": "t" * 20}).status_code == 401
    assert client.post("/auth/kakao/unlink").status_code == 401
    assert client.get("/auth/identities").status_code == 401


def test_naver_works_like_kakao_and_both_can_share_one_account() -> None:
    db, fb = _Db(), _FbAuth(providers=["google.com"])
    fb.users["g1"] = True
    identities.link(db, "g1", "kakao", "t" * 20, verify=_verify("777"))
    assert identities.link(db, "g1", "naver", "t" * 20, verify=_verify("n55")) == {
        "linked": True,
        "already": False,
    }
    assert db.stores[identities.IDENTITIES]["naver:n55"]["uid"] == "g1"
    out = identities.login(db, "naver", "t" * 20, verify=_verify("n55"), fb_auth=fb)
    assert out == {"custom_token": "custom-for-g1", "new_account": False}
    assert identities.list_providers(db, "g1", fb_auth=fb) == {
        "providers": ["google", "kakao", "naver"]
    }


def test_a_new_naver_user_gets_a_new_account() -> None:
    db, fb = _Db(), _FbAuth()
    out = identities.login(db, "naver", "t" * 20, verify=_verify("n1"), fb_auth=fb)
    assert out["new_account"] is True
    assert db.stores[identities.IDENTITIES]["naver:n1"]["provider"] == "naver"


def test_naver_unlink_is_allowed_when_kakao_remains() -> None:
    db, fb = _Db(), _FbAuth()
    fb.users["u1"] = True
    identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("k1"))
    identities.link(db, "u1", "naver", "t" * 20, verify=_verify("n1"))
    assert identities.unlink(db, "u1", "naver", fb_auth=fb) == {"unlinked": True}
    # 이제 카카오가 마지막 방법이다.
    with pytest.raises(HTTPException) as caught:
        identities.unlink(db, "u1", "kakao", fb_auth=fb)
    assert caught.value.detail == "last_login_method"


def test_naver_token_is_read_from_the_profile_answer(monkeypatch) -> None:
    monkeypatch.setattr(
        identities.urllib.request,
        "urlopen",
        lambda req, timeout=0: _Resp(
            b'{"resultcode":"00","message":"success","response":{"id":"abc123"}}'
        ),
    )
    assert identities.verify_naver_token("t" * 20) == "abc123"


def test_naver_bad_answers_are_refused(monkeypatch) -> None:
    import urllib.error

    for body in (
        b'{"resultcode":"024","message":"Authentication failed"}',
        b'{"resultcode":"00","message":"success","response":{}}',
        b"{}",
    ):
        monkeypatch.setattr(
            identities.urllib.request,
            "urlopen",
            lambda req, timeout=0, b=body: _Resp(b),
        )
        with pytest.raises(HTTPException) as caught:
            identities.verify_naver_token("t" * 20)
        assert caught.value.detail == "invalid_provider_token"

    def boom(req, timeout=0):
        raise urllib.error.HTTPError(req.full_url, 401, "no", {}, None)

    monkeypatch.setattr(identities.urllib.request, "urlopen", boom)
    with pytest.raises(HTTPException) as caught:
        identities.verify_naver_token("t" * 20)
    assert caught.value.status_code == 401

    def down(req, timeout=0):
        raise urllib.error.URLError("down")

    monkeypatch.setattr(identities.urllib.request, "urlopen", down)
    with pytest.raises(HTTPException) as unreachable:
        identities.verify_naver_token("t" * 20)
    assert unreachable.value.status_code == 502


def test_naver_routes_are_wired_like_kakao() -> None:
    from fastapi.testclient import TestClient

    from app.main import app

    client = TestClient(app)
    assert client.post("/auth/naver/login", json={"access_token": "x"}).status_code == 422
    assert client.post("/auth/naver/link", json={"access_token": "t" * 20}).status_code == 401
    assert client.post("/auth/naver/unlink").status_code == 401
