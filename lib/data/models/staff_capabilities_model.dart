/// Модуль из `GET /api/v1/staff/capabilities`.
class StaffModuleModel {
  const StaffModuleModel({
    required this.id,
    required this.label,
    this.roles = const [],
    this.apiPrefix,
    this.mobileReady = 'full',
    this.note,
  });

  final String id;
  final String label;
  final List<String> roles;
  final String? apiPrefix;
  /// `full` | `partial` | `web_only`
  final String mobileReady;
  final String? note;

  bool get isFull => mobileReady == 'full';
  bool get isPartial => mobileReady == 'partial';
  bool get isWebOnly => mobileReady == 'web_only';

  factory StaffModuleModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    return StaffModuleModel(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? json['id'] ?? '').toString(),
      roles: rolesRaw is List
          ? rolesRaw.map((e) => e.toString()).toList()
          : const [],
      apiPrefix: json['api_prefix'] as String?,
      mobileReady: (json['mobile_ready'] ?? 'full').toString(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'roles': roles,
        'api_prefix': apiPrefix,
        'mobile_ready': mobileReady,
        'note': note,
      };
}

/// Ответ `GET /api/v1/staff/capabilities`.
class StaffCapabilitiesModel {
  const StaffCapabilitiesModel({
    required this.role,
    this.isAdmin = false,
    this.canAccessSiteAdmin = false,
    this.canAccessAdmissionAdmin = false,
    this.canAccessDepartmentCabinet = false,
    this.isTeacher = false,
    this.modules = const [],
  });

  final String role;
  final bool isAdmin;
  final bool canAccessSiteAdmin;
  final bool canAccessAdmissionAdmin;
  final bool canAccessDepartmentCabinet;
  final bool isTeacher;
  final List<StaffModuleModel> modules;

  factory StaffCapabilitiesModel.fromJson(Map<String, dynamic> json) {
    final modulesRaw = json['modules'];
    return StaffCapabilitiesModel(
      role: (json['role'] ?? '').toString(),
      isAdmin: json['is_admin'] == true,
      canAccessSiteAdmin: json['can_access_site_admin'] == true,
      canAccessAdmissionAdmin: json['can_access_admission_admin'] == true,
      canAccessDepartmentCabinet: json['can_access_department_cabinet'] == true,
      isTeacher: json['is_teacher'] == true,
      modules: modulesRaw is List
          ? modulesRaw
              .whereType<Map>()
              .map((e) => StaffModuleModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'is_admin': isAdmin,
        'can_access_site_admin': canAccessSiteAdmin,
        'can_access_admission_admin': canAccessAdmissionAdmin,
        'can_access_department_cabinet': canAccessDepartmentCabinet,
        'is_teacher': isTeacher,
        'modules': modules.map((m) => m.toJson()).toList(),
      };

  String get cabinetTitle {
    if (canAccessDepartmentCabinet) return 'Кабинет отделения';
    if (isTeacher) return 'Кабинет преподавателя';
    if (canAccessSiteAdmin && isAdmin) return 'Администрирование';
    if (canAccessSiteAdmin) return 'Админка сайта';
    return 'Сотрудник';
  }

  /// Модули для главного экрана (без profile — он на отдельной вкладке).
  List<StaffModuleModel> get homeModules =>
      modules.where((m) => m.id != 'profile').toList();
}
