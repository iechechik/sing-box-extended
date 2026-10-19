#!/usr/bin/env bash
set -euo pipefail

SBE_DIR=".."
PATCH_FILE="./iechechik-sbe.patch"
MIGRATE_SCRIPT="./migrate_old_snell.sh"
OLD_SNELL_TAG="v1.13.18-extended-2.6.5"
OLD_SNELL_REPO="https://github.com/shtorm-7/sing-box-extended"

# 1. Сносим старую директорию
rm -rf "$SBE_DIR"

# 2. Клонируем SBE
echo "=> Клонируем sing-box-extended..."
git clone -b extended https://github.com/shtorm-7/sing-box-extended "$SBE_DIR"
cd "$SBE_DIR"

# 3. Клонируем старый snell (тег 2.6.5) и переносим его в свежий чекаут
echo "=> Клонируем старый snell ($OLD_SNELL_TAG)..."
OLD_SNELL_DIR="$(mktemp -d /opt/software/sbe-old-snell.XXXXXX)"
git clone --branch "$OLD_SNELL_TAG" --depth 1 "$OLD_SNELL_REPO" "$OLD_SNELL_DIR"

echo "=> Переносим старый snell в свежий чекаут..."
SRC="$OLD_SNELL_DIR" DST="$SBE_DIR" "$MIGRATE_SCRIPT"
rm -rf "$OLD_SNELL_DIR"

# 4. Клонируем UTLS
echo "=> Клонируем utls в vendor-utls..."
git clone https://github.com/metacubex/utls.git vendor-utls
rm -rf vendor-utls/.git vendor-mieru/.git

# 5. Накатываем патч и СОЗДАЕМ .orig файлы для каждого измененного файла
if [ -f "$PATCH_FILE" ]; then
  echo "=> Применяем патч $PATCH_FILE с сохранением .orig бэкапов..."
  patch -p1 -b -z .orig < "$PATCH_FILE"
else
  echo "Ошибка: патч $PATCH_FILE не найден!"
  exit 1
fi
echo "Готово! Исходники развернуты, пропатчены, файлы .orig созданы."

# 5. Возвращаем твои коммиты из бэкапа
echo "Восстанавливаем правки из форка github/iechechik/sing-box/extended"
cd "$SBE_DIR"
git remote add origin https://github.com/iechechik/sing-box-extended.git 2>/dev/null || true
git fetch origin
git checkout extended
# Сливаем твою ветку из форка с текущим состоянием (где применен патч)
git merge origin/extended --no-edit

echo "Всё готово. Если есть конфликты — исправь их."
exit 0
