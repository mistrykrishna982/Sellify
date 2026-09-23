from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text

from database import engine
from utils.auth import require_admin


router = APIRouter()

def record_unsupported_product(
    product_name: str,
    category_id: int | None = None
):
    product_name = product_name.strip()

    if not product_name:
        return None

    with engine.begin() as connection:

        existing = connection.execute(
            text("""
                SELECT
                    UNSUPPORTED_PRODUCT_ID,
                    REQUEST_COUNT,
                    STATUS
                FROM UNSUPPORTED_PRODUCTS
                WHERE LOWER(PRODUCT_NAME) = LOWER(:product_name)
            """),
            {
                "product_name": product_name
            }
        ).fetchone()

        if existing:

            connection.execute(
                text("""
                    UPDATE UNSUPPORTED_PRODUCTS
                    SET
                        REQUEST_COUNT = REQUEST_COUNT + 1,
                        UPDATED_AT = CURRENT_TIMESTAMP
                    WHERE UNSUPPORTED_PRODUCT_ID =
                          :unsupported_product_id
                """),
                {
                    "unsupported_product_id":
                        existing.UNSUPPORTED_PRODUCT_ID
                }
            )

            return {
                "unsupported_product_id":
                    existing.UNSUPPORTED_PRODUCT_ID,
                "product_name":
                    product_name,
                "request_count":
                    existing.REQUEST_COUNT + 1,
                "status":
                    existing.STATUS
            }

        result = connection.execute(
            text("""
                INSERT INTO UNSUPPORTED_PRODUCTS
                (
                    PRODUCT_NAME,
                    CATEGORY_ID,
                    REQUEST_COUNT,
                    STATUS
                )
                VALUES
                (
                    :product_name,
                    :category_id,
                    1,
                    'PENDING'
                )
            """),
            {
                "product_name": product_name,
                "category_id": category_id
            }
        )

        return {
            "unsupported_product_id":
                result.lastrowid,
            "product_name":
                product_name,
            "request_count": 1,
            "status": "PENDING"
        }


# ------------------------------------------------
# ADD / INCREMENT UNSUPPORTED PRODUCT
# ------------------------------------------------

@router.post("")
def add_unsupported_product(
    product_name: str,
    category_id: int | None = None
):

    product_name = product_name.strip()

    if not product_name:
        raise HTTPException(
            status_code=400,
            detail="Product name is required"
        )

    try:

        with engine.begin() as connection:

            # Check whether this unsupported product
            # already exists and is still pending
            existing = connection.execute(
                text("""
                    SELECT
                        UNSUPPORTED_PRODUCT_ID,
                        REQUEST_COUNT,
                        STATUS
                    FROM UNSUPPORTED_PRODUCTS
                    WHERE LOWER(PRODUCT_NAME) = LOWER(:product_name)
                """),
                {
                    "product_name": product_name
                }
            ).fetchone()

            # ----------------------------------------
            # PRODUCT ALREADY EXISTS
            # ----------------------------------------

            if existing:

                connection.execute(
                    text("""
                        UPDATE UNSUPPORTED_PRODUCTS
                        SET
                            REQUEST_COUNT = REQUEST_COUNT + 1,
                            UPDATED_AT = CURRENT_TIMESTAMP
                        WHERE UNSUPPORTED_PRODUCT_ID =
                              :unsupported_product_id
                    """),
                    {
                        "unsupported_product_id":
                            existing.UNSUPPORTED_PRODUCT_ID
                    }
                )

                return {
                    "message":
                        "Unsupported product request count updated",
                    "unsupported_product_id":
                        existing.UNSUPPORTED_PRODUCT_ID,
                    "product_name":
                        product_name,
                    "request_count":
                        existing.REQUEST_COUNT + 1,
                    "status":
                        existing.STATUS
                }

            # ----------------------------------------
            # NEW UNSUPPORTED PRODUCT
            # ----------------------------------------

            result = connection.execute(
                text("""
                    INSERT INTO UNSUPPORTED_PRODUCTS
                    (
                        PRODUCT_NAME,
                        CATEGORY_ID,
                        REQUEST_COUNT,
                        STATUS
                    )
                    VALUES
                    (
                        :product_name,
                        :category_id,
                        1,
                        'PENDING'
                    )
                """),
                {
                    "product_name": product_name,
                    "category_id": category_id
                }
            )

            return {
                "message":
                    "Unsupported product added",
                "unsupported_product_id":
                    result.lastrowid,
                "product_name":
                    product_name,
                "request_count": 1,
                "status": "PENDING"
            }


    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


# ------------------------------------------------
# GET PENDING UNSUPPORTED PRODUCTS
# ADMIN ONLY
# ------------------------------------------------

