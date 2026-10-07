import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';


class ApiService {
  static const String baseUrl = "http://10.210.212.48:8000";

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


  static Future<Map<String, dynamic>> uploadProductImage(
      File image,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/products/upload-image",
    );

    final request = http.MultipartRequest(
      "POST",
      uri,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        image.path,
      ),
    );

    final response = await request.send();

    final responseBody =
    await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    }

    throw Exception(
      "Image upload failed: ${response.statusCode} - $responseBody",
    );
  }


  static Future<Map<String, dynamic>> analyzeProductImage(
      File image,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/products/analyze",
    );

    final request = http.MultipartRequest(
      "POST",
      uri,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        image.path,
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
            "AI analysis failed",
      );
    }

    return Map<String, dynamic>.from(data);
  }


  static Future<List<Map<String, dynamic>>> getCategoryAttributes(
      int categoryId,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/categories/$categoryId/attributes",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(
        data["attributes"],
      );
    }

    throw Exception(
      "Failed to load category attributes: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<List<Map<String, dynamic>>> getProductTypeAttributes(
      int productTypeId,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/product-types/$productTypeId/attributes",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(
        data["attributes"],
      );
    }

    throw Exception(
      "Failed to load product type attributes: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<List<Map<String, dynamic>>> getCategories() async {
    final uri = Uri.parse(
      "$baseUrl/categories",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(
        data["categories"],
      );
    }

    throw Exception(
      "Failed to load categories: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<Map<String, dynamic>> createCategory({
    required String categoryName,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/categories",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "category_name": categoryName,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to create category",
    );
  }

  static Future<int> predictPrice({
    required String category,
    required String productType,
    required String title,
    required String age,
    required String description,
    required String condition,
  }) async {
    final uri =
    Uri.parse("$baseUrl/products/predict-price");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "category": category,
        "product_type": productType,
        "title": title,
        "age": age,
        "description": description,
        "condition": condition,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      final price = data["ai_price"];

      if (price == null) {
        throw Exception(
          "AI price was not returned by server",
        );
      }

      return int.parse(
        price.toString(),
      );
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to predict price",
    );
  }



  // ============================================================
