#!/usr/bin/env bash
set -euo pipefail

SBE_DIR="/opt/software/sing-box-extended"
OUT="/opt/software/iechechik-sbe.patch"

# --- Пути к внешнему файлу conn.go ---
# Укажи реальный путь к оригиналу (если есть) и к твоему измененному файлу
ORIG_CONN="$SBE_DIR/vendor-utls/conn.go.orig" 
MY_CONN="$SBE_DIR/vendor-utls/conn.go" 

cd "$SBE_DIR"

 cd "$SBE_DIR"
 
# 1. Генерируем диффы для основного репозитория sing-box-extended
git diff origin/extended -- . \
+  ':!*.orig' \
+  ':!vendor-utls' ':!vendor-mieru' \
+  ':!option/snell.go' ':!protocol/snell/inbound.go' ':!protocol/snell/outbound.go' \
+  > "$OUT"

# 2. Дописываем дифф для внешнего файла conn.go в конец патча
if [[ -f "$MY_CONN" ]]; then
    echo "" >> "$OUT"
    if [[ -f "$ORIG_CONN" ]]; then
        # Если есть оригинальный файл для сравнения:
        diff -u --label "a/vendor-utls/conn.go" --label "b/vendor-utls/conn.go" "$ORIG_CONN" "$MY_CONN" >> "$OUT" || true
    else
        # Если оригинала нет, добавляем файл целиком как новый:
        diff -u --label "a/vendor-utls/conn.go" --label "b/vendor-utls/conn.go" /dev/null "$MY_CONN" >> "$OUT" || true
    fi
fi

echo "Готово: $OUT ($(wc -l < "$OUT") строк)"
exit 0
