#!/usr/bin/env bash
# Экспорт ZIP (PEPK) и PEM для загрузки AAB в RuStore.
# Отредактируйте KEYSTORE / ALIAS при необходимости. Пароли keytool/pepk запросит сам.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Пути под этот проект (скопируйте в RuStore без правок, если всё совпадает).
KEYSTORE="${PROJECT_ROOT}/android/upload-keystore.jks"
ALIAS="upload"

# Если в кабинете RuStore показали другую команду — вставьте их ключ целиком.
ENCRYPTION_KEY="000097991a66926f113727b77535a4b623473ee0193c2ee21d745048e24e94679cc0de6dc9ed568b78a3365f68ba68f70d22bb1d78724a2aa23d2e1462983b8912bdad39"

PEPK_JAR="${PROJECT_ROOT}/pepk.jar"
OUT_DIR="${PROJECT_ROOT}/rustore_signing_out"
ZIP_OUT="${OUT_DIR}/pepk_out.zip"
PEM_OUT="${OUT_DIR}/upload_certificate.pem"

if [[ ! -f "$PEPK_JAR" ]]; then
  echo "Не найден $PEPK_JAR — положите pepk.jar в корень проекта." >&2
  exit 1
fi

if [[ ! -f "$KEYSTORE" ]]; then
  echo "Не найден keystore: $KEYSTORE" >&2
  echo "Создайте его (см. docs/rustore-pepk-upload.md) или поправьте KEYSTORE в этом скрипте." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo ">>> PEPK → $ZIP_OUT"
java -jar "$PEPK_JAR" \
  --keystore "$KEYSTORE" \
  --alias "$ALIAS" \
  --output "$ZIP_OUT" \
  --encryptionkey="$ENCRYPTION_KEY" \
  --include-cert

echo ">>> PEM → $PEM_OUT"
keytool -exportcert -rfc \
  -alias "$ALIAS" \
  -keystore "$KEYSTORE" \
  -file "$PEM_OUT"

echo "Готово:"
ls -lah "$ZIP_OUT" "$PEM_OUT"
