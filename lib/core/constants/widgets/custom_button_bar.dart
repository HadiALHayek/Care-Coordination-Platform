// import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// class CustomBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//
//   const CustomBottomNavBar({super.key, required this.currentIndex});
//
//   @override
//   Widget build(BuildContext context) {
//     final icons = [
//       'assets/women2-removebg-preview.png', // Breast
//       'assets/brain.1png.png', // Brain
//     ];
//
//     final routes = ['/breast', '/brain'];
//
//     return Stack(
//       clipBehavior: Clip.none,
//       alignment: Alignment.center,
//       children: [
//         AnimatedBottomNavigationBar.builder(
//           itemCount: icons.length,
//           tabBuilder: (index, isActive) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               child: Image.asset(
//                 icons[index],
//                 height: 28,
//                 color: isActive ? Colors.blueAccent : null,
//               ),
//             );
//           },
//           activeIndex: currentIndex,
//           backgroundColor: Colors.white,
//           gapLocation: GapLocation.center,
//           notchSmoothness: NotchSmoothness.verySmoothEdge,
//           leftCornerRadius: 32,
//           rightCornerRadius: 32,
//           onTap: (index) {
//             if (index >= 0 && index < routes.length) {
//               context.go(routes[index]);
//             }
//           },
//         ),
//
//         // Home button in center
//         Positioned(
//           top: -28,
//           child: GestureDetector(
//             onTap: () => context.go('/home'),
//             child: Container(
//               height: 60,
//               width: 60,
//               decoration: BoxDecoration(
//                 color: const Color(0xff20bcd0),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: const Icon(Icons.home, size: 35, color: Colors.cyanAccent),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
