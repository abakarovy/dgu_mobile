import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_overlay_notifier.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';

/// Оболочка кабинета зав. отделением — 4 вкладки.
class DepartmentShellPage extends StatefulWidget {
  const DepartmentShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<DepartmentShellPage> createState() => _DepartmentShellPageState();
}

class _DepartmentShellPageState extends State<DepartmentShellPage> {
  static const int _indexOverview = 0;
  static const int _indexCurators = 1;
  static const int _indexAnnouncements = 2;
  static const int _indexProfile = 3;

  static const double _navBarHeight = 67;
  static const double _navIconSize = 22;
  static const double _navIconToLabelGap = 4;
  static const double _navLabelFontSize = 8.89;

  static const Color _navSelectedColor = Color(0xFF2563EB);
  static const Color _navUnselectedColor = Color(0xFF64748B);

  StatefulNavigationShell get _shell => widget.navigationShell;

  void _goTabRoot(int branchIndex) {
    final location = switch (branchIndex) {
      _indexOverview => '/department/home',
      _indexCurators => '/department/curators',
      _indexAnnouncements => '/department/announcements',
      _indexProfile => '/department/profile',
      _ => '/department/home',
    };
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final branchIndex = _shell.currentIndex;
    final isSettingsScreen = path.endsWith('/settings');
    final hideShellAppBar = isSettingsScreen;
    final hideShellBottomNavBase = isSettingsScreen;

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
                          _indexOverview => _navTitle(
                              'Главная',
                              iconAsset: 'assets/icons/nav_home.svg',
                            ),
                          _indexCurators => _navTitle(
                              'Кураторы',
                              iconAsset: 'assets/icons/users.svg',
                            ),
                          _indexAnnouncements => _navTitle(
                              'Объявления',
                              iconAsset: 'assets/icons/rupor.svg',
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
                        showNotificationIcon: false,
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
                                    selected: branchIndex == _indexOverview,
                                    iconAsset: 'assets/icons/nav_home.svg',
                                    label: 'Главная',
                                    onTap: () => _goTabRoot(_indexOverview),
                                  ),
                                ),
                                Expanded(
                                  child: _navItem(
                                    selected: branchIndex == _indexCurators,
                                    iconAsset: 'assets/icons/users.svg',
                                    label: 'Кураторы',
                                    onTap: () => _goTabRoot(_indexCurators),
                                  ),
                                ),
                                Expanded(
                                  child: _navItem(
                                    selected: branchIndex == _indexAnnouncements,
                                    iconAsset: 'assets/icons/rupor.svg',
                                    label: 'Объявления',
                                    onTap: () => _goTabRoot(_indexAnnouncements),
                                  ),
                                ),
                                Expanded(
                                  child: _navItem(
                                    selected: branchIndex == _indexProfile,
                                    iconAsset: 'assets/icons/nav_profile.svg',
                                    label: 'Профиль',
                                    onTap: () => _goTabRoot(_indexProfile),
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

  Widget _navTitle(String label, {String? iconAsset, IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconAsset != null)
          SvgPicture.asset(
            iconAsset,
            width: _navIconSize,
            height: _navIconSize,
            colorFilter: const ColorFilter.mode(
              Color(0xFF000000),
              BlendMode.srcIn,
            ),
          )
        else if (icon != null)
          Icon(icon, size: _navIconSize, color: const Color(0xFF000000)),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14.44,
            height: 1.0,
            color: const Color(0xFF000000),
          ),
        ),
      ],
    );
  }

  Widget _navItem({
    required bool selected,
    String? iconAsset,
    IconData? icon,
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
            if (iconAsset != null)
              SvgPicture.asset(
                iconAsset,
                width: _navIconSize,
                height: _navIconSize,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              )
            else
              Icon(icon, size: _navIconSize, color: color),
            const SizedBox(height: _navIconToLabelGap),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
