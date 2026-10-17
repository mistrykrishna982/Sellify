
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import SessionLocal
from auth import get_current_user

router = APIRouter(
    prefix="/favorites",
    tags=["Favorites"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_user_id(current_user: dict) -> int:
    user_id = current_user.get("U_ID") or current_user.get("user_id")

    if user_id is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid user session",
        )

    return user_id


@router.post("/{product_id}")
def add_favorite(
    product_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_id = get_user_id(current_user)

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
    ).first()

    if not product:
        raise HTTPException(
            status_code=404,
            detail="Product not found or cannot favorite your own product",
        )

    db.execute(
        text("""
            INSERT IGNORE INTO favorites (user_id, product_id)
            VALUES (:user_id, :product_id)
        """),
        {
            "user_id": user_id,
            "product_id": product_id,
        },
    )

    db.commit()

    return {
        "message": "Product added to favorites",
        "product_id": product_id,
    }


@router.delete("/{product_id}")
def remove_favorite(
    product_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_id = get_user_id(current_user)

    db.execute(
        text("""
            DELETE FROM favorites
            WHERE user_id = :user_id
              AND product_id = :product_id
        """),
        {
            "user_id": user_id,
            "product_id": product_id,
        },
    )

    db.commit()

    return {
        "message": "Product removed from favorites",
        "product_id": product_id,
    }


@router.get("")
def get_favorites(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_id = get_user_id(current_user)

    rows = db.execute(
        text("""
            SELECT
                p.P_ID AS product_id,
                p.TITLE AS title,
                p.PRICE AS price,
                p.DESCRIPTION AS description,
                p.CONDITION AS `condition`,
                p.LOCATION AS location,
                p.C_ID AS category_id,
                p.PRODUCT_TYPE AS category
            FROM favorites f
            JOIN products p ON p.P_ID = f.product_id
            WHERE f.user_id = :user_id
              AND p.STATUS = 'ACTIVE'
            ORDER BY f.created_at DESC
        """),
        {"user_id": user_id},
    ).mappings().all()

    return {
        "items": [dict(row) for row in rows],
    }
