import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/language_provider.dart';
import '../../core/constants/prefs_cache.dart';
import '../../core/constants/theme_provider.dart';
import '../../services/profile_api.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isEditing = false;
  bool _loading = true;
  String? _token;

  // ✅ NEW: preferred pharmacy
  // ignore: unused_field
  int? _preferredPharmacyId; // Stored for potential future use in profile updates
  String? _preferredPharmacyName;

  // ✅ latest scan + active doctors
  Map<String, dynamic>? _latestScan;
  List<Map<String, dynamic>> _activeDoctors = [];

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();
  final dobController = TextEditingController();
  final weightController = TextEditingController();

  String selectedGender = "M";
  String selectedPrivacy = "LINKED_DOCTORS";
  String selectedLocation = "Damascus";

  final Map<String, Map<String, String>> syriaGovernorates = {
    "Damascus": {"en": "Damascus", "ar": "دمشق"},
    "RifDimashq": {"en": "Rif Dimashq", "ar": "ريف دمشق"},
    "Aleppo": {"en": "Aleppo", "ar": "حلب"},
    "Homs": {"en": "Homs", "ar": "حمص"},
    "Hama": {"en": "Hama", "ar": "حماة"},
    "Latakia": {"en": "Latakia", "ar": "اللاذقية"},
    "Tartus": {"en": "Tartus", "ar": "طرطوس"},
    "Idlib": {"en": "Idlib", "ar": "إدلب"},
    "DeirEzzor": {"en": "Deir ez-Zor", "ar": "دير الزور"},
    "Raqqa": {"en": "Raqqa", "ar": "الرقة"},
    "AlHasakah": {"en": "Al-Hasakah", "ar": "الحسكة"},
    "Daraa": {"en": "Daraa", "ar": "درعا"},
    "AsSweida": {"en": "As-Suwayda", "ar": "السويداء"},
    "Quneitra": {"en": "Quneitra", "ar": "القنيطرة"},
  };

  String tr(BuildContext context, String en, String ar) {
    return context.read<LanguageProvider>().language == "English" ? en : ar;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    emergencyController.dispose();
    dobController.dispose();
    weightController.dispose();
    super.dispose();
  }

  String _fmtDate(dynamic value) {
    if (value == null) return "";
    try {
      final dt = DateTime.tryParse(value.toString());
      if (dt == null) return value.toString();
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return "$y-$m-$d";
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // LOAD PROFILE DATA
  // ============================================================
  Future<void> _loadProfile() async {
    final prefs = await PrefsCache.getInstance();
    _token = prefs.getString("token");

    if (_token == null) {
      if (mounted) context.go('/login');
      return;
    }

    final result = await ProfileApi.getProfile(_token!);

    if (!mounted) return;

    if (result["success"] == true) {
      final data = result["data"];
      final profile =
          (data is Map && data["patient_profile"] is Map)
              ? Map<String, dynamic>.from(data["patient_profile"])
              : <String, dynamic>{};

      final latestScan =
          (data is Map && data["latest_scan"] is Map)
              ? Map<String, dynamic>.from(data["latest_scan"])
              : null;

      final activeDoctors =
          (data is Map && data["active_doctors"] is List)
              ? (data["active_doctors"] as List)
                  .where((e) => e is Map)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[];

      final preferredPharmacyId = int.tryParse(
        profile["preferred_pharmacy_id"]?.toString() ?? "",
      );
      final preferredPharmacyName =
          profile["preferred_pharmacy_name"]?.toString();

      setState(() {
        nameController.text =
            (data is Map ? (data["full_name"] ?? "") : "").toString();
        emailController.text =
            (data is Map ? (data["email"] ?? "") : "").toString();

        phoneController.text = profile["phone_number"]?.toString() ?? "";
        emergencyController.text =
            profile["emergency_contact_number"]?.toString() ?? "";
        dobController.text = profile["date_of_birth"]?.toString() ?? "";
        weightController.text = profile["weight_kg"]?.toString() ?? "";

        selectedGender = (profile["gender"] ?? "M").toString();
        selectedPrivacy =
            (profile["privacy_setting"] ?? "LINKED_DOCTORS").toString();
        selectedLocation = (profile["location"] ?? "Damascus").toString();

        _preferredPharmacyId = preferredPharmacyId;
        _preferredPharmacyName = preferredPharmacyName;

        _latestScan = latestScan;
        _activeDoctors = activeDoctors;

        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, "Failed to load profile", "فشل تحميل الملف الشخصي"),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // SAVE PROFILE CHANGES
  // ============================================================
  Future<void> _saveProfile() async {
    if (_token == null) return;

    final body = {
      "full_name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone_number": phoneController.text.trim(),
      "emergency_contact_number": emergencyController.text.trim(),
      "date_of_birth": dobController.text.trim(),
      "gender": selectedGender,
      "weight_kg": weightController.text.trim(),
      "privacy_setting": selectedPrivacy,
      "location": selectedLocation, // ok if backend ignores
    };

    final result = await ProfileApi.updateProfile(_token!, body);

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, "Profile updated", "تم تحديث الملف الشخصي"),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, "Error updating profile", "خطأ في تحديث الملف الشخصي"),
          ),
        ),
      );
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================
  Future<void> _pickDateOfBirth() async {
    final initialDate = DateTime.tryParse(dobController.text) ?? DateTime(1990);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================
  Widget _sectionCard({required bool isDark, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: child,
    );
  }

  // ✅ NEW: preferred pharmacy section
  Widget _preferredPharmacySection(bool isDark) {
    final name = (_preferredPharmacyName ?? "").trim();
    final text =
        name.isEmpty
            ? tr(
              context,
              "Preferred Pharmacy: not set",
              "الصيدلية المفضلة: غير محددة",
            )
            : tr(
              context,
              "Preferred Pharmacy: $name",
              "الصيدلية المفضلة: $name",
            );

    return _sectionCard(
      isDark: isDark,
      child: Row(
        children: [
          const Icon(Icons.local_pharmacy, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // this route should open PharmacyListView
              final changed = await context.push<bool>('/pharmacies');
              if (changed == true) {
                await _loadProfile();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20BCD0),
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, "Choose", "اختيار")),
          ),
        ],
      ),
    );
  }

  Widget _latestScanSection(bool isDark) {
    final scan = _latestScan;

    if (scan == null) {
      return _sectionCard(
        isDark: isDark,
        child: Row(
          children: [
            const Icon(Icons.biotech, color: Colors.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(context, "Latest Scan: none yet", "آخر فحص: لا يوجد بعد"),
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final scanType = (scan["scan_type"] ?? "").toString();
    final aiResult = (scan["ai_result"] ?? "").toString();
    final status = (scan["status"] ?? "").toString();
    final confidence =
        (scan["ai_confidence"] ?? scan["confidence"] ?? "").toString();
    final date = _fmtDate(scan["scan_date"]);
    final pdfUrl = scan["pdf_url"]?.toString();

    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech, color: Colors.teal),
              const SizedBox(width: 10),
              Text(
                tr(context, "Latest Scan", "آخر فحص"),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$scanType • $aiResult",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Status: $status${confidence.isNotEmpty ? " • Confidence: $confidence" : ""}",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 10),
          if (pdfUrl != null && pdfUrl.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(tr(context, "Open PDF", "فتح PDF")),
                onPressed: () => context.push('/pdf-viewer', extra: pdfUrl),
              ),
            ),
        ],
      ),
    );
  }

  Widget _activeDoctorsSection(bool isDark) {
    if (_activeDoctors.isEmpty) {
      return _sectionCard(
        isDark: isDark,
        child: Row(
          children: [
            const Icon(Icons.medical_services, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(context, "No linked doctors yet", "لا يوجد طبيب مرتبط بعد"),
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: Colors.orange),
              const SizedBox(width: 10),
              Text(
                tr(context, "Linked Doctors", "الأطباء المرتبطون"),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._activeDoctors.map((d) {
            final id = int.tryParse(d["id"]?.toString() ?? "") ?? 0;
            final name = (d["full_name"] ?? "Doctor").toString();
            final email = (d["email"] ?? "").toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        id == 0
                            ? null
                            : () {
                              context.push(
                                "/chat",
                                extra: {
                                  "recipientId": id,
                                  "recipientName": name,
                                },
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20BCD0),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(tr(context, "Chat", "محادثة")),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, bool>(
      selector: (_, provider) => provider.isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: isDark ? Colors.black : AppColors.backgroundColor1,
          appBar: AppBar(
            title: Text(tr(context, "Profile", "الملف الشخصي")),
            backgroundColor: const Color(0xFF20BCD0),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/home'),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.save : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (_isEditing) {
                    await _saveProfile();
                    await _loadProfile();
                  }
                  if (!mounted) return;
                  setState(() => _isEditing = !_isEditing);
                },
              ),
            ],
          ),
          body:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _preferredPharmacySection(isDark), // ✅ NEW
                          _latestScanSection(isDark),
                          _activeDoctorsSection(isDark),

                          _buildField(
                            context,
                            tr(context, "Full Name", "الاسم الكامل"),
                            nameController,
                          ),
                          _buildField(
                            context,
                            tr(context, "Email", "البريد الإلكتروني"),
                            emailController,
                          ),
                          _buildField(
                            context,
                            tr(context, "Phone Number", "رقم الهاتف"),
                            phoneController,
                          ),
                          _buildField(
                            context,
                            tr(context, "Emergency Contact", "رقم الطوارئ"),
                            emergencyController,
                          ),

                          GestureDetector(
                            onTap: _isEditing ? _pickDateOfBirth : null,
                            child: AbsorbPointer(
                              child: _buildField(
                                context,
                                tr(context, "Date of Birth", "تاريخ الميلاد"),
                                dobController,
                              ),
                            ),
                          ),

                          _buildDropdownField(
                            context: context,
                            label: tr(context, "Gender", "الجنس"),
                            value: selectedGender,
                            items: {
                              "M": tr(context, "Male", "ذكر"),
                              "F": tr(context, "Female", "أنثى"),
                              "O": tr(context, "Other", "أخرى"),
                            },
                            onChanged:
                                (v) => setState(() => selectedGender = v!),
                          ),

                          _buildField(
                            context,
                            tr(context, "Weight (kg)", "الوزن (كغ)"),
                            weightController,
                          ),

                          _buildDropdownField(
                            context: context,
                            label: tr(
                              context,
                              "Privacy Setting",
                              "إعدادات الخصوصية",
                            ),
                            value: selectedPrivacy,
                            items: {
                              "PRIVATE": tr(
                                context,
                                "Private (Only You)",
                                "خاص (أنت فقط)",
                              ),
                              "LINKED_DOCTORS": tr(
                                context,
                                "Linked Doctors Only",
                                "الأطباء المرتبطون فقط",
                              ),
                              "ALL_DOCTORS": tr(
                                context,
                                "All Doctors Allowed",
                                "السماح لجميع الأطباء",
                              ),
                            },
                            onChanged:
                                (v) => setState(() => selectedPrivacy = v!),
                          ),

                          _buildDropdownField(
                            context: context,
                            label: tr(context, "Governorate", "المحافظة"),
                            value: selectedLocation,
                            items: {
                              for (var entry in syriaGovernorates.entries)
                                entry.key: tr(
                                  context,
                                  entry.value["en"]!,
                                  entry.value["ar"]!,
                                ),
                            },
                            onChanged:
                                (v) => setState(() => selectedLocation = v!),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  // ============================================================
  // TEXT FIELD COMPONENT
  // ============================================================
  Widget _buildField(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border.all(color: Colors.teal.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  // ============================================================
  // DROPDOWN COMPONENT
  // ============================================================
  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: isDark ? Colors.grey[900] : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.white,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        items:
            items.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: _isEditing ? onChanged : null,
      ),
    );
  }
}
