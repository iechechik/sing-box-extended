#!/usr/bin/env bash
set -euo pipefail

SBE_DIR=".."
PATCH_FILE="./iechechik-sbe.patch"

# 1. Сносим старую директорию
rm -rf "$SBE_DIR"

# 2. Клонируем SBE
echo "=> Клонируем sing-box-extended..."
git clone -b extended https://github.com/shtorm-7/sing-box-extended "$SBE_DIR"
cd "$SBE_DIR"

# 3. Клонируем UTLS
echo "=> Клонируем utls в vendor-utls..."
git clone https://github.com/metacubex/utls.git vendor-utls
rm -rf vendor-utls/.git

# 4. Накатываем патч
if [ -f "$PATCH_FILE" ]; then
  echo "=> Применяем патч $PATCH_FILE с сохранением .orig бэкапов..."
  patch -p1 -b -z .orig < "$PATCH_FILE"
else
  echo "Ошибка: патч $PATCH_FILE не найден!"
  exit 1
fi
echo "Готово! Исходники развернуты и пропатчены."

# 5. Возвращаем твои коммиты из бэкапа форка
echo "=> Восстанавливаем правки из форка github/iechechik/sing-box-extended..."
git remote add origin https://github.com/iechechik/sing-box-extended.git 2>/dev/null || true
git fetch origin
git checkout extended
# Сливаем твою ветку из форка с текущим состоянием (где применен патч)
git merge origin/extended --no-edit

echo "Всё готово. Если есть конфликты — исправь их."
exit 0
