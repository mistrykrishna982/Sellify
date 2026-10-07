from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text

from database import engine
from auth import get_current_user


router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


# ============================================================
# GET USER NOTIFICATIONS
# ============================================================

@router.get("")
def get_notifications(
    current_user=Depends(get_current_user),
):
    user_id = current_user["user_id"]

    with engine.connect() as conn:

        result = conn.execute(
            text("""
                SELECT
                    NOTIFICATION_ID,
                    U_ID,
                    REQUEST_ID,
                    TITLE,
                    MESSAGE,
                    TYPE,
                    STATUS,
                    CATEGORY_ID,
                    PRODUCT_TYPE_ID,
                    CATEGORY_NAME,
                    PRODUCT_TYPE_NAME,
                    IMAGE_PATH,
                    CREATED_AT
                FROM NOTIFICATIONS
                WHERE U_ID = :user_id
                ORDER BY CREATED_AT DESC
            """),
            {
                "user_id": user_id,
            },
        )

        rows = result.mappings().all()

    return {
        "notifications": [
            dict(row)
            for row in rows
        ]
    }


# ============================================================
# GET UNREAD NOTIFICATION COUNT
# ============================================================

@router.get("/unread-count")
def get_unread_notification_count(
    current_user=Depends(get_current_user),
):
    user_id = current_user["user_id"]

    with engine.connect() as conn:

        result = conn.execute(
            text("""
                SELECT COUNT(*) AS UNREAD_COUNT
                FROM NOTIFICATIONS
                WHERE U_ID = :user_id
                  AND STATUS = 'UNREAD'
            """),
            {
                "user_id": user_id,
            },
        )

        row = result.mappings().first()

    return {
        "unread_count": int(
            row["UNREAD_COUNT"] or 0
        )
    }


# ============================================================
# MARK NOTIFICATION AS READ
# ============================================================

@router.patch("/{notification_id}/read")
def mark_notification_as_read(
    notification_id: int,
    current_user=Depends(get_current_user),
):
    user_id = current_user["user_id"]

    with engine.begin() as conn:

        result = conn.execute(
            text("""
                UPDATE NOTIFICATIONS
                SET STATUS = 'READ'
                WHERE NOTIFICATION_ID = :notification_id
                  AND U_ID = :user_id
            """),
            {
                "notification_id": notification_id,
                "user_id": user_id,
            },
        )

        if result.rowcount == 0:
            raise HTTPException(
                status_code=404,
                detail="Notification not found",
            )

    return {
        "message": "Notification marked as read",
        "notification_id": notification_id,
        "status": "READ",
    }