import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ProductDetailsScreen.dart';


class NotificationsScreen extends StatefulWidget {

  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}


class _NotificationsScreenState
    extends State<NotificationsScreen> {

  bool isLoading = true;

  String? errorMessage;

  List<Map<String, dynamic>> notifications = [];


  @override
  void initState() {
    super.initState();

    loadNotifications();
  }


  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> loadNotifications() async {

    try {

      final result =
      await ApiService.getNotifications();

      if (!mounted) return;

      setState(() {

        notifications = result;

        isLoading = false;

        errorMessage = null;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        isLoading = false;

        errorMessage =
            e.toString();
      });
    }
  }


  // ============================================================
  // OPEN NOTIFICATION
  // ============================================================

  Future<void> openNotification(
      Map<String, dynamic> notification,
      ) async {

    final int? notificationId =
    int.tryParse(
      notification["NOTIFICATION_ID"]
          ?.toString() ??
          notification["notification_id"]
              ?.toString() ??
          "",
    );

    if (notificationId != null) {

      try {

        await ApiService.markNotificationAsRead(
          notificationId,
        );

      } catch (_) {}
    }


    final String type =
    (
        notification["TYPE"] ??
            notification["type"] ??
            ""
    )
        .toString()
        .toUpperCase();


    // ========================================================
    // CLASSIFICATION APPROVED
    // ========================================================

    if (type == "CLASSIFICATION_APPROVED") {

      final int? categoryId =
      int.tryParse(
        (
            notification["CATEGORY_ID"] ??
                notification["category_id"]
        )
            ?.toString() ??
            "",
      );


      final int? productTypeId =
      int.tryParse(
        (
            notification["PRODUCT_TYPE_ID"] ??
                notification["product_type_id"]
        )
            ?.toString() ??
            "",
      );


      final String categoryName =
      (
          notification["CATEGORY_NAME"] ??
              notification["category_name"] ??
              ""
      )
          .toString();


      final String productTypeName =
      (
          notification["PRODUCT_TYPE_NAME"] ??
              notification["product_type_name"] ??
              ""
      )
          .toString();


      if (categoryId == null ||
          productTypeId == null) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Classification information is incomplete.",
            ),
          ),
        );

        return;
      }


      // ------------------------------------------------------
      // CONTINUE SELLING DIALOG
      // ------------------------------------------------------

      await showDialog(
        context: context,
        builder: (dialogContext) {

          return AlertDialog(

            title: const Row(
              children: [

                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    "Admin Approved",
                  ),
                ),
              ],
            ),

            content: Text(
              "Your product was approved as "
                  "$productTypeName in $categoryName.\n\n"
                  "Continue selling your product.",
            ),

            actions: [

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.pop(
                      dialogContext,
                    );

                    final Map<String, dynamic>
                    aiResult = {

                      "category":
                      categoryName,

                      "product_type":
                      productTypeName,

                      "category_id":
                      categoryId,

                      "product_type_id":
                      productTypeId,

                      "image_path":
                      notification[
                      "IMAGE_PATH"] ??
                          notification[
                          "image_path"],

                      "user_edited_classification":
                      true,
                    };


                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(
                              imagePath:
                              aiResult[
                              "image_path"],
                              aiResult:
                              aiResult,
                            ),
                      ),
                    );
                  },

                  child: const Text(
                    "CONTINUE SELLING",
                  ),
                ),
              ),
            ],
          );
        },
      );

      await loadNotifications();
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(

        onRefresh: loadNotifications,

        child: isLoading

            ? const Center(
          child: CircularProgressIndicator(),
        )

            : errorMessage != null

            ? ListView(
          children: [

            const SizedBox(
              height: 200,
            ),

            Center(
              child: Text(
                errorMessage!,
              ),
            ),
          ],
        )

            : notifications.isEmpty

            ? ListView(
          children: const [

            SizedBox(
              height: 200,
            ),

            Center(
              child: Column(
                children: [

                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey,
                  ),

                  SizedBox(
                    height: 15,
                  ),

                  Text(
                    "No notifications",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )

            : ListView.builder(

          padding:
          const EdgeInsets.all(12),

          itemCount:
          notifications.length,

          itemBuilder:
              (context, index) {

            final notification =
            notifications[index];

            final String title =
            (
                notification["TITLE"] ??
                    notification["title"] ??
                    "Notification"
            )
                .toString();

            final String message =
            (
                notification["MESSAGE"] ??
                    notification["message"] ??
                    ""
            )
                .toString();

            final String status =
            (
                notification["STATUS"] ??
                    notification["status"] ??
                    "READ"
            )
                .toString()
                .toUpperCase();

            final bool unread =
                status == "UNREAD";


            return Card(

              margin:
              const EdgeInsets.only(
                bottom: 12,
              ),

              color: unread
                  ? Colors.blue.shade50
                  : Colors.white,

              child: ListTile(

                contentPadding:
                const EdgeInsets.all(
                  12,
                ),

                leading: Container(

                  width: 50,
                  height: 50,

                  decoration:
                  BoxDecoration(
                    color:
                    Colors.green.shade50,
                    shape:
                    BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),

                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                subtitle: Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 5,
                  ),

                  child: Text(
                    message,
                  ),
                ),

                trailing: unread
                    ? Container(
                  width: 10,
                  height: 10,
                  decoration:
                  const BoxDecoration(
                    color:
                    Colors.blue,
                    shape:
                    BoxShape.circle,
                  ),
                )
                    : null,

                onTap: () {
                  openNotification(
                    notification,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}