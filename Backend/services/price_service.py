import re
import joblib
import pandas as pd
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_FILE = BASE_DIR / "ml" / "price_model.pkl"


print("Loading price prediction model...")
price_model = joblib.load(MODEL_FILE)
print("Price prediction model loaded successfully.")


def extract_description_value(
    description: str,
    field_names: list[str],
) -> str:
    if not description:
        return "Unknown"

    for field_name in field_names:
        pattern = (
            rf"(?im)^\s*"
            rf"{re.escape(field_name)}"
            rf"\s*[:=]\s*(.+?)\s*$"
        )

        match = re.search(pattern, description)

        if match:
            return match.group(1).strip()

    return "Unknown"


def predict_price(
    category,
    product_type,
    title,
    description,
    age,
    condition,
):
    category = (
        str(category).strip()
        if category
        else "Unknown"
    )

    product_type = (
        str(product_type).strip()
        if product_type
        else "Unknown"
    )

    title = (
        str(title).strip()
        if title
        else ""
    )

    description = (
        str(description).strip()
        if description
        else ""
    )

    age = (
        str(age).strip()
        if age
        else "Unknown"
    )

    condition = (
        str(condition).strip()
        if condition
        else "Unknown"
    )


    # -----------------------------------------
    # Extract information from free-form
    # description
    # -----------------------------------------

    brand = extract_description_value(
        description,
        [
            "Brand",
            "Manufacturer",
            "Make",
        ],
    )

    model = extract_description_value(
        description,
        [
            "Model",
            "Model Name",
            "Model Number",
        ],
    )

    ram = extract_description_value(
        description,
        [
            "RAM",
            "Memory",
        ],
    )

    storage = extract_description_value(
        description,
        [
            "Storage",
            "Internal Storage",
            "Storage Capacity",
        ],
    )

    processor = extract_description_value(
        description,
        [
            "Processor",
            "CPU",
            "Chipset",
        ],
    )


    # If the user did not provide Model
    # in the description, use the title.
    if model == "Unknown" and title:
        model = title


    # -----------------------------------------
    # Debug output
    # -----------------------------------------

    print("==========================================")
    print("PRICE PREDICTION INPUT")
    print("==========================================")
    print(f"Category    : {category}")
    print(f"Product Type: {product_type}")
    print(f"Brand       : {brand}")
    print(f"Model       : {model}")
    print(f"Age         : {age}")
    print(f"Condition   : {condition}")
    print(f"RAM         : {ram}")
    print(f"Storage     : {storage}")
    print(f"Processor   : {processor}")
    print("==========================================")


    # -----------------------------------------
    # Build dataframe for existing ML model
    # -----------------------------------------

    data = pd.DataFrame([
        {
            "category": category,
            "product_type": product_type,
            "brand": brand,
            "model": model,
            "age": age,
            "condition": condition,
            "ram": ram,
            "storage": storage,
            "processor": processor,
        }
    ])


    # -----------------------------------------
    # Predict
    # -----------------------------------------

    predicted_price = price_model.predict(data)[0]

    predicted_price = round(float(predicted_price))

    return predicted_price