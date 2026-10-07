from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import text

from database import engine
from auth import get_current_user


router = APIRouter(
    prefix="/classification-requests",
    tags=["Classification Requests"],
)


# ============================================================
# REQUEST MODELS
# ============================================================

class ClassificationRequestCreate(BaseModel):
    category_name: str
    product_type_name: str
    image_path: str


class ClassificationRejectRequest(BaseModel):
    admin_note: str | None = None


# ============================================================
# ADMIN CHECK
# ============================================================

def require_admin(current_user):
    role = str(
        current_user.get("role", "")
    ).upper()

    if role != "ADMIN":
        raise HTTPException(
            status_code=403,
            detail="Admin access required",
        )



def create_user_notification(
    conn,
    user_id: int,
    request_id: int,
    title: str,
    message: str,
    notification_type: str,
    category_id: int | None = None,
    product_type_id: int | None = None,
    category_name: str | None = None,
    product_type_name: str | None = None,
    image_path: str | None = None,
):
    conn.execute(
        text("""
            INSERT INTO NOTIFICATIONS (
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
                IMAGE_PATH
            )
            VALUES (
                :user_id,
                :request_id,
                :title,
                :message,
                :notification_type,
                'UNREAD',
                :category_id,
                :product_type_id,
                :category_name,
                :product_type_name,
                :image_path
            )
        """),
        {
            "user_id": user_id,
            "request_id": request_id,
            "title": title,
            "message": message,
            "notification_type": notification_type,
            "category_id": category_id,
            "product_type_id": product_type_id,
            "category_name": category_name,
            "product_type_name": product_type_name,
            "image_path": image_path,
        },
    )



# ============================================================
# USER
# CREATE CLASSIFICATION REQUEST
# ============================================================

@router.post("")
def create_classification_request(
    request: ClassificationRequestCreate,
    current_user=Depends(get_current_user),
):
    user_id = current_user["user_id"]

    category_name = request.category_name.strip()
    product_type_name = request.product_type_name.strip()
    image_path = request.image_path.strip()

    if not category_name:
        raise HTTPException(
            status_code=400,
            detail="Category is required",
        )

    if not product_type_name:
        raise HTTPException(
            status_code=400,
            detail="Product type is required",
        )

    if not image_path:
        raise HTTPException(
            status_code=400,
            detail="Image is required",
        )

    with engine.begin() as conn:

        result = conn.execute(
            text("""
                INSERT INTO CLASSIFICATION_REQUESTS
                (
                    U_ID,
                    CATEGORY_NAME,
                    PRODUCT_TYPE_NAME,
                    IMAGE_PATH,
                    STATUS
                )
                VALUES
                (
                    :user_id,
                    :category_name,
                    :product_type_name,
                    :image_path,
                    'PENDING'
                )
            """),
            {
                "user_id": user_id,
                "category_name": category_name,
                "product_type_name": product_type_name,
                "image_path": image_path,
            },
        )

        request_id = result.lastrowid

    return {
        "message": "Classification request submitted",
        "request_id": request_id,
        "status": "PENDING",
    }


# ============================================================
# USER
# GET OWN REQUEST
# ============================================================

@router.get("/{request_id}")
def get_classification_request(
    request_id: int,
    current_user=Depends(get_current_user),
):
    user_id = current_user["user_id"]

    with engine.connect() as conn:

        result = conn.execute(
            text("""
                SELECT
                    REQUEST_ID,
                    U_ID,
                    CATEGORY_NAME,
                    PRODUCT_TYPE_NAME,
                    IMAGE_PATH,
                    STATUS,
                    CATEGORY_ID,
                    PRODUCT_TYPE_ID,
                    ADMIN_NOTE,
                    CREATED_AT,
                    UPDATED_AT
                FROM CLASSIFICATION_REQUESTS
                WHERE REQUEST_ID = :request_id
                  AND U_ID = :user_id
            """),
            {
                "request_id": request_id,
                "user_id": user_id,
            },
        )

        row = result.mappings().first()

    if not row:
        raise HTTPException(
            status_code=404,
            detail="Classification request not found",
        )

    return dict(row)


