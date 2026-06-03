# Нативная реклама Yandex в «Новостях» и «Мероприятиях»

В лентах **Новости** и **Мероприятия** показывается **нативная реклама** (Android и iOS):

- **Пустой список** — один рекламный блок.
- **Есть карточки** — реклама **между** ними (после каждой, кроме последней).

На Web реклама отключена.

---

## 1. Кабинет Yandex Advertising Network

| Платформа | ID приложения в РСЯ | ID блока «Новости» (нативная) |
|-----------|---------------------|-------------------------------|
| **Android** | `19381333` | `R-M-19381333-1` |
| **iOS** | `19381131` | `R-M-19381131-1` |

Package Android: `ru.dgu.college.dgu_mobile.android`  
Bundle iOS: `ru.dgu.college.dgu-mobile.ios`

**Не подставляйте** в `.env` только число `19381333` — нужен полный ID блока `R-M-…`.

### Статус «тестовое приложение»

Если в кабинете баннер: *«Приложение в тестовом статусе. Для активации добавьте ссылку на приложение»*, SDK на устройстве может отвечать:

```text
Provided AdUnitId 'R-M-19381333-1' does not exist! (code=2)
```

Это **не ошибка кода** — блок ещё не активен для выдачи. Добавьте ссылку на RuStore / App Store в карточке приложения. Для проверки вёрстки до активации используйте демо-id (см. ниже).

### Проверка без боевого блока

```env
YANDEX_NATIVE_AD_UNIT_ID_ANDROID=demo-native-content-yandex
YANDEX_NATIVE_AD_UNIT_ID_IOS=demo-native-content-yandex
YANDEX_ADS_ENABLED=true
```

После изменения `.env` нужен **полный перезапуск** (`flutter run`), не hot reload.

---

## 2. Настройка проекта

В `assets/env/.env` (файл не в git):

```env
YANDEX_NATIVE_AD_UNIT_ID_ANDROID=R-M-19381333-1
YANDEX_NATIVE_AD_UNIT_ID_IOS=R-M-19381131-1
YANDEX_ANDROID_APPLICATION_ID=19381333
YANDEX_ADS_ENABLED=true
```

`YANDEX_ANDROID_APPLICATION_ID` дублирует meta-data в `AndroidManifest.xml`.

Отключить рекламу:

```env
YANDEX_ADS_ENABLED=false
```

---

## 3. Сборка и проверка

```bash
flutter pub get
flutter run -d <android-или-ios>
```

Откройте **Новости** или **Мероприятия**. Карточка с подписью **РЕКЛАМА**.

Лог:

```bash
adb logcat -s YandexAds
```

Ожидается: `Ad type native was integrated successfully` и успешный bind (без `sponsored is not present`).

Строки `AppLovin: NOT INTEGRATED` и т.п. — медиация, их можно игнорировать.

---

## 4. Файлы в репозитории

| Что | Где |
|-----|-----|
| Слоты ленты | `lib/core/ads/feed_ad_slots.dart` |
| Конфиг ID | `lib/core/ads/yandex_ads_config.dart` |
| Карточка Flutter | `lib/features/news/presentation/widgets/native_feed_ad_card.dart` |
| Новости | `lib/features/news/presentation/pages/news_page.dart` |
| Мероприятия | `lib/features/events/presentation/pages/events_page.dart` |
| Android layout | `android/app/src/main/res/layout/layout_news_native_ad.xml` |
| Android loader | `android/.../NewsNativeAdPlatformView.kt` |
| iOS loader | `ios/Runner/NativeFeedAdPlatformView.swift` |
| Инициализация | `lib/main.dart` → `YandexAds.initialize()` |

---

## 5. RuStore / политика

- Обновите политику конфиденциальности (реклама, Yandex).
- В метаданных укажите наличие рекламы (`docs/app-store-metadata.md`).

Контакт: `info@gadzhilaev.ru`.
