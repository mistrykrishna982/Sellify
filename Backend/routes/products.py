from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from pathlib import Path
import shutil
import uuid

from pydantic import BaseModel, Field
from sqlalchemy import text

from database import engine
from services.ai_service import analyze_product_image
from services.price_service import predict_price
from auth import get_current_user

class PricePredictionRequest(BaseModel):
    category: str
    product_type: str
    title: str = ""
    age: str = ""
    description: str = ""
    condition: str

class ResolveProductClassificationRequest(BaseModel):
    category: str = Field(..., min_length=1, max_length=100)
    product_type: str = Field(..., min_length=1, max_length=100)


class UpdateProductRequest(BaseModel):
    title: str
    description: str
    condition: str
    price: float
    ai_price: float | None = None
    location: str


class CreateProductRequest(BaseModel):
    category_id: int
    product_type_id: int
    title: str
    description: str
    condition: str
    price: float
    ai_price: float | None = None
    location: str
    image_path: str
    ai_product_name: str | None = None
    ai_confidence: float | None = None
    attributes: dict[int, str] = Field(default_factory=dict)


router = APIRouter(
    prefix="/products",
    tags=["Products"]
)


# Backend root folder
BASE_DIR = Path(__file__).resolve().parent.parent


# Product image upload folder
UPLOAD_DIR = BASE_DIR / "uploads" / "products"

UPLOAD_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ---------------------------------------------------
# API 1: Upload Product Image
# ---------------------------------------------------

@router.post("/upload-image")
async def upload_product_image(
    file: UploadFile = File(...)
):

    try:

        allowed_extensions = [
            ".jpg",
            ".jpeg",
            ".png",
            ".webp",
            ".heic",
            ".heif"
        ]

        extension = Path(file.filename).suffix.lower()

        if extension not in allowed_extensions:

            raise HTTPException(
                status_code=400,
                detail="Only JPG, JPEG, PNG, WEBP, HEIC and HEIF images are allowed"
            )


        filename = f"{uuid.uuid4()}{extension}"

        file_path = UPLOAD_DIR / filename


        with file_path.open("wb") as buffer:

            shutil.copyfileobj(
                file.file,
                buffer
            )


        return {

            "message": "Image uploaded successfully",

            "filename": filename,

            "image_path": str(
                file_path.relative_to(BASE_DIR)
            )
        }


    except HTTPException:

        raise


    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


# ---------------------------------------------------
# API 2: Analyze Product Image Using AI
# ---------------------------------------------------

@router.post("/analyze")
async def analyze_product(
    file: UploadFile = File(...)
):

    try:

        allowed_extensions = [
            ".jpg",
            ".jpeg",
            ".png",
            ".webp",
            ".heic",
            ".heif"
        ]

        extension = Path(file.filename).suffix.lower()


        if extension not in allowed_extensions:

            raise HTTPException(
                status_code=400,
                detail="Only JPG, JPEG, PNG, WEBP, HEIC and HEIF images are allowed"
            )


        # Create unique filename
        filename = f"{uuid.uuid4()}{extension}"


        # Full path where image will be saved
        file_path = UPLOAD_DIR / filename


        # Save image
        with file_path.open("wb") as buffer:

            shutil.copyfileobj(
                file.file,
                buffer
            )


        # Run AI analysis
        ai_result = analyze_product_image(
            str(file_path)
        )
        


        return {

    "message": "AI analysis completed successfully",

    "filename": filename,

    "image_path": str(
        file_path.relative_to(BASE_DIR)
    ),

    "product_type": ai_result["product_type"],

    "product_type_id": ai_result["product_type_id"],

    "category": ai_result["category"],

    "category_id": ai_result["category_id"],

    "confidence": ai_result["confidence"],

     "supported": ai_result["supported"],

    "unsupported_product_name":
        ai_result["unsupported_product_name"],

    "predictions": ai_result["predictions"]

}


    except HTTPException:

        raise


    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



# ============================================================
# API: Resolve / Create Category and Product Type
# ============================================================

