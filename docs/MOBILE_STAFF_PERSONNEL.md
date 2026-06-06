# Модуль «Персонал и Администрация» — инструкция для мобильного разработчика

Документ описывает API бэкенда `college.dgu.ru` для закрытой части приложения: вход сотрудников, профиль с аватаром, мобильная админка приёмной кампании.

**Полное руководство** (преподаватели, админка сайта, кабинет отделения, все разделы): [MOBILE_STAFF_AND_ADMIN.md](./MOBILE_STAFF_AND_ADMIN.md).

**Базовый URL:** `https://college.dgu.ru` (или staging / `NEXT_PUBLIC_API_URL` при разработке).

**Префикс API:** `/api/v1`

**Авторизация:** после входа передавайте JWT в заголовке:

```http
Authorization: Bearer <token>
```

---

## 1. Ролевая модель

| Роль | `is_admin` | `can_access_site_admin` | `can_access_admission_admin` | В приложении |
|------|------------|-------------------------|------------------------------|--------------|
| `teacher` | false | false | false | Кабинет преподавателя |
| `department`, `department_methodist` | false | false | false | Кабинет отделения |
| `event_manager`, `methodist` | false | **true** | **true** | Админка сайта (часть) + абитуриенты |
| `admin` | **true** | **true** | **true** | Полная админка + проходной балл |

Меню стройте по **`GET /api/v1/staff/capabilities`** (см. [MOBILE_STAFF_AND_ADMIN.md](./MOBILE_STAFF_AND_ADMIN.md)).

Установка проходного балла — **только** `is_admin === true`.

---

## 2. Авторизация персонала

### `POST /api/v1/auth/staff`

**Тело (JSON):**

```json
{
  "email": "teacher@dgu.ru",
  "password": "secret"
}
```

