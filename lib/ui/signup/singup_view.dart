import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/language_provider.dart';
import '../../core/constants/widgets/governorates.dart';
import '../../core/constants/widgets/pack_ground.dart';
import '../../services/signup_api.dart';
import '../../widgets/custom_text_field.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final weightController = TextEditingController();

  String? selectedGender;
  String? selectedGovernorate;
  DateTime? selectedDate;

  final TextEditingController dobController = TextEditingController();

  bool _loading = false;

  // Date Picker
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

  // Submit Signup
  Future<void> _submitSignup() async {
    if (selectedGender == null ||
        selectedDate == null ||
        selectedGovernorate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final weight = double.tryParse(weightController.text.trim());
    if (weight == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid weight")));
      return;
    }

    setState(() => _loading = true);

    final result = await registerPatient(
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      gender: selectedGender!,
      dateOfBirth:
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
      phoneNumber: phoneController.text.trim(),
      emergencyContact: emergencyController.text.trim(),
      location: selectedGovernorate!,
      weightKg: weight,
    );

    setState(() => _loading = false);

    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful! Please login.")),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${result['error']}")));
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
    final lang = context.watch<LanguageProvider>().language;

    return Scaffold(
      body: Stack(
        children: [
          const PackGround.withDefaultImage(),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  border: Border.all(
                    color: const Color.fromARGB(255, 93, 148, 199),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      lang == "English" ? "Sign Up" : "إنشاء حساب",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 25),

                    CustomTextField(
                      tite: lang == "English" ? "Full Name" : "الاسم الكامل",
                      controller: fullNameController,
                      textInputType: TextInputType.name,
                      obscureText: false,
                      widget: const Icon(Icons.person),
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      tite: lang == "English" ? "Phone Number" : "رقم الهاتف",
                      controller: phoneController,
                      textInputType: TextInputType.phone,
                      obscureText: false,
                      widget: const Icon(Icons.phone),
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      tite:
                          lang == "English"
                              ? "Emergency Contact"
                              : "رقم الطوارئ",
                      controller: emergencyController,
                      textInputType: TextInputType.phone,
                      obscureText: false,
                      widget: const Icon(Icons.phone_in_talk),
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
                      tite: lang == "English" ? "Password" : "كلمة المرور",
                      controller: passwordController,
                      textInputType: TextInputType.text,
                      obscureText: true,
                      widget: const Icon(Icons.lock),
                    ),
                    const SizedBox(height: 10),

                    // Gender Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(255, 93, 148, 199),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedGender,
                        dropdownColor: Colors.white,
                        hint: Text(
                          lang == "English" ? "Select Gender" : "اختر الجنس",
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text("Male")),
                          DropdownMenuItem(value: 'F', child: Text("Female")),
                          DropdownMenuItem(value: 'O', child: Text("Other")),
                        ],
                        onChanged:
                            (value) => setState(() => selectedGender = value),
                      ),
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      tite: lang == "English" ? "Birth Date" : "تاريخ الميلاد",
                      controller: dobController,
                      readOnly: true,
                      textInputType: TextInputType.none,
                      obscureText: false,
                      widget: const Icon(Icons.calendar_today),
                      ontap: _selectDate,
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      tite: lang == "English" ? "Weight (kg)" : "الوزن (كغ)",
                      controller: weightController,
                      textInputType: TextInputType.number,
                      obscureText: false,
                      widget: const Icon(Icons.monitor_weight),
                    ),
                    const SizedBox(height: 10),

                    // Governorate Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(255, 93, 148, 199),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedGovernorate,
                        dropdownColor: Colors.white,
                        hint: Text(
                          lang == "English"
                              ? "Select Governorate"
                              : "اختر المحافظة",
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items:
                            syriaGovernorates.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) =>
                                setState(() => selectedGovernorate = value),
                      ),
                    ),
                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: _loading ? null : _submitSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20BCD0),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child:
                          _loading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                lang == "English" ? "Sign Up" : "إنشاء حساب",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