# ============================================================
# ADMIN
# GET PENDING REQUESTS
# ============================================================

@router.get("/admin/pending")
def get_pending_classification_requests(
    current_user=Depends(get_current_user),
):
    require_admin(current_user)

    with engine.connect() as conn:

        result = conn.execute(
            text("""
                SELECT
                    REQUEST_ID,
                    U_ID,
                    CATEGORY_NAME,
                    PRODUCT_TYPE_NAME,
                    IMAGE_PATH,
                    STATUS,
                    CATEGORY_ID,
                    PRODUCT_TYPE_ID,
                    ADMIN_NOTE,
                    CREATED_AT,
                    UPDATED_AT
                FROM CLASSIFICATION_REQUESTS
                WHERE STATUS = 'PENDING'
                ORDER BY CREATED_AT ASC
            """)
        )

        rows = result.mappings().all()

    return {
        "requests": [
            dict(row)
            for row in rows
        ]
    }


# ============================================================
# ADMIN
# APPROVE REQUEST
# ============================================================

@router.post("/admin/{request_id}/approve")
def approve_classification_request(
    request_id: int,
    current_user=Depends(get_current_user),
):
    require_admin(current_user)

    with engine.begin() as conn:

        # ----------------------------------------------------
        # Get request
        # ----------------------------------------------------

        result = conn.execute(
            text("""
                SELECT
                    REQUEST_ID,
                    U_ID,
                    CATEGORY_NAME,
                    PRODUCT_TYPE_NAME,
                    IMAGE_PATH,
                    STATUS
                FROM CLASSIFICATION_REQUESTS
                WHERE REQUEST_ID = :request_id
            """),
            {
                "request_id": request_id,
            },
        )

        request_row = result.mappings().first()

        if not request_row:
            raise HTTPException(
                status_code=404,
                detail="Classification request not found",
            )

        if request_row["STATUS"] != "PENDING":
            raise HTTPException(
                status_code=400,
                detail="Classification request is already processed",
            )

        # ----------------------------------------------------
        # Request information
        # ----------------------------------------------------

        user_id = request_row["U_ID"]

        category_name = (
            request_row["CATEGORY_NAME"] or ""
        ).strip()

        product_type_name = (
            request_row["PRODUCT_TYPE_NAME"] or ""
        ).strip()

        image_path = (
            request_row["IMAGE_PATH"] or ""
        ).strip()

        # ----------------------------------------------------
        # FIND CATEGORY
        # ----------------------------------------------------

        category_result = conn.execute(
            text("""
                SELECT C_ID
                FROM CATEGORIES
                WHERE LOWER(CATEGORY_NAME) =
                      LOWER(:category_name)
                LIMIT 1
            """),
            {
                "category_name": category_name,
            },
        )

        category_row = category_result.mappings().first()

        if category_row:

            category_id = category_row["C_ID"]

        else:

            category_result = conn.execute(
                text("""
                    INSERT INTO CATEGORIES
                    (
                        CATEGORY_NAME
                    )
                    VALUES
                    (
                        :category_name
                    )
                """),
                {
                    "category_name": category_name,
                },
            )

            category_id = category_result.lastrowid

        # ----------------------------------------------------
        # FIND PRODUCT TYPE
        # ----------------------------------------------------

        product_result = conn.execute(
            text("""
                SELECT PRODUCT_TYPE_ID
                FROM PRODUCT_TYPES
                WHERE C_ID = :category_id
                  AND LOWER(PRODUCT_TYPE_NAME) =
                      LOWER(:product_type_name)
                LIMIT 1
            """),
            {
                "category_id": category_id,
                "product_type_name": product_type_name,
            },
        )

        product_row = product_result.mappings().first()

        if product_row:

            product_type_id = product_row["PRODUCT_TYPE_ID"]

        else:

            product_result = conn.execute(
                text("""
                    INSERT INTO PRODUCT_TYPES
                    (
                        C_ID,
                        PRODUCT_TYPE_NAME
                    )
                    VALUES
                    (
                        :category_id,
                        :product_type_name
                    )
                """),
                {
                    "category_id": category_id,
                    "product_type_name": product_type_name,
                },
            )

            product_type_id = product_result.lastrowid

        # ----------------------------------------------------
        # UPDATE CLASSIFICATION REQUEST
        # ----------------------------------------------------
        # ----------------------------------------------------
        # UPDATE REQUEST
        # ----------------------------------------------------

        conn.execute(
            text("""
                UPDATE CLASSIFICATION_REQUESTS
                SET
                    STATUS = 'APPROVED',
                    CATEGORY_ID = :category_id,
                    PRODUCT_TYPE_ID = :product_type_id,
                    UPDATED_AT = CURRENT_TIMESTAMP
                WHERE REQUEST_ID = :request_id
            """),
            {
                "request_id": request_id,
                "category_id": category_id,
                "product_type_id": product_type_id,
            },
        )

        # ----------------------------------------------------
        # CREATE USER NOTIFICATION
        # ----------------------------------------------------

        request_user_result = conn.execute(
            text("""
                SELECT
                    U_ID,
                    IMAGE_PATH
                FROM CLASSIFICATION_REQUESTS
                WHERE REQUEST_ID = :request_id
            """),
            {
                "request_id": request_id,
            },
        )

        request_user = request_user_result.mappings().first()

        if not request_user:
            raise HTTPException(
                status_code=404,
                detail="User information not found",
            )

        create_user_notification(
            conn=conn,
            user_id=request_user["U_ID"],
            request_id=request_id,
            title="Classification Approved",
            message=(
                "Admin approved your product classification. "
                "Continue selling by adding your product details."
            ),
            notification_type="CLASSIFICATION_APPROVED",
            category_id=category_id,
            product_type_id=product_type_id,
            category_name=category_name,
            product_type_name=product_type_name,
            image_path=request_user["IMAGE_PATH"],
        )


    return {
        "message": "Classification request approved",
        "request_id": request_id,
        "status": "APPROVED",
        "category_id": category_id,
        "product_type_id": product_type_id,
    }

