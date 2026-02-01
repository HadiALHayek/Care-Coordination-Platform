import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/image_picker_cache.dart';
import '../../core/constants/language_provider.dart';
import '../../core/constants/prefs_cache.dart';
import '../../services/breast_mri_scan_api.dart';
import '../../services/profile_api.dart'; // ✅ ADD

class BreastView extends StatefulWidget {
  const BreastView({super.key});

  @override
  State<BreastView> createState() => _BreastViewState();
}

class _BreastViewState extends State<BreastView> {
  File? _imageFile;
  bool _uploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePickerCache.instance.pickImage(
      source: source,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Take a photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Choose from gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // ✅ NEW: check if patient already has an ACTIVE doctor
  Future<bool> _hasActiveDoctor(String token) async {
    try {
      final res = await ProfileApi.getProfile(token);
      if (res["success"] == true) {
        final data = res["data"];
        final active = (data is Map) ? data["active_doctors"] : null;
        if (active is List && active.isNotEmpty) return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _uploadScan() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload an MRI scan first")),
      );
      return;
    }

    setState(() => _uploading = true);

    final prefs = await PrefsCache.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login again.")));
      if (mounted) context.go('/login');
      return;
    }

    final result = await BreastMammoScanApi.uploadBreastScan(
      imageFile: _imageFile!,
      token: token,
    );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (result["success"] == true) {
      final data = result["data"];

      final aiRaw = (data["ai_result"] ?? data["ai_label"] ?? "").toString();
      final ai = aiRaw.toLowerCase();

      final isNegative = ai.contains("benign") || ai.contains("false");

      final scanId = data["scan_id"];
      final pdfUrl = (data["pdf_url"] ?? "").toString();
      if (pdfUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF report not available")),
        );
      }

      // save latest scan info
      if (scanId != null) prefs.setInt("last_scan_id", scanId);
      prefs.setString("last_scan_pdf", pdfUrl);

      if (isNegative) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No tumor detected ✅")));
        if (mounted) context.go('/home');
        return;
      }

      final isPositiveOrNeedsReview =
          ai.contains("malignant") ||
          ai.contains("needs_review") ||
          ai.contains("true");

      final bool alreadyHasDoctor = await _hasActiveDoctor(token);

      final bool needsDoctorSelection =
          isPositiveOrNeedsReview && !alreadyHasDoctor;

      if (needsDoctorSelection) {
        if (mounted) context.go('/doctor-list');
        return;
      }

      if (mounted) context.go('/home');
      return;
    }

    // error
    final errorMsg =
        result["message"] ??
        result["error"]?.toString() ??
        "Unknown error occurred";
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error: $errorMsg")));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    final title = lang == 'English' ? 'Breast Scan' : 'فحص الدماغ';
    final instruction =
        lang == 'English'
            ? "Please upload your Breast Mammogram scan for AI analysis."
            : "يرجى رفع صورة الرنين المغناطيسي للدماغ لتحليل الذكاء الاصطناعي.";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF20BCD0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    _imageFile != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                        : const Center(
                          child: Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _uploading ? null : _uploadScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20BCD0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _uploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        lang == 'English' ? "Upload Scan" : "رفع الفحص",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
