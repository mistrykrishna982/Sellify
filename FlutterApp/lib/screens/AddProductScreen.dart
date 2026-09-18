import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import 'AIAnalysisScreen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ImagePicker _picker = ImagePicker();

  List<File> selectedImages = [];

  bool isUploading = false;

  static const int maxImages = 5;

  // --------------------------------------------------
  // TAKE PHOTO
  // --------------------------------------------------

  Future<void> takePhoto() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can select a maximum of 5 images."),
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        selectedImages.add(File(image.path));
      });
    }
  }

  // --------------------------------------------------
  // CHOOSE FROM GALLERY
  // --------------------------------------------------

  Future<void> chooseFromGallery() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can select a maximum of 5 images."),
        ),
      );
      return;
    }

    final int remainingImages =
        maxImages - selectedImages.length;

    final List<XFile> images =
    await _picker.pickMultiImage(
      imageQuality: 80,
    );

    if (images.isEmpty) {
      return;
    }

    final List<XFile> imagesToAdd =
    images.take(remainingImages).toList();

    setState(() {
      selectedImages.addAll(
        imagesToAdd.map(
              (image) => File(image.path),
        ),
      );
    });

    if (images.length > remainingImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Only 5 images can be selected.",
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // REMOVE IMAGE
  // --------------------------------------------------

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // --------------------------------------------------
  // START AI ANALYSIS
  // --------------------------------------------------

  Future<void> continueToAIAnalysis() async {
    if (selectedImages.isEmpty) {
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // First image is the primary image.
      final File primaryImage = selectedImages.first;

      // AI initially analyzes only the primary image.
      final result =
      await ApiService.analyzeProductImage(
        primaryImage,
      );

      if (!mounted) return;

      print("AI RESULT: $result");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIAnalysisScreen(
            image: primaryImage,
            result: {
              ...result,
              "allImages": selectedImages,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "AI analysis failed: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sell Product",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const Text(
              "Add Your Product",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Add up to 5 photos of the product you want to sell.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // IMAGE PREVIEW
            // --------------------------------------------------

            if (selectedImages.isEmpty)
              Container(
                width: double.infinity,
                height: 280,

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius:
                  BorderRadius.circular(20),

                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Column(
                children: [
                  // PRIMARY IMAGE
                  Container(
                    width: double.infinity,
                    height: 280,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,

                      borderRadius:
                      BorderRadius.circular(20),

                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),

                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(20),

                      child: Image.file(
                        selectedImages.first,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Align(
                    alignment: Alignment.centerLeft,

                    child: Text(
                      "Primary image",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // OTHER IMAGES
                  SizedBox(
                    height: 90,

                    child: ListView.builder(
                      scrollDirection:
                      Axis.horizontal,

                      itemCount:
                      selectedImages.length,

                      itemBuilder:
                          (context, index) {
                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            right: 10,
                          ),

                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,

                                decoration:
                                BoxDecoration(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    12,
                                  ),

                                  border:
                                  Border.all(
                                    color: Colors
                                        .grey
                                        .shade300,
                                  ),
                                ),

                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    12,
                                  ),

                                  child: Image.file(
                                    selectedImages[
                                    index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // REMOVE BUTTON
                              Positioned(
                                top: 3,
                                right: 3,

                                child:
                                GestureDetector(
                                  onTap: () {
                                    removeImage(
                                      index,
                                    );
                                  },

                                  child: Container(
                                    width: 25,
                                    height: 25,

                                    decoration:
                                    const BoxDecoration(
                                      color:
                                      Colors.black54,
                                      shape:
                                      BoxShape.circle,
                                    ),

                                    child:
                                    const Icon(
                                      Icons.close,
                                      color:
                                      Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),

                              // PRIMARY LABEL
                              if (index == 0)
                                Positioned(
                                  bottom: 3,
                                  left: 3,

                                  child: Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),

                                    decoration:
                                    BoxDecoration(
                                      color:
                                      Colors.black54,
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        5,
                                      ),
                                    ),

                                    child: const Text(
                                      "MAIN",
                                      style:
                                      TextStyle(
                                        color:
                                        Colors.white,
                                        fontSize: 9,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // IMAGE COUNT
            // --------------------------------------------------

            Text(
              "${selectedImages.length}/$maxImages images selected",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // TAKE PHOTO
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed:
                selectedImages.length >= maxImages
                    ? null
                    : takePhoto,

                icon: const Icon(
                  Icons.camera_alt,
                ),

                label: const Text(
                  "Take Photo",
                ),

                style:
                ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // GALLERY
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed:
                selectedImages.length >= maxImages
                    ? null
                    : chooseFromGallery,

                icon: const Icon(
                  Icons.photo_library_outlined,
                ),

                label: const Text(
                  "Choose From Gallery",
                ),

                style:
                OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // CONTINUE
            // --------------------------------------------------

            if (selectedImages.isNotEmpty)
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : continueToAIAnalysis,

                  style:
                  ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                  ),

                  child: isUploading
                      ? const SizedBox(
                    height: 22,
                    width: 22,

                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "CONTINUE",

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}