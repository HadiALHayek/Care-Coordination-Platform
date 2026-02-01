import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/prefs_cache.dart';
import '../../services/doctor_list_api.dart';
import '../../services/doctor_requests_api.dart';

class DoctorListView extends StatefulWidget {
  const DoctorListView({super.key});

  @override
  State<DoctorListView> createState() => _DoctorListViewState();
}

class _DoctorListViewState extends State<DoctorListView> {
  List doctors = [];
  bool loading = true;

  // show spinner only for the pressed doctor
  int? _requestingDoctorId;

  // tap-through protection
  bool _touchEnabled = false;

  // ✅ Governorate filter
  String? _selectedGovernorate;

  // ✅ Syria governorates list (edit labels if you prefer Arabic)
  final List<String> _syriaGovernorates = const [
    "Damascus",
    "Rif Dimashq",
    "Aleppo",
    "Homs",
    "Hama",
    "Latakia",
    "Tartus",
    "Idlib",
    "Deir ez-Zor",
    "Raqqa",
    "Al-Hasakah",
    "Daraa",
    "As-Suwayda",
    "Quneitra",
  ];

  @override
  void initState() {
    super.initState();
    loadDoctors();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _touchEnabled = true);
      });
    });
  }

  Future<void> loadDoctors() async {
    if (!mounted) return;
    setState(() => loading = true);

    // ✅ pass governorate to API (null = all)
    final list = await DoctorListApi.getDoctors(
      governorate: _selectedGovernorate,
    );

    if (!mounted) return;
    setState(() {
      doctors = list;
      loading = false;
    });
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _relationshipStatus(Map<String, dynamic> doc) {
    final raw = doc["relationship_status"] ?? "NONE";
    return raw.toString().toUpperCase();
  }

  bool _disableRequestButton(String status) {
    return status == "PENDING" || status == "ACTIVE";
  }

  String _buttonText(String status) {
    if (status == "ACTIVE") return "Linked";
    if (status == "PENDING") return "Requested";
    if (status == "REJECTED") return "Request Again";
    return "Request";
  }

  Future<void> selectDoctor(int doctorId) async {
    if (_requestingDoctorId != null) return;
    if (doctorId == 0) {
      _showSnack("Invalid doctor id");
      return;
    }

    // find doctor (safe)
    Map<String, dynamic> doctor = {};
    for (final d in doctors) {
      if (d is Map) {
        final id = _safeInt(d["id"]);
        if (id == doctorId) {
          doctor = Map<String, dynamic>.from(d);
          break;
        }
      }
    }

    final doctorName = (doctor["full_name"] ?? "Doctor").toString();

    final prefs = await PrefsCache.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    setState(() => _requestingDoctorId = doctorId);

    try {
      final result = await DoctorRequestsApi.requestDoctorWithStatus(
        token,
        doctorId: doctorId,
      );

      if (!mounted) return;

      final bool ok = result["success"] == true;
      final String status = (result["status"] ?? "").toString().toUpperCase();
      final String detail =
          (result["detail"] ?? result["error"] ?? "").toString();

      if (!ok) {
        _showSnack(detail.isNotEmpty ? detail : "Request failed");
        return;
      }

      // ✅ update local list so button becomes shady immediately
      final idx = doctors.indexWhere(
        (d) => d is Map && _safeInt(d["id"]) == doctorId,
      );
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(doctors[idx] as Map);
        updated["relationship_status"] = status.isNotEmpty ? status : "PENDING";
        doctors[idx] = updated;
        setState(() {});
      }

      // message
      if (status == "ACTIVE") {
        _showSnack("You are already linked with Dr. $doctorName ✅");
      } else if (status == "PENDING") {
        _showSnack("Request pending for Dr. $doctorName ⏳");
      } else if (status == "REJECTED") {
        _showSnack("Request re-sent to Dr. $doctorName ⏳");
      } else {
        _showSnack("Request sent to Dr. $doctorName ⏳");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _requestingDoctorId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool absorbInitialTouches = !_touchEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose a Doctor"),
        backgroundColor: const Color(0xFF20BCD0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/brain'),
        ),
      ),
      body: AbsorbPointer(
        absorbing: absorbInitialTouches,
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // ✅ Filter UI
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGovernorate,
                              decoration: const InputDecoration(
                                labelText: "Governorate",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text("All governorates"),
                                ),
                                ..._syriaGovernorates.map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                ),
                              ],
                              onChanged:
                                  (!_touchEnabled ||
                                          _requestingDoctorId != null)
                                      ? null
                                      : (value) async {
                                        setState(
                                          () => _selectedGovernorate = value,
                                        );
                                        await loadDoctors();
                                      },
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed:
                                (!_touchEnabled || _requestingDoctorId != null)
                                    ? null
                                    : () async {
                                      setState(
                                        () => _selectedGovernorate = null,
                                      );
                                      await loadDoctors();
                                    },
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                    ),

                    // ✅ List
                    Expanded(
                      child:
                          doctors.isEmpty
                              ? const Center(child: Text("No doctors found"))
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: doctors.length,
                                itemBuilder: (context, index) {
                                  final raw = doctors[index];
                                  if (raw is! Map) return const SizedBox();

                                  final doc = Map<String, dynamic>.from(raw);
                                  final int doctorId = _safeInt(doc["id"]);
                                  final String doctorName =
                                      (doc["full_name"] ?? "Unknown")
                                          .toString();
                                  final String email =
                                      (doc["email"] ?? "").toString();

                                  final String status = _relationshipStatus(
                                    doc,
                                  );
                                  final bool disabled = _disableRequestButton(
                                    status,
                                  );
                                  final String btnText = _buttonText(status);

                                  final bool isThisRequesting =
                                      _requestingDoctorId == doctorId;

                                  return Card(
                                    key: ValueKey('doctor_$doctorId'),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.person,
                                        color: Colors.teal,
                                      ),
                                      title: Text(doctorName),
                                      subtitle: Text(email),
                                      trailing: ElevatedButton(
                                        onPressed:
                                            (!_touchEnabled ||
                                                    doctorId == 0 ||
                                                    disabled ||
                                                    _requestingDoctorId != null)
                                                ? null
                                                : () => selectDoctor(doctorId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              disabled
                                                  ? Colors.grey.shade400
                                                  : null,
                                        ),
                                        child:
                                            isThisRequesting
                                                ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                                : Text(btnText),
                                      ),
                                      onTap: null,
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}
