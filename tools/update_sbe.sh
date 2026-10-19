#!/usr/bin/env bash
set -euo pipefail

SBE_DIR=".."
MIGRATE_SCRIPT="./migrate_old_snell.sh"
OLD_SNELL_TAG="v1.13.18-extended-2.6.5"
OLD_SNELL_REPO="https://github.com/shtorm-7/sing-box-extended"

cd "$SBE_DIR"

# 1. Забираем свежие изменения от автора
echo "=> Забираем обновления от upstream..."
git fetch upstream

# 2. Переключаемся на extended и сливаем
echo "=> Сливаем upstream/extended в локальную extended..."
git checkout extended
git merge upstream/extended --no-edit

# 3. Поскольку автор мог изменить ванильный snell, перегенерируем старый
echo "=> Пересобираем старый snell (migrate_old_snell.sh)..."
# Удаляем старые файлы snell_old, чтобы скрипт создал их заново из нового источника
rm -rf protocol/snell/*_old.go option/snell_old.go transport/snell_old/
OLD_SNELL_DIR="$(mktemp -d /opt/software/sbe-old-snell.XXXXXX)"
git clone --branch "$OLD_SNELL_TAG" --depth 1 "$OLD_SNELL_REPO" "$OLD_SNELL_DIR"
SRC="$OLD_SNELL_DIR" DST="$SBE_DIR" "$MIGRATE_SCRIPT"
rm -rf "$OLD_SNELL_DIR"

# 4. Проверяем, что появились новые изменения (snell_old и т.д.)
echo "=> Проверяем статус:"
git status --short

echo ""
echo "Внимание! Если есть конфликты (git пишет 'CONFLICT'), исправь их."
echo "Если всё ок, выполни:"
echo "  git add ."
echo "  git commit -m 'update: new upstream + snell_old migration'"
echo "  git push origin extended"
