import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Профиль гостя: вход студента или родителя.
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({super.key});

  static const Color _kBlue = Color(0xFF2E63D5);

  static const _afterLoginItems = <String>[
    'Оценки и журнал',
    'Расписание и задания',
    'Справки и студенческий билет',
    'Уведомления колледжа',
  ];

  @override
  Widget build(BuildContext context) {
    final btnStyle = AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH > 0 ? minH : 0),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppUi.spacingXl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.push('/login/student'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kBlue,
                            side: const BorderSide(color: _kBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(46),
                            ),
                          ),
                          child: Text('Я студент', style: btnStyle.copyWith(color: _kBlue)),
                        ),
                      ),
                      const SizedBox(height: AppUi.spacingM),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () => context.push(
                            '/login/email',
                            extra: const {'role': 'parent', 'mode': 'login'},
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(46),
                            ),
                            elevation: 0,
                          ),
                          child: Text('Я родитель', style: btnStyle.copyWith(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: AppUi.spacingXl),
                      Text(
                        'После входа будет доступно',
                        textAlign: TextAlign.center,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppUi.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppUi.spacingL,
                          vertical: AppUi.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppUi.radiusL),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _afterLoginItems.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.lightBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _afterLoginItems[i],
                                      style: AppTextStyle.inter(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: AppColors.notificationSubtitle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
