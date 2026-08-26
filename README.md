# Course Telegram bot

Воронка запуска курса в Telegram.

## Документы

- [`docs/TZ.md`](docs/TZ.md) — ТЗ, согласованное с заказчиком
- [`docs/LEKALA.md`](docs/LEKALA.md) — лекала: что копировать из DVOR и в каком порядке собирать
- [`docs/funnel-example.png`](docs/funnel-example.png) — пример среза воронки в Google Sheets

Порядок работ — раздел 10 в `docs/LEKALA.md`. Сейчас закрыт шаг 1: процесс живой, `/start` отвечает, SQLite и job dedupe на месте.

## Запуск

```bash
cp .env.example .env
# прописать BOT_TOKEN
dart pub get
make bot
```

Проверки:

```bash
dart format bin lib test
dart analyze --fatal-infos --fatal-warnings
dart test
```
