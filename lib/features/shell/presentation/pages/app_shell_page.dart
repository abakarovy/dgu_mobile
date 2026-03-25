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
/// Нижняя панель: Профиль → Оценки → Главная (центр, круг без подписи) → Новости → Мероприятия.
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
  /// Слот по layout (как у ряда иконок); сам круг больше и рисуется через [OverflowBox].
  static const double _homeIconSlotHeight = 30;
  static const double _homeFabDiameter = 70; // было 42 → ×3
  static const double _homeIconInnerSize = 40; // было 26 → ×2
  /// Как у боковых: зазор + высота строки подписи (подписи у «Главной» нет — оставляем место).
  static const double _homeBottomReserve = 4 + 11;

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
    return Expanded(
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.none,
        child: InkWell(
          onTap: () => navigationShell.goBranch(_indexHome),
          customBorder: const CircleBorder(),
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
                SizedBox(
                  height: _homeIconSlotHeight,
                  width: double.infinity,
                  child: OverflowBox(
                    maxWidth: _homeFabDiameter,
                    minWidth: _homeFabDiameter,
                    maxHeight: _homeFabDiameter,
                    minHeight: _homeFabDiameter,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: _homeFabDiameter,
                      height: _homeFabDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.backgroundBlue
                            : AppColors.surfaceLight,
                      ),
                      child: Center(
                        child: _navIcon(
                          context,
                          selected
                              ? 'assets/icons/home_filled_icon.svg'
                              : 'assets/icons/home_icon.svg',
                          selected,
                          size: _homeIconInnerSize,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _homeBottomReserve),
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
        clipBehavior: Clip.none,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
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
