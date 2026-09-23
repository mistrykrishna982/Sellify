from pathlib import Path
import sys
import re

from transformers import (
    BlipProcessor,
    BlipForConditionalGeneration,
)

from PIL import Image

from sqlalchemy import text


# --------------------------------------------------
# Project path
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent

sys.path.append(
    str(BASE_DIR.parent)
)

from database import engine


# --------------------------------------------------
# Test image
# --------------------------------------------------

IMAGE_PATH = (
    BASE_DIR
    / "images"
    / "laptop.jpg"
)


# --------------------------------------------------
# Product Type aliases
# --------------------------------------------------

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


# --------------------------------------------------
# Text normalization
# --------------------------------------------------

def normalize_text(value: str):

    value = value.lower().strip()

    value = re.sub(
        r"[^a-z0-9\s]",
        " ",
        value,
    )

    value = re.sub(
        r"\s+",
        " ",
        value,
    )

    return value


# --------------------------------------------------
# Load Product Types
# --------------------------------------------------

def load_product_types():

    print(
        "\nLoading Sellify Product Types..."
    )

    with engine.connect() as connection:

        result = connection.execute(
            text("""
                SELECT
                    PRODUCT_TYPE_ID,
                    PRODUCT_TYPE_NAME,
                    C_ID
                FROM PRODUCT_TYPES
                ORDER BY PRODUCT_TYPE_ID
            """)
        )

        product_types = []

        for row in result:

            product_types.append({
                "product_type_id":
                    row.PRODUCT_TYPE_ID,

                "product_type_name":
                    row.PRODUCT_TYPE_NAME,

                "category_id":
                    row.C_ID,
            })

        return product_types


# --------------------------------------------------
# Match caption to Product Type
# --------------------------------------------------

def find_product_type(
    caption,
    product_types,
):

    caption_normalized = normalize_text(
        caption
    )

    for product_type in product_types:

        product_type_name = (
            product_type[
                "product_type_name"
            ]
        )

        names_to_check = [
            product_type_name
        ]

        aliases = PRODUCT_TYPE_ALIASES.get(
            product_type_name,
            []
        )

        names_to_check.extend(
            aliases
        )

        for name in names_to_check:

            normalized_name = (
                normalize_text(name)
            )

            if normalized_name in caption_normalized:

                return product_type

    return None


# --------------------------------------------------
# Main
# --------------------------------------------------

print("Loading BLIP model...")

processor = BlipProcessor.from_pretrained(
    "Salesforce/blip-image-captioning-base"
)

model = BlipForConditionalGeneration.from_pretrained(
    "Salesforce/blip-image-captioning-base"
)


# --------------------------------------------------
# Check image
# --------------------------------------------------

if not IMAGE_PATH.exists():

    raise FileNotFoundError(
        f"Test image not found: {IMAGE_PATH}"
    )


# --------------------------------------------------
# Load image
# --------------------------------------------------

image = Image.open(
    IMAGE_PATH
).convert("RGB")


# --------------------------------------------------
# Generate BLIP caption
# --------------------------------------------------

inputs = processor(
    images=image,
    return_tensors="pt",
)


output = model.generate(
    **inputs,
    max_new_tokens=30,
)


caption = processor.decode(
    output[0],
    skip_special_tokens=True,
)


print("\nBLIP caption:")
print(caption)


# --------------------------------------------------
# Load database Product Types
# --------------------------------------------------

product_types = load_product_types()


print(
    "\nDatabase Product Types:"
)

for product_type in product_types:

    print(
        f"- {product_type['product_type_name']}"
    )


# --------------------------------------------------
# Match
# --------------------------------------------------

matched_product_type = (
    find_product_type(
        caption,
        product_types,
    )
)


# --------------------------------------------------
# Final result
# --------------------------------------------------

print(
    "\nFinal AI classification:"
)

if matched_product_type:

    print(
        "SUPPORTED"
    )

    print(
        f"Product Type: "
        f"{matched_product_type['product_type_name']}"
    )

    print(
        f"Product Type ID: "
        f"{matched_product_type['product_type_id']}"
    )

    print(
        f"Category ID: "
        f"{matched_product_type['category_id']}"
    )

else:

    print(
        "UNSUPPORTED"
    )

    print(
        "No matching Sellify Product Type."
    )