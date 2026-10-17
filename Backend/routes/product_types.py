from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from pydantic import BaseModel

from database import engine
from utils.auth import require_admin


router = APIRouter()





class ProductTypeCreateRequest(BaseModel):
    product_type_name: str
    category_id: int
    ai_description: str | None = None



# ------------------------------------------------
# GET ALL PRODUCT TYPES
# ------------------------------------------------

@router.get("")
def get_product_types(
    category_id: int | None = None
):

    try:
        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        pt.PRODUCT_TYPE_ID,
                        pt.PRODUCT_TYPE_NAME,
                        pt.AI_DESCRIPTION,
                        pt.C_ID,
                        c.CATEGORY_NAME
                    FROM PRODUCT_TYPES pt
                    JOIN CATEGORIES c
                        ON pt.C_ID = c.C_ID
                    WHERE (
                        :category_id IS NULL
                        OR pt.C_ID = :category_id
                    )
                    ORDER BY pt.PRODUCT_TYPE_ID
                """),
                {
                    "category_id": category_id
                }
            )

            product_types = []

            for row in result:

                product_types.append({
                    "product_type_id": row.PRODUCT_TYPE_ID,
                    "product_type_name": row.PRODUCT_TYPE_NAME,
                    "ai_description": row.AI_DESCRIPTION,
                    "category_id": row.C_ID,
                    "category_name": row.CATEGORY_NAME,
                })

            return {
                "product_types": product_types
            }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


# ------------------------------------------------
# CREATE PRODUCT TYPE
# ADMIN ONLY
# ------------------------------------------------

@router.post("")
def create_product_type(
    request: ProductTypeCreateRequest,
    admin=Depends(require_admin)
):

    try:

        with engine.begin() as connection:

            # Check category exists
            category_result = connection.execute(
                text("""
                    SELECT C_ID, CATEGORY_NAME
                    FROM CATEGORIES
                    WHERE C_ID = :category_id
                """),
                {
                    "category_id": request.category_id
                }
            )

            category = category_result.fetchone()

            if not category:

                raise HTTPException(
                    status_code=404,
                    detail="Category not found"
                )


            # Check duplicate product type
            existing_result = connection.execute(
                text("""
                    SELECT PRODUCT_TYPE_ID
                    FROM PRODUCT_TYPES
                    WHERE PRODUCT_TYPE_NAME = :product_type_name
                      AND C_ID = :category_id
                """),
                {
                    "product_type_name": request.product_type_name,
                    "category_id": request.category_id
                }
            )

            existing = existing_result.fetchone()

            if existing:

                raise HTTPException(
                    status_code=400,
                    detail="Product type already exists"
                )


            # Insert product type
            result = connection.execute(
                text("""
                    INSERT INTO PRODUCT_TYPES
                    (
                        C_ID,
                        PRODUCT_TYPE_NAME,
                        AI_DESCRIPTION
                    )
                    VALUES
                    (
                        :category_id,
                        :product_type_name,
                        :ai_description
                    )
                """),
                {
                    "category_id": request.category_id,
                    "product_type_name":
                        request.product_type_name,
                    "ai_description":
                        request.ai_description
                }
            )

            return {
                "message": "Product type created successfully",
                "product_type_id": result.lastrowid,
                "product_type_name":
                    request.product_type_name,
                "category_id":
                    request.category_id,
                "category_name":
                    category.CATEGORY_NAME
            }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
