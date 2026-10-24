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
        self.stores.setdefault(name, {})
        store = self.stores[name]

        class C:
            def document(self, id_=None):
                return _Doc(store, id_ or f"auto{len(store)}")

            def where(self, field, op, value):
                return _Query(store, []).where(field, op, value)

        return C()


class _NotFound(Exception):
    pass


class _AuthUser:
    def __init__(self, uid, email, email_verified, provider_ids):
        self.uid = uid
        self.email = email
        self.email_verified = email_verified
        self.provider_data = [type("P", (), {"provider_id": p})() for p in provider_ids]


class _FbAuth:
    UserNotFoundError = _NotFound

    def __init__(self, providers=()):
        self.users = {}
        self.providers = list(providers)
        self.next = 1

    def add(self, uid, *, email=None, email_verified=False):
        self.users[uid] = _AuthUser(uid, email, email_verified, list(self.providers))
        return self.users[uid]

    def create_user(self, email=None, email_verified=False, **_kwargs):
        uid = f"fb{self.next}"
        self.next += 1
        return self.add(uid, email=email, email_verified=email_verified)

    def get_user(self, uid):
        raw = self.users.get(uid)
        if raw is None:
            raise _NotFound()
        if raw is True:
            raw = self.add(uid)
        return raw

    def get_user_by_email(self, email):
        want = (email or "").strip().lower()
        found = []
        for uid in list(self.users):
            user = self.get_user(uid)
            if (user.email or "").strip().lower() == want:
                found.append(user)
        if not found:
            raise _NotFound()
        if len(found) > 1:
            raise identities.AmbiguousVerifiedEmail()
        return found[0]

    def update_user(self, uid, email=None, email_verified=None, **_kwargs):
        user = self.get_user(uid)
        if email is not None:
            user.email = email
        if email_verified is not None:
            user.email_verified = email_verified
        return user

    def delete_user(self, uid):
        self.users.pop(uid, None)

    def create_custom_token(self, uid, claims=None):
        return f"custom-for-{uid}".encode()


def _verify(pid):
    return lambda token: pid


def test_first_kakao_login_makes_one_account_and_a_token() -> None:
    db, fb = _Db(), _FbAuth()
    out = identities.login(
        db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb, create_account=True
    )
    assert out == {"custom_token": "custom-for-fb1", "new_account": True}
    assert db.stores[identities.IDENTITIES]["kakao:777"]["uid"] == "fb1"
    log = list(db.stores[identities.LOG].values())
    assert [r["action"] for r in log] == ["login_new"]
    assert "t" * 20 not in str(log) and "777" not in str(log)


def test_second_login_reuses_the_same_account() -> None:
    db, fb = _Db(), _FbAuth()
    identities.login(
        db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb, create_account=True
    )
    out = identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    assert out == {"custom_token": "custom-for-fb1", "new_account": False}
    assert len(fb.users) == 1


def test_a_deleted_account_is_not_recreated_in_silence() -> None:
    db, fb = _Db(), _FbAuth()
    identities.login(
        db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb, create_account=True
    )
    fb.delete_user("fb1")
    out = identities.login(db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb)
    assert out == {"needs_account_choice": True, "new_account": False}
    assert "kakao:777" not in db.stores[identities.IDENTITIES]
    assert fb.users == {}


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
    out = identities.login(
        db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb, create_account=True
    )
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
        identities.login(
            _Db(),
            "kakao",
            "t" * 20,
            verify=_verify("1"),
            fb_auth=Broken(),
            create_account=True,
        )
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
    assert identities.verify_kakao_token("t" * 20).user_id == "55"
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
    assert client.get("/auth/link-preview").status_code == 401


def _named(db, uid, nickname="러너", share=100) -> None:
    db.collection(identities.USERS).document(uid).set({
        "nickname": nickname,
        "wallet": {"shareBalance": share},
    })


def test_naver_works_like_kakao_and_both_can_share_one_account() -> None:
    db, fb = _Db(), _FbAuth(providers=["google.com"])
    fb.users["g1"] = True
    _named(db, "g1", share=1200)
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
    out = identities.login(
        db, "naver", "t" * 20, verify=_verify("n1"), fb_auth=fb, create_account=True
    )
    assert out["new_account"] is True
    assert db.stores[identities.IDENTITIES]["naver:n1"]["provider"] == "naver"


