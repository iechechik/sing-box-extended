#!/usr/bin/env bash
set -euo pipefail

SBE_DIR="/opt/software/sing-box-extended"
PATCH_FILE="/opt/software/iechechik-sbe.patch"

# 1. Сносим старую директорию
rm -rf "$SBE_DIR"

# 2. Клонируем SBE автора
echo "=> Клонируем sing-box-extended..."
git clone -b extended https://github.com/shtorm-7/sing-box-extended "$SBE_DIR"
cd "$SBE_DIR"

# 3. Клонируем UTLS
echo "=> Клонируем utls в vendor-utls..."
git clone https://github.com/metacubex/utls.git vendor-utls
rm -rf vendor-utls/.git

# 4. Накатываем патч и СОЗДАЕМ .orig файлы
if [ -f "$PATCH_FILE" ]; then
  echo "=> Применяем патч $PATCH_FILE с сохранением .orig..."
  patch -p1 -b -z .orig < "$PATCH_FILE"
else
  echo "Ошибка: патч $PATCH_FILE не найден!"
  exit 1
fi

# 5. Настраиваем remote для будущих обновлений
echo "=> Настраиваем remote (upstream и origin)..."
git remote rename origin upstream
git remote add origin https://github.com/iechechik/sing-box-extended.git

echo "Готово! Исходники развернуты, пропатчены, .orig созданы."
exit 0
