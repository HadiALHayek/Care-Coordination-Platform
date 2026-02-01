import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/language_provider.dart';
import '../../core/constants/prefs_cache.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/widgets/custom_appbar.dart';
import '../../services/blog_api.dart'; // ✅ NEW
import '../../services/profile_api.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _loadingDoctors = true;
  List<Map<String, dynamic>> _activeDoctors = [];

  // ✅ BLOGS
  bool _loadingBlogs = true;
  List<Map<String, dynamic>> _blogs = [];
  final ScrollController _blogScrollController = ScrollController();

  // LOGOUT FUNCTION
  Future<void> _logout(BuildContext context) async {
    final prefs = await PrefsCache.getInstance();
    await prefs.remove("token");
    if (context.mounted) context.go('/login');
  }

  @override
  void initState() {
    super.initState();
    _loadActiveDoctors();
    _loadBlogs(); // ✅ NEW
  }

  @override
  void dispose() {
    _blogScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveDoctors() async {
    setState(() => _loadingDoctors = true);

    final prefs = await PrefsCache.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      if (mounted) context.go('/login');
      return;
    }

    final res = await ProfileApi.getProfile(token);

    if (!mounted) return;

    if (res["success"] == true) {
      final data = res["data"];
      final raw = (data is Map) ? data["active_doctors"] : null;

      final list =
          (raw is List)
              ? raw.map((e) => Map<String, dynamic>.from(e)).toList()
              : <Map<String, dynamic>>[];

      setState(() {
        _activeDoctors = list;
        _loadingDoctors = false;
      });
    } else {
      setState(() => _loadingDoctors = false);
    }
  }

  // ✅ LOAD BLOGS
  Future<void> _loadBlogs() async {
    setState(() => _loadingBlogs = true);

    final res = await BlogApi.getBlogs();

    if (!mounted) return;

    if (res["success"] == true) {
      final raw = res["data"];
      final list =
          (raw is List)
              ? raw.map((e) => Map<String, dynamic>.from(e)).toList()
              : <Map<String, dynamic>>[];

      setState(() {
        _blogs = list;
        _loadingBlogs = false;
      });
    } else {
      setState(() => _loadingBlogs = false);
    }
  }

  void _scrollBlogsLeft() {
    if (!_blogScrollController.hasClients) return;
    final current = _blogScrollController.offset;
    const step = 200.0;
    final target = (current - step).clamp(
      0.0,
      _blogScrollController.position.maxScrollExtent,
    );
    _blogScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _scrollBlogsRight() {
    if (!_blogScrollController.hasClients) return;
    final current = _blogScrollController.offset;
    const step = 200.0;
    final target = (current + step).clamp(
      0.0,
      _blogScrollController.position.maxScrollExtent,
    );
    _blogScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, bool>(
      selector: (_, provider) => provider.isDarkMode,
      builder: (context, isDark, _) {
        return Selector<LanguageProvider, String>(
          selector: (_, provider) => provider.language,
          builder: (context, language, _) {
            final bgColor = isDark ? Colors.black : AppColors.backgroundColor1;
            final isEnglish = language == 'English';
            return _buildContent(context, bgColor, isEnglish);
          },
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, Color bgColor, bool isEnglish) {
    return Scaffold(
      backgroundColor: bgColor,

      // APP BAR
      appBar: CustomAppbar(
        title: isEnglish ? 'TUMOR TRACK' : 'مسار الورم',
        isShowe: false,
        onTap: () {},
        centerTitle: true,
      ),

      // DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF20BCD0)),
              child: Text(
                isEnglish ? 'Menu' : 'القائمة',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            _buildDrawerItem(
              context,
              icon: Icons.account_circle,
              label: isEnglish ? 'Profile' : 'الملف الشخصي',
              onTap: () => context.go('/profile'),
            ),

            _buildDrawerItem(
              context,
              icon: Icons.settings,
              label: isEnglish ? 'Settings' : 'الإعدادات',
              onTap: () => context.push('/settings'),
            ),

            _buildDrawerItem(
              context,
              icon: Icons.logout,
              label: isEnglish ? 'Logout' : 'تسجيل الخروج',
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),

      // BODY CONTENT
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadActiveDoctors(), _loadBlogs()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // =================== MY DOCTORS ===================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    isEnglish ? "My Doctors" : "أطبائي",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (_loadingDoctors)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_activeDoctors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF20BCD0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF20BCD0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEnglish
                                ? "No active doctor yet. Once a doctor accepts your request, you can chat here."
                                : "لا يوجد طبيب مرتبط بعد. عندما يقبل الطبيب طلبك سيظهر هنا زر المحادثة.",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children:
                        _activeDoctors.map((d) {
                          final int id =
                              int.tryParse((d["id"] ?? "").toString()) ?? 0;
                          final String name =
                              (d["full_name"] ?? "Doctor").toString();
                          final String email = (d["email"] ?? "").toString();

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF20BCD0),
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0xFFEAF7F9),
                                  child: Icon(
                                    Icons.medical_services,
                                    color: Color(0xFF20BCD0),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF263238),
                                        ),
                                      ),
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF20BCD0),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed:
                                        id == 0
                                            ? null
                                            : () {
                                              context.push(
                                                '/chat',
                                                extra: {
                                                  "recipientId": id,
                                                  "recipientName": name,
                                                },
                                              );
                                            },
                                    child: Text(isEnglish ? "Chat" : "محادثة"),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),

              const SizedBox(height: 10),

              // =================== BLOG SECTION (LEFT/RIGHT SLIDE) ===================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    isEnglish ? 'Blog' : 'المدونة',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 34),
                      onPressed: _scrollBlogsLeft,
                    ),
                    Expanded(
                      child:
                          _loadingBlogs
                              ? const Center(child: CircularProgressIndicator())
                              : (_blogs.isEmpty)
                              ? Center(
                                child: Text(
                                  isEnglish
                                      ? "No blog posts yet."
                                      : "لا توجد مقالات بعد.",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              )
                              : ListView.separated(
                                controller: _blogScrollController,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                itemCount: _blogs.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(width: 14),
                                // ✅ spacing
                                itemBuilder: (context, index) {
                                  final b = _blogs[index];
                                  final title = (b["title"] ?? "").toString();
                                  final preview =
                                      (b["preview"] ?? "").toString();
                                  final body = (b["body"] ?? "").toString();
                                  final shownPreview =
                                      preview.isNotEmpty ? preview : body;

                                  return _BlogCard(
                                    title:
                                        title.isNotEmpty
                                            ? title
                                            : (isEnglish ? "Blog" : "مدونة"),
                                    preview: shownPreview,
                                    isEnglish: isEnglish,
                                    onTap:
                                        () => context.push(
                                          '/blog-details',
                                          extra: b,
                                        ),
                                  );
                                },
                              ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 34),
                      onPressed: _scrollBlogsRight,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =================== MRI SCANS ===================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    isEnglish ? 'Scans Analysis' : 'تحليل الصور',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ScanCard(
                      key: const ValueKey('breast_scan'),
                      title: isEnglish ? 'Breast Scan' : 'فحص الثدي',
                      subtitle:
                          isEnglish
                              ? 'Upload your breast mammogram for AI analysis'
                              : 'قم برفع الصورة الشعاعية للثدي ',
                      icon: Icons.medical_services,
                      iconAsset: 'assets/women2-removebg-preview.png',
                      color: const Color(0xFFE91E63),
                      onTap: () => context.go('/breast'),
                    ),
                    const SizedBox(height: 16),
                    _ScanCard(
                      key: const ValueKey('brain_scan'),
                      title: isEnglish ? 'Brain Scan' : 'فحص الدماغ',
                      subtitle:
                          isEnglish
                              ? 'Upload your brain MRI scan for AI analysis'
                              : 'قم برفع صورة الرنين المغناطيسي للدماغ ',
                      icon: Icons.psychology,
                      iconAsset: 'assets/brain.1png.png',
                      color: const Color(0xFF20BCD0),
                      onTap: () => context.go('/brain'),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Text(
                          isEnglish ? 'checks' : 'الفحوصات',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    _ScanCard(
                      key: const ValueKey('expert_rules'),
                      title:
                          isEnglish
                              ? 'Drug Interceptions'
                              : 'التداخلات الدوائية',
                      subtitle:
                          isEnglish
                              ? 'Clinical expert rules for drug interactions and oncology safety'
                              : 'قواعد طبية من خبراء للتداخلات الدوائية وسلامة علاج السرطان',
                      icon: Icons.rule,
                      iconAsset: 'assets/rules.png',
                      color: const Color(0xFF4CAF50),
                      onTap: () => context.go('/expert-rules'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Drawer item helper
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 80), onTap);
      },
    );
  }
}

// ================= BLOG CARD WIDGET ==========================
class _BlogCard extends StatelessWidget {
  final String title;
  final String preview;
  final bool isEnglish;
  final VoidCallback onTap;

  const _BlogCard({
    super.key,
    required this.title,
    required this.preview,
    required this.isEnglish,
    required this.onTap,
  });

  String _normalize(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    final t = _normalize(title);
    final p = _normalize(preview);

    return SizedBox(
      width: 185,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF20BCD0).withOpacity(0.35),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // ✅ FULL TITLE: wraps, no ellipsis
                Expanded(
                  flex: 3, // give title most of the height
                  child: Align(
                    alignment:
                        isEnglish ? Alignment.topLeft : Alignment.topRight,
                    child: Text(
                      t.isNotEmpty ? t : (isEnglish ? "Blog" : "مدونة"),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.indigo, // ✅ Navy
                        height: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ✅ Keep preview short to avoid overflow
                Expanded(
                  flex: 2,
                  child: Text(
                    p.isNotEmpty
                        ? p
                        : (isEnglish ? "Tap to read..." : "اضغط للقراءة..."),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20BCD0).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isEnglish ? "Read" : "اقرأ",
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF20BCD0),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 13,
                      color: Color(0xFF20BCD0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= SCAN CARD WIDGET ==========================
class _ScanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String iconAsset;
  final Color color;
  final VoidCallback onTap;

  const _ScanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    iconAsset,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
