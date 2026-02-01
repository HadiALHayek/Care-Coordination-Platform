import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;

  const PdfViewerPage({super.key, required this.pdfUrl});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  bool loading = true;
  String? errorMessage;

  late PdfControllerPinch pdfController;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = "Failed to load PDF (${response.statusCode})";
          loading = false;
        });
        return;
      }

      final bytes = response.bodyBytes;

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/report.pdf");
      await file.writeAsBytes(bytes, flush: true);

      setState(() {
        localPath = file.path;
        loading = false;
      });

      pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(localPath!),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error loading PDF: $e";
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    if (localPath != null) {
      pdfController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Report")),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
              : PdfViewPinch(controller: pdfController),
    );
  }
}