# ============================================================
# ADMIN
# REJECT REQUEST
# ============================================================

@router.post("/admin/{request_id}/reject")
def reject_classification_request(
    request_id: int,
    request: ClassificationRejectRequest,
    current_user=Depends(get_current_user),
):
    require_admin(current_user)

    with engine.begin() as conn:

        # ----------------------------------------------------
        # GET REQUEST
        # ----------------------------------------------------

        result = conn.execute(
            text("""
                SELECT
                    REQUEST_ID,
                    U_ID,
                    CATEGORY_NAME,
                    PRODUCT_TYPE_NAME,
                    IMAGE_PATH,
                    STATUS
                FROM CLASSIFICATION_REQUESTS
                WHERE REQUEST_ID = :request_id
            """),
            {
                "request_id": request_id,
            },
        )

        row = result.mappings().first()

        if not row:
            raise HTTPException(
                status_code=404,
                detail="Classification request not found",
            )

        if row["STATUS"] != "PENDING":
            raise HTTPException(
                status_code=400,
                detail="Classification request is already processed",
            )

        # ----------------------------------------------------
        # UPDATE REQUEST
        # ----------------------------------------------------

        conn.execute(
            text("""
                UPDATE CLASSIFICATION_REQUESTS
                SET
                    STATUS = 'REJECTED',
                    ADMIN_NOTE = :admin_note,
                    UPDATED_AT = CURRENT_TIMESTAMP
                WHERE REQUEST_ID = :request_id
            """),
            {
                "request_id": request_id,
                "admin_note": request.admin_note,
            },
        )

        # ----------------------------------------------------
        # CREATE USER NOTIFICATION
        # ----------------------------------------------------

        create_user_notification(
            conn=conn,
            user_id=row["U_ID"],
            request_id=request_id,
            title="Product Classification Rejected",
            message=(
                "Your product classification request was rejected. "
                "Please review the admin note and try again."
            ),
            notification_type="CLASSIFICATION_REJECTED",
            category_name=row["CATEGORY_NAME"],
            product_type_name=row["PRODUCT_TYPE_NAME"],
            image_path=row["IMAGE_PATH"],
        )

    return {
        "message": "Classification request rejected",
        "request_id": request_id,
        "status": "REJECTED",
    }