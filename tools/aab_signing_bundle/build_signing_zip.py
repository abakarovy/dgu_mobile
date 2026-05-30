#!/usr/bin/env python3
"""
Собирает aab_signing_bundle.zip из текущего проекта dgu_mobile.

Запуск из корня репозитория:
  python3 tools/aab_signing_bundle/build_signing_zip.py
"""

from __future__ import annotations

import shutil
import sys
import zipfile
from pathlib import Path


# Пути относительно корня проекта → копируются в bundle/ с той же структурой.
FILES_TO_PACK = [
    "pepk.jar",
    "android/upload-keystore.jks",
    "android/key.properties",
    "android/key.properties.example",
    "scripts/rustore_export_pepk.sh",
    "docs/rustore-pepk-upload.md",
    "rustore_signing_out/pepk_out.zip",
    "rustore_signing_out/upload_certificate.pem",
]

README_TEXT = """Набор файлов для подписи AAB и загрузки в RuStore (Колледж ДГУ)

⚠️  СЕКРЕТНО: в архиве keystore и key.properties с паролями.
    Не отправляйте архив в мессенджеры и не выкладывайте в git.

Состав bundle/:
  pepk.jar                          — инструмент PEPK для RuStore
  android/upload-keystore.jks       — ключ подписи release
  android/key.properties            — пароли и alias для Gradle
  android/key.properties.example    — шаблон
  scripts/rustore_export_pepk.sh    — экспорт pepk_out.zip и upload_certificate.pem
  docs/rustore-pepk-upload.md       — инструкция
  rustore_signing_out/              — готовые ZIP и PEM для RuStore (если были сгенерированы)

Установка в проект:
  1. Распакуйте архив
  2. cd aab_signing_bundle
  3. python3 install_aab_signing.py /path/to/dgu_mobile

  Или из корня проекта:
  python3 /path/to/aab_signing_bundle/install_aab_signing.py .

Сборка подписанного AAB:
  flutter build appbundle --release

Обновить ZIP/PEM для RuStore:
  chmod +x scripts/rustore_export_pepk.sh
  ./scripts/rustore_export_pepk.sh
"""


def repo_root() -> Path:
    here = Path(__file__).resolve().parent
    root = here.parent.parent
    if not (root / "pubspec.yaml").is_file():
        print("Запустите из репозитория dgu_mobile.", file=sys.stderr)
        raise SystemExit(1)
    return root


def main() -> int:
    root = repo_root()
    tool_dir = Path(__file__).resolve().parent
    staging = tool_dir / "_staging"
    bundle_dir = staging / "bundle"
    out_zip = root / "dist" / "aab_signing_bundle.zip"

    if staging.exists():
        shutil.rmtree(staging)
    bundle_dir.mkdir(parents=True)

    missing_required: list[str] = []
    packed = 0
    for rel in FILES_TO_PACK:
        src = root / rel
        dst = bundle_dir / rel
        if not src.is_file():
            if rel in (
                "rustore_signing_out/pepk_out.zip",
                "rustore_signing_out/upload_certificate.pem",
            ):
                print(f"  [пропуск] нет {rel} (необязательно)")
                continue
            missing_required.append(rel)
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        packed += 1
        print(f"  + {rel}")

    if missing_required:
        print("\nОшибка: не найдены обязательные файлы:", file=sys.stderr)
        for item in missing_required:
            print(f"  - {item}", file=sys.stderr)
        shutil.rmtree(staging)
        return 1

    shutil.copy2(tool_dir / "install_aab_signing.py", staging / "install_aab_signing.py")
    (staging / "README.txt").write_text(README_TEXT, encoding="utf-8")

    out_zip.parent.mkdir(parents=True, exist_ok=True)
    if out_zip.exists():
        out_zip.unlink()

    with zipfile.ZipFile(out_zip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zip_root = "aab_signing_bundle"
        for path in sorted(staging.rglob("*")):
            if path.is_file():
                rel = path.relative_to(staging)
                arcname = f"{zip_root}/{rel.as_posix()}"
                zf.write(path, arcname)
                print(f"  zip: {arcname}")

    shutil.rmtree(staging)
    size_mb = out_zip.stat().st_size / (1024 * 1024)
    print(f"\nАрхив: {out_zip} ({size_mb:.1f} MB, {packed} файлов в bundle/)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
