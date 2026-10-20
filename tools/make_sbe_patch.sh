#!/usr/bin/env bash
set -euo pipefail

SBE_DIR="/opt/software/sing-box-extended"
OUT="/opt/software/iechechik-sbe.patch"

ORIG_CONN="$SBE_DIR/vendor-utls/conn.go.orig"
MY_CONN="$SBE_DIR/vendor-utls/conn.go"

cd "$SBE_DIR"

echo "=> Генерируем диффы для основного кода (сравнение с upstream)..."
# Сравниваем с upstream (чистый код автора), исключаем мусор
git diff upstream/extended -- . \
  ':!*.orig' \
  ':!vendor-utls' ':!vendor-mieru' \
  ':!tools' ':!FORK_CHANGES.md' ':!.github' \
  > "$OUT"

echo "=> Добавляем дифф для vendor-utls/conn.go..."
if [[ -f "$MY_CONN" ]]; then
    echo "" >> "$OUT"
    if [[ -f "$ORIG_CONN" ]]; then
        # Переходим в vendor-utls, чтобы пути были относительными и правильными
        (cd vendor-utls && git diff --no-index --src-prefix=a/vendor-utls/ --dst-prefix=b/vendor-utls/ conn.go.orig conn.go) >> "$OUT" || true
    else
        (cd vendor-utls && git diff --no-index --src-prefix=a/vendor-utls/ --dst-prefix=b/vendor-utls/ /dev/null conn.go) >> "$OUT" || true
    fi
fi

echo "Готово: $OUT ($(wc -l < "$OUT") строк)"