@router.get("")
def get_unsupported_products(
    admin=Depends(require_admin)
):

    try:

        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        up.UNSUPPORTED_PRODUCT_ID,
                        up.PRODUCT_NAME,
                        up.CATEGORY_ID,
                        c.CATEGORY_NAME,
                        up.REQUEST_COUNT,
                        up.STATUS,
                        up.CREATED_AT,
                        up.UPDATED_AT
                    FROM UNSUPPORTED_PRODUCTS up
                    LEFT JOIN CATEGORIES c
                        ON up.CATEGORY_ID = c.C_ID
                    WHERE up.STATUS = 'PENDING'
                    ORDER BY up.REQUEST_COUNT DESC,
                             up.UPDATED_AT DESC
                """)
            )

            products = []

            for row in result:

                products.append({
                    "unsupported_product_id":
                        row.UNSUPPORTED_PRODUCT_ID,
                    "product_name":
                        row.PRODUCT_NAME,
                    "category_id":
                        row.CATEGORY_ID,
                    "category_name":
                        row.CATEGORY_NAME,
                    "request_count":
                        row.REQUEST_COUNT,
                    "status":
                        row.STATUS,
                    "created_at":
                        row.CREATED_AT,
                    "updated_at":
                        row.UPDATED_AT
                })

            return {
                "unsupported_products": products
            }


    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



# ------------------------------------------------
# ADD UNSUPPORTED PRODUCT AS SUPPORTED PRODUCT TYPE
# ADMIN ONLY
# ------------------------------------------------

@router.post("/{unsupported_product_id}/add")
def add_unsupported_product_as_product_type(
    unsupported_product_id: int,
    category_id: int,
    admin=Depends(require_admin)
):
    try:

        with engine.begin() as connection:

            # ----------------------------------------
            # GET UNSUPPORTED PRODUCT
            # ----------------------------------------

            unsupported = connection.execute(
                text("""
                    SELECT
                        UNSUPPORTED_PRODUCT_ID,
                        PRODUCT_NAME,
                        CATEGORY_ID,
                        STATUS
                    FROM UNSUPPORTED_PRODUCTS
                    WHERE UNSUPPORTED_PRODUCT_ID =
                          :unsupported_product_id
                """),
                {
                    "unsupported_product_id":
                        unsupported_product_id
                }
            ).fetchone()

            if not unsupported:
                raise HTTPException(
                    status_code=404,
                    detail="Unsupported product not found"
                )

            product_name = unsupported.PRODUCT_NAME

            # ----------------------------------------
            # CHECK CATEGORY
            # ----------------------------------------

            category = connection.execute(
                text("""
                    SELECT
                        C_ID,
                        CATEGORY_NAME
                    FROM CATEGORIES
                    WHERE C_ID = :category_id
                """),
                {
                    "category_id": category_id
                }
            ).fetchone()

            if not category:
                raise HTTPException(
                    status_code=404,
                    detail="Category not found"
                )

            # ----------------------------------------
            # CHECK WHETHER PRODUCT TYPE ALREADY EXISTS
            # IN THE SELECTED CATEGORY
            # ----------------------------------------

            existing_product_type = connection.execute(
                text("""
                    SELECT
                        PRODUCT_TYPE_ID,
                        PRODUCT_TYPE_NAME,
                        C_ID
                    FROM PRODUCT_TYPES
                    WHERE LOWER(PRODUCT_TYPE_NAME) =
                          LOWER(:product_name)
                      AND C_ID = :category_id
                    LIMIT 1
                """),
                {
                    "product_name": product_name,
                    "category_id": category_id
                }
            ).fetchone()

            # ----------------------------------------
            # PRODUCT TYPE ALREADY EXISTS
            # ----------------------------------------

            if existing_product_type:

                connection.execute(
                    text("""
                        UPDATE UNSUPPORTED_PRODUCTS
                        SET
                            STATUS = 'ADDED',
                            CATEGORY_ID = :category_id,
                            UPDATED_AT = CURRENT_TIMESTAMP
                        WHERE UNSUPPORTED_PRODUCT_ID =
                              :unsupported_product_id
                    """),
                    {
                        "unsupported_product_id":
                            unsupported_product_id,
                        "category_id":
                            category_id
                    }
                )

                return {
                    "message":
                        "Product type already exists. Unsupported product marked as added.",
                    "unsupported_product_id":
                        unsupported_product_id,
                    "product_type_id":
                        existing_product_type.PRODUCT_TYPE_ID,
                    "product_type_name":
                        existing_product_type.PRODUCT_TYPE_NAME,
                    "category_id":
                        existing_product_type.C_ID,
                    "category_name":
                        category.CATEGORY_NAME,
                    "created": False,
                    "status": "ADDED"
                }

            # ----------------------------------------
            # CREATE NEW PRODUCT TYPE
            # ----------------------------------------

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
                        :product_name,
                        :ai_description
                    )
                """),
                {
                    "category_id":
                        category_id,
                    "product_name":
                        product_name,
                    "ai_description":
                        "Product type detected from unsupported product requests."
                }
            )

            product_type_id = result.lastrowid

            # ----------------------------------------
            # MARK UNSUPPORTED PRODUCT AS ADDED
            # ----------------------------------------

            connection.execute(
                text("""
                    UPDATE UNSUPPORTED_PRODUCTS
                    SET
                        STATUS = 'ADDED',
                        CATEGORY_ID = :category_id,
                        UPDATED_AT = CURRENT_TIMESTAMP
                    WHERE UNSUPPORTED_PRODUCT_ID =
                          :unsupported_product_id
                """),
                {
                    "unsupported_product_id":
                        unsupported_product_id,
                    "category_id":
                        category_id
                }
            )

            return {
                "message":
                    "Unsupported product added successfully",
                "unsupported_product_id":
                    unsupported_product_id,
                "product_type_id":
                    product_type_id,
                "product_type_name":
                    product_name,
                "category_id":
                    category_id,
                "category_name":
                    category.CATEGORY_NAME,
                "created": True,
                "status": "ADDED"
            }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )