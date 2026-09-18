import 'dart:io';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';


class ProductDetailsScreen extends StatefulWidget {
  final File image;
  final Map<String, dynamic> aiResult;

  const ProductDetailsScreen({
    super.key,
    required this.image,
    required this.aiResult,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}


class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {


  final TextEditingController locationController =
  TextEditingController();


  String condition = "Good";

  List<Map<String, dynamic>> attributes = [];

  Map<int, TextEditingController> attributeControllers = {};

  int? categoryId;

  bool isLoadingAttributes = true;

  String? errorMessage;

  bool isPredictingPrice = false;

  int? aiPrice;


  @override
  void initState() {
    super.initState();

    loadCategoryAttributes();
  }


  @override
  void dispose() {

    locationController.dispose();

    for (final controller in attributeControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }


  Future<void> loadCategoryAttributes() async {
    try {
      final productTypeIdValue =
      widget.aiResult["product_type_id"];

      if (productTypeIdValue == null) {
        throw Exception(
          "AI product type ID is not available",
        );
      }

      final int productTypeId =
      productTypeIdValue is int
          ? productTypeIdValue
          : int.parse(
        productTypeIdValue.toString(),
      );

      final categoryName =
          widget.aiResult["category"] ??
              "Electronics";

      final categories =
      await ApiService.getCategories();

      final matchingCategory =
      categories.firstWhere(
            (category) =>
        category["category_name"]
            .toString()
            .toLowerCase() ==
            categoryName
                .toString()
                .toLowerCase(),
        orElse: () => {
          "category_id": 5,
          "category_name": "Electronics",
        },
      );

      final int selectedCategoryId =
      matchingCategory["category_id"];

      final result =
      await ApiService.getProductTypeAttributes(
        productTypeId,
      );

      if (!mounted) return;

      setState(() {
        categoryId = selectedCategoryId;

        attributes = result;

        isLoadingAttributes = false;

        for (final attribute in attributes) {
          final int attributeId =
          attribute["attribute_id"];

          attributeControllers[attributeId] =
              TextEditingController();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingAttributes = false;

        errorMessage =
        "Failed to load product fields: $e";
      });
    }
  }


  bool validateAttributes() {

    for (final attribute in attributes) {

      final bool isRequired =
          attribute["is_required"] == true;

      if (!isRequired) {
        continue;
      }

      final int attributeId =
      attribute["attribute_id"];

      final controller =
      attributeControllers[attributeId];

      if (controller == null ||
          controller.text.trim().isEmpty) {

        final String name =
        attribute["attribute_name"];

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              "Please enter $name",
            ),
          ),
        );

        return false;
      }
    }

    return true;
  }



  String getAttributeValue(String attributeName) {

    for (final attribute in attributes) {

      final String name =
      attribute["attribute_name"]
          .toString()
          .trim()
          .toLowerCase();

      if (name == attributeName.trim().toLowerCase()) {

        final int attributeId =
        attribute["attribute_id"];

        return attributeControllers[attributeId]
            ?.text
            .trim() ??
            "";
      }
    }

    return "";
  }



  String generateProductTitle() {
    final String category =
    (widget.aiResult["category"] ?? "Product")
        .toString()
        .trim();

    final String brand = getAttributeValue("Brand");
    final String model = getAttributeValue("Model");
    final String ram = getAttributeValue("RAM");
    final String storage = getAttributeValue("Storage");

    // MOBILE PHONES
    if (category.toLowerCase().contains("mobile")) {
      final List<String> parts = [];

      if (brand.isNotEmpty) {
        parts.add(brand);
      }

      if (model.isNotEmpty) {
        parts.add(model);
      }

      if (ram.isNotEmpty) {
        parts.add(ram);
      }

      if (storage.isNotEmpty) {
        parts.add(storage);
      }

      if (parts.isNotEmpty) {
        return parts.join(" ");
      }

      return "Used Mobile Phone";
    }

    // LAPTOPS
    if (category.toLowerCase().contains("laptop")) {
      final List<String> parts = [];

      if (brand.isNotEmpty) {
        parts.add(brand);
      }

      if (model.isNotEmpty) {
        parts.add(model);
      }

      if (ram.isNotEmpty) {
        parts.add(ram);
      }

      if (storage.isNotEmpty) {
        parts.add(storage);
      }

      if (parts.isNotEmpty) {
        return parts.join(" ");
      }

      return "Used Laptop";
    }

    // FURNITURE
    if (category.toLowerCase().contains("furniture")) {
      final String furnitureType =
      getAttributeValue("Furniture Type");

      final List<String> parts = [];

      if (brand.isNotEmpty) {
        parts.add(brand);
      }

      if (furnitureType.isNotEmpty) {
        parts.add(furnitureType);
      }

      if (parts.isNotEmpty) {
        return parts.join(" ");
      }

      return "Used Furniture";
    }

    // BICYCLES
    if (category.toLowerCase().contains("bicycle")) {
      final String bicycleType =
      getAttributeValue("Bicycle Type");

      final List<String> parts = [];

      if (brand.isNotEmpty) {
        parts.add(brand);
      }

      if (model.isNotEmpty) {
        parts.add(model);
      }

      if (bicycleType.isNotEmpty) {
        parts.add(bicycleType);
      }

      if (parts.isNotEmpty) {
        return parts.join(" ");
      }

      return "Used Bicycle";
    }

    // ELECTRONICS
    if (category.toLowerCase().contains("electronic")) {
      final String deviceType =
      getAttributeValue("Device Type");

      final List<String> parts = [];

      if (brand.isNotEmpty) {
        parts.add(brand);
      }

      if (model.isNotEmpty) {
        parts.add(model);
      }

      if (deviceType.isNotEmpty) {
        parts.add(deviceType);
      }

      if (parts.isNotEmpty) {
        return parts.join(" ");
      }

      return "Used Electronics";
    }

    return "Used $category";
  }



  String generateProductDescription() {
    final String category =
    (widget.aiResult["category"] ?? "Product")
        .toString()
        .trim();

    final List<String> parts = [];

    for (final attribute in attributes) {
      final int attributeId =
      attribute["attribute_id"];

      final String name =
      attribute["attribute_name"]
          .toString()
          .trim();

      final String value =
          attributeControllers[attributeId]
              ?.text
              .trim() ??
              "";

      if (value.isEmpty) {
        continue;
      }

      switch (name.toLowerCase()) {

        case "brand":
          parts.add(value);
          break;

        case "model":
          parts.add(value);
          break;

        case "ram":
          parts.add("$value RAM");
          break;

        case "storage":
          parts.add("$value storage");
          break;

        case "processor":
          parts.add("$value processor");
          break;

        case "generation":
          parts.add("$value generation");
          break;

        case "graphics":
          parts.add("$value graphics");
          break;

        case "screen size":
          parts.add("$value screen size");
          break;

        case "operating system":
          parts.add("$value operating system");
          break;

        case "battery capacity":
          parts.add("$value battery capacity");
          break;

        case "battery health":
          parts.add("$value battery health");
          break;

        case "camera":
          parts.add("$value camera");
          break;

        case "5g support":
          parts.add("$value 5G support");
          break;

        case "furniture type":
          parts.add(value);
          break;

        case "material":
          parts.add("$value material");
          break;

        case "dimensions":
          parts.add("$value dimensions");
          break;

        case "colour":
          parts.add("$value colour");
          break;

        case "bicycle type":
          parts.add(value);
          break;

        case "frame size":
          parts.add("$value frame size");
          break;

        case "wheel size":
          parts.add("$value wheel size");
          break;

        case "gear count":
          parts.add("$value gears");
          break;

        case "brake type":
          parts.add("$value brakes");
          break;

        case "device type":
          parts.add(value);
          break;

        case "specifications":
          parts.add(value);
          break;

        case "age":
          parts.add("$value years old");
          break;

        default:
          parts.add("$value ${name.toLowerCase()}");
      }
    }

    if (parts.isEmpty) {
      return "$category available for sale.";
    }

    return "${generateProductTitle()}, ${parts.join(", ")}.";
  }




  Future<void> listProduct() async {
    if (aiPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "AI price is not available",
          ),
        ),
      );

