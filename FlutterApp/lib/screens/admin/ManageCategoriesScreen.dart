import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'ManageProductTypesScreen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends State<ManageCategoriesScreen> {

  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final result = await ApiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = result;
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
            "Failed to load categories: $e",
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
          "Manage Categories",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : categories.isEmpty
          ? const Center(
        child: Text(
          "No categories found",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadCategories,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {

            final category = categories[index];

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
                  category["category_name"].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  "Category ID: ${category["category_id"]}",
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
                          ManageProductTypesScreen(
                            categoryId:
                            category["category_id"],
                            categoryName:
                            category["category_name"].toString(),
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

Future<void> showAddCategoryDialog() async {
  final controller = TextEditingController();

  try {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Add Category",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Category Name",
              hintText: "Example: Garden & Tools",
              border: OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final categoryName =
                  controller.text.trim();

                if (categoryName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter a category name",
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await ApiService.createCategory(
                    categoryName: categoryName,
                  );

                  if (!mounted) return;

                  Navigator.of(dialogContext).pop();

                  await loadCategories();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '"$categoryName" added successfully',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Failed to add category: $e",
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "Add Category",
              ),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
    }
  }
}