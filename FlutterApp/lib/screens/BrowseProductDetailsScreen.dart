import 'package:flutter/material.dart';
import 'package:sellify/services/api_service.dart';
import 'package:sellify/services/auth_service.dart';
import 'ChatScreen.dart';

class BrowseProductDetailsScreen extends StatefulWidget {
final int productId;
final VoidCallback requireLogin;

const BrowseProductDetailsScreen({
super.key,
required this.productId,
required this.requireLogin,
});

@override
State<BrowseProductDetailsScreen> createState() =>
_BrowseProductDetailsScreenState();
}

class _BrowseProductDetailsScreenState
extends State<BrowseProductDetailsScreen> {
Map<String, dynamic>? product;
bool isLoading = true;
String? errorMessage;
int selectedImageIndex = 0;
bool isFavorite = false;
bool isFavoriteLoading = false;

@override
void initState() {
super.initState();
loadProductDetails();
}

Future<void> loadProductDetails() async {
try {
final result = await ApiService.getProductDetails(
productId: widget.productId,
);
bool favoriteStatus = false;

try {
  final favorites = await ApiService.getFavorites();

  favoriteStatus = favorites.any(
        (item) =>
    int.tryParse(item['product_id'].toString()) ==
        widget.productId,
  );
} catch (e) {
  debugPrint('Load favorite status error: $e');
}

if (!mounted) return;

setState(() {
  product = result;
  isFavorite = favoriteStatus;
  isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
errorMessage = 'Unable to load product details.';
isLoading = false;
});

debugPrint('Product details error: $e');
}
}



String imageUrl(String path) {
final cleanPath = path.replaceAll('\\', '/');

if (cleanPath.startsWith('http://') ||
cleanPath.startsWith('https://')) {
return cleanPath;
}

return '${ApiService.baseUrl}/${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';
}



Future<void> toggleFavorite() async {
  final loggedIn = await AuthService.isLoggedIn();

  if (!mounted) return;

  if (!loggedIn) {
    widget.requireLogin();
    return;
  }

  if (isFavoriteLoading) return;

  setState(() {
    isFavoriteLoading = true;
  });

  try {
    if (isFavorite) {
      await ApiService.removeFavorite(
        productId: widget.productId,
      );
    } else {
      await ApiService.addFavorite(
        productId: widget.productId,
      );
    }

    if (!mounted) return;

    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'Added to favorites'
              : 'Removed from favorites',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isFavoriteLoading = false;
      });
    }
  }
}




@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.white,
appBar: AppBar(
title: const Text(
'Product Details',
style: TextStyle(
color: Colors.black,
fontWeight: FontWeight.bold,
),
),
backgroundColor: Colors.white,
elevation: 0,
iconTheme: const IconThemeData(color: Colors.black),
actions: [
  IconButton(
    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
    onPressed: isFavoriteLoading ? null : toggleFavorite,
    icon: isFavoriteLoading
        ? const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    )
        : Icon(
      isFavorite
          ? Icons.favorite_rounded
          : Icons.favorite_border_rounded,
      color: isFavorite ? Colors.red : Colors.black87,
    ),
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
size: 50,
color: Colors.grey,
),
const SizedBox(height: 12),
Text(
errorMessage!,
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: () {
setState(() {
isLoading = true;
errorMessage = null;
});
loadProductDetails();
},
child: const Text('Retry'),
),
],
),
),
)
    : _buildProductContent(),