@router.post("/resolve-classification")
def resolve_product_classification(
    request: ResolveProductClassificationRequest,
    current_user=Depends(get_current_user)
):

    try:

        # ----------------------------------------------------
        # Clean user input
        # ----------------------------------------------------

        category_name = request.category.strip()
        product_type_name = request.product_type.strip()

        if not category_name:
            raise HTTPException(
                status_code=400,
                detail="Category is required"
            )

        if not product_type_name:
            raise HTTPException(
                status_code=400,
                detail="Product type is required"
            )

        # ----------------------------------------------------
        # Start database transaction
        # ----------------------------------------------------

        with engine.begin() as connection:

            # =================================================
            # 1. FIND CATEGORY
            # =================================================

            category_result = connection.execute(
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
                    "category_name": category_name
                }
            )

            category = category_result.fetchone()

            # =================================================
            # 2. CREATE CATEGORY IF IT DOES NOT EXIST
            # =================================================

            if not category:

                connection.execute(
                    text("""
                        INSERT INTO CATEGORIES
                        (
                            CATEGORY_NAME,
                            AI_DESCRIPTION
                        )
                        VALUES
                        (
                            :category_name,
                            NULL
                        )
                    """),
                    {
                        "category_name": category_name
                    }
                )

                # Get newly created category
                category_result = connection.execute(
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
                        "category_name": category_name
                    }
                )

                category = category_result.fetchone()

            if not category:
                raise HTTPException(
                    status_code=500,
                    detail="Failed to create category"
                )

            category_id = int(category.C_ID)
            final_category_name = str(
                category.CATEGORY_NAME
            )

            # =================================================
            # 3. FIND PRODUCT TYPE INSIDE CATEGORY
            # =================================================

            product_type_result = connection.execute(
                text("""
                    SELECT
                        PRODUCT_TYPE_ID,
                        PRODUCT_TYPE_NAME
                    FROM PRODUCT_TYPES
                    WHERE C_ID = :category_id
                      AND LOWER(PRODUCT_TYPE_NAME) =
                          LOWER(:product_type_name)
                    LIMIT 1
                """),
                {
                    "category_id": category_id,
                    "product_type_name": product_type_name
                }
            )

            product_type = (
                product_type_result.fetchone()
            )

            # =================================================
            # 4. CREATE PRODUCT TYPE IF IT DOES NOT EXIST
            # =================================================

            if not product_type:

                connection.execute(
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
                            NULL
                        )
                    """),
                    {
                        "category_id": category_id,
                        "product_type_name": product_type_name
                    }
                )

                # Get newly created product type
                product_type_result = connection.execute(
                    text("""
                        SELECT
                            PRODUCT_TYPE_ID,
                            PRODUCT_TYPE_NAME
                        FROM PRODUCT_TYPES
                        WHERE C_ID = :category_id
                          AND LOWER(PRODUCT_TYPE_NAME) =
                              LOWER(:product_type_name)
                        LIMIT 1
                    """),
                    {
                        "category_id": category_id,
                        "product_type_name": product_type_name
                    }
                )

                product_type = (
                    product_type_result.fetchone()
                )

            if not product_type:
                raise HTTPException(
                    status_code=500,
                    detail="Failed to create product type"
                )

            product_type_id = int(
                product_type.PRODUCT_TYPE_ID
            )

            final_product_type_name = str(
                product_type.PRODUCT_TYPE_NAME
            )

        # =====================================================
        # RETURN CLASSIFICATION
        # =====================================================

        return {
            "category_id": category_id,
            "category": final_category_name,

            "product_type_id": product_type_id,
            "product_type": final_product_type_name,
        }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )




@router.post("/predict-price")
def predict_product_price(
    request: PricePredictionRequest,
):
    predicted_price = predict_price(
        category=request.category,
        product_type=request.product_type,
        title=request.title,
        description=request.description,
        age=request.age,
        condition=request.condition,
    )

    return {
        "ai_price": predicted_price,
    }



# ---------------------------------------------------
# API 4: Create Final Product Listing
# ---------------------------------------------------

@router.post("/create")
def create_product(
    data: CreateProductRequest,
    current_user=Depends(get_current_user)
):

    try:

        # ------------------------------------------------
        # Get user ID from JWT
        # ------------------------------------------------

        user_id = current_user["user_id"]


        # ------------------------------------------------
        # Validate image path
        # ------------------------------------------------

        if not data.image_path:

            raise HTTPException(
                status_code=400,
                detail="Product image is required"
            )


        # ------------------------------------------------
        # Start database transaction
        # ------------------------------------------------

        with engine.begin() as connection:

            # --------------------------------------------
            # Check user exists
            # --------------------------------------------

            user_result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE U_ID = :user_id
                """),
                {
                    "user_id": user_id
                }
            )

            user = user_result.fetchone()

            if not user:

                raise HTTPException(
                    status_code=404,
                    detail="User not found"
                )


            # --------------------------------------------
            # Check category exists
            # --------------------------------------------

            category_result = connection.execute(
                text("""
                    SELECT C_ID
                    FROM CATEGORIES
                    WHERE C_ID = :category_id
                """),
                {
                    "category_id": data.category_id
                }
            )

            category = category_result.fetchone()

            if not category:

                raise HTTPException(
                    status_code=404,
                    detail="Category not found"
                )


            # --------------------------------------------
            # Check product type belongs to category
            # --------------------------------------------

            product_type_result = connection.execute(
                text("""
                    SELECT PRODUCT_TYPE_ID
                    FROM PRODUCT_TYPES
                    WHERE PRODUCT_TYPE_ID = :product_type_id
                      AND C_ID = :category_id
                """),
                {
                    "product_type_id": data.product_type_id,
                    "category_id": data.category_id
                }
            )

            product_type = product_type_result.fetchone()

            if not product_type:

                raise HTTPException(
                    status_code=400,
                    detail="Selected product type does not belong to selected category"
                )


            # --------------------------------------------
            # Insert product
            # --------------------------------------------

            product_result = connection.execute(
                text("""
                    INSERT INTO PRODUCTS
                    (
                        U_ID,
                        C_ID,
                        PRODUCT_TYPE_ID,
                        TITLE,
                        DESCRIPTION,
                        `CONDITION`,
                        PRICE,
                        AI_PRICE,
                        LOCATION,
                        AI_CONFIDENCE,
                        AI_ANALYZED,
                        AI_PRODUCT_NAME,
                        STATUS
                    )
                    VALUES
                    (
                        :user_id,
                        :category_id,
                        :product_type_id,
                        :title,
                        :description,
                        :condition,
                        :price,
                        :ai_price,
                        :location,
                        :ai_confidence,
                        :ai_analyzed,
                        :ai_product_name,
                        'ACTIVE'
                    )
                """),
                {
                    "user_id": user_id,

                    "category_id": data.category_id,

                    "product_type_id": data.product_type_id,

                    "title": data.title,

                    "description": data.description,

                    "condition": data.condition,

                    "price": data.price,

                    "ai_price": data.ai_price,

                    "location": data.location,

                    "ai_confidence": data.ai_confidence,

                    "ai_analyzed": 1,

                    "ai_product_name": data.ai_product_name
                }
            )


            # --------------------------------------------
            # Get new product ID
            # --------------------------------------------

            product_id = product_result.lastrowid


            # --------------------------------------------
            # Save product image
            # --------------------------------------------

            connection.execute(
                text("""
                    INSERT INTO PRODUCT_IMAGES
                    (
                        P_ID,
                        IMAGE_PATH
                    )
                    VALUES
                    (
                        :product_id,
                        :image_path
                    )
                """),
                {
                    "product_id": product_id,

                    "image_path": data.image_path
                }
            )


            # --------------------------------------------
            # Save dynamic attributes
            # --------------------------------------------

            for attribute_id, attribute_value in data.attributes.items():

                if not attribute_value:
                    continue


                # ----------------------------------------
                # Check attribute belongs to product type
                # ----------------------------------------

                attribute_result = connection.execute(
                    text("""
                        SELECT ATTRIBUTE_ID
                        FROM PRODUCT_TYPE_ATTRIBUTES
                        WHERE PRODUCT_TYPE_ID = :product_type_id
                          AND ATTRIBUTE_ID = :attribute_id
                    """),
                    {
                        "product_type_id": data.product_type_id,

                        "attribute_id": attribute_id
                    }
                )

                attribute = attribute_result.fetchone()

                if not attribute:

                    raise HTTPException(
                        status_code=400,
                        detail=(
                            f"Invalid attribute {attribute_id} "
                            "for selected product type"
                        )
                    )


                # ----------------------------------------
                # Save attribute value
                # ----------------------------------------

                connection.execute(
                    text("""
                        INSERT INTO PRODUCT_ATTRIBUTE_VALUES
                        (
                            P_ID,
                            ATTRIBUTE_ID,
                            ATTRIBUTE_VALUE
                        )
                        VALUES
                        (
                            :product_id,
                            :attribute_id,
                            :attribute_value
                        )
                    """),
                    {
                        "product_id": product_id,

                        "attribute_id": attribute_id,

                        "attribute_value": attribute_value
                    }
                )


        # ------------------------------------------------
        # Transaction completed
        # ------------------------------------------------

        return {

            "message": "Product listed successfully",

            "product_id": product_id,

            "price": data.price,

            "ai_price": data.ai_price,

            "status": "ACTIVE"
        }


    except HTTPException:

        raise


    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    

