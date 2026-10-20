# Личный форк sing-box-extended

Этот репозиторий является форком [shtorm-7/sing-box-extended](https://github.com/shtorm-7/sing-box-extended) и содержит локальные модификации для личного использования.

## Что добавлено в этой ветке (актуальное состояние после слияния с автором, который оперативно реализует issue)

1. **UTLS (`vendor-utls`)**:
   - Добавлен метод `FreeBuffers()` в `vendor-utls/conn.go` для освобождения памяти после закрытия соединения.
   - Использование этого метода в `common/tls/reality_server.go` при закрытии `realityConnWrapper`.

2. **URLTest**:
   - Добавлена поддержка `penalties` в `URLTestOutboundOptions` (`option/group.go`) и логика учета штрафов в `protocol/group/urltest.go`.

6. **Docker**:
   - `Dockerfile`: намертdо зашит вызов команды sing-box run -c /etc/sing-box/config.json для предотвращения ошибки в конфиге vyos, не мешает в случае запуска с аргументами.
   - Изменен `release/DEFAULT_BUILD_TAGS_DOCKER` под нужды личной сборки.

## Инструменты

В папке `tools/` находятся скрипты для развертывания и обновления:
- `extract_sbe.sh` — полная переустановка с нуля (клонирование, применение патча).
- `update_sbe.sh` — обновление через git (слияние с upstream).
- `make_sbe_patch.sh` — создание кумулятивного патча.
