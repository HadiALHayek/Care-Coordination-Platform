import 'package:flutter/material.dart';
import 'package:test_app/core/constants/app_colors.dart';
import 'package:test_app/ui/login/widgets/custom_logn_info.dart';

import '../../core/constants/widgets/pack_ground.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor1,
      body: Stack(
        children: [
          const PackGround.withDefaultImage(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.6,
                width: MediaQuery.sizeOf(context).width,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromARGB(255, 93, 148, 199),
                    width: 1.0,
                  ),
                  color: Colors.white54,
                ),
                child: const SingleChildScrollView(child: CustomLognInfo()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
