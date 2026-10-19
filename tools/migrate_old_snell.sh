#!/usr/bin/env bash
#
# Переносит старую (2.6.5) реализацию Snell в текущий чекаут (sing-box-extended)
# как альтернативную сборку под тегом with_old_snell.
#
# Использование:
#   cd /opt/software
#   ./migrate_old_snell.sh
#
# Что делает:
#   1. Существующие "ванильные" файлы (option/snell.go, protocol/snell/{in,out}bound.go)
#      бэкапит в *.orig и создаёт новую версию с добавленным //go:build !with_old_snell
#   2. Копирует старые файлы из sbe-2.6.5 под новыми именами (*_old.go / transport/snell_old/)
#      и добавляет //go:build with_old_snell
#   3. В скопированных protocol/snell/*_old.go правит импорт transport/snell -> transport/snell_old
#
# Скрипт идемпотентен: повторный запуск не наложит тег дважды и не перезапишет
# уже созданные *_old файлы (переспросит явным сообщением).

set -euo pipefail

SRC="${SRC:-sbe-2.6.5}"
DST="${DST:-sing-box-extended}"

if [[ ! -d "$SRC" ]]; then
    echo "Не найден каталог с исходниками: $(pwd)/$SRC" >&2
    exit 1
fi
if [[ ! -d "$DST" ]]; then
    echo "Не найден целевой каталог: $(pwd)/$DST" >&2
    exit 1
fi

# --- вспомогательная функция: добавить //go:build <tag> первой строкой файла ---
# Идемпотентна: если файл уже начинается с "//go:build", ничего не делает.
add_build_tag() {
    local tag="$1"
    local file="$2"

    if [[ ! -f "$file" ]]; then
        echo "  ПРОПУСК (нет файла): $file" >&2
        return 1
    fi
    if head -n1 "$file" | grep -q '^//go:build'; then
        echo "  уже есть build-тег, пропускаю: $file"
        return 0
    fi
    local tmp
    tmp="$(mktemp)"
    {
        echo "//go:build ${tag}"
        echo
        cat "$file"
    } > "$tmp"
    mv "$tmp" "$file"
    echo "  добавлен тег '${tag}': $file"
}

# --- шаг 1: бэкап и разметка текущих ("ванильных") файлов тегом !with_old_snell ---
echo "== Шаг 1: разметка текущих файлов ($DST) тегом !with_old_snell =="

VANILLA_FILES=(
    "$DST/option/snell.go"
    "$DST/protocol/snell/inbound.go"
    "$DST/protocol/snell/outbound.go"
)

for f in "${VANILLA_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "  ПРОПУСК (нет файла): $f" >&2
        continue
    fi
    orig="${f}.orig"
    if [[ -f "$orig" ]]; then
        echo "  бэкап уже существует, не трогаю: $orig"
    else
        cp -p "$f" "$orig"
        echo "  бэкап создан: $orig"
    fi
    add_build_tag "!with_old_snell" "$f"
done

# --- шаг 2: старый транспорт -> transport/snell_old/ (package snell, тег with_old_snell) ---
echo
echo "== Шаг 2: перенос $SRC/transport/snell/ -> $DST/transport/snell_old/ =="

mkdir -p "$DST/transport/snell_old"

TRANSPORT_FILES=(
    address.go
    cipher.go
    client.go
    pool.go
    service.go
    shadowaead.go
    snell.go
    v4.go
)

for f in "${TRANSPORT_FILES[@]}"; do
    src_file="$SRC/transport/snell/$f"
    dst_file="$DST/transport/snell_old/$f"
    if [[ ! -f "$src_file" ]]; then
        echo "  ПРОПУСК (нет файла в источнике): $src_file" >&2
        continue
    fi
    if [[ -f "$dst_file" ]]; then
        echo "  уже скопирован, пропускаю: $dst_file"
        continue
    fi
    cp -p "$src_file" "$dst_file"
    add_build_tag "with_old_snell" "$dst_file"
done

# --- шаг 3: старые option/protocol файлы -> *_old.go (тег with_old_snell) ---
echo
echo "== Шаг 3: перенос option/snell.go и protocol/snell/{in,out}bound.go =="

copy_old() {
    local src_file="$1"
    local dst_file="$2"

    if [[ ! -f "$src_file" ]]; then
        echo "  ПРОПУСК (нет файла в источнике): $src_file" >&2
        return 1
    fi
    if [[ -f "$dst_file" ]]; then
        echo "  уже скопирован, пропускаю: $dst_file"
        return 0
    fi
    cp -p "$src_file" "$dst_file"
    add_build_tag "with_old_snell" "$dst_file"
}

copy_old "$SRC/option/snell.go"              "$DST/option/snell_old.go"
copy_old "$SRC/protocol/snell/inbound.go"    "$DST/protocol/snell/inbound_old.go"
copy_old "$SRC/protocol/snell/outbound.go"   "$DST/protocol/snell/outbound_old.go"

 echo
 echo "== Шаг 4: правка импорта в protocol/snell/{in,out}bound_old.go =="
 
 for f in "$DST/protocol/snell/inbound_old.go" "$DST/protocol/snell/outbound_old.go"; do
     if [[ ! -f "$f" ]]; then
         continue
     fi
     if grep -q '"github.com/sagernet/sing-box/transport/snell_old"' "$f"; then
         echo "  импорт уже поправлен: $f"
         continue
     fi
     sed -i 's#"github.com/sagernet/sing-box/transport/snell"#"github.com/sagernet/sing-box/transport/snell_old"#' "$f"
     echo "  импорт поправлен: $f"
 done
 
# --- шаг 5: адаптация под ядро 1.14 ---
# В 1.13.18 были два интерфейса: ConnectionHandler (deprecated, без onClose)
# и ConnectionHandlerEx (с onClose). В 1.14 их слили в один ConnectionHandler
# с сигнатурой бывшего ...Ex, метод при этом переименовали в просто NewConnection.
echo
echo "== Шаг 5: адаптация inbound_old.go под ядро 1.14 (ConnectionHandler) =="

INBOUND_OLD="$DST/protocol/snell/inbound_old.go"
if [[ -f "$INBOUND_OLD" ]]; then
    if grep -q 'func (h \*Inbound) NewConnectionEx(' "$INBOUND_OLD"; then
        sed -i 's/func (h \*Inbound) NewConnectionEx(/func (h *Inbound) NewConnection(/' "$INBOUND_OLD"
        echo "  NewConnectionEx -> NewConnection: $INBOUND_OLD"
    else
        echo "  уже адаптирован (или сигнатура не найдена), пропускаю: $INBOUND_OLD"
    fi
fi

echo
echo "Готово. Проверь:"
echo "  git -C $DST status"
echo "  git -C $DST diff -- option/snell.go protocol/snell/inbound.go protocol/snell/outbound.go"
echo
echo "Сборка со старым snell:"
echo "  go build -tags \"...обычные теги... with_old_snell\" -o sing-box ./cmd/sing-box"
echo
echo "Не забудь: 'go mod tidy' запускать ТОЛЬКО без тега with_old_snell,"
echo "иначе он решит, что github.com/sagernet/sing-snell больше не нужен, и уберёт из go.mod."
