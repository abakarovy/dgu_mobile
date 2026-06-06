import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';

class StaffUserTile extends StatelessWidget {
  const StaffUserTile({super.key, required this.user});

  final Map<String, dynamic> user;

  String get _name {
    final n = user['full_name'] ?? user['fio'] ?? user['email'];
    return (n ?? '—').toString();
  }

  String get _email => (user['email'] ?? '').toString();

  String get _role => (user['role'] ?? '').toString();

  bool get _isActive {
    final s = user['status'] ?? user['is_active'];
    if (s == true || s == 'active' || s == 'Активен') return true;
    if (s == false || s == 'inactive') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.backgroundBlue,
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : '?',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ),
          const SizedBox(width: AppUi.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: AppTextStyle.inter(
                      fontSize: 13,
                      color: AppColors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_role.isNotEmpty) _pill(_role, AppColors.backgroundBlue, AppColors.lightBlue),
                    _pill(
                      _isActive ? 'Активен' : 'Неактивен',
                      _isActive
                          ? const Color(0xFFDCFCE7)
                          : AppColors.lightGrey.withValues(alpha: 0.35),
                      _isActive ? const Color(0xFF15803D) : AppColors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyle.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
