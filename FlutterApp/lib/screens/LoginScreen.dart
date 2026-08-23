import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'HomeScreen.dart';
import 'registerScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  //login user

  Future<void> loginUser() async {
    // Check empty fields
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter email and password"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (result["message"] == "Login successful") {

        // Save login information on the phone
        await AuthService.login(
          userId: result["user_id"],
          name: result["name"],
          email: result["email"],
          role: result["role"],
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful!"),
          ),
        );

        // Go to HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
              (route) => false,
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result["detail"] ?? "Login failed",
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

          prefixIcon: Icon(icon),

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

     //app bar

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

     //body

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 10,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 25),

              Center(
                child: Container(
                  height: 90,
                  width: 90,

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.storefront_rounded,
                    size: 50,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 24),

             //title
              const Text(
                "Welcome Back",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Login to continue to Sellify",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 35),

              //email

              buildTextField(
                label: "Email Address",
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              //password

              buildTextField(
                label: "Password",
                icon: Icons.lock_outline,
                controller: passwordController,
                password: true,
              ),

             //forgot password

              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed: () {
                    // Forgot password will be added later.
                  },

                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

             //login button

              SizedBox(
                height: 54,

                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,

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
                        Icons.login_rounded,
                      ),

                      SizedBox(width: 10),

                      Text(
                        "LOGIN",
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

            //register

              // Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      "Don't have an account?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

// Footer
              Text(
                "Buy smart. Sell easy. Sellify.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 20),
        ]))
      ),
    );
  }
}