// RESOLVE / CREATE PRODUCT CLASSIFICATION
// ============================================================

  static Future<Map<String, dynamic>>
  resolveProductClassification({
    required String category,
    required String productType,
  }) async {

    final uri = Uri.parse(
      "$baseUrl/products/resolve-classification",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Login token not found",
      );
    }

    final response = await http.post(
      uri,

      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },

      body: jsonEncode({
        "category": category,
        "product_type": productType,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to resolve product classification",
    );
  }



  static Future<Map<String, dynamic>> createProduct({
    required int categoryId,
    required int productTypeId,
    required String title,
    required String description,
    required String condition,
    required int price,
    required int aiPrice,
    required String location,
    required String imagePath,
    required String? aiProductName,
    required double? aiConfidence,
    required Map<int, String> attributes,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/products/create",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Login token not found",
      );
    }

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "category_id": categoryId,
        "product_type_id": productTypeId,
        "title": title,
        "description": description,
        "condition": condition,
        "price": price,
        "ai_price": aiPrice,
        "location": location,
        "image_path": imagePath,
        "ai_product_name": aiProductName,
        "ai_confidence": aiConfidence,
        "attributes": attributes.map(
              (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        ),
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to create product",
    );
  }



  // ============================================================
  // CLASSIFICATION REQUEST
  // ============================================================

  static Future<Map<String, dynamic>>
  submitClassificationRequest({
    required String categoryName,
    required String productTypeName,
    required String imagePath,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/classification-requests",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Login token not found");
    }

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "category_name": categoryName,
        "product_type_name": productTypeName,
        "image_path": imagePath,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to submit classification request",
    );
  }


  // ============================================================
  // CHECK CLASSIFICATION REQUEST
  // ============================================================

  static Future<Map<String, dynamic>>
  getClassificationRequest(
      int requestId,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/classification-requests/$requestId",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Login token not found");
    }

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to check classification request",
    );
  }


  // ============================================================
  // ADMIN: GET PENDING CLASSIFICATION REQUESTS
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getPendingClassificationRequests() async {
    final uri = Uri.parse(
      "$baseUrl/classification-requests/admin/pending",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Admin login token not found");
    }

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        data["requests"] ?? [],
      );
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to load classification requests",
    );
  }


  // ============================================================
  // ADMIN: APPROVE CLASSIFICATION REQUEST
  // ============================================================

  static Future<Map<String, dynamic>>
  approveClassificationRequest(
      int requestId,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/classification-requests/admin/"
          "$requestId/approve",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Admin login token not found");
    }

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to approve classification request",
    );
  }


  // ============================================================
  // ADMIN: REJECT CLASSIFICATION REQUEST
  // ============================================================
  static Future<Map<String, dynamic>>
  rejectClassificationRequest(
      int requestId, {
        String? adminNote,
      }) async {

    final uri = Uri.parse(
      "$baseUrl/classification-requests/admin/"
          "$requestId/reject",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.post(
      uri,

      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },

      body: jsonEncode({
        "admin_note": adminNote,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to reject classification request",
    );
  }

  static Future<List<Map<String, dynamic>>> getProducts({
    required String userId,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/products?user_id=$userId",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List products = data["products"] ?? [];

      return products
          .map(
            (product) =>
        Map<String, dynamic>.from(product),
      )
          .toList();
    }

    throw Exception(
      "Failed to load products: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<List<Map<String, dynamic>>> getMyProducts({
    required String userId,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/products/user/$userId",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List products = data["products"] ?? [];

      return products
          .map(
            (product) =>
        Map<String, dynamic>.from(product),
      )
          .toList();
    }

    throw Exception(
      "Failed to load my products: "
          "${response.statusCode} - ${response.body}",
    );
  }



  // ============================================================
// GET SINGLE MY PRODUCT DETAILS
// ============================================================

  static Future<Map<String, dynamic>> getMyProductDetails({
    required int productId,
  }) async {

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception("Login token not found");
    }

    final response = await http.get(
      Uri.parse(
        "$baseUrl/products/$productId",
      ),
      headers: {
        "Authorization":
        "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {

      return Map<String, dynamic>.from(
        data["product"],
      );
    }

    throw Exception(
      data["detail"] ??
          "Failed to load product details",
    );
  }



  static Future<String> requestForgotPasswordOtp({
    required String email,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/forgot-password/request",
    );

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["message"] ?? "OTP sent successfully.";
    }

    throw Exception(
      "Failed to send OTP: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/forgot-password/verify",
    );

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["message"] ?? "OTP verified successfully.";
    }

    throw Exception(
      "OTP verification failed: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<String> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/forgot-password/reset",
    );

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "new_password": newPassword,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["message"] ?? "Password reset successfully.";
    }

    throw Exception(
      "Password reset failed: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<List<Map<String, dynamic>>> getProductTypes({
    int? categoryId,
  }) async {
    final uri = Uri.parse(
      categoryId == null
          ? "$baseUrl/product-types"
          : "$baseUrl/product-types?category_id=$categoryId",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(
        data["product_types"],
      );
    }

    throw Exception(
      "Failed to load product types: "
          "${response.statusCode} - ${response.body}",
    );
  }

  static Future<Map<String, dynamic>> createProductType({
    required String productTypeName,
    required int categoryId,
    String? aiDescription,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/product-types",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "product_type_name": productTypeName,
        "category_id": categoryId,
        "ai_description": aiDescription,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to create product type",
    );
  }


  static Future<Map<String, dynamic>> addAttributeToProductType({
    required int productTypeId,
    required int attributeId,
    bool isRequired = false,
    int displayOrder = 0,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/product-types/$productTypeId/attributes"
          "?attribute_id=$attributeId"
          "&is_required=$isRequired"
          "&display_order=$displayOrder",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to add attribute to product type",
    );
  }


  static Future<List<Map<String, dynamic>>>
  getAdminProductTypeAttributes(
      int productTypeId,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/product-types/$productTypeId/attributes",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(
        data["attributes"],
      );
    }

    throw Exception(
      "Failed to load product type attributes: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<List<Map<String, dynamic>>>
  getAllAttributeDefinitions() async {

    final uri = Uri.parse(
      "$baseUrl/product-types/attributes",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        data["attributes"],
      );
    }

    throw Exception(
      data["detail"] ??
          "Failed to load attribute definitions",
    );
  }


  static Future<Map<String, dynamic>> createAttributeForProductType({
    required int productTypeId,
    required String attributeName,
    String attributeType = "TEXT",
  }) async {

    final uri = Uri.parse(
      "$baseUrl/product-types/$productTypeId/attributes/create",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "attribute_name": attributeName,
        "attribute_type": attributeType,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to create attribute",
    );
  }

  static Future<List<Map<String, dynamic>>>
  getAvailableProductTypeAttributes(
      int productTypeId,
      ) async {
    final uri = Uri.parse(
      "$baseUrl/product-types/$productTypeId/available-attributes",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(
        data["attributes"],
      );
    }

    throw Exception(
      "Failed to load available attributes: "
          "${response.statusCode} - ${response.body}",
    );
  }


  static Future<List<Map<String, dynamic>>>
  getUnsupportedProducts() async {

    final uri = Uri.parse(
      "$baseUrl/unsupported-products",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      print("UNSUPPORTED PRODUCTS RESPONSE: $data");

      return List<Map<String, dynamic>>.from(
        data["unsupported_products"] ?? [],
      );
    }

    throw Exception(
      data["detail"] ??
          "Failed to load unsupported products",
    );
  }




  static Future<Map<String, dynamic>>
  addUnsupportedProductAsProductType({
    required int unsupportedProductId,
    required int categoryId,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/unsupported-products/"
          "$unsupportedProductId/add"
          "?category_id=$categoryId",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to add unsupported product",
    );
  }



  static Future<Map<String, dynamic>>
  approveUnsupportedProduct({
    required int unsupportedProductId,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/unsupported-products/"
          "$unsupportedProductId/approve",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to approve unsupported product",
    );
  }



  static Future<Map<String, dynamic>>
  removeAttributeFromProductType({
    required int productTypeId,
    required int attributeId,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/product-types/$productTypeId/attributes/$attributeId",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.delete(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to remove attribute",
    );
  }


  static Future<List<String>> getReportTables() async {
    final uri = Uri.parse(
      "$baseUrl/admin/reports/tables",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return List<String>.from(
        data["tables"] ?? [],
      );
    }

    throw Exception(
      data["detail"] ??
          "Failed to load report tables",
    );
  }


  static Future<Map<String, dynamic>> generateReport({
    required String tableName,
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, String>{
      "table_name": tableName,
      "period": period,
    };

    if (startDate != null) {
      queryParameters["start_date"] =
      "${startDate.year.toString().padLeft(4, '0')}-"
          "${startDate.month.toString().padLeft(2, '0')}-"
          "${startDate.day.toString().padLeft(2, '0')}";
    }

    if (endDate != null) {
      queryParameters["end_date"] =
      "${endDate.year.toString().padLeft(4, '0')}-"
          "${endDate.month.toString().padLeft(2, '0')}-"
          "${endDate.day.toString().padLeft(2, '0')}";
    }

    final uri = Uri.parse(
      "$baseUrl/admin/reports",
    ).replace(
      queryParameters: queryParameters,
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          "Failed to generate report",
    );
  }




  static Future<List<int>> downloadReportPdf({
    required String tableName,
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, String>{
      "table_name": tableName,
      "period": period,
    };

    if (startDate != null) {
      queryParameters["start_date"] =
      "${startDate.year.toString().padLeft(4, '0')}-"
          "${startDate.month.toString().padLeft(2, '0')}-"
          "${startDate.day.toString().padLeft(2, '0')}";
    }

    if (endDate != null) {
      queryParameters["end_date"] =
      "${endDate.year.toString().padLeft(4, '0')}-"
          "${endDate.month.toString().padLeft(2, '0')}-"
          "${endDate.day.toString().padLeft(2, '0')}";
    }

    final uri = Uri.parse(
      "$baseUrl/admin/reports/pdf",
    ).replace(
      queryParameters: queryParameters,
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    String errorMessage;

    try {
      final data = jsonDecode(response.body);
      errorMessage =
          data["detail"] ??
              data["message"] ??
              "Failed to download PDF";
    } catch (_) {
      errorMessage = "Failed to download PDF";
    }

    throw Exception(
      "$errorMessage (${response.statusCode})",
    );
  }


  static Future<void> deleteCategory({
    required int categoryId,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/categories/$categoryId",
    );

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Admin login token not found",
      );
    }

    final response = await http.delete(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      data["detail"] ??
          "Failed to delete category",
    );
  }


  static Future<List<Map<String, dynamic>>>
  getNotifications() async {

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception("Login token not found");
    }

    final response = await http.get(
      Uri.parse(
        "$baseUrl/notifications",
      ),
      headers: {
        "Authorization":
        "Bearer $accessToken",
      },
    );

    final data =
    jsonDecode(response.body);

    if (response.statusCode == 200) {

      return List<Map<String, dynamic>>.from(
        data["notifications"] ?? [],
      );
    }

    throw Exception(
      data["detail"] ??
          "Failed to load notifications",
    );
  }


  static Future<int>
  getUnreadNotificationCount() async {

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception("Login token not found");
    }

    final response = await http.get(
      Uri.parse(
        "$baseUrl/notifications/unread-count",
      ),
      headers: {
        "Authorization":
        "Bearer $accessToken",
      },
    );

    final data =
    jsonDecode(response.body);

    if (response.statusCode == 200) {

      return int.tryParse(
        data["unread_count"].toString(),
      ) ??
          0;
    }

    throw Exception(
      data["detail"] ??
          "Failed to get notification count",
    );
  }


  // ============================================================
