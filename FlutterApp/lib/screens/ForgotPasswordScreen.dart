import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'LoginScreen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  int currentStep = 0;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // STEP 1 - SEND OTP
  // ============================================================

  Future<void> sendOtp() async {

    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage("Please enter your email address.");
      return;
    }

    if (!email.contains("@")) {
      showMessage("Please enter a valid email address.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      await ApiService.requestForgotPasswordOtp(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        currentStep = 1;
      });

      showMessage(
        "If an account exists, an OTP has been sent.",
      );

    } catch (e) {

      if (!mounted) return;

      showMessage(
        "Failed to send OTP: $e",
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  // ============================================================
  // STEP 2 - VERIFY OTP
  // ============================================================

  Future<void> verifyOtp() async {

    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      showMessage("Please enter the 6-digit OTP.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      await ApiService.verifyForgotPasswordOtp(
        email: email,
        otp: otp,
      );

      if (!mounted) return;

      setState(() {
        currentStep = 2;
      });

      showMessage(
        "OTP verified successfully.",
      );

    } catch (e) {

      if (!mounted) return;

      showMessage(
        "OTP verification failed: $e",
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  // ============================================================
  // STEP 3 - RESET PASSWORD
  // ============================================================

  Future<void> resetPassword() async {

    final password = passwordController.text;
    final confirmPassword =
        confirmPasswordController.text;

    if (password.isEmpty) {
      showMessage("Please enter a new password.");
      return;
    }

    if (password.length < 6) {
      showMessage(
        "Password must be at least 6 characters.",
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage(
        "Please confirm your password.",
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        "Passwords do not match.",
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      await ApiService.resetPassword(
        email: emailController.text.trim(),
        newPassword: password,
      );

      if (!mounted) return;

      showMessage(
        "Password reset successfully.",
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const LoginScreen(),
        ),
            (route) => false,
      );

    } catch (e) {

      if (!mounted) return;

      showMessage(
        "Password reset failed: $e",
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  // ============================================================
  // BACK BUTTON
  // ============================================================

  void goBack() {

    if (currentStep == 0) {

      Navigator.pop(context);

    } else {

      setState(() {
        currentStep--;
      });
    }
  }


  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: goBack,
        ),

        title: const Text(
          "Forgot Password",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,

            children: [

              const SizedBox(height: 25),

              // =================================================
              // ICON
              // =================================================

              Container(
                height: 90,
                width: 90,

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  currentStep == 0
                      ? Icons.lock_reset
                      : currentStep == 1
                      ? Icons.mark_email_read_outlined
                      : Icons.lock_outline,
                  size: 50,
                  color: Colors.blue.shade700,
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // TITLE
              // =================================================

              Text(
                currentStep == 0
                    ? "Reset Your Password"
                    : currentStep == 1
                    ? "Verify OTP"
                    : "Create New Password",

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // DESCRIPTION
              // =================================================

              Text(
                currentStep == 0
                    ? "Enter your registered email address to receive an OTP."
                    : currentStep == 1
                    ? "Enter the 6-digit OTP sent to your email."
                    : "Enter a new password for your Sellify account.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 35),

              // =================================================
              // STEP 1
              // =================================================

              if (currentStep == 0) ...[

                TextField(
                  controller: emailController,

                  keyboardType:
                  TextInputType.emailAddress,

                  decoration: InputDecoration(
                    labelText: "Email Address",

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),

                      borderSide:
                      const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  height: 54,

                  child: ElevatedButton.icon(
                    onPressed:
                    isLoading ? null : sendOtp,

                    icon: isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.send_outlined,
                    ),

                    label: Text(
                      isLoading
                          ? "SENDING..."
                          : "SEND OTP",

                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.blue.shade700,

                      foregroundColor:
                      Colors.white,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],

              // =================================================
              // STEP 2
              // =================================================

              if (currentStep == 1) ...[

                Text(
                  emailController.text.trim(),

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: otpController,

                  keyboardType:
                  TextInputType.number,

                  maxLength: 6,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),

                  decoration: InputDecoration(
                    labelText: "Enter OTP",
                    counterText: "",

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),

                      borderSide:
                      const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  height: 54,

                  child: ElevatedButton.icon(
                    onPressed:
                    isLoading ? null : verifyOtp,

                    icon: isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.verified_outlined,
                    ),

                    label: Text(
                      isLoading
                          ? "VERIFYING..."
                          : "VERIFY OTP",

                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.blue.shade700,

                      foregroundColor:
                      Colors.white,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "The OTP will expire after 10 minutes.",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],

              // =================================================
              // STEP 3
              // =================================================

              if (currentStep == 2) ...[

                TextField(
                  controller: passwordController,

                  obscureText: hidePassword,

                  decoration: InputDecoration(
                    labelText: "New Password",

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),

                      onPressed: () {
                        setState(() {
                          hidePassword =
                          !hidePassword;
                        });
                      },
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),

                      borderSide:
                      const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller:
                  confirmPasswordController,

                  obscureText:
                  hideConfirmPassword,

                  decoration: InputDecoration(
                    labelText:
                    "Confirm Password",

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),

                      onPressed: () {
                        setState(() {
                          hideConfirmPassword =
                          !hideConfirmPassword;
                        });
                      },
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),

                      borderSide:
                      const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  height: 54,

                  child: ElevatedButton.icon(
                    onPressed:
                    isLoading
                        ? null
                        : resetPassword,

                    icon: isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.check_circle_outline,
                    ),

                    label: Text(
                      isLoading
                          ? "RESETTING..."
                          : "RESET PASSWORD",

                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.blue.shade700,

                      foregroundColor:
                      Colors.white,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}