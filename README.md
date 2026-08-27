# Course Telegram bot

Воронка запуска курса в Telegram: гайд → прогрев → онлайн-оплата → одноразовый invite в канал этого запуска.

## Документы

- [`docs/TZ.md`](docs/TZ.md) — ТЗ, согласованное с заказчиком
- [`docs/LEKALA.md`](docs/LEKALA.md) — лекала сборки
- [`docs/OPEN_TASKS.md`](docs/OPEN_TASKS.md) — что осталось сделать тебе и заказчику (VPS, таблица, касса, тексты)
- [`docs/funnel-example.png`](docs/funnel-example.png) — пример среза воронки в Google Sheets

## Запуск локально

```bash
cp .env.example .env
# BOT_TOKEN, ADMIN_USER_IDS
dart pub get
make bot
```

Админ может прислать PDF гайда в личку бота — сохранится `file_id`. В репозитории уже лежит `assets/guide.pdf` («Гайд Язык цвета»); бот отдаёт его сам, `LEAD_MAGNET_FILE_ID` не обязателен.

## Docker

```bash
cp .env.example .env
# BOT_TOKEN, ADMIN_USER_IDS
# для контейнера compose сам ставит PAYMENT_WEBHOOK_BIND=0.0.0.0:8080
# порт на хосте только 127.0.0.1:8080
docker compose up -d --build
```

SQLite живёт в `./data`. Бэкап — периодический `VACUUM INTO` в `data/backups/` и копия файла `data/course.sqlite` (и `-wal`/`-shm`, если есть).

## Касса

`PAYMENT_PROVIDER=leadpay | yookassa | manual`.

- LeadPay — первый заход. Нужен токен «для внешних систем» и `PAYMENT_WEBHOOK_SECRET`. Пока токена нет, бот работает как `manual` (ссылку не отдаёт, админ отмечает оплату).
- ЮKassa — запасной шлюз. Callback: `POST /payments/callback` (секрет в query `?secret=`, заголовке `X-Webhook-Secret` или в path). Бот дополнительно перечитывает платёж из API ЮKassa.
- `GET /health` — liveness для Docker.
- Sidecar HTTP не заменяет long polling Telegram.
- Не публикуй 8080 в интернет. Compose слушает только `127.0.0.1` на хосте; снаружи нужен reverse proxy.

Повторы `succeeded` идемпотентны: второй callback не создаёт второй invite и не затирает уже оплаченный заказ. Если invite не выдался, повтор webhook чинит ссылку. Предоплата канал не открывает.

## Google Sheets

Сервис-аккаунт JSON в `secrets/` (не в git). Таблице выдать доступ редактора. Бот пересобирает вкладку `FUNNEL`.

## Проверки

```bash
dart format bin lib test
dart analyze --fatal-infos --fatal-warnings
dart test
```

Стартовые метки: `ig_reels_guide`, `threads_guide`, `tg_announce`, `direct_course` — `https://t.me/<bot>?start=<метка>`.
