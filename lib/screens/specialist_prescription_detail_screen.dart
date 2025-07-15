
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/foundation.dart' show ByteData, Uint8List, kIsWeb;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;  // Import path package

import '../models/specialist_prescription_item.dart';
import '../models/specialist_prescription_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class SpecialistPrescriptionDetailScreen extends StatefulWidget {
  final String consultationId;

  const SpecialistPrescriptionDetailScreen({Key? key, required this.consultationId})
      : super(key: key);

  @override
  _SpecialistPrescriptionDetailScreenState createState() =>
      _SpecialistPrescriptionDetailScreenState();
}

class _SpecialistPrescriptionDetailScreenState
    extends State<SpecialistPrescriptionDetailScreen> {
  SpecialistPrescriptionResponse? _prescriptionResponse;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPrescriptionData();
  }

  Future<void> _fetchPrescriptionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Construct the URL with the consultation_id as a query parameter
    final String url =
        'https://webdocsite.webddocsystems.com/public/api/v1/prescription/view?consultation_id=${widget.consultationId}';

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
      'Cookie': 'ci_session=rlvi7sqhnih4jcgqv8di1m1uftdr6b22', // Replace with the actual session id
    };

    try {
      final response = await http.get(
        Uri.parse(url), // Use the constructed URL
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        print('API Response: ${response.body}');
        setState(() {
          _prescriptionResponse =
              SpecialistPrescriptionResponse.fromJson(decodedResponse);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
          'Failed to load prescription data. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred while fetching data: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 16),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Prescription",
          style: AppStyles.bodyLarge(context).copyWith(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primaryColor),
      ));
    } else if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_prescriptionResponse == null ||
        _prescriptionResponse!.payLoad == null) {
      return const Center(
          child: Text('No prescription data available.')); // or display a message
    } else {
      return _buildPrescriptionDetails(_prescriptionResponse!.payLoad!);
    }
  }

  Widget _buildPrescriptionDetails(Consultation consultation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDoctorHeader(context, consultation),
          const SizedBox(height: 24),
          _buildDiagnosticSection(consultation),
          const SizedBox(height: 24),
          Text('Medicines:',
              style: AppStyles.titleMedium(context)
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (consultation.consultationdetails != null &&
              consultation.consultationdetails!.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: consultation.consultationdetails!.length,
              itemBuilder: (context, index) {
                final detail = consultation.consultationdetails![index];
                return SpecialistPrescriptionItem(detail: detail); // Changed here!
              },
            )
          else
            const Text('No medicines prescribed.',
                style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader(BuildContext context, Consultation consultation) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
              Icons.local_hospital, size: 40, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consultation.doctorName ?? "N/A",
                    style: AppStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold)),
                Text(
                  'Date: ${consultation.consultationDate != null
                      ? DateFormat('dd MMM yyyy hh:mm a').format( // Format for display
                      DateFormat('dd-MMM-yyyy hh:mm:ss a', 'en_US') // Correct parsing format
                          .parse(consultation.consultationDate!))
                      : "N/A"}',
                  style: AppStyles.bodySmall(context)
                      .copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Row( // Wrap the IconButtons in a Row
            mainAxisSize: MainAxisSize.min, // Important to keep the row small
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                icon: Image.asset(
                  'assets/images/download.png',
                  width: 30,
                  height: 30,
                ),
                onPressed: () {
                  _downloadPdf(context, consultation);
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: Image.asset(
                  'assets/images/share.png',
                  width: 30,
                  height: 30,
                ),
                onPressed: () {
                  _generateAndSavePdf(context, consultation);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection(Consultation consultation) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDiagnosticRow(
                    context, 'Complaint:', consultation.complaint ?? "N/A"),
                _buildDiagnosticRow(
                    context, 'Diagnosis:', consultation.diagnosis ?? "N/A"),
                _buildDiagnosticRow(context, 'Tests:', consultation.tests ?? "N/A"),
                if (consultation.remarks != null &&
                    consultation.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Remarks:',
                    style: AppStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.bold),
                  ),
                  ExpandableText(text: consultation.remarks!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagnosticRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.bold)),
          Text(value,
              style: AppStyles.bodyMedium(context)
                  .copyWith(color: Colors.grey)),
        ],
      ),
    );
  }


  Future<void> _generateAndSavePdf(BuildContext context,
      Consultation consultation) async {
    final pdf = pw.Document();

    // Define some styles
    final titleStyle = pw.TextStyle(
        fontSize: 20, fontWeight: pw.FontWeight.bold);
    final headingStyle = pw.TextStyle(
        fontSize: 16, fontWeight: pw.FontWeight.bold);
    final detailStyle = const pw.TextStyle(fontSize: 12);

    // Load the logo image as bytes
    Uint8List? logoBytes;
    try {
      final ByteData data = await rootBundle.load('assets/images/logob.png');
      logoBytes = data.buffer.asUint8List();
    } catch (e) {
      print('Error loading logo: $e');
      logoBytes = null;
    }

    // Build PDF content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (logoBytes != null)
                        pw.Image(pw.MemoryImage(logoBytes!), width: 150),
                      pw.Text('Prescription', style: titleStyle),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // Doctor Information
                pw.Text('Doctor Information', style: headingStyle),
                pw.Text('Doctor: ${consultation.doctorName ?? "N/A"}',
                    style: detailStyle),
                pw.Text('Date: ${consultation.consultationDate != null
                    ? DateFormat('dd MMM yyyy hh:mm a').format(
                    DateFormat('dd-MMM-yyyy hh:mm:ss a', 'en_US')
                        .parse(consultation.consultationDate!))
                    : "N/A"}', style: detailStyle),
                pw.SizedBox(height: 10),

                // Patient Information
                pw.Text('Patient Information', style: headingStyle),
                pw.Text('Complaint: ${consultation.complaint ?? "N/A"}',
                    style: detailStyle),
                pw.Text('Diagnosis: ${consultation.diagnosis ?? "N/A"}',
                    style: detailStyle),
                pw.Text('Tests: ${consultation.tests ?? "N/A"}',
                    style: detailStyle),
                pw.SizedBox(height: 10),

                // Remarks
                pw.Text('Remarks', style: headingStyle),
                pw.Text(consultation.remarks ?? "N/A", style: detailStyle),

                pw.SizedBox(height: 10),

                // Medicines
                pw.Text('Medicines', style: headingStyle),
                if (consultation.consultationdetails != null &&
                    consultation.consultationdetails!.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: consultation.consultationdetails!.map((detail) =>
                        pw.Text('${detail.medicineName ?? "N/A"} - ${detail
                            .additionalNotes ?? "N/A"}', style: detailStyle)
                    ).toList(),
                  )
                else
                  pw.Text('No medicines prescribed.', style: detailStyle),
              ],
            ),
          );
        },
      ),
    );

    try {
      // 1. Get the temporary directory
      final tempDir = await getTemporaryDirectory();
      String formattedDate = "N_A"; // Default value if date is null
      if (consultation.consultationDate != null) {
        try {
          final consultationDateTime = DateFormat(
              'dd-MMM-yyyy hh:mm:ss a', 'en_US').parse(
              consultation.consultationDate!);
          formattedDate =
              DateFormat('dd-MMM-yyyy_hhmm').format(consultationDateTime);
        } catch (e) {
          print('Error formatting date: $e');
          formattedDate = "invalid_date"; // Handle invalid date format
        }
      }
      final String fileName = 'prescription_$formattedDate.pdf';
      final String filePath = '${tempDir.path}/$fileName';
      final File file = File(filePath);

      // 2. Write the PDF data to the file
      await file.writeAsBytes(await pdf.save());

      // 3. Determine the MIME type
      String? mimeType = lookupMimeType(filePath);
      if (mimeType == null) {
        // If lookupMimeType fails, default to 'application/pdf'
        mimeType = 'application/pdf';
        print(
            'MIME type could not be determined, defaulting to application/pdf');
      } else {
        print(
            'MIME Type: $mimeType'); // Print the detected MIME type for debugging
      }

      // 4. Create the XFile with the determined MIME type
      final xFile = XFile(filePath, mimeType: mimeType);

      // 5. Share only the XFile
      await Share.shareXFiles([xFile]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Prescription generated. Use the share sheet to save or share it.')),
      );
    } catch (e) {
      print('Error saving/sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving/sharing PDF: $e')),
      );
    }
  }


  Future<void> _downloadPdf(BuildContext context, Consultation consultation) async {
    try {
      final pdf = pw.Document();

      // Load logo
      Uint8List? logoBytes;
      try {
        final ByteData data = await rootBundle.load('assets/images/logob.png');
        logoBytes = data.buffer.asUint8List();
      } catch (e) {
        print('Error loading logo: $e');
      }

      final titleStyle = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
      final headingStyle = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
      final detailStyle = const pw.TextStyle(fontSize: 12);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Column(
                      children: [
                        if (logoBytes != null)
                          pw.Image(pw.MemoryImage(logoBytes), width: 150),
                        pw.Text('Prescription', style: titleStyle),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('Doctor Information', style: headingStyle),
                  pw.Text('Doctor: ${consultation.doctorName ?? "N/A"}', style: detailStyle),
                  pw.Text(
                      'Date: ${consultation.consultationDate != null
                          ? DateFormat('dd MMM yyyy hh:mm a').format(
                          DateFormat('dd-MMM-yyyy hh:mm:ss a', 'en_US')
                              .parse(consultation.consultationDate!))
                          : "N/A"}',
                      style: detailStyle),
                  pw.SizedBox(height: 10),
                  pw.Text('Patient Information', style: headingStyle),
                  pw.Text('Complaint: ${consultation.complaint ?? "N/A"}', style: detailStyle),
                  pw.Text('Diagnosis: ${consultation.diagnosis ?? "N/A"}', style: detailStyle),
                  pw.Text('Tests: ${consultation.tests ?? "N/A"}', style: detailStyle),
                  pw.SizedBox(height: 10),
                  pw.Text('Remarks', style: headingStyle),
                  pw.Text(consultation.remarks ?? "N/A", style: detailStyle),
                  pw.SizedBox(height: 10),
                  pw.Text('Medicines', style: headingStyle),
                  if (consultation.consultationdetails != null &&
                      consultation.consultationdetails!.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: consultation.consultationdetails!.map(
                            (detail) => pw.Text(
                          '${detail.medicineName ?? "N/A"} - ${detail.additionalNotes ?? "N/A"}',
                          style: detailStyle,
                        ),
                      ).toList(),
                    )
                  else
                    pw.Text('No medicines prescribed.', style: detailStyle),
                ],
              ),
            );
          },
        ),
      );

      // Save to Downloads directory using MediaStore API for Android 10+ (API 29+)
      String? savedPath;
      String formattedDate = "N_A";
      if (consultation.consultationDate != null) {
        try {
          final consultationDateTime = DateFormat('dd-MMM-yyyy hh:mm:ss a', 'en_US')
              .parse(consultation.consultationDate!);
          formattedDate = DateFormat('dd-MMM-yyyy_hhmm').format(consultationDateTime);
        } catch (e) {
          print('Error formatting date: $e');
          formattedDate = "invalid_date";
        }
      }
      final fileName = 'prescription_$formattedDate.pdf';

      if (Platform.isAndroid) {
        // For Android 10+ (API 29+), use MediaStore via FlutterFileDialog
        final params = SaveFileDialogParams(
          fileName: fileName,
          data: await pdf.save(),
        );
        savedPath = await FlutterFileDialog.saveFile(params: params);
      } else if (Platform.isIOS) {
        // For iOS, save to app documents directory
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(dir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        savedPath = filePath;
      } else {
        // Fallback for other platforms
        final dir = await getDownloadsDirectory();
        if (dir != null) {
          final filePath = p.join(dir.path, fileName);
          final file = File(filePath);
          await file.writeAsBytes(await pdf.save());
          savedPath = filePath;
        }
      }

      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescription downloaded successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF not saved. User cancelled or permission denied.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF: $e')),
      );
    }
  }
}


