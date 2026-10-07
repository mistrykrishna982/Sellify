import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final File? image;
  final List<File> allImages;
  final String? imagePath;
  final Map<String, dynamic> aiResult;

  const ProductDetailsScreen({
    super.key,
    this.image,
    this.allImages = const [],
    this.imagePath,
    required this.aiResult,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController ageController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  final TextEditingController locationController =
  TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool isPredictingPrice = false;

  int? aiPrice;

  String? uploadedImagePath;

  String condition = "Good";

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final String aiProductName =
    (widget.aiResult["product_type"] ?? "")
        .toString()
        .trim();

    // Automatically put product type into title.
    if (aiProductName.isNotEmpty &&
        aiProductName.toUpperCase() != "UNKNOWN") {
      titleController.text = aiProductName;
    }
  }

  // ============================================================
  // IMAGE URL
  // ============================================================

  String getImageUrl(String imagePath) {
    if (imagePath.startsWith("http://") ||
        imagePath.startsWith("https://")) {
      return imagePath;
    }

    return "${ApiService.baseUrl}/$imagePath";
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    titleController.dispose();
    ageController.dispose();
    descriptionController.dispose();
    locationController.dispose();

    super.dispose();
  }

  // ============================================================
  // GET AI PRICE
  // ============================================================

  Future<void> continueToNextStep() async {
    final String title =
    titleController.text.trim();

    final String age =
    ageController.text.trim();

    final String description =
    descriptionController.text.trim();

    // ----------------------------------------------------------
    // VALIDATE TITLE
    // ----------------------------------------------------------

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a title"),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // VALIDATE AGE
    // ----------------------------------------------------------

    if (age.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the product age"),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // VALIDATE DESCRIPTION
    // ----------------------------------------------------------

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter product information",
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    final String category =
    (widget.aiResult["category"] ?? "")
        .toString()
        .trim();

    if (category.isEmpty ||
        category.toUpperCase() == "UNKNOWN") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Product category is not available.",
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // PRODUCT TYPE
    // ----------------------------------------------------------

    final String productType =
    (widget.aiResult["product_type"] ?? "")
        .toString()
        .trim();

    if (productType.isEmpty ||
        productType.toUpperCase() == "UNKNOWN") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Product type is not available.",
          ),
        ),
      );

      return;
    }

    setState(() {
      isPredictingPrice = true;
    });

    try {
      // ========================================================
      // 1. GET IMAGE PATH
      // ========================================================

      String? imagePath = widget.imagePath;

      // Admin-approved flow already has an image on the server.
      if (imagePath != null &&
          imagePath.isNotEmpty) {
        imagePath =
            imagePath.replaceAll("\\", "/");
      }

      // Normal AI flow has a local image.
      if ((imagePath == null ||
          imagePath.isEmpty) &&
          widget.image != null) {
        final imageResult =
        await ApiService.uploadProductImage(
          widget.image!,
        );

        imagePath =
            imageResult["image_path"]
                ?.toString()
                .replaceAll("\\", "/");
      }

      if (imagePath == null ||
          imagePath.isEmpty) {
        throw Exception(
          "Image path is not available",
        );
      }

      uploadedImagePath = imagePath;

      // ========================================================
      // 2. ASK BACKEND FOR AI PRICE
      // ========================================================

      final int predictedPrice =
      await ApiService.predictPrice(
        category: category,
        productType: productType,
        title: title,
        age: age,
        description: description,
        condition: condition,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        aiPrice = predictedPrice;
        isPredictingPrice = false;
      });

      // ========================================================
      // 3. SHOW PRICE
      // ========================================================

      showPricePredictionDialog();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isPredictingPrice = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to predict price: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // AI PRICE DIALOG
  // ============================================================

  void showPricePredictionDialog() {
    if (aiPrice == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "AI Suggested Price",
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
                "Our AI suggests this price based on the product information.",
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                showManualPriceDialog();
              },
              child: const Text(
                "ENTER MY OWN PRICE",
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                listProduct(
                  finalPrice: aiPrice!,
                );
              },
              child: const Text(
                "ACCEPT PRICE",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MANUAL PRICE
  // ============================================================

  void showManualPriceDialog() {
    final TextEditingController priceController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Enter Your Price",
          ),
          content: TextField(
            controller: priceController,
            keyboardType:
            TextInputType.number,
            decoration:
            const InputDecoration(
              labelText: "Price",
              prefixText: "₹ ",
              border:
              OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("CANCEL"),
            ),

            ElevatedButton(
              onPressed: () {
                final int? price =
                int.tryParse(
                  priceController.text.trim(),
                );

                if (price == null ||
                    price <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Enter a valid price",
                      ),
                    ),
                  );

                  return;
                }

                Navigator.pop(dialogContext);

                listProduct(
                  finalPrice: price,
                );
              },
              child: const Text(
                "CONTINUE",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CREATE PRODUCT
  // ============================================================

  Future<void> listProduct({
    required int finalPrice,
  }) async {
    try {
      // ========================================================
      // 1. GET IMAGE PATH
      // ========================================================

      String? imagePath =
          uploadedImagePath;

      // Admin-approved notification flow.
      if (imagePath == null ||
          imagePath.isEmpty) {
        imagePath = widget.imagePath;
      }

      if (imagePath != null &&
          imagePath.isNotEmpty) {
        imagePath =
            imagePath.replaceAll("\\", "/");
      }

      // Normal AI flow.
      if ((imagePath == null ||
          imagePath.isEmpty) &&
          widget.image != null) {
        final imageResult =
        await ApiService.uploadProductImage(
          widget.image!,
        );

        imagePath =
            imageResult["image_path"]
                ?.toString()
                .replaceAll("\\", "/");
      }

      if (imagePath == null ||
          imagePath.isEmpty) {
        throw Exception(
          "Image path is not available",
        );
      }

      // ========================================================
      // 2. CATEGORY ID
      // ========================================================

      final int categoryId =
          int.tryParse(
            widget.aiResult["category_id"]
                ?.toString() ??
                "",
          ) ??
              0;

      if (categoryId <= 0) {
        throw Exception(
          "Category ID is not available.",
        );
      }

      // ========================================================
      // 3. PRODUCT TYPE ID
      // ========================================================

      final int productTypeId =
          int.tryParse(
            widget.aiResult["product_type_id"]
                ?.toString() ??
                "",
          ) ??
              0;

      if (productTypeId <= 0) {
        throw Exception(
          "Product type ID is not available.",
        );
      }

      // ========================================================
      // 4. AI PRODUCT NAME
      // ========================================================

      final String aiProductName =
      (widget.aiResult["product_type"] ?? "")
          .toString()
          .trim();

      // ========================================================
      // 5. AI CONFIDENCE
      // ========================================================

      final double? aiConfidence =
      double.tryParse(
        widget.aiResult["confidence"]
            ?.toString() ??
            "",
      );

      // ========================================================
      // 6. DESCRIPTION
      // ========================================================

      final String finalDescription =
          "Age: ${ageController.text.trim()}\n"
          "${descriptionController.text.trim()}";

      // ========================================================
      // 7. CREATE PRODUCT
      // ========================================================

      final result =
      await ApiService.createProduct(
        categoryId: categoryId,

        productTypeId: productTypeId,

        title:
        titleController.text.trim(),

        description:
        finalDescription,

        condition:
        condition,

        price:
        finalPrice,

        aiPrice:
        aiPrice ?? finalPrice,

        location:
        locationController.text.trim(),

        imagePath:
        imagePath,

        aiProductName:
        aiProductName.isEmpty
            ? null
            : aiProductName,

        aiConfidence:
        aiConfidence,

        attributes: {},
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result["message"] ??
                "Product listed successfully",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to list product: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
            // ==================================================
            // IMAGE
            // ==================================================

            ClipRRect(
              borderRadius:
              BorderRadius.circular(20),

              child: SizedBox(
                height: 220,
                width: double.infinity,

                child:
                widget.allImages.isNotEmpty
                    ? PageView.builder(
                  itemCount:
                  widget.allImages.length,

                  itemBuilder:
                      (context, index) {
                    return Image.file(
                      widget
                          .allImages[index],

                      width:
                      double.infinity,

                      height: 220,

                      fit:
                      BoxFit.cover,
                    );
                  },
                )
                    : widget.image != null
                    ? Image.file(
                  widget.image!,

                  width:
                  double.infinity,

                  height: 220,

                  fit:
                  BoxFit.cover,
                )
                    : widget.imagePath != null &&
                    widget.imagePath!
                        .isNotEmpty
                    ? Image.network(
                  getImageUrl(
                    widget
                        .imagePath!,
                  ),

                  width:
                  double.infinity,

                  height: 220,

                  fit:
                  BoxFit.cover,
                )
                    : const Center(
                  child: Icon(
                    Icons
                        .image_not_supported,
                    size: 60,
                    color:
                    Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TITLE
            // ==================================================

            const Text(
              "Title",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
              titleController,

              decoration:
              const InputDecoration(
                hintText:
                "Enter product title",

                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // AGE
            // ==================================================

            const Text(
              "Age",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
              ageController,

              keyboardType:
              TextInputType.number,

              decoration:
              const InputDecoration(
                hintText:
                "Example: 2 years",

                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            const Text(
              "Description",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
              descriptionController,

              maxLines: 10,

              decoration:
              const InputDecoration(
                hintText:
                "Enter product information\n\n"
                    "Example:\n"
                    "Battery Life: 12 hours\n"
                    "RAM: 8 GB\n"
                    "Storage: 256 GB\n"
                    "Color: Black",

                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // CONDITION
            // ==================================================

            const Text(
              "Condition",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value:
              condition,

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

              onChanged:
                  (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  condition =
                      value;
                });
              },
            ),

            const SizedBox(height: 30),

            // ==================================================
            // GET AI PRICE
            // ==================================================

            SizedBox(
              width:
              double.infinity,

              child:
              ElevatedButton(
                onPressed:
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

                child:
                isPredictingPrice
                    ? const SizedBox(
                  height: 22,
                  width: 22,

                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "GET AI PRICE",

                  style:
                  TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
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