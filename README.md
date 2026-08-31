# Course Telegram bot

Воронка запуска курса в Telegram: гайд → прогрев → онлайн-оплата → одноразовый invite в канал этого запуска.

## Документы

- [`docs/TZ.md`](docs/TZ.md) — ТЗ, согласованное с заказчиком
- [`docs/LEKALA.md`](docs/LEKALA.md) — лекала сборки
- [`docs/OPEN_TASKS.md`](docs/OPEN_TASKS.md) — что осталось сделать тебе и заказчику (VPS, таблица, касса, тексты)
- [`docs/DEPLOY.md`](docs/DEPLOY.md) — заказ VPS в SmartApe, `.env`, Docker, HTTPS для кассы
- [`docs/YOOKASSA.md`](docs/YOOKASSA.md) — кабинет ЮKassa, `.env`, деплой callback, тест и бой
- [`docs/PAY_HTTPS.md`](docs/PAY_HTTPS.md) — домен, DNS (A-запись), Caddy для webhook кассы
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
# BOT_TOKEN, ADMIN_USER_IDS, COURSE_CHANNEL_ID
# compose сам ставит PAYMENT_WEBHOOK_BIND=0.0.0.0:8080
# порт на хосте только 127.0.0.1:8080
docker compose up -d --build
```

SQLite живёт в `./data`. Бэкап — периодический `VACUUM INTO` в `data/backups/` и копия файла `data/course.sqlite` (и `-wal`/`-shm`, если есть).

Прод: SmartApe, `/opt/course-chatbot`. Подробнее: [`docs/DEPLOY.md`](docs/DEPLOY.md) → раздел 10.

- Обычный апдейт на сервере: `bash scripts/update_and_logs.sh` (`git pull` + сборка с кэшем Docker).
- Полный деплой (новые пакеты, Dockerfile, `.env`, воронка Sheets): с Mac после commit + push — `./scripts/full_deploy.sh`. На VPS — `bash scripts/full_deploy.sh` (сборка **без кэша**, recreate контейнера).

## Касса

Живой путь: `PAYMENT_PROVIDER=yookassa` + ключи магазина + HTTPS callback. Пошагово: [`docs/YOOKASSA.md`](docs/YOOKASSA.md).

`PAYMENT_PROVIDER=yookassa | manual`.

- ЮKassa — единственная живая касса. Нужны `YOOKASSA_SHOP_ID`, `YOOKASSA_SECRET_KEY` и `PAYMENT_WEBHOOK_SECRET`. Callback: `POST /payments/callback` (секрет в query `?secret=`, заголовке `X-Webhook-Secret` или в path). Бот дополнительно перечитывает платёж из API ЮKassa (`GET /v3/payments/{id}`).
- Если ключи пустые при `PAYMENT_PROVIDER=yookassa`, фабрика падает в `manual`: ссылку не отдаёт, админ отмечает оплату в карточке.
- `PAYMENT_PROVIDER=manual` — жить без кассы (перевод мимо кассы, отладка).
- `GET /health` — liveness для Docker.
- Sidecar HTTP не заменяет long polling Telegram.
- Не публикуй 8080 в интернет. Compose слушает только `127.0.0.1` на хосте; снаружи нужен reverse proxy (Caddy, см. [`docs/DEPLOY.md`](docs/DEPLOY.md) §9).

Повторы `succeeded` идемпотентны: второй callback не создаёт второй invite и не затирает уже оплаченный заказ. Если invite не выдался, повтор webhook чинит ссылку. Предоплата канал не открывает. Новую ссылку в канал выдаёт только админ из карточки человека; ученик сам её не запрашивает.

## Google Sheets

Сервис-аккаунт JSON в `secrets/` (не в git). Таблице выдать доступ редактора на `client_email` из JSON.

- Вкладка **`COURSES`** (`gid=0`) — каталог запуска (цена, предоплата, даты). Править можно в боте («Управление курсами») или руками: шапка как у воронки, русские колонки, примечания к заголовкам, колонка «статус», одна активная строка. Бот пишет и удаляет строки, вкладку не пересобирает и `gid=0` не удаляет. Если лист пустой, бот один раз запишет текущие значения (18 000 ₽ / 5 000 ₽, доплата 05.10.2026, старт 12.10.2026).
- Вкладка **`ССЫЛКИ`** — диплинки в бота (`t.me/<bot>?start=<метка>`). Руками правят подписи и добавляют метки; колонку «Ссылка» заполняет бот. Колонка «Поток» — выпадающий список названий запусков с `COURSES` (пусто = текущий). Лист не пересобирается. Кнопка админа «Диплинки» отдаёт те же ссылки в личку.
- Вкладка **`ВОРОНКА`** — срез воронки. Бот пересобирает её сам; руками не править. Старый лист `FUNNEL` при обновлении удаляется.

Старт бота и кнопка админа «Обновить Google Sheets» перечитывают `COURSES` в SQLite, обновляют ссылки на `ССЫЛКИ`, затем пересобирают `ВОРОНКА`. Пошагово: [`docs/DEPLOY.md`](docs/DEPLOY.md) → раздел Google Sheets.

## Проверки

```bash
dart format bin lib test
dart analyze --fatal-infos --fatal-warnings
dart test
```

Стартовые метки: `ig_reels_guide`, `threads_guide`, `tg_announce`, `direct_course` — `https://t.me/<bot>?start=<метка>`.