@router.get("")
def get_products(user_id: int):
    try:
        with engine.connect() as connection:
            result = connection.execute(
                text("""
                    SELECT
                        p.P_ID,
                        p.TITLE,
                        p.DESCRIPTION,
                        p.`CONDITION`,
                        p.PRICE,
                        p.AI_PRICE,
                        p.LOCATION,
                        c.CATEGORY_NAME,
                        pi.IMAGE_PATH
                    FROM PRODUCTS p
                    INNER JOIN CATEGORIES c
                        ON p.C_ID = c.C_ID
                    LEFT JOIN PRODUCT_IMAGES pi
                        ON p.P_ID = pi.P_ID
                    WHERE p.STATUS = 'ACTIVE'
                      AND p.U_ID != :user_id
                    ORDER BY p.CREATED_AT DESC
                """),
                {
                    "user_id": user_id
                }
            )

            products = []

            for row in result:
                products.append({
                    "product_id": row.P_ID,
                    "title": row.TITLE,
                    "description": row.DESCRIPTION,
                    "condition": row.CONDITION,
                    "price": float(row.PRICE),
                    "ai_price": float(row.AI_PRICE),
                    "location": row.LOCATION,
                    "category": row.CATEGORY_NAME,
                    "image_path": row.IMAGE_PATH
                })

            return {
                "products": products
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



# ---------------------------------------------------
# API: Update Product
# ---------------------------------------------------

@router.put("/{product_id}")
def update_product(
    product_id: int,
    data: UpdateProductRequest,
    current_user=Depends(get_current_user)
):
    try:

        user_id = current_user["user_id"]

        # ------------------------------------------------
        # Validate values
        # ------------------------------------------------

        if not data.title.strip():
            raise HTTPException(
                status_code=400,
                detail="Product title is required"
            )

        if not data.description.strip():
            raise HTTPException(
                status_code=400,
                detail="Product description is required"
            )

        if not data.condition.strip():
            raise HTTPException(
                status_code=400,
                detail="Product condition is required"
            )

        if not data.location.strip():
            raise HTTPException(
                status_code=400,
                detail="Product location is required"
            )

        if data.price <= 0:
            raise HTTPException(
                status_code=400,
                detail="Product price must be greater than zero"
            )

        # ------------------------------------------------
        # Update product
        # ------------------------------------------------

        with engine.begin() as connection:

            product_result = connection.execute(
                text("""
                    SELECT
                        P_ID,
                        C_ID,
                        PRODUCT_TYPE_ID,
                        STATUS
                    FROM PRODUCTS
                    WHERE P_ID = :product_id
                      AND U_ID = :user_id
                    LIMIT 1
                """),
                {
                    "product_id": product_id,
                    "user_id": user_id,
                }
            )

            product = product_result.mappings().first()

            if not product:
                raise HTTPException(
                    status_code=404,
                    detail="Product not found"
                )

            if product["STATUS"] != "ACTIVE":
                raise HTTPException(
                    status_code=400,
                    detail="Only active products can be edited"
                )

            # ------------------------------------------------
            # Update only editable information
            #
            # Category and Product Type are intentionally
            # NOT changed.
            # ------------------------------------------------

            connection.execute(
                text("""
                    UPDATE PRODUCTS
                    SET
                        TITLE = :title,
                        DESCRIPTION = :description,
                        `CONDITION` = :condition,
                        PRICE = :price,
                        AI_PRICE = :ai_price,
                        LOCATION = :location
                    WHERE P_ID = :product_id
                      AND U_ID = :user_id
                """),
                {
                    "title": data.title.strip(),
                    "description": data.description.strip(),
                    "condition": data.condition.strip(),
                    "price": data.price,
                    "ai_price": data.ai_price,
                    "location": data.location.strip(),
                    "product_id": product_id,
                    "user_id": user_id,
                }
            )

        return {
            "message": "Product updated successfully",
            "product_id": product_id,
            "status": "ACTIVE",
            "price": data.price,
            "ai_price": data.ai_price,
        }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )




