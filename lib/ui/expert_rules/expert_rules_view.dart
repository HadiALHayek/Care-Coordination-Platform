import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/language_provider.dart';
import '../../services/drug_api.dart';

class DrugView extends StatefulWidget {
  const DrugView({super.key});

  @override
  State<DrugView> createState() => _DrugViewState();
}

class _DrugViewState extends State<DrugView> {
  bool _loading = true;
  bool _computing = false;
  String? _error;
  bool _hasComputed = false;
  String? _token;
  Map<String, dynamic>? _catalog;
  String? _selectedCancerType;

  final Set<String> _oncoSelected = {};
  final Map<String, Set<String>> _chronicByCat = {};
  final Map<String, Set<String>> _nonChronicByCat = {};
  List<Map<String, dynamic>> _results = [];

  // Simple translation helper
  String _t(String en, String ar) {
    final lang = context.read<LanguageProvider>().language;
    return lang == 'Arabic' ? ar : en;
  }

  // Translate cancer type
  String _cancerTypeLabel(String raw) {
    final isAr = context.read<LanguageProvider>().language == 'Arabic';
    if (isAr) return raw;
    const map = {
      'سرطان الثدي': 'Breast cancer',
      'سرطان الدماغ': 'Brain cancer',
    };
    return map[raw] ?? raw;
  }

  // Translate category labels
  String _categoryLabel(String raw) {
    final isAr = context.read<LanguageProvider>().language == 'Arabic';
    if (isAr) return raw;
    const map = {
      'اكتئاب/قلق': 'Depression/Anxiety',
      'اضطراب نظم/قلب': 'Arrhythmia/Heart',
      'صرع': 'Epilepsy',
      'مضاد تخثر': 'Anticoagulant',
      'مضاد صفيحات': 'Antiplatelet',
      'ارتفاع شحوم': 'Hyperlipidemia',
      'ضغط': 'Hypertension',
      'سكري': 'Diabetes',
      'غدة': 'Thyroid/Steroids',
      'الربو': 'Asthma',
      'حموضة/ارتجاع (مزمن)': 'GERD/Acid reflux (chronic)',
      'HIV': 'HIV',
      'أدوية الحموضة': 'Acid reducers',
      'مسكنات/التهاب': 'Pain/Inflammation',
      'مضادات حيوية': 'Antibiotics',
      'مضادات فطرية': 'Antifungals',
      'مكمّلات/أدوية داعمة': 'Supplements/Supportive meds',
      'مزيل احتقان': 'Decongestant',
      'أدوية للغثيان': 'Antiemetics',
      'مانع حمل': 'Contraception',
    };
    return map[raw] ?? raw;
  }

