import 'package:flutter/material.dart';
import 'package:sellify/screens/LoginScreen.dart';
import 'package:sellify/screens/ProfileScreen.dart';
import 'package:sellify/screens/registerScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //0=home
  //1=profile
  int selectedIndex = 0;


  final List<Map<String, dynamic>> products = const [
    {
      "name": "iPhone 13",
      "price": "₹45,000",
      "category": "Mobiles",
      "location": "Ahmedabad",
    },
    {
      "name": "Dell Laptop",
      "price": "₹38,000",
      "category": "Laptops",
      "location": "Ahmedabad",
    },
    {
      "name": "Study Table",
      "price": "₹3,500",
      "category": "Furniture",
      "location": "Ahmedabad",
    },
  ];

  //login
  void requireLogin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),

          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Small handle
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 25),

              // Icon
              Container(
                height: 70,
                width: 70,

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 35,
                  color: Colors.blue.shade700,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Please login or create an account to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 25),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },

                  icon: const Icon(Icons.login_rounded),

                  label: const Text(
                    "LOGIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,

                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                  ),

                  label: const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,

                    side: BorderSide(
                      color: Colors.blue.shade700,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CONTINUE BROWSING
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: Text(
                  "Continue Browsing",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

 //home page

  Widget buildHomePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
       //search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),

          child: TextField(
            decoration: InputDecoration(
              hintText: "Search products...",

              hintStyle: TextStyle(
                color: Colors.grey.shade500,
              ),

              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 26,
              ),

              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                ),
                onPressed: () {

                },
              ),

              border: InputBorder.none,

              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
        ),

        const SizedBox(height: 25),

        //categories

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Categories",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            TextButton(
              onPressed: () {

              },
              child: const Text(
                "See all",
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 105,

          child: ListView(
            scrollDirection: Axis.horizontal,

            children: const [
              CategoryItem(
                icon: Icons.phone_android_rounded,
                title: "Mobiles",
              ),

              CategoryItem(
                icon: Icons.laptop_mac_rounded,
                title: "Laptops",
              ),

              CategoryItem(
                icon: Icons.chair_rounded,
                title: "Furniture",
              ),

              CategoryItem(
                icon: Icons.directions_car_rounded,
                title: "Vehicles",
              ),

              CategoryItem(
                icon: Icons.watch_rounded,
                title: "Fashion",
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

       //product title

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Latest Products",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            TextButton(
              onPressed: () {
                // View all products later.
              },
              child: const Text(
                "See all",
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

//products

        ...products.map(
              (product) => ProductCard(
            product: product,
            onAction: () {
              requireLogin(context);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

     //appbar

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        titleSpacing: 16,

        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.storefront_rounded,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),

            const SizedBox(width: 10),

            const Text(
              "Sellify",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          // Notification
          IconButton(
            tooltip: "Notifications",
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
            ),
            onPressed: () {
              requireLogin(context);
            },
          ),

          // Cart
          IconButton(
            tooltip: "Cart",
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black87,
            ),
            onPressed: () {
              requireLogin(context);
            },
          ),

          const SizedBox(width: 8),
        ],
      ),

     //body
      body: selectedIndex == 0
          ? buildHomePage()
          : const ProfileScreen(),

    //sell button

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,

        elevation: 4,

        onPressed: () {
          requireLogin(context);
        },

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          "Sell",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

     //navigation bar

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        backgroundColor: Colors.white,

        elevation: 8,

        indicatorColor: Colors.blue.shade50,

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
            ),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}


//category item

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,

      margin: const EdgeInsets.only(right: 12),

      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(18),
            ),

            child: Icon(
              icon,
              size: 32,
              color: Colors.blue.shade700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

//product card

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAction;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      shadowColor: Colors.black12,

      margin: const EdgeInsets.only(
        bottom: 16,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
         //images
          Stack(
            children: [
              Container(
                height: 190,
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                ),

                child: const Icon(
                  Icons.image_outlined,
                  size: 65,
                  color: Colors.grey,
                ),
              ),

              // Favorite button
              Positioned(
                top: 10,
                right: 10,

                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),

                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border_rounded,
                    ),

                    color: Colors.grey.shade700,

                    onPressed: () {
                      onAction();
                    },
                  ),
                ),
              ),
            ],
          ),

         //product info

          Padding(
            padding: const EdgeInsets.all(14),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Category
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Text(
                    product["category"],

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Product name
                Text(
                  product["name"],

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                // Price
                Text(
                  product["price"],

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: Colors.grey.shade600,
                    ),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        product["location"],

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
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
}