def test_naver_unlink_is_allowed_when_kakao_remains() -> None:
    db, fb = _Db(), _FbAuth()
    fb.users["u1"] = True
    _named(db, "u1")
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
    identity = identities.verify_naver_token("t" * 20)
    assert identity.user_id == "abc123"
    assert identity.verified_email is None


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
    assert client.post("/auth/google/login", json={"id_token": "x"}).status_code == 422
    assert client.post("/auth/google/link", json={"id_token": "t" * 20}).status_code == 401
    assert client.post("/auth/google/unlink").status_code == 401
    assert client.get("/auth/link-preview").status_code == 401


def _verified(pid, email):
    return lambda token: identities.ProviderIdentity(pid, email)


def test_a_verified_email_links_the_existing_account() -> None:
    import hashlib

    db, fb = _Db(), _FbAuth()
    fb.add("google-user", email="Match@x.com", email_verified=True)
    out = identities.login(
        db,
        "kakao",
        "t" * 20,
        verify=_verified("k9", "match@x.com"),
        fb_auth=fb,
    )
    assert out == {"custom_token": "custom-for-google-user", "new_account": False}
    assert db.stores[identities.IDENTITIES]["kakao:k9"]["uid"] == "google-user"
    assert db.stores[identities.IDENTITIES]["kakao:k9"]["linkedBy"] == "verified_email"
    assert list(fb.users) == ["google-user"]
    log = list(db.stores[identities.LOG].values())
    assert [row["action"] for row in log] == ["auto_link"]
    assert log[0]["emailHash"] == hashlib.sha256(b"match@x.com").hexdigest()[:16]
    assert "match@x.com" not in str(log) and "k9" not in str(log) and "t" * 20 not in str(log)
    saved = list(db.stores[identities.VERIFIED_EMAILS].values())
    assert saved == [{"uids": ["google-user"]}]
    assert "match@x.com" not in str(saved)


def test_an_unverified_or_missing_email_does_not_merge() -> None:
    db, fb = _Db(), _FbAuth()
    fb.add("google-user", email="match@x.com", email_verified=True)
    for identity in (
        identities.ProviderIdentity("k1", None),
        identities.ProviderIdentity("k2", ""),
        "k3",
    ):
        out = identities.login(
            db, "kakao", "t" * 20, verify=lambda token, identity=identity: identity, fb_auth=fb
        )
        assert out == {"needs_account_choice": True, "new_account": False}
    assert db.stores[identities.IDENTITIES] == {}
    assert list(fb.users) == ["google-user"]

    # The account's own address is not verified, so the provider address is not enough.
    fb.add("plain", email="other@x.com", email_verified=False)
    out = identities.login(
        db, "kakao", "t" * 20, verify=_verified("k4", "other@x.com"), fb_auth=fb
    )
    assert out["needs_account_choice"] is True
    assert "kakao:k4" not in db.stores[identities.IDENTITIES]


def test_duplicate_verified_emails_are_not_merged() -> None:
    db, fb = _Db(), _FbAuth()
    fb.add("a", email="same@x.com", email_verified=True)
    fb.add("b", email="same@x.com", email_verified=True)
    out = identities.login(
        db, "kakao", "t" * 20, verify=_verified("k9", "same@x.com"), fb_auth=fb
    )
    assert out == {"needs_account_choice": True, "new_account": False}
    assert db.stores[identities.IDENTITIES] == {}
    assert set(fb.users) == {"a", "b"}

    # Asking for a new account is allowed once the person says so. It must not
    # pick a or b.
    created = identities.login(
        db,
        "kakao",
        "t" * 20,
        verify=_verified("k9", "same@x.com"),
        fb_auth=fb,
        create_account=True,
    )
    assert created["new_account"] is True
    assert created["custom_token"] not in {"custom-for-a", "custom-for-b"}


