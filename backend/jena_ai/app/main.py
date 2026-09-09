import os

from fastapi import FastAPI, HTTPException, status

from app import config  # noqa: F401 — loads .env on import

from app.routers.ops_router import router as ops_router
from app.routers.payment_router import router as payment_router
from app.routers.secured_action_router import router as secured_action_router
from app.routers.validation_router import router as validation_router

app = FastAPI(
    title="SRC Jena AI Engine",
    version="0.1.0",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/ready")
def health_ready() -> dict[str, str]:
    if config.is_local_dev_mode():
        return {"status": "ready", "mode": "local"}

    missing_env = [
        name
        for name in ("PG_WEBHOOK_SECRET", "OPS_ADMIN_SECRET")
        if not os.getenv(name)
    ]
    if missing_env:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "status": "not_ready",
                "missing_env": missing_env,
            },
        )
    return {"status": "ready"}


app.include_router(validation_router)
app.include_router(payment_router)
app.include_router(secured_action_router)
app.include_router(ops_router)
