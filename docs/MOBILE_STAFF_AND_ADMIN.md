# Мобильное приложение: персонал, преподаватели и админка сайта

Полное руководство для мобильной команды: **вход сотрудников**, **кабинет преподавателя**, **админ-панель** (как на сайте) и **приёмная кампания**.

Связанный документ (только приёмная кампания): [MOBILE_STAFF_PERSONNEL.md](./MOBILE_STAFF_PERSONNEL.md).

---

## 1. Главная идея

На **сайте** сотрудники входят через `/login/teacher` и получают JWT. Те же токены работают в **мобильном приложении**.

| Кто | На сайте | В мобилке |
|-----|----------|-----------|
| Преподаватель | `/teacher`, журнал, материалы | Кабинет преподавателя |
| Зав. отделением / методист | `/cabinet/department` | Кабинет отделения |
| Ивент-менеджер | Админка (часть разделов) | «Админка сайта» (ограниченное меню) |
| Администратор | Полная админка `/staff/.../admin` | «Админка сайта» + приёмная кампания |

**Не дублируйте API под `/api/mobile/...`**, если эндпоинт уже есть на сайте: вызывайте те же URL с `Authorization: Bearer <token>`.

---

## 2. Базовый URL и авторизация

```text
Production: https://college.dgu.ru
```

После входа персонала **все** запросы:

```http
Authorization: Bearer <token>
Content-Type: application/json
```

### Рекомендуемый вход (мобилка)

```http
POST /api/v1/auth/staff
```

```json
{ "email": "ivanov@college.dgu.ru", "password": "secret" }
```

Ответ:

```json
{
  "token": "eyJ...",
  "user": {
    "id": 12,
    "fio": "Иванов И.И.",
    "email": "ivanov@college.dgu.ru",
    "role": "teacher",
    "is_admin": false,
    "can_access_site_admin": false,
    "can_access_admission_admin": false,
    "can_access_department_cabinet": false,
    "is_teacher": true,
    "position": "Кафедра ИТ",
    "avatar_url": "/uploads/avatars/avatar_xxx.jpg"
  }
}
```

| Флаг | Значение |
|------|----------|
| `is_admin` | Суперадмин (`role === "admin"`) — полная админка + проходной балл |
| `can_access_site_admin` | Пункт меню «Админка сайта» (`admin`, `event_manager`, `methodist`) |
| `can_access_admission_admin` | Приёмная кампания — список абитуриентов |
| `can_access_department_cabinet` | Кабинет отделения |
| `is_teacher` | Преподаватель |

> Старый веб-вход `POST /api/auth/staff/login` отдаёт токен в **заголовках** (`X-Auth-Token`). Для нового кода мобилки используйте только `/api/v1/auth/staff`.

---

## 3. Меню приложения: `GET /api/v1/staff/capabilities`

После логина запросите список модулей — **не хардкодьте** меню по роли:

```http
GET /api/v1/staff/capabilities
Authorization: Bearer <token>
```

Пример ответа (admin):

```json
{
  "role": "admin",
  "is_admin": true,
  "can_access_site_admin": true,
  "can_access_admission_admin": true,
  "can_access_department_cabinet": false,
  "is_teacher": false,
  "modules": [
    {
      "id": "profile",
      "label": "Профиль и аватар",
      "roles": ["teacher", "department", "..."],
      "api_prefix": "/api/v1/user",
      "mobile_ready": "full",
      "note": null
    },
    {
      "id": "news",
      "label": "Новости сайта",
      "roles": ["admin", "event_manager", "methodist", "teacher"],
      "api_prefix": "/api/news",
      "mobile_ready": "partial",
      "note": "Создание/редактирование; для HTML — редактор или упрощённые поля."
    }
  ]
}
```

### `mobile_ready`

| Значение | Действие в приложении |
|----------|------------------------|
| `full` | Делайте нативные экраны |
| `partial` | Нативный список/формы; сложный HTML — WebView или десктоп |
| `web_only` | Открывать встроенный браузер на админку сайта |

---

## 4. Навигация в приложении (рекомендуемая)

```text
Вход «Для сотрудников»
    │
    ├─ role: teacher ──────────► Кабинет преподавателя
    │                              ├─ Профиль / аватар
    │                              ├─ Журнал (оценки)
    │                              ├─ Материалы
    │                              ├─ Мероприятия (если есть в modules)
    │                              └─ 1С: расписание / профиль
    │
    ├─ role: department* ─────► Кабинет отделения
    │                              ├─ Группы, документы, объявления
    │                              ├─ Итоговые работы
    │                              └─ Стипендиальный рейтинг (отделение)
    │
    ├─ can_access_admission_admin ► Приёмная кампания (см. MOBILE_STAFF_PERSONNEL.md)
    │
    └─ can_access_site_admin ───► Админка сайта
                                   └─ подпункты из modules (news, events, …)
```

---

## 5. Профиль и аватар

| Метод | Путь |
|-------|------|
| GET | `/api/v1/user/profile` |
| POST | `/api/v1/user/avatar` — `multipart/form-data`, поле **`avatar`** |

