# Аудит интеграции мобильного клиента с Backend API (март 2026)

Источник контрактов: `МОБИЛЬНЫЙ_КЛИЕНТ_BACKEND (2).md`.

Дата аудита: **2026-03-30**.  
Проект: `dgu_mobile` (Flutter).

## Как формируется base URL

В приложении `baseUrl` уже включает суффикс `**/api`**:

- `**ApiConstants.baseUrl**`: по приоритету `.env (API_BASE_URL)` → `--dart-define=API_BASE_URL` → fallback `http://10.0.2.2:8000/api`.
- Все запросы в коде используют пути вида `'/auth/login'`, `'/1c/schedule'`, `'/mobile/events'` и т.п., то есть фактически уходят на:
  - `BASE/api/auth/login`
  - `BASE/api/1c/schedule`
  - `BASE/api/mobile/events`

## Реальные запросы, которые есть в приложении сейчас

Ниже — то, что **фактически вызывается** из `lib/data/api/*` (через `Dio`).

### Auth

- `**POST /api/auth/login`** (form-urlencoded) — логин (email или № зачётки).
- `**GET /api/auth/me**` — профиль текущего пользователя.
- `**POST /api/auth/student/verify-1c**` — проверка студента в 1С.
- `**POST /api/auth/student/register**` — регистрация студента.
- `**POST /api/auth/staff/login**` — добавлено в клиент (API-метод есть), но UI потока может не быть.
- `**POST /api/auth/email-change/request**` — запрос смены email (экран в профиле).
- `**POST /api/auth/email-change/confirm**` — подтверждение смены email (экран в профиле).
- `**POST /api/auth/password-reset/request**` — публичный запрос сброса пароля (экран в профиле).
- `**POST /api/auth/password-reset/request-self**` — запрос сброса по JWT (экран в профиле).
- `**POST /api/auth/password-reset/complete**` — завершение сброса пароля (экран в профиле).

**Заголовки при логине/регистрации**:

- Клиент сохраняет JWT из response header `Authorization: Bearer <jwt>` или `X-Auth-Token`.
- Клиент пытается декодировать `X-User-Data` (Base64 → UTF-8 JSON) и сохраняет в local storage; если не получилось — делает `GET /auth/me`.

### 1С (ones)

- `**GET /api/1c/schedule`** — расписание:
  - на сегодня: без query
  - на дату: `for_date=YYYY-MM-DD`
  - неделя по типу: `week=числитель|знаменатель` + `today_only=false`
  - календарная неделя: 7 последовательных запросов по дням `for_date=...`
- `**GET /api/1c/my-profile**` — профиль 1С (используется и в «студенческом билете», и для подписи «Группа» на главной через кэш).

### Общие методы сайта

- `**GET /api/news**` — новости.
- `**GET /api/journal/grades/my**` — оценки.
- `**GET /api/groups/my**` — группа (но у студента может быть пусто/[]; на главной подпись группы берётся из `1c:my-profile`, если есть).

### Mobile API (`/api/mobile`)

- `**GET /api/mobile/help**` — помощь/FAQ (встроено в экран «Поддержка»).
- `**GET /api/mobile/notification-preferences**` — настройки уведомлений (экран «Уведомления»).
- `**PATCH /api/mobile/notification-preferences**` — сохранение настроек уведомлений.
- `**GET /api/mobile/assignments/my**` — задания (экран «Задания» + счётчик на главной).
- `**POST /api/mobile/assignments**` — добавлено в клиент (API-метод есть), UI создания зависит от роли (teacher/admin).
- `**GET /api/mobile/events**` — мероприятия (в клиенте используется путь `'/mobile/events'` при baseUrl `.../api`).

### Push (FCM)

- `**POST /api/push/device**` — регистрация FCM-токена (best-effort при старте и после логина).
- `**DELETE /api/push/device**` — отвязка FCM-токена при logout (best-effort).

### WebSocket

- `**WS /api/ws?token=<JWT>**` — подключение и тихое обновление кэша для `news/events/assignments` при сообщениях `data_changed` (best-effort).

## Что описано в бэке, но отсутствует в приложении (нет вызовов / нет API-обёрток)

### `/api/mobile/*` (из документа)

- `**GET /api/mobile/student-ticket**` — нет (вместо этого используется `GET /api/1c/my-profile` + `GET /api/auth/me`).
- `**GET /api/mobile/events**` — есть.
- `**POST /api/mobile/events**` — нет.

### Push (FCM)

- (Добавлено) `**POST /api/push/device**`
- (Добавлено) `**DELETE /api/push/device**`

### WebSocket

- (Добавлено) `**WS /api/ws?token=<JWT>**`

### Смена email / сброс пароля

- (Добавлено) `**POST /api/auth/email-change/request**`
- (Добавлено) `**POST /api/auth/email-change/confirm**`
- (Добавлено) `**POST /api/auth/password-reset/request**`
- (Добавлено) `**POST /api/auth/password-reset/request-self**`
- (Добавлено) `**POST /api/auth/password-reset/complete**`

## Что есть в приложении, но не выделено как обязательное в документе

Это не «противоречия», а просто то, что используется приложением и относится к общему API сайта:

- `**GET /api/news**`
- `**GET /api/journal/grades/my**`
- `**GET /api/groups/my**`

## Ошибки API: соответствие единому формату

Документ требует ориентироваться на:

```json
{ "success": false, "error": { "code": "...", "message": "..." }, "detail": "..." }
```

и для `422` — на `error.fields[]`.

Что сделано в клиенте:

- В `AuthApi` извлечение сообщения ошибки обновлено: сначала `error.message`, затем `error.fields[0].message`, затем `detail`, затем fallback на старый FastAPI `detail[0].msg`.

Ограничение текущей реализации:

- В остальных `*Api` (news/grades/groups/events/schedule/profile_1c) пока выбрасывается `DioException` с фиксированным `message`, без парсинга `error.message`. Если нужно «исправь все» по ошибкам глобально — лучше вынести общий парсер ошибок и использовать везде.

## Статус по итогам

- Анализатор `dart analyze`: **OK** (ошибок нет).
- Подключено/исправлено по документу:
  - `for_date` / `today_only` в расписании
  - чтение JWT из заголовков + `X-User-Data`
  - `registration_token` из `verify-1c` → передача в `student/register`
  - `GET /api/mobile/help` (через `'/mobile/help'`)
  - `GET/PATCH /api/mobile/notification-preferences`
  - `GET /api/mobile/assignments/my` (+ кэш + счётчик на главной)
  - `GET /api/mobile/events` (через `'/mobile/events'`)
  - `POST/DELETE /api/push/device` (FCM best-effort)
  - `WS /api/ws?token=...` (best-effort)

## Рекомендованный план до “полного соответствия” документу

1. Решить источник “студенческого билета”:
  - либо внедрить `GET /mobile/student-ticket`,
  - либо оставить текущую схему (`/auth/me` + `/1c/my-profile`) и зафиксировать контракт в документации клиента.
2. Добавить `POST /api/mobile/events` (создание) и UI (teacher/admin), если нужно.
3. Вынести единый парсер ошибок и использовать во всех API-обёртках, не только в `AuthApi`.

