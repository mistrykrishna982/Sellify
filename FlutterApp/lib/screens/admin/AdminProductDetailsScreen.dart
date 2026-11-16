
import 'package:flutter/material.dart';
import 'package:sellify/services/api_service.dart';

class AdminProductDetailsScreen extends StatefulWidget {
  final int productId;

  const AdminProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<AdminProductDetailsScreen> createState() =>
      _AdminProductDetailsScreenState();
}

class _AdminProductDetailsScreenState
    extends State<AdminProductDetailsScreen> {
  late Future<dynamic> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture =
        ApiService.getProductDetails(productId: widget.productId);
  }

  String imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return '${ApiService.baseUrl}/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: FutureBuilder<dynamic>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Failed to load product details'),
            );
          }

          final product = snapshot.data;

          if (product is! Map) {
            return const Center(
              child: Text('Invalid product details'),
            );
          }

          final title = product['title'] ??
              product['name'] ??
              'Untitled Product';
          final price = product['price'] ?? '0';
          final description =
              product['description'] ?? 'No description available';
          final category = product['category'] ?? 'Not specified';
          final condition = product['condition'] ?? 'Not specified';
          final location = product['location'] ?? 'Not specified';

          final rawImages = product['images'];
          final List<String> images = [];

          if (rawImages is List) {
            for (final item in rawImages) {
              if (item is String && item.isNotEmpty) {
                images.add(item);
              } else if (item is Map && item['image_path'] != null) {
                images.add(item['image_path'].toString());
              } else if (item is Map && item['IMAGE_PATH'] != null) {
                images.add(item['IMAGE_PATH'].toString());
              }
            }
          }

          if (images.isEmpty && product['image_path'] != null) {
            images.add(product['image_path'].toString());
          }

          if (images.isEmpty && product['image'] != null) {
            images.add(product['image'].toString());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final url = imageUrl(images[index]);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: url.isEmpty
                              ? const Icon(Icons.image_not_supported,
                              size: 60)
                              : Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_not_supported, size: 60),
                ),
              const SizedBox(height: 20),
              Text(
                title.toString(),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹$price',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const Divider(height: 28),
              _detailRow('Category', category),
              _detailRow('Condition', condition),
              _detailRow('Location', location),
              const SizedBox(height: 18),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description.toString(),
                style: const TextStyle(fontSize: 15),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
