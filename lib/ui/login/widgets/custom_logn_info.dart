import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/stayle.dart';
import '../../../core/constants/widgets/custom_button.dart';
import '../../../services/login_api.dart';
import '../../../widgets/custom_text_field.dart';

class CustomLognInfo extends StatefulWidget {
  const CustomLognInfo({super.key});

  @override
  State<CustomLognInfo> createState() => _CustomLognInfoState();
}

class _CustomLognInfoState extends State<CustomLognInfo> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    final result = await LoginApi.login(email: email, password: password);

    if (result["success"]) {
      final data = result["data"];
      final token = data["token"];
      final userType = data["user_type"] ?? "patient";

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);
      await prefs.setString("user_type", userType);
      await prefs.setString(
        "user_type",
        (data["user_type"] ?? "patient").toString(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login successful")));

      // === Navigate based on role ===
      if (userType == "doctor") {
        context.go("/doctor-home");
      } else {
        context.go("/home");
      }
    } else {
      final error = result["error"].toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('Login', style: AppTextStyle.Text30),
        const SizedBox(height: 40),

        CustomTextField(
          tite: 'Email',
          controller: emailController,
          textInputType: TextInputType.emailAddress,
          obscureText: false,
          widget: const Icon(Icons.email),
        ),
        const SizedBox(height: 10),

        CustomTextField(
          tite: 'Password',
          controller: passwordController,
          textInputType: TextInputType.text,
          obscureText: true,
          widget: const Icon(Icons.lock_outline_rounded),
        ),
        const SizedBox(height: 30),

        TextButton(
          onPressed: () {},
          child: Text(
            'Forget your password?',
            style: AppTextStyle.Text18.copyWith(
              color: const Color.fromARGB(255, 59, 90, 190),
            ),
          ),
        ),

        CustomButton(title: 'Login', ontap: _login),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ' or create one',
              style: AppTextStyle.Text18.copyWith(
                color: const Color.fromARGB(255, 59, 90, 190),
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                context.pushReplacement('/signup');
              },
              child: Text(
                'Signup',
                style: AppTextStyle.Text18.copyWith(
                  color: const Color.fromARGB(255, 59, 90, 190),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
