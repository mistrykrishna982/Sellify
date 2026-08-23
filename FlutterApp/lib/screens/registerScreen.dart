import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'HomeScreen.dart';
import 'LoginScreen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  //register user



  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final phone = phoneController.text.trim();
    final location = locationController.text.trim();

    // Check empty fields
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // =====================================================
      // STEP 1: REGISTER USER
      // =====================================================

      final registerResult = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        location: location,
        profileImage: null,
      );

      if (!mounted) return;

      if (registerResult["message"] != "Registration successful") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              registerResult["detail"] ?? "Registration failed",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      // =====================================================
      // STEP 2: AUTOMATICALLY LOGIN
      // =====================================================

      final loginResult = await ApiService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (loginResult["message"] == "Login successful") {

        // ===================================================
        // STEP 3: SAVE USER LOGIN DATA ON DEVICE
        // ===================================================

        await AuthService.login(
          userId: loginResult["user_id"],
          name: loginResult["name"],
          email: loginResult["email"],
          role: loginResult["role"],
        );

        if (!mounted) return;

        // ===================================================
        // STEP 4: SHOW SUCCESS MESSAGE
        // ===================================================

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // ===================================================
        // STEP 5: GO TO HOME SCREEN
        // ===================================================

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
              (route) => false,
        );
      } else {
        // Registration worked, but automatic login failed.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loginResult["detail"] ??
                  "Account created, but automatic login failed. Please login manually.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool password = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: password && hidePassword,
        keyboardType: keyboardType,

        decoration: InputDecoration(
          labelText: label,

          prefixIcon: Icon(
            icon,
          ),

          suffixIcon: password
              ? IconButton(
            icon: Icon(
              hidePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () {
              setState(() {
                hidePassword = !hidePassword;
              });
            },
          )
              : null,

          filled: true,
          fillColor: Colors.grey.shade100,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 2,
            ),
          ),

          contentPadding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 16,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Sellify",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 10,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const SizedBox(height: 10),

              Center(
                child: Container(
                  height: 85,
                  width: 85,

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.storefront_rounded,
                    size: 48,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Create Account",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Join Sellify and start buying & selling",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              //form

              buildTextField(
                label: "Full Name",
                icon: Icons.person_outline,
                controller: nameController,
              ),

              buildTextField(
                label: "Email Address",
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              buildTextField(
                label: "Password",
                icon: Icons.lock_outline,
                controller: passwordController,
                password: true,
              ),

              buildTextField(
                label: "Phone Number",
                icon: Icons.phone_outlined,
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),

              buildTextField(
                label: "Location",
                icon: Icons.location_on_outlined,
                controller: locationController,
              ),

              const SizedBox(height: 5),

         //register button
              SizedBox(
                height: 54,

                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : registerUser,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,

                    elevation: 2,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,

                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                      ),

                      SizedBox(width: 10),

                      Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),



              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Flexible(
                    child: Text(
                      "Already have an account?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                "By creating an account, you agree to use Sellify responsibly.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}