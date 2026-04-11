import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/one_c_my_profile.dart';
import '../../../../data/models/student_ticket_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/widgets/app_header.dart';

/// Экран «Студенческий билет»: шапка как у настроек профиля, белый фон, карточка с тенью.
class StudentIdPage extends StatefulWidget {
  const StudentIdPage({super.key});

  @override
  State<StudentIdPage> createState() => _StudentIdPageState();
}

class _StudentIdPageState extends State<StudentIdPage> {
  UserModel? _me;
  StudentTicketModel? _ticket;
  OneCMyProfile? _oneC; // fallback if student-ticket is not available
  GroupModel? _group;
  String? _avatarPath;
  bool _meLoading = true;

  static const Color _labelBlue = Color(0xFF0069FF);
  /// Портретное фото 3:4 (ширина : высота).
  static const double _avatarWidth = 96;
  static const double _avatarHeight = 128; // 96 * 4 / 3

  static TextStyle _fieldLabelStyle() {
    return AppTextStyle.inter(
      fontWeight: FontWeight.w600,
      fontSize: 9.67,
      height: 1.2,
      color: _labelBlue,
    );
  }

  static TextStyle _fieldValueStyle() {
    return AppTextStyle.inter(
      fontWeight: FontWeight.w800,
      fontSize: 14.38,
      height: 1.2,
      color: const Color(0xFF000000),
    );
  }

  static TextStyle _chipTextStyle() {
    return AppTextStyle.inter(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1.2,
      color: Colors.white,
    );
  }

