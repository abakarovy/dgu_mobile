# Реестр документации dgu_mobile

Нумерованные документы — по порядку внедрения. Следующий свободный номер: **7**.

| № | Файл | Описание |
|---|------|----------|
| — | [MOBILE_STAFF_AND_ADMIN.md](./MOBILE_STAFF_AND_ADMIN.md) | Персонал, админка сайта, capabilities, API |
| — | [MOBILE_STAFF_PERSONNEL.md](./MOBILE_STAFF_PERSONNEL.md) | Приёмная кампания |
| — | [MOBILE_WEB_HANDOFF.md](./MOBILE_WEB_HANDOFF.md) | Web-handoff для редактирования на сайте |
| **5** | [5_MOBILE_TEACHER_TZ.md](./5_MOBILE_TEACHER_TZ.md) | **ТЗ:** кабинет преподавателя, что не тащить из админки |
| **6** | [6_MOBILE_TEACHER_SETUP.md](./6_MOBILE_TEACHER_SETUP.md) | **Flutter:** роуты, whitelist, переиспользование админ-виджетов |

## Связанные (без номера)

| Файл | Описание |
|------|----------|
| [MOBILE_HEALTH_CLIENT.md](./MOBILE_HEALTH_CLIENT.md) | Health, обновления приложения |
| [MOBILE_HEALTH_APP_UPDATE.md](./MOBILE_HEALTH_APP_UPDATE.md) | Контракт `/api/health` |
| [README.md](./README.md) | App Store, Rustore, прочее |

## Код: ключевые точки кабинета преподавателя

| Область | Файл |
|---------|------|
| Whitelist + redirect после входа | `lib/core/staff/teacher_tool_whitelist.dart` |
| Оболочка 4 вкладки | `lib/features/teacher/presentation/pages/teacher_shell_page.dart` |
| Guard `/staff/*` → teacher | `lib/app/router/app_router.dart` |
| Bootstrap | `lib/app/bootstrap/bootstrap_page.dart` |
| Админ whitelist (6 пунктов) | `kAdminToolModuleIds` в `teacher_tool_whitelist.dart` |
