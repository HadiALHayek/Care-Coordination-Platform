import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/doctor_patient_profile_api.dart';

class DoctorPatientProfileView extends StatefulWidget {
  final int patientId;

  const DoctorPatientProfileView({super.key, required this.patientId});

  @override
  State<DoctorPatientProfileView> createState() =>
      _DoctorPatientProfileViewState();
}

class _DoctorPatientProfileViewState extends State<DoctorPatientProfileView> {
  bool loading = true;
  Map<String, dynamic>? patient;
  Map<String, dynamic>? lastScan;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return;

    final result = await DoctorPatientProfileApi.getPatientProfile(
      widget.patientId,
      token,
    );

    if (!mounted) return;

    if (result["success"]) {
      final data = result["data"];
      setState(() {
        patient = data;
        print("🔥 PATIENT JSON = $patient"); // <-- ADD THIS
        print("🔥 LAST SCAN JSON = $lastScan"); // <-- ADD THIS
        lastScan = data["last_scan"];

        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Map<String, dynamic>? _normalizeScan() {
    if (lastScan == null || patient == null) return null;

    return {
      "id": lastScan!["scan_id"],
      "scan_type": lastScan!["scan_type"],
      "ai_result": lastScan!["ai_result"],
      "scan_date": lastScan!["scan_date"],
      "pdf_url": lastScan!["pdf_url"], // required for PDF viewer
      // needed for chat
      "patient_id": patient!["id"],
      "patient_name": patient!["full_name"],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Profile"),
        backgroundColor: const Color(0xFF20BCD0),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/doctor-patients'),
        ),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : patient == null
              ? const Center(
                child: Text(
                  "Patient not found.",
                  style: TextStyle(fontSize: 18),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    Text(
                      patient!["full_name"],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // EMAIL
                    Text(
                      "Email: ${patient!["email"]}",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),

                    // LAST SCAN TITLE
                    const Text(
                      "Last Scan:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    lastScan == null
                        ? const Text(
                          "No scan data available.",
                          style: TextStyle(fontSize: 16),
                        )
                        : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Scan Type: ${lastScan!["scan_type"]}"),
                              Text("AI Result: ${lastScan!["ai_result"]}"),
                              Text("Scan ID: ${lastScan!["scan_id"]}"),
                              Text("Date: ${lastScan!["scan_date"]}"),
                              const SizedBox(height: 15),

                              // OPEN SCAN
                              ElevatedButton(
                                onPressed: () {
                                  final normalizedScan = _normalizeScan();

                                  if (normalizedScan == null ||
                                      normalizedScan["pdf_url"] == null ||
                                      normalizedScan["pdf_url"]
                                          .toString()
                                          .isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "No PDF available for this scan",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  context.push(
                                    '/scan-details',
                                    extra: normalizedScan,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF20BCD0),
                                  minimumSize: Size(double.infinity, 48),
                                ),
                                child: const Text(
                                  "Open Scan",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // CHAT WITH PATIENT — ADDED HERE
                              // inside DoctorPatientProfileView, in the Chat button:
                              ElevatedButton(
                                onPressed: () {
                                  context.push(
                                    '/chat',
                                    extra: {
                                      "recipientId": patient!["patient_id"],
                                      // <-- THIS WORKS
                                      "recipientName": patient!["full_name"],
                                      // works
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  minimumSize: Size(double.infinity, 48),
                                ),
                                child: const Text(
                                  "Chat With Patient",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
    );
  }
}
