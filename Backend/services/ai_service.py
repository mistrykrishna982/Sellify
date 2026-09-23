from pathlib import Path
from PIL import Image

from transformers import (
    pipeline,
    BlipProcessor,
    BlipForConditionalGeneration,
)

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
# Load BLIP AI model
# ---------------------------------------------------

blip_processor = BlipProcessor.from_pretrained(
    "Salesforce/blip-image-captioning-base"
)

blip_model = BlipForConditionalGeneration.from_pretrained(
    "Salesforce/blip-image-captioning-base"
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
# Generate Product Caption Using BLIP
# ---------------------------------------------------

def generate_product_caption(image_path: str):

    path = Path(image_path)

    if not path.is_absolute():
        path = BASE_DIR / path

    if not path.exists():
        raise FileNotFoundError(
            f"Image not found: {path}"
        )

    print("Generating BLIP product caption...")

    image = Image.open(path).convert("RGB")

    inputs = blip_processor(
        images=image,
        return_tensors="pt"
    )

    output = blip_model.generate(
        **inputs,
        max_new_tokens=30
    )

    caption = blip_processor.decode(
        output[0],
        skip_special_tokens=True
    ).strip()

    print("BLIP caption:")
    print(caption)

    if not caption:
        raise ValueError(
            "BLIP could not generate a product caption."
        )

    return caption



# ---------------------------------------------------
# Product Type Aliases For BLIP Matching
# ---------------------------------------------------

PRODUCT_TYPE_ALIASES = {

    "Mobile Phone": [
        "mobile phone",
        "mobile",
        "cell phone",
        "cellphone",
        "smartphone",
        "smart phone",
        "iphone",
        "android phone",
        "android smartphone",
        "samsung phone",
    ],

    "Laptop": [
        "laptop",
        "notebook",
        "notebook computer",
        "portable computer",
    ],

    "Speaker": [
        "speaker",
        "bluetooth speaker",
        "portable speaker",
    ],

    "Headphones": [
        "headphones",
        "headphone",
        "earphones",
        "earbuds",
        "wireless earbuds",
    ],

    "Camera": [
        "camera",
        "digital camera",
        "dslr",
        "mirrorless camera",
    ],

    "Glucose Meter": [
        "glucose meter",
        "blood glucose meter",
        "blood sugar meter",
        "glucometer",
    ],

    "smartwatch": [
        "smartwatch",
        "smart watch",
        "fitness watch",
    ],

    "computer": [
        "computer",
        "desktop computer",
        "desktop pc",
        "personal computer",
    ],

    "chair": [
        "chair",
        "office chair",
        "dining chair",
    ],

    "sofa": [
        "sofa",
        "couch",
        "loveseat",
        "sectional sofa",
    ],
}


# ---------------------------------------------------
# Find Product Type From BLIP Caption
# ---------------------------------------------------

def find_product_type_from_caption(
    caption,
    product_types
):

    caption = caption.lower().strip()

    for product_type in product_types:

        product_type_name = (
            product_type["product_type_name"]
        ).lower().strip()

        ai_description = (
            product_type.get("ai_description") or ""
        ).lower().strip()

        # ------------------------------------------------
        # 1. Check the actual Product Type name
        # ------------------------------------------------

        if product_type_name in caption:

            return product_type

        # ------------------------------------------------
        # 2. Check manually defined aliases
        # ------------------------------------------------

        aliases = PRODUCT_TYPE_ALIASES.get(
            product_type["product_type_name"],
            []
        )

        for alias in aliases:

            if alias.lower() in caption:

                return product_type

        # ------------------------------------------------
        # 3. Check useful words from AI description
        # ------------------------------------------------

        if ai_description:

            description_words = [
                word.strip(
                    ".,!?;:()[]{}"
                ).lower()
                for word in ai_description.split()
            ]

            important_words = [
                word
                for word in description_words
                if len(word) >= 5
            ]

            matches = 0

            for word in important_words:

                if word in caption:

                    matches += 1

            if matches >= 2:

                return product_type

    return None


# ---------------------------------------------------
# Get Clean Unsupported Product Name
# ---------------------------------------------------

def get_unsupported_product_name(caption: str):

    caption = caption.lower().strip()

    # ------------------------------------------------
    # Canonical marketplace product names
    # ------------------------------------------------

    product_aliases = {

        "Washing Machine": [
            "washing machine",
            "washer",
            "front load washer",
            "front-load washer",
            "top load washer",
            "top-load washer",
            "front load washing machine",
            "front-load washing machine",
            "top load washing machine",
            "top-load washing machine",
        ],

        "Printer": [
            "printer",
        ],

        "Projector": [
            "projector",
        ],

        "Air Purifier": [
            "air purifier",
        ],

        "Television": [
            "television",
            "tv",
        ],

        "Microwave": [
            "microwave",
        ],

        "Refrigerator": [
            "refrigerator",
            "fridge",
        ],

        "Vacuum Cleaner": [
            "vacuum cleaner",
            "vacuum",
        ],

        "Iron": [
            "iron",
        ],

        "Keyboard": [
            "keyboard",
        ],

        "Mouse": [
            "mouse",
        ],

        "Monitor": [
            "monitor",
        ],

        "Tablet": [
            "tablet",
        ],

        "Gaming Console": [
            "gaming console",
        ],
    }

    # ------------------------------------------------
    # Find canonical product name
    # ------------------------------------------------

    for product_name, aliases in product_aliases.items():

        for alias in aliases:

            if alias in caption:

                return product_name

    # ------------------------------------------------
    # If nothing matches, do not save a raw BLIP
    # caption as the Product Type.
    # ------------------------------------------------

    return "Unknown"

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
    # Generate BLIP product caption
    # ------------------------------------------------

    caption = generate_product_caption(
        str(path)
    )

    print(
        "BLIP product caption:"
    )

    print(caption)

   

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

        "unsupported_product_name":
            None,

        "predictions":
            predictions

    }