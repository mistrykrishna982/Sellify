import 'dart:io';

import 'package:flutter/material.dart';
import 'admin/UnsupportedProductScreen.dart';
import 'ProductDetailsScreen.dart';


class AIAnalysisScreen extends StatefulWidget {
  final File image;
  final List<File> allImages;
  final Map<String, dynamic> result;

  const AIAnalysisScreen({
    super.key,
    required this.image,
    required this.allImages,
    required this.result,
  });

  @override
  State<AIAnalysisScreen> createState() =>
      _AIAnalysisScreenState();
}


class _AIAnalysisScreenState
    extends State<AIAnalysisScreen> {


  // ------------------------------------------------
  // CONTINUE TO PRODUCT DETAILS
  // ------------------------------------------------

  void continueToProductDetails() {
    final String productType =
    (widget.result["product_type"] ?? "Unknown")
        .toString()
        .trim();

    final dynamic productTypeId =
    widget.result["product_type_id"];

    final bool isUnsupported =
        productType.isEmpty ||
            productType.toLowerCase() == "unknown" ||
            productTypeId == null;

    if (isUnsupported) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UnsupportedProductScreen(
                image: widget.image,
                aiResult: {
                  ...widget.result,
                },
              ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailsScreen(
              image: widget.image,
              allImages: widget.allImages,
              aiResult: {
                ...widget.result,
              },
            ),
      ),
    );
  }


  // ------------------------------------------------
  // BUILD
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {

    final String productType =
        widget.result["product_type"] ??
            widget.result["category"] ??
            "Unknown";

    final double confidence =
    (widget.result["confidence"] ?? 0)
        .toDouble();


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "AI Product Analysis",

          style: TextStyle(
            fontWeight:
            FontWeight.bold,
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

            // ----------------------------------------
            // TITLE
            // ----------------------------------------

            const Text(
              "AI Analysis",

              style: TextStyle(
                fontSize: 28,
                fontWeight:
                FontWeight.bold,
              ),
            ),


            const SizedBox(height: 8),


            Text(
              "Our AI analyzed your product image.",

              style: TextStyle(
                fontSize: 15,
                color:
                Colors.grey.shade600,
              ),
            ),


            const SizedBox(height: 25),


            // ----------------------------------------
            // IMAGE
            // ----------------------------------------

            ClipRRect(

              borderRadius:
              BorderRadius.circular(20),

              child: Image.file(

                widget.image,

                width:
                double.infinity,

                height: 280,

                fit: BoxFit.cover,
              ),
            ),


            const SizedBox(height: 25),


            // ----------------------------------------
            // AI RESULT CARD
            // ----------------------------------------

            Container(

              width:
              double.infinity,

              padding:
              const EdgeInsets.all(20),

              decoration:
              BoxDecoration(

                borderRadius:
                BorderRadius.circular(20),

                color:
                Colors.grey.shade100,

                border:
                Border.all(
                  color:
                  Colors.grey.shade300,
                ),
              ),


              child: Column(

                children: [

                  const Icon(
                    Icons.auto_awesome,
                    size: 45,
                  ),


                  const SizedBox(height: 15),


                  const Text(
                    "AI detected:",

                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),


                  const SizedBox(height: 8),


                  Text(

                    productType
                        .toUpperCase(),

                    textAlign:
                    TextAlign.center,

                    style:
                    const TextStyle(
                      fontSize: 23,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),


                  const SizedBox(height: 25),


                  const Text(
                    "Sellify Category:",

                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),


                  const SizedBox(height: 8),


                  Text(
                    (widget.result["category"] ?? "Unknown")
                        .toString()
                        .toUpperCase(),

                    textAlign:
                    TextAlign.center,

                    style:
                    const TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),


                  const SizedBox(height: 12),


                  Text(

                    "Confidence: "
                        "${confidence.toStringAsFixed(2)}%",

                    style:
                    const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                ],
              ),
            ),


            const SizedBox(height: 30),


            // ----------------------------------------
            // INFORMATION
            // ----------------------------------------

            Container(

              width:
              double.infinity,

              padding:
              const EdgeInsets.all(16),

              decoration:
              BoxDecoration(

                borderRadius:
                BorderRadius.circular(15),

                color:
                Colors.blueGrey.shade50,
              ),

              child: const Text(

                "AI automatically selected the "
                    "most suitable Sellify category "
                    "for this product.",

                textAlign:
                TextAlign.center,

                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),


            const SizedBox(height: 25),


            // ----------------------------------------
            // CONFIRMATION
            // ----------------------------------------

            const Center(

              child: Text(
                "Is this correct?",

                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),


            const SizedBox(height: 15),


            // ----------------------------------------
            // CONTINUE BUTTON
            // ----------------------------------------

            SizedBox(

              width:
              double.infinity,

              child:
              ElevatedButton(

                onPressed:
                continueToProductDetails,

                style:
                ElevatedButton.styleFrom(

                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 17,
                  ),
                ),

                child:
                const Text(
                  "YES, CONTINUE",

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