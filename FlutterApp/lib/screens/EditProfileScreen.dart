import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'EmailOtpScreen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();

  String originalEmail = "";
  String userRole = "";


  String? profileImageUrl;
  File? selectedProfileImage;


  bool isLoading = true;
  bool isSaving = false;


  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD USER DATA
  // =========================================================

  Future<void> loadUserData() async {

    try {

      final userId = await AuthService.getUserId();

      if (userId == null || userId.isEmpty) {
        throw Exception("User ID not found");
      }

      final result = await ApiService.getProfile(
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        nameController.text = result["name"] ?? "";
        emailController.text = result["email"] ?? "";

        phoneController.text = result["phone"] ?? "";
        locationController.text = result["location"] ?? "";

        originalEmail = result["email"] ?? "";
        userRole = result["role"] ?? "USER";

        profileImageUrl = result["profile_image"];

        isLoading = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load profile: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // =======================================================
    // EMAIL CHANGED
    // =======================================================

    if (email != originalEmail) {
      showEmailVerificationDialog(email);
      return;
    }

    // =======================================================
    // EMAIL NOT CHANGED
    // =======================================================

    await updateProfile(
      name: name,
      email: originalEmail,
      phone: phone,
      location: location,
    );
  }

  // =========================================================
  // EMAIL VERIFICATION DIALOG
  // =========================================================

  void showEmailVerificationDialog(String newEmail) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: Colors.blue,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Verify New Email",
                ),
              ),
            ],
          ),

          content: Text(
            "We will send a verification OTP to:\n\n$newEmail",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("CANCEL"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // We will connect the OTP API here.
                sendEmailOtp(newEmail);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),

              child: const Text("SEND OTP"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SEND EMAIL OTP
  // =========================================================

  Future<void> sendEmailOtp(String newEmail) async {

    try {

      final userId = await AuthService.getUserId();

      if (userId == null || userId.isEmpty) {
        throw Exception("User ID not found");
      }

      setState(() {
        isSaving = true;
      });

      await ApiService.requestEmailChange(
        userId: userId,
        newEmail: newEmail,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "OTP sent successfully. Check your email.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailOtpScreen(
            newEmail: newEmail,
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            location: locationController.text.trim(),
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to send OTP: $e",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }


  // =========================================================
  // add image picker fun
  // =========================================================

  Future<void> pickProfileImage() async {

    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image == null) {
      return;
    }

    setState(() {
      selectedProfileImage = File(image.path);
    });
  }


  // =========================================================
  // UPDATE PROFILE
  // =========================================================



  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String location,
  }) async {

    setState(() {
      isSaving = true;
    });

    try {

      final userId = await AuthService.getUserId();

      if (userId == null || userId.isEmpty) {
        throw Exception("User ID not found");
      }

      // Update MySQL
      await ApiService.updateProfile(
        userId: userId,
        name: name,
        phone: phone,
        location: location,
      );

      //upload profile image if user selected one
      if (selectedProfileImage != null) {
        await ApiService.uploadProfileImage(
          userId: userId,
          image: selectedProfileImage!,
        );
      }

      // Update local storage
      await AuthService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        location: location,
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
            "Failed to update profile: $e",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,

        decoration: InputDecoration(
          labelText: label,

          prefixIcon: Icon(icon),

          filled: true,
          fillColor: enabled
              ? Colors.grey.shade100
              : Colors.grey.shade200,

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

          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

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
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              const SizedBox(height: 10),

              // =================================================
              // AVATAR
              // =================================================

              Center(
                child: GestureDetector(
                  onTap: pickProfileImage,

                  child: Stack(
                    alignment: Alignment.bottomRight,

                    children: [

                      Container(
                        height: 100,
                        width: 100,

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,

                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 3,
                          ),

                          image: selectedProfileImage != null
                              ? DecorationImage(
                            image: FileImage(
                              selectedProfileImage!,
                            ),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),

                        child: selectedProfileImage == null
                            ? (
                            profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                                ? ClipOval(
                              child: Image.network(
                                "${ApiService.baseUrl}$profileImageUrl",
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: Colors.blue.shade700,
                                  );
                                },
                              ),
                            )
                                : Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: Colors.blue.shade700,
                            )
                        )
                            : null,
                      ),

                      Container(
                        height: 34,
                        width: 34,

                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),

                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Update your account information",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 25),

              // NAME
              buildTextField(
                label: "Full Name",
                icon: Icons.person_outline,
                controller: nameController,
              ),

              // EMAIL
              buildTextField(
                label: "Email Address",
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              // PHONE
              buildTextField(
                label: "Phone Number",
                icon: Icons.phone_outlined,
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),

              // LOCATION
              buildTextField(
                label: "Location",
                icon: Icons.location_on_outlined,
                controller: locationController,
              ),

              const SizedBox(height: 5),

              // =================================================
              // ROLE
              // =================================================

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: Row(
                  children: [

                    Container(
                      height: 42,
                      width: 42,

                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),

                      child: Icon(
                        Icons.badge_outlined,
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
                            "Account Type",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            userRole.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // SAVE BUTTON
              // =================================================

              SizedBox(
                height: 54,

                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : saveProfile,

                  icon: isSaving
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
                    Icons.save_outlined,
                  ),

                  label: Text(
                    isSaving
                        ? "SAVING..."
                        : "SAVE CHANGES",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.blue.shade700,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Changing your email requires email verification.",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
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