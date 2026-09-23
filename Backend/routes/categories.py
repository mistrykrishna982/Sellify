from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import text
from database import engine
from utils.auth import require_admin

router = APIRouter(
    prefix="/categories",
    tags=["Categories"]
)


class CategoryCreate(BaseModel):
    category_name: str


@router.post("")
def create_category(
    category: CategoryCreate,
    admin=Depends(require_admin)
):
    try:
        category_name = category.category_name.strip()

        if not category_name:
            raise HTTPException(
                status_code=400,
                detail="Category name cannot be empty"
            )

        with engine.begin() as connection:

            # Check whether category already exists
            existing = connection.execute(
                text("""
                    SELECT
                        C_ID,
                        CATEGORY_NAME
                    FROM CATEGORIES
                    WHERE LOWER(CATEGORY_NAME) = LOWER(:category_name)
                    LIMIT 1
                """),
                {
                    "category_name": category_name
                }
            ).fetchone()

            if existing:
                raise HTTPException(
                    status_code=409,
                    detail="Category already exists"
                )

            # Create category
            result = connection.execute(
                text("""
                    INSERT INTO CATEGORIES (CATEGORY_NAME)
                    VALUES (:category_name)
                """),
                {
                    "category_name": category_name
                }
            )

            return {
                "message": "Category created successfully",
                "category_id": result.lastrowid,
                "category_name": category_name
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )




@router.get("")
def get_categories():

    try:
        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        C_ID,
                        CATEGORY_NAME
                    FROM CATEGORIES
                    ORDER BY C_ID
                """)
            )

            categories = []

            for row in result:
                categories.append({
                    "category_id": row.C_ID,
                    "category_name": row.CATEGORY_NAME
                })

            return {
                "categories": categories
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.get("/{category_id}/attributes")
def get_category_attributes(category_id: int):

    try:
        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        ATTRIBUTE_ID,
                        ATTRIBUTE_NAME,
                        ATTRIBUTE_TYPE,
                        IS_REQUIRED,
                        DISPLAY_ORDER
                    FROM CATEGORY_ATTRIBUTES
                    WHERE C_ID = :category_id
                    ORDER BY DISPLAY_ORDER
                """),
                {
                    "category_id": category_id
                }
            )

            attributes = []

            for row in result:
                attributes.append({
                    "attribute_id": row.ATTRIBUTE_ID,
                    "attribute_name": row.ATTRIBUTE_NAME,
                    "attribute_type": row.ATTRIBUTE_TYPE,
                    "is_required": bool(row.IS_REQUIRED),
                    "display_order": row.DISPLAY_ORDER
                })

            return {
                "category_id": category_id,
                "attributes": attributes
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



@router.get("/product-types/{product_type_id}/attributes")
def get_product_type_attributes(product_type_id: int):

    try:
        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        ca.ATTRIBUTE_ID,
                        ca.ATTRIBUTE_NAME,
                        ca.ATTRIBUTE_TYPE,
                        pta.IS_REQUIRED,
                        pta.DISPLAY_ORDER
                    FROM PRODUCT_TYPE_ATTRIBUTES pta
                    JOIN CATEGORY_ATTRIBUTES ca
                        ON pta.ATTRIBUTE_ID = ca.ATTRIBUTE_ID
                    WHERE pta.PRODUCT_TYPE_ID = :product_type_id
                    ORDER BY pta.DISPLAY_ORDER, ca.ATTRIBUTE_ID
                """),
                {
                    "product_type_id": product_type_id
                }
            )

            attributes = []

            for row in result:
                attributes.append({
                    "attribute_id": row.ATTRIBUTE_ID,
                    "attribute_name": row.ATTRIBUTE_NAME,
                    "attribute_type": row.ATTRIBUTE_TYPE,
                    "is_required": bool(row.IS_REQUIRED),
                    "display_order": row.DISPLAY_ORDER
                })

            return {
                "product_type_id": product_type_id,
                "attributes": attributes
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )