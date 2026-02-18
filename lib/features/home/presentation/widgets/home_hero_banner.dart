import 'package:flutter/material.dart';

/// Баннер (hero) на главной: фон card_background.png, приветствие и данные студента.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: const AssetImage('assets/images/card_background.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Привет, студент!',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Имя Фамилия',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Expanded(
                  //   child: 
                    _InfoChip(
                      label: 'Группа',
                      value: 'ИСИП-41',
                    ),
                  // ),
                  const SizedBox(width: 12),
                  // Expanded(
                  //   child: 
                    _InfoChip(
                      label: 'Успеваемость',
                      value: '4.92',
                    ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
