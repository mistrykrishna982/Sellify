import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = "http://192.168.155.48:8000";

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String location,
    String? profileImage,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "phone": phone,
        "location": location,
        "profile_image": profileImage,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }



  static Future<Map<String, dynamic>> getProfile({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/profile/$userId"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["detail"] ?? "Failed to load profile",
      );
    }

    return Map<String, dynamic>.from(data);
  }


  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    required String phone,
    required String location,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/profile/$userId"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "location": location,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["detail"] ?? "Failed to update profile",
      );
    }

    return Map<String, dynamic>.from(data);
  }



  static Future<Map<String, dynamic>> requestEmailChange({
    required String userId,
    required String newEmail,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/profile/$userId/email/request"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "new_email": newEmail,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["detail"] ?? "Failed to send OTP",
      );
    }

    return Map<String, dynamic>.from(data);
  }



  static Future<Map<String, dynamic>> verifyEmailChange({
    required String userId,
    required String newEmail,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/profile/$userId/email/verify"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "new_email": newEmail,
        "otp": otp,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["detail"] ?? "Invalid OTP",
      );
    }

    return Map<String, dynamic>.from(data);
  }


  static Future<Map<String, dynamic>> uploadProfileImage({
    required String userId,
    required File image,
  }) async {
    final uri = Uri.parse("$baseUrl/profile/$userId/image");

    final extension = image.path.split('.').last.toLowerCase();

    String mimeType;

    switch (extension) {
      case "jpg":
      case "jpeg":
        mimeType = "jpeg";
        break;

      case "png":
        mimeType = "png";
        break;

      case "webp":
        mimeType = "webp";
        break;

      default:
        throw Exception(
          "Only JPG, PNG and WEBP images are allowed",
        );
    }

    final request = http.MultipartRequest(
      "POST",
      uri,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        image.path,
        contentType: MediaType("image", mimeType),
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data["detail"] ??
            data["message"] ??
            "Failed to upload profile image",
      );
    }

    return Map<String, dynamic>.from(data);
  }
}