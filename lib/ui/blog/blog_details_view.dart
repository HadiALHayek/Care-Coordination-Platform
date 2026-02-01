import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/language_provider.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/widgets/custom_appbar.dart';

class BlogDetailsView extends StatelessWidget {
  final Map<String, dynamic> blog;

  const BlogDetailsView({super.key, required this.blog});

  String _safeString(dynamic v) => (v ?? "").toString();

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, bool>(
      selector: (_, p) => p.isDarkMode,
      builder: (context, isDark, _) {
        return Selector<LanguageProvider, String>(
          selector: (_, p) => p.language,
          builder: (context, lang, __) {
            final isEnglish = lang == "English";

            final title = _safeString(blog["title"]);
            final preview = _safeString(blog["preview"]);
            final body = _safeString(blog["body"]);
            final createdAt = _safeString(blog["created_at"]);

            final content = body.isNotEmpty ? body : preview;

            return Scaffold(
              backgroundColor: isDark ? Colors.black : const Color(0xFFF7F9FB),
              appBar: CustomAppbar(
                title: isEnglish ? "Blog" : "المدونة",
                isShowe: true,
                onTap: () => context.pop(),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111111) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF20BCD0),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isEnglish
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                    children: [
                      Text(
                        title.isNotEmpty
                            ? title
                            : (isEnglish ? "Blog Post" : "مقال"),
                        textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (createdAt.isNotEmpty)
                        Text(
                          createdAt,
                          textAlign:
                              isEnglish ? TextAlign.left : TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark
                                    ? Colors.white70
                                    : Colors.black.withOpacity(0.55),
                          ),
                        ),

                      const SizedBox(height: 14),

                      if (preview.isNotEmpty)
                        Text(
                          preview,
                          textAlign:
                              isEnglish ? TextAlign.left : TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? Colors.white70
                                    : const Color(0xFF37474F),
                          ),
                        ),

                      if (preview.isNotEmpty) const SizedBox(height: 14),

                      Text(
                        content,
                        textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
