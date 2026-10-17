import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'BrowseProductDetailsScreen.dart';
import 'package:sellify/services/auth_service.dart';

class CartScreen extends StatefulWidget {
const CartScreen({super.key});

@override
State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
late Future<List<Map<String, dynamic>>> _cartFuture;

@override
void initState() {
super.initState();
_loadCart();
}

void _loadCart() {
_cartFuture = ApiService.getCartItems();
}

Future<void> _refreshCart() async {
setState(() {
_loadCart();
});
await _cartFuture;
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('My Cart'),
),
body: FutureBuilder<List<Map<String, dynamic>>>(
future: _cartFuture,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
size: 48,
color: Colors.red,
),
const SizedBox(height: 12),
Text(
snapshot.error.toString().replaceFirst(
'Exception: ',
'',
),
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
ElevatedButton(
onPressed: () {
setState(_loadCart);
},
child: const Text('Retry'),
),
],
),
),
);
}

final items = snapshot.data ?? [];

if (items.isEmpty) {
return RefreshIndicator(
onRefresh: _refreshCart,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(),
children: const [
SizedBox(height: 180),
Icon(
Icons.shopping_cart_outlined,
size: 70,
color: Colors.grey,
),
SizedBox(height: 16),
Center(
child: Text(
'Your cart is empty',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
),
],
),
);
}

return RefreshIndicator(
onRefresh: _refreshCart,
child: ListView.separated(
padding: const EdgeInsets.all(16),
itemCount: items.length,
separatorBuilder: (_, __) => const Divider(height: 24),
itemBuilder: (context, index) {
final item = items[index];
final title = item['title']?.toString() ?? 'Untitled product';
final price = double.tryParse(
item['price']?.toString() ?? '',
) ??
0;
final quantity = int.tryParse(
item['quantity']?.toString() ?? '1',
) ??
1;
final imagePath = item['image_path']?.toString();


return ListTile(
  onTap: () {
    final productId = int.tryParse(
      item['product_id']?.toString() ?? '',
    );

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid product ID')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowseProductDetailsScreen(
          productId: productId,
          requireLogin: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to continue'),
              ),
            );
          },
        ),
      ),
    );
  },
  contentPadding: EdgeInsets.zero,
  leading: SizedBox(
    width: 64,
    height: 64,
    child: imagePath != null && imagePath.isNotEmpty
        ? Image.network(
      imagePath.startsWith('http')
          ? imagePath
          : '${ApiService.baseUrl.replaceFirst('/api', '')}/$imagePath',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported_outlined,
          size: 40,
        );
      },
    )
        : const Icon(
      Icons.shopping_bag_outlined,
      size: 40,
    ),
  ),
  title: Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
  subtitle: Text(
    '₹${price.toStringAsFixed(2)} × $quantity',
  ),
  trailing: Text(
    '₹${(price * quantity).toStringAsFixed(2)}',
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
);
},
),
);
},
),
);
}
}
