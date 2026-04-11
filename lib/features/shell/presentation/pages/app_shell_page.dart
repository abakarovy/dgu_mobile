import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_overlay_notifier.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/navigation/home_refresh_host.dart';
import '../../../../core/navigation/news_header_host.dart';
import '../../../../core/navigation/news_refresh_host.dart';
import '../../../../features/home/presentation/widgets/home_header_title.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';

/// Оболочка главного экрана: AppBar, нижняя навигация, контент.
class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  static const int _indexProfile = 0;
  static const int _indexGrades = 1;
  static const int _indexHome = 2;
  static const int _indexNews = 3;

  static const double _navBarHeight = 67;
  static const double _navIconSize = 22;
  static const double _navIconToLabelGap = 4;
  static const double _navLabelFontSize = 8.89;

  static const Color _navSelectedColor = Color(0xFF2563EB);
  static const Color _navUnselectedColor = Color(0xFF64748B);

  StatefulNavigationShell get _shell => widget.navigationShell;

  static int _branchIndexFromPath(String path, StatefulNavigationShell shell) {
    if (path.startsWith('/app/profile')) return _indexProfile;
    if (path.startsWith('/app/grades')) return _indexGrades;
    if (path.startsWith('/app/home')) return _indexHome;
    if (path.startsWith('/app/news')) return _indexNews;
    return shell.currentIndex;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final branchIndex = _branchIndexFromPath(path, _shell);
    final isNotificationsScreen = path.endsWith('notifications');
    final isSupportScreen = path.endsWith('support');
    final isStudentIdScreen = path.endsWith('student-id');
    final isSettingsScreen = path.endsWith('settings');
    final isAbsencesScreen = path.endsWith('absences');
    final hideShellAppBar = isNotificationsScreen ||
        isSupportScreen ||
        isStudentIdScreen ||
        isSettingsScreen ||
        isAbsencesScreen;

    /// Без нижнего меню: полноэкранные вложенные экраны профиля и поддержка.
    final hideShellBottomNavBase = isSettingsScreen ||
        isAbsencesScreen ||
        isStudentIdScreen ||
        isSupportScreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: AppOverlayNotifier.modalBottomSheetDepth,
            builder: (context, sheetDepth, _) {
              final hideShellBottomNav =
                  hideShellBottomNavBase || sheetDepth > 0;
              return Scaffold(
            appBar: hideShellAppBar
                ? null
                : AppHeader(
                    headerTitle: switch (branchIndex) {
                      _indexHome => const HomeHeaderTitle(),
                      _indexGrades => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/nav_grades.svg',
                              width: _navIconSize,
                              height: _navIconSize,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF000000),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Оценки',
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.44,
                                height: 1.0,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ],
                        ),
                      _indexNews => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/nav_news.svg',
                              width: _navIconSize,
                              height: _navIconSize,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF000000),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ValueListenableBuilder<String>(
                              valueListenable: NewsHeaderHost.title,
                              builder: (context, value, _) {
                                return Text(
                                  value,
                                  style: AppTextStyle.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.44,
                                    height: 1.0,
                                    color: const Color(0xFF000000),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      _indexProfile => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/nav_profile.svg',
                              width: _navIconSize,
                              height: _navIconSize,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF000000),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Профиль',
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.44,
                                height: 1.0,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ],
                        ),
                      _ => const SizedBox.shrink(),
                    },
                    actions: branchIndex == _indexProfile
                        ? [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child:                             IconButton(
                                onPressed: () {
                                  context.push('/app/profile/settings');
                                },
                                icon: SvgPicture.asset(
                                  'assets/icons/settings.svg',
                                  width: 25,
                                  height: 25,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF000000),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ]
                        : null,
                  ),
            body: widget.navigationShell,
            bottomNavigationBar: hideShellBottomNav
                ? null
                : Material(
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    clipBehavior: Clip.none,
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: _navBarHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: _navItem(
                                selected: branchIndex == _indexHome,
                                iconAsset: 'assets/icons/nav_home.svg',
                                label: 'Главная',
                                onTap: () {
                                  _shell.goBranch(_indexHome);
                                  HomeRefreshHost.requestRefresh(force: false);
                                },
                              ),
                            ),
                            Expanded(
                              child: _navItem(
                                selected: branchIndex == _indexGrades,
                                iconAsset: 'assets/icons/nav_grades.svg',
                                label: 'Оценки',
                                onTap: () => _shell.goBranch(_indexGrades),
                              ),
                            ),
                            Expanded(
                              child: _navItem(
                                selected: branchIndex == _indexNews,
                                iconAsset: 'assets/icons/nav_news.svg',
                                label: 'Новости',
                                onTap: () {
                                  _shell.goBranch(_indexNews);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    NewsRefreshHost.requestRefresh();
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _navItem(
                                selected: branchIndex == _indexProfile,
                                iconAsset: 'assets/icons/nav_profile.svg',
                                label: 'Профиль',
                                onTap: () => _shell.goBranch(_indexProfile),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          );
            },
          ),
        ),
      ],
    );
  }

  Widget _navItem({
    required bool selected,
    required String iconAsset,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = selected ? _navSelectedColor : _navUnselectedColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: _navIconSize,
              height: _navIconSize,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: _navIconToLabelGap),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: _navLabelFontSize,
                height: 1.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
