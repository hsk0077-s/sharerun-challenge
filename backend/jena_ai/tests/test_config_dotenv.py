from pathlib import Path

from app.config import dotenv_path, load_repo_dotenv, repo_root, repo_root_from


def test_checkout_repo_root_matches_parents_three() -> None:
    assert repo_root() == Path(__file__).resolve().parents[3]


def test_cloud_run_layout_has_no_repo_root_and_skips_dotenv(monkeypatch) -> None:
    config_file = Path("/app/app/config.py")
    called: list[object] = []
    monkeypatch.setattr(
        "app.config.load_dotenv",
        lambda *args, **kwargs: called.append((args, kwargs)) or True,
    )

    assert repo_root_from(config_file) is None
    assert dotenv_path(config_file) is None
    assert load_repo_dotenv(config_file) is False
    assert called == []


def test_missing_env_file_skips_load_but_keeps_repo_root(tmp_path, monkeypatch) -> None:
    repo = tmp_path / "src"
    config_file = repo / "backend" / "jena_ai" / "app" / "config.py"
    config_file.parent.mkdir(parents=True)
    config_file.write_text("# marker\n", encoding="utf-8")
    called: list[object] = []
    monkeypatch.setattr(
        "app.config.load_dotenv",
        lambda *args, **kwargs: called.append((args, kwargs)) or True,
    )

    assert repo_root_from(config_file) == repo.resolve()
    assert dotenv_path(config_file) is None
    assert load_repo_dotenv(config_file) is False
    assert called == []


def test_existing_repo_env_is_loaded_without_override(tmp_path, monkeypatch) -> None:
    repo = tmp_path / "src"
    config_file = repo / "backend" / "jena_ai" / "app" / "config.py"
    config_file.parent.mkdir(parents=True)
    config_file.write_text("# marker\n", encoding="utf-8")
    env_file = repo / ".env"
    env_file.write_text("LOCAL_DEV_MODE=true\n", encoding="utf-8")
    called: list[tuple] = []

    def _load(path, override=True):
        called.append((path, override))
        return True

    monkeypatch.setattr("app.config.load_dotenv", _load)

    assert dotenv_path(config_file) == env_file.resolve()
    assert load_repo_dotenv(config_file) is True
    assert called == [(env_file.resolve(), False)]
