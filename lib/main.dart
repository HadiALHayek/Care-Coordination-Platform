import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/core/constants/theme_provider.dart';
import 'package:test_app/core/constants/language_provider.dart';
import 'package:test_app/core/constants/routs/app_routs.dart';
import 'package:test_app/core/constants/theme_cache.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const RootApp(),
    ),
  );
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when specific values change
    // This prevents unnecessary rebuilds when other provider properties change
    return Selector<ThemeProvider, bool>(
      selector: (_, provider) => provider.isDarkMode,
      builder: (context, isDarkMode, _) {
        return Selector<LanguageProvider, String>(
          selector: (_, provider) => provider.language,
          builder: (context, language, _) {
            final key = ValueKey('$isDarkMode-$language');
            return MaterialApp.router(
              key: key,
              debugShowCheckedModeBanner: false,
              title: 'Tumor Track',
              // Use cached theme instances to prevent recreation on every rebuild
              theme: isDarkMode ? ThemeCache.darkTheme : ThemeCache.lightTheme,
              routerConfig: AppRouts.route,
            );
          },
        );
      },
    );
  }
}
