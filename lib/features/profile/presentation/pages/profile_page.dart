import 'dart:io';

import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_constants.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/models/user_model.dart';

/// Вкладка «Профиль» — данные аккаунта, образование, личные данные и настройки.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _savedAvatarPath;
  UserModel? _me;

  @override
  void initState() {
    super.initState();
    _me = _readCachedMe();
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

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final fullName = (me?.fullName ?? '').trim();
    final course = '${me?.course ?? ''}'.trim();
    final direction = '${me?.direction ?? ''}'.trim();
    final educationForm = '${me?.department ?? ''}'.trim(); // fallback if no explicit field

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _courseCard(
                    courseText: course.isEmpty ? '—' : '${course} курс',
                    directionText: direction.isEmpty ? '—' : direction,
                    formText: educationForm.isEmpty ? '—' : educationForm,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _performanceCard(valueText: '—'),
                  ),
                ],
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
      child: Stack(
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
          // Decorative image справа (если ассета нет — просто не покажется).
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/profile_image.png',
              width: 230.6774,
              height: 263.4363,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                const SizedBox(height: 4),
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
                    fontSize: 8.25,
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
      return Image.file(f, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackAvatar());
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
    required String courseText,
    required String directionText,
    required String formText,
  }) {
    return SizedBox(
      width: 180,
      height: 99,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: Icon(Icons.school, color: Colors.white, size: 44),
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
                  Text(
                    directionText,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 6.96,
                      height: 1.0,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.5),
                    ),
                    child: Center(
                      child: Text(
                        formText,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 6.5,
                          height: 1.0,
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
    return SizedBox(
      height: 99,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0x1A2E63D5),
                borderRadius: BorderRadius.circular(8.85),
              ),
              child: Center(
                child: const Icon(Icons.auto_graph, size: 14, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Успеваемость',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.72,
                      height: 1.0,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    valueText,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.52,
                      height: 1.0,
                      color: const Color(0xFF000000),
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
