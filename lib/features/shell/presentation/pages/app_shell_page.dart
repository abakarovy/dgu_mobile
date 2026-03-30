import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/navigation/nav_bar_edit_host.dart';
import '../../../../features/home/presentation/widgets/home_header_title.dart';
import '../../../../core/network/app_network_banner_controller.dart';
import '../../../../core/preferences/nav_bar_order_prefs.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';

/// Оболочка главного экрана: AppBar, нижняя навигация, контент.
///
/// Четыре боковые вкладки можно **переставить**: долгое нажатие на боковую вкладку
/// (кроме «Главной») или пункт «Настроить нижнее меню» в профиле, затем два нажатия по вкладкам — обмен местами.
class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _BranchMeta {
  const _BranchMeta({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
  });

  final String outlineIcon;
  final String filledIcon;
  final String label;
}

class _AppShellPageState extends State<AppShellPage> {
  static const int _indexProfile = 0;
  static const int _indexGrades = 1;
  static const int _indexHome = 2;
  static const int _indexNews = 3;
  static const int _indexEvents = 4;

  static const Color _selectedColor = AppColors.primaryBlue;
  static const double _navLabelFontSize = 10;
  static const double _navIconToLabelGap = 3;
  static const double _sideIconSize = 24;
  static const double _homeIconSlotHeight = 30;
  static const double _homeFabDiameter = 70;
  static const double _homeIconInnerSize = 40;
  static const double _homeBottomReserve = 4 + 11;

  /// Рамка вокруг слота в режиме правки — компактнее, чем полная ширина [Expanded].
  static const EdgeInsets _editSlotFramePadding =
      EdgeInsets.symmetric(horizontal: 2, vertical: 0);

  late List<int> _movableOrder;
  bool _navEditMode = false;
  /// В режиме правки: выбранный слот (0..3) для обмена по второму нажатию.
  int? _selectedSlotForSwap;

  StatefulNavigationShell get _shell => widget.navigationShell;

  static Color _unselectedColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  static int _branchIndexFromPath(String path, StatefulNavigationShell shell) {
    if (path.startsWith('/app/profile')) return _indexProfile;
    if (path.startsWith('/app/grades')) return _indexGrades;
    if (path.startsWith('/app/home')) return _indexHome;
    if (path.startsWith('/app/news')) return _indexNews;
    if (path.startsWith('/app/events')) return _indexEvents;
    return shell.currentIndex;
  }

  static _BranchMeta _metaForBranch(int branchIndex) {
    switch (branchIndex) {
      case _indexProfile:
        return const _BranchMeta(
          outlineIcon: 'assets/icons/profile_icon.svg',
          filledIcon: 'assets/icons/profile_filled_icon.svg',
          label: 'Профиль',
        );
      case _indexGrades:
        return const _BranchMeta(
          outlineIcon: 'assets/icons/grades_icon.svg',
          filledIcon: 'assets/icons/grades_filled_icon.svg',
          label: 'Оценки',
        );
      case _indexNews:
        return const _BranchMeta(
          outlineIcon: 'assets/icons/news_icon.svg',
          filledIcon: 'assets/icons/news_filled_icon.svg',
          label: 'Новости',
        );
      case _indexEvents:
        return const _BranchMeta(
          outlineIcon: 'assets/icons/events.svg',
          filledIcon: 'assets/icons/events_filed.svg',
          label: 'Мероприятия',
        );
      default:
        return const _BranchMeta(
          outlineIcon: 'assets/icons/profile_icon.svg',
          filledIcon: 'assets/icons/profile_filled_icon.svg',
          label: '',
        );
    }
  }

