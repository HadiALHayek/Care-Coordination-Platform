import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/ui/home/home_view.dart';
import 'package:test_app/ui/login/login_view.dart';
import 'package:test_app/ui/profile/profile_view.dart';
import 'package:test_app/ui/settings/setting_view.dart';
import 'package:test_app/ui/start/start_view.dart';
import 'package:test_app/ui/welcome/welcome_view.dart';

import '../../../ui/blog/blog_details_view.dart';
import '../../../ui/bran/brain_view.dart';
import '../../../ui/breast/Breast_view.dart';
import '../../../ui/chat/chat_view.dart';
import '../../../ui/doctor_home/doctor_home_view.dart';
import '../../../ui/doctor_list/doctor_list_view.dart';
import '../../../ui/doctor_patient_list/doctor_patients_view.dart';
import '../../../ui/doctor_patient_profile/doctor_patient_profile_view.dart';
import '../../../ui/doctor_profile/doctor_profile_view.dart';
import '../../../ui/doctor_scan_details/scan_details_view.dart';
import '../../../ui/edit_doctor_profile/edit_doctor_profile_view.dart';
import '../../../ui/expert_rules/expert_rules_view.dart';
import '../../../ui/pharmacy/pharmacy_list_view.dart';
import '../../../ui/signup/singup_view.dart';
import '../widgets/pdf_viewer.dart';

/// Non-functional requirements extracted from this code:
///
/// 1. **Performance**:
///    - Routes should load efficiently with minimal memory footprint
///    - Lazy instantiation of widgets to reduce initial load time
///    - Optimized type checking to minimize runtime overhead
///
/// 2. **Reliability**:
///    - Robust error handling for invalid route parameters
///    - Type-safe parameter extraction with fallback error screens
///    - Graceful degradation when route data is missing or invalid
///
/// 3. **Maintainability**:
///    - Clear error messages for debugging
///    - Consistent error handling patterns across routes
///    - Type-safe route parameter handling
///
/// 4. **Scalability**:
///    - Efficient route matching and navigation
///    - Minimal memory allocation during navigation
///
/// 5. **Security**:
///    - Input validation for all route parameters
///    - Safe type casting with proper null checks

class AppRouts {
  /// Error widget builder for consistent error handling
  static Widget _buildErrorScreen(String message, [Object? error]) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Safely extracts recipient ID from various types
  static int? _extractRecipientId(dynamic rawId) {
    if (rawId == null) return null;
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  /// Safely extracts string value from dynamic
  static String? _extractString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Safely extracts Map from state.extra with type checking
  static Map<String, dynamic>? _extractMap(dynamic extra) {
    if (extra is Map<String, dynamic>) return extra;
    if (extra is Map) {
      return extra.cast<String, dynamic>();
    }
    return null;
  }

  static final GoRouter route = GoRouter(
    initialLocation: '/',
    // Enable error handling for better reliability
    errorBuilder:
        (context, state) =>
            _buildErrorScreen('Route not found: ${state.uri}', state.error),
    routes: [
      // Simple routes with const widgets for better performance
      GoRoute(path: '/', builder: (context, state) => const WelcomeView()),
      GoRoute(path: '/start', builder: (context, state) => const StartView()),
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupView()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(path: '/brain', builder: (context, state) => const BrainView()),
      GoRoute(path: '/breast', builder: (context, state) => const BreastView()),

      // Chat route with optimized parameter extraction
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          try {
            final extras = state.extra;
            final recipientId =
                extras is Map<String, dynamic>
                    ? _extractRecipientId(extras["recipientId"])
                    : null;
            final recipientName =
                extras is Map<String, dynamic>
                    ? _extractString(extras["recipientName"])
                    : null;

            if (recipientId == null ||
                recipientName == null ||
                recipientName.isEmpty) {
              return _buildErrorScreen(
                'Error: Missing or invalid chat parameters',
                'Required: recipientId (int or string), recipientName (string)',
              );
            }

            return ChatView(
              recipientId: recipientId,
              recipientName: recipientName,
            );
          } catch (e) {
            return _buildErrorScreen('Error loading chat', e);
          }
        },
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: '/doctor-home',
        builder: (context, state) => const DoctorHomeView(),
      ),
      GoRoute(
        path: '/doctor-patients',
        builder: (context, state) => const DoctorPatientsView(),
      ),

      // Doctor patient profile with safe parameter parsing
      GoRoute(
        path: '/doctor-patient-profile/:id',
        builder: (context, state) {
          try {
            final idParam = state.pathParameters["id"];
            if (idParam == null || idParam.isEmpty) {
              return _buildErrorScreen('Error: Missing patient ID parameter');
            }

            final id = int.tryParse(idParam);
            if (id == null) {
              return _buildErrorScreen(
                'Error: Invalid patient ID format',
                'Expected integer, got: $idParam',
              );
            }

            return DoctorPatientProfileView(patientId: id);
          } catch (e) {
            return _buildErrorScreen('Error loading patient profile', e);
          }
        },
      ),

      GoRoute(
        path: '/doctor-list',
        builder: (context, state) => const DoctorListView(),
      ),

      // PDF viewer with safe type checking
      GoRoute(
        path: "/pdf-viewer",
        builder: (context, state) {
          try {
            final url =
                state.extra is String
                    ? state.extra as String
                    : state.extra?.toString();

            if (url == null || url.isEmpty) {
              return _buildErrorScreen('Error: Missing PDF URL');
            }

            return PdfViewerPage(pdfUrl: url);
          } catch (e) {
            return _buildErrorScreen('Error loading PDF viewer', e);
          }
        },
      ),

      GoRoute(
        path: '/doctor-profile',
        builder: (context, state) => const DoctorProfileView(),
      ),

      // Scan details with safe type checking
      GoRoute(
        path: '/scan-details',
        builder: (context, state) {
          try {
            final scan = _extractMap(state.extra);
            if (scan == null || scan.isEmpty) {
              return _buildErrorScreen('Error: Missing or invalid scan data');
            }

            return ScanDetailsView(scan: scan);
          } catch (e) {
            return _buildErrorScreen('Error loading scan details', e);
          }
        },
      ),

      GoRoute(
        path: '/expert-rules',
        builder: (context, state) => const DrugView(),
      ),
      GoRoute(
        path: '/pharmacies',
        builder: (context, state) => const PharmacyListView(),
      ),

      // Doctor profile edit with safe type checking
      GoRoute(
        path: '/doctor-profile/edit',
        builder: (context, state) {
          try {
            final doctor = _extractMap(state.extra);
            if (doctor == null || doctor.isEmpty) {
              return _buildErrorScreen('Error: Missing or invalid doctor data');
            }

            return DoctorEditProfileView(initialDoctor: doctor);
          } catch (e) {
            return _buildErrorScreen('Error loading doctor edit profile', e);
          }
        },
      ),
      GoRoute(
        path: '/blog-details',
        builder: (context, state) {
          final extra = state.extra;
          final blog =
              (extra is Map<String, dynamic>) ? extra : <String, dynamic>{};
          return BlogDetailsView(blog: blog);
        },
      ),
    ],
  );
}
