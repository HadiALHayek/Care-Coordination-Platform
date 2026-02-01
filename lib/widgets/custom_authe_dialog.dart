// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:test_app/core/constants/app_colors.dart';
// import 'package:test_app/widgets/custom_text_field.dart';
//
// import '../core/constants/widgets/custom_button.dart';
//
// class CustomAutheDialog extends StatelessWidget {
//   final String title;
//   final String buttontitle;
//   final VoidCallback ontap;
//
//   const CustomAutheDialog({
//     super.key,
//     required this.title,
//     required this.buttontitle, required this.ontap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: EdgeInsets.all(20),
//
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               title,
//               style: GoogleFonts.poppins(
//                 fontSize: 22,
//                 color: AppColors.buttonTitle,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 10),
//             CustomTextField(
//               tite: 'email..',
//               textInputType: TextInputType.emailAddress,
//               obscureText: false,
//             ),
//             SizedBox(height: 15),
//             CustomTextField(
//               tite: 'Passwored..',
//               textInputType: TextInputType.none,
//               obscureText: true,
//             ),
//             SizedBox(height: 10),
//             CustomButton(
//               title: buttontitle,
//               ontap:ontap,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
