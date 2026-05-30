#!/usr/bin/env python3
"""
Распаковывает файлы подписи AAB / RuStore из папки bundle/ в проект dgu_mobile.

Использование:
  python3 install_aab_signing.py
  python3 install_aab_signing.py /path/to/dgu_mobile
  python3 install_aab_signing.py --dry-run
"""

from __future__ import annotations

import argparse
import os
import shutil
import stat
import sys
from datetime import datetime
from pathlib import Path


BUNDLE_DIR_NAME = "bundle"
MARKER_FILES = ("pubspec.yaml",)


def find_project_root(start: Path) -> Path | None:
    current = start.resolve()
    for _ in range(12):
        if any((current / name).is_file() for name in MARKER_FILES):
            return current
        if current.parent == current:
            break
        current = current.parent
    return None


def iter_bundle_files(bundle_root: Path) -> list[Path]:
    files: list[Path] = []
    for path in sorted(bundle_root.rglob("*")):
        if path.is_file():
            files.append(path)
    return files


def copy_tree_file(src: Path, dst: Path, dry_run: bool) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dry_run:
        action = "обновить" if dst.exists() else "создать"
        print(f"  [{action}] {dst}")
        return
    shutil.copy2(src, dst)


def make_executable(path: Path) -> None:
    if not path.exists():
        return
    mode = path.stat().st_mode
    path.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Установить файлы подписи AAB из bundle/ в проект Flutter.",
    )
    parser.add_argument(
        "project_dir",
        nargs="?",
        default=None,
        help="Корень проекта (где pubspec.yaml). По умолчанию — текущая папка или родитель.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Только показать, что будет скопировано.",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Не создавать резервную копию заменяемых файлов.",
    )
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    bundle_root = script_dir / BUNDLE_DIR_NAME
    if not bundle_root.is_dir():
        print(f"Ошибка: не найдена папка {bundle_root}", file=sys.stderr)
        print("Распакуйте полный архив aab_signing_bundle.zip.", file=sys.stderr)
        return 1

    if args.project_dir:
        project_root = Path(args.project_dir).expanduser().resolve()
        if not any((project_root / name).is_file() for name in MARKER_FILES):
            print(f"Ошибка: в {project_root} нет pubspec.yaml", file=sys.stderr)
            return 1
    else:
        project_root = find_project_root(Path.cwd())
        if project_root is None:
            project_root = find_project_root(script_dir.parent.parent)
        if project_root is None:
            print(
                "Ошибка: не найден проект. Укажите путь:\n"
                "  python3 install_aab_signing.py /path/to/dgu_mobile",
                file=sys.stderr,
            )
            return 1

    files = iter_bundle_files(bundle_root)
    if not files:
        print(f"Ошибка: в {bundle_root} нет файлов.", file=sys.stderr)
        return 1

    backup_root: Path | None = None
    if not args.no_backup and not args.dry_run:
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_root = project_root / f".aab_signing_backup_{stamp}"
        backup_root.mkdir(parents=True, exist_ok=True)

    print(f"Проект: {project_root}")
    print(f"Источник: {bundle_root}")
    if args.dry_run:
        print("Режим: dry-run (файлы не изменяются)\n")
    else:
        print("Копирование:\n")

    copied = 0
    for src in files:
        rel = src.relative_to(bundle_root)
        dst = project_root / rel

        if backup_root is not None and dst.exists():
            backup_dst = backup_root / rel
            backup_dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, backup_dst)

        copy_tree_file(src, dst, args.dry_run)
        copied += 1

        if not args.dry_run and rel.as_posix().endswith(".sh"):
            make_executable(dst)

    print(f"\nГотово: {copied} файл(ов).")
    if backup_root is not None:
        print(f"Резервная копия: {backup_root}")

    if not args.dry_run:
        print("\nДальше:")
        print("  flutter build appbundle --release")
        print("  AAB: build/app/outputs/bundle/release/app-release.aab")
        print("\nRuStore PEPK/PEM (при необходимости обновить):")
        print("  ./scripts/rustore_export_pepk.sh")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
