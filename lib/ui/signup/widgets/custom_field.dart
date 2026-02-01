import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/stayle.dart';
import '../../../core/constants/widgets/custom_button.dart';
import '../../../core/constants/widgets/governorates.dart';
import '../../../services/signup_api.dart' as SignupApi;
import '../../../widgets/custom_text_field.dart';

class CustomField extends StatefulWidget {
  const CustomField({super.key});

  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  // Controllers
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final weightController = TextEditingController();

  // Dropdowns
  final List<String> genderOptions = ['M', 'F', 'O'];
  String? selectedGender;
  String? selectedGovernorate;

  // Date
  DateTime? selectedDate;
  final TextEditingController dobController = TextEditingController();

  // ---------------- Date Picker ----------------
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  String _formatDob(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // ---------------- Submit ----------------
  Future<void> _submitSignup() async {
    if (selectedGender == null ||
        selectedDate == null ||
        selectedGovernorate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select gender, date & governorate"),
        ),
      );
      return;
    }

    final weight = double.tryParse(weightController.text.trim());
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid weight (e.g. 65.5)")),
      );
      return;
    }

    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emergencyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    final result = await SignupApi.registerPatient(
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      gender: selectedGender!,
      dateOfBirth: _formatDob(selectedDate!),
      phoneNumber: phoneController.text.trim(),
      emergencyContact: emergencyController.text.trim(),
      location: selectedGovernorate!,
      weightKg: weight,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup Successful")));
      context.push("/login");
    } else {
      final error = result["error"];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $error")));
    }
  }

  @override
  void dispose() {
    dobController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    emergencyController.dispose();
    emailController.dispose();
    passwordController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Signup", style: AppTextStyle.Text30),
        const SizedBox(height: 30),

        CustomTextField(
          tite: "Full Name",
          controller: fullNameController,
          textInputType: TextInputType.name,
          obscureText: false,
          widget: const Icon(Icons.person),
        ),
        const SizedBox(height: 10),

        CustomTextField(
          tite: "Phone Number",
          controller: phoneController,
          textInputType: TextInputType.phone,
          obscureText: false,
          widget: const Icon(Icons.phone),
        ),
        const SizedBox(height: 10),

        CustomTextField(
          tite: "Emergency Contact",
          controller: emergencyController,
          textInputType: TextInputType.phone,
          obscureText: false,
          widget: const Icon(Icons.phone_android),
        ),
        const SizedBox(height: 10),

        CustomTextField(
          tite: "Email",
          controller: emailController,
          textInputType: TextInputType.emailAddress,
          obscureText: false,
          widget: const Icon(Icons.email),
        ),
        const SizedBox(height: 10),

        CustomTextField(
          tite: "Password",
          controller: passwordController,
          textInputType: TextInputType.text,
          obscureText: true,
          widget: const Icon(Icons.lock),
        ),
        const SizedBox(height: 20),

        // Gender Dropdown
        CustomTextField(
          tite: "Select Gender",
          readOnly: true,
          textInputType: TextInputType.none,
          obscureText: false,
          widget: DropdownButton<String>(
            value: selectedGender,
            hint: const Text("Choose"),
            isExpanded: true,
            underline: const SizedBox(),
            items:
                genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
            onChanged: (value) => setState(() => selectedGender = value),
          ),
        ),
        const SizedBox(height: 10),

        // Birth Date
        CustomTextField(
          tite: "Birth Date",
          controller: dobController,
          readOnly: true,
          textInputType: TextInputType.none,
          obscureText: false,
          widget: const Icon(Icons.calendar_today),
          ontap: _selectDate,
        ),
        const SizedBox(height: 10),

        // Weight
        CustomTextField(
          tite: "Weight (kg)",
          controller: weightController,
          textInputType: TextInputType.number,
          obscureText: false,
          widget: const Icon(Icons.monitor_weight),
        ),
        const SizedBox(height: 10),

        // Governorate Dropdown
        CustomTextField(
          tite: "Select Governorate",
          readOnly: true,
          textInputType: TextInputType.none,
          obscureText: false,
          widget: DropdownButton<String>(
            value: selectedGovernorate,
            hint: const Text("Choose Governorate"),
            isExpanded: true,
            underline: const SizedBox(),
            items:
                syriaGovernorates.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => selectedGovernorate = value),
          ),
        ),
        const SizedBox(height: 30),

        CustomButton(title: "Sign Up", ontap: _submitSignup),
      ],
    );
  }
}
