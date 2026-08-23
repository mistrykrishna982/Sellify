import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // Save logged-in user
  static Future<void> login({
    required dynamic userId,
    required String name,
    required String email,
    required String role,
  }) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("isLoggedIn", true);
    await prefs.setString("userId", userId.toString());
    await prefs.setString("name", name);
    await prefs.setString("email", email);
    await prefs.setString("role", role);
  }


  // Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool("isLoggedIn") ?? false;
  }


  // Get user name
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("name");
  }


  // Get user email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("email");
  }


  // Get user role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("role");
  }


  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("userId");
  }


  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }

//edit profile
  static Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String location,
  }) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("name", name);
    await prefs.setString("email", email);
    await prefs.setString("phone", phone);
    await prefs.setString("location", location);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("phone");
  }

  static Future<String?> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("location");
  }
}