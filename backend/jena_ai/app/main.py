import logging
import os

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from app import config  # noqa: F401 — loads .env on import

from app.routers.admin_router import router as admin_router
from app.routers.identity_router import router as identity_router
from app.routers.ops_router import router as ops_router
from app.routers.payment_router import router as payment_router
from app.routers.secured_action_router import router as secured_action_router

_log = logging.getLogger(__name__)
_warned_no_pg_secret = False

# The interactive docs list every route. Show them only on a developer machine.
_docs = config.is_local_dev_mode()
app = FastAPI(
    title="SRC Jena AI Engine",
    version="0.1.0",
    docs_url="/docs" if _docs else None,
    redoc_url="/redoc" if _docs else None,
    openapi_url="/openapi.json" if _docs else None,
)

# Browser admin calls /admin with an ID token. No cookies.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/ready")
def health_ready() -> dict[str, object]:
    global _warned_no_pg_secret
    if config.is_local_dev_mode():
        return {"status": "ready", "mode": "local"}

    # The PG webhook secret is required only while payments are on. With
    # payments off it is a warning, so a 1.0 deploy without it stays ready.
    required = ["OPS_ADMIN_SECRET"]
    if config.payments_enabled():
        required.append("PG_WEBHOOK_SECRET")
    missing_env = [name for name in required if not os.getenv(name)]
    if missing_env:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "status": "not_ready",
                "missing_env": missing_env,
            },
        )

    warnings: list[str] = []
    if not config.payments_enabled() and not os.getenv("PG_WEBHOOK_SECRET"):
        warnings.append("PG_WEBHOOK_SECRET")
        if not _warned_no_pg_secret:
            _warned_no_pg_secret = True
            _log.warning(
                "PG_WEBHOOK_SECRET is not set and PAYMENTS_ENABLED is off. "
                "Payments stay off. Set both before turning payments on."
            )
    if warnings:
        return {"status": "ready", "warnings": warnings}
    return {"status": "ready"}


app.include_router(admin_router)
app.include_router(identity_router)
app.include_router(payment_router)
app.include_router(secured_action_router)
app.include_router(ops_router)
