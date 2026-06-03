import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Переключатель семестра (стрелки + подпись), как на вкладке «Сессия» в оценках.
class SemesterPeriodSelector extends StatelessWidget {
  const SemesterPeriodSelector({
    super.key,
    required this.periodLabel,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
    this.canGoPrev = true,
    this.canGoNext = true,
  });

  final String periodLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final bool canGoPrev;
  final bool canGoNext;

  static const double controlHeight = 30;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: controlHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF2147B6),
              Color(0xFF3779EC),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2249B9),
            width: 0.36,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 26,
              child: canGoPrev
                  ? GestureDetector(
                      onTap: onPrev,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.chevron_left, size: 18, color: Colors.white),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Text(
                    periodLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 26,
              child: canGoNext
                  ? GestureDetector(
                      onTap: onNext,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.chevron_right, size: 18, color: Colors.white),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
