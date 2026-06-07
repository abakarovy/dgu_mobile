import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../data/models/staff_capabilities_model.dart';

/// Маршруты и иконки модулей staff (см. MOBILE_STAFF_AND_ADMIN.md).
abstract final class StaffModuleNavigation {
  static const cacheKey = 'staff:capabilities';

  static IconData iconFor(String moduleId) {
    switch (moduleId) {
      case 'profile':
        return Icons.person_outline;
      case 'admission_campaign':
        return Icons.school_outlined;
      case 'events':
        return Icons.event_outlined;
      case 'news':
        return Icons.newspaper_outlined;
      case 'mobile_app':
        return Icons.phone_android_outlined;
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'users':
        return Icons.group_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'moderation':
        return Icons.fact_check_outlined;
      case 'weekly_grades':
        return Icons.mail_outline;
      case 'upk':
        return Icons.menu_book_outlined;
      case 'department_catalog':
        return Icons.apartment_outlined;
      case 'edu_disclosure':
        return Icons.info_outline;
      case 'student_portal':
        return Icons.public_outlined;
      case 'upbringing':
        return Icons.volunteer_activism_outlined;
      case 'scholarship_rating':
        return Icons.emoji_events_outlined;
      case 'settings':
        return Icons.settings_outlined;
      case 'journal':
        return Icons.grade_outlined;
      case 'materials':
        return Icons.folder_outlined;
      case 'department_cabinet':
        return Icons.business_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }

  /// In-app route для нативного экрана; `null` — открыть сайт или заглушку.
  static String? nativeRouteFor(StaffModuleModel module) {
    switch (module.id) {
      case 'profile':
        return '/staff/profile';
      case 'admission_campaign':
        return '/staff/admission';
      case 'events':
        return '/staff/events';
      case 'mobile_app':
        return '/staff/mobile-release';
      case 'journal':
        return '/staff/journal';
      case 'department_cabinet':
      case 'cabinet_department':
      case 'department':
        return '/department/home';
      case 'dashboard':
        return '/staff/home';
      case 'news':
        return '/staff/news';
      case 'users':
        return '/staff/users';
      case 'groups':
        return '/staff/groups';
      case 'moderation':
        return '/staff/moderation';
      case 'weekly_grades':
        return '/staff/weekly-grades';
      case 'scholarship_rating':
        return '/staff/scholarship-rating';
      case 'settings':
        return '/staff/settings-admin';
      case 'edu_disclosure':
        return '/staff/edu-disclosure';
      default:
        if (module.isWebOnly) return '/staff/web/${module.id}';
        return '/staff/web/${module.id}';
    }
  }

  static String? webAdminUrl(String moduleId) {
    final origin = ApiConstants.collegeSiteOrigin;
    final path = switch (moduleId) {
      'edu_disclosure' => '/staff/college/college-admin/admin/edu-disclosure',
      'student_portal' => '/staff/college/college-admin/admin/student-portal',
      'upk' => '/staff/college/college-admin/admin/upk',
      'upbringing' => '/staff/college/college-admin/admin/upbringing',
      'scholarship_rating' =>
        '/staff/college/college-admin/admin/scholarship-rating',
      'settings' => '/staff/college/college-admin/admin/settings',
      'moderation' => '/staff/college/college-admin/admin/moderation',
      'weekly_grades' => '/staff/college/college-admin/admin/weekly-grades',
      'department_catalog' =>
        '/staff/college/college-admin/admin/department-catalog',
      'groups' => '/staff/college/college-admin/admin/groups',
      'dashboard' => '/staff/college/college-admin/admin',
      'users' => '/staff/college/college-admin/admin/users',
      'news' => '/staff/college/college-admin/admin/news',
      'events' => '/staff/college/college-admin/admin/events',
      _ => '/staff/college/college-admin/admin',
    };
    return '$origin$path';
  }

  /// Запасной URL (без автологина), если handoff недоступен.
  static String webEditFallbackUrl({required bool isNews, int? resourceId}) {
    final origin = ApiConstants.collegeSiteOrigin;
    final section = isNews ? 'news' : 'events';
    if (resourceId != null) {
      return '$origin/staff/college/college-admin/admin/$section?edit=$resourceId';
    }
    return '$origin/staff/college/college-admin/admin/$section';
  }
}