def test_an_email_index_duplicate_blocks_auto_link_when_auth_returns_one() -> None:
    """Firebase get_user_by_email returns one user. A second verified uid we
    already recorded still means the address is not safe to merge on."""

    class _FirstOnly(_FbAuth):
        def get_user_by_email(self, email):
            want = (email or "").strip().lower()
            for uid in self.users:
                user = self.get_user(uid)
                if (user.email or "").strip().lower() == want and user.email_verified:
                    return user
            raise _NotFound()

    db, fb = _Db(), _FirstOnly()
    fb.add("a", email="same@x.com", email_verified=True)
    fb.add("b", email="same@x.com", email_verified=True)
    db.collection(identities.VERIFIED_EMAILS).document(identities._email_doc("same@x.com")).set(
        {"uids": ["a", "b"]}
    )
    out = identities.login(
        db, "naver", "t" * 20, verify=_verified("n1", "same@x.com"), fb_auth=fb
    )
    assert out["needs_account_choice"] is True
    assert db.stores[identities.IDENTITIES] == {}


def test_an_identity_already_linked_elsewhere_is_not_moved() -> None:
    db, fb = _Db(), _FbAuth()
    fb.add("owner", email="owner@x.com", email_verified=True)
    fb.add("match", email="match@x.com", email_verified=True)
    identities.link(db, "owner", "kakao", "t" * 20, verify=_verify("777"))
    out = identities.login(
        db, "kakao", "t" * 20, verify=_verified("777", "match@x.com"), fb_auth=fb
    )
    assert out == {"custom_token": "custom-for-owner", "new_account": False}
    assert db.stores[identities.IDENTITIES]["kakao:777"]["uid"] == "owner"
    assert [row["action"] for row in db.stores[identities.LOG].values()] == ["link", "login"]


def test_auto_link_is_skipped_when_the_account_already_has_that_provider() -> None:
    db, fb = _Db(), _FbAuth()
    fb.add("match", email="match@x.com", email_verified=True)
    identities.link(db, "match", "kakao", "t" * 20, verify=_verify("111"))
    out = identities.login(
        db, "kakao", "t" * 20, verify=_verified("222", "match@x.com"), fb_auth=fb
    )
    assert out["needs_account_choice"] is True
    assert "kakao:222" not in db.stores[identities.IDENTITIES]
    assert db.stores[identities.IDENTITIES]["kakao:111"]["uid"] == "match"
    assert "auto_link" not in [row["action"] for row in db.stores[identities.LOG].values()]


def test_deleted_and_purging_accounts_are_not_merge_targets() -> None:
    db, fb = _Db(), _FbAuth()
    fb.add("gone", email="match@x.com", email_verified=True)
    db.collection("users").document("gone").set({"accountStatus": "purged"})
    out = identities.login(
        db, "kakao", "t" * 20, verify=_verified("k9", "match@x.com"), fb_auth=fb
    )
    assert out["needs_account_choice"] is True
    assert db.stores[identities.IDENTITIES] == {}

    fb.add("old", email="old@x.com", email_verified=True)
    identities.link(db, "old", "naver", "t" * 20, verify=_verify("n1"))
    db.collection("users").document("old").set({"accountStatus": "deleted"})
    again = identities.login(
        db, "naver", "t" * 20, verify=_verified("n1", "old@x.com"), fb_auth=fb
    )
    assert again["needs_account_choice"] is True
    assert "naver:n1" not in db.stores[identities.IDENTITIES]


def test_explicit_create_then_the_other_provider_lands_on_it() -> None:
    db, fb = _Db(), _FbAuth()
    first = identities.login(
        db,
        "kakao",
        "t" * 20,
        verify=_verified("k1", "match@x.com"),
        fb_auth=fb,
        create_account=True,
    )
    assert first["new_account"] is True
    uid = first["custom_token"].removeprefix("custom-for-")
    assert fb.get_user(uid).email == "match@x.com"
    assert fb.get_user(uid).email_verified is True
    second = identities.login(
        db, "google", "t" * 20, verify=_verified("gsub", "match@x.com"), fb_auth=fb
    )
    assert second == {"custom_token": f"custom-for-{uid}", "new_account": False}
    assert db.stores[identities.IDENTITIES]["google:gsub"]["uid"] == uid
    assert [row["action"] for row in db.stores[identities.LOG].values()] == [
        "login_new",
        "auto_link",
    ]


