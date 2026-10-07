import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ManageClassificationRequestsScreen extends StatefulWidget {
  const ManageClassificationRequestsScreen({
    super.key,
  });

  @override
  State<ManageClassificationRequestsScreen> createState() =>
      _ManageClassificationRequestsScreenState();
}

class _ManageClassificationRequestsScreenState
    extends State<ManageClassificationRequestsScreen> {

  bool isLoading = true;

  List<Map<String, dynamic>> requests = [];

  String? errorMessage;

  int _getRequestId(Map<String, dynamic> request) {
    final value =
        request["request_id"] ??
            request["REQUEST_ID"] ??
            request["requestId"] ??
            request["Request_ID"];

    if (value == null) {
      throw Exception(
        "Request ID was not returned by server. Response: $request",
      );
    }

    return int.parse(value.toString());
  }


  String _getString(
      Map<String, dynamic> request,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = request[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != "null") {
        return value.toString().trim();
      }
    }

    return "";
  }


  @override
  void initState() {
    super.initState();

    loadRequests();
  }





  // ============================================================
  // LOAD PENDING REQUESTS
  // ============================================================

  Future<void> loadRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await ApiService.getPendingClassificationRequests();

      if (!mounted) return;

      setState(() {
        requests = result
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // APPROVE
  // ============================================================

  Future<void> approveRequest(
      Map<String, dynamic> request,
      ) async {

    final int requestId = _getRequestId(request);

    try {

      setState(() {
        isLoading = true;
      });

      await ApiService.approveClassificationRequest(
        requestId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Classification request approved.",
          ),
        ),
      );

      await loadRequests();

    } catch (e) {

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to approve request: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // REJECT
  // ============================================================
  Future<void> rejectRequest(
      Map<String, dynamic> request,
      ) async {

    final int requestId = _getRequestId(request);

    final TextEditingController noteController =
    TextEditingController();

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text(
            "Reject Request",
          ),

          content: TextField(
            controller: noteController,
            maxLines: 3,

            decoration: const InputDecoration(
              labelText: "Admin note",
              hintText: "Enter reason for rejection",
              border: OutlineInputBorder(),
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                "CANCEL",
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                "REJECT",
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      noteController.dispose();
      return;
    }

    try {

      setState(() {
        isLoading = true;
      });

      await ApiService.rejectClassificationRequest(
        requestId,
        adminNote: noteController.text.trim(),
      );

      noteController.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Classification request rejected.",
          ),
        ),
      );

      await loadRequests();

    } catch (e) {

      noteController.dispose();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to reject request: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget buildRequestCard(
      Map<String, dynamic> request,
      ) {

    final int requestId = _getRequestId(request);

    final String category = _getString(
      request,
      [
        "category_name",
        "CATEGORY_NAME",
        "categoryName",
      ],
    );

    final String productType = _getString(
      request,
      [
        "product_type_name",
        "PRODUCT_TYPE_NAME",
        "productTypeName",
      ],
    );

    final String imagePath = _getString(
      request,
      [
        "image_path",
        "IMAGE_PATH",
        "imagePath",
      ],
    );

    final String userId = _getString(
      request,
      [
        "u_id",
        "U_ID",
        "user_id",
        "USER_ID",
        "userId",
      ],
    );

    final String imageUrl = imagePath.isEmpty
        ? ""
        : "${ApiService.baseUrl}/$imagePath"
        .replaceAll("\\", "/");

    return Card(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),

      elevation: 3,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // --------------------------------------------------
            // IMAGE
            // --------------------------------------------------

            ClipRRect(
              borderRadius:
              BorderRadius.circular(12),

              child: imageUrl.isEmpty
                  ? Container(
                height: 220,
                width: double.infinity,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 50,
                ),
              )
                  : Image.network(
                imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Request #$requestId",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "User ID: $userId",
              style: const TextStyle(
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Requested Category",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              category,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Requested Product Type",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              productType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                      approveRequest(
                        request,
                      );
                    },

                    icon: const Icon(
                      Icons.check,
                    ),

                    label: const Text(
                      "APPROVE",
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                      rejectRequest(
                        request,
                      );
                    },

                    icon: const Icon(
                      Icons.close,
                    ),

                    label: const Text(
                      "REJECT",
                    ),

                    style:
                    OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Classification Requests",
        ),

        actions: [

          IconButton(
            onPressed: isLoading
                ? null
                : loadRequests,

            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadRequests,

        child: isLoading

            ? const Center(
          child:
          CircularProgressIndicator(),
        )

            : errorMessage != null

            ? Center(
          child: Padding(
            padding:
            const EdgeInsets.all(24),

            child: Text(
              errorMessage!,
              textAlign:
              TextAlign.center,

              style:
              const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        )

            : requests.isEmpty

            ? ListView(
          children: const [

            SizedBox(height: 180),

            Center(
              child: Text(
                "No pending classification requests.",
                textAlign:
                TextAlign.center,

                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        )

            : ListView.builder(
          padding:
          const EdgeInsets.all(16),

          itemCount:
          requests.length,

          itemBuilder:
              (context, index) {

            return buildRequestCard(
              requests[index],
            );
          },
        ),
      ),
    );
  }
}