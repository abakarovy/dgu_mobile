# DGU Mobile

Мобильное приложение портала Колледжа ДГУ для студентов и преподавателей. Flutter-клиент с подключением к backend API College DGU.

---

## Содержание

- [Требования](#требования)
- [Установка](#установка)
- [Запуск](#запуск)
- [Подключение к backend](#подключение-к-backend)
- [Структура проекта](#структура-проекта)
- [Функциональность](#функциональность)
- [Дизайн и макеты](#дизайн-и-макеты)
- [Сборка релиза](#сборка-релиза)

---

## Требования

- **Flutter** 3.10.7+ (SDK `^3.10.7`)
- **Dart** 3.10+
- Для полной работы: **Backend College DGU** (FastAPI), запущенный и доступный по сети

---

## Установка

```bash
git clone <repo-url>
cd dgu_mobile
flutter pub get
```

Убедитесь, что в проекте есть папки с ресурсами:

- `assets/` — общие ресурсы
- `assets/icons/` — иконки (SVG, PNG)
- `assets/images/` — изображения
- `assets/fonts/` — шрифты (Inter, Montserrat)

---

## Запуск

### Эмулятор или устройство (backend по умолчанию)

По умолчанию приложение обращается к API по адресу `http://10.0.2.2:8000/api` (удобно для Android-эмулятора, где `10.0.2.2` — это `localhost` хоста).

```bash
flutter run
```

### Указание своего URL API

Для реального устройства или другого хоста задайте базовый URL через `--dart-define`:

```bash
# Пример: backend на компе в той же сети
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api

# Пример: production
flutter run --dart-define=API_BASE_URL=https://api.college.dgu.ru/api
```

---

## Подключение к backend

Приложение использует **College DGU API** (документация: `college_site/backend/docs and sql/API_DOCUMENTATION.md`).

### Аутентификация

- **JWT (Bearer)** — токен приходит в заголовках ответа при `POST /api/auth/login` и сохраняется локально (`SharedPreferences`).
- Логин возможен двумя способами:
  - **По номеру зачётной книжки и паролю** — экран «Вход по № з/к» (Фамилия, Имя, Отчество, Номер з/к, Пароль). В API уходит `username` = номер з/к, `password` = пароль.
  - **По E-Mail и паролю** — экран «Войти по E-Mail»; в API уходит `username` = email, `password` = пароль.

После успешного входа токен подставляется во все запросы через интерцептор Dio.

### Основные эндпоинты

| Назначение        | Метод и путь           |
|-------------------|------------------------|
| Вход              | `POST /api/auth/login` |
| Текущий пользователь | `GET /api/auth/me`  |
| Список новостей   | `GET /api/news`        |
| Оценки, расписание, 1С и др. | см. полную документацию API |

Константы API заданы в `lib/core/constants/api_constants.dart`. Клиент — `lib/data/api/api_client.dart` (Dio + интерцептор с токеном), слой авторизации — `lib/data/api/auth_api.dart` и `lib/features/auth/data/repositories/auth_repository_impl.dart`.

---

## Структура проекта

```
lib/
├── main.dart                 # Точка входа, инициализация AppContainer
├── app/
│   ├── app.dart              # MaterialApp и GoRouter
│   ├── router/
│   │   └── app_router.dart   # Маршруты (splash, login, shell, news detail и т.д.)
│   └── theme/
│       └── app_theme.dart    # Тема приложения
├── core/
│   ├── constants/            # app_colors, app_ui, api_constants, app_constants
│   ├── di/
│   │   └── app_container.dart # DI: TokenStorage, ApiClient, AuthApi, AuthRepository
│   ├── theme/
│   │   └── app_text_styles.dart
│   ├── errors/               # exceptions, failures
│   ├── extensions/
│   └── utils/
├── data/
│   ├── api/
│   │   ├── api_client.dart   # Dio, baseUrl, auth interceptor
│   │   └── auth_api.dart     # login, getMe
│   ├── models/
│   │   └── user_model.dart   # DTO пользователя из API
│   └── services/
│       └── token_storage.dart # JWT и user data (SharedPreferences)
├── features/
│   ├── auth/                 # Вход по з/к и по E-Mail
│   │   ├── data/repositories/auth_repository_impl.dart
│   │   ├── domain/entities/user_entity.dart
│   │   ├── domain/repositories/auth_repository.dart
│   │   └── presentation/pages/login_page.dart, login_email_page.dart
│   ├── home/                 # Главная (баннер, карточки)
│   ├── grades/               # Оценки
│   ├── news/                 # Список новостей, детальная новость
│   ├── profile/              # Профиль, студбилет, уведомления, поддержка, выход
│   ├── schedule/             # Расписание
│   ├── shell/                # Нижняя навигация и AppBar
│   ├── splash/               # Стартовый экран
│   ├── support/             # Поддержка (контакты, FAQ)
│   ├── tasks/                # Задания
│   └── notifications/        # Настройки уведомлений
└── shared/                    # app_header, profile_row_button, loading_indicator и др.
```

В каждой фиче используется разделение на **data** (API, репозитории, модели), **domain** (сущности, контракты репозиториев) и **presentation** (страницы, виджеты).

---

## Функциональность

- **Splash** — проверка авторизации; при наличии токена переход на главную, иначе на экран входа.
- **Вход**  
  - По номеру зачётки: Фамилия, Имя, Отчество, Номер з/к, Пароль → запрос к API.  
  - По E-Mail: E-Mail и Пароль → запрос к API.  
  Переключение между способами входа кнопками «Войти по E-Mail» / «Войти по № з/к». Возврат по кнопке «Назад» отключён на экранах входа.
- **Главная** — баннер, быстрые действия (расписание, задания и т.п.).
- **Оценки** — список оценок (данные пока могут быть моковыми).
- **Новости** — список карточек; по тапу открывается полный экран новости (без AppBar и нижней навигации).
- **Профиль** — аватар, имя, блоки «Личные данные» (студбилет), «Настройки» (уведомления, поддержка, выход). Выход очищает токен и перенаправляет на экран входа.
- **Студенческий билет** — экран с ФИО, ID, датами, формой обучения, курсом; копирование данных в буфер.
- **Расписание** — экран расписания (мок/заглушка).
- **Задания** — список заданий (мок).
- **Поддержка** — контакты (телефон, email, сайт), FAQ.
- **Уведомления** — настройки оповещений.

Маршруты заданы в `app_router.dart` (go_router). Детальный экран новости открывается как отдельный маршрут без shell.

---

## Дизайн и макеты

- Референс макета: **448×1200** px; отступы и размеры при необходимости масштабируются под ширину экрана.
- Шрифты: **Inter** (Regular, SemiBold, Bold, ExtraBold), **Montserrat** (Regular, ExtraBold).
- Цвета и отступы вынесены в `lib/core/constants/app_colors.dart` и `app_ui.dart`.
- Используются SVG-иконки из `assets/icons/`, изображения из `assets/images/`.

---

## Сборка релиза

### APK (Android)

```bash
flutter build apk --release
```

Файл: `build/app/outputs/flutter-apk/app-release.apk`

При необходимости передайте URL API:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.college.dgu.ru/api
```

### App Bundle (AAB) для публикации в Google Play

```bash
flutter build appbundle --release
```

---

## Зависимости

| Пакет              | Назначение                    |
|--------------------|-------------------------------|
| dio                | HTTP-клиент, запросы к API    |
| go_router          | Маршрутизация                |
| flutter_svg        | Отображение SVG-иконок       |
| image_picker       | Выбор фото (аватар в профиле)|
| path_provider      | Пути к файлам                |
| shared_preferences | Токен и данные пользователя  |
| url_launcher       | Открытие ссылок и телефона   |

---

## Лицензия

Внутренний проект Колледжа ДГУ. Публикация и распространение — по согласованию с правообладателем.
