from pathlib import Path
import sys
import re

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
# Test captions
# --------------------------------------------------

test_captions = [
    "an iphone with the screen open on a white surface",
    "a laptop on a wooden table in a living room",
    "hp office printer",
]


# --------------------------------------------------
# Product name normalization
# --------------------------------------------------

def normalize_text(value: str) -> str:

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
# Load Product Types from database
# --------------------------------------------------

print("Loading Sellify Product Types...")

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


print("\nDatabase Product Types:")

for product_type in product_types:

    print(
        f"- {product_type['product_type_name']}"
    )


# --------------------------------------------------
# Matching function
# --------------------------------------------------

def find_product_type(caption: str):

    caption_normalized = normalize_text(
        caption
    )

    for product_type in product_types:

        product_type_name = (
            product_type["product_type_name"]
        )

        # Direct product type name
        names_to_check = [
            product_type_name
        ]

        # Known aliases
        aliases = PRODUCT_TYPE_ALIASES.get(
            product_type_name,
            []
        )

        names_to_check.extend(
            aliases
        )

        for name in names_to_check:

            normalized_name = normalize_text(
                name
            )

            if normalized_name in caption_normalized:

                return product_type

    return None


# --------------------------------------------------
# Test all captions
# --------------------------------------------------

print("\n\nMatching Tests")
print("============================")


for caption in test_captions:

    print(
        f"\nCaption: {caption}"
    )

    matched = find_product_type(
        caption
    )

    if matched:

        print(
            "Result: SUPPORTED"
        )

        print(
            f"Product Type: "
            f"{matched['product_type_name']}"
        )

        print(
            f"Product Type ID: "
            f"{matched['product_type_id']}"
        )

        print(
            f"Category ID: "
            f"{matched['category_id']}"
        )

    else:

        print(
            "Result: UNSUPPORTED"
        )

        print(
            "No matching Sellify Product Type."
        )