Подробности: [MOBILE_STAFF_PERSONNEL.md](./MOBILE_STAFF_PERSONNEL.md) §4.

URL картинки: `https://college.dgu.ru` + `avatar_url`.

---

## 6. Преподаватель (`teacher`)

### 6.1. Журнал / оценки

| Действие | API |
|----------|-----|
| Мои предметы | `GET /api/journal/subjects/my` |
| Создать предмет | `POST /api/journal/subjects` |
| Оценки по предмету | `GET /api/journal/grades/subject/{subject_id}` |
| Выставить оценку | `POST /api/journal/grades` |
| Удалить предмет | `DELETE /api/journal/subjects/{subject_id}` |

### 6.2. Материалы

| Действие | API |
|----------|-----|
| Список / загрузка | `GET/POST /api/materials/...` (как на сайте у преподавателя) |

### 6.3. Данные 1С

| Действие | API |
|----------|-----|
| Профиль сотрудника | `GET /api/1c/my-profile` |
| Расписание | `GET /api/1c/schedule?...` |

### 6.4. Мероприятия (если роль в `modules`)

См. раздел 7.2 — те же эндпоинты `/api/mobile/events`.

---

## 7. Админка сайта

Доступ: `can_access_site_admin === true`.

### 7.1. Соответствие пунктам меню сайта

| № | Раздел на сайте | `module.id` | API (основной префикс) | Роли |
|---|-----------------|-------------|-------------------------|------|
| 1 | Дашборд | `dashboard` | `GET /api/admin/dashboard-stats` | admin |
| 2 | Пользователи | `users` | `GET/POST/PUT /api/users` | admin |
| 3 | Новости | `news` | `GET /api/news/admin/list`, `POST/PUT /api/news`, `POST /api/news/upload-image` | admin, event_manager, methodist, teacher* |
| 4 | Группы | `groups` | `/api/groups` | admin |
| 5 | Модерация | `moderation` | `GET /api/portfolio/admin/pending`, `PATCH /api/portfolio/admin/{id}` | admin, event_manager, methodist |
| 6 | Рассылка оценок | `weekly_grades` | `/api/admin/weekly-grades-digest` | admin |
| 7–8 | УПК | `upk` | `/api/upk/admin/services`, `/api/upk/admin/cases` | admin, event_manager, methodist |
| 9 | Отделения 1С | `department_catalog` | `GET /api/admin/department-catalog`, `POST .../sync` | admin |
| 10 | Сведения об ОО | `edu_disclosure` | `/api/edu-disclosure/admin/...` | admin, event_manager, methodist |
| 11 | Студентам (сайт) | `student_portal` | `/api/student-portal/admin/...` | admin, event_manager, methodist |
| 12 | Воспитание | `upbringing` | `GET /api/upbringing/admin/snapshot`, `POST/PUT /api/upbringing/admin/entries` | admin, event_manager, methodist |
| 13 | Стипенд. рейтинг | `scholarship_rating` | `/api/scholarship-rating/admin/...` | admin, event_manager, methodist |
| 14 | Настройки | `settings` | `GET/PATCH /api/admin/settings` | admin |
| 15 | Мобильное приложение | `mobile_app` | `GET/PUT /api/mobile-app-release/admin` | admin |

\* Учитель может создавать новости/мероприятия, но не удалять новости (как на бэкенде).

### 7.2. Мероприятия (готово для мобилки)

| Действие | API |
|----------|-----|
| Список (все, с черновиками) | `GET /api/mobile/events/admin/list` |
| Создать | `POST /api/mobile/events` |
| Изменить | `PUT /api/mobile/events/{id}` |
| Удалить | `DELETE /api/mobile/events/{id}` (не teacher) |
| Обложка | `POST /api/mobile/events/upload-image` |

Тело создания — см. схему `CollegeEventCreate` в OpenAPI (`/docs`).

### 7.3. Новости

| Действие | API |
|----------|-----|
| Список для админки | `GET /api/news/admin/list` |
| Одна новость | `GET /api/news/{id}` |
| Создать | `POST /api/news` |
| Изменить | `PUT /api/news/{id}` |
| Удалить | `DELETE /api/news/{id}` |
| Картинка в тексте / обложка | `POST /api/news/upload-image` |

Поле `content` — HTML (Quill на сайте). **Создание и редактирование в мобилке** — переход на сайт через web handoff: [`MOBILE_WEB_HANDOFF.md`](./MOBILE_WEB_HANDOFF.md) (`POST /api/v1/auth/web-handoff`).

### 7.4. Пользователи (только admin)

| Действие | API |
|----------|-----|
| Список | `GET /api/users` |
| Создать | `POST /api/users` |
| Изменить | `PUT /api/users/{id}` |

Флаги: `is_test_user`, роли, `student_book_number` и т.д. — как в админке сайта.

### 7.5. Настройки и мобильное приложение

