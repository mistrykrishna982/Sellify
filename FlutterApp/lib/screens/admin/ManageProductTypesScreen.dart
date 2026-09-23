import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'ManageProductTypeAttributesScreen.dart';

class ManageProductTypesScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ManageProductTypesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });
  @override
  State<ManageProductTypesScreen> createState() =>
      _ManageProductTypesScreenState();
}

class _ManageProductTypesScreenState
    extends State<ManageProductTypesScreen> {

  List<Map<String, dynamic>> productTypes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProductTypes();
  }

  Future<void> loadProductTypes() async {
    try {
      final result =
      await ApiService.getProductTypes(
        categoryId: widget.categoryId,
      );

      if (!mounted) return;

      setState(() {
        productTypes = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load product types: $e",
          ),
        ),
      );
    }
  }


  Future<void> showAddProductTypeDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    List<Map<String, dynamic>> categories = [];

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

    int? selectedCategoryId;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Add Product Type",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Product Type Name",
                        hintText: "Example: Smartwatch",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),

                      items: categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category["category_id"],
                          child: Text(
                            category["category_name"].toString(),
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "AI Description",
                        hintText:
                        "Describe what this product type is",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final name =
                    nameController.text.trim();

                    final description =
                    descriptionController.text.trim();

                    if (name.isEmpty ||
                        selectedCategoryId == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter product type and category",
                          ),
                        ),
                      );

                      return;
                    }

                    try {
                      await ApiService.createProductType(
                        productTypeName: name,
                        categoryId: selectedCategoryId!,
                        aiDescription:
                        description.isEmpty
                            ? null
                            : description,
                      );

                      Navigator.pop(context);

                      await loadProductTypes();

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Product type created successfully",
                          ),
                        ),
                      );



                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            "Failed to create product type: $e",
                          ),
                        ),
                      );
                    }
                  },

                  child: const Text(
                    "Add",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Product Types",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddProductTypeDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Product Type"),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : productTypes.isEmpty
          ? const Center(
        child: Text(
          "No product types found",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadProductTypes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: productTypes.length,
          itemBuilder: (context, index) {

            final productType =
            productTypes[index];

            return Card(
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    "${index + 1}",
                  ),
                ),

                title: Text(
                  productType["product_type_name"].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),

                    Text(
                      "Category: "
                          "${productType["category_name"]}",
                    ),

                    const SizedBox(height: 3),

                    Text(
                      productType["ai_description"]?.toString() ??
                          "No AI description",
                    ),
                  ],
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManageProductTypeAttributesScreen(
                            productTypeId:
                            productType["product_type_id"],
                            productTypeName:
                            productType["product_type_name"].toString(),
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}