# ---------------------------------------------------
# API: Delete / Stop Selling Product
# ---------------------------------------------------

@router.delete("/{product_id}")
def delete_product(
    product_id: int,
    current_user=Depends(get_current_user)
):
    try:

        user_id = current_user["user_id"]

        with engine.begin() as connection:

            # --------------------------------------------
            # Check product belongs to current user
            # --------------------------------------------

            product_result = connection.execute(
                text("""
                    SELECT
                        P_ID,
                        STATUS
                    FROM PRODUCTS
                    WHERE P_ID = :product_id
                      AND U_ID = :user_id
                    LIMIT 1
                """),
                {
                    "product_id": product_id,
                    "user_id": user_id,
                }
            )

            product = product_result.mappings().first()

            if not product:
                raise HTTPException(
                    status_code=404,
                    detail="Product not found"
                )

            # --------------------------------------------
            # Already deleted
            # --------------------------------------------

            if product["STATUS"] == "DELETED":
                raise HTTPException(
                    status_code=400,
                    detail="Product has already been deleted"
                )

            # --------------------------------------------
            # Stop selling product
            # --------------------------------------------

            connection.execute(
                text("""
                    UPDATE PRODUCTS
                    SET STATUS = 'DELETED'
                    WHERE P_ID = :product_id
                      AND U_ID = :user_id
                """),
                {
                    "product_id": product_id,
                    "user_id": user_id,
                }
            )

        return {
            "message": "Product deleted successfully",
            "product_id": product_id,
            "status": "DELETED"
        }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )




