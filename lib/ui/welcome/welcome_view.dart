import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:test_app/core/constants/app_colors.dart';
import 'package:test_app/core/constants/stayle.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      context.pushReplacement('/start');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor1,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset('assets/brain.json', width: 280, height: 280),
            Text('TUMOR TRACK', style: AppTextStyle.Text30),
            Text(
              'Empowering early brain tumor diagnosis\nthrough AI precision',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 70, 103, 212),
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
