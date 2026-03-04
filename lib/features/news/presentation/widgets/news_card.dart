import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Карточка одной новости: изображение 160px, текст с отступами 20, категория, заголовок, описание, дата.
/// Изображения только локальные: передавайте [imageWidget] с [Image.asset] или покажется плейсхолдер.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.category,
    required this.title,
    required this.excerpt,
    required this.date,
    this.imageWidget,
    this.onTap,
  });

  final String category;
  final String title;
  final String excerpt;
  final String date;
  final Widget? imageWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppUi.newsCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.newsCardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: AppUi.newsImageHeight,
              width: double.infinity,
              child: imageWidget ?? _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppUi.newsContentPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 21.6 / 18,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    excerpt,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      height: 19.5 / 13,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/schedule_icon.svg',
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(
                          AppColors.caption,
                          BlendMode.srcIn,
                        ),
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
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.backgroundSecondary,
      child: Icon(Icons.image_outlined, color: AppColors.caption, size: 40),
    );
  }
}