  /// Не ВСЕ ЗАГЛАВНЫЕ — только первая буква каждого слова.
  static String _titleCaseWords(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == '-') return s;
    return s
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) {
          if (w.length == 1) return w.toUpperCase();
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  bool _copiedToastVisible = false;
  Timer? _copiedToastTimer;

  @override
  void initState() {
    super.initState();
    _me = _readCachedMe();
    _ticket = _readCachedTicket();
    _oneC = _readCachedOneC();
    _group = _readCachedGroup();
    if (_me != null) _meLoading = false;
    _avatarPath = _bestLocal1cPhotoPathSync();
    unawaited(_loadAvatarPath());
    _loadMeAsync();
    unawaited(_loadGroupAsync());
  }

  static String? _bestLocal1cPhotoPathSync() {
    final dir = AppContainer.appDocumentsDirPath;
    if (dir == null || dir.trim().isEmpty) return null;
    final path = '$dir/${AppConstants.profile1cPhotoFileName}';
    try {
      final f = File(path);
      if (!f.existsSync()) return null;
      if (f.lengthSync() <= 0) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  UserModel? _readCachedMe() {
    final cached = AppContainer.jsonCache.getJsonMap('auth:me');
    if (cached == null) return null;
    try {
      return UserModel.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  GroupModel? _readCachedGroup() {
    final cached = AppContainer.jsonCache.getJsonMap('groups:my');
    if (cached == null) return null;
    try {
      return GroupModel.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  OneCMyProfile? _readCachedOneC() {
    final cached = AppContainer.jsonCache.getJsonMap('1c:my-profile');
    if (cached == null) return null;
    try {
      return OneCMyProfile.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  StudentTicketModel? _readCachedTicket() {
    final cached = AppContainer.jsonCache.getJsonMap('mobile:student-ticket');
    if (cached == null) return null;
    try {
      return StudentTicketModel.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final oneC = prefs.getString(AppConstants.profile1cPhotoPathKey);
    // Если в prefs пути нет, но файл уже на диске — берём его.
    final chosen = (oneC != null && oneC.trim().isNotEmpty) ? oneC : _bestLocal1cPhotoPathSync();
    if (mounted) setState(() => _avatarPath = chosen);
  }

  Future<void> _loadGroupAsync() async {
    try {
      final g = await AppContainer.groupsApi
          .getMyGroup()
          .timeout(ApiConstants.prefetchRequestTimeout);
      if (g != null) {
        await AppContainer.jsonCache.setJson('groups:my', g.toJson());
        if (mounted) setState(() => _group = g);
      }
    } catch (_) {}
  }

  Future<void> _loadMeAsync() async {
    UserModel? me = _me;
    try {
      final fresh = await AppContainer.authApi
          .getMe()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('auth:me', fresh.toJson());
      me = fresh;
      if (mounted) setState(() => _me = fresh);
    } catch (_) {
      // остаётся кэш или пусто
    }
    final isParent = (me?.role ?? '').trim().toLowerCase() == 'parent';
    if (!isParent) {
      try {
        final t = await AppContainer.studentTicketApi
            .getMyTicket()
            .timeout(ApiConstants.prefetchRequestTimeout);
        await AppContainer.jsonCache.setJson('mobile:student-ticket', t.toJsonMap());
        if (mounted) setState(() => _ticket = t);
      } catch (_) {
        // остаётся кэш или пусто
      }
    }
    if (mounted) setState(() => _meLoading = false);
  }

  @override
  void dispose() {
    _copiedToastTimer?.cancel();
    super.dispose();
  }

  String _copyableText(UserModel me, StudentTicketModel? t, OneCMyProfile? oneC, GroupModel? group) {
    final fullName = _displayFullName(me, t, oneC);
    final id = _studentId(me, t, oneC);
    final birthDate = _birthDate(t, oneC);
    final department = _department(me, t, oneC);
    final studyGroup = _studyGroup(me, t, oneC, group);
    final admissionYear = _admissionYear(t, oneC);
    final studyForm = _studyForm(me, t, oneC);
    final course = _course(me, t, oneC);
    final status = _status(me, t, oneC);
    return '$fullName\n'
        'ID: $id\n'
        'Дата рождения: $birthDate\n'
        'Отделение: $department\n'
        'Учебная группа: $studyGroup\n'
        'Год поступления: $admissionYear\n'
        'Форма обучения: $studyForm\n'
        'Курс: ${_formatCourseChip(course)}\n'
        'Статус: $status';
  }

  Future<void> _copyToClipboard(BuildContext context, UserModel me) async {
    await Clipboard.setData(
        ClipboardData(text: _copyableText(me, _ticket, _oneC, _group)));
    if (!context.mounted) return;
    _copiedToastTimer?.cancel();
    setState(() => _copiedToastVisible = true);
    _copiedToastTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _copiedToastVisible = false);
    });
  }

  Widget _avatar() {
    const r = 12.0;
    final hasPath = _avatarPath != null && _avatarPath!.trim().isNotEmpty;
    Widget placeholder() => ColoredBox(
          color: const Color(0xFFF0F6FF),
          child: Icon(
            Icons.person_rounded,
            size: 48,
            color: _labelBlue.withValues(alpha: 0.45),
          ),
        );
    return SizedBox(
      width: _avatarWidth,
      height: _avatarHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPath)
              Image.file(
                File(_avatarPath!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder(),
              )
            else
              placeholder(),
            // Только рамка; тень с голубым даёт «плёнку» поверх фото — оставляем её для заглушки.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(
                      color: _labelBlue.withValues(alpha: 0.35),
                      width: 2.5,
                    ),
                    boxShadow: hasPath
                        ? null
                        : [
                            BoxShadow(
                              color: _labelBlue.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Для синего чипа: «3 курс», если пришла только цифра.
  static String _formatCourseChip(String raw) {
    final t = raw.trim();
    if (t.isEmpty || t == '-') return '—';
    final lower = t.toLowerCase();
    if (lower.contains('курс')) return t;
    final n = int.tryParse(t);
    if (n != null) return '$n курс';
    return '$t курс';
  }

  Widget _dataChip(String text) {
    final t = text.trim();
    final display = (t.isEmpty || t == '-') ? '—' : t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _labelBlue,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(display, style: _chipTextStyle()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(
          leading: appHeaderNestedBackLeading(context),
          headerTitle: Text(
            'Студенческий билет',
            style: appHeaderNestedTitleStyle,
          ),
        ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Builder(
                builder: (context) {
                  final me = _me;
                  if (me == null) {
                    if (_meLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Не удалось загрузить данные. Нажмите «Обновить» вверху или откройте экран позже.',
                        style: AppTextStyle.inter(
                          fontSize: 14,
                          color: AppColors.caption,
                        ),
                      ),
                    );
                  }
                  final fullNameRaw = _displayFullName(me, _ticket, _oneC);
                  final fullName = _titleCaseWords(fullNameRaw);
                  final id = _studentId(me, _ticket, _oneC);
                  final birthDate = _birthDate(_ticket, _oneC);
                  final department = _department(me, _ticket, _oneC);
                  final direction = _direction(me, _ticket, _oneC);
                  final studyGroup = _studyGroup(me, _ticket, _oneC, _group);
                  final course = _course(me, _ticket, _oneC);
                  final admissionYear = _admissionYear(_ticket, _oneC);
                  final studyForm = _studyForm(me, _ticket, _oneC);
                  final status = _status(me, _ticket, _oneC);
                  final curator = _curator(_oneC);
                  final fundingType = _fundingType(_oneC);
                  final socialRole = _socialRole(_oneC);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          offset: Offset(2, 7),
                          blurRadius: 23.9,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _avatar(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _fieldLabel('ФИО'),
                                  const SizedBox(height: 4),
                                  Text(fullName, style: _fieldValueStyle()),
                                  const SizedBox(height: 14),
                                  _fieldLabel('Зачётная книжка'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(id, style: _fieldValueStyle()),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _copyToClipboard(context, me),
                                        child: SvgPicture.asset(
                                          'assets/icons/copy.svg',
                                          width: 14,
                                          height: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _fieldLabel('Дата рождения'),
                                  const SizedBox(height: 4),
                                  Text(birthDate, style: _fieldValueStyle()),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _fieldLabel('Год поступления'),
                                  const SizedBox(height: 4),
                                  Text(admissionYear, style: _fieldValueStyle()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_hasValue(department)) ...[
                          const SizedBox(height: 16),
                          _fieldBlock('Отделение', department),
                        ],
                        if (_hasValue(direction)) ...[
                          const SizedBox(height: 16),
                          _fieldBlock('Направление', direction),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _fieldLabel('Группа'),
                                  const SizedBox(height: 4),
                                  Text(studyGroup, style: _fieldValueStyle()),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _fieldLabel('Статус'),
                                  const SizedBox(height: 4),
                                  Text(status, style: _fieldValueStyle()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_hasValue(curator)) ...[
                          const SizedBox(height: 16),
                          _fieldBlock('Куратор', curator),
                        ],
                        if (_hasValue(fundingType)) ...[
                          const SizedBox(height: 16),
                          _fieldBlock('Тип финансирования', fundingType),
                        ],
                        if (_hasValue(socialRole)) ...[
                          const SizedBox(height: 16),
                          _fieldBlock('Общественное поручение', socialRole),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_hasValue(studyForm)) _dataChip(studyForm),
                            _dataChip(_formatCourseChip(course)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: _copiedToastVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Text(
                      'Данные скопированы',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 20 / 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: _fieldLabelStyle());
  }

  static String _safe(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

  static bool _hasValue(String v) {
    final t = v.trim();
    return t.isNotEmpty && t != '-';
  }

  Widget _fieldBlock(String label, String value) {
    if (!_hasValue(value)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        Text(value, style: _fieldValueStyle()),
      ],
    );
  }

  static String _displayFullName(UserModel me, StudentTicketModel? t, OneCMyProfile? c) {
    final st = t?.fullName?.trim();
    if (st != null && st.isNotEmpty) return st;
    final from1c = c?.fullName?.trim();
    if (from1c != null && from1c.isNotEmpty) return from1c;
    return _safe(me.fullName);
  }

  static String _studentId(UserModel me, StudentTicketModel? t, OneCMyProfile? c) {
    final st = t?.studentBookNumber?.trim();
    if (st != null && st.isNotEmpty) return st.replaceAll(' ', '');
    final from1c = c?.studentBookNumber?.trim();
    if (from1c != null && from1c.isNotEmpty) {
      return from1c.replaceAll(' ', '');
    }
    return _safe(me.studentBookNumber).replaceAll(' ', '');
  }

  static String _birthDate(StudentTicketModel? t, OneCMyProfile? c) {
    final st = t?.birthDate?.trim();
    if (st != null && st.isNotEmpty) return st;
    final b = c?.birthDate?.trim();
    if (b != null && b.isNotEmpty) return b;
    return '-';
  }

  static String _department(UserModel me, StudentTicketModel? t, OneCMyProfile? c) {
    final st = t?.department?.trim();
    if (st != null && st.isNotEmpty) return st;
    final d1 = c?.department?.trim();
    if (d1 != null && d1.isNotEmpty) return d1;
    final dir1c = c?.direction?.trim();
    if (dir1c != null && dir1c.isNotEmpty) return dir1c;
    final d = me.department?.trim();
    if (d != null && d.isNotEmpty) return d;
    final dir = me.direction?.trim();
    if (dir != null && dir.isNotEmpty) return dir;
    return '-';
  }

  static String _direction(UserModel me, StudentTicketModel? t, OneCMyProfile? c) {
    final d1 = c?.direction?.trim();
    if (d1 != null && d1.isNotEmpty) return d1;
    final d = me.direction?.trim();
    if (d != null && d.isNotEmpty) return d;
    return '-';
  }

  static String _studyGroup(UserModel me, StudentTicketModel? t, OneCMyProfile? c, GroupModel? g) {
    final st = t?.studyGroup?.trim();
    if (st != null && st.isNotEmpty) return st;
    final g1c = c?.group?.trim();
    if (g1c != null && g1c.isNotEmpty) return g1c;
    final label = g?.displayLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return '-';
  }

  static String _admissionYear(StudentTicketModel? t, OneCMyProfile? c) {
    final st = t?.admissionYear?.trim();
    if (st != null && st.isNotEmpty) return st;
    final y = c?.admissionYear?.trim();
    if (y != null && y.isNotEmpty) return y;
    return '-';
  }

  static String _studyForm(UserModel me, StudentTicketModel? t, OneCMyProfile? c) {
    final st = t?.studyForm?.trim();
    if (st != null && st.isNotEmpty) return st;
    final f = c?.studyForm?.trim();
    if (f != null && f.isNotEmpty) return f;
    return me.role == 'student' ? 'Очная' : '-';
  }

  static String _course(UserModel me, StudentTicketModel? t, OneCMyProfile? c) {
    if (t?.course != null) return t!.course.toString();
    if (c?.course != null) return c!.course.toString();
    return me.course?.toString() ?? '-';
  }

  static String _status(UserModel me, StudentTicketModel? t, OneCMyProfile? c) {
    final st = t?.status?.trim();
    if (st != null && st.isNotEmpty) return st;
    final s = c?.status?.trim();
    if (s != null && s.isNotEmpty) return s;
    return me.isActive ? 'Обучается' : 'Неактивен';
  }

  static String _curator(OneCMyProfile? c) {
    final v = c?.curator?.trim();
    if (v != null && v.isNotEmpty) return v;
    return '-';
  }

  static String _fundingType(OneCMyProfile? c) {
    final v = c?.fundingType?.trim();
    if (v != null && v.isNotEmpty) return v;
    return '-';
  }

  static String _socialRole(OneCMyProfile? c) {
    final v = c?.socialRole?.trim();
    if (v != null && v.isNotEmpty) return v;
    return '-';
  }
}
