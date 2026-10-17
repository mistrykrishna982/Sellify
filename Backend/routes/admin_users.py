
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text

from database import engine
from auth import get_current_user

router = APIRouter(
    prefix="/admin/users",
    tags=["Admin Users"],
)


@router.get("")
def list_users(
    current_user=Depends(get_current_user),
):
    # Only administrators can access this endpoint.
    if str(current_user.get("role", "")).upper() != "ADMIN":
        raise HTTPException(
            status_code=403,
            detail="Admin access required",
        )

    with engine.connect() as connection:
        result = connection.execute(
            text("""
                SELECT
                    u.U_ID AS user_id,
                    u.U_NAME AS name,
                    u.EMAIL AS email,
                    u.ROLE AS role,
                    p.PHONE AS phone,
                    p.LOCATION AS location,
                    p.PROFILE_IMAGE AS profile_image
                FROM USERS u
                LEFT JOIN USER_PROFILES p
                    ON p.U_ID = u.U_ID
                ORDER BY u.U_ID DESC
            """)
        )

        users = [
            dict(row)
            for row in result.mappings().all()
        ]

        return {"users": users}
