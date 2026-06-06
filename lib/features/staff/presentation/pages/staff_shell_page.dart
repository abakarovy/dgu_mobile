import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_overlay_notifier.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';

/// Оболочка ЛК сотрудника — как у студента: AppHeader + нижняя навигация.
class StaffShellPage extends StatefulWidget {
  const StaffShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<StaffShellPage> createState() => _StaffShellPageState();
}

class _StaffShellPageState extends State<StaffShellPage> {
  static const int _indexProfile = 0;
  static const int _indexUsers = 1;
  static const int _indexHome = 2;
  static const int _indexTools = 3;

  static const double _navBarHeight = 67;
  static const double _navIconSize = 22;
  static const double _navIconToLabelGap = 4;
  static const double _navLabelFontSize = 8.89;

  static const Color _navSelectedColor = Color(0xFF2563EB);
  static const Color _navUnselectedColor = Color(0xFF64748B);

  StatefulNavigationShell get _shell => widget.navigationShell;

  void _goTabRoot(int branchIndex) {
    final location = switch (branchIndex) {
      _indexProfile => '/staff/profile',
      _indexUsers => '/staff/users',
      _indexHome => '/staff/home',
      _indexTools => '/staff/tools',
      _ => '/staff/home',
    };
    context.go(location);
  }

  bool _isNestedStaffRoute(String path) {
    return path.startsWith('/staff/admission') ||
        path.startsWith('/staff/events') ||
        path.startsWith('/staff/mobile-release') ||
        path.startsWith('/staff/department') ||
        path.startsWith('/staff/journal') ||
        path.startsWith('/staff/dashboard') ||
        path.startsWith('/staff/news') ||
        path.startsWith('/staff/groups') ||
        path.startsWith('/staff/moderation') ||
        path.startsWith('/staff/weekly-grades') ||
        path.startsWith('/staff/scholarship-rating') ||
        path.startsWith('/staff/settings-admin') ||
        path.startsWith('/staff/edu-disclosure') ||
        path.startsWith('/staff/web') ||
        path.startsWith('/staff/module') ||
        path.endsWith('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final branchIndex = _shell.currentIndex;
    final isSettingsScreen = path.endsWith('/settings');
    final hideShellAppBar = isSettingsScreen || branchIndex == _indexHome;
    final hideShellBottomNavBase = isSettingsScreen || _isNestedStaffRoute(path);

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
                          _indexHome => Text(
                              'Дашборд',
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.44,
                                height: 1.0,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          _indexUsers => _navTitle(
                              'Пользователи',
                              iconAsset: 'assets/icons/users.svg',
                            ),
                          _indexTools => _navTitle(
                              'Инструменты',
                              iconAsset: 'assets/icons/tools.svg',
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
                        actions: branchIndex == _indexProfile
                            ? [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    onPressed: () {
                                      context.push('/staff/profile/settings');
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
                                    label: 'Дашборд',
                                    onTap: () => _goTabRoot(_indexHome),
                                  ),
                                ),
                                Expanded(
                                  child: _navItem(
                                    selected: branchIndex == _indexUsers,
                                    iconAsset: 'assets/icons/users.svg',
                                    label: 'Пользователи',
                                    onTap: () => _goTabRoot(_indexUsers),
                                  ),
                                ),
                                Expanded(
                                  child: _navItem(
                                    selected: branchIndex == _indexTools,
                                    iconAsset: 'assets/icons/tools.svg',
                                    label: 'Инструменты',
                                    onTap: () => _goTabRoot(_indexTools),
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

  Widget _navTitle(
    String label, {
    String? iconAsset,
    IconData? icon,
  }) {
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