bottomNavigationBar: product == null
? null
        : SafeArea(
    minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
  child: Row(
  children: [
  Expanded(
  child: SizedBox(
  height: 52,
  child: OutlinedButton.icon(
  icon: const Icon(Icons.chat_bubble_outline),
  label: const Text(
  'Chat',
  style: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  ),
  ),
  onPressed: () async {
  final loggedIn =
  await AuthService.isLoggedIn();

  if (!mounted) return;

  if (!loggedIn) {
  widget.requireLogin();
  return;
  }

  final item = product!;

  final sellerId = int.tryParse(
  (item['user_id'] ?? item['U_ID'] ?? '')
      .toString(),
  );

  if (sellerId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text(
  'Unable to identify the seller.',
  ),
  ),
  );
  return;
  }

  Navigator.push(
  context,
  MaterialPageRoute(
  builder: (context) => ChatScreen(
  productId: widget.productId,
  sellerId: sellerId,
  productTitle:
  item['title']?.toString() ??
  'Product',
  productPrice:
  '₹${item['price'] ?? 'N/A'}',
  ),
  ),
  );
  },
  style: OutlinedButton.styleFrom(
  foregroundColor: Colors.blue.shade800,
  side: BorderSide(
  color: Colors.blue.shade800,
  width: 1.5,
  ),
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),
  ),
  ),
  ),
  ),
  ),
  const SizedBox(width: 12),
  Expanded(
  child: SizedBox(
  height: 52,
  child: ElevatedButton.icon(
  icon: const Icon(Icons.shopping_cart_outlined),
  label: const Text(
  'Add to Cart',
  style: TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
  ),
  ),
  onPressed: () async {
  final loggedIn =
  await AuthService.isLoggedIn();

  if (!mounted) return;

  if (!loggedIn) {
  widget.requireLogin();
  return;
  }

  try {
  final result = await ApiService.addToCart(
  productId: widget.productId,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  content: Text(
  result['message'] ??
  'Product added to cart',
  ),
  ),
  );
  } catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  content: Text(
  e.toString().replaceFirst(
  'Exception: ',
  '',
  ),
  ),
  ),
  );
  }
  },
  style: ElevatedButton.styleFrom(
  backgroundColor: Colors.blue.shade800,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),
  ),
  ),
  ),
  ),
  ),
  ],
  ),
  ),

);
}

Widget _buildProductContent() {
final item = product!;
final rawImages = item['images'];

final List<Map<String, dynamic>> images = rawImages is List
? rawImages
    .whereType<Map>()
    .map((image) => Map<String, dynamic>.from(image))
    .toList()
    : <Map<String, dynamic>>[];

// Fall back to the listing image if the details response has no images.
if (images.isEmpty &&
item['image_path'] != null &&
item['image_path'].toString().isNotEmpty) {
images.add({'image_path': item['image_path']});
}

return ListView(
padding: const EdgeInsets.only(bottom: 24),
children: [
SizedBox(
height: 300,
child: images.isEmpty
? Container(
color: Colors.grey.shade100,
child: const Icon(
Icons.image_outlined,
size: 80,
color: Colors.grey,
),
)
    : PageView.builder(
itemCount: images.length,
onPageChanged: (index) {
setState(() {
selectedImageIndex = index;
});
},
itemBuilder: (context, index) {
final path =
images[index]['image_path']?.toString() ?? '';

return Container(
color: Colors.grey.shade100,
child: path.isEmpty
? const Icon(
Icons.image_outlined,
size: 80,
color: Colors.grey,
)
    : Image.network(
imageUrl(path),
fit: BoxFit.contain,
errorBuilder: (context, error, stackTrace) {
return const Icon(
Icons.broken_image_outlined,
size: 70,
color: Colors.grey,
);
},
),
);
},
),
),

if (images.length > 1)
Padding(
padding: const EdgeInsets.only(top: 10),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: List.generate(
images.length,
(index) => Container(
width: 8,
height: 8,
margin: const EdgeInsets.symmetric(horizontal: 4),
decoration: BoxDecoration(
shape: BoxShape.circle,
color: selectedImageIndex == index
? Colors.blue.shade700
    : Colors.grey.shade300,
),
),
),
),
),

Padding(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (item['category'] != null)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(8),
),
child: Text(
item['category'].toString(),
style: TextStyle(
color: Colors.blue.shade700,
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(height: 14),

Text(
item['title']?.toString() ?? 'Untitled Product',
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 10),

Text(
'₹${item['price'] ?? 'N/A'}',
style: TextStyle(
fontSize: 27,
fontWeight: FontWeight.bold,
color: Colors.blue.shade700,
),
),

const SizedBox(height: 18),
const Divider(),
const SizedBox(height: 12),

_detailRow(
Icons.verified_outlined,
'Condition',
item['condition']?.toString() ?? 'Not specified',
),

const SizedBox(height: 14),

_detailRow(
Icons.location_on_outlined,
'Location',
item['location']?.toString() ?? 'Not specified',
),

const SizedBox(height: 22),

const Text(
'Description',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
item['description']?.toString().trim().isNotEmpty == true
? item['description'].toString()
    : 'No description provided.',
style: TextStyle(
fontSize: 15,
height: 1.5,
color: Colors.grey.shade700,
),
),
],
),
),
],
);
}

Widget _detailRow(IconData icon, String label, String value) {
return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(icon, color: Colors.blue.shade700, size: 22),
const SizedBox(width: 10),
SizedBox(
width: 85,
child: Text(
label,
style: const TextStyle(fontWeight: FontWeight.w600),
),
),
Expanded(
child: Text(
value,
style: TextStyle(color: Colors.grey.shade700),
),
),
],
);
}
}

