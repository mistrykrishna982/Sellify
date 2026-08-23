import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EmailOtpScreen extends StatefulWidget {
  final String newEmail;

  final String name;
  final String phone;
  final String location;

  const EmailOtpScreen({
    super.key,
    required this.newEmail,
    required this.name,
    required this.phone,
    required this.location,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {

  final otpController = TextEditingController();

  bool isVerifying = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> verifyOtp() async {

    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the 6-digit OTP"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      isVerifying = true;
    });

    try {

      final userId = await AuthService.getUserId();

      if (userId == null) {
        throw Exception("User ID not found");
      }

      // Verify email OTP
      await ApiService.verifyEmailChange(
        userId: userId,
        newEmail: widget.newEmail,
        otp: otp,
      );

      // Email verified successfully.
      // Now update name, phone and location.
      await ApiService.updateProfile(
        userId: userId,
        name: widget.name,
        phone: widget.phone,
        location: widget.location,
      );

      // Update local storage
      await AuthService.updateProfile(
        name: widget.name,
        email: widget.newEmail,
        phone: widget.phone,
        location: widget.location,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Profile updated successfully",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Verification failed: $e",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Verify Email",
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
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              const SizedBox(height: 30),

              Container(
                height: 90,
                width: 90,

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 50,
                  color: Colors.blue.shade700,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Verify Your New Email",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "We sent a 6-digit verification code to:",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.newEmail,
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: otpController,

                keyboardType: TextInputType.number,

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
                    borderRadius: BorderRadius.circular(14),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
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
                  onPressed: isVerifying
                      ? null
                      : verifyOtp,

                  icon: isVerifying
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.verified_outlined,
                  ),

                  label: Text(
                    isVerifying
                        ? "VERIFYING..."
                        : "VERIFY OTP",
                    style: const TextStyle(
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
          ),
        ),
      ),
    );
  }
}