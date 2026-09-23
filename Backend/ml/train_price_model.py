import pandas as pd
import joblib

from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.ensemble import RandomForestRegressor


# ---------------------------------------------------
# File paths
# ---------------------------------------------------

DATA_FILE = "ml/training_data.csv"

MODEL_FILE = "ml/price_model.pkl"


# ---------------------------------------------------
# Load training data
# ---------------------------------------------------

print("Loading training data...")

df = pd.read_csv(DATA_FILE)

print(
    "Training rows:",
    len(df)
)


# ---------------------------------------------------
# Fill missing values
# ---------------------------------------------------

df["brand"] = df["brand"].fillna("Unknown")
df["model"] = df["model"].fillna("Unknown")
df["processor"] = df["processor"].fillna("Unknown")
df["ram"] = df["ram"].fillna("Unknown")
df["storage"] = df["storage"].fillna("Unknown")


# ---------------------------------------------------
# Select features
# ---------------------------------------------------

FEATURE_COLUMNS = [
    "category",
    "product_type",
    "brand",
    "model",
    "age",
    "condition",
    "ram",
    "storage",
    "processor"
]

X = df[FEATURE_COLUMNS]

y = df["price"]


# ---------------------------------------------------
# Feature types
# ---------------------------------------------------

CATEGORICAL_FEATURES = [
    "category",
    "product_type",
    "brand",
    "model",
    "condition",
    "ram",
    "storage",
    "processor"
]

NUMERICAL_FEATURES = [
    "age"
]


# ---------------------------------------------------
# Preprocessing
# ---------------------------------------------------

preprocessor = ColumnTransformer(

    transformers=[

        (
            "categorical",

            OneHotEncoder(
                handle_unknown="ignore"
            ),

            CATEGORICAL_FEATURES
        ),

        (
            "numerical",

            "passthrough",

            NUMERICAL_FEATURES
        )
    ]
)


# ---------------------------------------------------
# Random Forest model
# ---------------------------------------------------

model = RandomForestRegressor(

    n_estimators=200,

    random_state=42,

    max_depth=12,

    min_samples_leaf=1
)


# ---------------------------------------------------
# Complete ML pipeline
# ---------------------------------------------------

price_model = Pipeline(

    steps=[

        (
            "preprocessor",
            preprocessor
        ),

        (
            "model",
            model
        )
    ]
)


# ---------------------------------------------------
# Train model
# ---------------------------------------------------

print("Training price prediction model...")

price_model.fit(
    X,
    y
)


# ---------------------------------------------------
# Save model
# ---------------------------------------------------

joblib.dump(
    price_model,
    MODEL_FILE
)


print(
    "Price model saved successfully:"
)

print(
    MODEL_FILE
)


print(
    "Training completed successfully."
)