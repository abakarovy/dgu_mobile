# 6. Настройка кабинета преподавателя в dgu_mobile

Практическая инструкция для Flutter-разработчика: **куда вставить код**, **какие константы**, **как не сломать админку**.

ТЗ по функциям: [5_MOBILE_TEACHER_TZ.md](./5_MOBILE_TEACHER_TZ.md).  
Реестр документов: [MOBILE_DOCS_INDEX.md](./MOBILE_DOCS_INDEX.md).

---

## 1. Файлы и точки входа (ориентир)

Имена из вашего текущего проекта — подставьте свои, если отличаются:

| Область | Файлы (пример) |
|---------|----------------|
| Вход | `login/staff`, флаг «для сотрудников» |
| Роутинг после логина | `staff_module_navigation.dart`, `auth_repository.dart` |
| Админ-оболочка | `StaffShellPage`, `StaffToolsPage`, whitelist 6 разделов |
| Web-редактор | `staff_web_edit_dialog.dart`, `StaffNewsAdminPage` |
| Профиль | `StaffProfilePage`, `StaffSettingsPage` |
| Журнал (заготовка) | `StaffTeacherJournalPage`, маршрут `/staff/journal` |

**Новое для преподавателя:**

| Файл | Назначение |
|------|------------|
| `teacher_shell_page.dart` | Нижняя навигация 4 вкладки |
| `teacher_home_page.dart` | Главная + расписание |
| `teacher_journal_page.dart` | Журнал (можно вынести из `StaffTeacherJournalPage`) |
| `teacher_materials_page.dart` | Материалы |
| `teacher_content_page.dart` | Обёртка над `StaffNewsAdminPage` |
| `teacher_profile_page.dart` | Профиль без админ-быстрых ссылок |
| `teacher_tool_whitelist.dart` | Константы id модулей |
| `teacher_route_guard.dart` | Запрет `/staff/*` для teacher |

---

## 2. Константы whitelist

### 2.1. Админ (уже есть — не трогать)

```dart
/// StaffToolsPage — только эти 6 id
const kAdminToolModuleIds = {
  'news',
  'groups',
  'moderation',
  'weekly_grades',
  'scholarship_rating',
  'mobile_app',
};
```

### 2.2. Преподаватель (новое)

```dart
/// Модули, которые преподаватель видит в своём кабинете
const kTeacherModuleIds = {
  'journal',
  'materials',
  'news',
  'events',
  'ones',
  'profile',
  // 'notifications', // фаза 2
};

/// id для фильтрации GET /api/v1/staff/capabilities → modules
bool isTeacherModule(String id) => kTeacherModuleIds.contains(id);

/// Плитки на вкладке «Контент» (объединяем news + events в один экран)
const kTeacherContentModuleIds = {'news', 'events'};
```

### 2.3. Фильтр capabilities

```dart
List<StaffModule> teacherModulesFromCapabilities(StaffCapabilities cap) {
  return cap.modules.where((m) => kTeacherModuleIds.contains(m.id)).toList();
}
```

**Не используйте** для teacher:

```dart
// ПЛОХО — покажет dashboard, users, settings из API
cap.modules;
```

---

## 3. Роутинг (go_router / auto_route)

### 3.1. Дерево маршрутов

```text
/login/staff
/teacher                          → TeacherShellPage
    /teacher/home                 → TeacherHomePage
    /teacher/journal              → TeacherJournalPage
    /teacher/journal/subject/:id  → TeacherSubjectGradesPage (опционально)
    /teacher/materials            → TeacherMaterialsPage
    /teacher/content              → TeacherContentPage (StaffNewsAdminPage)
    /teacher/profile              → TeacherProfilePage
    /teacher/profile/settings     → StaffSettingsPage (logout)

/staff                            → StaffShellPage (admin / event_manager)
    ... без изменений ...
```

### 3.2. Redirect после логина

```dart
String staffHomeRoute(StaffUser user) {
  if (user.isTeacher &&
      !user.canAccessSiteAdmin &&
      !user.canAccessDepartmentCabinet) {
    return '/teacher/home';
  }
  if (user.canAccessDepartmentCabinet) {
    return '/staff/department';
  }
  if (user.canAccessSiteAdmin || user.isAdmin) {
    return '/staff/home';
  }
  return '/staff/profile';
}
```

### 3.3. Guard: teacher не заходит в админку

```dart
redirect: (context, state) {
  final user = authState.user;
  if (user == null) return '/login/staff';
  if (user.isTeacher && !user.canAccessSiteAdmin) {
    if (state.matchedLocation.startsWith('/staff/')) {
      return '/teacher/home';
    }
  }
  return null;
},
```

Исключение: deep link `https://college.dgu.ru/auth/mobile-handoff?code=...` обрабатывается **в браузере**, не внутри `/staff` shell.

---

## 4. `TeacherShellPage` — шаблон

Повторяет паттерн `StaffShellPage`, другие вкладки:

```dart
final _tabs = [
  TeacherTab.home,      // /teacher/home
  TeacherTab.journal,   // /teacher/journal
  TeacherTab.content,   // /teacher/content
  TeacherTab.profile,   // /teacher/profile
];
```

- `AppHeader` — тот же.
- Нижняя панель скрывается на вложенных маршрутах (`/teacher/journal/subject/5`).
- **Нет** вкладок `users`, `tools` (админских).

---

## 5. Переиспользование админ-компонентов

