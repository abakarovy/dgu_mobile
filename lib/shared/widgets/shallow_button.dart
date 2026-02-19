import 'package:flutter/material.dart';

/// Кнопка без рамки и фона — только текст.
/// Используй для вторичных действий (например «Подробнее», «Пропустить»).
class ShallowButton extends StatelessWidget {
  const ShallowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = style ?? theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
    );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: textStyle),
    );
  }
}
