# 5. ТЗ: кабинет преподавателя в мобильном приложении

Техническое задание на доработку `dgu_mobile`: **отдельный кабинет преподавателя** (`role === "teacher"`), без смешивания с **админской оболочкой** (`StaffShellPage`).

Основа: [Сделай только для _Персонала_ ТЗ (2)](file:///c:/Users/Ягияев%20Али/Downloads/Сделай%20только%20для%20_Пероснала_%20ТЗ%20(2).md) + фактический API сайта + уже реализованная **админка в мобилке** (whitelist 6 разделов).

Реестр: [MOBILE_DOCS_INDEX.md](./MOBILE_DOCS_INDEX.md).  
Настройка роутинга и whitelist в коде: [6_MOBILE_TEACHER_SETUP.md](./6_MOBILE_TEACHER_SETUP.md).  
Общий API персонала: [MOBILE_STAFF_AND_ADMIN.md](./MOBILE_STAFF_AND_ADMIN.md) §6.

---

## 1. Цель и принцип разделения

### 1.1. Проблема

В мобилке уже есть **кабинет администратора / ивент-менеджера**:

- 4 вкладки: Дашборд, Пользователи, Инструменты (whitelist **6** разделов), Профиль.
- Жёсткий whitelist — лишние модули из `capabilities` **не показываются**.

Преподаватель на сайте — **другой кабинет** (журнал, материалы, контент), не админ-панель. Если открыть преподавателю `StaffShellPage`, он увидит чужие разделы или пустые вкладки.

### 1.2. Правило (обязательно)

| Роль | Оболочка | Whitelist «Инструментов» |
|------|----------|---------------------------|
| `admin` | `StaffShellPage` | 6 админ-разделов (как сейчас) |
| `event_manager` / `methodist` | `StaffShellPage` | те же 6 + приёмная кампания отдельным маршрутом |
| **`teacher`** | **`TeacherShellPage`** (новая) | **свой whitelist (4–5 пунктов)** |
| `department` / `department_methodist` | `DepartmentShellPage` | кабинет отделения (отдельное ТЗ) |

**Запрещено:**

- Показывать преподавателю вкладки **Дашборд / Пользователи** и админский whitelist.
- Добавлять в админский whitelist **Журнал, Материалы, Рассылку email** только потому, что они есть у преподавателя.
- Сливать «всё из `modules`» в одну вкладку «Инструменты» без фильтра по роли.

**Разрешено:**

- Переиспользовать **общие виджеты**: профиль, аватар, `StaffNewsAdminPage`, `StaffWebEditDialog`, `StaffAdminUi`.
- Один вход `/login/staff` и один JWT; разветвление **после** `POST /api/v1/auth/staff` по флагам.

---

## 2. Ролевая модель и маршрутизация после входа

### 2.1. Вход (без изменений)

```http
POST /api/v1/auth/staff
{ "email": "...", "password": "..." }
```

Ответ — см. [MOBILE_STAFF_PERSONNEL.md](./MOBILE_STAFF_PERSONNEL.md). Для преподавателя типично:

```json
{
  "user": {
    "role": "teacher",
    "is_admin": false,
    "can_access_site_admin": false,
    "can_access_admission_admin": false,
    "can_access_department_cabinet": false,
    "is_teacher": true
  }
}
```

### 2.2. Куда вести после логина

```dart
if (user.isTeacher && !user.canAccessSiteAdmin && !user.canAccessDepartmentCabinet) {
  context.go('/teacher/home');
} else if (user.canAccessDepartmentCabinet) {
  context.go('/staff/department');
} else if (user.canAccessSiteAdmin || user.isAdmin) {
  context.go('/staff/home');
} else {
  // fallback: профиль персонала
  context.go('/staff/profile');
}
```

`GET /api/v1/staff/capabilities` — **вспомогательный** список API; меню преподавателя строится по **локальному whitelist**, не по полному `modules`.

---

## 3. Оболочка преподавателя `TeacherShellPage`

### 3.1. Нижняя навигация (4 вкладки)

| № | Вкладка | Маршрут | Назначение |
|---|---------|---------|------------|
| 1 | **Главная** | `/teacher/home` | Расписание 1С, быстрые действия |
| 2 | **Журнал** | `/teacher/journal` | Предметы и оценки (локальный журнал сайта) |
| 3 | **Контент** | `/teacher/content` | Новости + мероприятия (как у админа, урезанные права) |
| 4 | **Профиль** | `/teacher/profile` | Аккаунт, аватар, выход |

На вложенных экранах — как в `StaffShellPage`: нижняя панель скрыта, кнопка «назад».

### 3.2. Whitelist «рабочих» модулей (внутри вкладок, не отдельная плитка «Инструменты»)

Преподавателю **нативно** доступны только:

| `module.id` из API | Экран | Приоритет |
|--------------------|-------|-----------|
| `journal` | `TeacherJournalPage` | MVP |
| `materials` | `TeacherMaterialsPage` | MVP |
| `news` + `events` | `TeacherContentPage` → переиспользовать `StaffNewsAdminPage` | MVP |
| `ones` | блок на `TeacherHomePage` (расписание) | MVP |
| `notifications` | `TeacherNotificationsPage` | Фаза 2 |
| `profile` | `TeacherProfilePage` → обёртка над `StaffProfilePage` | MVP |

**Не входят в кабинет преподавателя** (только у админа / ивент-менеджера):

`dashboard`, `users`, `groups`, `moderation`, `weekly_grades`, `scholarship_rating`, `mobile_app`, `admission_campaign`, `settings`, `edu_disclosure`, `student_portal`, `upbringing`, `upk`, `department_catalog` и т.д.

Для них при необходимости — только `StaffWebModulePage` / «Открыть на сайте» **не показывать** преподавателю по умолчанию.

---

## 4. Функциональные требования по экранам

### 4.1. Главная (`TeacherHomePage`)

**Цель:** аналог «дашборда» преподавателя на сайте (не путать с админским `StaffHomePage`).

| Блок | API | Поведение |
|------|-----|-----------|
| Приветствие | `GET /api/v1/user/profile` | ФИО, должность |
| Расписание на сегодня / неделю | `GET /api/1c/schedule?week=...` | Список пар; pull-to-refresh |
| Быстрые кнопки | — | «Журнал», «Новость», «Материал» → deep link во вкладки |
| Профиль 1С | `GET /api/1c/my-profile` | Опционально: отделение, должность из 1С |

**Не показывать:** KPI колледжа, регистрации студентов, версии приложения.

### 4.2. Журнал (`TeacherJournalPage`)

Расширить существующий `StaffTeacherJournalPage` / вынести под `/teacher/journal`.

| Действие | API | UI |
|----------|-----|-----|
| Список моих предметов | `GET /api/journal/subjects/my` | Карточки предметов |
| Создать предмет | `POST /api/journal/subjects` | Bottom sheet |
| Оценки по предмету | `GET /api/journal/grades/subject/{id}` | Таблица / список |
| Выставить оценку | `POST /api/journal/grades` | Диалог: студент, тип, балл, дата |
| Удалить предмет | `DELETE /api/journal/subjects/{id}` | Подтверждение |

**Не путать** с просмотром оценок **студента** (`GET /api/journal/grades/my`) — это экран студента, не преподавателя.

### 4.3. Материалы (`TeacherMaterialsPage`)

| Действие | API | UI |
|----------|-----|-----|
| Выбор группы | `GET /api/groups` или привязка к предметам | Picker группы |
| Список материалов группы | `GET /api/materials/group/{group_id}` | Список файлов |
| Создать материал | `POST /api/materials` | Название, описание, группа |
| Загрузить файл | `POST /api/materials/{id}/upload` | multipart |
| Удалить | `DELETE /api/materials/{id}` | Только свои / по правилам API |

### 4.4. Контент — новости и мероприятия (`TeacherContentPage`)

**Переиспользовать** `StaffNewsAdminPage` + `StaffWebEditDialog` + [MOBILE_WEB_HANDOFF.md](./MOBILE_WEB_HANDOFF.md).

| Действие | API | Ограничение для teacher |
|----------|-----|-------------------------|
| Список новостей | `GET /api/news/admin/list` | ✓ |
| Создать / редактировать | Web handoff | ✓ |
| Удалить новость | `DELETE /api/news/{id}` | **✗** (403 на бэкенде) |
| Список мероприятий | `GET /api/mobile/events/admin/list` | ✓ |
| Создать / редактировать | Web handoff | ✓ |
| Удалить мероприятие | `DELETE /api/mobile/events/{id}` | **✗** |

В UI скрыть кнопки «Удалить» для `role === teacher` (как `canEditContent` у админа).

### 4.5. Профиль (`TeacherProfilePage`)

По ТЗ «Персонал» (файл (2)):

| Функция | API |
|---------|-----|
| Просмотр профиля | `GET /api/v1/user/profile` |
| Аватар: камера / галерея / кроп 1:1 | `POST /api/v1/user/avatar` multipart `avatar` |
| Настройки | только **«Выйти»** |
| Карточка «Доступ» | чипы: `Преподаватель`, без «Админка сайта» |

**Не показывать** в профиле преподавателя блок «Мои инструменты» с 6 админ-плитками. Вместо него — **«Мои разделы»**: Журнал, Материалы, Контент.

### 4.6. Рассылка уведомлений (фаза 2, опционально)

| Действие | API |
|----------|-----|
| Отправить email студентам/родителям | `POST /api/notifications/send` |
| История | `GET /api/notifications/history` |

Отдельный пункт в «Контент» или подменю на главной — **не** в админских «Инструментах».

---

## 5. Соответствие сайту

| На сайте | В мобилке преподавателя | Статус |
|----------|-------------------------|--------|
| `/teacher` (демо-страница) | Не копировать хардкод; брать **реальные API** | — |
| Журнал (API) | `TeacherJournalPage` | MVP |
| Материалы | `TeacherMaterialsPage` | MVP |
| Новости / мероприятия (teacher может создавать) | `TeacherContentPage` + handoff | MVP |
| Расписание 1С | `TeacherHomePage` | MVP |
| Юрайт / демо-курсы | Не в MVP | Позже / WebView |
| Админ-панель `/staff/.../admin` | **Недоступна** | — |

---

## 6. Требования к бэкенду

Для MVP **доработка бэкенда не обязательна** — эндпоинты уже есть (см. `staff_capabilities.py`).

Рекомендации (по желанию, не блокер):

| Улучшение | Зачем |
|-----------|--------|
| `GET /api/v1/staff/capabilities` → поле `shell: "teacher" \| "admin" \| "department"` | Явная подсказка мобилке |
| Отдельный whitelist в ответе `teacher_tools: string[]` | Меньше дублирования констант в Flutter |

Текущие флаги достаточны: `is_teacher` + `!can_access_site_admin`.

---

## 7. План внедрения (этапы)

### Этап A — каркас (1–2 дня)

- [ ] `TeacherShellPage` + 4 вкладки
- [ ] Роутинг после `/login/staff` для `teacher`
- [ ] `TeacherProfilePage` (аватар по ТЗ (2))
- [ ] Константа `kTeacherToolIds` (см. doc 6)

### Этап B — учёба (3–5 дней)

- [ ] `TeacherJournalPage` (полный CRUD предметов/оценок)
- [ ] `TeacherMaterialsPage`
- [ ] `TeacherHomePage` + расписание 1С

### Этап C — контент (1–2 дня)

- [ ] `TeacherContentPage` = `StaffNewsAdminPage` без удаления
- [ ] Handoff уже подключён

### Этап D — опционально

- [ ] `TeacherNotificationsPage`
- [ ] Push / локальные напоминания о парах

---

## 8. План тестирования (QA)

1. Вход **teacher** → открывается `/teacher/home`, **нет** вкладок «Пользователи» / админского «Дашборда».
2. Вход **admin** → по-прежнему `/staff/home`, whitelist 6 разделов **без** журнала преподавателя в «Инструментах».
3. Преподаватель: журнал — создать предмет, выставить оценку.
4. Преподаватель: материалы — загрузка файла в группу.
5. Преподаватель: новость — handoff → сайт → форма → сохранение.
6. Преподаватель: кнопки «Удалить» новость/мероприятие **скрыты**; прямой `DELETE` → 403.
7. Аватар: кроп 1:1, `POST /api/v1/user/avatar`, обновление в профиле.
8. `capabilities` для teacher содержит `journal`, `materials`, `news` — но в UI **не** отображаются `dashboard`, `users`.

---

## 9. Критерии приёмки

- Преподаватель работает в **отдельной оболочке**, функционально близкой к сайту (журнал, материалы, контент, расписание).
- Админская мобилка **не изменилась** по составу whitelist (6 разделов).
- Нет «протечки» админ-экранов к teacher и teacher-only экранов к admin.
- Документ [6_MOBILE_TEACHER_SETUP.md](./6_MOBILE_TEACHER_SETUP.md) применён в репозитории `dgu_mobile`.
