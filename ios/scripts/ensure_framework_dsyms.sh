#!/bin/sh
# Generates missing dSYM bundles for Swift runtime frameworks embedded in the app
# (e.g. objective_c.framework) so App Store symbol upload can match crash UUIDs.
set -e

case "${CONFIGURATION}" in
  Release|Profile) ;;
  *) exit 0 ;;
esac

APP="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
FRAMEWORKS="${APP}/Frameworks"
OUT="${DWARF_DSYM_FOLDER_PATH}"

if [ ! -d "${FRAMEWORKS}" ] || [ -z "${OUT}" ]; then
  exit 0
fi

mkdir -p "${OUT}"

find "${FRAMEWORKS}" -maxdepth 1 -name '*.framework' -print0 2>/dev/null | while IFS= read -r -d '' fw; do
  name=$(basename "${fw}" .framework)
  binary="${fw}/${name}"
  if [ ! -f "${binary}" ]; then
    continue
  fi
  dsym="${OUT}/${name}.framework.dSYM"
  if [ -d "${dsym}" ]; then
    continue
  fi
  xcrun dsymutil "${binary}" -o "${dsym}" 2>/dev/null || true
done

exit 0
