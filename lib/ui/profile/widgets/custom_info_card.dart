import 'package:flutter/material.dart';

import '../../../core/constants/stayle.dart';

class CustomInfoCard extends StatelessWidget {
  final String title;
  final IconData iconData;
  final String title2;
  final Color iconColor;

  const CustomInfoCard({
    super.key,
    required this.title,
    required this.iconData,
    required this.title2,
    this.iconColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.060,
        width: MediaQuery.sizeOf(context).width,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromARGB(255, 93, 148, 199),
            width: 1.0,
          ),
          color: Colors.white54,
        ),
        child: Row(
          children: [
            Icon(iconData, color: iconColor),
            SizedBox(width: 10),
            Text(title, style: AppTextStyle.Texte18),
            SizedBox(width: 10),
            Text(title2, style: AppTextStyle.Texte18),
          ],
        ),
      ),
    );
  }
}
