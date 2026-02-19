import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../home/presentation/widgets/home_header_title.dart';

/// Оболочка главного экрана: один AppBar, нижняя навигация, контент с плавной сменой.
class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  static const String _pathHome = '/app/home';
  static const String _pathGrades = '/app/grades';
  static const String _pathNews = '/app/news';
  static const String _pathProfile = '/app/profile';

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(_pathGrades)) return 1;
    if (path.startsWith(_pathNews)) return 2;
    if (path.startsWith(_pathProfile)) return 3;
    return 0;
  }

  Widget _titleForPath(String path) {
    if (path.startsWith(_pathHome)) return const HomeHeaderTitle();
    if (path.startsWith(_pathGrades)) return const Text('Оценки');
    if (path.startsWith(_pathNews)) return const Text('Новости');
    if (path.startsWith(_pathProfile)) return const Text('Профиль');
    return const SizedBox.shrink();
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(_pathHome);
        break;
      case 1:
        context.go(_pathGrades);
        break;
      case 2:
        context.go(_pathNews);
        break;
      case 3:
        context.go(_pathProfile);
        break;
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
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      appBar: AppHeader(
        headerTitle: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey<String>(path),
            child: _titleForPath(path),
          ),
        ),
      ),
      body: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey<String>(path),
            child: widget.child,
          ),
        ),
      ),
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
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onTap(context, index),
          destinations: [
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/home_icon.svg', selectedIndex == 0),
              selectedIcon: _navIcon(context, 'assets/icons/home_filled_icon.svg', true),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/grades_icon.svg', selectedIndex == 1),
              selectedIcon: _navIcon(context, 'assets/icons/grades_filled_icon.svg', true),
              label: 'Оценки',
            ),
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/news_icon.svg', selectedIndex == 2),
              selectedIcon: _navIcon(context, 'assets/icons/news_filled_icon.svg', true),
              label: 'Новости',
            ),
            NavigationDestination(
              icon: _navIcon(context, 'assets/icons/profile_icon.svg', selectedIndex == 3),
              selectedIcon: _navIcon(context, 'assets/icons/profile_filled_icon.svg', true),
              label: 'Профиль',
            ),
          ],
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    );
  }
}
