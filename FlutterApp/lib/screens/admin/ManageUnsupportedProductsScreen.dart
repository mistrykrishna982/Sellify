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


  Future<void> addProductType(
      Map<String, dynamic> product,
      ) async {
    final productName =
    product["product_name"]?.toString().trim();

    final unsupportedProductId =
    product["unsupported_product_id"];

    if (productName == null ||
        productName.isEmpty ||
        unsupportedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unsupported product information is incomplete.",
          ),
        ),
      );
      return;
    }

    // Load categories
    List<Map<String, dynamic>> categories;

    try {
      categories = await ApiService.getCategories();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load categories: $e",
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    // Show category selection dialog
    final selectedCategory =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Select Category",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.category_outlined,
                    ),
                    title: Text(
                      category["category_name"].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop(
                        category,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final categoryController =
                TextEditingController();

                final categoryName =
                await showDialog<String>(
                  context: dialogContext,
                  builder: (categoryDialogContext) {
                    return AlertDialog(
                      title: const Text(
                        "Create New Category",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: TextField(
                        controller: categoryController,
                        autofocus: true,
                        textCapitalization:
                        TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Category Name",
                          hintText: "Example: Garden & Tools",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(
                              categoryDialogContext,
                            ).pop();
                          },
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final name =
                            categoryController.text.trim();

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please enter a category name",
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.of(
                              categoryDialogContext,
                            ).pop(name);
                          },
                          child: const Text("Create"),
                        ),
                      ],
                    );
                  },
                );

                categoryController.dispose();

                if (categoryName == null ||
                    categoryName.trim().isEmpty) {
                  return;
                }

                try {
                  final createdCategory =
                  await ApiService.createCategory(
                    categoryName: categoryName.trim(),
                  );

                  if (!mounted) return;

                  final newCategory = {
                    "category_id":
                    createdCategory["category_id"],
                    "category_name":
                    createdCategory["category_name"],
                  };

                  Navigator.of(dialogContext).pop(
                    newCategory,
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Failed to create category: $e",
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text(
                "Create New Category",
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );

    if (selectedCategory == null) {
      return;
    }

    final selectedCategoryId =
    int.parse(
      selectedCategory["category_id"].toString(),
    );

    final selectedCategoryName =
    selectedCategory["category_name"].toString();

    // Call backend
    try {
      final result =
      await ApiService.addUnsupportedProductAsProductType(
        unsupportedProductId:
        int.parse(
          unsupportedProductId.toString(),
        ),
        categoryId: selectedCategoryId,
      );

      if (!mounted) return;

      final created =
          result["created"] == true;

      final message = created
          ? "$productName added under $selectedCategoryName."
          : "$productName already exists under $selectedCategoryName.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      await loadUnsupportedProducts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to add product type: $e",
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
          final product = unsupportedProducts[index];

          final productName =
              product["product_name"]?.toString() ?? "Unknown";

          final categoryName =
              product["category_name"]?.toString() ?? "Unknown category";

          debugPrint("UNSUPPORTED PRODUCT: $product");

          final requestCount =
              product["request_count"] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
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
              subtitle: Text(
                "$categoryName • $requestCount requests",
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  addProductType(product);
                },
                child: const Text("Add"),
              ),
            ),
          );
        },
      ),
    );
  }
}