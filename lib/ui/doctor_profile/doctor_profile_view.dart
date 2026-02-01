import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/theme_provider.dart';
import '../../services/doctor_profile_api.dart';

class DoctorProfileView extends StatefulWidget {
  const DoctorProfileView({super.key});

  @override
  State<DoctorProfileView> createState() => _DoctorProfileViewState();
}

// ... keep your imports and class structure unchanged ...

class _DoctorProfileViewState extends State<DoctorProfileView> {
  bool loading = true;
  Map<String, dynamic>? doctor;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        if (mounted) context.go('/login');
        return;
      }

      final result = await DoctorProfileApi.getProfile(token);
      print("DOCTOR PROFILE RESPONSE (normalized): $result");

      if (!mounted) return;

      setState(() {
        if (result["success"] == true && result["data"] != null) {
          try {
            doctor = Map<String, dynamic>.from(result["data"] as Map);
          } catch (e) {
            print("Error parsing doctor data: $e");
            doctor = null;
          }
        } else {
          doctor = null;
          print("Failed to load doctor profile: ${result["error"]}");
        }
        loading = false;
      });
    } catch (e, stackTrace) {
      print("Error in _loadDoctor: $e");
      print("Stack trace: $stackTrace");
      if (!mounted) return;
      setState(() {
        doctor = null;
        loading = false;
      });
    }
  }

  Widget infoTile(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              value?.toString() ?? "N/A",
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String formatGender(dynamic g) {
    if (g == null) return "N/A";
    final v = g.toString().toUpperCase();
    switch (v) {
      case "M":
      case "MALE":
        return "Male";
      case "F":
      case "FEMALE":
        return "Female";
      case "O":
      case "OTHER":
        return "Other";
      default:
        return "N/A";
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return "N/A";
    try {
      final dateStr = date.toString();
      if (dateStr.isEmpty || dateStr == "null") return "N/A";
      return dateStr;
    } catch (e) {
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Doctor Profile"),
          backgroundColor: const Color(0xFF20BCD0),
        ),
        body: const Center(child: Text("Unable to load doctor profile.")),
      );
    }

    final fullName = (doctor!["full_name"] ?? "").toString();
    final avatarLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : "?";

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Doctor Profile"),
        backgroundColor: const Color(0xFF20BCD0),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/doctor-home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await context.push(
                '/doctor-profile/edit',
                extra: doctor,
              );
              if (updated == true) {
                _loadDoctor();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.teal.shade200,
              child: Text(
                avatarLetter,
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              fullName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              (doctor!["specialization"] ?? "No specialization").toString(),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            infoTile("Email", doctor!["email"]),
            infoTile("Gender", formatGender(doctor!["gender"])),
            infoTile("Phone Number", doctor!["phone_number"]),
            infoTile("Clinic Phone", doctor!["clinic_phone_number"]),
            infoTile("Clinic Address", doctor!["clinic_address"]),
            infoTile("Certifications", doctor!["certifications"]),
          ],
        ),
      ),
    );
  }
}
