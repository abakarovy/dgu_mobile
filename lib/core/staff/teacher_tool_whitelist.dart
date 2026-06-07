import '../../data/models/staff_capabilities_model.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// StaffToolsPage — только эти 6 id (не расширять для teacher).
const kAdminToolModuleIds = {
  'news',
  'groups',
  'moderation',
  'weekly_grades',
  'scholarship_rating',
  'mobile_app',
};

/// Модули кабинета преподавателя (локальный whitelist, не полный `capabilities.modules`).
const kTeacherModuleIds = {
  'journal',
  'materials',
  'news',
  'events',
  'ones',
  'profile',
  // 'notifications', // фаза 2
};

/// news + events объединены во вкладке «Контент».
const kTeacherContentModuleIds = {'news', 'events'};

bool isTeacherModule(String id) => kTeacherModuleIds.contains(id);

List<StaffModuleModel> teacherModulesFromCapabilities(
  StaffCapabilitiesModel cap,
) {
  return cap.modules.where((m) => kTeacherModuleIds.contains(m.id)).toList();
}

/// Кабинет зав. отделением — отдельная оболочка.
bool userUsesDepartmentShell(UserModel? user) {
  if (user == null) return false;
  return user.canAccessDepartmentCabinet;
}

bool userUsesDepartmentShellEntity(UserEntity? user) {
  if (user == null) return false;
  return user.canAccessDepartmentCabinet;
}

/// Кабинет преподавателя — отдельная оболочка, не админка.
bool userUsesTeacherShell(UserModel? user) {
  if (user == null) return false;
  if (user.canAccessDepartmentCabinet) return false;
  if (user.canAccessSiteAdmin || user.isAdmin) return false;
  return user.isTeacher;
}

bool userUsesTeacherShellEntity(UserEntity? user) {
  if (user == null) return false;
  if (user.canAccessDepartmentCabinet) return false;
  if (user.canAccessSiteAdmin || user.isAdmin) return false;
  return user.isTeacher;
}

/// Маршрут после входа персонала / bootstrap.
String staffHomeRoute(UserModel? user) {
  if (user == null) return '/public/home';
  if (user.canAccessDepartmentCabinet) return '/department/home';
  if (user.canAccessSiteAdmin || user.isAdmin) return '/staff/home';
  if (userUsesTeacherShell(user)) return '/teacher/home';
  return '/staff/profile';
}

String staffHomeRouteFromEntity(UserEntity? user) {
  if (user == null) return '/public/home';
  if (user.canAccessDepartmentCabinet) return '/department/home';
  if (user.canAccessSiteAdmin || user.isAdmin) return '/staff/home';
  if (userUsesTeacherShellEntity(user)) return '/teacher/home';
  return '/staff/profile';
}
