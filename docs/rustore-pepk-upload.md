# RuStore: ZIP (PEPK) и PEM для загрузки AAB

В консоли RuStore при загрузке AAB нужны **два файла**, сделанные из **одного и того же** хранилища ключей и **одного alias**:

| Поле в RuStore | Файл |
|----------------|------|
| ZIP не более 100 KB | `pepk_out.zip` (из `pepk.jar`, зашифрованный приватный ключ + сертификат внутри архива) |
| PEM не более 100 KB | `upload_certificate.pem` (публичный сертификат ключа подписи, RFC/PEM) |

Пути в этом проекте (macOS, ваш каталог):

- Корень проекта: `/Users/admin/Documents/MobileProjects/dgu_mobile`
- `pepk.jar`: `/Users/admin/Documents/MobileProjects/dgu_mobile/pepk.jar`
- Хранилище ключей (создадите сами, в git не попадает): `/Users/admin/Documents/MobileProjects/dgu_mobile/android/upload-keystore.jks`
- Папка с результатами для RuStore: `/Users/admin/Documents/MobileProjects/dgu_mobile/rustore_signing_out/`  
  (не коммитьте её — в `.gitignore`)

---

## Важно про ключ шифрования `--encryptionkey`

В справке RuStore обычно есть кнопка **«Скопировать»** с командой и **вашим** ключом для PEPK. Если там другая длинная hex-строка, чем ниже — **используйте ту, что из кабинета RuStore**, а не из этой инструкции.

Стандартный ключ Google PEPK (часто совпадает с тем, что показывают для совместимости с Play App Signing):

```
000097991a66926f113727b77535a4b623473ee0193c2ee21d745048e24e94679cc0de6dc9ed568b78a3365f68ba68f70d22bb1d78724a2aa23d2e1462983b8912bdad39
```

Если RuStore прислал другой — подставьте его в команду вместо этой строки.

---

## Шаг 1. Установить Java (если ещё не стоит)

Нужен `java` в терминале для `pepk.jar` и `keytool`:

```bash
java -version
```

---

## Шаг 2. Один раз создать keystore (если ещё нет своего)

Если у вас **уже есть** `.jks`/`.keystore`, с которым будете подписывать RuStore — пропустите создание и в командах ниже подставьте **свой путь к файлу** и **свой alias**.

Создание нового (alias по умолчанию для этих команд — `upload`):

```bash
cd /Users/admin/Documents/MobileProjects/dgu_mobile

keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Сохраните пароли хранилища и ключа в надёжном месте. Без них обновлять приложение в RuStore будет нельзя.

Заполните шаблон подписи Flutter:

```bash
cp android/key.properties.example android/key.properties
# отредактируйте android/key.properties — реальные пароли и при необходимости путь/alias
```

После этого соберите релизный AAB с подписью этого ключа (пример):

```bash
flutter build appbundle --release
```

AAB будет в `build/app/outputs/bundle/release/app-release.aab`.

---

## Шаг 3. Сформировать ZIP через PEPK (поле «Загрузите созданный ZIP»)

Создайте каталог для выходных файлов и выполните (**пароли keystore введёте в терминале по запросу**):

```bash
cd /Users/admin/Documents/MobileProjects/dgu_mobile

mkdir -p rustore_signing_out

java -jar /Users/admin/Documents/MobileProjects/dgu_mobile/pepk.jar \
  --keystore /Users/admin/Documents/MobileProjects/dgu_mobile/android/upload-keystore.jks \
  --alias upload \
  --output /Users/admin/Documents/MobileProjects/dgu_mobile/rustore_signing_out/pepk_out.zip \
  --encryptionkey=000097991a66926f113727b77535a4b623473ee0193c2ee21d745048e24e94679cc0de6dc9ed568b78a3365f68ba68f70d22bb1d78724a2aa23d2e1462983b8912bdad39 \
  --include-cert
```

Если ваш alias не `upload` — замените `upload` в `--alias` на свой.  
Если keystore не в `android/upload-keystore.jks` — замените полный путь в `--keystore`.

Готовый файл для RuStore:

`/Users/admin/Documents/MobileProjects/dgu_mobile/rustore_signing_out/pepk_out.zip`

---

## Шаг 4. Экспорт PEM (поле «Загрузите сертификат загрузки»)

Тот же keystore и тот же alias:

```bash
keytool -exportcert -rfc \
  -alias upload \
  -keystore /Users/admin/Documents/MobileProjects/dgu_mobile/android/upload-keystore.jks \
  -file /Users/admin/Documents/MobileProjects/dgu_mobile/rustore_signing_out/upload_certificate.pem
```

Файл для RuStore:

`/Users/admin/Documents/MobileProjects/dgu_mobile/rustore_signing_out/upload_certificate.pem`

Проверить размер (оба должны быть < 100 KB):

```bash
ls -lah rustore_signing_out/pepk_out.zip rustore_signing_out/upload_certificate.pem
```

---

## Быстрый вариант: один скрипт

Из корня репозитория:

```bash
chmod +x scripts/rustore_export_pepk.sh
./scripts/rustore_export_pepk.sh
```

При необходимости отредактируйте переменные `KEYSTORE`, `ALIAS`, `ENCRYPTION_KEY` в начале `scripts/rustore_export_pepk.sh`.

---

## Если уже публиковали сборку другим ключом

Для следующих версий нужен **тот же** сертификат/ключ, что и у первого релиза. Новый keystore = новое приложение в RuStore (или отдельный процесс переноса по правилам площадки).
