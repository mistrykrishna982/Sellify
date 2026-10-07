import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ProductDetailsScreen.dart';

class ClassificationRequestPendingScreen
    extends StatefulWidget {
  final int requestId;

  final File image;
  final List<File> allImages;
  final Map<String, dynamic> aiResult;

  const ClassificationRequestPendingScreen({
    super.key,
    required this.requestId,
    required this.image,
    required this.allImages,
    required this.aiResult,
  });

  @override
  State<ClassificationRequestPendingScreen> createState() =>
      _ClassificationRequestPendingScreenState();
}

class _ClassificationRequestPendingScreenState
    extends State<ClassificationRequestPendingScreen> {

  Timer? _timer;

  bool _checking = false;

  bool _decisionShown = false;

  @override
  void initState() {
    super.initState();

    // Check immediately.
    _checkStatus();

    // Then check every 5 seconds.
    _timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // GET VALUE FROM API
  //
  // Supports both:
  //
  // STATUS
  // status
  //
  // CATEGORY_ID
  // category_id
  // ============================================================

  dynamic _getValue(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final key in keys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().trim().isNotEmpty &&
          data[key].toString().toLowerCase() != "null") {
        return data[key];
      }
    }

    return null;
  }

  // ============================================================
  // GET INTEGER SAFELY
  // ============================================================

  int? _getInt(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    final value = _getValue(data, keys);

    if (value == null) {
      return null;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // CHECK REQUEST STATUS
  // ============================================================

  Future<void> _checkStatus() async {
    if (_checking || _decisionShown) {
      return;
    }

    _checking = true;

    try {
      final result =
      await ApiService.getClassificationRequest(
        widget.requestId,
      );

      debugPrint(
        "CLASSIFICATION STATUS RESPONSE: $result",
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      final String status =
      (_getValue(
        result,
        [
          "STATUS",
          "status",
          "Status",
        ],
      ) ??
          "")
          .toString()
          .trim()
          .toUpperCase();

      debugPrint(
        "CLASSIFICATION REQUEST STATUS: $status",
      );

      // ========================================================
      // APPROVED
      // ========================================================

      if (status == "APPROVED") {
        _timer?.cancel();

        if (_decisionShown) {
          return;
        }

        _decisionShown = true;

        final int? categoryId =
        _getInt(
          result,
          [
            "CATEGORY_ID",
            "category_id",
            "categoryId",
          ],
        );

        final int? productTypeId =
        _getInt(
          result,
          [
            "PRODUCT_TYPE_ID",
            "product_type_id",
            "productTypeId",
          ],
        );

        final String categoryName =
        (_getValue(
          result,
          [
            "CATEGORY_NAME",
            "category_name",
            "categoryName",
          ],
        ) ??
            "")
            .toString()
            .trim();

        final String productTypeName =
        (_getValue(
          result,
          [
            "PRODUCT_TYPE_NAME",
            "product_type_name",
            "productTypeName",
          ],
        ) ??
            "")
            .toString()
            .trim();

        // ------------------------------------------------------
        // IMPORTANT
        // Do not continue if IDs are missing.
        // ------------------------------------------------------

        if (categoryId == null ||
            categoryId <= 0 ||
            productTypeId == null ||
            productTypeId <= 0) {

          debugPrint(
            "APPROVAL ERROR: IDs missing. Response: $result",
          );

          _decisionShown = false;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Admin approved the request, but category information is incomplete.",
              ),
            ),
          );

          return;
        }

        await _showApprovalPopup(
          categoryId: categoryId,
          productTypeId: productTypeId,
          categoryName: categoryName,
          productTypeName: productTypeName,
        );

        return;
      }

      // ========================================================
      // REJECTED
      // ========================================================

      if (status == "REJECTED") {
        _timer?.cancel();

        if (_decisionShown) {
          return;
        }

        _decisionShown = true;

        final String note =
        (_getValue(
          result,
          [
            "ADMIN_NOTE",
            "admin_note",
            "adminNote",
          ],
        ) ??
            "Your classification request was rejected.")
            .toString();

        await _showRejectedPopup(note);

        return;
      }

      // ========================================================
      // PENDING
      // ========================================================

      if (status == "PENDING") {
        debugPrint(
          "Classification request still pending.",
        );
      }

    } catch (e) {
      debugPrint(
        "Classification status error: $e",
      );
    } finally {
      _checking = false;
    }
  }

  // ============================================================
  // APPROVED POPUP
  // ============================================================

  Future<void> _showApprovalPopup({
    required int categoryId,
    required int productTypeId,
    required String categoryName,
    required String productTypeName,
  }) async {

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Classification Approved",
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const Text(
                "Great! Your product classification "
                    "has been approved by admin.",
                style: TextStyle(
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(12),

                  color: Colors.green.withOpacity(0.08),
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Approved Classification",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Category: $categoryName",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Product Type: $productTypeName",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Continue to enter your product details.",
              ),
            ],
          ),

          actions: [

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {

                  Navigator.of(
                    dialogContext,
                  ).pop();

                  // ------------------------------------------------
                  // UPDATE AI RESULT WITH ADMIN APPROVED DATA
                  // ------------------------------------------------

                  final Map<String, dynamic>
                  updatedResult = {

                    ...widget.aiResult,

                    "category_id":
                    categoryId,

                    "product_type_id":
                    productTypeId,

                    "category":
                    categoryName,

                    "product_type":
                    productTypeName,

                    "user_edited_classification":
                    true,
                  };

                  // ------------------------------------------------
                  // GO DIRECTLY TO PRODUCT DETAILS
                  // ------------------------------------------------

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailsScreen(
                            image: widget.image,
                            allImages:
                            widget.allImages,
                            aiResult:
                            updatedResult,
                          ),
                    ),
                  );
                },

                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),

                child: const Text(
                  "CONTINUE TO PRODUCT DETAILS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REJECTED POPUP
  // ============================================================

  Future<void> _showRejectedPopup(
      String note,
      ) async {

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(18),
          ),

          title: const Row(
            children: [

              Icon(
                Icons.cancel,
                color: Colors.red,
                size: 30,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Request Rejected",
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize:
            MainAxisSize.min,

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const Text(
                "Your classification request "
                    "was not approved by admin.",
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,

                padding:
                const EdgeInsets.all(12),

                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(10),

                  color: Colors.red.withOpacity(
                    0.08,
                  ),
                ),

                child: Text(
                  note,
                ),
              ),
            ],
          ),

          actions: [

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {

                  Navigator.of(
                    dialogContext,
                  ).pop();

                  // Return to AI analysis screen.
                  Navigator.of(context).pop();
                },

                child: const Text(
                  "GO BACK",
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Classification Request",
        ),
      ),

      body: Center(

        child: Padding(
          padding:
          const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.hourglass_top,
                size: 70,
              ),

              const SizedBox(height: 20),

              const Text(
                "Waiting for Admin Approval",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
                textAlign:
                TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                "Your classification request "
                    "has been sent to admin.\n\n"
                    "You will be notified here when "
                    "admin approves or rejects it.",
                textAlign:
                TextAlign.center,
              ),

              const SizedBox(height: 25),

              const CircularProgressIndicator(),

              const SizedBox(height: 20),

              Text(
                "Request #${widget.requestId}",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}