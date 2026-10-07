import 'package:flutter/material.dart';
import 'EditMyProductScreen.dart';
import '../services/api_service.dart';

class MyProductDetailsScreen extends StatefulWidget {

  final int productId;

  const MyProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<MyProductDetailsScreen> createState() =>
      _MyProductDetailsScreenState();
}

class _MyProductDetailsScreenState
    extends State<MyProductDetailsScreen> {

  bool isLoading = true;

  String? errorMessage;

  Map<String, dynamic>? product;

  int currentImageIndex = 0;

  final PageController pageController =
  PageController();

  @override
  void initState() {
    super.initState();

    loadProduct();
  }

  @override
  void dispose() {
    pageController.dispose();

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

      setState(() {
        product = result;
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
  // IMAGE URL
  // =========================================================

  String getImageUrl(String imagePath) {

    if (imagePath.startsWith("http://") ||
        imagePath.startsWith("https://")) {
      return imagePath;
    }

    return "${ApiService.baseUrl}/$imagePath";
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
          "Product Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? buildErrorState()
          : product == null
          ? buildErrorState()
          : buildProductDetails(),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget buildErrorState() {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade400,
            ),

            const SizedBox(height: 15),

            Text(
              errorMessage ??
                  "Product not found",
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {

                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                loadProduct();
              },

              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PRODUCT DETAILS
  // =========================================================

  Widget buildProductDetails() {

    final p = product!;

    final List images =
        (p["images"] as List?) ?? [];

    final title =
        p["title"]?.toString() ??
            "Untitled Product";

    final category =
        p["category"]?.toString() ??
            "Unknown";

    final productType =
        p["product_type"]?.toString() ??
            "Unknown";

    final description =
        p["description"]?.toString() ??
            "";

    final condition =
        p["condition"]?.toString() ??
            "Unknown";

    final location =
        p["location"]?.toString() ??
            "Location unavailable";

    final status =
        p["status"]?.toString() ??
            "UNKNOWN";

    final price =
        p["price"]?.toString() ??
            "0";

    final aiPrice =
    p["ai_price"]?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          // =================================================
          // IMAGE SLIDER
          // =================================================

          buildImageSlider(images),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // =================================================
                // STATUS
                // =================================================

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // =================================================
                // TITLE
                // =================================================

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),


                // =================================================
                // PRICE
                // =================================================

                buildInformationCard(
                  title: "Price Information",

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Row(
                        children: [

                          Text(
                            "₹$price",

                            style: TextStyle(
                              fontSize: 30,
                              fontWeight:
                              FontWeight.bold,
                              color:
                              Colors.green.shade700,
                            ),
                          ),

                          const SizedBox(width: 12),

                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // PRODUCT INFORMATION
                // =================================================

                buildInformationCard(
                  title: "Product Information",

                  child: Column(
                    children: [

                      buildDetailRow(
                        Icons.category_outlined,
                        "Category",
                        category,
                      ),

                      buildDivider(),

                      buildDetailRow(
                        Icons.inventory_2_outlined,
                        "Product Type",
                        productType,
                      ),

                      buildDivider(),

                      buildDetailRow(
                        Icons.verified_outlined,
                        "Condition",
                        condition,
                      ),

                      buildDivider(),

                      buildDetailRow(
                        Icons.location_on_outlined,
                        "Location",
                        location,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // DESCRIPTION
                // =================================================

                buildInformationCard(
                  title: "Description",

                  child: Text(
                    description.isEmpty
                        ? "No description available."
                        : description,

                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // ATTRIBUTES
                // =================================================

                buildAttributesCard(p),

                const SizedBox(height: 20),

                // =================================================
                // ACTION BUTTONS
                // =================================================

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditMyProductScreen(
                                productId: widget.productId,
                              ),
                            ),
                          );

                          if (result == true && mounted) {
                            await loadProduct();
                          }
                        },

                        icon: const Icon(
                          Icons.edit_outlined,
                        ),

                        label: const Text(
                          "EDIT",
                        ),

                        style:
                        OutlinedButton.styleFrom(
                          minimumSize:
                          const Size(
                            0,
                            52,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text(
                                  "Delete Product?",
                                ),
                                content: const Text(
                                  "Are you sure you don't want to sell this product anymore?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        dialogContext,
                                        false,
                                      );
                                    },
                                    child: const Text(
                                      "CANCEL",
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        dialogContext,
                                        true,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.red.shade600,
                                      foregroundColor:
                                      Colors.white,
                                    ),
                                    child: const Text(
                                      "DELETE",
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldDelete != true) {
                            return;
                          }

                          try {
                            await ApiService.deleteProduct(
                              productId: widget.productId,
                            );

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Product deleted successfully",
                                ),
                              ),
                            );

                            Navigator.pop(context);
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Failed to delete product: $e",
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                        label: const Text(
                          "DELETE",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.red.shade600,
                          foregroundColor:
                          Colors.white,
                          minimumSize:
                          const Size(
                            0,
                            52,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
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

  // =========================================================
  // IMAGE SLIDER
  // =========================================================

  Widget buildImageSlider(List images) {

    if (images.isEmpty) {

      return Container(
        height: 300,
        width: double.infinity,

        color: Colors.grey.shade100,

        child: const Icon(
          Icons.image_outlined,
          size: 80,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      children: [

        SizedBox(
          height: 330,
          width: double.infinity,

          child: PageView.builder(
            controller: pageController,

            itemCount: images.length,

            onPageChanged: (index) {

              setState(() {
                currentImageIndex = index;
              });
            },

            itemBuilder: (context, index) {

              final imagePath =
                  images[index]["image_path"]
                      ?.toString() ??
                      "";

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(18),

                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                clipBehavior:
                Clip.antiAlias,

                child: imagePath.isEmpty
                    ? const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                )
                    : Image.network(
                  getImageUrl(imagePath),

                  fit: BoxFit.contain,

                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                    );
                  },

                  loadingBuilder:
                      (
                      context,
                      child,
                      loadingProgress,
                      ) {

                    if (loadingProgress ==
                        null) {
                      return child;
                    }

                    return const Center(
                      child:
                      CircularProgressIndicator(),
                    );
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // =====================================================
        // IMAGE DOTS
        // =====================================================

        if (images.length > 1)
          Row(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children:
            List.generate(
              images.length,

                  (index) {

                final selected =
                    currentImageIndex ==
                        index;

                return AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds: 200,
                  ),

                  margin:
                  const EdgeInsets.symmetric(
                    horizontal: 3,
                  ),

                  height: 8,

                  width: selected
                      ? 22
                      : 8,

                  decoration:
                  BoxDecoration(
                    color: selected
                        ? Colors.blue
                        : Colors.grey.shade400,

                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // =========================================================
  // TAG
  // =========================================================

  Widget buildTag(
      IconData icon,
      String text,
      ) {

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: Colors.blue.shade50,

        borderRadius:
        BorderRadius.circular(10),
      ),

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [

          Icon(
            icon,
            size: 16,
            color: Colors.blue.shade700,
          ),

          const SizedBox(width: 5),

          Text(
            text,

            style: TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
              color:
              Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFORMATION CARD
  // =========================================================

  Widget buildInformationCard({
    required String title,
    required Widget child,
  }) {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            title,

            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          child,
        ],
      ),
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget buildDetailRow(
      IconData icon,
      String title,
      String value,
      ) {

    return Row(
      children: [

        Container(
          height: 38,
          width: 38,

          decoration: BoxDecoration(
            color: Colors.blue.shade50,

            borderRadius:
            BorderRadius.circular(10),
          ),

          child: Icon(
            icon,
            size: 20,
            color: Colors.blue.shade700,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,

            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),

        Text(
          value,

          textAlign: TextAlign.right,

          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DIVIDER
  // =========================================================

  Widget buildDivider() {

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }

  // =========================================================
  // ATTRIBUTES
  // =========================================================

  Widget buildAttributesCard(
      Map<String, dynamic> p,
      ) {

    final List attributes =
        (p["attributes"] as List?) ?? [];

    if (attributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return buildInformationCard(
      title: "Product Attributes",

      child: Column(
        children:
        List.generate(
          attributes.length,

              (index) {

            final attribute =
            attributes[index];

            final attributeId =
                attribute["attribute_id"]
                    ?.toString() ??
                    "";

            final value =
                attribute["value"]
                    ?.toString() ??
                    "";

            return Column(
              children: [

                buildDetailRow(
                  Icons.tune_outlined,
                  "Attribute $attributeId",
                  value,
                ),

                if (index !=
                    attributes.length - 1)
                  buildDivider(),
              ],
            );
          },
        ),
      ),
    );
  }
}