// Make sure this ExpandableText is consistent with your project structure.
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableText({Key? key, required this.text, this.maxLines = 3})
      : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: ConstrainedBox(
            constraints: isExpanded
                ? const BoxConstraints()
                : BoxConstraints(maxHeight: 75.0), // Adjust the maxHeight
            child: Text(
              widget.text,
              style: AppStyles.bodyMedium(context)
                  .copyWith(color: AppColors.secondaryTextColor),
              softWrap: true,
              overflow: TextOverflow.fade,
              maxLines: isExpanded ? null : widget.maxLines,
            ),
          ),
        ),
        if (widget.text.length > 70) // Or a suitable character count
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Text(
              isExpanded ? 'Read Less' : 'Read More',
              style: AppStyles.bodyMedium(context).copyWith(
                  color: AppColors.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}



/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/specialist_prescription_item.dart';
import '../models/specialist_prescription_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';



class SpecialistPrescriptionDetailScreen extends StatefulWidget {
  final String consultationId;

  const SpecialistPrescriptionDetailScreen({Key? key, required this.consultationId})
      : super(key: key);

  @override
  _SpecialistPrescriptionDetailScreenState createState() =>
      _SpecialistPrescriptionDetailScreenState();
}

class _SpecialistPrescriptionDetailScreenState
    extends State<SpecialistPrescriptionDetailScreen> {
  SpecialistPrescriptionResponse? _prescriptionResponse;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPrescriptionData();
  }

  Future<void> _fetchPrescriptionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Construct the URL with the consultation_id as a query parameter
    final String url =
        'https://webdocsite.webddocsystems.com/public/api/v1/prescription/view?consultation_id=${widget.consultationId}';

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
      'Cookie': 'ci_session=rlvi7sqhnih4jcgqv8di1m1uftdr6b22', // Replace with the actual session id
    };

    try {
      final response = await http.get(
        Uri.parse(url), // Use the constructed URL
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        print('API Response: ${response.body}');
        setState(() {
          _prescriptionResponse =
              SpecialistPrescriptionResponse.fromJson(decodedResponse);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
          'Failed to load prescription data. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred while fetching data: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 16),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Prescription",
          style: AppStyles.bodyLarge(context).copyWith(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primaryColor),
      ));
    } else if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_prescriptionResponse == null ||
        _prescriptionResponse!.payLoad == null) {
      return const Center(
          child: Text('No prescription data available.')); // or display a message
    } else {
      return _buildPrescriptionDetails(_prescriptionResponse!.payLoad!);
    }
  }

  Widget _buildPrescriptionDetails(Consultation consultation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDoctorHeader(context, consultation),
          const SizedBox(height: 24),
          _buildDiagnosticSection(consultation),
          const SizedBox(height: 24),
          Text('Medicines:',
              style: AppStyles.titleMedium(context)
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (consultation.consultationdetails != null &&
              consultation.consultationdetails!.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: consultation.consultationdetails!.length,
              itemBuilder: (context, index) {
                final detail = consultation.consultationdetails![index];
                return SpecialistPrescriptionItem(detail: detail); // Changed here!
              },
            )
          else
            const Text('No medicines prescribed.',
                style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader(BuildContext context, Consultation consultation) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
              Icons.local_hospital, size: 40, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consultation.doctorName ?? "N/A",
                    style: AppStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold)),
                Text(
                  'Date: ${consultation.consultationDate != null
                      ? DateFormat('dd MMM yyyy hh:mm a').format( // Format for display
                      DateFormat('dd-MMM-yyyy hh:mm:ss a', 'en_US') // Correct parsing format
                          .parse(consultation.consultationDate!))
                      : "N/A"}',
                  style: AppStyles.bodySmall(context)
                      .copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          // IconButton(
          //   icon: Image.asset(
          //     'assets/images/download.png',
          //     width: 30,
          //     height: 30,
          //   ),
          //   onPressed: () {
          //     // Implement download PDF functionality
          //   },
          // ),
          // IconButton(
          //   icon: Image.asset(
          //     'assets/images/share.png',
          //     width: 30,
          //     height: 30,
          //   ),
          //   onPressed: () {
          //     // Implement share functionality
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection(Consultation consultation) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDiagnosticRow(
                    context, 'Complaint:', consultation.complaint ?? "N/A"),
                _buildDiagnosticRow(
                    context, 'Diagnosis:', consultation.diagnosis ?? "N/A"),
                _buildDiagnosticRow(context, 'Tests:', consultation.tests ?? "N/A"),
                if (consultation.remarks != null &&
                    consultation.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Remarks:',
                    style: AppStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.bold),
                  ),
                  ExpandableText(text: consultation.remarks!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagnosticRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.bold)),
          Text(value,
              style: AppStyles.bodyMedium(context)
                  .copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Make sure this ExpandableText is consistent with your project structure.
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableText({Key? key, required this.text, this.maxLines = 3})
      : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: ConstrainedBox(
            constraints: isExpanded
                ? const BoxConstraints()
                : BoxConstraints(maxHeight: 75.0), // Adjust the maxHeight
            child: Text(
              widget.text,
              style: AppStyles.bodyMedium(context)
                  .copyWith(color: AppColors.secondaryTextColor),
              softWrap: true,
              overflow: TextOverflow.fade,
              maxLines: isExpanded ? null : widget.maxLines,
            ),
          ),
        ),
        if (widget.text.length > 70) // Or a suitable character count
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Text(
              isExpanded ? 'Read Less' : 'Read More',
              style: AppStyles.bodyMedium(context).copyWith(
                  color: AppColors.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}*/
