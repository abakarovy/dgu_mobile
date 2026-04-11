import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_constants.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/utils/parent_child_name.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/data/api/api_exception.dart';
import 'package:flutter/material.dart';
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
    // Единый вертикальный отступ между кнопками/карточками внизу профиля.
    final actionGap = 6 * layoutScale;

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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minProfileCardHeight),
                child: _courseCard(
                  layoutScale: layoutScale,
                  courseText: course.isEmpty ? '—' : '$course курс',
                  directionText: direction.isEmpty ? '—' : direction,
                  groupText: groupLine.isEmpty ? null : groupLine,
                ),
              ),
            ),
            SizedBox(height: gapM),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minProfileCardHeight),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/app/profile/student-id'),
                          child: _studentTicketCard(
                            layoutScale: layoutScale,
                            ticketNumber: ticketNo,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: gapM),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minProfileCardHeight),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/app/profile/absences'),
                          child: _absencesCard(
                            layoutScale: layoutScale,
                            hoursLabel: absenceLabel,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Отступ как между верхними карточками.
            SizedBox(height: gapM),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((me?.role ?? '').trim().toLowerCase() != 'parent')
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                      final emailCtrl = TextEditingController();
                      bool busy = false;
                      String? errorText;
                      Map<String, dynamic>? parentStatus;
                      bool statusLoaded = false;
                      bool statusLoading = false;
                      showDialog<void>(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.35),
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setLocal) {
                              final linked = (parentStatus?['linked'] == true);
                              final masked =
                                  (parentStatus?['parent_email_masked'] ?? '').toString().trim();
                              final linkStatus =
                                  (parentStatus?['link_status'] ?? '').toString().trim();
                              final isActive = linkStatus.toLowerCase() == 'active';
                              if (!statusLoaded && !statusLoading) {
                                statusLoading = true;
                                unawaited(() async {
                                  try {
                                    final s = await AppContainer.accountApi.getParentStatus();
                                    if (context.mounted) {
                                      setLocal(() {
                                        parentStatus = s;
                                        statusLoaded = true;
                                        statusLoading = false;
                                      });
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      setLocal(() {
                                        statusLoaded = true;
                                        statusLoading = false;
                                      });
                                    }
                                  }
                                }());
                              }

                              Future<void> submit() async {
                                final parentEmail = emailCtrl.text.trim();
                                if (busy) return;
                                if (linked) {
                                  setLocal(() {
                                    errorText = masked.isNotEmpty
                                        ? 'Родитель уже приглашён: $masked'
                                        : 'Родитель уже приглашён';
                                  });
                                  return;
                                }
                                if (parentEmail.isEmpty) {
                                  setLocal(() => errorText = 'Введите e-mail родителя');
                                  return;
                                }
                                setLocal(() {
                                  busy = true;
                                  errorText = null;
                                });
                                try {
                                  await AppContainer.accountApi.inviteParent(
                                    parentEmail: parentEmail,
                                  );
                                  if (context.mounted) Navigator.of(context).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Text('Приглашение отправили на $parentEmail'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  final msg = (e is ApiException && e.message.trim().isNotEmpty)
                                      ? e.message.trim()
                                      : 'Не удалось отправить приглашение';
                                  setLocal(() => errorText = msg);
                                } finally {
                                  if (context.mounted) setLocal(() => busy = false);
                                }
                              }

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
                                      Text(
                                        'Укажите e-mail родителя — мы отправим письмо с приглашением и ссылкой для подключения.',
                                        style: AppTextStyle.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          height: 1.2,
                                          color: const Color(0xFF000000),
                                        ),
                                      ),
                                      if (statusLoading) ...[
                                        const SizedBox(height: 10),
                                        const LinearProgressIndicator(minHeight: 2),
                                      ] else if (linked) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          masked.isNotEmpty
                                              ? 'Статус: ${linkStatus.isEmpty ? 'pending' : linkStatus}. Email: $masked'
                                              : 'Статус: ${linkStatus.isEmpty ? 'pending' : linkStatus}',
                                          style: AppTextStyle.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            height: 1.2,
                                            color: const Color(0xFF2E63D5),
                                          ),
                                        ),
                                      ],
                                      if (isActive) ...[
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
                                      ] else ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 44,
                                          child: Container(
                                            width: double.infinity,
                                            padding:
                                                const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: (errorText == null)
                                                    ? const Color(0xFF000000)
                                                    : const Color(0xFFE11D48),
                                                width: 1.5,
                                              ),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: TextField(
                                              controller: emailCtrl,
                                              keyboardType: TextInputType.emailAddress,
                                              textInputAction: TextInputAction.done,
                                              onSubmitted: (_) => submit(),
                                              maxLines: 1,
                                              enabled: !busy && !linked,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(vertical: 14),
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
                                                if (errorText != null) {
                                                  setLocal(() => errorText = null);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        if (errorText != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            errorText!,
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
                                                  onTap: busy ? null : submit,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: busy
                                                          ? const Color(0xFF2E63D5)
                                                              .withValues(alpha: 0.4)
                                                          : const Color(0xFF2E63D5),
                                                      borderRadius:
                                                          BorderRadius.circular(15),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: busy
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                      Color>(
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
                                                              fontWeight:
                                                                  FontWeight.w700,
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
                                                    borderRadius:
                                                        BorderRadius.circular(15),
                                                    border: Border.all(
                                                      color:
                                                          const Color(0xFF2E63D5),
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
                                                      color:
                                                          const Color(0xFF2E63D5),
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
                            },
                          );
                        },
                      ).whenComplete(emailCtrl.dispose);
                      },
                      child: _primaryActionCard(
                        layoutScale: layoutScale,
                        title: 'Пригласить родителя',
                        subtitle: 'Родитель получит доступ к вашим данным об успеваемости',
                      ),
                    ),
                  SizedBox(height: actionGap),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.push('/account/certificate-order');
                    },
                    child: _secondaryActionCard(
                      layoutScale: layoutScale,
                      title: 'Заказать справку с места учебы',
                    ),
                  ),
                  SizedBox(height: actionGap),
                  _mailCard(
                    layoutScale: layoutScale,
                    email: () {
                      final e = (me?.email ?? '').trim();
                      return e.isEmpty ? '—' : e;
                    }(),
                    onChangePassword: (me?.role ?? '').trim().toLowerCase() == 'parent'
                        ? null
                        : () => context.push('/account/password-reset'),
                    onChangeEmail: (me?.role ?? '').trim().toLowerCase() == 'parent'
                        ? null
                        : () => context.push('/account/email-change'),
                  ),
                  SizedBox(height: actionGap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryActionCard({
    required double layoutScale,
    required String title,
    required String subtitle,
  }) {
    final r = 26.4 * layoutScale;
    // 53px по макету
    final h = 70 * layoutScale;
    final titleFs = 11.53 * layoutScale * 1.5 / 1.2;
    final subFs = 8.56 * layoutScale * 1.5 / 1.2;
    return SizedBox(
      height: h,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0267FB),
          borderRadius: BorderRadius.circular(r),
          boxShadow: _shadowProfile(layoutScale),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 14.4 * layoutScale,
          vertical: 6 * layoutScale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w800,
                fontSize: titleFs,
                height: 1.0,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2 * layoutScale),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w600,
                fontSize: subFs,
                height: 1.1,
                color: const Color(0x70FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryActionCard({
    required double layoutScale,
    required String title,
  }) {
    final r = 26.4 * layoutScale;
    // Такой же размер, как у "Пригласить родителя".
    final titleFs = 11.53 * layoutScale * 1.5 / 1.2;
    final h = 70 * layoutScale;
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
        padding: EdgeInsets.symmetric(horizontal: 14.4 * layoutScale),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: titleFs,
            height: 1.05,
            color: const Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  Widget _mailCard({
    required double layoutScale,
    required String email,
    VoidCallback? onChangePassword,
    VoidCallback? onChangeEmail,
  }) {
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
                  color: const Color(0x52000000), // #00000052
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
  }) {
    final r = 22 * layoutScale;
    final padL = 16 * layoutScale;
    final padV = 14 * layoutScale;
    final courseFs = 17.2 * layoutScale;
    final subFs = 13.0 * layoutScale;
    final decoW = 96 * layoutScale;
    return Container(
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
        // StackFit.loose: карточка курса в прокрутке с неограниченной высотой.
        // Без LayoutBuilder — иначе ломается IntrinsicHeight у ряда студбилет/пропуски.
        child: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.loose,
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
            Padding(
              padding: EdgeInsets.fromLTRB(padL, padV, padL, padV),
              child: Column(
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
              ),
            ),
          ],
        ),
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
  }) {
    final r = 26.4 * layoutScale;
    final titleFs = 14.5 * layoutScale;
    final valueFs = 14.0 * layoutScale;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
        boxShadow: _shadowProfile(layoutScale),
      ),
      padding: EdgeInsets.all(16 * layoutScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Студенческий билет',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: titleFs,
              height: 1.1,
              color: const Color(0xFF000000),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              ticketNumber,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w600,
                fontSize: valueFs,
                height: 1.1,
                color: const Color(0xFF999999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _absencesCard({
    required double layoutScale,
    required String hoursLabel,
  }) {
    final pad = 16 * layoutScale;
    final r = 26.4 * layoutScale;
    final titleFs = 14.5 * layoutScale;
    final valueFs = 11.5 * layoutScale;
    final decoW = 88 * layoutScale;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0267FB),
        borderRadius: BorderRadius.circular(r),
        boxShadow: _shadowProfile(layoutScale),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        // expand: в ряду со студбилетом высота задана растягиванием; без LayoutBuilder — см. IntrinsicHeight выше.
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Пропуски',
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: titleFs,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8 * layoutScale),
                    const Spacer(),
                    Text(
                      hoursLabel,
                      textAlign: TextAlign.right,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: valueFs,
                        height: 1.2,
                        color: Colors.white,
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
