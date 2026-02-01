import 'package:flutter/material.dart';

import '../../core/constants/prefs_cache.dart';
import '../../services/doctor_list_api.dart';
import '../../services/doctor_requests_api.dart';

class DoctorSelectionPage extends StatefulWidget {
  final int scanId;
  final String pdfUrl;

  const DoctorSelectionPage({
    super.key,
    required this.scanId,
    required this.pdfUrl,
  });

  @override
  _DoctorSelectionPageState createState() => _DoctorSelectionPageState();
}

class _DoctorSelectionPageState extends State<DoctorSelectionPage> {
  List doctors = [];
  bool loading = true;

  int? _requestingDoctorId;
  bool _touchEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _touchEnabled = true);
      });
    });
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  String _statusOf(Map doc) {
    final raw = doc["relationship_status"] ?? "NONE";
    return raw.toString().toUpperCase();
  }

  bool _isDisabledStatus(String status) {
    return status == "PENDING" || status == "ACTIVE";
  }

  String _buttonTextForStatus(String status) {
    if (status == "ACTIVE") return "Linked";
    if (status == "PENDING") return "Requested";
    if (status == "REJECTED") return "Request Again";
    return "Request";
  }

  Future<void> _loadDoctors() async {
    final data = await DoctorListApi.getDoctors();

    if (!mounted) return;
    setState(() {
      doctors = data;
      loading = false;
    });
  }

  Future<void> _requestDoctor(int doctorId, String doctorName) async {
    if (_requestingDoctorId != null) return;

    final prefs = await PrefsCache.getInstance();
    final token = prefs.getString("token");
    if (token == null || token.isEmpty) return;

    setState(() => _requestingDoctorId = doctorId);

    try {
      final result = await DoctorRequestsApi.requestDoctorWithStatus(
        token,
        doctorId: doctorId,
      );

      if (!mounted) return;

      final ok = result["success"] == true;
      final status = (result["status"] ?? "").toString().toUpperCase();
      final detail = (result["detail"] ?? result["error"] ?? "").toString();

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(detail.isNotEmpty ? detail : "Request failed"),
          ),
        );
        return;
      }

      // ✅ Update local list so button greys out immediately
      final idx = doctors.indexWhere(
        (d) => _safeInt((d as Map)["id"]) == doctorId,
      );
      if (idx != -1) {
        final Map updated = Map<String, dynamic>.from(doctors[idx] as Map);
        updated["relationship_status"] = status.isNotEmpty ? status : "PENDING";
        doctors[idx] = updated;
        setState(() {});
      }

      String msg;
      if (status == "ACTIVE") {
        msg = "You are already linked with Dr. $doctorName ✅";
      } else if (status == "PENDING") {
        msg = "Request pending for Dr. $doctorName ⏳";
      } else {
        msg = "Request sent to Dr. $doctorName ⏳";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _requestingDoctorId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool absorbInitialTouches = !_touchEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text("Select Doctor")),
      body: AbsorbPointer(
        absorbing: absorbInitialTouches,
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (_, index) {
                    final doc = doctors[index] as Map;
                    final int doctorId = _safeInt(doc["id"]);
                    final String doctorName =
                        (doc["full_name"] ?? "Doctor").toString();

                    final status = _statusOf(doc);
                    final disabled = _isDisabledStatus(status);
                    final btnText = _buttonTextForStatus(status);

                    final bool isThisRequesting =
                        _requestingDoctorId == doctorId;

                    return ListTile(
                      title: Text(doctorName),
                      subtitle: Text((doc["email"] ?? "").toString()),
                      trailing: ElevatedButton(
                        onPressed:
                            (!_touchEnabled ||
                                    doctorId == 0 ||
                                    disabled ||
                                    _requestingDoctorId != null)
                                ? null
                                : () => _requestDoctor(doctorId, doctorName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              disabled ? Colors.grey.shade400 : null,
                        ),
                        child:
                            isThisRequesting
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(btnText),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
