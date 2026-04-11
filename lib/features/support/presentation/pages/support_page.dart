import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/help_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/support_contact_row.dart';
import '../widgets/support_faq_row.dart';

/// Экран поддержки: баннер как на главной, блок контактов в карточке, FAQ.
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

  static const double _uiScaleBoost = 1.2;

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
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Поддержка', style: appHeaderNestedTitleStyle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppUi.spacingL),
              _buildHomeStyleBanner(context, loading: _loading),
              const SizedBox(height: AppUi.spacingXl),
              _buildSectionTitle('Связаться с нами'),
              const SizedBox(height: AppUi.spacingM),
              _buildContactsCard(
                context,
                phone: phone,
                email: email,
                site: site,
              ),
              const SizedBox(height: 28),
              _buildSectionTitle('Частые вопросы'),
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

  /// Баннер в стиле главной: градиент, декор справа, заголовок по центру.
  Widget _buildHomeStyleBanner(BuildContext context, {required bool loading}) {
    final size = MediaQuery.sizeOf(context);
    final sf = min(size.width / 402, size.height / 874) * _uiScaleBoost;
    final radius = 20.0 * sf;
    final pad = 20.0 * sf;

    return Container(
      constraints: BoxConstraints(minHeight: 168 * sf),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E40AF),
            Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDBEAFE),
            offset: Offset(0, 5.12 * sf),
            blurRadius: 6.4 * sf,
            spreadRadius: -3.84 * sf,
          ),
          BoxShadow(
            color: const Color(0xFFDBEAFE),
            offset: Offset(0, 12.8 * sf),
            blurRadius: 16 * sf,
            spreadRadius: -3.2 * sf,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/image_home.png',
              width: 108 * sf,
              height: 123 * sf,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56 * sf,
                  height: 56 * sf,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14 * sf),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/mes.svg',
                      width: 28 * sf,
                      height: 28 * sf,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textOnBanner,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14 * sf),
                Text(
                  'Как мы можем помочь?',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 19 * sf,
                    height: 1.2,
                    color: AppColors.textOnBanner,
                  ),
                ),
                SizedBox(height: 8 * sf),
                Text(
                  'Команда поддержки колледжа ответит на вопросы по приложению и обучению',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 11.5 * sf,
                    height: 1.35,
                    color: AppColors.textOnBanner.withValues(alpha: 0.88),
                  ),
                ),
                if (loading) ...[
                  SizedBox(height: 12 * sf),
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
        ],
      ),
    );
  }

  /// Карточка как блоки на главной: белый фон, лёгкая тень.
  Widget _buildContactsCard(
    BuildContext context, {
    required String phone,
    required String email,
    required String site,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SupportContactRow(
            description: 'Горячая линия',
            title: phone,
            iconPath: 'assets/icons/tel.svg',
            iconColor: AppColors.supportTelIcon,
            iconBackgroundColor: AppColors.supportTelIconBg,
            showShadow: false,
            onTap: () => _launchTel(context, phone),
          ),
          const SizedBox(height: 10),
          SupportContactRow(
            description: 'Email поддержка',
            title: email,
            iconPath: 'assets/icons/mail.svg',
            iconColor: AppColors.supportMailIcon,
            iconBackgroundColor: AppColors.supportMailIconBg,
            showShadow: false,
            onTap: () => _launchMail(context, email),
          ),
          const SizedBox(height: 10),
          SupportContactRow(
            description: 'Сайт колледжа',
            title: Uri.tryParse(site)?.host.isNotEmpty == true ? Uri.parse(site).host : site,
            iconPath: 'assets/icons/internet.svg',
            iconColor: AppColors.supportInternetIcon,
            iconBackgroundColor: AppColors.supportInternetIconBg,
            showShadow: false,
            onTap: () => _launchWebsite(context, site),
          ),
        ],
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
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть звонилку')),
        );
      }
    }
  }

  static Future<void> _launchMail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть почту')),
        );
      }
    }
  }

  static Future<void> _launchWebsite(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
