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
# GET ALL ATTRIBUTE DEFINITIONS
# ADMIN ONLY
# ------------------------------------------------

@router.get("/attributes")
def get_all_attribute_definitions(
    admin=Depends(require_admin)
):

    try:

        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        ATTRIBUTE_ID,
                        ATTRIBUTE_NAME,
                        ATTRIBUTE_TYPE
                    FROM CATEGORY_ATTRIBUTES
                    ORDER BY ATTRIBUTE_NAME
                """)
            )

            attributes = []

            for row in result:

                attributes.append({
                    "attribute_id": row.ATTRIBUTE_ID,
                    "attribute_name": row.ATTRIBUTE_NAME,
                    "attribute_type": row.ATTRIBUTE_TYPE
                })

            return {
                "attributes": attributes
            }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


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

            # Mark matching unsupported product as ADDED
            connection.execute(
                text("""
                    UPDATE UNSUPPORTED_PRODUCTS
                    SET
                        STATUS = 'ADDED',
                        CATEGORY_ID = :category_id,
                        UPDATED_AT = CURRENT_TIMESTAMP
                    WHERE LOWER(PRODUCT_NAME) = LOWER(:product_type_name)
                        AND STATUS = 'PENDING'
                """),
                {
                    "category_id": request.category_id,
                    "product_type_name":
                        request.product_type_name.strip()
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




# ------------------------------------------------
# CREATE ATTRIBUTE DEFINITION
# ADMIN ONLY
# ------------------------------------------------

class AttributeCreateRequest(BaseModel):
    attribute_name: str
    attribute_type: str = "TEXT"


@router.post("/{product_type_id}/attributes/create")
def create_attribute_for_product_type(
    product_type_id: int,
    request: AttributeCreateRequest,
    admin=Depends(require_admin)
):

    try:

        with engine.begin() as connection:

            # Check product type exists
            product_type_result = connection.execute(
                text("""
                    SELECT
                        PRODUCT_TYPE_ID,
                        C_ID
                    FROM PRODUCT_TYPES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                """),
                {
                    "product_type_id": product_type_id
                }
            )

            product_type = product_type_result.fetchone()

            if not product_type:
                raise HTTPException(
                    status_code=404,
                    detail="Product type not found"
                )

            # Check whether an attribute with the same name
            # already exists
            existing_attribute_result = connection.execute(
                text("""
                    SELECT
                        ATTRIBUTE_ID,
                        ATTRIBUTE_NAME,
                        ATTRIBUTE_TYPE
                    FROM CATEGORY_ATTRIBUTES
                    WHERE LOWER(ATTRIBUTE_NAME) =
                          LOWER(:attribute_name)
                """),
                {
                    "attribute_name": request.attribute_name.strip()
                }
            )

            existing_attribute = existing_attribute_result.fetchone()

            if existing_attribute:
                raise HTTPException(
                    status_code=400,
                    detail="Attribute with this name already exists"
                )

            # Create the attribute definition
            attribute_result = connection.execute(
                text("""
                    INSERT INTO CATEGORY_ATTRIBUTES
                    (
                        C_ID,
                        ATTRIBUTE_NAME,
                        ATTRIBUTE_TYPE,
                        IS_REQUIRED,
                        DISPLAY_ORDER
                    )
                    VALUES
                    (
                        :category_id,
                        :attribute_name,
                        :attribute_type,
                        0,
                        0
                    )
                """),
                {
                    "category_id": product_type.C_ID,
                    "attribute_name": request.attribute_name.strip(),
                    "attribute_type": request.attribute_type.upper()
                }
            )

            attribute_id = attribute_result.lastrowid

            # Assign the newly-created attribute
            # specifically to this product type
            connection.execute(
                text("""
                    INSERT INTO PRODUCT_TYPE_ATTRIBUTES
                    (
                        PRODUCT_TYPE_ID,
                        ATTRIBUTE_ID,
                        IS_REQUIRED,
                        DISPLAY_ORDER
                    )
                    VALUES
                    (
                        :product_type_id,
                        :attribute_id,
                        :is_required,
                        :display_order
                    )
                """),
                {
                    "product_type_id": product_type_id,
                    "attribute_id": attribute_id,
                    "is_required": False,
                    "display_order": 0
                }
            )

            return {
                "message": "Attribute created and assigned successfully",
                "product_type_id": product_type_id,
                "attribute_id": attribute_id,
                "attribute_name": request.attribute_name.strip(),
                "attribute_type": request.attribute_type.upper(),
                "is_required": False,
                "display_order": 0
            }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



# ------------------------------------------------
# ADD ATTRIBUTE TO PRODUCT TYPE
# ADMIN ONLY
# ------------------------------------------------

@router.post("/{product_type_id}/attributes")
def add_attribute_to_product_type(
    product_type_id: int,
    attribute_id: int,
    is_required: bool = False,
    display_order: int = 0,
    admin=Depends(require_admin)
):

    try:

        with engine.begin() as connection:

            # Check product type exists
            product_type_result = connection.execute(
                text("""
                    SELECT PRODUCT_TYPE_ID
                    FROM PRODUCT_TYPES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                """),
                {
                    "product_type_id": product_type_id
                }
            )

            if not product_type_result.fetchone():

                raise HTTPException(
                    status_code=404,
                    detail="Product type not found"
                )

            # Check attribute exists
            attribute_result = connection.execute(
                text("""
                    SELECT ATTRIBUTE_ID, ATTRIBUTE_NAME
                    FROM CATEGORY_ATTRIBUTES
                    WHERE ATTRIBUTE_ID = :attribute_id
                """),
                {
                    "attribute_id": attribute_id
                }
            )

            attribute = attribute_result.fetchone()

            if not attribute:

                raise HTTPException(
                    status_code=404,
                    detail="Attribute not found"
                )

            # Check duplicate mapping
            existing_result = connection.execute(
                text("""
                    SELECT PRODUCT_TYPE_ID
                    FROM PRODUCT_TYPE_ATTRIBUTES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                      AND ATTRIBUTE_ID = :attribute_id
                """),
                {
                    "product_type_id": product_type_id,
                    "attribute_id": attribute_id
                }
            )

            if existing_result.fetchone():

                raise HTTPException(
                    status_code=400,
                    detail="Attribute already assigned to this product type"
                )

            # Insert mapping
            connection.execute(
                text("""
                    INSERT INTO PRODUCT_TYPE_ATTRIBUTES
                    (
                        PRODUCT_TYPE_ID,
                        ATTRIBUTE_ID,
                        IS_REQUIRED,
                        DISPLAY_ORDER
                    )
                    VALUES
                    (
                        :product_type_id,
                        :attribute_id,
                        :is_required,
                        :display_order
                    )
                """),
                {
                    "product_type_id": product_type_id,
                    "attribute_id": attribute_id,
                    "is_required": is_required,
                    "display_order": display_order
                }
            )

            return {
                "message": "Attribute added to product type successfully",
                "product_type_id": product_type_id,
                "attribute_id": attribute_id,
                "attribute_name": attribute.ATTRIBUTE_NAME,
                "is_required": is_required,
                "display_order": display_order
            }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



@router.delete("/{product_type_id}/attributes/{attribute_id}")
def remove_attribute_from_product_type(
    product_type_id: int,
    attribute_id: int,
    admin=Depends(require_admin)
):
    try:
        with engine.begin() as connection:

            # Check that the Product Type exists
            product_type = connection.execute(
                text("""
                    SELECT PRODUCT_TYPE_ID, PRODUCT_TYPE_NAME
                    FROM PRODUCT_TYPES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                """),
                {
                    "product_type_id": product_type_id
                }
            ).fetchone()

            if not product_type:
                raise HTTPException(
                    status_code=404,
                    detail="Product type not found"
                )

            # Check that the attribute is assigned
            existing = connection.execute(
                text("""
                    SELECT PRODUCT_TYPE_ID, ATTRIBUTE_ID
                    FROM PRODUCT_TYPE_ATTRIBUTES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                      AND ATTRIBUTE_ID = :attribute_id
                """),
                {
                    "product_type_id": product_type_id,
                    "attribute_id": attribute_id
                }
            ).fetchone()

            if not existing:
                raise HTTPException(
                    status_code=404,
                    detail="Attribute is not assigned to this product type"
                )

            # Remove only the assignment
            connection.execute(
                text("""
                    DELETE FROM PRODUCT_TYPE_ATTRIBUTES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                      AND ATTRIBUTE_ID = :attribute_id
                """),
                {
                    "product_type_id": product_type_id,
                    "attribute_id": attribute_id
                }
            )

            return {
                "message": "Attribute removed from product type successfully",
                "product_type_id": product_type_id,
                "attribute_id": attribute_id
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )





# ------------------------------------------------
# GET ATTRIBUTES OF A PRODUCT TYPE
# ADMIN / PUBLIC
# ------------------------------------------------

@router.get("/{product_type_id}/attributes")
def get_product_type_attributes(
    product_type_id: int
):

    try:

        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        ca.ATTRIBUTE_ID,
                        ca.ATTRIBUTE_NAME,
                       ca.ATTRIBUTE_TYPE,
                        ca.IS_REQUIRED AS CATEGORY_REQUIRED,
                        pta.IS_REQUIRED,
                        pta.DISPLAY_ORDER
                    FROM PRODUCT_TYPE_ATTRIBUTES pta
                    JOIN CATEGORY_ATTRIBUTES ca
                        ON pta.ATTRIBUTE_ID = ca.ATTRIBUTE_ID
                    WHERE pta.PRODUCT_TYPE_ID = :product_type_id
                    ORDER BY pta.DISPLAY_ORDER,
                             ca.ATTRIBUTE_ID
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
                    "data_type": row.ATTRIBUTE_TYPE,
                    "category_required":
                        bool(row.CATEGORY_REQUIRED),
                    "is_required":
                        bool(row.IS_REQUIRED),
                    "display_order":
                        row.DISPLAY_ORDER,
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

@router.get("/{product_type_id}/available-attributes")
def get_available_product_type_attributes(
    product_type_id: int
):
    try:
        with engine.connect() as connection:

            # Get the category of this product type
            product_type = connection.execute(
                text("""
                    SELECT C_ID
                    FROM PRODUCT_TYPES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                """),
                {
                    "product_type_id": product_type_id
                }
            ).fetchone()

            if not product_type:
                raise HTTPException(
                    status_code=404,
                    detail="Product type not found"
                )

            category_id = product_type.C_ID

            # Get category attributes that are NOT
            # already assigned to this product type
            result = connection.execute(
                text("""
                    SELECT
                        ca.ATTRIBUTE_ID,
                        ca.ATTRIBUTE_NAME,
                        ca.ATTRIBUTE_TYPE,
                        ca.IS_REQUIRED,
                        ca.DISPLAY_ORDER
                    FROM CATEGORY_ATTRIBUTES ca
                    WHERE ca.C_ID = :category_id
                    AND NOT EXISTS (
                        SELECT 1
                        FROM PRODUCT_TYPE_ATTRIBUTES pta
                        JOIN CATEGORY_ATTRIBUTES assigned_ca
                            ON assigned_ca.ATTRIBUTE_ID = pta.ATTRIBUTE_ID
                        WHERE pta.PRODUCT_TYPE_ID = :product_type_id
                        AND assigned_ca.ATTRIBUTE_NAME = ca.ATTRIBUTE_NAME
                    )
                    ORDER BY
                        ca.DISPLAY_ORDER,
                        ca.ATTRIBUTE_ID
                """),
                {
                    "category_id": category_id,
                    "product_type_id": product_type_id
                }
            )

            attributes = []

            for row in result:
                attributes.append({
                    "attribute_id": row.ATTRIBUTE_ID,
                    "attribute_name": row.ATTRIBUTE_NAME,
                    "data_type": row.ATTRIBUTE_TYPE,
                    "is_required": bool(row.IS_REQUIRED),
                    "display_order": row.DISPLAY_ORDER
                })

            return {
                "product_type_id": product_type_id,
                "attributes": attributes
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )