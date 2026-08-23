import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'LoginScreen.dart';
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  bool isLoading = true;
  bool isLoggedIn = false;

  String userName = "";
  String userEmail = "";
  String userRole = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================================================
  // LOAD USER FROM PHONE
  // =========================================================

  Future<void> loadUser() async {

    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {

      final name = await AuthService.getName();
      final email = await AuthService.getEmail();
      final role = await AuthService.getRole();

      setState(() {
        isLoggedIn = true;
        userName = name ?? "User";
        userEmail = email ?? "";
        userRole = role ?? "User";
        isLoading = false;
      });

    } else {

      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  // =========================================================
  // MAIN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : isLoggedIn
          ? buildLoggedInProfile()
          : buildGuestProfile(),
    );
  }

  // =========================================================
  // GUEST PROFILE
  // =========================================================

  Widget buildGuestProfile() {

    return Column(
      children: [

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                const SizedBox(height: 25),

                // PROFILE ICON
                Container(
                  height: 110,
                  width: 110,

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,

                    border: Border.all(
                      color: Colors.blue.shade100,
                      width: 3,
                    ),
                  ),

                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 65,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Guest User",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Login or register to access your profile",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 28),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton.icon(
                    onPressed: () async {

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );

                      // Check again after returning
                      loadUser();
                    },

                    icon: const Icon(
                      Icons.login_rounded,
                    ),

                    label: const Text(
                      "LOGIN / REGISTER",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      elevation: 2,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // INFORMATION CARD
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Why create an account?",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      buildFeatureItem(
                        icon: Icons.sell_outlined,
                        title: "Sell Products",
                        subtitle:
                        "List your products for buyers",
                      ),

                      const SizedBox(height: 15),

                      buildFeatureItem(
                        icon: Icons.shopping_bag_outlined,
                        title: "Buy Products",
                        subtitle:
                        "Purchase products from sellers",
                      ),

                      const SizedBox(height: 15),

                      buildFeatureItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: "Chat with Sellers",
                        subtitle:
                        "Communicate with buyers and sellers",
                      ),

                      const SizedBox(height: 15),

                      buildFeatureItem(
                        icon: Icons.person_outline_rounded,
                        title: "Manage Your Profile",
                        subtitle:
                        "Keep your account information updated",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),

        // FIXED FOOTER
        Padding(
          padding: const EdgeInsets.only(
            bottom: 15,
            top: 8,
          ),

          child: Text(
            "Buy smart. Sell easy. Sellify.",
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FEATURE ITEM
  // =========================================================

  Widget buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Container(
          height: 42,
          width: 42,

          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 23,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LOGGED-IN PROFILE
  // =========================================================

  Widget buildLoggedInProfile() {

    return Column(
      children: [

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                const SizedBox(height: 25),

                // PROFILE AVATAR
                Container(
                  height: 110,
                  width: 110,

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,

                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 3,
                    ),
                  ),

                  child: Icon(
                    Icons.person_rounded,
                    size: 65,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 18),

                // USER NAME
                Text(
                  userName,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // ROLE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    userRole.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // PERSONAL INFORMATION CARD
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      buildInfoItem(
                        icon: Icons.person_outline,
                        title: "Name",
                        value: userName,
                      ),

                      const SizedBox(height: 16),

                      buildInfoItem(
                        icon: Icons.email_outlined,
                        title: "Email",
                        value: userEmail,
                      ),

                      const SizedBox(height: 16),


                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // EDIT PROFILE
                buildProfileButton(
                  icon: Icons.edit_outlined,
                  title: "Edit Profile",
                  onTap: () async {

                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );

                    if (updated == true) {
                      loadUser();
                    }
                  },
                ),

                const SizedBox(height: 12),

                // MY PRODUCTS
                buildProfileButton(
                  icon: Icons.inventory_2_outlined,
                  title: "My Products",
                  onTap: () {
                    // Later
                  },
                ),

                const SizedBox(height: 12),

                // MY ORDERS
                buildProfileButton(
                  icon: Icons.shopping_bag_outlined,
                  title: "My Orders",
                  onTap: () {
                    // Later
                  },
                ),

                const SizedBox(height: 12),

                // SETTINGS
                buildProfileButton(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {
                    // Later
                  },
                ),

                const SizedBox(height: 20),

                // LOGOUT
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: OutlinedButton.icon(
                    onPressed: () async {

                      await AuthService.logout();

                      if (!mounted) return;

                      setState(() {
                        isLoggedIn = false;
                        userName = "";
                        userEmail = "";
                        userRole = "";
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Logged out successfully"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.logout_rounded,
                    ),

                    label: const Text(
                      "LOGOUT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,

                      side: BorderSide(
                        color: Colors.red.shade200,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),

        // FOOTER
        Padding(
          padding: const EdgeInsets.only(
            bottom: 15,
            top: 8,
          ),

          child: Text(
            "Buy smart. Sell easy. Sellify.",
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // USER INFO ITEM
  // =========================================================

  Widget buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {

    return Row(
      children: [

        Container(
          height: 42,
          width: 42,

          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: Colors.blue.shade700,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PROFILE BUTTON
  // =========================================================

  Widget buildProfileButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: ListTile(
        onTap: onTap,

        leading: Container(
          height: 42,
          width: 42,

          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: Colors.blue.shade700,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
        ),
      ),
    );
  }
}