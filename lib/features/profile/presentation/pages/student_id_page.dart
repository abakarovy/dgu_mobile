import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/widgets/app_header.dart';

/// Экран «Студенческий билет»: AppBar как у поддержки, контейнер с отступами 24, ФИО, ID, копирование, даты, форма, курс.
class StudentIdPage extends StatefulWidget {
  const StudentIdPage({super.key});

  @override
  State<StudentIdPage> createState() => _StudentIdPageState();
}

class _StudentIdPageState extends State<StudentIdPage> {
  late final Future<UserModel> _meFuture;
  static const String _studentPhotoAsset = 'assets/images/alibek.png';
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
    _meFuture = _loadMe();
  }

  @override
  void dispose() {
    _copiedToastTimer?.cancel();
    super.dispose();
  }

  String _copyableText(UserModel me) {
    final fullName = _safe(me.fullName);
    final id = _studentId(me);
    final birthDate = _birthDate(me);
    final department = _department(me);
    final studyGroup = _studyGroup(me);
    final admissionYear = _admissionYear(me);
    final studyForm = _studyForm(me);
    final status = _status(me);
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
    await Clipboard.setData(ClipboardData(text: _copyableText(me)));
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
            child: FutureBuilder<UserModel>(
              future: _meFuture,
              builder: (context, snap) {
                final me = snap.data;
                if (me == null) {
                  return const SizedBox.shrink();
                }
                final fullName = _safe(me.fullName);
                final id = _studentId(me);
                final birthDate = _birthDate(me);
                final department = _department(me);
                final studyGroup = _studyGroup(me);
                final course = _course(me);
                final admissionYear = _admissionYear(me);
                final studyForm = _studyForm(me);
                final status = _status(me);

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
                                child: Image.asset(
                                  _studentPhotoAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.person,
                                    size: 56,
                                    color: AppColors.caption,
                                  ),
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

  Future<UserModel> _loadMe() async {
    const cacheKey = 'auth:me';
    final cached = AppContainer.jsonCache.getJsonMap(cacheKey);
    if (cached != null) return UserModel.fromJson(cached);
    final fresh = await AppContainer.authApi.getMe();
    await AppContainer.jsonCache.setJson(cacheKey, fresh.toJson());
    return fresh;
  }

  static String _safe(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

  static String _studentId(UserModel me) =>
      _safe(me.studentBookNumber).replaceAll(' ', '');

  static String _birthDate(UserModel me) => '1.11.2008';

  static String _department(UserModel me) =>
      'Право и организация социального обеспечения';

  static String _studyGroup(UserModel me) => 'ПСО 1к 1г 2025';

  static String _admissionYear(UserModel me) => '2025';

  static String _studyForm(UserModel me) => me.role == 'student' ? 'Очная' : '-';
  static String _course(UserModel me) => me.course?.toString() ?? '-';

  static String _status(UserModel me) => me.isActive ? 'Обучается' : 'Неактивен';
}
