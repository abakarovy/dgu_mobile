import 'dart:io';
import 'dart:math' show min;

import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_constants.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/models/one_c_my_profile.dart';
import '../../../../data/models/student_ticket_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../grades/domain/entities/grade_entity.dart';

/// Вкладка «Профиль» — данные аккаунта, образование, личные данные и настройки.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _savedAvatarPath;
  UserModel? _me;
  StudentTicketModel? _ticket;
  OneCMyProfile? _oneC;
  /// Подпись пропусков с `GET /api/1c/absences` (после загрузки).
  String? _absenceHoursText;
  /// Средний балл по кэшу оценок (текущий семестр), как на главной.
  String? _performanceAvgText;

  @override
  void initState() {
    super.initState();
    _me = _readCachedMe();
    _ticket = _readCachedTicket();
    _oneC = _readCachedOneC();
    _absenceHoursText = _readCachedAbsencesLabel();
    _applyPerformanceFromCache();
    _loadAvatarPath();
    _refreshMeInBackground();
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
    final cached = AppContainer.jsonCache.getJsonMap('1c:my-profile');
    if (cached == null) return null;
    try {
      return OneCMyProfile.fromJson(cached);
    } catch (_) {
      return null;
    }
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
    try {
      final fresh = await AppContainer.authApi
          .getMe()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('auth:me', fresh.toJson());
      if (mounted) {
        setState(() {
          _me = fresh;
        });
      }
    } catch (_) {}

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

    try {
      final p = await AppContainer.profile1cApi
          .getMyProfile()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('1c:my-profile', p.toJsonMap());
      if (mounted) {
        setState(() {
          _oneC = p;
        });
      }
    } catch (_) {}

    try {
      final bundle = await AppContainer.gradesApi
          .loadMyGrades()
          .timeout(ApiConstants.prefetchRequestTimeout);
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
      if (mounted) {
        setState(_applyPerformanceFromCache);
      }
    } catch (_) {}

    try {
      final sem = _currentSemesterLabel(_loadGradesFromCache());
      final abs = await AppContainer.profile1cApi
          .getAbsencesDisplayLabel(currentSemester: sem)
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

  void _applyPerformanceFromCache() {
    final grades = _loadGradesFromCache();
    if (grades.isEmpty) {
      _performanceAvgText = null;
      return;
    }
    final currentSem = _currentSemesterLabel(grades);
    final avg = _calcAverage(grades, semester: currentSem) ??
        _calcAverage(grades, semester: null);
    _performanceAvgText = avg?.toStringAsFixed(2);
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

  double? _calcAverage(List<GradeEntity> grades, {required String? semester}) {
    final nums = <double>[];
    for (final g in grades) {
      if (semester != null && g.semester?.trim() != semester) continue;
      final raw = g.grade.trim().replaceAll(',', '.');
      final v = double.tryParse(raw);
      if (v != null) nums.add(v);
    }
    if (nums.isEmpty) return null;
    final sum = nums.fold<double>(0, (a, b) => a + b);
    return sum / nums.length;
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
    final path = prefs.getString(AppConstants.profileAvatarPathKey);
    if (path != null && mounted) {
      setState(() => _savedAvatarPath = path);
    }
  }

  Future<void> _pickAndSaveAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/${AppConstants.profileAvatarFileName}');
      await file.writeAsBytes(await xFile.readAsBytes());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.profileAvatarPathKey, file.path);
      if (mounted) {
        setState(() => _savedAvatarPath = file.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить фото')),
        );
      }
    }
  }

  /// Как на студенческом билете: «Очная форма обучения» и т.п.
  String _educationFormFull(UserModel? me) {
    final t = _ticket;
    final c = _oneC;
    final raw = (t?.studyForm?.trim().isNotEmpty == true)
        ? t!.studyForm!.trim()
        : (c?.studyForm?.trim().isNotEmpty == true)
            ? c!.studyForm!.trim()
            : '';
    if (raw.isEmpty) {
      if (me?.role == 'student') {
        return 'Очная форма обучения';
      }
      return '—';
    }
    final lower = raw.toLowerCase();
    if (lower.contains('форма')) {
      return raw;
    }
    return '$raw форма обучения';
  }

  String _displayTicketNumber(UserModel? me) {
    final t = _ticket?.studentBookNumber?.trim();
    if (t != null && t.isNotEmpty) return t;
    final c = _oneC?.studentBookNumber?.trim();
    if (c != null && c.isNotEmpty) return c;
    final m = me?.studentBookNumber?.trim();
    if (m != null && m.isNotEmpty) return m;
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final fullName = (me?.fullName ?? '').trim();
    final course = (me?.course?.toString() ?? '').trim();
    final direction = (me?.direction ?? '').trim();
    final formFull = _educationFormFull(me);
    final ticketNo = _displayTicketNumber(me);
    final absenceLabel = _absenceHoursText ?? '—';
    final performanceLabel = _performanceAvgText ?? '—';

    // Макет 402×874 — как на главной (`HomePage`).
    final size = MediaQuery.sizeOf(context);
    final layoutScale = min(size.width / 402, size.height / 874);
    final minProfileCardHeight = 100 * layoutScale;

    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topHero(
              fullName: fullName.isEmpty ? '—' : fullName,
              onAvatarTap: _pickAndSaveAvatar,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minProfileCardHeight),
                        child: _courseCard(
                          layoutScale: layoutScale,
                          courseText: course.isEmpty ? '—' : '$course курс',
                          directionText: direction.isEmpty ? '—' : direction,
                          formText: formFull,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minProfileCardHeight),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go('/app/grades?tab=0'),
                          child: _performanceCard(valueText: performanceLabel),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    const SizedBox(width: 16),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _topHero({
    required String fullName,
    required VoidCallback onAvatarTap,
  }) {
    return SizedBox(
      height: 309,
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
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/profile_image.png',
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerRight,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: Colors.white, width: 3.34),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          offset: Offset(0, 8.35),
                          blurRadius: 20.86,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: _avatarImage(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20.03,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Колледж ДГУ',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.5,
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

  Widget _avatarImage() {
    final p = _savedAvatarPath;
    if (p != null && p.isNotEmpty) {
      final f = File(p);
      return Image.file(f, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackAvatar());
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: const Icon(Icons.person, color: Colors.white, size: 48),
    );
  }

  Widget _courseCard({
    required double layoutScale,
    required String courseText,
    required String directionText,
    required String formText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(4, 5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -8,
              top: 0,
              bottom: 0,
              child: SvgPicture.asset(
                'assets/icons/uspex.svg',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                width: 120 * layoutScale,
                colorFilter: const ColorFilter.mode(
                  Color(0x1AFFFFFF),
                  BlendMode.srcIn,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseText,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.95,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    directionText,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 10.0224,
                      height: 1.0,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: double.infinity),
                      padding: const EdgeInsets.symmetric(horizontal: 7.2, vertical: 3.6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.2),
                      ),
                      child: Text(
                        formText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 7.8,
                          height: 1.15,
                          color: const Color(0xFF1E293B),
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
    );
  }

  Widget _performanceCard({required String valueText}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(4, 5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x1A2E63D5),
                  borderRadius: BorderRadius.circular(10.62),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/uspex.svg',
                    width: 14.4,
                    height: 14.4,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF2563EB),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14.4),
              Expanded(
                child: Text(
                  'Успеваемость',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.064,
                    height: 1.0,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              valueText,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 22.224,
                height: 1.0,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _shadowProfile = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(4, 5),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  Widget _studentTicketCard({
    required double layoutScale,
    required String ticketNumber,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26.4),
        boxShadow: _shadowProfile,
      ),
      padding: EdgeInsets.all(14.4 * layoutScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Студенческий билет',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 11.53 * layoutScale,
              height: 1.0,
              color: const Color(0xFF000000),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              ticketNumber,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w600,
                fontSize: 11.13 * layoutScale,
                height: 1.0,
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
    final pad = 14.4 * layoutScale;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0267FB),
        borderRadius: BorderRadius.circular(26.4),
        boxShadow: _shadowProfile,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -8,
              top: 0,
              bottom: 0,
              child: SvgPicture.asset(
                'assets/icons/uspex.svg',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                width: 120 * layoutScale,
                colorFilter: const ColorFilter.mode(
                  Color(0x1AFFFFFF),
                  BlendMode.srcIn,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пропуски',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.53 * layoutScale,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3 * layoutScale),
                  Text(
                    hoursLabel,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 8.56 * layoutScale,
                      height: 1.0,
                      color: Colors.white,
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
}