      return;
    }

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Product category is not available",
          ),
        ),
      );

      return;
    }

    final String? userIdString =
    await AuthService.getUserId();

    if (userIdString == null ||
        userIdString.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please login again",
          ),
        ),
      );

      return;
    }

    final int? userId =
    int.tryParse(userIdString);

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid user ID",
          ),
        ),
      );

      return;
    }

    final Map<int, String> attributeValues =
    getAttributeValues();

    try {
      // STEP 1: Upload product image
      final imageResult =
      await ApiService.uploadProductImage(
        widget.image,
      );

      final String? imagePath =
      imageResult["image_path"]
          ?.toString()
          .replaceAll("\\", "/");

      if (imagePath == null ||
          imagePath.isEmpty) {
        throw Exception(
          "Image path was not returned by server",
        );
      }

      // STEP 2: Create product
      final result =
      await ApiService.createProduct(
        userId: userId,
        categoryId: categoryId!,
        title: generateProductTitle(),
        description: generateProductDescription(),
        condition: condition,
        price: aiPrice!,
        aiPrice: aiPrice!,
        location: locationController.text.trim(),
        imagePath: imagePath,
        attributes: attributeValues,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"] ??
                "Product listed successfully",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to list product: $e",
          ),
        ),
      );
    }
  }



  Future<void> continueToNextStep() async {

    if (locationController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter your location",
          ),
        ),
      );

      return;
    }


    if (!validateAttributes()) {
      return;
    }


    // Get dynamic product attributes

    final String brand =
    getAttributeValue("Brand");

    final String model =
    getAttributeValue("Model");

    final String ram =
    getAttributeValue("RAM");

    final String storage =
    getAttributeValue("Storage");

    final String processor =
    getAttributeValue("Processor");

    final String ageText =
    getAttributeValue("Age");


    final int? age =
    int.tryParse(ageText);


    if (age == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid product age",
          ),
        ),
      );

      return;
    }


    setState(() {
      isPredictingPrice = true;
    });


    try {

      final String category =
          widget.aiResult["category"] ??
              "Electronics";


      final predictedPrice =
      await ApiService.predictPrice(

        category: category,
        brand: brand,
        model: model,
        age: age,
        condition: condition,
        ram: ram,
        storage: storage,
        processor: processor,
      );


      if (!mounted) return;

      setState(() {
        aiPrice =
            predictedPrice;

        isPredictingPrice =
        false;
      });


      showPricePredictionDialog();


    } catch (e) {

      if (!mounted) return;


      setState(() {
        isPredictingPrice = false;
      });


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to predict price: $e",
          ),
        ),
      );
    }
  }


  void showPricePredictionDialog() {

    if (aiPrice == null) {
      return;
    }


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {

        return AlertDialog(

          title: const Text(
            "AI Price Prediction",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(
                Icons.auto_awesome,
                size: 50,
              ),

              const SizedBox(height: 15),

              const Text(
                "Our AI suggests the following price for your product:",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              Text(
                "₹${aiPrice!}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Would you like to list this product at this price?",
                textAlign: TextAlign.center,
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {

                Navigator.pop(context);

                Navigator.pop(this.context);
              },

              child: const Text(
                "NO, DON'T LIST",
              ),
            ),

            ElevatedButton(
              onPressed: () async {

                Navigator.pop(context);

                await listProduct();
              },

              child: const Text(
                "YES, LIST PRODUCT",
              ),
            ),
          ],
        );
      },
    );
  }



  Map<int, String> getAttributeValues() {
    final Map<int, String> values = {};

    for (final attribute in attributes) {
      final int attributeId =
      attribute["attribute_id"];

      final String value =
          attributeControllers[attributeId]
              ?.text
              .trim() ??
              "";

      if (value.isNotEmpty) {
        values[attributeId] = value;
      }
    }

    return values;
  }



  String getAttributeSummary() {

    final List<String> values = [];

    for (final attribute in attributes) {

      final int attributeId =
      attribute["attribute_id"];

      final String name =
      attribute["attribute_name"];

      final String value =
          attributeControllers[attributeId]
              ?.text
              .trim() ??
              "";

      if (value.isNotEmpty) {

        values.add(
          "$name: $value",
        );
      }
    }

    return values.isEmpty
        ? "No additional information"
        : values.join("\n");
  }


  Widget buildDynamicAttributeField(
      Map<String, dynamic> attribute) {

    final int attributeId =
    attribute["attribute_id"];

    final String name =
    attribute["attribute_name"];

    final String type =
    attribute["attribute_type"];

    final bool required =
        attribute["is_required"] == true;


    final controller =
    attributeControllers[attributeId]!;


    TextInputType keyboardType =
        TextInputType.text;


    if (type == "NUMBER") {
      keyboardType =
          TextInputType.number;
    }


    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboardType,

        decoration: InputDecoration(

          labelText:
          required
              ? "$name *"
              : name,

          hintText:
          "Enter $name",

          border:
          const OutlineInputBorder(),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    final String category =
        widget.aiResult["category"] ??
            "Electronics";


    final String productType =
        widget.aiResult["product_type"] ??
            "Unknown";


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Product Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "Product Details",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 8),


            Text(
              "Enter information about the product you want to sell.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),


            const SizedBox(height: 25),


            // IMAGE

            ClipRRect(

              borderRadius:
              BorderRadius.circular(20),

              child: Image.file(

                widget.image,

                width:
                double.infinity,

                height: 220,

                fit: BoxFit.cover,
              ),
            ),


            const SizedBox(height: 25),


            // AI PRODUCT TYPE

            const Text(
              "AI Product Type",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),


            const SizedBox(height: 8),


            Container(

              width:
              double.infinity,

              padding:
              const EdgeInsets.all(15),

              decoration:
              BoxDecoration(

                borderRadius:
                BorderRadius.circular(12),

                color:
                Colors.grey.shade100,
              ),

              child: Text(
                productType,

                style:
                const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),


            const SizedBox(height: 20),


            // CATEGORY

            const Text(
              "Category",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),


            const SizedBox(height: 8),


            Container(

              width:
              double.infinity,

              padding:
              const EdgeInsets.all(15),

              decoration:
              BoxDecoration(

                borderRadius:
                BorderRadius.circular(12),

                color:
                Colors.grey.shade100,
              ),

              child: Text(
                category,

                style:
                const TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 18),
            // DYNAMIC ATTRIBUTES

            const Text(
              "Product Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),


            const SizedBox(height: 12),


            if (isLoadingAttributes)

              const Center(
                child:
                Padding(
                  padding:
                  EdgeInsets.all(20),

                  child:
                  CircularProgressIndicator(),
                ),
              )


            else if (errorMessage != null)

              Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets.all(15),

                decoration:
                BoxDecoration(

                  color:
                  Colors.red.shade50,

                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: Text(
                  errorMessage!,

                  style:
                  const TextStyle(
                    color: Colors.red,
                  ),
                ),
              )


            else

              Column(
                children:
                attributes
                    .map(
                  buildDynamicAttributeField,
                )
                    .toList(),
              ),


            const SizedBox(height: 5),


            // CONDITION

            const Text(
              "Condition",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),


            const SizedBox(height: 8),


            DropdownButtonFormField<String>(

              value: condition,

              decoration:
              const InputDecoration(
                border:
                OutlineInputBorder(),
              ),

              items: const [

                DropdownMenuItem(
                  value: "New",
                  child:
                  Text("New"),
                ),

                DropdownMenuItem(
                  value: "Like New",
                  child:
                  Text("Like New"),
                ),

                DropdownMenuItem(
                  value: "Good",
                  child:
                  Text("Good"),
                ),

                DropdownMenuItem(
                  value: "Fair",
                  child:
                  Text("Fair"),
                ),

                DropdownMenuItem(
                  value: "Poor",
                  child:
                  Text("Poor"),
                ),
              ],

              onChanged: (value) {

                if (value != null) {

                  setState(() {
                    condition = value;
                  });
                }
              },
            ),


            const SizedBox(height: 18),


            // LOCATION

            TextField(

              controller:
              locationController,

              decoration:
              const InputDecoration(

                labelText:
                "Location",

                hintText:
                "Example: Ahmedabad",

                border:
                OutlineInputBorder(),
              ),
            ),


            const SizedBox(height: 30),


            // CONTINUE

            SizedBox(

              width:
              double.infinity,

              child:
              ElevatedButton(

                onPressed:
                isLoadingAttributes ||
                    isPredictingPrice
                    ? null
                    : continueToNextStep,

                style:
                ElevatedButton.styleFrom(

                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                ),

                child: isPredictingPrice
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "GET AI PRICE",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}