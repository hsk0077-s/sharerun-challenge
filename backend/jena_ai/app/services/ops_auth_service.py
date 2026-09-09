import os

from fastapi import Header, HTTPException, status


def require_ops_admin(x_ops_admin_secret: str | None = Header(default=None)) -> None:
    expected_secret = os.getenv("OPS_ADMIN_SECRET", "")
    if not expected_secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OPS_ADMIN_SECRET is not configured.",
        )

    if x_ops_admin_secret != expected_secret:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid operations admin secret.",
        )