def test_kakao_email_needs_both_flags(monkeypatch) -> None:
    monkeypatch.setenv("KAKAO_APP_ID", "1234")

    def urlopen(req, timeout=0, body=None):
        if req.full_url.endswith("access_token_info"):
            return _Resp(b'{"id": 55, "app_id": 1234}')
        return _Resp(body)

    cases = (
        (
            b'{"kakao_account":{"email":"A@x.com","is_email_valid":true,"is_email_verified":true}}',
            "a@x.com",
        ),
        (
            b'{"kakao_account":{"email":"A@x.com","is_email_valid":true,"is_email_verified":false}}',
            None,
        ),
        (
            b'{"kakao_account":{"email":"A@x.com","is_email_valid":false,"is_email_verified":true}}',
            None,
        ),
        (b'{"kakao_account":{"is_email_valid":true,"is_email_verified":true}}', None),
        (b"{}", None),
    )
    for body, email in cases:
        monkeypatch.setattr(
            identities.urllib.request,
            "urlopen",
            lambda req, timeout=0, body=body: urlopen(req, timeout, body),
        )
        identity = identities.verify_kakao_token("t" * 20)
        assert identity.user_id == "55"
        assert identity.verified_email == email


def test_naver_profile_email_is_treated_as_verified(monkeypatch) -> None:
    monkeypatch.setattr(
        identities.urllib.request,
        "urlopen",
        lambda req, timeout=0: _Resp(
            b'{"resultcode":"00","message":"success","response":{"id":"abc","email":"User@Naver.com"}}'
        ),
    )
    identity = identities.verify_naver_token("t" * 20)
    assert identity.user_id == "abc"
    assert identity.verified_email == "user@naver.com"

    monkeypatch.setattr(
        identities.urllib.request,
        "urlopen",
        lambda req, timeout=0: _Resp(
            b'{"resultcode":"00","message":"success","response":{"id":"abc","email":"  "}}'
        ),
    )
    assert identities.verify_naver_token("t" * 20).verified_email is None


def test_google_email_is_verified_only_when_the_claim_says_so(monkeypatch) -> None:
    seen = {}

    def claims(token, audience):
        seen["audience"] = audience
        return {"sub": "g1", "email": "A@x.com", "email_verified": True}

    monkeypatch.setattr(identities, "_google_claims", claims)
    monkeypatch.delenv("GOOGLE_WEB_CLIENT_ID", raising=False)
    assert identities.verify_google_id_token("t" * 20) == identities.ProviderIdentity(
        "g1", "a@x.com"
    )
    assert seen["audience"] is None

    monkeypatch.setenv("GOOGLE_WEB_CLIENT_ID", "web-client")
    identities.verify_google_id_token("t" * 20)
    assert seen["audience"] == "web-client"
    monkeypatch.setattr(
        identities,
        "_google_claims",
        lambda token, audience: {"sub": "g1", "email": "a@x.com", "email_verified": False},
    )
    assert identities.verify_google_id_token("t" * 20).verified_email is None


def test_link_refuses_an_account_without_a_nickname() -> None:
    db = _Db()
    identities.link(db, "empty", "kakao", "t" * 20, verify=_verify("k1"))
    with pytest.raises(HTTPException) as caught:
        identities.link(db, "empty", "naver", "t" * 20, verify=_verify("n1"))
    assert caught.value.status_code == 409
    assert caught.value.detail == "empty_account"
    assert "naver:n1" not in db.stores[identities.IDENTITIES]
    assert [row["action"] for row in db.stores[identities.LOG].values()][-1] == "link_refused"

    for provider, pid in (("kakao", "k9"), ("naver", "n9"), ("google", "g9")):
        uid = f"shell-{provider}"
        db.collection(identities.USERS).document(uid).set({
            "nickname": "   ",
            "wallet": {"shareBalance": 0},
        })
        with pytest.raises(HTTPException) as blank:
            identities.link(db, uid, provider, "t" * 20, verify=_verify(pid))
        assert blank.value.detail == "empty_account"
        assert f"{provider}:{pid}" not in db.stores[identities.IDENTITIES]


