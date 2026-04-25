import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Блок «Почта» (профиль / настройки).
class ProfileMailCard extends StatelessWidget {
  const ProfileMailCard({
    super.key,
    required this.layoutScale,
    required this.email,
    this.onChangePassword,
    this.onChangeEmail,
  });

  final double layoutScale;
  final String email;
  final VoidCallback? onChangePassword;
  final VoidCallback? onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final r = 26.4 * layoutScale;
    final titleFs = 14.4 * layoutScale;
    final valueFs = 10.8 * layoutScale;
    final iconW = 120 * layoutScale;
    final h = 118 * layoutScale;

    final miniR = 14 * layoutScale;
    final miniPad = 10 * layoutScale;
    final miniFs = 10.8 * layoutScale;

    return SizedBox(
      height: h,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: const Color(0x24000000), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(2, 0),
              blurRadius: 13.8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/images/profile_image.png',
                  width: iconW,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  color: const Color(0x52000000),
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14.4 * layoutScale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Почта',
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: titleFs,
                        height: 1.0,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    SizedBox(height: 8 * layoutScale),
                    Text(
                      email,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: valueFs,
                        height: 1.15,
                        color: const Color(0x4D000000),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: (onChangePassword == null && onChangeEmail == null)
                          ? const SizedBox.shrink()
                          : Wrap(
                              spacing: (8 * layoutScale) / 4,
                              runSpacing: (8 * layoutScale) / 4,
                              children: [
                                if (onChangePassword != null)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onChangePassword,
                                    child: Container(
                                      padding: EdgeInsets.all(miniPad),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF000000),
                                        borderRadius: BorderRadius.circular(miniR),
                                      ),
                                      child: Text(
                                        'Поменять пароль',
                                        style: AppTextStyle.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: miniFs,
                                          height: 1.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (onChangeEmail != null)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onChangeEmail,
                                    child: Container(
                                      padding: EdgeInsets.all(miniPad),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF000000),
                                        borderRadius: BorderRadius.circular(miniR),
                                      ),
                                      child: Text(
                                        'Поменять e-mail',
                                        style: AppTextStyle.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: miniFs,
                                          height: 1.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
