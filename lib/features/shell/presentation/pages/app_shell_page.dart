import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../home/presentation/widgets/home_header_title.dart';

/// Оболочка главного экрана: один AppBar, нижняя навигация, контент с отдельным
/// Navigator для каждой вкладки (StatefulShellRoute — без дублирования GlobalKey).
class AppShellPage extends StatelessWidget {
  const AppShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const double _minWidthForTitle = 240;

  static TextStyle _headerTitleStyle(BuildContext context) {
    return Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle();
  }

  Widget _titleForIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        return const HomeHeaderTitle();
      case 1:
        final style = _headerTitleStyle(context);
        return Text('Успеваемость', style: style);
      case 2:
        final style = _headerTitleStyle(context);
        return Text('Новости', style: style);
      case 3:
        final style = _headerTitleStyle(context);
        return Text('Профиль', style: style);
      default:
        return const SizedBox.shrink();
    }
  }

  static const Color _selectedColor = AppColors.primaryBlue;
  static Color _unselectedColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  Widget _navIcon(BuildContext context, String assetPath, bool selected) {
    return SvgPicture.asset(
      assetPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        selected ? _selectedColor : _unselectedColor(context),
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final width = MediaQuery.sizeOf(context).width;
    final showTitle = width >= _minWidthForTitle;

    return Scaffold(
      appBar: AppHeader(
        headerTitle: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: SizedBox(
            key: ValueKey<int>(index),
            child: showTitle
                ? _titleForIndex(context, index)
                : Image.asset(
                    'assets/images/logo_icon.png',
                    height: 38,
                    width: 38,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _selectedColor,
            onSurface: _unselectedColor(context),
          ),
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _selectedColor : _unselectedColor(context),
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (int i) => navigationShell.goBranch(i),
          destinations: [
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/home_icon.svg', index == 0),
              selectedIcon: _navIcon(context, 'assets/icons/home_filled_icon.svg', true),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/grades_icon.svg', index == 1),
              selectedIcon: _navIcon(context, 'assets/icons/grades_filled_icon.svg', true),
              label: 'Оценки',
            ),
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/news_icon.svg', index == 2),
              selectedIcon: _navIcon(context, 'assets/icons/news_filled_icon.svg', true),
              label: 'Новости',
            ),
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/profile_icon.svg', index == 3),
              selectedIcon: _navIcon(context, 'assets/icons/profile_filled_icon.svg', true),
              label: 'Профиль',
            ),
          ],
          indicatorColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    );
  }
}
