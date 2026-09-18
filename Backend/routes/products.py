from fastapi import APIRouter, UploadFile, File, HTTPException
from pathlib import Path
import shutil
import uuid

from services.ai_service import analyze_product_image
from services.price_service import predict_price
from pydantic import BaseModel
from sqlalchemy import text
from database import engine


class PricePredictionRequest(BaseModel):
    category: str
    brand: str = ""
    model: str = ""
    age: int
    condition: str
    ram: str = ""
    storage: str = ""
    processor: str = ""


class CreateProductRequest(BaseModel):

    user_id: int

    category_id: int

    title: str

    description: str

    condition: str

    price: int

    ai_price: int

    location: str

    image_path: str

    attributes: dict[int, str] = {}


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

    "predictions": ai_result["predictions"]

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
    data: PricePredictionRequest
):

    try:

        predicted_price = predict_price(
            category=data.category,
            brand=data.brand,
            model=data.model,
            age=data.age,
            condition=data.condition,
            ram=data.ram,
            storage=data.storage,
            processor=data.processor
        )

        return {
            "message": "Price prediction completed successfully",
            "ai_price": predicted_price
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



# ---------------------------------------------------
# API 4: Create Final Product Listing
# ---------------------------------------------------

@router.post("/create")
def create_product(
    data: CreateProductRequest
):

    try:

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
                    "user_id": data.user_id
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
                    "category_id":
                        data.category_id
                }
            )

            category = category_result.fetchone()

            if not category:

                raise HTTPException(
                    status_code=404,
                    detail="Category not found"
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
                        TITLE,
                        DESCRIPTION,
                        `CONDITION`,
                        PRICE,
                        AI_PRICE,
                        LOCATION,
                        STATUS
                    )
                    VALUES
                    (
                        :user_id,
                        :category_id,
                        :title,
                        :description,
                        :condition,
                        :price,
                        :ai_price,
                        :location,
                        'ACTIVE'
                    )
                """),
                {
                    "user_id":
                        data.user_id,

                    "category_id":
                        data.category_id,

                    "title":
                        data.title,

                    "description":
                        data.description,

                    "condition":
                        data.condition,

                    "price":
                        data.price,

                    "ai_price":
                        data.ai_price,

                    "location":
                        data.location
                }
            )


            # --------------------------------------------
            # Get new product ID
            # --------------------------------------------

            product_id = (
                product_result.lastrowid
            )


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
                    "product_id":
                        product_id,

                    "image_path":
                        data.image_path
                }
            )


            # --------------------------------------------
            # Save dynamic attributes
            # --------------------------------------------

            for attribute_id, attribute_value in (
                data.attributes.items()
            ):

                if not attribute_value:
                    continue


                # Check attribute belongs to category

                attribute_result = connection.execute(
                    text("""
                        SELECT ATTRIBUTE_ID
                        FROM CATEGORY_ATTRIBUTES
                        WHERE ATTRIBUTE_ID = :attribute_id
                          AND C_ID = :category_id
                    """),
                    {
                        "attribute_id":
                            attribute_id,

                        "category_id":
                            data.category_id
                    }
                )

                attribute = (
                    attribute_result.fetchone()
                )

                if not attribute:

                    raise HTTPException(
                        status_code=400,
                        detail=(
                            "Invalid attribute "
                            f"{attribute_id} "
                            "for selected category"
                        )
                    )


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
                        "product_id":
                            product_id,

                        "attribute_id":
                            attribute_id,

                        "attribute_value":
                            attribute_value
                    }
                )


        # ------------------------------------------------
        # Transaction completed
        # ------------------------------------------------

        return {

            "message":
                "Product listed successfully",

            "product_id":
                product_id,

            "price":
                data.price,

            "ai_price":
                data.ai_price,

            "status":
                "ACTIVE"
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