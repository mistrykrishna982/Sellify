from pathlib import Path

from transformers import pipeline
from sqlalchemy import text

from database import engine


# ---------------------------------------------------
# Load CLIP AI model
# ---------------------------------------------------

classifier = pipeline(
    "zero-shot-image-classification",
    model="openai/clip-vit-base-patch32"
)


# ---------------------------------------------------
# Backend root folder
# ---------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent


# ---------------------------------------------------
# Get Product Types From Database
# ---------------------------------------------------

def get_sellify_product_types():

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
                    ORDER BY pt.PRODUCT_TYPE_ID
                """)
            )

            product_types = []

            for row in result:

                product_types.append({

                    "product_type_id":
                        row.PRODUCT_TYPE_ID,

                    "product_type_name":
                        row.PRODUCT_TYPE_NAME,

                    "ai_description":
                        row.AI_DESCRIPTION,

                    "category_id":
                        row.C_ID,

                    "category_name":
                        row.CATEGORY_NAME

                })

            return product_types

    except Exception as e:

        print(
            "Failed to load product types:",
            e
        )

        raise


# ---------------------------------------------------
# Build AI Product Type Prompts
# ---------------------------------------------------

def build_product_type_prompts(product_types):

    prompts = []

    for product_type in product_types:

        product_type_name = (
            product_type["product_type_name"]
        )

        ai_description = (
            product_type["ai_description"]
        )

        if ai_description:

            prompt = (
                f"a second-hand marketplace "
                f"{product_type_name.lower()}, "
                f"such as {ai_description}"
            )

        else:

            prompt = (
                f"a second-hand marketplace "
                f"{product_type_name.lower()}"
            )

        prompts.append(prompt)

    return prompts


# ---------------------------------------------------
# Find Product Type From Prompt
# ---------------------------------------------------

def find_product_type_from_prompt(
    prompt,
    product_types
):

    for product_type in product_types:

        product_type_name = (
            product_type["product_type_name"]
        )

        ai_description = (
            product_type["ai_description"]
        )

        if ai_description:

            expected_prompt = (
                f"a second-hand marketplace "
                f"{product_type_name.lower()}, "
                f"such as {ai_description}"
            )

        else:

            expected_prompt = (
                f"a second-hand marketplace "
                f"{product_type_name.lower()}"
            )

        if prompt == expected_prompt:

            return product_type

    return None


# ---------------------------------------------------
# Analyze Product Image
# ---------------------------------------------------

def analyze_product_image(image_path: str):

    path = Path(image_path)

    # ------------------------------------------------
    # Convert relative path to absolute path
    # ------------------------------------------------

    if not path.is_absolute():

        path = BASE_DIR / path

    # ------------------------------------------------
    # Check image exists
    # ------------------------------------------------

    if not path.exists():

        raise FileNotFoundError(
            f"Image not found: {path}"
        )

    print(
        "AI analyzing image:"
    )

    print(path)

    # ------------------------------------------------
    # Load product types
    # ------------------------------------------------

    product_types = (
        get_sellify_product_types()
    )

    if not product_types:

        raise ValueError(
            "No Sellify product types found."
        )

    # ------------------------------------------------
    # Build product type prompts
    # ------------------------------------------------

    product_type_prompts = (
        build_product_type_prompts(
            product_types
        )
    )

    print(
        "AI candidate product types:"
    )

    for prompt in product_type_prompts:

        print(prompt)

    # ------------------------------------------------
    # Run CLIP product type detection
    # ------------------------------------------------

    results = classifier(

        str(path),

        candidate_labels=
            product_type_prompts

    )

    print(
        "Raw AI product type results:"
    )

    print(results)

    # ------------------------------------------------
    # Check result
    # ------------------------------------------------

    if results is None:

        raise ValueError(
            "AI returned no prediction."
        )

    if not isinstance(results, list):

        raise ValueError(
            "Unexpected AI result type."
        )

    if len(results) == 0:

        raise ValueError(
            "AI returned an empty prediction."
        )

    # ------------------------------------------------
    # Process predictions
    # ------------------------------------------------

    predictions = []

    for result in results:

        prompt = result["label"]

        confidence = round(
            float(result["score"]) * 100,
            2
        )

        matched_product_type = (
            find_product_type_from_prompt(
                prompt,
                product_types
            )
        )

        if matched_product_type is None:

            continue

        predictions.append({

            "product_type_id":
                matched_product_type[
                    "product_type_id"
                ],

            "product_type":
                matched_product_type[
                    "product_type_name"
                ],

            "category_id":
                matched_product_type[
                    "category_id"
                ],

            "category":
                matched_product_type[
                    "category_name"
                ],

            "confidence":
                confidence

        })

    # ------------------------------------------------
    # Check predictions
    # ------------------------------------------------

    if not predictions:

        raise ValueError(
            "AI could not generate a valid product type prediction."
        )

    # ------------------------------------------------
    # Sort predictions
    # ------------------------------------------------

    predictions.sort(

        key=lambda item:
            item["confidence"],

        reverse=True

    )

    # ------------------------------------------------
    # Best prediction
    # ------------------------------------------------

    best_result = predictions[0]

    print(
        "Best AI product type:",
        best_result["product_type"]
    )

    print(
        "Best AI category:",
        best_result["category"]
    )

    print(
        "AI confidence:",
        best_result["confidence"]
    )

    # ------------------------------------------------
    # Return result
    # ------------------------------------------------

    return {

        "product_type":
            best_result["product_type"],

        "product_type_id":
            best_result["product_type_id"],

        "category":
            best_result["category"],

        "category_id":
            best_result["category_id"],

        "confidence":
            best_result["confidence"],

        "supported":
            True,

        "predictions":
            predictions

    }