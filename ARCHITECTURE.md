# Структура проекта DGU Mobile

Мобильное приложение колледжа/вуза для просмотра оценок, расписания и профиля.

## Дерево каталогов `lib/`

```
lib/
├── main.dart
├── app/
│   ├── app.dart              # Корневой виджет приложения
│   ├── router/
│   │   └── app_router.dart   # GoRouter: маршруты и deep links
│   └── theme/
│       └── app_theme.dart    # Светлая/тёмная тема
├── core/
│   ├── constants/            # API URL, таймауты, строки приложения
│   ├── errors/               # Failures (domain), Exceptions (data)
│   ├── utils/                # Валидаторы, хелперы
│   └── extensions/           # Расширения BuildContext, String и т.д.
├── features/
│   ├── auth/                 # Вход, выход, токены
│   │   ├── data/             # Репозитории, data sources, DTO
│   │   ├── domain/           # Entities, use cases, repository interfaces
│   │   └── presentation/     # Pages, widgets, BLoC/Cubit/Provider
│   ├── dashboard/            # Главный экран после входа
│   ├── grades/               # Оценки по дисциплинам
│   ├── schedule/             # Расписание занятий
│   └── profile/              # Профиль студента, настройки
├── shared/
│   ├── widgets/              # Общие UI: LoadingIndicator, ErrorView
│   ├── services/             # Storage, Analytics, Push
│   └── models/               # (опционально) общие модели
└── data/
    ├── api/                  # HTTP-клиент, interceptors
    └── models/               # Общие DTO из API (User и т.д.)
```

## Слои (Clean Architecture)

- **Presentation** — экраны, виджеты, состояние (BLoC/Cubit/Provider).
- **Domain** — сущности (entities), интерфейсы репозиториев, use cases; без зависимостей от Flutter и API.
- **Data** — репозитории (реализации), API-клиент, локальное хранилище, DTO (models).

## Рекомендации

1. Импорты: только «внутрь» (core ← features ← app), без циклических зависимостей.
2. Фичи изолированы: общий код выносить в `core/` или `shared/`.
3. Сеть: вынести base URL и таймауты в `core/constants/api_constants.dart`.
4. Тесты: зеркалить структуру (`test/features/auth/`, `test/core/`).