  @override
  void initState() {
    super.initState();
    AppNetworkBannerController.instance.startConnectivityListener();
    NavBarEditHost.register(_openNavEditMode);
    _movableOrder = List<int>.from(NavBarOrderPrefs.defaultOrder);
    NavBarOrderPrefs.load().then((o) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _movableOrder = o);
      });
    });
  }

  @override
  void dispose() {
    NavBarEditHost.clear();
    super.dispose();
  }

  void _openNavEditMode() {
    if (!mounted) return;
    setState(() {
      _navEditMode = true;
      _selectedSlotForSwap = null;
    });
    HapticFeedback.mediumImpact();
  }

  void _exitEditMode() {
    if (!_navEditMode) return;
    setState(() {
      _navEditMode = false;
      _selectedSlotForSwap = null;
    });
  }

  void _onSideSlotTapInEditMode(int slotIndex) {
    final selected = _selectedSlotForSwap;
    if (selected == null) {
      setState(() => _selectedSlotForSwap = slotIndex);
      return;
    }
    if (selected == slotIndex) {
      setState(() => _selectedSlotForSwap = null);
      return;
    }
    setState(() {
      final t = _movableOrder[selected];
      _movableOrder[selected] = _movableOrder[slotIndex];
      _movableOrder[slotIndex] = t;
      _selectedSlotForSwap = null;
    });
    NavBarOrderPrefs.save(_movableOrder);
  }

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

  Widget _sideSlotContent(
    BuildContext context, {
    required int branchIndex,
    required int currentBranchIndex,
  }) {
    final meta = _metaForBranch(branchIndex);
    final selected = currentBranchIndex == branchIndex;
    final color = selected ? _selectedColor : _unselectedColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _navIcon(
            context,
            selected ? meta.filledIcon : meta.outlineIcon,
            selected,
          ),
          SizedBox(height: _navIconToLabelGap),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                meta.label,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _navLabelFontSize,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.0,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movableSlot(
    BuildContext context,
    int slotIndex,
    int currentBranchIndex,
  ) {
    final branchIndex = _movableOrder[slotIndex];

    Widget inner = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navEditMode
            ? () => _onSideSlotTapInEditMode(slotIndex)
            : () => _shell.goBranch(branchIndex),
        onLongPress: _navEditMode ? null : _openNavEditMode,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: _sideSlotContent(
          context,
          branchIndex: branchIndex,
          currentBranchIndex: currentBranchIndex,
        ),
      ),
    );

    if (_navEditMode) {
      final isArmed = _selectedSlotForSwap == slotIndex;
      inner = Padding(
        padding: _editSlotFramePadding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isArmed
                  ? AppColors.primaryBlue
                  : AppColors.lightGrey.withValues(alpha: 0.5),
              width: isArmed ? 1.5 : 1,
            ),
          ),
          child: inner,
        ),
      );
    }

    return Expanded(child: inner);
  }

  Widget _homeDestination(BuildContext context, {required int currentBranchIndex}) {
    final selected = currentBranchIndex == _indexHome;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.none,
        child: InkWell(
          onTap: () {
            if (_navEditMode) {
              _exitEditMode();
            } else {
              _shell.goBranch(_indexHome);
            }
          },
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

  /// Заголовок AppBar: на «Главной» — логотип + «Колледж ДГУ», на остальных вкладках — логотип + название раздела.
  Widget _shellAppBarTitle(int branchIndex) {
    if (branchIndex == _indexHome) {
      return const HomeHeaderTitle();
    }
    final meta = _metaForBranch(branchIndex);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/logo.svg',
          height: AppUi.appBarIconSize,
          width: AppUi.appBarIconSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppUi.spacingS),
        Text(
          meta.label,
          style: AppTextStyle.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0.35, 0),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editModeBanner() {
    return Material(
      color: AppColors.backgroundBlue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Нажмите одну вкладку, затем другую, чтобы поменять местами',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
              ),
            ),
            TextButton(
              onPressed: _exitEditMode,
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final branchIndex = _branchIndexFromPath(path, _shell);
    final isNotificationsScreen = path.endsWith('notifications');
    final isSupportScreen = path.endsWith('support');
    final isStudentIdScreen = path.endsWith('student-id');
    final hideShellAppBar = isNotificationsScreen ||
        isSupportScreen ||
        isStudentIdScreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            appBar: hideShellAppBar
                ? null
                : AppHeader(
                    headerTitle: _shellAppBarTitle(branchIndex),
                  ),
            body: widget.navigationShell,
            bottomNavigationBar: Material(
              color: Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              clipBehavior: Clip.none,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_navEditMode) _editModeBanner(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _movableSlot(context, 0, branchIndex),
                          _movableSlot(context, 1, branchIndex),
                          _homeDestination(context, currentBranchIndex: branchIndex),
                          _movableSlot(context, 2, branchIndex),
                          _movableSlot(context, 3, branchIndex),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
