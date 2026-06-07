import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_developer_info.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Карточка разработчика: имя и ссылка на сайт (тап по всей карточке).
class AppDeveloperCard extends StatelessWidget {
  const AppDeveloperCard({
    super.key,
    this.layoutScale = 1.0,
    this.showVersion = true,
  });

  final double layoutScale;
  final bool showVersion;

  Future<void> _openWebsite(BuildContext context) async {
    final uri = Uri.parse(AppDeveloperInfo.websiteUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppDeveloperInfo.websiteUrl)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = layoutScale;
    final radius = 14.0 * s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: Offset(0, 2 * s),
                blurRadius: 8 * s,
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: () => _openWebsite(context),
              borderRadius: BorderRadius.circular(radius),
              splashFactory: NoSplash.splashFactory,
              highlightColor: AppColors.backgroundBlue.withValues(alpha: 0.5),
              child: Ink(
                padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: AppColors.lightGrey.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44 * s,
                      height: 44 * s,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12 * s),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/internet.svg',
                        width: 22 * s,
                        height: 22 * s,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppDeveloperInfo.roleLabel,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 10 * s,
                              height: 1.2,
                              letterSpacing: 0.4,
                              color: AppColors.notificationSubtitle,
                            ),
                          ),
                          SizedBox(height: 3 * s),
                          Text(
                            AppDeveloperInfo.fullName,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14 * s,
                              height: 1.25,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2 * s),
                          Text(
                            AppDeveloperInfo.websiteHost,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13 * s,
                              height: 1.2,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/chevron_right.svg',
                      width: 20 * s,
                      height: 20 * s,
                      colorFilter: const ColorFilter.mode(
                        AppColors.chevronRight,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showVersion) ...[
          SizedBox(height: 8 * s),
          Text(
            AppContainer.runtimeInfo.versionDisplay,
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(
              fontSize: 11 * s,
              height: 1.3,
              color: AppColors.notificationSubtitle,
            ),
          ),
        ],
      ],
    );
  }
}
