#!/usr/bin/env bash
set -euo pipefail

SBE_DIR="/opt/software/sing-box-extended"

cd "$SBE_DIR"

# 1. Забираем свежие изменения от автора
echo "=> Забираем обновления от upstream..."
git fetch upstream

# 2. Переключаемся на extended и сливаем
echo "=> Сливаем upstream/extended в локальную extended..."
git checkout extended
git merge upstream/extended --no-edit

# 3. Проверяем статус
echo "=> Проверяем статус:"
git status --short

echo ""
echo "Внимание! Если есть конфликты (git пишет 'CONFLICT'), исправь их."
echo "Если всё ок, выполни:"
echo "  git add ."
echo "  git commit -m 'update: new upstream'"
echo "  git push origin extended"
