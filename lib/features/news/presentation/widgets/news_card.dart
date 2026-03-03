import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Карточка одной новости: изображение 160px, текст с отступами 20, категория, заголовок, описание, дата.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.category,
    required this.title,
    required this.excerpt,
    required this.date,
    this.imageUrl,
    this.imageWidget,
    this.onTap,
  });

  final String category;
  final String title;
  final String excerpt;
  final String date;
  final String? imageUrl;
  final Widget? imageWidget;
  final VoidCallback? onTap;

  static const double _imageHeight = 160;
  static const double _contentPaddingH = 20;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _imageHeight,
              width: double.infinity,
              child: imageWidget ??
                  (imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      : _placeholder()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _contentPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    category.toUpperCase(),
                    style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