// MARK NOTIFICATION AS READ
// ============================================================

  static Future<void> markNotificationAsRead(
      int notificationId,
      ) async {

    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        "Login token not found",
      );
    }

    final response = await http.patch(
      Uri.parse(
        "$baseUrl/notifications/$notificationId/read",
      ),
      headers: {
        "Authorization":
        "Bearer $accessToken",
      },
    );

    if (response.statusCode != 200) {

      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          "Invalid server response: ${response.body}",
        );
      }

      throw Exception(
        data["detail"] ??
            "Failed to mark notification as read",
      );
    }
  }


// ---------------------------------------------------
// Delete / Stop Selling Product
// ---------------------------------------------------

  static Future<void> deleteProduct({
    required int productId,
  }) async {
    final accessToken = await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Login token not found");
    }

    final response = await http.delete(
      Uri.parse(
        "$baseUrl/products/$productId",
      ),
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode != 200) {
      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          "Invalid server response: ${response.body}",
        );
      }

      throw Exception(
        data["detail"] ?? "Failed to delete product",
      );
    }
  }


  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String title,
    required String age,
    required String description,
    required String condition,
    required String location,
    required double price,
    double? aiPrice,
  }) async {
    final accessToken =
    await AuthService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Login token not found");
    }

    final response = await http.put(
      Uri.parse(
        "$baseUrl/products/$productId",
      ),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "title": title.trim(),
        "age": age.trim(),
        "description": description.trim(),
        "condition": condition.trim(),
        "location": location.trim(),
        "price": price,
        "ai_price": aiPrice,
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response: ${response.body}",
      );
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "Failed to update product",
    );
  }

}