import joblib
import pandas as pd
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent

MODEL_FILE = BASE_DIR / "ml" / "price_model.pkl"


print("Loading price prediction model...")

price_model = joblib.load(MODEL_FILE)

print("Price prediction model loaded successfully.")


def predict_price(
    category,
    brand,
    model,
    age,
    condition,
    ram,
    storage,
    processor
):

    data = pd.DataFrame([
        {
            "category": category,
            "brand": brand if brand else "Unknown",
            "model": model if model else "Unknown",
            "age": age,
            "condition": condition,
            "ram": ram if ram else "Unknown",
            "storage": storage if storage else "Unknown",
            "processor": processor if processor else "Unknown"
        }
    ])

    predicted_price = price_model.predict(data)[0]

    predicted_price = round(float(predicted_price))

    return predicted_price