# ---------------------------------------------------
# API: Get Single Product Details
# ---------------------------------------------------

@router.get("/{product_id}")
def get_product_details(
    product_id: int,
    current_user=Depends(get_current_user)
):
    try:

        user_id = current_user["user_id"]

        with engine.connect() as connection:

            # =================================================
            # 1. GET PRODUCT
            # =================================================

            product_result = connection.execute(
                text("""
                    SELECT
                        p.P_ID,
                        p.U_ID,
                        p.C_ID,
                        p.PRODUCT_TYPE_ID,
                        p.TITLE,
                        p.DESCRIPTION,
                        p.`CONDITION`,
                        p.PRICE,
                        p.AI_PRICE,
                        p.LOCATION,
                        p.AI_CONFIDENCE,
                        p.AI_ANALYZED,
                        p.AI_PRODUCT_NAME,
                        p.STATUS,
                        p.CREATED_AT,
                        c.CATEGORY_NAME,
                        pt.PRODUCT_TYPE_NAME
                    FROM PRODUCTS p

                    INNER JOIN CATEGORIES c
                        ON p.C_ID = c.C_ID

                    INNER JOIN PRODUCT_TYPES pt
                        ON p.PRODUCT_TYPE_ID = pt.PRODUCT_TYPE_ID

                    WHERE p.P_ID = :product_id
                      AND p.U_ID = :user_id
                    LIMIT 1
                """),
                {
                    "product_id": product_id,
                    "user_id": user_id,
                }
            )

            product = product_result.mappings().first()

            if not product:
                raise HTTPException(
                    status_code=404,
                    detail="Product not found"
                )

            # =================================================
            # 2. GET ALL PRODUCT IMAGES
            # =================================================

            image_result = connection.execute(
                text("""
                    SELECT
                        PI_ID,
                        IMAGE_PATH
                    FROM PRODUCT_IMAGES
                    WHERE P_ID = :product_id
                    ORDER BY PI_ID ASC
                """),
                {
                    "product_id": product_id,
                }
            )

            images = []

            for image in image_result.mappings().all():

                images.append({
                    "image_id": image["PI_ID"],
                    "image_path": image["IMAGE_PATH"],
                })

            # =================================================
            # 3. GET PRODUCT ATTRIBUTES
            # =================================================

            attribute_result = connection.execute(
                text("""
                    SELECT
                        P_ID,
                        ATTRIBUTE_ID,
                        ATTRIBUTE_VALUE
                    FROM PRODUCT_ATTRIBUTE_VALUES
                    WHERE P_ID = :product_id
                """),
                {
                    "product_id": product_id,
                }
            )

            attributes = []

            for attribute in attribute_result.mappings().all():

                attributes.append({
                    "attribute_id": attribute["ATTRIBUTE_ID"],
                    "value": attribute["ATTRIBUTE_VALUE"],
                })

            # =================================================
            # 4. RETURN COMPLETE PRODUCT
            # =================================================

            return {
                "product": {
                    "product_id": product["P_ID"],
                    "user_id": product["U_ID"],

                    "category_id": product["C_ID"],
                    "category": product["CATEGORY_NAME"],

                    "product_type_id":
                        product["PRODUCT_TYPE_ID"],
                    "product_type":
                        product["PRODUCT_TYPE_NAME"],

                    "title": product["TITLE"],
                    "description": product["DESCRIPTION"],
                    "condition": product["CONDITION"],

                    "price": float(product["PRICE"]),
                    "ai_price":
                        float(product["AI_PRICE"])
                        if product["AI_PRICE"] is not None
                        else None,

                    "location": product["LOCATION"],

                    "ai_confidence":
                        float(product["AI_CONFIDENCE"])
                        if product["AI_CONFIDENCE"] is not None
                        else None,

                    "ai_analyzed": product["AI_ANALYZED"],
                    "ai_product_name":
                        product["AI_PRODUCT_NAME"],

                    "status": product["STATUS"],

                    "created_at":
                        str(product["CREATED_AT"])
                        if product["CREATED_AT"] is not None
                        else None,

                    "images": images,

                    "attributes": attributes,
                }
            }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )




