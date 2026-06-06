# Web handoff: мобилка → сайт (новости и мероприятия)

Переход из `dgu_mobile` в системный браузер **без повторного ввода пароля** и с открытием нужной формы Quill.

---

## 1. Схема

```text
Мобилка (JWT)  →  POST /api/v1/auth/web-handoff  →  url с code
Браузер        →  GET /auth/mobile-handoff?code=…
Фронт          →  POST /api/v1/auth/web-handoff/exchange
                 →  localStorage сессия + redirect на админку
```

- **JWT в URL не передаётся** — только одноразовый `code` (TTL 90 с).
- Code привязан к `user_id`, `target`, `resource_id` и гасится после обмена.

---

## 2. Выдача ссылки (мобилка)

```http
POST /api/v1/auth/web-handoff
Authorization: Bearer <token>
Content-Type: application/json
```

### Тело

```json
{
  "target": "news_edit",
  "resource_id": 10
}
```

| `target` | `resource_id` | Куда откроется сайт |
|----------|---------------|---------------------|
| `news_create` | `null` | `/staff/.../admin/news?tab=news&mode=create` |
| `news_edit` | `10` | `...?tab=news&edit=10` |
| `event_create` | `null` | `...?tab=events&mode=create` |
| `event_edit` | `5` | `...?tab=events&edit=5` |

### Ответ `200`

```json
{
  "url": "https://college.dgu.ru/auth/mobile-handoff?code=a1b2c3d4..."
}
```

Откройте `url` через `url_launcher` (внешний браузер).

### Ошибки

| Код | Причина |
|-----|---------|
| 401 | Невалидный JWT |
| 403 | Нет прав (роль / чужая новость для teacher) |
| 404 | Новость или мероприятие не найдено |
| 429 | Больше 10 запросов в минуту на пользователя |

### Права

Те же, что на API:

- **Новости / мероприятия (создание и редактирование):** `admin`, `event_manager`, `methodist`, `teacher`
- **Редактирование чужой новости:** только `admin` (автор — `author_id` в БД)
- **Удаление** через handoff не предусмотрено (только список в мобилке)

---

## 3. Обмен code (браузер, автоматически)

Страница `GET /auth/mobile-handoff?code=…` вызывает:

```http
POST /api/v1/auth/web-handoff/exchange
Content-Type: application/json

{ "code": "a1b2c3d4..." }
```

### Ответ `200`

```json
{
  "access_token": "eyJ...",
  "user": {
    "id": 12,
    "email": "ivanov@college.dgu.ru",
    "full_name": "Иванов И.И.",
    "role": "admin",
    "is_active": true,
    "created_at": "..."
  },
  "redirect_path": "/staff/college/college-admin/admin/news?tab=news&edit=10"
}
```

Фронт сохраняет сессию в `localStorage` (`college_dgu_auth`) и делает `router.replace(redirect_path)`.

Админка по query-параметрам открывает модалку Quill:

- `mode=create` — создание
- `edit=<id>` — редактирование (подгружает запись по API, если её нет в текущей странице списка)

### Ошибки обмена

| Код | Действие фронта |
|-----|-----------------|
| 401 | Сообщение + редирект на `/login/teacher` через ~2.5 с |

Повторное использование или просроченный code → `401`.

---

## 4. Пример (Dart / Flutter)

Реализация в приложении: `StaffApi.createWebHandoffUrl`, `showStaffWebEditDialog`.

```dart
final url = await AppContainer.staffApi.createWebHandoffUrl(
  target: 'news_edit',
  resourceId: 10,
);
await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
```

Создание новости: `target: 'news_create'`, без `resource_id`.

---

## 5. Настройки сервера

| Переменная | Назначение |
|------------|------------|
| `PUBLIC_SITE_URL` | База для `url` в ответе handoff (прод: `https://college.dgu.ru`) |

Таблица БД: `web_handoff_codes` (создаётся при старте бэкенда).

---

## 6. OpenAPI

Эндпоинты в группе **mobile-v1** на `https://college.dgu.ru/docs`.

---

## 7. Критерии приёмки

- [ ] Admin: «Ред.» новости → браузер → форма этой новости без логина
- [ ] «+» создание новости → форма создания
- [ ] То же для мероприятий (`event_*`)
- [ ] Просроченный / повторный code → ошибка, редирект на логин
- [ ] Teacher без прав на чужую новость → 403 в мобилке
