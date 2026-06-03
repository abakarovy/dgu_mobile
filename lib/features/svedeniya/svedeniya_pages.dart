import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_ui.dart';
import '../../core/di/app_container.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/edu_disclosure_api.dart';
import '../../data/api/upbringing_api.dart';
import '../../data/svedeniya/svedeniya_merge.dart';
import '../../shared/widgets/app_header.dart';
import 'edu_disclosure_nav.dart';
import 'svedeniya_content_builder.dart';

/// Общий фон экранов сведений.
abstract final class SvedeniyaPageStyle {
  static const background = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
      stops: [0.0, 0.18, 0.45],
    ),
  );

  static const hubHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
  );
}

/// Хаб «Сведения об ОО» — разделы без промежуточных подменю.
class SvedeniyaHubPage extends StatefulWidget {
  const SvedeniyaHubPage({super.key});

  @override
  State<SvedeniyaHubPage> createState() => _SvedeniyaHubPageState();
}

class _SvedeniyaHubPageState extends State<SvedeniyaHubPage> {
  Map<String, dynamic> _disclosure = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cached = AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey);
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _disclosure = cached);
      }
      final fresh = await AppContainer.eduDisclosureApi.getDisclosure();
      await AppContainer.jsonCache.setJson(EduDisclosureApi.cacheKey, fresh);
      if (mounted) setState(() => _disclosure = fresh);
    } catch (_) {
      final cached = AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey);
      if (cached != null && mounted) setState(() => _disclosure = cached);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSection(String rootId) {
    if (_disclosure.isEmpty) return;
    context.push('/public/home/svedeniya/$rootId', extra: _disclosure);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Сведения об ОО', style: appHeaderNestedTitleStyle),
      ),
      body: DecoratedBox(
        decoration: SvedeniyaPageStyle.background,
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: _load,
          child: _loading && _disclosure.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppUi.screenPaddingH,
                    AppUi.spacingL,
                    AppUi.screenPaddingH,
                    32,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppUi.spacingL),
                      decoration: BoxDecoration(
                        gradient: SvedeniyaPageStyle.hubHeroGradient,
                        borderRadius: BorderRadius.circular(AppUi.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightBlue.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сведения об образовательной организации',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              height: 1.25,
                              color: AppColors.textOnBanner,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Официальная информация о колледже ДГУ: структура, документы, '
                            'материально-техническая база и сервисы для студентов.',
                            style: AppTextStyle.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.textOnBanner.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppUi.spacingXl),
                    for (var i = 0; i < EduDisclosureNav.roots.length; i++) ...[
                      _HubSectionTile(
                        root: EduDisclosureNav.roots[i],
                        enabled: _disclosure.isNotEmpty,
                        onTap: () => _openSection(EduDisclosureNav.roots[i].id),
                      ),
                      if (i != EduDisclosureNav.roots.length - 1)
                        const SizedBox(height: AppUi.spacingM),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Один раздел: весь контент подразделов на одной прокручиваемой странице.
class SvedeniyaSectionPage extends StatefulWidget {
  const SvedeniyaSectionPage({super.key, required this.rootId, this.disclosure = const {}});

  final String rootId;
  final Map<String, dynamic> disclosure;

  @override
  State<SvedeniyaSectionPage> createState() => _SvedeniyaSectionPageState();
}

class _SvedeniyaSectionPageState extends State<SvedeniyaSectionPage> {
  Map<String, dynamic> _disclosure = const {};
  Map<String, dynamic> _upbringing = const {};
  Map<String, dynamic> _studentPortal = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _disclosure = _resolveDisclosure();
    _load();
  }

  Map<String, dynamic> _resolveDisclosure() {
    if (widget.disclosure.isNotEmpty) return widget.disclosure;
    return AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey) ?? const {};
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_disclosure.isEmpty) {
        final fresh = await AppContainer.eduDisclosureApi.getDisclosure();
        await AppContainer.jsonCache.setJson(EduDisclosureApi.cacheKey, fresh);
        _disclosure = fresh;
      }
      if (widget.rootId == 'vospitatelnaya-deyatelnost') {
        final cached = AppContainer.jsonCache.getJsonMap(UpbringingApi.cacheKey);
        if (cached != null) _upbringing = cached;
        final fresh = await AppContainer.upbringingApi.getUpbringing();
        await AppContainer.jsonCache.setJson(UpbringingApi.cacheKey, fresh);
        _upbringing = fresh;
      }
      if (widget.rootId == 'studentam') {
        _studentPortal = await AppContainer.studentServicesApi.studentPortal();
      }
    } catch (_) {
      _disclosure = _resolveDisclosure();
      _upbringing = AppContainer.jsonCache.getJsonMap(UpbringingApi.cacheKey) ?? const {};
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = EduDisclosureNav.rootById(widget.rootId);
    if (root == null) {
      return Scaffold(
        appBar: AppHeader(
          leading: appHeaderNestedBackLeading(context),
          headerTitle: Text('Раздел', style: appHeaderNestedTitleStyle),
        ),
        body: Center(child: Text('Раздел не найден', style: AppTextStyle.inter())),
      );
    }

    final merged = MergedSvedeniyaPayload.fromApi(_disclosure);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(root.title, style: appHeaderNestedTitleStyle),
      ),
      body: DecoratedBox(
        decoration: SvedeniyaPageStyle.background,
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: _load,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppUi.screenPaddingH,
                    AppUi.spacingL,
                    AppUi.screenPaddingH,
                    32,
                  ),
                  children: [
                    for (var i = 0; i < root.children.length; i++) ...[
                      _ContentBlock(
                        title: root.children[i].title,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: SvedeniyaContentBuilder(
                            rootId: widget.rootId,
                            childId: root.children[i].id,
                            merged: merged,
                            upbringing: _upbringing,
                            studentPortal: _studentPortal,
                          ).build(),
                        ),
                      ),
                      if (i != root.children.length - 1)
                        const SizedBox(height: AppUi.spacingXl),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Совместимость: старый маршрут с подразделом → якорь на объединённой странице.
class SvedeniyaContentPage extends StatelessWidget {
  const SvedeniyaContentPage({
    super.key,
    required this.rootId,
    required this.childId,
    this.disclosure = const {},
  });

  final String rootId;
  final String childId;
  final Map<String, dynamic> disclosure;

  @override
  Widget build(BuildContext context) {
    return SvedeniyaSectionPage(rootId: rootId, disclosure: disclosure);
  }
}

/// @deprecated Используйте [SvedeniyaSectionPage].
typedef SvedeniyaRootPage = SvedeniyaSectionPage;

class _HubSectionTile extends StatelessWidget {
  const _HubSectionTile({
    required this.root,
    required this.onTap,
    this.enabled = true,
  });

  final SvedeniyaRoot root;
  final VoidCallback onTap;
  final bool enabled;

  static IconData _iconFor(String id) {
    return switch (id) {
      'osnovnye-svedeniya' => Icons.apartment_outlined,
      'struktura' => Icons.account_tree_outlined,
      'dokumenty' => Icons.description_outlined,
      'obrazovanie' => Icons.school_outlined,
      'mto' => Icons.precision_manufacturing_outlined,
      'stipendii' => Icons.volunteer_activism_outlined,
      'biblioteka-i-sport' => Icons.local_library_outlined,
      'vospitatelnaya-deyatelnost' => Icons.groups_outlined,
      'nauchnaya-zhizn' => Icons.science_outlined,
      'pedagogam-resursy' => Icons.menu_book_outlined,
      'studentam' => Icons.person_outline,
      _ => Icons.folder_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppUi.radiusL),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUi.spacingL,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconFor(root.id),
                    color: enabled ? AppColors.lightBlue : AppColors.caption,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppUi.spacingM),
                Expanded(
                  child: Text(
                    root.title,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: enabled ? AppColors.textPrimary : AppColors.caption,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    enabled ? AppColors.chevronRight : AppColors.lightGrey,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentBlock extends StatelessWidget {
  const _ContentBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppUi.spacingM),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUi.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppUi.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppUi.radiusL),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

typedef ApplicantDisclosurePage = SvedeniyaHubPage;
