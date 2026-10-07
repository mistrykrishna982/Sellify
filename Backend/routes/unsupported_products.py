from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import text

from database import engine
from utils.auth import require_admin, get_current_user

router = APIRouter()

class UnsupportedProductRequest(BaseModel):
    product_name: str
    category_name: str







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
# USER REQUEST FOR UNSUPPORTED PRODUCT
# ------------------------------------------------

@router.post("/request")
def request_unsupported_product(
    request: UnsupportedProductRequest,
    user=Depends(get_current_user)
):

    product_name = request.product_name.strip()
    category_name = request.category_name.strip()

    if not product_name:
        raise HTTPException(
            status_code=400,
            detail="Product name is required"
        )

    if not category_name:
        raise HTTPException(
            status_code=400,
            detail="Category name is required"
        )

    user_id = user.get("user_id")

    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="User information not found"
        )

    try:

        with engine.begin() as connection:

            # ----------------------------------------
            # CHECK WHETHER SAME USER ALREADY HAS
            # THE SAME PENDING REQUEST
            # ----------------------------------------

            existing = connection.execute(
                text("""
                    SELECT
                        UNSUPPORTED_PRODUCT_ID,
                        REQUEST_COUNT,
                        STATUS
                    FROM UNSUPPORTED_PRODUCTS
                    WHERE U_ID = :user_id
                      AND LOWER(PRODUCT_NAME) =
                          LOWER(:product_name)
                      AND LOWER(REQUESTED_CATEGORY_NAME) =
                          LOWER(:category_name)
                      AND STATUS = 'PENDING'
                    LIMIT 1
                """),
                {
                    "user_id": user_id,
                    "product_name": product_name,
                    "category_name": category_name
                }
            ).fetchone()

            # ----------------------------------------
            # SAME REQUEST ALREADY EXISTS
            # ----------------------------------------

            if existing:

                connection.execute(
                    text("""
                        UPDATE UNSUPPORTED_PRODUCTS
                        SET
                            REQUEST_COUNT =
                                REQUEST_COUNT + 1,
                            UPDATED_AT =
                                CURRENT_TIMESTAMP
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
                        "Product request already exists",
                    "unsupported_product_id":
                        existing.UNSUPPORTED_PRODUCT_ID,
                    "product_name":
                        product_name,
                    "category_name":
                        category_name,
                    "request_count":
                        existing.REQUEST_COUNT + 1,
                    "status":
                        existing.STATUS
                }

            # ----------------------------------------
            # CREATE NEW REQUEST
            # ----------------------------------------

            result = connection.execute(
                text("""
                    INSERT INTO UNSUPPORTED_PRODUCTS
                    (
                        U_ID,
                        PRODUCT_NAME,
                        REQUESTED_CATEGORY_NAME,
                        CATEGORY_ID,
                        ADMIN_ID,
                        PRODUCT_TYPE_ID,
                        REQUEST_COUNT,
                        STATUS
                    )
                    VALUES
                    (
                        :user_id,
                        :product_name,
                        :category_name,
                        NULL,
                        NULL,
                        NULL,
                        1,
                        'PENDING'
                    )
                """),
                {
                    "user_id": user_id,
                    "product_name": product_name,
                    "category_name": category_name
                }
            )

            return {
                "message":
                    "Product request submitted successfully",
                "unsupported_product_id":
                    result.lastrowid,
                "product_name":
                    product_name,
                "category_name":
                    category_name,
                "request_count": 1,
                "status": "PENDING"
            }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )




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
# GET PENDING UNSUPPORTED PRODUCT REQUESTS
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
                        up.U_ID,
                        u.U_NAME,
                        up.PRODUCT_NAME,
                        up.REQUESTED_CATEGORY_NAME,
                        up.CATEGORY_ID,
                        c.CATEGORY_NAME,
                        up.ADMIN_ID,
                        up.PRODUCT_TYPE_ID,
                        up.REQUEST_COUNT,
                        up.STATUS,
                        up.CREATED_AT,
                        up.UPDATED_AT,
                        up.APPROVED_AT
                    FROM UNSUPPORTED_PRODUCTS up

                    LEFT JOIN USERS u
                        ON up.U_ID = u.U_ID

                    LEFT JOIN CATEGORIES c
                        ON up.CATEGORY_ID = c.C_ID

                    WHERE up.STATUS = 'PENDING'

                    ORDER BY
                        up.CREATED_AT DESC
                """)
            )

            products = []

            for row in result:

                products.append({
                    "unsupported_product_id":
                        row.UNSUPPORTED_PRODUCT_ID,

                    "user_id":
                        row.U_ID,

                    "user_name":
                        row.U_NAME,

                    "product_name":
                        row.PRODUCT_NAME,

                    "requested_category_name":
                        row.REQUESTED_CATEGORY_NAME,

                    "category_id":
                        row.CATEGORY_ID,

                    "category_name":
                        row.CATEGORY_NAME,

                    "admin_id":
                        row.ADMIN_ID,

                    "product_type_id":
                        row.PRODUCT_TYPE_ID,

                    "request_count":
                        row.REQUEST_COUNT,

                    "status":
                        row.STATUS,

                    "created_at":
                        row.CREATED_AT,

                    "updated_at":
                        row.UPDATED_AT,

                    "approved_at":
                        row.APPROVED_AT
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


# ------------------------------------------------
# APPROVE UNSUPPORTED PRODUCT REQUEST
# ADMIN ONLY
# ------------------------------------------------

@router.post("/{unsupported_product_id}/approve")
def approve_unsupported_product(
    unsupported_product_id: int,
    admin=Depends(require_admin)
):
    try:
        admin_id = admin.get("user_id")

        if not admin_id:
            raise HTTPException(
                status_code=401,
                detail="Admin information not found"
            )

        with engine.begin() as connection:

            # ----------------------------------------
            # 1. GET UNSUPPORTED PRODUCT REQUEST
            # ----------------------------------------

            unsupported = connection.execute(
                text("""
                    SELECT
                        UNSUPPORTED_PRODUCT_ID,
                        U_ID,
                        PRODUCT_NAME,
                        REQUESTED_CATEGORY_NAME,
                        CATEGORY_ID,
                        PRODUCT_TYPE_ID,
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
                    detail="Unsupported product request not found"
                )

            if unsupported.STATUS != "PENDING":
                raise HTTPException(
                    status_code=400,
                    detail="Only pending requests can be approved"
                )

            product_name = unsupported.PRODUCT_NAME.strip()
            requested_category_name = (
                unsupported.REQUESTED_CATEGORY_NAME or ""
            ).strip()

            if not requested_category_name:
                raise HTTPException(
                    status_code=400,
                    detail="Requested category name is missing"
                )

            # ----------------------------------------
            # 2. CHECK CATEGORY
            # ----------------------------------------

            category = connection.execute(
                text("""
                    SELECT
                        C_ID,
                        CATEGORY_NAME
                    FROM CATEGORIES
                    WHERE LOWER(CATEGORY_NAME) =
                          LOWER(:category_name)
                    LIMIT 1
                """),
                {
                    "category_name":
                        requested_category_name
                }
            ).fetchone()

            # ----------------------------------------
            # 3. CREATE CATEGORY IF IT DOES NOT EXIST
            # ----------------------------------------

            if not category:

                category_result = connection.execute(
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
                        "category_name":
                            requested_category_name
                    }
                )

                category_id = category_result.lastrowid
                category_name = requested_category_name

            else:

                category_id = category.C_ID
                category_name = category.CATEGORY_NAME

            # ----------------------------------------
            # 4. CHECK PRODUCT TYPE
            # ----------------------------------------

            product_type = connection.execute(
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
            # 5. CREATE PRODUCT TYPE IF NEEDED
            # ----------------------------------------

            if not product_type:

                product_type_result = connection.execute(
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
                            "Product type created from an approved user request."
                    }
                )

                product_type_id = (
                    product_type_result.lastrowid
                )

                product_type_name = product_name

            else:

                product_type_id = (
                    product_type.PRODUCT_TYPE_ID
                )

                product_type_name = (
                    product_type.PRODUCT_TYPE_NAME
                )

            # ----------------------------------------
            # 6. UPDATE UNSUPPORTED PRODUCT REQUEST
            # ----------------------------------------

            connection.execute(
                text("""
                    UPDATE UNSUPPORTED_PRODUCTS
                    SET
                        CATEGORY_ID = :category_id,
                        PRODUCT_TYPE_ID = :product_type_id,
                        ADMIN_ID = :admin_id,
                        STATUS = 'APPROVED',
                        APPROVED_AT = CURRENT_TIMESTAMP,
                        UPDATED_AT = CURRENT_TIMESTAMP
                    WHERE UNSUPPORTED_PRODUCT_ID =
                          :unsupported_product_id
                """),
                {
                    "category_id":
                        category_id,
                    "product_type_id":
                        product_type_id,
                    "admin_id":
                        admin_id,
                    "unsupported_product_id":
                        unsupported_product_id
                }
            )

            # ----------------------------------------
            # 7. RETURN APPROVAL RESULT
            # ----------------------------------------

            return {
                "message":
                    "Unsupported product request approved successfully",
                "unsupported_product_id":
                    unsupported_product_id,
                "product_name":
                    product_name,
                "category_id":
                    category_id,
                "category_name":
                    category_name,
                "product_type_id":
                    product_type_id,
                "product_type_name":
                    product_type_name,
                "admin_id":
                    admin_id,
                "status":
                    "APPROVED"
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
