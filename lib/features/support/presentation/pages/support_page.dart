import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/help_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/support_contact_row.dart';
import '../widgets/support_faq_row.dart';

/// Экран поддержки: баннер как на главной (по центру), блок «Связаться с нами», «Частые вопросы».
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  HelpModel? _help;
  bool _loading = true;

  static const String _fallbackPhoneNumber = '+78005553535';
  static const String _fallbackEmail = 'support@dgu.ru';
  static const String _fallbackWebsiteUrl = 'https://college.dgu.ru';

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    _load();
  }

  void _hydrateFromCache() {
    try {
      final cached = AppContainer.jsonCache.getJsonMap('mobile:help');
      if (cached != null) {
        _help = HelpModel.fromJson(cached);
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fresh = await AppContainer.mobileHelpApi.getHelp();
      await AppContainer.jsonCache.setJson('mobile:help', {
        'hotline_phone': fresh.hotlinePhone,
        'email': fresh.email,
        'website_url': fresh.websiteUrl,
        'faq': [
          for (final f in (fresh.faq ?? const []))
            {'title': f.title, 'answer': f.answer}
        ],
      });
      if (mounted) setState(() => _help = fresh);
    } catch (_) {
      // keep cache
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = _help?.hotlinePhone ?? _fallbackPhoneNumber;
    final email = _help?.email ?? _fallbackEmail;
    final site = _help?.websiteUrl ?? _fallbackWebsiteUrl;
    final faq = (_help?.faq ?? const <HelpFaqItem>[]);

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
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppUi.spacingXl),
              _buildBanner(context, loading: _loading),
              const SizedBox(height: 24),
              _buildSectionTitle('СВЯЗАТЬСЯ С НАМИ'),
              const SizedBox(height: AppUi.spacingM),
              SupportContactRow(
                description: 'Горячая линия',
                title: phone,
                iconPath: 'assets/icons/tel.svg',
                iconColor: AppColors.supportTelIcon,
                iconBackgroundColor: AppColors.supportTelIconBg,
                onTap: () => _launchTel(context, phone),
              ),
              const SizedBox(height: 10),
              SupportContactRow(
                description: 'Email поддержка',
                title: email,
                iconPath: 'assets/icons/mail.svg',
                iconColor: AppColors.supportMailIcon,
                iconBackgroundColor: AppColors.supportMailIconBg,
                onTap: () => _launchMail(context, email),
              ),
              const SizedBox(height: 10),
              SupportContactRow(
                description: 'Сайт колледжа',
                title: Uri.tryParse(site)?.host.isNotEmpty == true ? Uri.parse(site).host : site,
                iconPath: 'assets/icons/internet.svg',
                iconColor: AppColors.supportInternetIcon,
                iconBackgroundColor: AppColors.supportInternetIconBg,
                onTap: () => _launchWebsite(context, site),
              ),
              const SizedBox(height: 28),
              _buildSectionTitle('ЧАСТЫЕ ВОПРОСЫ'),
              const SizedBox(height: AppUi.spacingM),
              if (faq.isEmpty)
                Text(
                  'Нет данных',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.caption,
                  ),
                )
              else
                for (int i = 0; i < faq.length; i++) ...[
                  SupportFaqRow(
                    title: faq[i].title,
                    onTap: () => _showFaqAnswer(context, faq[i]),
                  ),
                  if (i != faq.length - 1) const SizedBox(height: 10),
                ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, {required bool loading}) {
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
            if (loading) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textOnBanner.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
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

  static Future<void> _launchTel(BuildContext context, String phoneNumber) async {
    debugPrint('[Support] Нажали: Горячая линия');
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      await launchUrl(uri);
      debugPrint('[Support] Открыли звонилку с номером $phoneNumber');
    } catch (e) {
      debugPrint('[Support] Не удалось открыть звонилку: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть звонилку')),
        );
      }
    }
  }

  static Future<void> _launchMail(BuildContext context, String email) async {
    debugPrint('[Support] Нажали: Email поддержка');
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri);
      debugPrint('[Support] Открыли почту: $email');
    } catch (e) {
      debugPrint('[Support] Не удалось открыть почту: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть почту')),
        );
      }
    }
  }

  static Future<void> _launchWebsite(BuildContext context, String url) async {
    debugPrint('[Support] Нажали: Сайт колледжа');
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('[Support] Открыли браузер: $url');
    } catch (e) {
      debugPrint('[Support] Не удалось открыть браузер: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть браузер')),
        );
      }
    }
  }

  static void _showFaqAnswer(BuildContext context, HelpFaqItem item) {
    final answer = item.answer?.trim();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppUi.screenPaddingH, 0, AppUi.screenPaddingH, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 20 / 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (answer == null || answer.isEmpty) ? 'Ответ отсутствует' : answer,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.notificationSubtitle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
