import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/support_contact_row.dart';
import '../widgets/support_faq_row.dart';

/// Экран поддержки: баннер как на главной (по центру), блок «Связаться с нами», «Частые вопросы».
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const String _phoneNumber = '+78005553535';
  static const String _email = 'support@dgu.ru';
  static const String _websiteUrl = 'https://college.dgu.ru';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            debugPrint('[Support] Нажали: назад');
            context.pop();
          },
          color: AppColors.textPrimary,
        ),
        headerTitle: Text(
          'Поддержка',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 24 / 18,
            color: AppColors.textPrimary,
          ),
        ),
        showNotificationIcon: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppUi.spacingXl),
            _buildBanner(context),
            const SizedBox(height: 24),
            _buildSectionTitle('СВЯЗАТЬСЯ С НАМИ'),
            const SizedBox(height: AppUi.spacingM),
            SupportContactRow(
              description: 'Горячая линия',
              title: '+7 (800) 555-35-35',
              iconPath: 'assets/icons/tel.svg',
              iconColor: AppColors.supportTelIcon,
              iconBackgroundColor: AppColors.supportTelIconBg,
              onTap: () => _launchTel(context),
            ),
            const SizedBox(height: 10),
            SupportContactRow(
              description: 'Email поддержка',
              title: 'support@dgu.ru',
              iconPath: 'assets/icons/mail.svg',
              iconColor: AppColors.supportMailIcon,
              iconBackgroundColor: AppColors.supportMailIconBg,
              onTap: () => _launchMail(context),
            ),
            const SizedBox(height: 10),
            SupportContactRow(
              description: 'Сайт колледжа',
              title: 'college.dgu.ru',
              iconPath: 'assets/icons/internet.svg',
              iconColor: AppColors.supportInternetIcon,
              iconBackgroundColor: AppColors.supportInternetIconBg,
              onTap: () => _launchWebsite(context),
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('ЧАСТЫЕ ВОПРОСЫ'),
            const SizedBox(height: AppUi.spacingM),
            SupportFaqRow(
              title: 'Как восстановить пароль?',
              onTap: () => debugPrint('[Support] Нажали: Как восстановить пароль?'),
            ),
            const SizedBox(height: 10),
            SupportFaqRow(
              title: 'Где найти номер студбилета?',
              onTap: () => debugPrint('[Support] Нажали: Где найти номер студбилета?'),
            ),
            const SizedBox(height: 10),
            SupportFaqRow(
              title: 'Как заказать справку?',
              onTap: () => debugPrint('[Support] Нажали: Как заказать справку?'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(AppUi.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4D003882),
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppUi.supportBannerPadding,
          horizontal: AppUi.screenPaddingH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppUi.supportBannerIconBoxSize,
              height: AppUi.supportBannerIconBoxSize,
              decoration: BoxDecoration(
                color: AppColors.supportBannerIconBoxBg,
                borderRadius:
                    BorderRadius.circular(AppUi.supportBannerIconBoxRadius),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/mes.svg',
                  width: AppUi.supportBannerIconSize,
                  height: AppUi.supportBannerIconSize,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textOnBanner,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppUi.supportBannerPadding),
            Text(
              'Как мы можем помочь?',
              textAlign: TextAlign.center,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 28 / 20,
                color: AppColors.textOnBanner,
              ),
            ),
            const SizedBox(height: AppUi.spacingS),
            Text(
              'Наша команда поддержки готова ответить на любые ваши вопросы',
              textAlign: TextAlign.center,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 16 / 12,
                color: AppColors.textOnBanner.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        height: 16.5 / 11,
        letterSpacing: 1.65,
        color: AppColors.caption,
      ),
    );
  }

  static Future<void> _launchTel(BuildContext context) async {
    debugPrint('[Support] Нажали: Горячая линия');
    final uri = Uri.parse('tel:$_phoneNumber');
    try {
      await launchUrl(uri);
      debugPrint('[Support] Открыли звонилку с номером $_phoneNumber');
    } catch (e) {
      debugPrint('[Support] Не удалось открыть звонилку: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть звонилку')),
        );
      }
    }
  }

  static Future<void> _launchMail(BuildContext context) async {
    debugPrint('[Support] Нажали: Email поддержка');
    final uri = Uri.parse('mailto:$_email');
    try {
      await launchUrl(uri);
      debugPrint('[Support] Открыли почту: $_email');
    } catch (e) {
      debugPrint('[Support] Не удалось открыть почту: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть почту')),
        );
      }
    }
  }

  static Future<void> _launchWebsite(BuildContext context) async {
    debugPrint('[Support] Нажали: Сайт колледжа');
    final uri = Uri.parse(_websiteUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('[Support] Открыли браузер: $_websiteUrl');
    } catch (e) {
      debugPrint('[Support] Не удалось открыть браузер: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть браузер')),
        );
      }
    }
  }
}
