import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/dashboard_stats_normalizer.dart';

/// Цвета и типографика веб-админки college.dgu.ru (не студенческое приложение).
abstract final class StaffDashboardTheme {
  static const bg = Color(0xFFF3F4F6);
  static const card = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const title = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const accentGreen = Color(0xFF059669);
  static const barGreen = Color(0xFF3D704D);
  static const barTrack = Color(0xFFE5E7EB);
  static const badgeNavy = Color(0xFF0F172A);
  static const primaryBlue = Color(0xFF2563EB);
  static const shadow = Color(0x0F000000);
  /// Единая высота KPI- и client-карточек.
  static const statCardHeight = 170.0;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      );
}

Widget _dashboardStatCardShell({required Widget child}) {
  return SizedBox(
    width: double.infinity,
    height: StaffDashboardTheme.statCardHeight,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: StaffDashboardTheme.cardDecoration,
      child: child,
    ),
  );
}

/// KPI-карточка верхней сетки.
class StaffDashboardKpiCard extends StatelessWidget {
  const StaffDashboardKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.footer,
    this.detailColor = StaffDashboardTheme.accentGreen,
  });

  final String title;
  final String value;
  /// Строки под числом (один цвет — зелёный, как на сайте).
  final String? subtitle;
  final String? footer;
  final Color detailColor;

  @override
  Widget build(BuildContext context) {
    final detailStyle = AppTextStyle.inter(
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: detailColor,
    );
    return _dashboardStatCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.inter(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: StaffDashboardTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1.0,
              letterSpacing: -0.5,
              color: StaffDashboardTheme.title,
            ),
          ),
          const Spacer(),
          if (subtitle != null && subtitle!.trim().isNotEmpty)
            Text(subtitle!, style: detailStyle),
          if (footer != null && footer!.trim().isNotEmpty) ...[
            if (subtitle != null && subtitle!.trim().isNotEmpty)
              const SizedBox(height: 4),
            Text(footer!, style: detailStyle),
          ],
        ],
      ),
    );
  }
}

/// Карточка блока «Сайт и мобильное приложение».
class StaffDashboardClientCard extends StatelessWidget {
  const StaffDashboardClientCard({
    super.key,
    required this.title,
    required this.value,
    this.footerLines = const [],
  });

  final String title;
  final String value;
  final List<String> footerLines;

  @override
  Widget build(BuildContext context) {
    return _dashboardStatCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.inter(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: StaffDashboardTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1.0,
              letterSpacing: -0.5,
              color: StaffDashboardTheme.title,
            ),
          ),
          const Spacer(),
          if (footerLines.isNotEmpty)
            for (final line in footerLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.inter(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: StaffDashboardTheme.accentGreen,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Строка с горизонтальной полосой (как на сайте).
class StaffDashboardBarRow extends StatelessWidget {
  const StaffDashboardBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyle.inter(
                    fontSize: 13,
                    height: 1.35,
                    color: StaffDashboardTheme.title,
                  ),
                ),
              ),
              Text(
                '$value',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: StaffDashboardTheme.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: StaffDashboardTheme.barTrack),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(color: StaffDashboardTheme.barGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffDashboardChartCard extends StatelessWidget {
  const StaffDashboardChartCard({
    super.key,
    required this.title,
    required this.rows,
  });

  final String title;
  final List<MapEntry<String, int>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: StaffDashboardTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: StaffDashboardTheme.border),
          boxShadow: const [
            BoxShadow(
              color: StaffDashboardTheme.shadow,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.3,
            color: StaffDashboardTheme.title,
          ),
        ),
      );
    }
    final max = rows.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: StaffDashboardTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StaffDashboardTheme.border),
        boxShadow: const [
          BoxShadow(
            color: StaffDashboardTheme.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.3,
              color: StaffDashboardTheme.title,
            ),
          ),
          const SizedBox(height: 16),
          for (final e in rows)
            StaffDashboardBarRow(label: e.key, value: e.value, maxValue: max),
        ],
      ),
    );
  }
}

/// Полный вид дашборда — копия веб «Главная панель управления».
class StaffDashboardView extends StatelessWidget {
  const StaffDashboardView({
    super.key,
    required this.stats,
  });

  final Map<String, dynamic> stats;

