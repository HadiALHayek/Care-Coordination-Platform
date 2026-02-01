import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/language_provider.dart';
import '../../core/constants/theme_provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  String _localized(BuildContext context, String en, String ar) {
    return context.watch<LanguageProvider>().language == 'Arabic' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_localized(context, 'Settings', 'الإعدادات')),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingCard(
            theme,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_localized(context, 'Dark Mode', 'الوضع الداكن')),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: themeProvider.toggleDarkMode,
                  activeColor: Colors.teal,
                ),
              ],
            ),
          ),
          _settingCard(
            theme,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_localized(context, 'Language', 'اللغة')),
                DropdownButton<String>(
                  value: languageProvider.language,
                  items:
                      languageProvider.languages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang,
                          child: Text(lang),
                        );
                      }).toList(),
                  onChanged: (val) => languageProvider.setLanguage(val),
                  underline: const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingCard(ThemeData theme, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: child,
    );
  }
}
