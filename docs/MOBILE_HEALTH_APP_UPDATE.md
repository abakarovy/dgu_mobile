# `GET /api/health` — заметки для бэкенда (college_site)

Контракт **2026-05**. Что делает **мобильный клиент** — в [MOBILE_HEALTH_CLIENT.md](./MOBILE_HEALTH_CLIENT.md).

---

## Запрос от клиента

```
GET /api/health?app_version=1.1.0&platform=android&device_model=...
```

| Параметр | Описание |
|----------|----------|
| `app_version` | Semver **без** номера сборки (`1.1.0`) |
| `platform` | `android`, `ios`, `windows`, … |
| `device_model` | Модель + ОС (URL-encoded) |

Заголовки (опционально): `X-App-Version`, `X-App-Platform`, `X-Device-Model`.

Авторизация **не** требуется.

---

## Ответ

### Без обновления

```json
{
  "status": "ok",
  "server_time": "2026-06-03T14:30:00+03:00"
}
```

### Опциональное обновление

Клиент сравнивает **semver**. «Позже» запоминает `latest_version`.

```json
{
  "status": "ok",
  "app_update": {
    "update_available": true,
    "force_update": false,
    "latest_version": "1.2.0",
    "title": "Доступно обновление",
    "message": "…",
    "store_url_rustore": "https://…",
    "store_url_android": "https://…",
    "store_url_ios": "https://…"
  }
}
```

### Принудительное

- `force_update: true`, или
- `min_version` выше, чем `app_version` в query (например `1.1.0` < `1.1.1`)

```json
{
  "app_update": {
    "update_available": true,
    "force_update": false,
    "min_version": "1.1.1",
    "latest_version": "1.2.0"
  }
}
```

---

## Правила для бэкенда

1. Для `platform` **windows** / **linux** / **macos** / **web** — **не** отдавать `app_update` (только `status` + телеметрия).
2. Сравнение версий на сервере — **semver** (`latest_version`, `min_version`), не номер сборки из pubspec (`+27`).
3. При сбое конфига обновлений — `200` и `status: "ok"` без `app_update`.
4. **503** + `status: "degraded"` только при недоступности Postgres; клиент не блокирует старт из‑за отсутствия `app_update`.

---

## QA (сервер)

| `app_version` в query | Настройка | Ожидание в Android/iOS |
|-----------------------|-----------|-------------------------|
| 1.1.0 | `latest_version=1.2.0` | Диалог с «Позже» |
| 1.1.0 | `min_version=1.1.1` | Принудительно |
| 1.2.0 | `latest_version=1.2.0` | Без диалога |

```bash
curl -s "https://college.dgu.ru/api/health?app_version=1.1.0&platform=android"
```

---

## Админка

Версию для политики обновлений администратор задаёт в **semver** из pubspec (`1.2.0`, без `+build`).
