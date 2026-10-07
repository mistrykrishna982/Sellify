import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:typed_data';
import 'package:public_file_saver/public_file_saver.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() =>
      _AdminReportScreenState();
}

class _AdminReportScreenState
    extends State<AdminReportScreen> {

  List<String> reportTables = [];

  String? selectedTable;
  String? selectedPeriod;

  DateTime? startDate;
  DateTime? endDate;

  Map<String, dynamic>? reportData;

  bool isLoadingTables = true;
  bool isGenerating = false;
  bool showDetails = false;

  final List<String> periods = [
    "weekly",
    "monthly",
    "yearly",
    "custom",
  ];

  @override
  void initState() {
    super.initState();
    loadReportTables();
  }

  Future<void> loadReportTables() async {
    try {
      final tables =
      await ApiService.getReportTables();

      if (!mounted) return;

      setState(() {
        reportTables = tables;
        isLoadingTables = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingTables = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load report tables: $e",
          ),
        ),
      );
    }
  }

  Future<void> selectDate({
    required bool isStartDate,
  }) async {
    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStartDate) {
        startDate = picked;
      } else {
        endDate = picked;
      }

      reportData = null;
      showDetails = false;
    });
  }

  Future<void> generateReport() async {
    if (selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a report type",
          ),
        ),
      );
      return;
    }

    if (selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a report period",
          ),
        ),
      );
      return;
    }

    if (selectedPeriod == "custom") {
      if (startDate == null ||
          endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please select both dates",
            ),
          ),
        );
        return;
      }

      if (startDate!.isAfter(endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Start date cannot be after end date",
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      isGenerating = true;
      reportData = null;
      showDetails = false;
    });

    try {
      final result =
      await ApiService.generateReport(
        tableName: selectedTable!,
        period: selectedPeriod!,
        startDate:
        selectedPeriod == "custom"
            ? startDate
            : null,
        endDate:
        selectedPeriod == "custom"
            ? endDate
            : null,
      );

      if (!mounted) return;

      setState(() {
        reportData = result;
        isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to generate report: $e",
          ),
        ),
      );
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return "Select date";
    }

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String reportTitle() {
    if (selectedTable == null) {
      return "Report";
    }

    switch (selectedTable) {
      case "USERS":
        return "Users Report";

      case "PRODUCTS":
        return "Products Report";

      case "PRODUCT_IMAGES":
        return "Product Images Report";

      case "UNSUPPORTED_PRODUCTS":
        return "Unsupported Products Report";

      default:
        return selectedTable!;
    }
  }

  String periodTitle() {
    switch (selectedPeriod) {
      case "weekly":
        return "Weekly";

      case "monthly":
        return "Monthly";

      case "yearly":
        return "Yearly";

      case "custom":
        return "Custom Date";

      default:
        return "Not selected";
    }
  }

  String getReportDateRange() {
    if (reportData == null) {
      return "";
    }

    final start =
        reportData!["start_date"]?.toString() ?? "";

    final end =
        reportData!["end_date"]?.toString() ?? "";

    if (start.isEmpty || end.isEmpty) {
      return "";
    }

    return "$start  →  $end";
  }

  @override
  Widget build(BuildContext context) {
    final hasReport = reportData != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FA),

      appBar: AppBar(
        title: const Text(
          "Admin Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const Text(
                "Generate Report",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Create a report from Sellify data.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionLabel(
                "Report Type",
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: selectedTable,

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.blue.shade700,
                      width: 1.5,
                    ),
                  ),
                ),

                hint: const Text(
                  "Select report type",
                ),

                items: reportTables.map(
                      (table) {
                    return DropdownMenuItem<String>(
                      value: table,
                      child: Text(
                        table,
                      ),
                    );
                  },
                ).toList(),

                onChanged: isLoadingTables
                    ? null
                    : (value) {
                  setState(() {
                    selectedTable = value;
                    reportData = null;
                    showDetails = false;
                  });
                },
              ),

              const SizedBox(height: 20),

              _buildSectionLabel(
                "Report Period",
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: selectedPeriod,

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.blue.shade700,
                      width: 1.5,
                    ),
                  ),
                ),

                hint: const Text(
                  "Select report period",
                ),

                items: periods.map(
                      (period) {
                    String label;

                    switch (period) {
                      case "weekly":
                        label = "Weekly";
                        break;

                      case "monthly":
                        label = "Monthly";
                        break;

                      case "yearly":
                        label = "Yearly";
                        break;

                      default:
                        label = "Custom Date";
                    }

                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(label),
                    );
                  },
                ).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedPeriod = value;
                    reportData = null;
                    showDetails = false;

                    if (value != "custom") {
                      startDate = null;
                      endDate = null;
                    }
                  });
                },
              ),

              if (selectedPeriod == "custom") ...[
                const SizedBox(height: 20),

                _buildSectionLabel(
                  "Date Range",
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    Expanded(
                      child: _buildDateButton(
                        title: "From",
                        date: startDate,
                        onTap: () {
                          selectDate(
                            isStartDate: true,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildDateButton(
                        title: "To",
                        date: endDate,
                        onTap: () {
                          selectDate(
                            isStartDate: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed:
                  isGenerating
                      ? null
                      : generateReport,

                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.blue.shade700,
                    foregroundColor:
                    Colors.white,
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),

                  child: isGenerating
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
                    "Generate Report",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (hasReport) ...[
                const SizedBox(height: 30),

                _buildReportSummary(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
      String text,
      ) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDateButton({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
      BorderRadius.circular(14),

      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              formatDate(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSummary() {
    final rows =
    List<Map<String, dynamic>>.from(
      reportData?["rows"] ?? [],
    );

    final count =
        reportData?["count"] ?? rows.length;

    final generatedBy =
    reportData?["generated_by"];

    final adminName =
    generatedBy is Map
        ? generatedBy["name"]?.toString() ?? "Unknown"
        : "Unknown";

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Divider(),

        const SizedBox(height: 20),

        const Text(
          "REPORT SUMMARY",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,

          padding:
          const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.05),
                blurRadius: 12,
                offset:
                const Offset(0, 4),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                reportTitle(),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                getReportDateRange(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Generated by: $adminName",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding:
                const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color:
                  Colors.blue.shade50,
                  borderRadius:
                  BorderRadius.circular(14),
                ),

                child: Row(
                  children: [

                    Icon(
                      Icons
                          .assessment_outlined,
                      color:
                      Colors.blue.shade700,
                      size: 32,
                    ),

                    const SizedBox(width: 14),

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "Total Records",
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          "$count",
                          style:
                          const TextStyle(
                            fontSize: 25,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: rows.isEmpty
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReportDetailsScreen(
                              title: reportTitle(),
                              rows: rows,
                            ),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.visibility_outlined,
                  ),

                  label: const Text(
                    "View Details",
                  ),

                  style:
                  OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final pdfBytes =
                      await ApiService.downloadReportPdf(
                        tableName: selectedTable!,
                        period: selectedPeriod!,
                        startDate:
                        selectedPeriod == "custom"
                            ? startDate
                            : null,
                        endDate:
                        selectedPeriod == "custom"
                            ? endDate
                            : null,
                      );

                      final fileName =
                          "${selectedTable!.toLowerCase()}_report_"
                          "${DateTime.now().millisecondsSinceEpoch}.pdf";

                      final fileSaver = PublicFileSaver();

                      final savedFile =
                      await fileSaver.saveBytes(
                        bytes: Uint8List.fromList(pdfBytes),
                        fileName: fileName,
                        mimeType: "application/pdf",
                      );

                      if (savedFile == null) {
                        throw Exception(
                          "PDF could not be saved",
                        );
                      }

                      final openIntent = AndroidIntent(
                        action: "action_view",
                        data: savedFile.uri,
                        type: "application/pdf",
                        flags: <int>[
                          Flag.FLAG_GRANT_READ_URI_PERMISSION,
                        ],
                      );

                      await openIntent.launch();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "PDF saved to Downloads",
                          ),
                        ),
                      );

                      await openIntent.launch();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "PDF saved to Downloads",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Failed to save PDF: $e",
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                  ),

                  label: const Text(
                    "Download PDF",
                  ),

                  style:
                  OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 14,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showDetails &&
            rows.isNotEmpty) ...[
          const SizedBox(height: 16),

          _buildDetails(rows),
        ],
      ],
    );
  }

  Widget _buildDetails(
      List<Map<String, dynamic>> rows,
      ) {
    final columns =
    rows.first.keys.toList();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
      ),

      child: SingleChildScrollView(
        scrollDirection:
        Axis.horizontal,

        child: DataTable(
          columns: columns.map(
                (column) {
              return DataColumn(
                label: Text(
                  column,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              );
            },
          ).toList(),

          rows: rows.map(
                (row) {
              return DataRow(
                cells: columns.map(
                      (column) {
                    return DataCell(
                      Text(
                        row[column]
                            ?.toString() ??
                            "",
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ).toList(),
        ),
      ),
    );
  }





}

class ReportDetailsScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> rows;

  const ReportDetailsScreen({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final columns = rows.isEmpty
        ? <String>[]
        : rows.first.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),

      body: rows.isEmpty
          ? const Center(
        child: Text(
          "No records found.",
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(
          scrollDirection:
          Axis.horizontal,

          child: DataTable(
            columns: columns.map(
                  (column) {
                return DataColumn(
                  label: Text(
                    column,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                );
              },
            ).toList(),

            rows: rows.map(
                  (row) {
                return DataRow(
                  cells: columns.map(
                        (column) {
                      return DataCell(
                        Text(
                          row[column]
                              ?.toString() ??
                              "",
                        ),
                      );
                    },
                  ).toList(),
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }
}