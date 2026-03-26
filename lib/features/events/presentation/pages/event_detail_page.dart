import 'dart:ui';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../data/event_item.dart';

/// Экран детали мероприятия — по паттерну детали новости: без AppBar, картинка сверху и кнопка «назад».
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.item});

  final EventItem item;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final paddingH = width > 0
        ? (AppUi.screenPaddingH * width / 448).clamp(16.0, 32.0)
        : AppUi.screenPaddingH;
    final imageHeight = width > 0
        ? (AppUi.newsDetailImageHeight * width / 448).clamp(200.0, 400.0)
        : AppUi.newsDetailImageHeight;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: Image.asset(
                    item.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.backgroundSecondary,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppColors.caption,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: paddingH,
                  top: paddingH,
                  child: _BackButton(size: AppUi.newsDetailBackButtonSize),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(paddingH, 0, paddingH, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppUi.spacingXl),
                _CategoryRow(category: item.category),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    height: 33 / 30,
                    color: AppColors.newsDetailTitle,
                  ),
                ),
                const SizedBox(height: 16),
                _MetaRow(dateRange: item.dateRange, location: item.location),
                const SizedBox(height: 24),
                Text(
                  item.description,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 26 / 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppUi.newsDetailBackBlurSigma,
          sigmaY: AppUi.newsDetailBackBlurSigma,
        ),
        child: Material(
          color: const Color(0x33000000),
          child: InkWell(
            onTap: () => context.pop(),
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: AppUi.newsDetailBackIconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Text(
      category.toUpperCase(),
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w700,
        fontSize: 10,
        height: 1.0,
        letterSpacing: 1,
        color: AppColors.primaryBlue,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.dateRange, required this.location});

  final String dateRange;
  final String location;

  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/calendar.svg',
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(_accentGreen, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              dateRange.toUpperCase(),
              style: AppTextStyle.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 15 / 10,
                letterSpacing: 0.5,
                color: _muted,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/location.svg',
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(_accentGreen, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              location.toUpperCase(),
              style: AppTextStyle.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 15 / 10,
                letterSpacing: 0.5,
                color: _muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

