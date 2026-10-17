
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import SessionLocal
from auth import get_current_user

router = APIRouter(
    prefix="/cart",
    tags=["Cart"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/items/{product_id}")
def add_to_cart(
    product_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_id = current_user.get("U_ID") or current_user.get("user_id")

    if user_id is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid user session",
        )

    product = db.execute(
        text("""
            SELECT P_ID
            FROM products
            WHERE P_ID = :product_id
              AND STATUS = 'ACTIVE'
              AND U_ID != :user_id
        """),
        {
            "product_id": product_id,
            "user_id": user_id,
        },
    ).mappings().first()

    if not product:
        raise HTTPException(
            status_code=404,
            detail="Product not found or cannot be added to your own cart",
        )

    existing_item = db.execute(
        text("""
            SELECT cart_item_id
            FROM cart_items
            WHERE user_id = :user_id
              AND product_id = :product_id
        """),
        {
            "user_id": user_id,
            "product_id": product_id,
        },
    ).mappings().first()

    if existing_item:
        db.execute(
            text("""
                UPDATE cart_items
                SET quantity = quantity + 1
                WHERE cart_item_id = :cart_item_id
            """),
            {"cart_item_id": existing_item["cart_item_id"]},
        )
        message = "Cart quantity updated"
    else:
        db.execute(
            text("""
                INSERT INTO cart_items (user_id, product_id, quantity)
                VALUES (:user_id, :product_id, 1)
            """),
            {
                "user_id": user_id,
                "product_id": product_id,
            },
        )
        message = "Product added to cart"

    db.commit()

    return {
        "message": message,
        "product_id": product_id,
    }




@router.get("/items")
def get_cart_items(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_id = current_user.get("U_ID") or current_user.get("user_id")

    if user_id is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid user session",
        )

    rows = db.execute(
        text("""
            SELECT
                ci.cart_item_id,
                ci.product_id,
                ci.quantity,
                p.TITLE AS title,
                p.PRICE AS price,
                p.DESCRIPTION AS description,
                p.CONDITION AS `condition`,
                p.LOCATION AS location,
                (
                    SELECT pi.IMAGE_PATH
                    FROM PRODUCT_IMAGES pi
                    WHERE pi.P_ID = p.P_ID
                    ORDER BY pi.PI_ID ASC
                    LIMIT 1
                ) AS image_path
            FROM cart_items ci
            JOIN products p ON p.P_ID = ci.product_id
            WHERE ci.user_id = :user_id
            ORDER BY ci.created_at DESC
        """),
        {"user_id": user_id},
    ).mappings().all()

    return {
        "items": [dict(row) for row in rows],
    }