import 'dart:io';

import 'package:flutter/material.dart';

class UnsupportedProductScreen extends StatelessWidget {
  final File image;
  final Map<String, dynamic> aiResult;

  const UnsupportedProductScreen({
    super.key,
    required this.image,
    required this.aiResult,
  });

  @override
  Widget build(BuildContext context) {
    final String productType =
    (aiResult["product_type"] ?? "Unknown")
        .toString()
        .trim();

    final String category =
    (aiResult["category"] ?? "Unknown")
        .toString()
        .trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Product Review",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.center,

          children: [
            const SizedBox(height: 15),

            // PRODUCT IMAGE
            ClipRRect(
              borderRadius:
              BorderRadius.circular(20),

              child: Image.file(
                image,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 30),

            // ICON
            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade50,
              ),

              child: Icon(
                Icons.info_outline,
                size: 55,
                color: Colors.orange.shade800,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Product Currently Unsupported",
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Sellify could not identify this product "
                  "as one of the currently supported product types.",
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 25),

            // AI RESULT
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                BorderRadius.circular(16),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  const Text(
                    "AI Analysis",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Product Type: $productType",
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Category: $category",
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ADMIN REVIEW MESSAGE
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.shade100,
                ),
              ),

              child: const Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 38,
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Sent for Admin Review",
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "This product has been recorded as an "
                        "unsupported product. An administrator "
                        "can add it as a new product type and "
                        "category.",
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // BACK BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .popUntil(
                        (route) => route.isFirst,
                  );
                },

                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                ),

                child: const Text(
                  "BACK TO HOME",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "You can return later after the product type "
                  "has been added by an administrator.",
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}