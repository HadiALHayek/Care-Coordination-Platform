import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/prefs_cache.dart';
import '../../services/doctor_patients_api.dart';
import '../../services/doctor_profile_api.dart';
import '../../services/doctor_requests_api.dart';
import '../../services/doctor_stats_api.dart';

class DoctorHomeView extends StatefulWidget {
  const DoctorHomeView({super.key});

  @override
  State<DoctorHomeView> createState() => _DoctorHomeViewState();
}

class _DoctorHomeViewState extends State<DoctorHomeView> {
  String doctorName = "Doctor";
  int patientCount = 0;
  int pendingScans = 0;
  int completedScans = 0;

  bool loadingHeader = true;
  bool loadingRequests = true;
  bool loadingPatients = true;

  List<Map<String, dynamic>> pendingRequests = [];
  List<Map<String, dynamic>> myPatients = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await PrefsCache.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    if (mounted) {
      setState(() {
        loadingHeader = true;
        loadingRequests = true;
        loadingPatients = true;
      });
    }

    await Future.wait([_loadDoctorProfile(token), _loadStats(token)]);

    if (!mounted) return;
    setState(() => loadingHeader = false);

    await Future.wait([_loadPendingRequests(token), _loadMyPatients(token)]);
  }

  Future<void> _loadDoctorProfile(String token) async {
    final profileResult = await DoctorProfileApi.getProfile(token);

    if (profileResult["success"] == true) {
      final data = profileResult["data"];
      final name =
          (data is Map && data["full_name"] != null)
              ? data["full_name"]
              : "Doctor";

      if (!mounted) return;

      final prefs = await PrefsCache.getInstance();
      final nameString = name.toString();

      setState(() => doctorName = nameString);
      prefs.setString("full_name", nameString);
    }
  }

  Future<void> _loadStats(String token) async {
    final statsResult = await DoctorStatsApi.getStats(token);

    if (statsResult["success"] == true) {
      final stats = statsResult["data"];
      if (stats is Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          patientCount = stats["patient_count"] ?? 0;
          pendingScans = stats["pending_scans"] ?? 0;
          completedScans = stats["completed_scans"] ?? 0;
        });
      }
    }
  }

  Future<void> _loadPendingRequests(String token) async {
    final list = await DoctorRequestsApi.getPending(token);
    if (!mounted) return;
    setState(() {
      pendingRequests = list;
      loadingRequests = false;
    });
  }

  Future<void> _loadMyPatients(String token) async {
    final res = await DoctorPatientsApi.getDoctorPatients(token);

    if (!mounted) return;

    if (res["success"] == true) {
      final data = res["data"];
      setState(() {
        myPatients =
            (data is List)
                ? data.map((e) => Map<String, dynamic>.from(e)).toList()
                : <Map<String, dynamic>>[];
        loadingPatients = false;
      });
    } else {
      setState(() => loadingPatients = false);
    }
  }

  Future<void> _handleRequest({
    required int requestId,
    required int patientId,
    required String patientName,
    required String action, // accept | reject
  }) async {
    final prefs = await PrefsCache.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    // loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await DoctorRequestsApi.handleRequest(
      token,
      requestId: requestId,
      action: action,
    );

    if (mounted) Navigator.of(context).pop();

    if (res["success"] == true) {
      setState(() {
        pendingRequests.removeWhere(
          (e) => (e["request_id"] ?? -1) == requestId,
        );
      });

      if (action == "accept") {
        // ✅ refresh patients list so the accepted patient appears immediately
        await _loadMyPatients(token);

        // ✅ go to chat
        if (!mounted) return;
        context.push(
          "/chat",
          extra: {"recipientId": patientId, "recipientName": patientName},
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update request.")),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await PrefsCache.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_type");
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF20BCD0),
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          tooltip: "Profile",
          icon: const Icon(Icons.account_circle, color: Colors.white),
          onPressed: () => context.go('/doctor-profile'),
        ),
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Settings",
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _headerCard(),
            const SizedBox(height: 14),

            _sectionTitle("Overview"),
            const SizedBox(height: 10),
            loadingHeader ? _statsSkeleton() : _statsGrid(),

            const SizedBox(height: 18),

            // ✅ MY PATIENTS SECTION
            Row(
              children: [
                Expanded(child: _sectionTitle("My Patients")),
                TextButton(
                  onPressed: () => context.go('/doctor-patients'),
                  child: const Text("View all"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (loadingPatients)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (myPatients.isEmpty)
              _emptyState(
                icon: Icons.people_outline,
                title: "No patients yet",
                subtitle: "Accepted patients will appear here.",
              )
            else
              ...myPatients.take(5).map(_patientCard).toList(),

            const SizedBox(height: 18),

            // ✅ PENDING REQUESTS SECTION
            _sectionTitle("Pending Requests"),
            const SizedBox(height: 10),

            if (loadingRequests)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (pendingRequests.isEmpty)
              _emptyState(
                icon: Icons.inbox_outlined,
                title: "No pending requests",
                subtitle: "Patient requests will appear here.",
              )
            else
              ...pendingRequests.map(_requestCard).toList(),
            const SizedBox(height: 19),
          ],
        ),
      ),
    );
  }

  // ===================== UI widgets =====================

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF20BCD0), Color(0xFF1AA7B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(Icons.medical_services, color: Color(0xFF20BCD0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Welcome, $doctorName",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: const Text("Doctor", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.white.withOpacity(0.18),
            side: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1A3C4A),
      ),
    );
  }

  Widget _statsGrid() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _statCard(
            title: "Patients",
            value: patientCount.toString(),
            icon: Icons.people,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _statsSkeleton() {
    final w = (MediaQuery.of(context).size.width - 18 * 2 - 12) / 2;
    Widget box() => Container(
      width: w,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.black12.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
    );

    return Wrap(spacing: 12, runSpacing: 12, children: [box(), box(), box()]);
  }

  // ✅ patient card shown on home
  Widget _patientCard(Map<String, dynamic> patient) {
    final int patientId = patient["patient_id"] ?? 0;
    final String fullName = (patient["full_name"] ?? "Patient").toString();
    final String email = (patient["email"] ?? "").toString();
    final Map<String, dynamic>? lastScan =
        patient["last_scan"] is Map
            ? Map<String, dynamic>.from(patient["last_scan"])
            : null;

    final String lastScanText =
        lastScan == null
            ? "No scans yet"
            : "${lastScan["scan_type"] ?? ""} • ${lastScan["ai_result"] ?? "N/A"}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEAF7F9),
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : "P",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF20BCD0),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A3C4A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(color: Colors.black.withOpacity(0.55)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastScanText,
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20BCD0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: () {
                      context.push(
                        "/chat",
                        extra: {
                          "recipientId": patientId,
                          "recipientName": fullName,
                        },
                      );
                    },
                    child: const Text("Chat"),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: () {
                      context.go("/doctor-patient-profile/$patientId");
                    },
                    child: const Text("Profile"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> r) {
    final requestId = (r["request_id"] ?? 0) as int;
    final patientId = (r["patient_id"] ?? 0) as int;
    final patientName = (r["patient_name"] ?? "Patient").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFEAF7F9),
              child: Icon(Icons.person, color: Color(0xFF20BCD0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A3C4A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Accept"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20BCD0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        () => _handleRequest(
                          requestId: requestId,
                          patientId: patientId,
                          patientName: patientName,
                          action: "accept",
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed:
                        () => _handleRequest(
                          requestId: requestId,
                          patientId: patientId,
                          patientName: patientName,
                          action: "reject",
                        ),
                    child: const Text("Reject"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.black26),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
