import 'package:flutter/material.dart';

import '../services/api_service.dart';

class EditMyProductScreen extends StatefulWidget {
  final int productId;

  const EditMyProductScreen({
    super.key,
    required this.productId,
  });

  @override
  State<EditMyProductScreen> createState() =>
      _EditMyProductScreenState();
}

class _EditMyProductScreenState
    extends State<EditMyProductScreen> {

  bool isLoading = true;
  bool isSaving = false;

  Map<String, dynamic>? product;

  String? errorMessage;

  // ---------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController ageController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  final TextEditingController locationController =
  TextEditingController();

  // ---------------------------------------------------------
  // Condition
  // ---------------------------------------------------------

  String? selectedCondition;

  final List<String> conditions = [
    "New",
    "Like New",
    "Good",
    "Fair",
    "Used",
  ];

  // ---------------------------------------------------------
  // Price
  // ---------------------------------------------------------

  double? aiPrice;

  double? finalPrice;

  // ---------------------------------------------------------
  // INIT
  // ---------------------------------------------------------

  @override
  void initState() {
    super.initState();

    loadProduct();
  }

  @override
  void dispose() {
    titleController.dispose();
    ageController.dispose();
    descriptionController.dispose();
    locationController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD PRODUCT
  // =========================================================

  Future<void> loadProduct() async {
    try {
      final result =
      await ApiService.getMyProductDetails(
        productId: widget.productId,
      );

      if (!mounted) return;

      final p = result;

      titleController.text =
          p["title"]?.toString() ?? "";

      ageController.text =
          extractAge(p["description"]?.toString() ?? "");

      descriptionController.text =
          removeAgeFromDescription(
            p["description"]?.toString() ?? "",
          );

      locationController.text =
          p["location"]?.toString() ?? "";

      selectedCondition =
          p["condition"]?.toString();

      finalPrice =
          double.tryParse(
            p["price"]?.toString() ?? "",
          );

      setState(() {
        product = p;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // =========================================================
  // AGE FROM DESCRIPTION
  // =========================================================

  String extractAge(String description) {
    final lines = description.split("\n");

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.toLowerCase().startsWith("age:")) {
        return trimmed
            .substring(4)
            .trim();
      }
    }

    return "";
  }

  // =========================================================
  // REMOVE AGE FROM DESCRIPTION
  // =========================================================

  String removeAgeFromDescription(
      String description,
      ) {
    final lines = description.split("\n");

    final remainingLines = lines.where((line) {
      return !line.trim().toLowerCase().startsWith("age:");
    }).toList();

    return remainingLines.join("\n").trim();
  }

  // =========================================================
  // GET AI PRICE
  // =========================================================

  Future<void> getAIPrice() async {
    if (product == null) return;

    final title =
    titleController.text.trim();

    final age =
    ageController.text.trim();

    final description =
    descriptionController.text.trim();

    final condition =
        selectedCondition?.trim() ?? "";

    if (title.isEmpty) {
      showMessage("Please enter a title");
      return;
    }

    if (age.isEmpty) {
      showMessage("Please enter product age");
      return;
    }

    if (description.isEmpty) {
      showMessage("Please enter a description");
      return;
    }

    if (locationController.text.trim().isEmpty) {
      showMessage("Please enter your city");
      return;
    }

    if (condition.isEmpty) {
      showMessage("Please select condition");
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final result =
      await ApiService.predictPrice(
        category:
        product!["category"]?.toString() ?? "",
        productType:
        product!["product_type"]?.toString() ?? "",
        title: title,
        age: age,
        description: description,
        condition: condition,
      );

      if (!mounted) return;

      final predicted =
      result.toDouble();

      setState(() {
        isSaving = false;
        aiPrice = predicted;
      });

      await showPriceDialog(predicted);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage(
        "Failed to get AI price: $e",
      );
    }
  }
  // =========================================================
  // PRICE DIALOG
  // =========================================================

  Future<void> showPriceDialog(
      double predictedPrice,
      ) async {

    final manualPriceController =
    TextEditingController(
      text: predictedPrice
          .toStringAsFixed(0),
    );

    final result =
    await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "AI Suggested Price",
          ),

          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              Text(
                "AI suggests ₹${predictedPrice.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "You can accept the AI price or enter your own price.",
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                manualPriceController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                const InputDecoration(
                  labelText: "Final Price",
                  prefixText: "₹ ",
                  border:
                  OutlineInputBorder(),
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  null,
                );
              },
              child: const Text(
                "CANCEL",
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final price =
                double.tryParse(
                  manualPriceController
                      .text
                      .trim(),
                );

                if (price == null ||
                    price <= 0) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  price,
                );
              },
              child: const Text(
                "USE PRICE",
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        finalPrice = result;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manualPriceController.dispose();
    });
  }

  // =========================================================
  // SAVE CHANGES
  // =========================================================

  Future<void> saveChanges() async {
    if (product == null) return;

    if (finalPrice == null ||
        finalPrice! <= 0) {
      showMessage(
        "Please get AI price or enter a price first",
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await ApiService.updateProduct(
        productId: widget.productId,
        title: titleController.text.trim(),
        age: ageController.text.trim(),
        description:
        descriptionController.text.trim(),
        condition:
        selectedCondition ?? "",
        location:
        locationController.text.trim(),
        price: finalPrice!,
        aiPrice: aiPrice,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Product updated successfully",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage(
        "Failed to update product: $e",
      );
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor:
        Colors.white,
        elevation: 0,

        title: const Text(
          "Edit Product",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          textAlign:
          TextAlign.center,
        ),
      )
          : buildEditForm(),
    );
  }

  // =========================================================
  // EDIT FORM
  // =========================================================

  Widget buildEditForm() {
    final p = product!;

    final category =
        p["category"]?.toString() ?? "";

    final productType =
        p["product_type"]?.toString() ?? "";

    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(18),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          // ---------------------------------------------------
          // CATEGORY - READ ONLY
          // ---------------------------------------------------

          const Text(
            "Category",
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller:
            TextEditingController(
              text: category,
            ),
            readOnly: true,
            decoration:
            const InputDecoration(
              prefixIcon:
              Icon(Icons.category_outlined),
              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------
          // PRODUCT TYPE - READ ONLY
          // ---------------------------------------------------

          const Text(
            "Product Type",
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller:
            TextEditingController(
              text: productType,
            ),
            readOnly: true,
            decoration:
            const InputDecoration(
              prefixIcon:
              Icon(Icons.inventory_2_outlined),
              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------
          // TITLE
          // ---------------------------------------------------

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

          const SizedBox(height: 18),

          // ---------------------------------------------------
          // AGE
          // ---------------------------------------------------

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
            decoration:
            const InputDecoration(
              hintText:
              "Enter product age",
              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------
          // DESCRIPTION
          // ---------------------------------------------------

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
            maxLines: 6,
            decoration:
            const InputDecoration(
              hintText:
              "Enter product description",
              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------
          // CITY
          // ---------------------------------------------------

          const Text(
            "City",
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller:
            locationController,
            decoration:
            const InputDecoration(
              hintText:
              "Enter your city",
              prefixIcon:
              Icon(
                Icons.location_on_outlined,
              ),
              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------
          // CONDITION
          // ---------------------------------------------------

          const Text(
            "Condition",
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: selectedCondition,
            decoration:
            const InputDecoration(
              border:
              OutlineInputBorder(),
            ),
            items:
            conditions.map(
                  (condition) {
                return DropdownMenuItem<
                    String>(
                  value: condition,
                  child: Text(
                    condition,
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              setState(() {
                selectedCondition =
                    value;
              });
            },
          ),

          const SizedBox(height: 25),

          // ---------------------------------------------------
          // AI PRICE
          // ---------------------------------------------------

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed:
              isSaving
                  ? null
                  : getAIPrice,

              icon: const Icon(
                Icons.auto_awesome,
              ),

              label: Text(
                aiPrice == null
                    ? "GET AI PRICE"
                    : "RECALCULATE AI PRICE",
              ),

              style:
              ElevatedButton.styleFrom(
                minimumSize:
                const Size(
                  double.infinity,
                  52,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ---------------------------------------------------
          // CURRENT FINAL PRICE
          // ---------------------------------------------------

          if (finalPrice != null)
            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets.all(16),

              decoration:
              BoxDecoration(
                color:
                Colors.green.shade50,

                borderRadius:
                BorderRadius.circular(
                  12,
                ),

                border:
                Border.all(
                  color:
                  Colors.green.shade200,
                ),
              ),

              child: Text(
                "Final Price: ₹${finalPrice!.toStringAsFixed(0)}",
                style:
                TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Colors.green.shade700,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ---------------------------------------------------
          // SAVE
          // ---------------------------------------------------

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed:
              isSaving
                  ? null
                  : saveChanges,

              style:
              ElevatedButton.styleFrom(
                minimumSize:
                const Size(
                  double.infinity,
                  55,
                ),
              ),

              child: isSaving
                  ? const SizedBox(
                height: 22,
                width: 22,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : const Text(
                "SAVE CHANGES",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}