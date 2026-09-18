from services.ai_service import analyze_product_image


image_path = r"C:\Users\Krishna\Pictures\laptop.jpg"


result = analyze_product_image(image_path)


print("\n")
print("================================")
print("SELLIFY AI RESULT")
print("================================")

print("Predicted Category:")
print(result["category"])

print("Confidence:")
print(result["confidence"], "%")

print("\nAll Predictions:")

for prediction in result["predictions"]:
    print(
        prediction["category"],
        "->",
        prediction["confidence"],
        "%"
    )

print("================================")