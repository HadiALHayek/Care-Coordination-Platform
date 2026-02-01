import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/image_picker_cache.dart';
import '../../core/constants/language_provider.dart';
import '../../core/constants/prefs_cache.dart';
import '../../services/brain_mri_scan_api.dart';
import '../../services/profile_api.dart'; // ✅ ADD

class BrainView extends StatefulWidget {
  const BrainView({super.key});

  @override
  State<BrainView> createState() => _BrainViewState();
}

class _BrainViewState extends State<BrainView> {
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

    final result = await BrainMriScanApi.uploadBrainScan(
      imageFile: _imageFile!,
      token: token,
    );

    if (!mounted) return;

    setState(() => _uploading = false);
    if (result["success"] == true) {
      final data = result["data"];

      final ai = (data["ai_result"] ?? "").toString().toLowerCase();
      final scanId = data["scan_id"];
      final pdfUrl = (data["pdf_url"] ?? "").toString();

      // ✅ Always save latest scan info
      if (scanId != null) prefs.setInt("last_scan_id", scanId);
      prefs.setString("last_scan_pdf", pdfUrl);

      // ✅ NEW: If negative -> show message and go home
      if (ai.contains("negative")) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("No Tumor Detected")));

        if (mounted) context.go('/home');
        return;
      }

      // ✅ Decide navigation based on ACTIVE doctor existence
      final bool alreadyHasDoctor = await _hasActiveDoctor(token);

      final bool needsDoctorSelection =
          (ai.contains("positive") || ai.contains("needs_review")) &&
          !alreadyHasDoctor;

      if (needsDoctorSelection) {
        // ✅ FIRST TIME only (no active doctor yet)
        if (mounted) context.go('/doctor-list');
        return;
      }

      // ✅ Otherwise: never force doctor list again
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
    final title = lang == 'English' ? 'Brain Scan' : 'فحص الدماغ';
    final instruction =
        lang == 'English'
            ? "Please upload your brain MRI scan for AI analysis."
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