  int _int(String key) {
    final v = stats[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String _fmt(int v) => v.toString();

  Map<String, dynamic>? get _clients {
    final c = stats['clients'];
    if (c is Map) return Map<String, dynamic>.from(c);
    return null;
  }

  int _client(String key) {
    final c = _clients;
    if (c != null && c.containsKey(key)) {
      final v = c[key];
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }
    return _int(key);
  }

  List<MapEntry<String, int>> _barEntries(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) {
            final labelRaw =
                (m['label'] ?? m['name'] ?? m['title'] ?? '').toString();
            final count = m['count'] ?? m['value'];
            final n = count is num ? count.toInt() : int.tryParse('$count') ?? 0;
            if (labelRaw.isEmpty) return null;
            return MapEntry(dashboardBarLabelRu(labelRaw), n);
          })
          .whereType<MapEntry<String, int>>()
          .toList();
    }
    if (raw is Map) {
      return raw.entries
          .map((e) {
            final v = e.value;
            if (v is num) return MapEntry(e.key.toString(), v.toInt());
            return null;
          })
          .whereType<MapEntry<String, int>>()
          .toList();
    }
    return const [];
  }

  int _pickClientOr(String clientsKey, String fallbackKey) {
    final c = _clients;
    if (c != null && c.containsKey(clientsKey)) {
      final v = c[clientsKey];
      if (v is num) return v.toInt();
    }
    return _int(fallbackKey);
  }

  int get _departmentHeads =>
      _int('department_heads_count') > 0
          ? _int('department_heads_count')
          : _int('department_staff_count');

  /// Ряд из 2 карточек одинаковой ширины и высоты.
  Widget _equalRow(List<Widget> cards, {required double gap}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  /// Первые [fullWidthLeading] карточек на всю ширину, остальные — по 2 в ряд.
  Widget _kpiGrid(
    List<Widget> cards, {
    double gap = 12,
    int fullWidthLeading = 1,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final leadingCount = fullWidthLeading.clamp(0, cards.length);
    final leading = cards.sublist(0, leadingCount);
    final rest = leadingCount < cards.length ? cards.sublist(leadingCount) : const <Widget>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < leading.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          leading[i],
        ],
        if (rest.isNotEmpty) ...[
          SizedBox(height: gap),
          for (var i = 0; i < rest.length; i += 2) ...[
            if (i > 0) SizedBox(height: gap),
            if (i + 1 < rest.length)
              _equalRow([rest[i], rest[i + 1]], gap: gap)
            else
              _equalRow([rest[i], const SizedBox.shrink()], gap: gap),
          ],
        ],
      ],
    );
  }

  /// Сайт + входы в ряд; регистрация через приложение и запуски — на всю ширину.
  Widget _clientGrid({
    required Widget site,
    required Widget mobile,
    required Widget logins,
    required Widget opens,
    double gap = 12,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _equalRow([site, logins], gap: gap),
        SizedBox(height: gap),
        mobile,
        SizedBox(height: gap),
        opens,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;

    final students = _int('students_count');
    final teachers = _int('teachers_count');
    final heads = _departmentHeads;
    final admins = _int('admins_count');
    final usersNew = _int('users_new_week');

    final newsTotal = _int('news_total');
    final newsDrafts = _int('news_unpublished');
    final newsWeek = _int('news_published_week');
    final groupsWeek = _int('groups_new_week');

    final kpiCards = <Widget>[
      StaffDashboardKpiCard(
        title: 'Пользователи (всего)',
        value: _fmt(_int('users_total')),
        subtitle: 'Студентов: $students · Преподавателей: $teachers · '
            'Зав. отделением: $heads · Админов: $admins',
        footer: usersNew > 0 ? '+$usersNew новых за 7 дней' : '+0 за 7 дней',
      ),
      StaffDashboardKpiCard(
        title: 'Новости',
        value: _fmt(_int('news_published')),
        subtitle: 'Всего записей: ${newsTotal > 0 ? newsTotal : _int('news_published')} · '
            'Черновиков: $newsDrafts',
        footer: newsWeek > 0
            ? '+$newsWeek опубликовано за 7 дней'
            : '+0 опубликовано за 7 дней',
      ),
      StaffDashboardKpiCard(
        title: 'Группы',
        value: _fmt(_int('groups_total')),
        footer: '+$groupsWeek за 7 дней',
      ),
      StaffDashboardKpiCard(
        title: 'Портфолио на модерации',
        value: _fmt(_int('portfolio_pending')),
        footer: 'Ожидают проверки',
      ),
      StaffDashboardKpiCard(
        title: 'Заявки на справки',
        value: _fmt(_int('document_requests_pending')),
        footer: 'В статусе «ожидает»',
      ),
      StaffDashboardKpiCard(
        title: 'Материалы (файлы)',
        value: _fmt(_int('materials_total')),
        subtitle: 'Записей в таблице материалов',
      ),
      StaffDashboardKpiCard(
        title: 'Услуги УПК',
        value: _fmt(_int('upk_services')),
        subtitle: 'Активных в каталоге · всего записей: ${_int('upk_services')}',
      ),
      StaffDashboardKpiCard(
        title: 'Кейсы УПК',
        value: _fmt(_int('upk_cases')),
        subtitle: 'Кейсов в разделе УПК',
      ),
    ];

    final clientSite = StaffDashboardClientCard(
      title: 'Зарегистрировались через сайт',
      value: _fmt(_pickClientOr('users_registered_web', 'users_registered_web')),
      footerLines: const ['Самостоятельная регистрация на сайте'],
    );
    final clientMobile = StaffDashboardClientCard(
      title: 'Зарегистрировались через приложение',
      value: _fmt(_pickClientOr('users_registered_mobile', 'users_registered_mobile')),
      footerLines: [
        'Админка: ${_pickClientOr('users_registered_admin', 'users_registered_admin')} · '
            'Приглашения: ${_pickClientOr('users_registered_invite', 'users_registered_invite')}',
      ],
    );
    final clientLogins = StaffDashboardClientCard(
      title: 'Входов за 7 дней',
      value: _fmt(_pickClientOr('logins_week_total', 'logins_week_total')),
      footerLines: _loginsFooterLines(),
    );
    final clientOpens = StaffDashboardClientCard(
      title: 'Запусков приложения за 7 дней',
      value: _fmt(_pickClientOr('mobile_app_opens_week', 'mobile_app_opens_week')),
      footerLines: _platformFooterLines(),
    );

    const chartSpecs = [
      ('registrations_by_source_week', 'Регистрации за 7 дней'),
      ('registrations_by_source_total', 'Регистрации (всего по источнику)'),
      ('logins_by_client_week', 'Входы за 7 дней — устройства / платформа'),
      ('registrations_by_client_week', 'Регистрации за 7 дней — сайт / приложение'),
      ('app_versions_week', 'Версии приложения за 7 дней (топ)'),
    ];

    final chartSections = <Widget>[
      for (final spec in chartSpecs)
        StaffDashboardChartCard(
          title: spec.$2,
          rows: _barEntries(stats[spec.$1]),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Главная панель управления',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            height: 1.15,
            letterSpacing: -0.3,
            color: StaffDashboardTheme.title,
          ),
        ),
        const SizedBox(height: 20),
        _kpiGrid(kpiCards, gap: gap, fullWidthLeading: 2),
        const SizedBox(height: 20),
        _clientGrid(
          site: clientSite,
          mobile: clientMobile,
          logins: clientLogins,
          opens: clientOpens,
          gap: gap,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < chartSections.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              chartSections[i],
            ],
          ],
        ),
      ],
    );
  }

  List<String> _loginsFooterLines() {
    final raw = stats['logins_week_by_client'] ?? _clients?['logins_week_by_client'];
    final rows = _barEntries(raw);
    if (rows.isEmpty) return const [];
    return [for (final e in rows) '${e.key}: ${e.value}'];
  }

  List<String> _platformFooterLines() {
    final raw = stats['mobile_app_by_platform'] ?? _clients?['mobile_app_by_platform'];
    final platform = _barEntries(raw);
    if (platform.isNotEmpty) {
      return [
        for (final e in platform) '${e.key}: ${e.value}',
      ];
    }
    final ios = _client('ios_opens');
    final android = _client('android_opens');
    if (ios > 0 || android > 0) {
      return [
        if (ios > 0) 'iOS: $ios',
        if (android > 0) 'Android: $android',
      ];
    }
    return const [];
  }
}

List<Widget> buildDashboardWidgets(Map<String, dynamic> stats) {
  return [StaffDashboardView(stats: stats)];
}
