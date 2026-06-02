import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/news_header_host.dart';
import '../../../../core/navigation/news_refresh_host.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/home/presentation/widgets/home_header_title.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';

/// Оболочка гостевого режима: главная, новости, профиль (без оценок и журнала).
class PublicShellPage extends StatelessWidget {
  const PublicShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int _indexHome = 0;
  static const int _indexNews = 1;
  static const int _indexProfile = 2;

  static const double _navBarHeight = 67;
  static const double _navIconSize = 22;
  static const double _navIconToLabelGap = 4;
  static const double _navLabelFontSize = 8.89;
  static const Color _navSelectedColor = Color(0xFF2563EB);
  static const Color _navUnselectedColor = Color(0xFF64748B);

  int _branchIndexFromPath(String path) {
    if (path.startsWith('/public/news')) return _indexNews;
    if (path.startsWith('/public/profile')) return _indexProfile;
    return _indexHome;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final branchIndex = _branchIndexFromPath(path);
    final hideShellAppBar = path.startsWith('/public/home/svedeniya');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            appBar: hideShellAppBar
                ? null
                : AppHeader(
                    headerTitle: switch (branchIndex) {
                      _indexHome => const HomeHeaderTitle(),
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
                              'Вход',
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.44,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ],
                        ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
            body: navigationShell,
            bottomNavigationBar: hideShellAppBar
                ? null
                : Material(
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
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
                                onTap: () => navigationShell.goBranch(_indexHome),
                              ),
                            ),
                            Expanded(
                              child: _navItem(
                                selected: branchIndex == _indexNews,
                                iconAsset: 'assets/icons/nav_news.svg',
                                label: 'Новости',
                                onTap: () {
                                  navigationShell.goBranch(_indexNews);
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
                                onTap: () => navigationShell.goBranch(_indexProfile),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: _navLabelFontSize,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
