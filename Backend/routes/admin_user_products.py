
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text

from database import engine
from auth import get_current_user

router = APIRouter(
    prefix="/admin/users",
    tags=["Admin User Products"],
)


@router.get("/{user_id}/products")
def get_user_products(
    user_id: int,
    current_user=Depends(get_current_user),
):
    if str(current_user.get("role", "")).upper() != "ADMIN":
        raise HTTPException(
            status_code=403,
            detail="Admin access required",
        )

    with engine.connect() as connection:
        result = connection.execute(
            text("""
                SELECT
                    p.P_ID AS product_id,
                    p.TITLE AS name,
                    p.DESCRIPTION AS description,
                    p.PRICE AS price,
                    p.U_ID AS user_id,
                    (
                        SELECT pi.IMAGE_PATH
                        FROM product_images pi
                        WHERE pi.P_ID = p.P_ID
                        ORDER BY pi.PI_ID ASC
                        LIMIT 1
                    ) AS image_path
                FROM PRODUCTS p
                WHERE p.U_ID = :user_id
                ORDER BY p.P_ID DESC
            """),
            {"user_id": user_id}
        )

        return {
            "products": [
                dict(row)
                for row in result.mappings().all()
            ]
        }