| Компонент | Преподаватель | Изменение |
|-----------|---------------|-----------|
| `StaffProfilePage` | ✓ | Убрать секцию «Мои инструменты» (6 админ-плиток); заменить на teacher-ссылки |
| `StaffNewsAdminPage` | ✓ | `canDelete: user.role != 'teacher'` |
| `StaffWebEditDialog` | ✓ | Без изменений |
| `StaffAdminUi` | ✓ | Без изменений |
| `StaffHomePage` | ✗ | Только admin |
| `StaffUsersTabPage` | ✗ | Только admin |
| `StaffToolsPage` | ✗ | Только admin |
| `StaffStudentSearchPicker` | △ | Только если делаете рассылку оценок teacher (не в MVP) |

### 5.1. `TeacherContentPage`

```dart
class TeacherContentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StaffNewsAdminPage(
      showDeleteActions: false, // или canManageSiteContent(role)
      initialTab: StaffNewsTab.news,
    );
  }
}
```

Handoff при «Создать» / «Ред.»:

```dart
await StaffWebEditDialog.show(
  context,
  target: StaffWebEditTarget.newsEdit,
  resourceId: newsId,
);
// внутри: POST /api/v1/auth/web-handoff → launchUrl
```

См. [MOBILE_WEB_HANDOFF.md](./MOBILE_WEB_HANDOFF.md).

---

## 6. API-слой

Рекомендуется отдельный файл `teacher_api.dart` (или расширить `staff_modules_api.dart`):

| Метод | HTTP |
|-------|------|
| `getMySubjects()` | `GET /api/journal/subjects/my` |
| `createSubject(...)` | `POST /api/journal/subjects` |
| `getSubjectGrades(id)` | `GET /api/journal/grades/subject/{id}` |
| `postGrade(...)` | `POST /api/journal/grades` |
| `getGroupMaterials(gid)` | `GET /api/materials/group/{gid}` |
| `createMaterial(...)` | `POST /api/materials` |
| `uploadMaterialFile(...)` | `POST /api/materials/{id}/upload` |
| `getSchedule(week)` | `GET /api/1c/schedule?week=...` |
| `getStaffProfile()` | `GET /api/v1/user/profile` |
| `uploadAvatar(bytes)` | `POST /api/v1/user/avatar` |

Заголовок для всех:

```dart
headers: {'Authorization': 'Bearer $token'}
```

Базовый URL: `https://college.dgu.ru` (или из env).

---

## 7. Модель пользователя после логина

Расширьте `StaffUser` (если ещё нет полей с бэкенда):

```dart
class StaffUser {
  final bool isAdmin;
  final bool canAccessSiteAdmin;
  final bool canAccessAdmissionAdmin;
  final bool canAccessDepartmentCabinet;
  final bool isTeacher;
  final String role;

  bool get useTeacherShell =>
      isTeacher && !canAccessSiteAdmin && !canAccessDepartmentCabinet;

  bool get useAdminShell =>
      canAccessSiteAdmin || isAdmin;
}
```

Парсинг из `POST /api/v1/auth/staff` — поля `user.is_teacher`, `user.can_access_site_admin` и т.д.

---

## 8. Профиль и аватар (по ТЗ «Персонал»)

1. Тап по аватару → `image_picker` / `image_cropper` (кроп **1:1**).
2. `POST /api/v1/user/avatar`, поле формы **`avatar`**.
3. Ответ `{ "avatar_url": "/uploads/avatars/..." }` → полный URL с хостом колледжа.
4. Обновить state профиля и `StaffProfilePage`.

Ограничения бэкенда: jpg/png, до 5 МБ, ресайз 500×500.

---

## 9. Чеклист «не сломать админку»

- [ ] `kAdminToolModuleIds` по-прежнему **6** элементов.
- [ ] `StaffToolsPage` фильтрует `modules` только по `kAdminToolModuleIds`.
- [ ] Teacher после логина **не** попадает на `/staff/home`.
- [ ] Admin после логина **не** попадает на `/teacher/home`.
- [ ] Маршрут `/staff/journal` перенесён или продублирован в `/teacher/journal` (старый — redirect для teacher).
- [ ] В `StaffProfilePage` блок «Мои инструменты» показывается только если `canAccessSiteAdmin`.
- [ ] Handoff URL открывается в **внешнем** браузере (`LaunchMode.externalApplication`).

---

## 10. Сопоставление с уже сделанной админкой

| У вас в админке | Для преподавателя |
|-----------------|-------------------|
| 4 вкладки: Дашборд, Пользователи, Инструменты, Профиль | 4 вкладки: **Главная, Журнал, Контент, Профиль** |
| Whitelist 6 в «Инструментах» | Whitelist **свой**; контент = news+events в одной вкладке |
| `/staff/news` | `/teacher/content` (тот же виджет) |
| `/staff/journal` | `/teacher/journal` (основной вход) |
| Приёмная кампания `/staff/admission` | **Нет** у teacher |
| Дашборд KPI | **Нет** у teacher; вместо него расписание 1С |

---

## 11. Порядок работ (рекомендуемый)

1. Добавить `teacher_tool_whitelist.dart` + `staffHomeRoute()`.
2. Сделать `TeacherShellPage` + пустые 4 экрана.
3. Подключить redirect и guard.
4. Перенести/скопировать журнал → `TeacherJournalPage`.
5. Встроить `StaffNewsAdminPage` в `TeacherContentPage` с `showDeleteActions: false`.
6. Профиль + аватар.
7. `TeacherHomePage` + API расписания.
8. `TeacherMaterialsPage`.
9. Прогон QA из [5_MOBILE_TEACHER_TZ.md](./5_MOBILE_TEACHER_TZ.md) §8.

---

## 12. Env и сборка

```env
API_BASE_URL=https://college.dgu.ru
# для handoff url в ответе бэкенда на проде нужен PUBLIC_SITE_URL на сервере
```

Проверка на staging: вход teacher `POST /api/v1/auth/staff` → `is_teacher: true` → `/teacher/home`.