| Действие | API |
|----------|-----|
| Настройки сайта | `GET/PATCH /api/admin/settings` |
| Версии приложения | `GET/PUT /api/mobile-app-release/admin` |

Документация по версиям: `docs/MOBILE_RELEASE_ADMIN.md`, `docs/MOBILE_HEALTH_CLIENT.md`.

### 7.6. Сведения об ОО и «Студентам»

Большие формы с Quill и PDF на сайте. **`mobile_ready: web_only`**.

Варианты:

1. Пункт меню открывает `https://college.dgu.ru/staff/college/college-admin/admin/...` во встроенном WebView с cookie/токеном (если реализуете SSO).
2. Оставить редактирование только с десктопа; в мобилке — просмотр статистики дашборда.

API те же, что дергает веб-админка: `/api/edu-disclosure/admin/*`, `/api/student-portal/admin/*`.

---

## 8. Кабинет отделения (`department`, `department_methodist`)

Префикс: `/api/cabinet/department`

| Действие | API |
|----------|-----|
| Кто я / отделение | `GET /api/cabinet/department/me` |
| Обзор групп | `GET /api/cabinet/department/groups-overview` |
| Документы — список | `GET /api/cabinet/department/documents` |
| Загрузить PDF | `POST /api/cabinet/department/documents` (multipart) |
| Скачать | `GET /api/cabinet/department/documents/{id}/file` |
| Объявления | `GET/POST/DELETE /api/cabinet/department/announcements` |
| Итоговые работы (пикеры) | `GET .../final-works/picker-groups`, `picker-students`, `picker-subjects` |

Стипендиальный рейтинг отделения: `/api/scholarship-rating/...` (как на `/cabinet/department/scholarship-rating`).

---

## 9. Приёмная кампания

Отдельный модуль `admission_campaign` — **полностью готов для мобилки**.

См. [MOBILE_STAFF_PERSONNEL.md](./MOBILE_STAFF_PERSONNEL.md):

- `GET /api/v1/admin/applicants?search=`
- `GET /api/v1/admin/applicants/{id}`
- `GET /api/v1/admin/payment-cutoff`
- `POST /api/v1/admin/set-payment-cutoff` (только `is_admin`)

---

## 10. Push и FCM

Регистрация устройства (для любого пользователя с JWT):

```http
POST /api/push/device
{ "token": "<fcm>", "platform": "android" | "ios" }
```

Настройки уведомлений студента: `/api/mobile/notification-preferences`.

Приёмная кампания шлёт push абитуриентам с привязанным `user_id` при установке проходного балла.

---

## 11. Роли — сводная таблица

| role | Сайт после входа | Флаги в API |
|------|------------------|-------------|
| `teacher` | `/teacher` | `is_teacher` |
| `department` | `/cabinet/department` | `can_access_department_cabinet` |
| `department_methodist` | `/cabinet/department` | `can_access_department_cabinet` |
| `event_manager` / `methodist` | Админка (5 разделов) | `can_access_site_admin`, `can_access_admission_admin` |
| `admin` | Полная админка | все флаги + `is_admin` |

---

## 12. План внедрения в мобилке (по этапам)

### Этап 1 — уже на бэкенде (`full`)

- [ ] Вход `POST /api/v1/auth/staff`
- [ ] `GET /api/v1/staff/capabilities` → меню
- [ ] Профиль + аватар
- [ ] Приёмная кампания
- [ ] Мероприятия `/api/mobile/events`
- [ ] Версии приложения `/api/mobile-app-release/admin`

### Этап 2 — `partial` (те же API, нативный UI)

- [ ] Новости
- [ ] Пользователи
- [ ] Дашборд
- [ ] Журнал преподавателя
- [ ] Кабинет отделения
- [ ] УПК, воспитание, модерация портфолио

### Этап 3 — `web_only`

- [ ] Сведения об ОО
- [ ] Раздел «Студентам» (контент сайта)

---

## 13. Ошибки и коды

| HTTP | Смысл |
|------|--------|
| 401 | Нет токена или сессия истекла → экран входа |
| 403 | Недостаточно прав для раздела |
| 503 | 1С недоступна (вход преподавателя через 1С) |

---

## 14. OpenAPI

Интерактивная схема после деплоя:

```text
https://college.dgu.ru/docs
```

Теги: `mobile-v1`, `mobile`, `news`, `journal`, `cabinet-department`, `edu-disclosure`, …

---

## 15. Деплой бэкенда

```bash
cd /var/www/college_site && git pull
docker compose build --pull=false backend
docker compose up -d backend
```

---

## 16. Чеклист для QA

1. Преподаватель: вход → нет админки, есть журнал/профиль.
2. Ивент-менеджер: вход → админка без пользователей/настроек; есть новости и абитуриенты.
3. Админ: полное меню из `capabilities`; проходной балл работает.
4. Зав. отделением: кабинет отделения, документы и объявления.
5. Один JWT работает и для `/api/v1/*`, и для `/api/news`, `/api/journal`, и т.д.

Вопросы по API — бэкенд-разработчик сайта колледжа.
