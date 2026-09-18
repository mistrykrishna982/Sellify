import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    loadMyProducts();
  }

  // =========================================================
  // LOAD MY PRODUCTS
  // =========================================================

  Future<void> loadMyProducts() async {

    try {

      final userId = await AuthService.getUserId();

      if (userId == null || userId.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "Please login again.";
        });
        return;
      }

      final result = await ApiService.getMyProducts(
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        products = result;
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
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "My Products",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                Icons.error_outline_rounded,
                size: 55,
                color: Colors.red.shade400,
              ),

              const SizedBox(height: 15),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: loadMyProducts,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      )
          : products.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
        onRefresh: loadMyProducts,

        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),

          itemCount: products.length,

          itemBuilder: (context, index) {

            final product = products[index];

            return buildProductCard(
              product,
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget buildEmptyState() {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            Container(
              height: 90,
              width: 90,

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.inventory_2_outlined,
                size: 45,
                color: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "No Products Yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Products you list for sale will appear here.",
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PRODUCT CARD
  // =========================================================

  Widget buildProductCard(
      Map<String, dynamic> product,
      ) {

    final imagePath =
        product["image_path"]?.toString() ?? "";

    final imageUrl =
    imagePath.isNotEmpty
        ? "${ApiService.baseUrl}/$imagePath"
        : null;

    final title =
        product["title"]?.toString() ??
            "Untitled Product";

    final category =
        product["category"]?.toString() ??
            "Unknown";

    final location =
        product["location"]?.toString() ??
            "Location unavailable";

    final condition =
        product["condition"]?.toString() ??
            "Unknown";

    final price =
        product["price"]?.toString() ??
            "0";

    final status =
        product["status"]?.toString() ??
            "UNKNOWN";

    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(
        bottom: 16,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          // =================================================
          // IMAGE
          // =================================================

          SizedBox(
            height: 200,
            width: double.infinity,

            child: imageUrl != null
                ? Image.network(
              imageUrl,

              fit: BoxFit.cover,

              errorBuilder:
                  (context, error, stackTrace) {

                return Container(
                  color: Colors.grey.shade100,

                  child: const Icon(
                    Icons.image_outlined,
                    size: 65,
                    color: Colors.grey,
                  ),
                );
              },

              loadingBuilder:
                  (context, child, loadingProgress) {

                if (loadingProgress == null) {
                  return child;
                }

                return Container(
                  color: Colors.grey.shade100,

                  child: const Center(
                    child:
                    CircularProgressIndicator(),
                  ),
                );
              },
            )
                : Container(
              color: Colors.grey.shade100,

              child: const Icon(
                Icons.image_outlined,
                size: 65,
                color: Colors.grey,
              ),
            ),
          ),

          // =================================================
          // PRODUCT INFORMATION
          // =================================================

          Padding(
            padding: const EdgeInsets.all(14),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // CATEGORY + STATUS

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius:
                        BorderRadius.circular(8),
                      ),

                      child: Text(
                        category,

                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Colors.blue.shade700,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius:
                        BorderRadius.circular(8),
                      ),

                      child: Text(
                        status,

                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // TITLE

                Text(
                  title,

                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // PRICE

                Text(
                  "₹$price",

                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 10),

                // CONDITION

                Row(
                  children: [

                    Icon(
                      Icons.verified_outlined,
                      size: 17,
                      color:
                      Colors.grey.shade600,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      condition,

                      style: TextStyle(
                        fontSize: 13,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // LOCATION

                Row(
                  children: [

                    Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color:
                      Colors.grey.shade600,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        location,

                        style: TextStyle(
                          fontSize: 13,
                          color:
                          Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}