import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String tite;
  final TextInputType textInputType;
  final bool obscureText;
  final Widget widget;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final bool readOnly;
  final void Function()? ontap;

  const CustomTextField({
    super.key,
    required this.tite,
    required this.textInputType,
    required this.obscureText,
    required this.widget,
    this.onChanged,
    this.controller,
    this.readOnly =false,
    this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        onTap: ontap,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: textInputType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: tite,
          hintStyle: TextStyle(color: Color.fromARGB(255, 59, 90, 190)),
          border: OutlineInputBorder(),
          suffixIcon: widget,
          suffixIconColor: Color.fromARGB(255, 59, 90, 190),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
