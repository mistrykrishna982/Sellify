
import 'package:flutter/material.dart';

class ManageProductTypeDetailsScreen extends StatelessWidget {
final int productTypeId;
final String productTypeName;
final String categoryName;
final String aiDescription;

const ManageProductTypeDetailsScreen({
super.key,
required this.productTypeId,
required this.productTypeName,
required this.categoryName,
required this.aiDescription,
});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
"Product Type Details",
style: TextStyle(fontWeight: FontWeight.bold),
),
centerTitle: true,
),
body: ListView(
padding: const EdgeInsets.all(20),
children: [
const Icon(
Icons.inventory_2_outlined,
size: 72,
),
const SizedBox(height: 24),
_detailCard(
label: "Product Type",
value: productTypeName,
),
_detailCard(
label: "Product Type ID",
value: productTypeId.toString(),
),
_detailCard(
label: "Category",
value: categoryName,
),
_detailCard(
label: "AI Description",
value: aiDescription.isEmpty
? "No AI description available"
    : aiDescription,
),
],
),
);
}

Widget _detailCard({
required String label,
required String value,
}) {
return Card(
margin: const EdgeInsets.only(bottom: 14),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
fontSize: 13,
color: Colors.grey,
),
),
const SizedBox(height: 6),
Text(
value,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w600,
),
),
],
),
),
);
}
}