  // Translate severity labels
  String _severityLabel(String raw) {
    final isAr = context.read<LanguageProvider>().language == 'Arabic';
    if (!isAr) return raw;
    switch (raw) {
      case 'Contraindicated':
        return 'ممنوع';
      case 'Avoid':
        return 'تجنّب';
      case 'Modify/Monitor':
        return 'تعديل/مراقبة';
      case 'Monitor':
        return 'مراقبة';
      case 'Info':
        return 'معلومات';
      default:
        return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _loading = false;
        _error = _t(
          'No token found. Please log in first.',
          'لا يوجد Token. سجّل دخول أولاً.',
        );
      });
      return;
    }

    await _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await DdiApi.fetchCatalog(token: _token!);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      final cancerTypes =
          (data['cancer_types'] as Map?)?.keys
              .map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        _catalog = data;
        _selectedCancerType = cancerTypes.isNotEmpty ? cancerTypes.first : null;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error =
            res['error']?.toString() ??
            _t('Failed to load lists.', 'فشل تحميل القوائم');
      });
    }
  }

  List<String> _oncoListForSelectedCancer() {
    if (_catalog == null || _selectedCancerType == null) return [];
    final map = _catalog!['cancer_types'] as Map?;
    final arr = (map?[_selectedCancerType] as List?) ?? [];
    return arr.map((e) => e.toString()).toList();
  }

  Map<String, List<String>> _chronicCategories() {
    final map = _catalog?['chronic_diseases'] as Map?;
    if (map == null) return {};
    return map.map(
      (k, v) =>
          MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
    );
  }

  Map<String, List<String>> _nonChronicCategories() {
    final map = _catalog?['nonchronic_categories'] as Map?;
    if (map == null) return {};
    return map.map(
      (k, v) =>
          MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
    );
  }

  List<String> _flatten(Map<String, Set<String>> m) =>
      m.values.expand((s) => s).toSet().toList()..sort();

  Future<void> _pickMulti({
    required String title,
    required List<String> items,
    required Set<String> selected,
  }) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final temp = Set<String>.from(selected);
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = items
                .where(
                  (e) => e.toLowerCase().contains(query.trim().toLowerCase()),
                )
                .toList(growable: false);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: _t('Search...', 'بحث...'),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (v) => setModalState(() => query = v),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (c, i) {
                            final v = filtered[i];
                            final checked = temp.contains(v);
                            return CheckboxListTile(
                              value: checked,
                              dense: true,
                              title: Text(v),
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true)
                                    temp.add(v);
                                  else
                                    temp.remove(v);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, selected),
                              child: Text(_t('Cancel', 'إلغاء')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff20bcd0),
                              ),
                              onPressed: () => Navigator.pop(context, temp),
                              child: Text(_t('Confirm', 'تأكيد')),
                            ),
                          ),
                        ],
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

    if (result != null) {
      setState(() {
        selected
          ..clear()
          ..addAll(result);
        _results = [];
        _hasComputed = false;
      });
    }
  }

  Future<void> _compute() async {
    if (_token == null) return;

    if (_oncoSelected.isEmpty) {
      setState(() {
        _error = _t(
          'Select at least one oncology drug.',
          'اختاري/اختر دواء سرطان واحد على الأقل.',
        );
      });
      return;
    }

    setState(() {
      _computing = true;
      _error = null;
      _results = [];
      _hasComputed = true;
    });

    final chronic = _flatten(_chronicByCat);
    final nonchronic = _flatten(_nonChronicByCat);

    final res = await DdiApi.checkInteractions(
      token: _token!,
      oncoDrugs: _oncoSelected.toList(),
      otherChronic: chronic,
      otherNonChronic: nonchronic,
      minSeverity: null,
      translateAr: context.read<LanguageProvider>().language == 'Arabic',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      final list = (data['results'] as List?) ?? [];
      setState(() {
        _results =
            list
                .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
                .toList();
        _computing = false;
      });
    } else {
      setState(() {
        _computing = false;
        _error =
            res['error']?.toString() ??
            _t('Failed to compute interactions.', 'فشل حساب التداخلات');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageProvider>().language == 'Arabic';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor1,
      appBar: AppBar(
        title: Text(_t('Drug interactions', 'التداخلات الدوائية')),
        backgroundColor: const Color(0xff20bcd0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop())
              context.pop();
            else
              context.go('/home');
          },
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorBox(message: _error!, onRetry: _loadCatalog)
              : _catalog == null
              ? Center(child: Text(_t('No data available', 'لا يوجد بيانات')))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle(_t('Cancer type', 'نوع السرطان')),
                  _buildCancerTypeSelector(),
                  const SizedBox(height: 12),
                  _sectionTitle(_t('Oncology drugs', 'أدوية السرطان')),
                  _PickRow(
                    title: _t('Select', 'اختيار'),
                    count: _oncoSelected.length,
                    onTap:
                        () => _pickMulti(
                          title: _t('Oncology drugs', 'أدوية السرطان'),
                          items: _oncoListForSelectedCancer(),
                          selected: _oncoSelected,
                        ),
                  ),
                  _ChipsWrap(values: _oncoSelected.toList(), translate: isAr),
                  const SizedBox(height: 16),
                  _sectionTitle(
                    _t('Chronic disease medications', 'أدوية الأمراض المزمنة'),
                  ),
                  ..._buildCategoryPickers(
                    categories: _chronicCategories(),
                    store: _chronicByCat,
                    pickTitlePrefix: _t(
                      'Chronic disease meds - ',
                      'أدوية الأمراض المزمنة - ',
                    ),
                    isChronic: true,
                  ),
                  _ChipsWrap(values: _flatten(_chronicByCat), translate: isAr),
                  const SizedBox(height: 16),
                  _sectionTitle(
                    _t(
                      'Non-chronic disease medications',
                      'أدوية الأمراض غير المزمنة',
                    ),
                  ),
                  ..._buildCategoryPickers(
                    categories: _nonChronicCategories(),
                    store: _nonChronicByCat,
                    pickTitlePrefix: _t(
                      'Non-chronic disease meds - ',
                      'أدوية الأمراض غير المزمنة - ',
                    ),
                    isChronic: false,
                  ),
                  _ChipsWrap(
                    values: _flatten(_nonChronicByCat),
                    translate: isAr,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _computing ? null : _compute,
                      icon:
                          _computing
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.calculate),
                      label: Text(
                        _computing
                            ? _t('Computing...', 'جاري الحساب...')
                            : _t('Calculate interactions', 'حساب التداخلات'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff20bcd0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_hasComputed) ...[
                    const SizedBox(height: 16),
                    _sectionTitle(
                      _t(
                        'Results (${_results.length})',
                        'النتائج (${_results.length})',
                      ),
                    ),
                    ..._results.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ResultCard(r: r, severityLabel: _severityLabel),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
    );
  }

  Widget _buildCancerTypeSelector() {
    final cancerTypes =
        (_catalog!['cancer_types'] as Map).keys
            .map((e) => e.toString())
            .toList();
    return DropdownButtonFormField<String>(
      value: _selectedCancerType,
      items:
          cancerTypes
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(_cancerTypeLabel(t)),
                ),
              )
              .toList(),
      onChanged: (v) {
        setState(() {
          _selectedCancerType = v;
          _oncoSelected.clear();
          _results = [];
          _hasComputed = false;
        });
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: ' ',
      ),
    );
  }

  List<Widget> _buildCategoryPickers({
    required Map<String, List<String>> categories,
    required Map<String, Set<String>> store,
    required String pickTitlePrefix,
    required bool isChronic,
  }) {
    final keys = categories.keys.toList()..sort();
    return keys.map((cat) {
      store.putIfAbsent(cat, () => <String>{});
      final sel = store[cat]!;
      final label = _categoryLabel(cat);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _PickRow(
          title: label,
          subtitle:
              sel.isEmpty
                  ? _t('Optional', 'اختياري')
                  : _t('Selected: ${sel.length}', 'مختار: ${sel.length}'),
          count: sel.length,
          onTap:
              () => _pickMulti(
                title: '$pickTitlePrefix$label',
                items: categories[cat] ?? const [],
                selected: sel,
              ),
        ),
      );
    }).toList();
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

/// Result Card
class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> r;
  final String Function(String rawSeverity) severityLabel;

  const _ResultCard({required this.r, required this.severityLabel});

  @override
  Widget build(BuildContext context) {
    final severity = r['severity']?.toString() ?? '';
    final lang = context.watch<LanguageProvider>().language;
    final isArUi = lang == 'Arabic';

    // Severity label
    final sevText = severityLabel(severity);

    // Translate mechanism/recommendation
    final mech =
        isArUi
            ? (r['mechanism_ar'] ?? r['mechanism_en'] ?? '')
            : (r['mechanism_en'] ?? '');
    final rec =
        isArUi
            ? (r['recommendation_ar'] ?? r['recommendation_en'] ?? '')
            : (r['recommendation_en'] ?? '');

    return Directionality(
      textDirection: isArUi ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${r['onco']} × ${r['other']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isArUi ? sevText : severity,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (mech.trim().isNotEmpty) ...[
                Text(
                  isArUi ? 'الآلية' : 'Mechanism',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(mech),
                const SizedBox(height: 8),
              ],
              if (rec.trim().isNotEmpty) ...[
                Text(
                  isArUi ? 'التوصية' : 'Recommendation',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(rec),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chips Wrap
class _ChipsWrap extends StatelessWidget {
  final List<String> values;
  final bool translate;

  const _ChipsWrap({required this.values, this.translate = false});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    String mapLabel(String raw) {
      if (!translate) return raw;
      const map = {
        'سرطان الثدي': 'Breast cancer',
        'سرطان الدماغ': 'Brain cancer',
      };
      return map[raw] ?? raw;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children:
            values.take(60).map((v) => Chip(label: Text(mapLabel(v)))).toList(),
      ),
    );
  }
}

/// Pick Row
class _PickRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;
  final VoidCallback onTap;

  const _PickRow({
    required this.title,
    this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff20bcd0), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff20bcd0).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// Error Box
class _ErrorBox extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(lang == 'Arabic' ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