**Успех `200`:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 12,
    "fio": "Иванов Иван Иванович",
    "email": "teacher@dgu.ru",
    "role": "teacher",
    "is_admin": false,
    "position": "Кафедра информатики",
    "avatar_url": "/uploads/avatars/avatar_abc123.jpg"
  }
}
```

| Поле | Описание |
|------|----------|
| `token` | JWT, срок жизни ~30 дней |
| `user.fio` | ФИО |
| `user.role` | `teacher`, `department`, `department_methodist`, `admin`, `event_manager`, `methodist` |
| `user.is_admin` | `true` только для суперадмина сайта |
| `user.position` | Должность / подразделение (для отображения под ФИО) |
| `user.avatar_url` | Относительный путь или `null` |

**Ошибки:**

| Код | Когда |
|-----|--------|
| `400` | Пустой email |
| `401` | Неверный логин или пароль |
| `403` | Аккаунт деактивирован или роль не подходит |
| `503` | 1С / сервис колледжа недоступен |

**Логика на клиенте:**

1. Сохранить `token` (Secure Storage).
2. Сохранить `user`.
3. Если `user.is_admin === true` — показать раздел «Панель управления».

> Старый веб-эндпоинт `POST /api/auth/staff/login` возвращает токен в **заголовках**, не в JSON. Для мобилки используйте только `/api/v1/auth/staff`.

---

## 3. Профиль сотрудника

### `GET /api/v1/user/profile`

Заголовок `Authorization: Bearer …`

Ответ — тот же объект `user`, что при логине (актуальные данные после смены аватара).

---

## 4. Аватар

### `POST /api/v1/user/avatar`

**Тип:** `multipart/form-data`  
**Поле файла:** `avatar` (обязательно это имя ключа)

**Ограничения (сервер):**

- Форматы: `.jpg`, `.jpeg`, `.png`
- Размер: до **5 МБ**
- Сервер обрезает и сжимает до **500×500 px** (квадрат 1:1)

**Успех `200`:**

```json
{
  "avatar_url": "/uploads/avatars/avatar_f3a1b2c4.jpg"
}
```

**Отображение картинки:**

```text
https://college.dgu.ru/uploads/avatars/avatar_f3a1b2c4.jpg
```

(префикс домена + значение `avatar_url`)

### Рекомендации по UI (из ТЗ)

1. Тап по аватару → системный диалог: «Камера» / «Галерея».
2. После выбора — **нативный кроппер ОС** (1:1).
3. На сервер отправляйте **уже обрезанный** файл (не оригинал с полным разрешением).
4. После успеха обновите аватар в UI из `avatar_url`.

**Пример (Dart / http):**

```dart
final request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/v1/user/avatar'),
);
request.headers['Authorization'] = 'Bearer $token';
request.files.add(await http.MultipartFile.fromPath('avatar', croppedFilePath));
final response = await request.send();
```

---

## 5. Мобильная админка (приёмная кампания)

Доступна после входа с ролью `admin`, `event_manager` или `methodist`.  
Вкладка «Проходной балл» — только при `is_admin === true`.

### 5.1. Список абитуриентов

#### `GET /api/v1/admin/applicants`

**Query:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `search` | string | Живой поиск по ФИО, email, телефону |
| `skip` | int | Пагинация, по умолчанию `0` |
| `limit` | int | По умолчанию `100`, макс. `500` |

**Ответ `200`:**

```json
{
  "items": [
    {
      "id": 1,
      "full_name": "Иванов Иван Иванович",
      "exam_score": 4.52,
      "status": "registered"
    }
  ],
  "total": 128
}
```

**Статусы `status`:**

| Значение | Смысл |
|----------|--------|
| `registered` | Зарегистрирован |
| `payment_list` | В списке на оплату |
| `rejected` | Отклонён (резерв) |
| `enrolled` | Зачислен (резерв) |

**UI:** строка поиска с debounce 300–500 ms → повторный `GET` с `search=`.

### 5.2. Карточка абитуриента (контакты)

#### `GET /api/v1/admin/applicants/{id}`

**Ответ `200`:**

```json
{
  "id": 1,
  "full_name": "Иванов Иван Иванович",
  "email": "ivanov@mail.ru",
  "phone": "+79001234567",
  "phone_extra": "+79007654321",
  "exam_score": 4.52,
  "status": "registered"
}
```

### 5.3. Текущий проходной балл

#### `GET /api/v1/admin/payment-cutoff`

```json
{
  "cutoff_score": 4.35
}
```

`cutoff_score: null` — порог ещё не задавали.

### 5.4. Установить проходной балл и уведомить

#### `POST /api/v1/admin/set-payment-cutoff`

**Только `role: admin`.**

**Тело:**

```json
{
  "cutoff_score": 4.35
}
```

**Ответ `200`:**

```json
{
  "cutoff_score": 4.35,
  "moved_to_payment_count": 12,
  "push_sent": 8,
  "push_failed": 0
}
```

**Логика сервера:**

1. Сохраняет порог в настройках.
2. Все абитуриенты со статусом `registered` и `exam_score >= cutoff_score` → `payment_list`.
3. Абитуриентам с привязанным `user_id` (аккаунт в приложении) отправляется **FCM push**.

**Push payload (data):**

```json
{
  "type": "admission_payment_list",
  "cutoff": "4.35"
}
```

**UI вкладки 2:**

- Поле ввода числа (например `4.35`, разделитель — точка).
- Кнопка «Применить и уведомить» → `POST /api/v1/admin/set-payment-cutoff`.
- Показать `moved_to_payment_count` и результат push.

---

## 6. Push-уведомления для абитуриентов

Чтобы абитуриент получил push при переводе «На оплату»:

1. У записи абитуриента в БД должен быть **`user_id`** — ID пользователя приложения.
2. Пользователь должен зарегистрировать FCM-токен: `POST /api/push/device` (существующий эндпоинт студенческого приложения).

Если `user_id` нет — статус обновится, push не уйдёт (`push_sent: 0`).

---

## 7. Дополнительно (наполнение базы)

Для тестов и приёмной комиссии бэкенд поддерживает создание абитуриента (не обязательно вызывать из приложения):

#### `POST /api/v1/admin/applicants`

```json
{
  "full_name": "Иванов Иван Иванович",
  "email": "ivanov@mail.ru",
  "phone": "+79001234567",
  "phone_extra": null,
  "exam_score": 4.5,
  "user_id": null
}
```

---

## 8. Чеклист QA (из ТЗ)

1. **Авторизация:** преподаватель — без «Панель управления»; админ — с панелью и кнопкой порога.
2. **Кроппер:** на iOS/Android отправляется обрезанное 1:1 фото; после загрузки аватар обновляется.
3. **Поиск:** при 1000+ записей — debounce + пагинация `skip`/`limit`.
4. **Порог:** после применения статусы и push соответствуют ответу API.

---

## 9. Сводка эндпоинтов

| Метод | Путь | Auth | Назначение |
|-------|------|------|------------|
| `POST` | `/api/v1/auth/staff` | — | Вход персонала |
| `GET` | `/api/v1/user/profile` | Bearer | Профиль |
| `POST` | `/api/v1/user/avatar` | Bearer | Загрузка аватара |
| `GET` | `/api/v1/admin/applicants` | Bearer staff* | Список абитуриентов |
| `GET` | `/api/v1/admin/applicants/{id}` | Bearer staff* | Контакты |
| `GET` | `/api/v1/admin/payment-cutoff` | Bearer staff* | Текущий порог |
| `POST` | `/api/v1/admin/set-payment-cutoff` | Bearer **admin** | Порог + статусы + push |

\* роли `admin`, `event_manager`, `methodist`

---

## 10. Деплой бэкенда

После обновления кода на сервере:

```bash
cd /var/www/college_site && git pull
docker compose build --pull=false backend
docker compose up -d backend
```

Новые таблицы/колонки (`applicants`, `users.avatar_url`, `system_settings.admission_payment_cutoff`) создаются при старте backend автоматически.

Зависимость **Pillow** нужна для ресайза аватаров (уже в `requirements.txt`).

---

## 11. Связанные документы

- `docs/MOBILE_HEALTH_CLIENT.md` — health / обновление приложения
- `backend/docs/STUDENT_BOOK_NOT_FOUND_YOUGILE_MOBILE.md` — регистрация студентов (отдельный поток)

Вопросы по API — к бэкенд-разработчику сайта колледжа.
