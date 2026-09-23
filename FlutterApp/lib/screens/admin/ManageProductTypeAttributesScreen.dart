import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageProductTypeAttributesScreen extends StatefulWidget {
  final int productTypeId;
  final String productTypeName;

  const ManageProductTypeAttributesScreen({
    super.key,
    required this.productTypeId,
    required this.productTypeName,
  });

  @override
  State<ManageProductTypeAttributesScreen> createState() =>
      _ManageProductTypeAttributesScreenState();
}

class _ManageProductTypeAttributesScreenState
    extends State<ManageProductTypeAttributesScreen> {

  List<Map<String, dynamic>> attributes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAttributes();
  }

  Future<void> loadAttributes() async {
    try {
      final result =
      await ApiService.getProductTypeAttributes(
        widget.productTypeId,
      );

      if (!mounted) return;

      setState(() {
        attributes = result;
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
            "Failed to load attributes: $e",
          ),
        ),
      );
    }
  }


  Future<void> addAttribute() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Add Attribute",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                ),
                title: const Text(
                  "Create New Attribute",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Create a new attribute for this product type",
                ),
                onTap: () {
                  Navigator.pop(context);
                  createNewAttribute();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.list_alt,
                ),
                title: const Text(
                  "Use Existing Attribute",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Choose an existing attribute definition",
                ),
                onTap: () {
                  Navigator.pop(context);
                  useExistingAttribute();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }



  Future<void> createNewAttribute() async {
    final nameController = TextEditingController();

    String attributeType = "TEXT";

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Create New Attribute",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Attribute Name",
                      hintText: "Example: Processor Speed",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: attributeType,
                    decoration: const InputDecoration(
                      labelText: "Attribute Type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "TEXT",
                        child: Text("Text"),
                      ),
                      DropdownMenuItem(
                        value: "NUMBER",
                        child: Text("Number"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        attributeType = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name =
                    nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter an attribute name",
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await ApiService
                          .createAttributeForProductType(
                        productTypeId:
                        widget.productTypeId,
                        attributeName: name,
                        attributeType: attributeType,
                      );

                      if (!mounted) return;

                      Navigator.pop(context, true);

                      await loadAttributes();

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            "$name created and added successfully",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            "Failed to create attribute: $e",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }



  Future<void> removeAttribute(
      Map<String, dynamic> attribute,
      ) async {
    final attributeId = attribute["attribute_id"];
    final attributeName =
        attribute["attribute_name"]?.toString() ?? "Attribute";

    if (attributeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Attribute ID not found",
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Remove Attribute?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Remove "$attributeName" from ${widget.productTypeName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.removeAttributeFromProductType(
        productTypeId: widget.productTypeId,
        attributeId: int.parse(
          attributeId.toString(),
        ),
      );

      if (!mounted) return;

      await loadAttributes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$attributeName removed successfully",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to remove attribute: $e",
          ),
        ),
      );
    }
  }



  Future<void> useExistingAttribute() async {
    try {
      final allAttributes =
      await ApiService.getAvailableProductTypeAttributes(
        widget.productTypeId,
      );

      if (!mounted) return;

      if (allAttributes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No attribute definitions available"),
          ),
        );
        return;
      }

      final selectedAttribute = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return _ExistingAttributeDialog(
            attributes: allAttributes,
          );
        },
      );

      if (selectedAttribute == null) {
        return;
      }

      if (!mounted) return;

      final attributeId =
      int.parse(selectedAttribute["attribute_id"].toString());

      final attributeName =
          selectedAttribute["attribute_name"]?.toString() ??
              "Attribute";

      try {
        await ApiService.addAttributeToProductType(
          productTypeId: widget.productTypeId,
          attributeId: attributeId,
          isRequired: false,
          displayOrder: attributes.length + 1,
        );

        if (!mounted) return;

        await loadAttributes();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$attributeName added successfully",
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to add attribute: $e",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load attribute definitions: $e",
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productTypeName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : attributes.isEmpty
          ? const Center(
        child: Text(
          "No attributes assigned",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadAttributes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: attributes.length,
          itemBuilder: (context, index) {

            final attribute =
            attributes[index];

            final required =
                attribute["is_required"] == true;

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
                  attribute[
                  "attribute_name"].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  "Type: "
                      "${attribute["attribute_type"]}"
                      "\n"
                      "${required ? "Required" : "Optional"}",
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  tooltip: "Remove Attribute",
                  onPressed: () {
                    removeAttribute(attribute);
                  },
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: addAttribute,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Attribute",
        ),
      ),
    );
  }
}

class _ExistingAttributeDialog extends StatefulWidget {
  final List<Map<String, dynamic>> attributes;

  const _ExistingAttributeDialog({
    required this.attributes,
  });

  @override
  State<_ExistingAttributeDialog> createState() =>
      _ExistingAttributeDialogState();
}

class _ExistingAttributeDialogState
    extends State<_ExistingAttributeDialog> {
  final TextEditingController searchController =
  TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchText =
    searchController.text.trim().toLowerCase();

    final filteredAttributes =
    widget.attributes.where((attribute) {
      final attributeName =
          attribute["attribute_name"]
              ?.toString()
              .toLowerCase() ??
              "";

      // Search ONLY by attribute name.
      return attributeName.contains(searchText);
    }).toList();

    return AlertDialog(
      title: const Text(
        "Use Existing Attribute",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by attribute name",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();

                    setState(() {});
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 12),

            Expanded(
              child: filteredAttributes.isEmpty
                  ? const Center(
                child: Text(
                  "No matching attributes",
                ),
              )
                  : ListView.builder(
                itemCount: filteredAttributes.length,
                itemBuilder: (context, index) {
                  final attribute =
                  filteredAttributes[index];

                  final attributeId =
                  attribute["attribute_id"];

                  final attributeName =
                      attribute["attribute_name"]
                          ?.toString() ??
                          "";

                  final attributeType =
                      attribute["attribute_type"]
                          ?.toString() ??
                          "";

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        attributeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "ID: $attributeId\n"
                            "Type: $attributeType",
                      ),
                      trailing: const Icon(
                        Icons.add_circle,
                        color: Colors.blue,
                      ),
                      onTap: () {
                        Navigator.of(context).pop(
                          attribute,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Close"),
        ),
      ],
    );
  }
}