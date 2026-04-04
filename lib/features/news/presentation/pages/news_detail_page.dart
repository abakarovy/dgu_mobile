import 'dart:ui';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/news_model.dart';

Widget _newsDetailImage(String? rawUrl, double imageHeight) {
  final placeholder = Container(
    color: AppColors.backgroundSecondary,
    child: const Icon(Icons.image_outlined, size: 48, color: AppColors.caption),
  );
  final asset = NewsModel.bundleAssetPath(rawUrl);
  if (asset != null) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: imageHeight,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
  final url = NewsModel.resolveImageUrl(rawUrl);
  if (url != null && url.isNotEmpty) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: imageHeight,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
  return placeholder;
}

/// Экран детали новости: без аппбара, картинка 320, стрелка назад в круге, категория, дата, заголовок, текст.
class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key, required this.item});

  final NewsModel item;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeTop = MediaQuery.paddingOf(context).top;
    final paddingH = width > 0 ? (AppUi.screenPaddingH * width / 448).clamp(16.0, 32.0) : AppUi.screenPaddingH;
    final imageHeight = width > 0 ? (AppUi.newsDetailImageHeight * width / 448).clamp(200.0, 400.0) : AppUi.newsDetailImageHeight;

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
                  child: _newsDetailImage(item.imageUrl, imageHeight),
                ),
                Positioned(
                  left: paddingH,
                  top: safeTop + paddingH,
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
                _CategoryAndDate(
                  category: 'Новости',
                  date: item.createdAt.toIso8601String().split('T').first,
                ),
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
                const SizedBox(height: 24),
                Text(
                  item.content,
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
        filter: ImageFilter.blur(sigmaX: AppUi.newsDetailBackBlurSigma, sigmaY: AppUi.newsDetailBackBlurSigma),
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

class _CategoryAndDate extends StatelessWidget {
  const _CategoryAndDate({required this.category, required this.date});

  final String category;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          category.toUpperCase(),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 1.0,
            letterSpacing: 1,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        SvgPicture.asset(
          'assets/icons/schedule_icon.svg',
          width: 12,
          height: 12,
          colorFilter: const ColorFilter.mode(AppColors.caption, BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(
          date,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            height: 1.0,
            color: AppColors.caption,
          ),
        ),
      ],
    );
  }
}
