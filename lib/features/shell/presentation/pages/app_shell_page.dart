import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Оболочка главного экрана с нижней навигацией (Home, Grades, News, Profile).
/// При переключении вкладок контент анимируется слайдом влево/вправо.
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

  int _previousIndex = 0;
  double _slideDirection = 1.0; // 1 = new from right, -1 = new from left

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(_pathGrades)) return 1;
    if (path.startsWith(_pathNews)) return 2;
    if (path.startsWith(_pathProfile)) return 3;
    return 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = _selectedIndex(context);
    if (current != _previousIndex) {
      _slideDirection = current > _previousIndex ? 1.0 : -1.0;
      _previousIndex = current;
    }
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

  static const Color _selectedColor = Color(0xFF1A4B8E);
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_slideDirection, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<String>(path),
          child: widget.child,
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
