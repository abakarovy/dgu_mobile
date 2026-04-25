import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io';
import 'dart:math' show min;

import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_constants.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/utils/parent_child_name.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/data/api/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/api/grades_api.dart' show GradesBundle;
import '../../../../data/models/one_c_my_profile.dart';
import '../../../../data/models/student_ticket_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../grades/domain/entities/grade_entity.dart';
// `CertificateOrderPage` открывается отдельным роутом `/account/certificate-order`.

/// Вкладка «Профиль» — данные аккаунта, образование, личные данные и настройки.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _savedAvatarPath;
  String? _saved1cPhotoPath;
  UserModel? _me;
  StudentTicketModel? _ticket;
  OneCMyProfile? _oneC;
  /// Подпись пропусков с `GET /api/1c/absences` (после загрузки).
  String? _absenceHoursText;
  /// Родитель принял приглашение (для бейджа на кнопке).
  bool? _parentConnected;
  /// Приглашение отправлено, ждём подтверждения на стороне родителя.
  bool _parentPending = false;
  @override
  void initState() {
    super.initState();
    _me = _readCachedMe();
    _ticket = _readCachedTicket();
    _oneC = _readCachedOneC();
    _absenceHoursText = _readCachedAbsencesLabel();
    _saved1cPhotoPath = _bestLocal1cPhotoPathSync();
    _maybeHydrateParentTicketFromOneC();
    _loadAvatarPath();
    _refreshMeInBackground();
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

  @override
  void dispose() {
    super.dispose();
  }

  void _applyParentStatus(Map<String, dynamic> s) {
    final connected = s['linked'] == true;
    final st = (s['link_status'] ?? '').toString().toLowerCase().trim();
    final pending = !connected &&
        (st == 'pending' ||
            st == 'invited' ||
            st == 'awaiting' ||
            st == 'awaiting_parent' ||
            s['invite_pending'] == true);
    _parentConnected = connected;
    _parentPending = pending;
  }

  Future<void> _hydrateParentStatusFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(AppConstants.profileLastParentStatusJsonKey);
      if (raw == null || raw.isEmpty) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _applyParentStatus(m));
    } catch (_) {}
  }

  Future<void> _saveParentStatusToPrefs(Map<String, dynamic> s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        AppConstants.profileLastParentStatusJsonKey,
        jsonEncode(s),
      );
    } catch (_) {}
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

  StudentTicketModel? _readCachedTicket() {
    final cached = AppContainer.jsonCache.getJsonMap('mobile:student-ticket');
    if (cached == null) return null;
    try {
      return StudentTicketModel.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  OneCMyProfile? _readCachedOneC() {
    try {
      final cached = AppContainer.jsonCache.getJsonMap('1c:my-profile');
      if (cached != null) return OneCMyProfile.fromJson(cached);
      final me = _readCachedMe();
      if ((me?.role ?? '').trim().toLowerCase() == 'parent') {
        final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
        final p1c = sd?['profile_1c'];
        if (p1c is Map) {
          return OneCMyProfile.fromJson(Map<String, dynamic>.from(p1c));
        }
      }
    } catch (_) {}
    return null;
  }

  void _maybeHydrateParentTicketFromOneC() {
    if ((_me?.role ?? '').trim().toLowerCase() != 'parent') return;
    if (_ticket != null) return;
    final c = _oneC;
    if (c == null) return;
    setState(() {
      _ticket = _studentTicketFromOneC(c);
    });
  }

  static StudentTicketModel _studentTicketFromOneC(OneCMyProfile c) {
    return StudentTicketModel(
      fullName: c.fullName,
      studentBookNumber: c.studentBookNumber,
      birthDate: c.birthDate,
      department: c.department,
      studyGroup: c.group,
      admissionYear: c.admissionYear,
      studyForm: c.studyForm,
      status: c.status,
      course: c.course,
    );
  }

  static int? _childStudentIdFromParentsPayload(Map<String, dynamic>? data) {
    if (data == null) return null;
    final st = data['student'];
    if (st is! Map) return null;
    final id = st['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return null;
  }

  int? _syncChildStudentIdForParent() {
    if ((_me?.role ?? '').trim().toLowerCase() != 'parent') return null;
    final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
    return _childStudentIdFromParentsPayload(sd);
  }

  /// Подпись пропусков с прогрева splash (`profile:absences-label`), до сетевого ответа.
  String? _readCachedAbsencesLabel() {
    final m = AppContainer.jsonCache.getJsonMap(AppContainer.profileAbsencesLabelCacheKey);
    if (m == null) return null;
    final v = m['label'];
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  Future<void> _refreshMeInBackground() async {
    UserModel? me = _me ?? _readCachedMe();

    try {
      final fresh = await AppContainer.authApi
          .getMe()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('auth:me', fresh.toJson());
      me = fresh;
      if (mounted) {
        setState(() {
          _me = fresh;
        });
      }
    } catch (_) {}

    final isParent = (me?.role ?? '').trim().toLowerCase() == 'parent';
    int? childId;
    if (isParent) {
      try {
        final data = await AppContainer.accountApi
            .getParentsStudentData()
            .timeout(ApiConstants.prefetchRequestTimeout);
        await AppContainer.jsonCache.setJson('parents:student-data', data);
        childId = _childStudentIdFromParentsPayload(data);
      } catch (_) {}
      childId ??= _syncChildStudentIdForParent();
    }

    if (!isParent) {
      try {
        final t = await AppContainer.studentTicketApi
            .getMyTicket()
            .timeout(ApiConstants.prefetchRequestTimeout);
        await AppContainer.jsonCache.setJson('mobile:student-ticket', t.toJsonMap());
        if (mounted) {
          setState(() {
            _ticket = t;
          });
        }
      } catch (_) {}
    }

    try {
      if (isParent && childId != null) {
        final p = await AppContainer.profile1cApi
            .getMyProfile(studentId: childId)
            .timeout(ApiConstants.prefetchRequestTimeout);
        await AppContainer.jsonCache.setJson('1c:my-profile', p.toJsonMap());
        if (mounted) {
          setState(() {
            _oneC = p;
            _ticket = _ticket ?? _studentTicketFromOneC(p);
          });
        }
      } else if (!isParent) {
        final p = await AppContainer.profile1cApi
            .getMyProfile()
            .timeout(ApiConstants.prefetchRequestTimeout);
        await AppContainer.jsonCache.setJson('1c:my-profile', p.toJsonMap());
        if (mounted) {
          setState(() {
            _oneC = p;
          });
        }
      }
    } catch (_) {}

    try {
      if ((me?.role ?? '').trim().toLowerCase() != 'parent') {
        await _hydrateParentStatusFromPrefs();
        final s = await AppContainer.accountApi
            .getParentStatus()
            .timeout(ApiConstants.prefetchRequestTimeout);
        if (mounted) {
          setState(() => _applyParentStatus(s));
        }
        await _saveParentStatusToPrefs(s);
      }
    } catch (_) {}

    try {
      if ((_savedAvatarPath ?? '').trim().isEmpty) {
        unawaited(
          _ensure1cPhotoCached(
            refreshIfCached: true,
            studentId: isParent ? childId : null,
          ),
        );
      }
    } catch (_) {}

    try {
      if (isParent && childId == null) {
        // Нет привязки к ребёнку — не затираем кэш оценок пустым ответом.
      } else {
      final GradesBundle bundle;
      if (isParent && childId != null) {
        bundle = await AppContainer.gradesApi
            .loadMyGrades(studentIdOverride: childId)
            .timeout(ApiConstants.prefetchRequestTimeout);
      } else {
        bundle = await AppContainer.gradesApi
            .loadMyGrades()
            .timeout(ApiConstants.prefetchRequestTimeout);
      }
      await AppContainer.jsonCache.setJson(
        'grades:my',
        [
          for (final g in bundle.grades)
            {
              'subject_name': g.subjectName,
              'grade': g.grade,
              'grade_type': g.gradeType,
              'teacher_name': g.teacherName,
              'date': g.date?.toIso8601String(),
              'semester': g.semester,
            }
        ],
      );
      await AppContainer.jsonCache.setJson('grades:semesters', bundle.semesters);
      }
    } catch (_) {}

    try {
      final sem = _currentSemesterLabel(_loadGradesFromCache());
      final abs = await AppContainer.profile1cApi
          .getAbsencesDisplayLabel(
            currentSemester: sem,
            studentId: isParent ? childId : null,
          )
          .timeout(ApiConstants.prefetchRequestTimeout);
      if (abs != null) {
        await AppContainer.jsonCache.setJson(
          AppContainer.profileAbsencesLabelCacheKey,
          {'label': abs},
        );
      }
      if (mounted) {
        setState(() {
          _absenceHoursText = abs;
        });
      }
    } catch (_) {}
  }

  List<GradeEntity> _loadGradesFromCache() {
    const cacheKey = 'grades:my';
    final cached = AppContainer.jsonCache.getJsonList(cacheKey);
    if (cached == null) return const <GradeEntity>[];
    String str(dynamic v) => v is String ? v : (v == null ? '' : '$v');
    return cached
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(
          (j) => GradeEntity(
            subjectName: str(j['subject_name']).trim(),
            grade: str(j['grade']).trim(),
            gradeType: j['grade_type'] != null ? str(j['grade_type']) : null,
            teacherName: j['teacher_name'] != null ? str(j['teacher_name']) : null,
            date: DateTime.tryParse(str(j['date'])),
            semester: j['semester'] != null ? str(j['semester']).trim() : null,
          ),
        )
        .toList();
  }

  String? _currentSemesterLabel(List<GradeEntity> grades) {
    int? bestKey;
    String? bestLabel;

    int? keyOf(String? s) {
      if (s == null) return null;
      final t = s.trim();
      final re = RegExp(r'([12])\s*сем\s*(\d{4})-(\d{4})');
      final m = re.firstMatch(t);
      if (m == null) return null;
      final sem = int.tryParse(m.group(1) ?? '');
      final y1 = int.tryParse(m.group(2) ?? '');
      final y2 = int.tryParse(m.group(3) ?? '');
      if (sem == null || y1 == null || y2 == null) return null;
      return (y2 * 10) + sem;
    }

    for (final g in grades) {
      final k = keyOf(g.semester);
      if (k == null) continue;
      if (bestKey == null || k > bestKey) {
        bestKey = k;
        bestLabel = g.semester?.trim();
      }
    }
    return bestLabel;
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final oneCPhoto = prefs.getString(AppConstants.profile1cPhotoPathKey);
    String? chosen = oneCPhoto;
    try {
      // Если prefs пустые/битые, но файл уже есть на диске — используем его сразу.
      final dir = await getApplicationDocumentsDirectory();
      final fallback = File('${dir.path}/${AppConstants.profile1cPhotoFileName}');
      if ((chosen == null || chosen.trim().isEmpty) && await fallback.exists()) {
        final len = await fallback.length();
        if (len > 0) chosen = fallback.path;
      } else if (chosen != null && chosen.trim().isNotEmpty) {
        final f = File(chosen);
        if (!await f.exists() || await f.length() == 0) {
          chosen = null;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      // Пользовательскую аватарку не используем — берём фото с бэка (1С) + его кэш.
      _savedAvatarPath = null;
      _saved1cPhotoPath = chosen;
    });

    // Показываем кэш сразу, а обновление с бэка делаем в фоне.
    unawaited(
      _ensure1cPhotoCached(
        refreshIfCached: true,
        studentId: _syncChildStudentIdForParent(),
      ),
    );
  }

  Future<void> _ensure1cPhotoCached({
    required bool refreshIfCached,
    int? studentId,
  }) async {
    // If we already have a cached file on disk, don't refetch on every app restart.
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPath = prefs.getString(AppConstants.profile1cPhotoPathKey);
      if (existingPath != null && existingPath.trim().isNotEmpty) {
        final f = File(existingPath);
        if (await f.exists()) {
          final len = await f.length();
          if (len > 0) {
            if (mounted) setState(() => _saved1cPhotoPath = existingPath);
            if (!refreshIfCached) return;
          }
        }
      }
    } catch (_) {
      // If cache check fails, fall back to fetch.
    }

    final bytes = await AppContainer.profile1cApi
        .getStudentPhotoBytes(studentId: studentId)
        .timeout(ApiConstants.prefetchRequestTimeout);
    if (bytes == null || bytes.isEmpty) return;
    final dirPath = AppContainer.appDocumentsDirPath ??
        (await getApplicationDocumentsDirectory()).path;
    final file = File('$dirPath/${AppConstants.profile1cPhotoFileName}');
    await file.writeAsBytes(bytes, flush: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.profile1cPhotoPathKey, file.path);
    if (mounted) setState(() => _saved1cPhotoPath = file.path);
  }

  // Пользовательскую замену аватарки отключили по требованию:
  // аватар всегда берётся с бэка (1С) + локальный кэш.

  String _displayTicketNumber(UserModel? me) {
    final t = _ticket?.studentBookNumber?.trim();
    if (t != null && t.isNotEmpty) return t;
    final c = _oneC?.studentBookNumber?.trim();
    if (c != null && c.isNotEmpty) return c;
    final m = me?.studentBookNumber?.trim();
    if (m != null && m.isNotEmpty) return m;
    return '—';
  }

  String _profileHeroDisplayName(UserModel? me) {
    if (me == null) return '—';
    if ((me.role).trim().toLowerCase() == 'parent') {
      final line = ParentChildName.settingsRoditelChildLine();
      if (line != null && line.trim().isNotEmpty) return line.trim();
    }
    final n = (me.fullName).trim();
    return n.isEmpty ? '—' : n;
  }

  void _showAppSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surfaceLight,
        elevation: 3,
        content: Text(
          message,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final fullName = _profileHeroDisplayName(me);
    final isParentProfile = (me?.role ?? '').trim().toLowerCase() == 'parent';
    final course = isParentProfile
        ? (_oneC?.course != null ? _oneC!.course.toString().trim() : '')
        : (me?.course?.toString() ?? '').trim();
    final direction = isParentProfile
        ? (_oneC?.direction ?? '').trim()
        : (me?.direction ?? '').trim();
    final groupLine = isParentProfile
        ? (_oneC?.group ?? '').trim()
        : (_ticket?.studyGroup ?? '').trim();
    final ticketNo = _displayTicketNumber(me);
    final absenceLabel = _absenceHoursText ?? '—';

    // Макет 402×874 — все размеры относительно `layoutScale` (как на главной).
    final size = MediaQuery.sizeOf(context);
    const figmaW = 402.0;
    const figmaH = 874.0;
    final layoutScale = min(size.width / figmaW, size.height / figmaH);
    final minProfileCardHeight = 100 * layoutScale;
    final hPad = 12 * layoutScale;
    final gapM = 16 * layoutScale;
    // Две кнопки справа — как раньше по высоте (minProfileCardHeight), между ними 7 лог. px.
    final ticketAbsenceH = minProfileCardHeight;
    final stackGap = 7 * layoutScale;
    final courseLeftHeight = ticketAbsenceH * 2 + stackGap;
    // Отступы секции «Действия».
    const actionsTitleFs = 11.63;
    const actionsTitleHeight = 17.44;

    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topHero(
              layoutScale: layoutScale,
              fullName: fullName.isEmpty ? '—' : fullName,
            ),
            SizedBox(height: gapM),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _courseCard(
                      layoutScale: layoutScale,
                      courseText: course.isEmpty ? '—' : '$course курс',
                      directionText: direction.isEmpty ? '—' : direction,
                      groupText: groupLine.isEmpty ? null : groupLine,
                      fixedHeight: courseLeftHeight,
                    ),
                  ),
                  SizedBox(width: gapM),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: ticketAbsenceH,
                          width: double.infinity,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/app/profile/student-id'),
                            child: _studentTicketCard(
                              layoutScale: layoutScale,
                              ticketNumber: ticketNo,
                              onCopy: () async {
                                await Clipboard.setData(ClipboardData(text: ticketNo));
                                if (!context.mounted) return;
                                _showAppSnackBar(context, 'Номер скопирован');
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: stackGap),
                        SizedBox(
                          height: ticketAbsenceH,
                          width: double.infinity,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/app/profile/absences'),
                            child: _absencesCard(
                              layoutScale: layoutScale,
                              hoursLabel: absenceLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24 * layoutScale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Действия',
                  textAlign: TextAlign.left,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: actionsTitleFs * layoutScale,
                    height: actionsTitleHeight / actionsTitleFs,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12 * layoutScale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((me?.role ?? '').trim().toLowerCase() != 'parent')
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.35),
                          builder: (dialogContext) => _InviteParentDialog(
                            onInvited: (parentEmail) {
                              if (!mounted) return;
                              setState(() {
                                _parentConnected = false;
                                _parentPending = true;
                              });
                              unawaited(
                                _saveParentStatusToPrefs({
                                  'linked': false,
                                  'link_status': 'pending',
                                  'parent_email_masked': null,
                                }),
                              );
                              _showAppSnackBar(
                                context,
                                'Приглашение отправили на $parentEmail',
                              );
                            },
                          ),
                        );
                      },
                      child: _inviteParentActionCard(
                        layoutScale: layoutScale,
                        parentConnected: _parentConnected == true,
                        parentPending: _parentPending,
                      ),
                    ),
                  SizedBox(height: 8 * layoutScale),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.push('/account/certificate-order');
                    },
                    child: _certificateActionCard(
                      layoutScale: layoutScale,
                      title: 'Заказать справку с места учебы',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _kActionShadow = Color(0x40000000);

  BoxShadow _inviteCertificateShadow(double layoutScale) => BoxShadow(
        color: _kActionShadow,
        offset: Offset(2.04 * layoutScale, 0),
        blurRadius: 14.09 * layoutScale,
        spreadRadius: 0,
      );

  static const double _actionTextScale = 1.2;

  /// Кнопка «Пригласить родителя» (макет 402×874, масштаб [layoutScale]).
  ///
  /// Бейдж статуса масштабируется в 1.2× относительно базовой сетки (как визуальный
  /// акцент к заголовку). Ширина бейджа — по содержимому; заголовок и бейдж в [Wrap],
  /// при нехватке ширины бейдж уходит на следующую строку.
  Widget _inviteParentActionCard({
    required double layoutScale,
    required bool parentConnected,
    required bool parentPending,
  }) {
    const statusBadgeEmphasis = 1.2;
    final r = 10 * layoutScale;
    final padH = 19 * layoutScale;
    final padV = 12 * layoutScale;
    final titleFs = 13.08 * _actionTextScale;
    final subFs = 7.89 * _actionTextScale;
    final badgeFs = 5.75 * _actionTextScale;
    final iconS = 28.0 * _actionTextScale * layoutScale;
    final minH = 55.0 * _actionTextScale * layoutScale;
    final hasStatusChip = parentConnected || parentPending;
    final s = hasStatusChip ? statusBadgeEmphasis : 1.0;
    final titleStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w800,
      fontSize: titleFs * layoutScale,
      height: 19.63 / 13.08,
      color: const Color(0xFF000000),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minH),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
          boxShadow: [_inviteCertificateShadow(layoutScale)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 3.6 * layoutScale * _actionTextScale * s,
                    runSpacing: 4 * layoutScale * _actionTextScale,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Пригласить родителя',
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        softWrap: true,
                        textWidthBasis: TextWidthBasis.longestLine,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      if (parentConnected)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7 * layoutScale * _actionTextScale * s,
                            vertical: 3 * layoutScale * s,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x2910B981),
                            borderRadius: BorderRadius.circular(6 * layoutScale * s),
                          ),
                          child: Text(
                            'Родитель подключен',
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: badgeFs * layoutScale * s,
                              height: 8.62 / 5.75,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        )
                      else if (parentPending)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7 * layoutScale * _actionTextScale * s,
                            vertical: 3 * layoutScale * s,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x29D97706),
                            borderRadius: BorderRadius.circular(6 * layoutScale * s),
                          ),
                          child: Text(
                            'Ожидает подтверждения',
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.left,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: badgeFs * layoutScale * s,
                              height: 1.1,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2 * layoutScale * _actionTextScale),
                  Text(
                    parentConnected
                        ? 'Для смены или отключения почты родителя подойдите к администратору'
                        : parentPending
                            ? 'Письмо с приглашением отправлено. Родитель подтвердит по ссылке из письма.'
                            : 'Родитель получит доступ к вашим данным об успеваемости',
                    textAlign: TextAlign.left,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: subFs * layoutScale,
                      height: 11.84 / 7.89,
                      color: const Color(0xB3000000),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * layoutScale * _actionTextScale),
            SvgPicture.asset(
              'assets/icons/rod.svg',
              width: iconS,
              height: iconS,
            ),
          ],
        ),
      ),
    );
  }

  /// Кнопка «Заказать справку…» — тот же контейнер, иконка справа.
  Widget _certificateActionCard({
    required double layoutScale,
    required String title,
  }) {
    final titleFs = 13.08 * _actionTextScale;
    final r = 10 * layoutScale;
    final padH = 19 * layoutScale;
    final padV = 12 * layoutScale;
    final iconS = 28.0 * _actionTextScale * layoutScale;
    final minH = 55.0 * _actionTextScale * layoutScale;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minH),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
          boxShadow: [_inviteCertificateShadow(layoutScale)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: titleFs * layoutScale,
                    height: 19.63 / 13.08,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8 * layoutScale * _actionTextScale),
            SvgPicture.asset(
              'assets/icons/spravka.svg',
              width: iconS,
              height: iconS,
            ),
          ],
        ),
      ),
    );
  }

  Widget _topHero({
    required double layoutScale,
    required String fullName,
  }) {
    // Ниже, чем в макете 309 — компактнее шапка профиля.
    final heroH = 248 * layoutScale;
    final avatar = 96 * layoutScale;
    final radius = 33 * layoutScale;
    final borderW = 3.34 * layoutScale;
    final nameSize = 20.03 * layoutScale;
    final subtitleSize = 16.5 * layoutScale;
    return SizedBox(
      height: heroH,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF224AB9),
                  Color(0xFF0069FF),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/images/profile_image.png',
                height: heroH,
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: avatar,
                  height: avatar,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1A000000),
                        offset: Offset(0, 8.35 * layoutScale),
                        blurRadius: 20.86 * layoutScale,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(child: _avatarImage(layoutScale)),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(radius),
                                border: Border.all(
                                  color: Colors.white,
                                  width: borderW,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8 * layoutScale),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: nameSize,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3 * layoutScale),
                Text(
                  'Колледж ДГУ',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: subtitleSize,
                    height: 1.0,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarImage(double layoutScale) {
    final p = (_savedAvatarPath != null && _savedAvatarPath!.trim().isNotEmpty)
        ? _savedAvatarPath
        : ((_saved1cPhotoPath != null && _saved1cPhotoPath!.trim().isNotEmpty)
            ? _saved1cPhotoPath
            : null);
    if (p != null) {
      final f = File(p);
      return Image.file(
        f,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallbackAvatar(layoutScale),
      );
    }
    return _fallbackAvatar(layoutScale);
  }

  Widget _fallbackAvatar(double layoutScale) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Icon(Icons.person, color: Colors.white, size: 48 * layoutScale),
    );
  }

  Widget _courseCard({
    required double layoutScale,
    required String courseText,
    required String directionText,
    String? groupText,
    /// Если задана, карточка курса фиксированной высоты (слева от столбца билет/пропуски).
    double? fixedHeight,
  }) {
    final r = 22 * layoutScale;
    final padL = 16 * layoutScale;
    final padV = 14 * layoutScale;
    final courseFs = 17.2 * layoutScale;
    final subFs = 13.0 * layoutScale;
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          courseText,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: courseFs,
            height: 1.15,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8 * layoutScale),
        Text(
          directionText,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: subFs,
            height: 1.25,
            color: const Color(0xFF94A3B8),
          ),
        ),
        if (groupText != null && groupText.trim().isNotEmpty) ...[
          SizedBox(height: 6 * layoutScale),
          Text(
            groupText.trim(),
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w600,
              fontSize: subFs,
              height: 1.25,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );

    final inner = Stack(
      clipBehavior: Clip.hardEdge,
      fit: fixedHeight != null ? StackFit.expand : StackFit.loose,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: SvgPicture.asset(
              'assets/icons/uspex.svg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              colorFilter: const ColorFilter.mode(
                Color(0x1AFFFFFF),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        if (fixedHeight != null)
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padL, padV, padL, padV),
              child: textColumn,
            ),
          )
        else
          Padding(
            padding: EdgeInsets.fromLTRB(padL, padV, padL, padV),
            child: textColumn,
          ),
      ],
    );

    return Container(
      height: fixedHeight,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            offset: Offset(4 * layoutScale, 5 * layoutScale),
            blurRadius: 4 * layoutScale,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: inner,
      ),
    );
  }

  List<BoxShadow> _shadowProfile(double layoutScale) => [
        BoxShadow(
          color: const Color(0x1A000000),
          offset: Offset(4 * layoutScale, 5 * layoutScale),
          blurRadius: 4 * layoutScale,
          spreadRadius: 0,
        ),
      ];

  Widget _studentTicketCard({
    required double layoutScale,
    required String ticketNumber,
    required VoidCallback onCopy,
  }) {
    const titleColor = Color(0xFF2563EB);
    final r = 13 * layoutScale;
    final titleFs = 13 * layoutScale;
    final valueFs = 12 * layoutScale;
    final pad = 12 * layoutScale;
    final iconStr = 10 * layoutScale;
    final iconCopy = 16 * layoutScale;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
        boxShadow: _shadowProfile(layoutScale),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                pad,
                pad + iconStr,
                pad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Студенческий билет',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: titleFs,
                      height: 1.1,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 2 * layoutScale),
                  Padding(
                    padding: EdgeInsets.only(right: iconCopy + 4 * layoutScale),
                    child: Text(
                      ticketNumber,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: valueFs,
                        height: 1.15,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: pad,
              top: pad,
              child: SvgPicture.asset(
                'assets/icons/str.svg',
                width: iconStr,
                height: iconStr,
                colorFilter: const ColorFilter.mode(
                  titleColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Positioned(
              right: pad,
              bottom: pad,
              child: GestureDetector(
                onTap: onCopy,
                behavior: HitTestBehavior.opaque,
                child: SvgPicture.asset(
                  'assets/icons/copy.svg',
                  width: iconCopy,
                  height: iconCopy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _absencesCard({
    required double layoutScale,
    required String hoursLabel,
  }) {
    const titleColor = Color(0xFFFFFFFF);
    final r = 13 * layoutScale;
    final titleFs = 13 * layoutScale;
    final valueFs = 12 * layoutScale;
    final pad = 12 * layoutScale;
    final decoW = 88 * layoutScale;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0267FB),
        borderRadius: BorderRadius.circular(r),
        boxShadow: _shadowProfile(layoutScale),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -6 * layoutScale,
              top: 0,
              bottom: 0,
              width: decoW,
              child: IgnorePointer(
                child: SizedBox.expand(
                  child: SvgPicture.asset(
                    'assets/icons/uspex.svg',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    colorFilter: const ColorFilter.mode(
                      Color(0x1AFFFFFF),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Пропуски',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: titleFs,
                              height: 1.1,
                              color: titleColor,
                            ),
                          ),
                          SizedBox(height: 2 * layoutScale),
                          Text(
                            hoursLabel,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: valueFs,
                              height: 1.15,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/str.svg',
                      width: 10 * layoutScale,
                      height: 10 * layoutScale,
                      colorFilter: const ColorFilter.mode(
                        titleColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteParentDialog extends StatefulWidget {
  const _InviteParentDialog({required this.onInvited});

  final void Function(String parentEmail) onInvited;

  @override
  State<_InviteParentDialog> createState() => _InviteParentDialogState();
}

class _InviteParentDialogState extends State<_InviteParentDialog> {
  late final TextEditingController _emailCtrl;
  bool _busy = false;
  String? _errorText;
  Map<String, dynamic>? _parentStatus;
  bool _statusLoading = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    unawaited(_loadStatus());
  }

  Future<void> _loadStatus() async {
    try {
      final s = await AppContainer.accountApi.getParentStatus();
      if (!mounted) return;
      setState(() {
        _parentStatus = s;
        _statusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _serverLinked => _parentStatus?['linked'] == true;

  bool get _serverPending {
    if (_serverLinked) return false;
    final st = (_parentStatus?['link_status'] ?? '').toString().toLowerCase().trim();
    return st == 'pending' ||
        st == 'invited' ||
        st == 'awaiting' ||
        st == 'awaiting_parent' ||
        _parentStatus?['invite_pending'] == true;
  }

  Future<void> _submit() async {
    final parentEmail = _emailCtrl.text.trim();
    if (_busy) return;
    final masked = (_parentStatus?['parent_email_masked'] ?? '').toString().trim();
    if (_serverLinked) {
      setState(() {
        _errorText = masked.isNotEmpty
            ? 'Родитель уже приглашён: $masked'
            : 'Родитель уже приглашён';
      });
      return;
    }
    if (_serverPending) {
      setState(() => _errorText = 'Уже ожидает подтверждения у родителя');
      return;
    }
    if (parentEmail.isEmpty) {
      setState(() => _errorText = 'Введите e-mail родителя');
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    var didPop = false;
    try {
      await AppContainer.accountApi.inviteParent(parentEmail: parentEmail);
      if (!mounted) return;
      didPop = true;
      Navigator.of(context).pop();
      widget.onInvited(parentEmail);
    } catch (e) {
      final msg = (e is ApiException && e.message.trim().isNotEmpty)
          ? e.message.trim()
          : 'Не удалось отправить приглашение';
      if (mounted) setState(() => _errorText = msg);
    } finally {
      if (mounted && !didPop) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = (_parentStatus?['parent_email_masked'] ?? '').toString().trim();
    final linkStatus = (_parentStatus?['link_status'] ?? '').toString().trim();
    final isActive = linkStatus.toLowerCase() == 'active';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Приглашение родителя',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 24 / 18,
                color: const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 10),
            if (!_statusLoading && !_serverPending && !_serverLinked) ...[
              Text(
                'Укажите e-mail родителя — мы отправим письмо с приглашением и ссылкой для подключения.',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                  color: const Color(0xFF000000),
                ),
              ),
            ],
            if (_statusLoading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ] else if (_serverLinked && isActive) ...[
              const SizedBox(height: 8),
              Text(
                'Родитель подключён к аккаунту.',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ] else if (_serverLinked) ...[
              const SizedBox(height: 8),
              Text(
                masked.isNotEmpty
                    ? 'Статус: ${linkStatus.isEmpty ? 'ожидание' : linkStatus}. E-mail: $masked'
                    : 'Статус: ${linkStatus.isEmpty ? 'ожидание' : linkStatus}',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.2,
                  color: const Color(0xFF2E63D5),
                ),
              ),
            ] else if (_serverPending) ...[
              const SizedBox(height: 8),
              Text(
                'Ожидает подтверждения',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.25,
                  color: const Color(0xFFD97706),
                ),
              ),
              if (masked.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Письмо на: $masked',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                    color: const Color(0xB3000000),
                  ),
                ),
              ],
            ],
            if (!_statusLoading && _serverLinked && isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 35,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E63D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Закрыть',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else if (!_statusLoading && _serverLinked && !isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 35,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E63D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Закрыть',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else if (!_statusLoading && _serverPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 35,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E63D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Закрыть',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else if (!_statusLoading) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_errorText == null)
                          ? const Color(0xFF000000)
                          : const Color(0xFFE11D48),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    maxLines: 1,
                    enabled: !_busy && !_serverLinked,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      border: InputBorder.none,
                      hintText: 'parent@email.ru',
                    ),
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.0,
                      color: const Color(0xFF000000),
                    ),
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorText!,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.1,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _busy ? null : _submit,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _busy
                                ? const Color(0xFF2E63D5).withValues(alpha: 0.4)
                                : const Color(0xFF2E63D5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Отправить приглашение',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    height: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    height: 30,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFF2E63D5),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Отмена',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.0,
                            color: const Color(0xFF2E63D5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
