import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/prefs_cache.dart';
import '../../services/pharmacy_api.dart';

class PharmacyListView extends StatefulWidget {
  const PharmacyListView({super.key});

  @override
  State<PharmacyListView> createState() => _PharmacyListViewState();
}

class _PharmacyListViewState extends State<PharmacyListView> {
  String token = "";
  bool loading = true;
  List<Map<String, dynamic>> pharmacies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await PrefsCache.getInstance();
    token = prefs.getString("token") ?? "";
    pharmacies = await PharmacyApi.listPharmacies(token: token);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _selectPharmacy(Map<String, dynamic> p) async {
    final id = int.tryParse(p["id"].toString()) ?? 0;
    if (id == 0) return;

    final res = await PharmacyApi.setPreferredPharmacy(
      token: token,
      pharmacyId: id,
    );

    if (!mounted) return;

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Preferred pharmacy set to: ${p["name"]} ✅")),
      );
      context.pop(true); // return success to ProfileView
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
        title: const Text("Choose Pharmacy"),
        backgroundColor: const Color(0xFF20BCD0),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : pharmacies.isEmpty
              ? const Center(child: Text("No pharmacies found"))
              : ListView.builder(
                itemCount: pharmacies.length,
                itemBuilder: (context, i) {
                  final p = pharmacies[i];
                  final name = (p["name"] ?? "").toString();
                  final address = (p["address"] ?? "").toString();

                  return ListTile(
                    leading: const Icon(
                      Icons.local_pharmacy,
                      color: Colors.teal,
                    ),
                    title: Text(name),
                    subtitle: address.isEmpty ? null : Text(address),
                    trailing: ElevatedButton(
                      onPressed: () => _selectPharmacy(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20BCD0),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Select"),
                    ),
                  );
                },
              ),
    );
  }
}
