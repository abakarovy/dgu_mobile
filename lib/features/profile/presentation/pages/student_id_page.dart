import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/one_c_my_profile.dart';
import '../../../../data/models/student_ticket_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/widgets/app_header.dart';

/// Экран «Студенческий билет»: AppBar как у поддержки, контейнер с отступами 24, ФИО, ID, копирование, даты, форма, курс.
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
  static const double _photoWidth = 150;
  static const double _photoHeight = 200;

  static TextStyle _valueStyle() {
    return AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 25 / 20,
      color: AppColors.newsDetailTitle,
    );
  }

  static TextStyle _dateValueStyle() {
    return AppTextStyle.inter(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 26 / 16,
      color: AppColors.textPrimary,
    );
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
    unawaited(_loadAvatarPath());
    _loadMeAsync();
    unawaited(_loadGroupAsync());
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
    final path = prefs.getString(AppConstants.profileAvatarPathKey);
    if (path != null && mounted) setState(() => _avatarPath = path);
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
    try {
      final fresh = await AppContainer.authApi
          .getMe()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('auth:me', fresh.toJson());
      if (mounted) setState(() => _me = fresh);
    } catch (_) {
      // остаётся кэш или пусто
    }
    try {
      final t = await AppContainer.studentTicketApi
          .getMyTicket()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('mobile:student-ticket', t.toJsonMap());
      if (mounted) setState(() => _ticket = t);
    } catch (_) {
      // остаётся кэш или пусто
    } finally {
      if (mounted) setState(() => _meLoading = false);
    }
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
    final status = _status(me, t, oneC);
    return '$fullName\n'
        'ID: $id\n'
        'Дата рождения: $birthDate\n'
        'Отделение: $department\n'
        'Учебная группа: $studyGroup\n'
        'Год поступления: $admissionYear\n'
        'Форма обучения: $studyForm\n'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        headerTitle: Text(
          'Студенческий билет',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 24 / 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppUi.screenPaddingH,
              AppUi.spacingXl,
              AppUi.screenPaddingH,
              AppUi.spacingXl,
            ),
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
                    padding: const EdgeInsets.all(AppUi.spacingXl),
                    child: Text(
                      'Не удалось загрузить данные. Нажмите «Обновить» вверху или откройте экран позже.',
                      style: AppTextStyle.inter(
                        fontSize: 14,
                        color: AppColors.caption,
                      ),
                    ),
                  );
                }
                final fullName = _displayFullName(me, _ticket, _oneC);
                final id = _studentId(me, _ticket, _oneC);
                final birthDate = _birthDate(_ticket, _oneC);
                final department = _department(me, _ticket, _oneC);
                final studyGroup = _studyGroup(me, _ticket, _oneC, _group);
                final course = _course(me, _ticket, _oneC);
                final admissionYear = _admissionYear(_ticket, _oneC);
                final studyForm = _studyForm(me, _ticket, _oneC);
                final status = _status(me, _ticket, _oneC);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppUi.spacingXl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppUi.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                width: _photoWidth,
                                height: _photoHeight,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _avatarPath != null
                                    ? Image.file(
                                        File(_avatarPath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Icon(
                                          Icons.person,
                                          size: 56,
                                          color: AppColors.caption,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 56,
                                        color: AppColors.caption,
                                      ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label(context, 'ФИО'),
                                const SizedBox(height: 4),
                                Text(fullName, style: _valueStyle()),
                                const SizedBox(height: AppUi.spacingM),
                                _label(context, 'ID'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(id, style: _valueStyle()),
                                    const SizedBox(width: AppUi.spacingS),
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
                      const SizedBox(height: AppUi.spacingXl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label(context, 'Дата рождения'),
                                const SizedBox(height: 4),
                                Text(birthDate, style: _dateValueStyle()),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label(context, 'Год поступления'),
                                const SizedBox(height: 4),
                                Text(admissionYear, style: _dateValueStyle()),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppUi.spacingXl),
                      _label(context, 'Отделение'),
                      const SizedBox(height: 4),
                      Text(department, style: _dateValueStyle()),
                      const SizedBox(height: AppUi.spacingXl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label(context, 'Учебная группа'),
                                const SizedBox(height: 4),
                                Text(studyGroup, style: _dateValueStyle()),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label(context, 'Курс'),
                                const SizedBox(height: 4),
                                Text(course, style: _dateValueStyle()),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppUi.spacingXl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label(context, 'Форма обучения'),
                                const SizedBox(height: 4),
                                Text(studyForm, style: _dateValueStyle()),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label(context, 'Статус'),
                                const SizedBox(height: 4),
                                Text(status, style: _dateValueStyle()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
                      borderRadius: BorderRadius.circular(AppUi.radiusL),
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
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w400,
        fontSize: 10,
        height: 15 / 10,
        letterSpacing: 0.5,
        color: AppColors.notificationSubtitle,
      ),
    );
  }

  static String _safe(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

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
}
