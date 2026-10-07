import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';


class EditProductClassificationScreen
    extends StatefulWidget {

  final File image;
  final List<File> allImages;
  final Map<String, dynamic> aiResult;

  const EditProductClassificationScreen({
    super.key,
    required this.image,
    required this.allImages,
    required this.aiResult,
  });

  @override
  State<EditProductClassificationScreen> createState() =>
      _EditProductClassificationScreenState();
}

class _EditProductClassificationScreenState
    extends State<EditProductClassificationScreen> {

  final TextEditingController categoryController =
  TextEditingController();

  final TextEditingController productTypeController =
  TextEditingController();

  bool isSubmitting = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final String aiCategory =
    (widget.aiResult["category"] ?? "").toString();

    final String aiProductType =
    (widget.aiResult["product_type"] ?? "").toString();

    if (aiCategory.isNotEmpty &&
        aiCategory.toUpperCase() != "UNKNOWN") {

      categoryController.text = aiCategory;
    }

    if (aiProductType.isNotEmpty &&
        aiProductType.toUpperCase() != "UNKNOWN") {

      productTypeController.text = aiProductType;
    }
  }

  @override
  void dispose() {

    categoryController.dispose();
    productTypeController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT CLASSIFICATION REQUEST
  // ============================================================

  Future<void> submitClassificationRequest() async {

    final String category =
    categoryController.text.trim();

    final String productType =
    productTypeController.text.trim();

    if (category.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a category.",
          ),
        ),
      );

      return;
    }

    if (productType.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a product type.",
          ),
        ),
      );

      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {

      // --------------------------------------------------------
      // Image was already uploaded during AI analysis.
      // --------------------------------------------------------

      String imagePath =
      (widget.aiResult["image_path"] ?? "")
          .toString();

      // --------------------------------------------------------
      // Safety fallback:
      // upload image if image_path is missing.
      // --------------------------------------------------------

      if (imagePath.isEmpty) {

        final uploadResult =
        await ApiService.uploadProductImage(
          widget.image,
        );

        imagePath =
            (uploadResult["image_path"] ?? "")
                .toString();
      }

      if (imagePath.isEmpty) {
        throw Exception(
          "Image path was not returned by server.",
        );
      }

      // --------------------------------------------------------
      // SEND REQUEST TO ADMIN
      // --------------------------------------------------------

      await ApiService.submitClassificationRequest(
        categoryName: category,
        productTypeName: productType,
        imagePath: imagePath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Request sent to admin. You will receive a notification after approval.",
          ),
        ),
      );
      Navigator.of(context).popUntil(
            (route) => route.isFirst,
      );


    } catch (e) {

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Edit Product",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "Enter Product Information",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "AI could not correctly identify your "
                  "product. Enter the category and product "
                  "type. An admin will review your request.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            ClipRRect(
              borderRadius:
              BorderRadius.circular(18),

              child: Image.file(
                widget.image,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Category",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: categoryController,
              textCapitalization:
              TextCapitalization.words,

              decoration: const InputDecoration(
                hintText: "Enter category",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Product Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
              productTypeController,

              textCapitalization:
              TextCapitalization.words,

              decoration: const InputDecoration(
                hintText: "Enter product type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                isSubmitting
                    ? null
                    : submitClassificationRequest,

                style:
                ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                ),

                child: isSubmitting
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "SEND TO ADMIN",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (errorMessage != null) ...[

              const SizedBox(height: 20),

              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
