import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/payslip_model.dart';

/// PDF viewer page for payslip with download option
class PayslipPdfViewerPage extends StatefulWidget {
  final PayslipModel payslip;

  const PayslipPdfViewerPage({
    super.key,
    required this.payslip,
  });

  @override
  State<PayslipPdfViewerPage> createState() => _PayslipPdfViewerPageState();
}

class _PayslipPdfViewerPageState extends State<PayslipPdfViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isDownloading = false;
  String? _localPdfPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      // Try to load from cache first
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/payslip_${widget.payslip.id}.pdf');
      
      if (await file.exists()) {
        setState(() {
          _localPdfPath = file.path;
        });
      }
    } catch (e) {
      // If local file doesn't exist, will load from URL
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Download PDF
      final response = await http.get(Uri.parse(widget.payslip.pdfUrl));
      
      if (response.statusCode == 200) {
        // Get application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/payslip_${widget.payslip.id}.pdf');
        
        // Write PDF to file
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          _localPdfPath = file.path;
          _isDownloading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payslip downloaded successfully'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Dark grey header color matching the design
    const headerColor = Color(0xFF424242);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom dark grey header
          Container(
            height: screenHeight * 0.08, // ~8% of screen height
            width: double.infinity,
            color: headerColor,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textWhite,
                    size: screenWidth * 0.05,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: screenWidth * 0.03),
                // Month and Year with purple dotted border
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.008,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF9C27B0), // Purple color
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.payslip.displayName,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                // Download button with purple dotted border
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF9C27B0), // Purple color
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    icon: _isDownloading
                        ? SizedBox(
                            width: screenWidth * 0.05,
                            height: screenWidth * 0.05,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textWhite,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.download,
                            color: AppColors.textWhite,
                            size: screenWidth * 0.05,
                          ),
                    onPressed: _isDownloading ? null : _downloadPdf,
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: _localPdfPath != null
                ? SfPdfViewer.file(
                    File(_localPdfPath!),
                    key: _pdfViewerKey,
                  )
                : SfPdfViewer.network(
                    widget.payslip.pdfUrl,
                    key: _pdfViewerKey,
                  ),
          ),
        ],
      ),
    );
  }
}

