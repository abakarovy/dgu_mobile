import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../home/presentation/widgets/home_header_title.dart';

/// Оболочка главного экрана: один AppBar, нижняя навигация, контент с отдельным
/// Navigator для каждой вкладки (StatefulShellRoute — без дублирования GlobalKey).
///
/// Нижняя панель: Профиль → Оценки → Главная (центр, крупнее) → Новости → Мероприятия.
class AppShellPage extends StatelessWidget {
  const AppShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static TextStyle _headerTitleStyle(BuildContext context) {
    return Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle();
  }

  static const int _indexProfile = 0;
  static const int _indexGrades = 1;
  static const int _indexHome = 2;
  static const int _indexNews = 3;
  static const int _indexEvents = 4;

  /// Индекс вкладки по URI: совпадает с маршрутом сразу при переключении.
  /// [navigationShell.currentIndex] отстаёт на кадр(ы) — из‑за этого заголовок AppBar «мигал» старым текстом.
  static int _branchIndexFromPath(String path, StatefulNavigationShell shell) {
    if (path.startsWith('/app/profile')) return _indexProfile;
    if (path.startsWith('/app/grades')) return _indexGrades;
    if (path.startsWith('/app/home')) return _indexHome;
    if (path.startsWith('/app/news')) return _indexNews;
    if (path.startsWith('/app/events')) return _indexEvents;
    return shell.currentIndex;
  }

  Widget _titleForIndex(BuildContext context, int index) {
    switch (index) {
      case _indexProfile:
        final style = _headerTitleStyle(context);
        return Text('Профиль', style: style);
      case _indexGrades:
        final style = _headerTitleStyle(context);
        return Text('Оценки', style: style);
      case _indexHome:
        return const HomeHeaderTitle();
      case _indexNews:
        final style = _headerTitleStyle(context);
        return Text('Новости', style: style);
      case _indexEvents:
        final style = _headerTitleStyle(context);
        return Text('Мероприятия', style: style);
      default:
        return const SizedBox.shrink();
    }
  }

  static const Color _selectedColor = AppColors.primaryBlue;
  static Color _unselectedColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  static const double _sideIconSize = 24;
  static const double _homeIconSize = 30;

  Widget _navIcon(
    BuildContext context,
    String assetPath,
    bool selected, {
    double size = _sideIconSize,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        selected ? _selectedColor : _unselectedColor(context),
        BlendMode.srcIn,
      ),
    );
  }

  Widget _sideDestination(
    BuildContext context, {
    required int branchIndex,
    required String outlineIcon,
    required String filledIcon,
    required String label,
    required int currentBranchIndex,
  }) {
    final selected = currentBranchIndex == branchIndex;
    final color = selected ? _selectedColor : _unselectedColor(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigationShell.goBranch(branchIndex),
          borderRadius: BorderRadius.circular(12),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _navIcon(
                  context,
                  selected ? filledIcon : outlineIcon,
                  selected,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.0,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _homeDestination(BuildContext context, {required int currentBranchIndex}) {
    final selected = currentBranchIndex == _indexHome;
    final color = selected ? _selectedColor : _unselectedColor(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigationShell.goBranch(_indexHome),
          borderRadius: BorderRadius.circular(28),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryBlue.withValues(alpha: 0.14)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: _navIcon(
                    context,
                    selected
                        ? 'assets/icons/home_filled_icon.svg'
                        : 'assets/icons/home_icon.svg',
                    selected,
                    size: _homeIconSize,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Главная',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.0,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final branchIndex = _branchIndexFromPath(path, navigationShell);
    final width = MediaQuery.sizeOf(context).width;
    final showTitle = width >= AppUi.shellMinWidthForTitle;
    final isNotificationsScreen = path.endsWith('notifications');
    final isSupportScreen = path.endsWith('support');
    final isStudentIdScreen = path.endsWith('student-id');
    final hideShellAppBar = isNotificationsScreen || isSupportScreen || isStudentIdScreen;

    return Scaffold(
      appBar: hideShellAppBar
          ? null
          : AppHeader(
              headerTitle: showTitle
                  ? _titleForIndex(context, branchIndex)
                  : Image.asset(
                      'assets/images/logo_icon.png',
                      height: AppUi.appBarIconSize,
                      width: AppUi.appBarIconSize,
                      fit: BoxFit.contain,
                    ),
            ),
      body: navigationShell,
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sideDestination(
                  context,
                  branchIndex: _indexProfile,
                  outlineIcon: 'assets/icons/profile_icon.svg',
                  filledIcon: 'assets/icons/profile_filled_icon.svg',
                  label: 'Профиль',
                  currentBranchIndex: branchIndex,
                ),
                _sideDestination(
                  context,
                  branchIndex: _indexGrades,
                  outlineIcon: 'assets/icons/grades_icon.svg',
                  filledIcon: 'assets/icons/grades_filled_icon.svg',
                  label: 'Оценки',
                  currentBranchIndex: branchIndex,
                ),
                _homeDestination(context, currentBranchIndex: branchIndex),
                _sideDestination(
                  context,
                  branchIndex: _indexNews,
                  outlineIcon: 'assets/icons/news_icon.svg',
                  filledIcon: 'assets/icons/news_filled_icon.svg',
                  label: 'Новости',
                  currentBranchIndex: branchIndex,
                ),
                _sideDestination(
                  context,
                  branchIndex: _indexEvents,
                  outlineIcon: 'assets/icons/news_icon.svg',
                  filledIcon: 'assets/icons/news_filled_icon.svg',
                  label: 'Мероприятия',
                  currentBranchIndex: branchIndex,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
