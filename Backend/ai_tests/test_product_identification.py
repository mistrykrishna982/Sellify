from pathlib import Path

from transformers import (
    BlipProcessor,
    BlipForConditionalGeneration,
)
from PIL import Image


BASE_DIR = Path(__file__).resolve().parent

IMAGE_PATH = BASE_DIR / "images" / "printer.jpg"


print("Loading BLIP model...")

processor = BlipProcessor.from_pretrained(
    "Salesforce/blip-image-captioning-base"
)

model = BlipForConditionalGeneration.from_pretrained(
    "Salesforce/blip-image-captioning-base"
)


if not IMAGE_PATH.exists():
    raise FileNotFoundError(
        f"Test image not found: {IMAGE_PATH}"
    )


image = Image.open(IMAGE_PATH).convert("RGB")


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


print("\nBLIP result:")
print(caption)