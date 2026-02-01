import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/core/constants/app_colors.dart';
import 'package:test_app/core/constants/stayle.dart';
import 'package:test_app/core/constants/widgets/custom_button.dart';

class StartView extends StatelessWidget {
  const StartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/log.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: const Color.fromARGB(255, 56, 121, 175).withOpacity(0.4),
          ),
          SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome',
                  style: AppTextStyle.Text30.copyWith(
                    color: AppColors.bigTitle,
                  ),
                ),
                Text(
                  'login or sign up to continue',
                  style: AppTextStyle.Text18,
                ),
                CustomButton(
                  title: 'Login',
                  ontap: () {
                    context.push('/login');
                  },
                ),
                CustomButton(
                  title: 'Sign Up',
                  ontap: () {
                    context.push('/signup');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
