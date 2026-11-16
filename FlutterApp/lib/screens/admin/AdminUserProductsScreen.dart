import 'AdminProductDetailsScreen.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:sellify/screens/BrowseProductDetailsScreen.dart';
import '../../services/auth_service.dart';

class AdminUserProductsScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const AdminUserProductsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserProductsScreen> createState() =>
      _AdminUserProductsScreenState();
}

class _AdminUserProductsScreenState
    extends State<AdminUserProductsScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ApiService.getAdminUserProducts(
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          '${widget.userName}\'s Products',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load products.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This user has not uploaded any products.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final name =
                  product['name']?.toString() ?? 'Unnamed product';
              final description =
                  product['description']?.toString() ?? '';
              final price = product['price'];
              final imagePath = product['image_path']?.toString();

              final imageUrl = (imagePath == null || imagePath.isEmpty)
                  ? null
                  : imagePath.startsWith('http')
                  ? imagePath
                  : '${ApiService.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/${imagePath.replaceFirst(RegExp(r'^/+'), '')}';


              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: Colors.blue.shade50,
                      child: imageUrl == null
                          ? const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.blue,
                        size: 32,
                      )
                          : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.blue,
                            size: 32,
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final productId = int.tryParse(
                      product['product_id']?.toString() ?? '',
                    );

                    if (productId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to identify this product.'),
                        ),
                      );
                      return;
                    }


                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminProductDetailsScreen(
                          productId: productId,
                        ),
                      ),
                    );

                  },
                ),
              );

            },
          );
        },
      ),
    );
  }
}
