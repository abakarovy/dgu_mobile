import '../../data/models/user_model.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// Роли персонала (см. docs/MOBILE_STAFF_AND_ADMIN.md).
/// Меню строится по [StaffCapabilitiesModel] с API; здесь — fallback и утилиты.
abstract final class StaffRoles {
  static const staffRoles = {
    'teacher',
    'department',
    'department_methodist',
    'admin',
    'event_manager',
    'methodist',
  };

  static bool isStaff(String? role) =>
      staffRoles.contains(role?.trim().toLowerCase());

  /// Fallback, если capabilities ещё не загружены.
  static bool canViewApplicants(UserModel? user) {
    if (user == null) return false;
    if (user.canAccessAdmissionAdmin) return true;
    final r = user.role.trim().toLowerCase();
    return r == 'admin' || r == 'event_manager' || r == 'methodist';
  }

  static bool canViewApplicantsByRole(String? role) {
    final r = role?.trim().toLowerCase();
    return r == 'admin' || r == 'event_manager' || r == 'methodist';
  }

  static bool canViewAdmission(UserEntity? user) {
    if (user == null) return false;
    if (user.canAccessAdmissionAdmin) return true;
    return canViewApplicantsByRole(user.role);
  }

  /// Установка проходного балла — только is_admin.
  static bool canSetPaymentCutoff({required bool isAdmin}) => isAdmin;

  static String applicantsStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'registered':
        return 'Зарегистрирован';
      case 'payment_list':
        return 'На оплату';
      case 'rejected':
        return 'Отклонён';
      case 'enrolled':
        return 'Зачислен';
      default:
        return status;
    }
  }
}
