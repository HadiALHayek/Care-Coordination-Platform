import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/doctor_profile_api.dart';

class DoctorEditProfileView extends StatefulWidget {
  final Map<String, dynamic> initialDoctor;

  const DoctorEditProfileView({super.key, required this.initialDoctor});

  @override
  State<DoctorEditProfileView> createState() => _DoctorEditProfileViewState();
}

class _DoctorEditProfileViewState extends State<DoctorEditProfileView> {
  late final TextEditingController fullNameC;
  late final TextEditingController emailC;
  late final TextEditingController specializationC;
  late final TextEditingController phoneC;
  late final TextEditingController clinicPhoneC;
  late final TextEditingController clinicAddressC;
  late final TextEditingController certificationsC;

  String? genderCode; // "M" / "F" / "O"
  DateTime? dob;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDoctor;

    fullNameC = TextEditingController(text: d["full_name"] ?? "");
    emailC = TextEditingController(text: d["email"] ?? "");
    specializationC = TextEditingController(text: d["specialization"] ?? "");
    phoneC = TextEditingController(text: d["phone_number"] ?? "");
    clinicPhoneC = TextEditingController(text: d["clinic_phone_number"] ?? "");
    clinicAddressC = TextEditingController(text: d["clinic_address"] ?? "");
    certificationsC = TextEditingController(text: d["certifications"] ?? "");

    genderCode = d["gender"]; // expects "M"/"F"/"O"/null

    final dobStr = d["date_of_birth"];
    if (dobStr is String && dobStr.isNotEmpty) {
      try {
        dob = DateTime.parse(dobStr);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    fullNameC.dispose();
    emailC.dispose();
    specializationC.dispose();
    phoneC.dispose();
    clinicPhoneC.dispose();
    clinicAddressC.dispose();
    certificationsC.dispose();
    super.dispose();
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked != null) setState(() => dob = picked);
  }

  String? dobToString() {
    if (dob == null) return null;
    final y = dob!.year.toString().padLeft(4, '0');
    final m = dob!.month.toString().padLeft(2, '0');
    final d = dob!.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  Future<void> save() async {
    setState(() => saving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    final body = {
      "full_name": fullNameC.text.trim(),
      "email": emailC.text.trim(),
      "specialization": specializationC.text.trim(),
      "gender": genderCode, // ✅ MUST be M/F/O (max_length=1)
      "date_of_birth": dobToString(),
      "phone_number": phoneC.text.trim(),
      "clinic_phone_number": clinicPhoneC.text.trim(),
      "clinic_address": clinicAddressC.text.trim(),
      "certifications": certificationsC.text.trim(),
    };

    final res = await DoctorProfileApi.updateProfile(token, body);

    if (!mounted) return;
    setState(() => saving = false);

    if (res["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));
      context.pop(true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: ${res["error"]}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF20BCD0),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: fullNameC,
            decoration: const InputDecoration(labelText: "Full Name"),
          ),
          TextField(
            controller: emailC,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: specializationC,
            decoration: const InputDecoration(labelText: "Specialization"),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: genderCode,
            decoration: const InputDecoration(labelText: "Gender"),
            items: const [
              DropdownMenuItem(value: "M", child: Text("Male")),
              DropdownMenuItem(value: "F", child: Text("Female")),
              DropdownMenuItem(value: "O", child: Text("Other")),
            ],
            onChanged: (v) => setState(() => genderCode = v),
          ),

          const SizedBox(height: 12),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Date of Birth"),
            subtitle: Text(dobToString() ?? "Not set"),
            trailing: IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: pickDob,
            ),
          ),

          TextField(
            controller: phoneC,
            decoration: const InputDecoration(labelText: "Phone Number"),
          ),
          TextField(
            controller: clinicPhoneC,
            decoration: const InputDecoration(labelText: "Clinic Phone Number"),
          ),
          TextField(
            controller: clinicAddressC,
            decoration: const InputDecoration(labelText: "Clinic Address"),
          ),
          TextField(
            controller: certificationsC,
            decoration: const InputDecoration(labelText: "Certifications"),
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: saving ? null : save,
            child:
                saving ? const CircularProgressIndicator() : const Text("Save"),
          ),
        ],
      ),
    );
  }
}