# ---------------------------------------------------
# API: Get Products of Specific User
# ---------------------------------------------------

@router.get("/user/{user_id}")
def get_user_products(user_id: int):
    try:
        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        p.P_ID,
                        p.TITLE,
                        p.DESCRIPTION,
                        p.`CONDITION`,
                        p.PRICE,
                        p.AI_PRICE,
                        p.LOCATION,
                        p.STATUS,
                        c.CATEGORY_NAME,
                        pi.IMAGE_PATH
                    FROM PRODUCTS p
                    INNER JOIN CATEGORIES c
                        ON p.C_ID = c.C_ID
                    LEFT JOIN PRODUCT_IMAGES pi
                        ON p.P_ID = pi.P_ID
                    WHERE p.U_ID = :user_id
                    AND p.STATUS = 'ACTIVE'
                    ORDER BY p.CREATED_AT DESC
                """),
                {
                    "user_id": user_id
                }
            )

            products = []

            for row in result:
                products.append({
                    "product_id": row.P_ID,
                    "title": row.TITLE,
                    "description": row.DESCRIPTION,
                    "condition": row.CONDITION,
                    "price": float(row.PRICE),
                    "ai_price": float(row.AI_PRICE),
                    "location": row.LOCATION,
                    "status": row.STATUS,
                    "category": row.CATEGORY_NAME,
                    "image_path": row.IMAGE_PATH
                })

            return {
                "products": products
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )