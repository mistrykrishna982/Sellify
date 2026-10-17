import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'BrowseProductDetailsScreen.dart';


class FavoriteScreen extends StatefulWidget {
  final VoidCallback requireLogin;

  const FavoriteScreen({
    super.key,
    required this.requireLogin,
  });


@override
State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
List<Map<String, dynamic>> favoriteProducts = [];
bool isLoading = true;
String? errorMessage;

@override
void initState() {
super.initState();
loadFavorites();
}

Future<void> loadFavorites() async {
setState(() {
isLoading = true;
errorMessage = null;
});

try {
final items = await ApiService.getFavorites();

if (!mounted) return;

setState(() {
favoriteProducts = items;
isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
errorMessage = e.toString();
isLoading = false;
});
}
}

int? getProductId(Map<String, dynamic> product) {
return int.tryParse(product['product_id'].toString());
}

void openProductDetails(Map<String, dynamic> product) {
final productId = getProductId(product);

if (productId == null) return;

Navigator.push(
context,
MaterialPageRoute(

  builder: (_) => BrowseProductDetailsScreen(
    productId: productId,
    requireLogin: widget.requireLogin,
  ),

),
);
}

String formatPrice(dynamic price) {
final value = double.tryParse(price.toString());

if (value == null) return 'Price unavailable';

return '₹${value.toStringAsFixed(0)}';
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('My Favorites'),
actions: [
IconButton(
onPressed: loadFavorites,
icon: const Icon(Icons.refresh),
tooltip: 'Refresh favorites',
),
],
),
body: isLoading
? const Center(child: CircularProgressIndicator())
    : errorMessage != null
? Center(
child: Padding(
padding: const EdgeInsets.all(24),
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
errorMessage!,
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
ElevatedButton(
onPressed: loadFavorites,
child: const Text('Try Again'),
),
],
),
),
)
    : favoriteProducts.isEmpty
? Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.favorite_border,
size: 72,
color: Colors.grey.shade400,
),
const SizedBox(height: 12),
const Text(
'No favorites yet',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
'Products you save will appear here.',
style: TextStyle(
color: Colors.grey.shade600,
),
),
],
),
)
    : RefreshIndicator(
onRefresh: loadFavorites,
child: ListView.builder(
padding: const EdgeInsets.all(12),
itemCount: favoriteProducts.length,
itemBuilder: (context, index) {
final product = favoriteProducts[index];

return Card(
margin: const EdgeInsets.only(bottom: 12),
clipBehavior: Clip.antiAlias,
child: ListTile(
contentPadding: const EdgeInsets.all(12),
leading: const CircleAvatar(
radius: 28,
child: Icon(
Icons.shopping_bag_outlined,
size: 28,
),
),
title: Text(
product['title']?.toString() ??
'Untitled product',
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
subtitle: Padding(
padding: const EdgeInsets.only(top: 6),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
formatPrice(product['price']),
style: const TextStyle(
fontWeight: FontWeight.w600,
color: Colors.green,
),
),
if (product['condition'] != null)
Text(
'Condition: ${product['condition']}',
),
if (product['location'] != null)
Text(
product['location'].toString(),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
],
),
),
trailing: const Icon(
Icons.favorite,
color: Colors.red,
),
onTap: () => openProductDetails(product),
),
);
},
),
),
);
}
}
