import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/staff_user_status.dart';

/// Общие элементы UI админ-панели (как на сайте college.dgu.ru).
abstract final class StaffAdminUi {
  static const bg = Color(0xFFF1F5F9);

  /// Горизонтальные отступы вкладок Дашборд / Пользователи / Инструменты.
  static const double tabPaddingH = 12;
  static const EdgeInsets tabPaddingAll = EdgeInsets.all(tabPaddingH);

  /// Высота pill-контролов (фильтр ролей, кнопка «Создать»).
  static const double pillControlHeight = 44;
  static const cardBorder = Color(0xFFE2E8F0);
  static const navy = Color(0xFF1E293B);
  static const primaryBlue = Color(0xFF2563EB);
  static const barGreen = Color(0xFF3D704D);
  static const stripeA = Colors.white;
  static const stripeB = Color(0xFFF8FAFC);

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: cardBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static Widget pageTitle(String title) => Text(
    title,
    style: AppTextStyle.inter(
      fontWeight: FontWeight.w800,
      fontSize: 22,
      color: AppColors.textPrimary,
    ),
  );

  static Widget infoBanner(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      text,
      style: AppTextStyle.inter(
        fontSize: 13,
        height: 1.35,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    ),
  );

  /// Pill-переключатель вкладок (новости/мероприятия, на проверке/завершённые).
  static Widget segmentSwitch({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color activeColor = primaryBlue,
  }) {
    return Container(
      height: pillControlHeight,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedIndex == i ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: selectedIndex == i ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget adminCheckboxTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          label,
          style: AppTextStyle.inter(fontSize: 13, height: 1.35),
        ),
        value: value,
        activeColor: primaryBlue,
        onChanged: onChanged,
      ),
    );
  }

  static Widget fieldHint(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: AppTextStyle.inter(fontSize: 11, height: 1.35, color: AppColors.grey),
    ),
  );

  static Widget sectionCard({
    required String title,
    String? subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyle.inter(
                          fontSize: 12,
                          color: AppColors.grey,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool compact = false,
    bool fullWidth = false,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: fullWidth
            ? const Size(double.infinity, pillControlHeight)
            : (compact ? const Size(0, pillControlHeight) : null),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 0 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  static Widget outlineButton({
    required String label,
    required VoidCallback? onPressed,
    bool compact = false,
    bool fullWidth = false,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: cardBorder),
        minimumSize: fullWidth
            ? const Size(double.infinity, pillControlHeight)
            : (compact ? const Size(0, pillControlHeight) : null),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 0 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: AppTextStyle.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      child: Text(label),
    );
  }

  static Widget outlineNavyButton({
    required String label,
    required VoidCallback? onPressed,
    bool fullWidth = false,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        side: BorderSide(color: navy.withValues(alpha: 0.45)),
        minimumSize: fullWidth
            ? const Size(double.infinity, pillControlHeight)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      child: Text(label),
    );
  }

  static Widget darkButton({
    required String label,
    required VoidCallback? onPressed,
    bool fullWidth = false,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        minimumSize: fullWidth
            ? const Size(double.infinity, pillControlHeight)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      child: Text(label),
    );
  }

  static Widget pillDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      height: pillControlHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            isDense: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.grey,
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      label(e),
                      style: AppTextStyle.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  static InputDecoration fieldDecoration(
    String label, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      labelStyle: AppTextStyle.inter(fontSize: 13, color: AppColors.grey),
      hintStyle: AppTextStyle.inter(fontSize: 14, color: AppColors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }

  static Widget statusBadge({required bool active}) {
    return userStatusBadgeFromInfo(
      StaffUserStatus.fromUser({'is_active': active}),
    );
  }

  /// Компактный бейдж статуса (для строк списка).
  static Widget compactStatusBadge({required bool active}) {
    final info = StaffUserStatus.fromUser({'is_active': active});
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: info.foregroundColor),
          const SizedBox(width: 4),
          Text(
            info.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: info.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  static Widget userStatusBadge(Map<String, dynamic> user) {
    final items = StaffUserStatus.allFromUser(user);
    if (items.length == 1) {
      return userStatusBadgeFromInfo(items.first);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          userStatusBadgeFromInfo(items[i]),
        ],
      ],
    );
  }

  static Widget userStatusBadgeFromInfo(StaffUserStatusInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 7, color: info.foregroundColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              info.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: info.foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Таблица с чередующимися строками (полосы), как на сайте.
class StaffStripedTable extends StatelessWidget {
  const StaffStripedTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onColumnHeaderTap,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final void Function(int index)? onRowTap;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex)? onColumnHeaderTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                for (int i = 0; i < columns.length; i++)
                  Expanded(
                    flex: i == 0 ? 3 : 2,
                    child: onColumnHeaderTap != null
                        ? InkWell(
                            onTap: () => onColumnHeaderTap!(i),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      columns[i],
                                      style: AppTextStyle.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: sortColumnIndex == i
                                            ? StaffAdminUi.primaryBlue
                                            : AppColors.grey,
                                      ),
                                    ),
                                  ),
                                  if (sortColumnIndex == i) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: StaffAdminUi.primaryBlue,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : Text(
                            columns[i],
                            style: AppTextStyle.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                            ),
                          ),
                  ),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            Material(
              color: i.isEven ? StaffAdminUi.stripeA : StaffAdminUi.stripeB,
              child: InkWell(
                onTap: onRowTap != null ? () => onRowTap!(i) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int j = 0; j < rows[i].length; j++)
                        Expanded(flex: j == 0 ? 3 : 2, child: rows[i][j]),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
