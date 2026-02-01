import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScanDetailsView extends StatelessWidget {
  final Map<String, dynamic> scan;

  const ScanDetailsView({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF20BCD0),
        title: const Text("Scan Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Scan ID: ${scan['id']}",
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              "Patient: ${scan['patient_name']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Type: ${scan['scan_type']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "AI Result: ${scan['ai_result']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Date: ${scan['scan_date']}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 25),

            // OPEN PDF ONLY
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20BCD0),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                context.push("/pdf-viewer", extra: scan["pdf_url"]);
              },
              child: const Text(
                "Open PDF Report",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
