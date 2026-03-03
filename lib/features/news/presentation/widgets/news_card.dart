import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Карточка одной новости: верхняя половина — изображение, нижняя — категория, заголовок, описание, дата.
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

  /// Категория (например «Мероприятия») — primary blue.
  final String category;
  /// Заголовок новости.
  final String title;
  /// Краткое описание (caption).
  final String excerpt;
  /// Дата (например «15 Мая 2024»).
  final String date;
  /// URL изображения (если null, показывается плейсхолдер).
  final String? imageUrl;
  /// Либо виджет изображения (приоритет над imageUrl).
  final Widget? imageWidget;
  final VoidCallback? onTap;

  /// Высота всей карточки; изображение и контент делят её пополам.
  static const double _cardHeight = 300;
  static const double _cardContentPadding = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: _cardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Первая половина — изображение на всю ширину и высоту
              SizedBox(
                height: _cardHeight / 2,
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
              // Вторая половина — контент
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(_cardContentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        style: theme.labelMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: theme.titleSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          excerpt,
                          style: theme.bodySmall?.copyWith(
                            color: AppColors.caption,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flex(
                            direction: Axis.horizontal,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/schedule_icon.svg',
                                width: 14,
                                height: 14,
                                colorFilter: ColorFilter.mode(
                                  AppColors.caption,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: theme.bodySmall?.copyWith(
                                  color: AppColors.caption,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