def test_a_named_account_can_link_another_method() -> None:
    db = _Db()
    _named(db, "u1", nickname="달림이", share=42)
    identities.link(db, "u1", "kakao", "t" * 20, verify=_verify("k1"))
    assert identities.link(db, "u1", "google", "t" * 20, verify=_verify("g1")) == {
        "linked": True,
        "already": False,
    }


def test_link_preview_returns_only_nickname_and_share() -> None:
    db = _Db()
    _named(db, "u1", nickname="달림이", share=1200)
    db.collection(identities.USERS).document("u1").set(
        {"nickname": "달림이", "email": "secret@example.com", "wallet": {"shareBalance": 1200}},
    )
    preview = identities.link_preview(db, "u1")
    assert preview == {"nickname": "달림이", "share_balance": 1200, "can_link": True}
    assert "email" not in preview

    missing = identities.link_preview(db, "nobody")
    assert missing == {"nickname": "", "share_balance": 0, "can_link": False}

    db.collection(identities.USERS).document("blank").set({"nickname": "  ", "wallet": {}})
    assert identities.link_preview(db, "blank")["can_link"] is False


def test_link_endpoints_are_rate_limited_per_account_and_per_address(monkeypatch) -> None:
    from fastapi.testclient import TestClient

    from app.main import app
    from app.routers import identity_router
    from app.services import auth_service, rate_limit

    for limiter in (
        rate_limit.LINK_BY_UID,
        rate_limit.LINK_BY_IP,
        rate_limit.PREVIEW_BY_UID,
        rate_limit.PREVIEW_BY_IP,
    ):
        limiter.clear()
    calls = {"link": 0, "preview": 0}
    monkeypatch.setattr(identity_router, "_db", lambda: object())
    monkeypatch.setattr(
        identities, "link", lambda *a, **k: calls.__setitem__("link", calls["link"] + 1) or {}
    )
    monkeypatch.setattr(
        identities,
        "link_preview",
        lambda *a, **k: calls.__setitem__("preview", calls["preview"] + 1) or {},
    )
    app.dependency_overrides[auth_service.require_uid] = lambda: "u1"
    try:
        client = TestClient(app)
        body = {"access_token": "t" * 20}
        statuses = [client.post("/auth/kakao/link", json=body).status_code for _ in range(12)]
        assert statuses[:10] == [200] * 10
        assert statuses[10:] == [429, 429]
        assert calls["link"] == 10
        refused = client.post("/auth/naver/unlink")
        assert refused.status_code == 429
        assert refused.json()["detail"] == "too_many_attempts"

        previews = [client.get("/auth/link-preview").status_code for _ in range(32)]
        assert previews[:30] == [200] * 30
        assert previews[30:] == [429, 429]
        assert calls["preview"] == 30
    finally:
        app.dependency_overrides.pop(auth_service.require_uid, None)
        for limiter in (
            rate_limit.LINK_BY_UID,
            rate_limit.LINK_BY_IP,
            rate_limit.PREVIEW_BY_UID,
            rate_limit.PREVIEW_BY_IP,
        ):
            limiter.clear()


def test_the_window_limiter_forgets_old_hits() -> None:
    from app.services.rate_limit import WindowLimiter

    limiter = WindowLimiter(limit=2, window_seconds=10)
    assert limiter.allow("a", 0) and limiter.allow("a", 1)
    assert limiter.allow("a", 2) is False
    assert limiter.allow("b", 2) is True
    assert limiter.allow("a", 12) is True


def test_signing_up_again_after_deletion_blocks_rewards() -> None:
    db, fb = _Db(), _FbAuth()
    first = identities.login(
        db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb, create_account=True
    )
    assert identities.REWARD_BLOCKS not in db.stores or not db.stores[identities.REWARD_BLOCKS]
    uid = [r["uid"] for r in db.stores[identities.IDENTITIES].values()][0]
    identities.forget_account(db, uid)
    assert "777" not in str(db.stores[identities.REWARD_TOMBSTONES])

    identities.login(
        db, "kakao", "t" * 20, verify=_verify("777"), fb_auth=fb, create_account=True
    )
    new_uid = [r["uid"] for r in db.stores[identities.IDENTITIES].values()][0]
    assert new_uid != uid
    assert new_uid in db.stores[identities.REWARD_BLOCKS]
    assert first
