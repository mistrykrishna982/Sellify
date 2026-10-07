import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageUnsupportedProductsScreen extends StatefulWidget {
  const ManageUnsupportedProductsScreen({super.key});

  @override
  State<ManageUnsupportedProductsScreen> createState() =>
      _ManageUnsupportedProductsScreenState();
}

class _ManageUnsupportedProductsScreenState
    extends State<ManageUnsupportedProductsScreen> {
  List<Map<String, dynamic>> unsupportedProducts = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadUnsupportedProducts();
  }

  Future<void> loadUnsupportedProducts() async {
    try {
      final result = await ApiService.getUnsupportedProducts();

      if (!mounted) return;

      setState(() {
        unsupportedProducts = result;
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


  Future<void> approveProductRequest(
      Map<String, dynamic> product) async {
    final unsupportedProductId =
    product["unsupported_product_id"];

    if (unsupportedProductId == null) {
      return;
    }

    try {
      final result =
      await ApiService.approveUnsupportedProduct(
        unsupportedProductId:
        unsupportedProductId is int
            ? unsupportedProductId
            : int.parse(
          unsupportedProductId.toString(),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Approved: ${result["product_type_name"]} "
                "under ${result["category_name"]}",
          ),
        ),
      );

      await loadUnsupportedProducts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Approval failed: $e",
          ),
        ),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Unsupported Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (unsupportedProducts.isEmpty) {
      return const Center(
        child: Text(
          "No unsupported products.",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadUnsupportedProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unsupportedProducts.length,
        itemBuilder: (context, index) {
          final product =
          unsupportedProducts[index];

          final productName =
              product["product_name"]
                  ?.toString() ??
                  "Unknown";

          final requestedCategoryName =
              product["requested_category_name"]
                  ?.toString() ??
                  "Unknown category";

          final userName =
              product["user_name"]
                  ?.toString() ??
                  "Unknown user";

          final userId =
              product["user_id"]
                  ?.toString() ??
                  "Unknown";

          final requestCount =
              product["request_count"] ?? 0;

          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),

              leading: CircleAvatar(
                backgroundColor:
                Colors.orange.shade100,
                child: Icon(
                  Icons.report_problem_outlined,
                  color: Colors.orange.shade800,
                ),
              ),

              title: Text(
                productName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  Text(
                    "Category: $requestedCategoryName",
                  ),

                  Text(
                    "Requested by: $userName (ID: $userId)",
                  ),

                  Text(
                    "Requests: $requestCount",
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product["status"]?.toString() ?? "PENDING",
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  approveProductRequest(product);
                },
                child: const Text("Approve"),
              ),
            ),
          );
        },
      ),
    );
  }
}