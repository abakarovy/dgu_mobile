import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/staff_user_name_format.dart';
import 'staff_admin_ui.dart';

int? staffParseUserId(dynamic raw) {
  if (raw is int) return raw;
  return int.tryParse('$raw');
}

String staffStudentPickerLabel(Map<String, dynamic> user) {
  final name = StaffUserNameFormat.displayNameFromUser(user);
  final email = (user['email'] ?? '').toString().trim();
  if (name.isNotEmpty && name != '—' && email.isNotEmpty) return '$name · $email';
  return name.isNotEmpty && name != '—' ? name : email;
}

bool _studentMatchesQuery(
  Map<String, dynamic> student,
  String query, {
  required bool includeBookNumber,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (staffStudentPickerLabel(student).toLowerCase().contains(q)) return true;
  if (!includeBookNumber) return false;
  final book = (student['student_book_number'] ?? '').toString().toLowerCase();
  return book.contains(q);
}

/// Поиск студента с автодополнением (как при добавлении в группу).
class StaffStudentSearchPicker extends StatelessWidget {
  const StaffStudentSearchPicker({
    super.key,
    required this.students,
    required this.onSelected,
    this.enabled = true,
    this.hint = 'Поиск по имени или e-mail',
    this.includeBookNumber = false,
  });

  final List<Map<String, dynamic>> students;
  final ValueChanged<int?> onSelected;
  final bool enabled;
  final String hint;
  final bool includeBookNumber;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return TextField(
        enabled: false,
        decoration: StaffAdminUi.fieldDecoration(
          'Студент',
          hint: 'Нет доступных студентов',
        ),
      );
    }

    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (value) {
        return students.where(
          (s) => _studentMatchesQuery(
            s,
            value.text,
            includeBookNumber: includeBookNumber,
          ),
        );
      },
      displayStringForOption: staffStudentPickerLabel,
      onSelected: (s) => onSelected(staffParseUserId(s['id'])),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: StaffAdminUi.fieldDecoration('Студент', hint: hint),
          onChanged: (_) => onSelected(null),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: StaffAdminUi.cardBorder.withValues(alpha: 0.7),
                ),
                itemBuilder: (context, index) {
                  final s = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Text(
                        staffStudentPickerLabel(s),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
