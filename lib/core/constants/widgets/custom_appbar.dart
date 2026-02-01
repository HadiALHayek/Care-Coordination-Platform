import 'package:flutter/material.dart';
import 'package:test_app/core/constants/app_colors.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isShowe;
  final VoidCallback onTap;
  final bool centerTitle;
  const CustomAppbar({
    super.key,
    required this.title,
    required this.isShowe,
    required this.onTap,
     this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: TextStyle(fontSize: 20)),
      leading:
          isShowe
              ? IconButton(
                onPressed: onTap,
                icon: Icon(Icons.arrow_back_ios_new),
              )
              : null,
      centerTitle: centerTitle,
      backgroundColor: AppColors.appBarbackgroundColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
