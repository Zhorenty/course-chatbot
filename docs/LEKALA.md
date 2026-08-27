# Лекала DVOR → бот запуска курса

Внутренний документ для разработки. Клиентское ТЗ (согласовано 26.08.2026): [`TZ.md`](TZ.md).

Это **не** форк клуба. Новый репозиторий, тот же каркас. Расписание, бонусы, антиспам, outdoor и PRO из DVOR не переносим.

---

## 0. Зафиксировано с заказчиком (не переоткрывать)

| Тема | Решение |
| --- | --- |
| Касса | Сначала **LeadPay** по её доступам. Спайк 1–2 дня. Если нет персональной ссылки + автостатуса в боте → **ЮKassa**, цена MVP та же |
| Рассрочка | Только на стороне кассы. Бот график не ведёт. Invite **после фактического списания**, не после «заявка одобрена» |
| Доступ в канал | Полная оплата → сразу. Предоплата → **нет**, пока не доплатят до полной суммы. Рассрочка → после списания |
| Лимит мест | **Нет.** Предоплата — разбивка платежа, не бронь слота. `BEGIN IMMEDIATE` на capacity из DVOR не копировать |
| Регистрация на гайд | Только Telegram user id. Имя / почта / телефон **не** собираем |
| Прогрев | **Сразу** после выдачи гайда — первое сообщение. Дальнейшая цепочка — тексты заказчика, пока каркас + первое касание |
| Отписка | Кнопка «Не писать» в прогреве. Меню / гайд / запись остаются. Напоминания про незакрытый платёж **не** глушить |
| Тихие часы | Исходящие джобы: **10:00–21:00 Europe/Moscow** (`TIMEZONE_OFFSET_HOURS=3`) |
| Канал | **Отдельный на каждый запуск.** Прошлый поток ≠ доступ к новому. `product_id` / `launch_id` + свой `COURSE_CHANNEL_ID` |
| Возврат | Вручную: пишут админу, админ снимает статус / invite. Бот не ходит в кассу за refund |
| Второй продукт | После первого запуска, ориентир **ноябрь**. В схеме сразу `product_id` |
| Copy | Все тексты и цепочки готовит заказчик. Не брать `docs/VOICE.md` клуба. UX: факт → статус → один шаг |
| Аналитика | Срез воронки в Google Sheets **в MVP**, как лист `FUNNEL` у DVOR (см. [`funnel-example.png`](funnel-example.png)) |
| Чьё после сдачи | Токен, канал, таблица, SQLite, VPS — заказчица. Касса — её кабинет |
| Оплата работ | Два транша 40 + 40 тыс., пауза неделя. На разработку не влияет, кроме «спайк после доступов LeadPay» |

Telegram Payments (`sendInvoice`) **не** берём: рассрочка кассы туда не влезает.

---

## 1. Что такое DVOR-бот одним абзацем

Dart CLI-приложение: long polling Telegram Bot API, SQLite как источник правды, фоновые джобы, админка в личке. Пользователь записывается на событие → получает реквизиты/ссылку → присылает чек → админ подтверждает. Параллельно онбординг с drip и атрибуцией (`/start book`, `/start start`, `/start ref_123`). Срез воронки бот пишет в Google Sheets (`FUNNEL`).

Оплата в DVOR **не** эквайринг. У курса — онлайн-касса с автостатусом; ручной override как **fallback**, не как основной путь.

---

## 2. Стек и инварианты, которые переносим как есть

| Слой | Как в DVOR | Зачем в боте курса |
| --- | --- | --- |
| Язык | Dart SDK ≥ 3.5 | Один стек, те же линтеры |
| Транспорт | Long polling, `getUpdates` | Telegram как сейчас. HTTPS нужен, если касса шлёт webhook (ЮKassa; LeadPay — по итогам спайка) |
| Хранение | SQLite + WAL + транзакции | Один файл, бэкап копированием. Capacity-check на места **не** нужен |
| Конфиг | CLI → env → `.env` → defaults | Секреты не в коде |
| Деплой | Docker Compose, volume `./data`, secrets read-only | Тот же Timeweb-контур |
| Sheets | `googleapis` + service account | Срез `FUNNEL` в MVP |
| Качество | `dart format`, `analyze --fatal-infos --fatal-warnings`, `dart test` | Перед сдачей |

Зависимости-ориентир: `http`, `sqlite3`, `args`, `intl`, `l`, `googleapis` / `googleapis_auth`. Касса — отдельный клиент за интерфейсом `PaymentGateway`, чтобы сменить LeadPay → ЮKassa без перепила хендлеров.

---

## 3. Слои. Копировать границы, не копировать домен

1. `telegram_client` — сырые запросы Telegram, retry, ошибки. Без бизнеса.
2. `handlers` / `application` — оркестрация.
3. `message_templates` — тексты, HTML, клавиатуры. Хендлер не клеит пользовательские строки.
4. `domain` — статусы. `data` — SQLite за репозиторием.

Пакетные импорты. DI через конструкторы. Без experimental API.

### Карта файлов DVOR → заготовки курса

| DVOR | Роль | В боте курса |
| --- | --- | --- |
| `bin/dvor_bot.dart` | Сборка графа | `bin/course_bot.dart` |
| `lib/src/config/app_config.dart` | CLI/env | Минус schedule/antispam; плюс касса, канал запуска, drip, тихие часы, Sheets |
| `lib/src/telegram/telegram_client.dart` | Bot API | + `sendDocument`, `createChatInviteLink`, `revokeChatInviteLink` |
| `lib/src/telegram/message_sender.dart` | Интерфейс отправки | Расширить контракт |
| `lib/src/telegram/retry.dart`, `telegram_api_exception.dart` | Надёжность | Как есть |
| `lib/src/telegram/logging_message_sender.dart` | Лог исходящих | Полезно для карточки «диалог» |
| `lib/src/bot/bot_runner.dart` | Polling + джобы + shutdown | Как есть |
| `lib/src/jobs/job_scheduler.dart` | In-flight guard | Как есть |
| `lib/src/data/job_dedupe_repository.dart` | Не слать дважды после рестарта | Drip, брошенная оплата, доплата |
| `lib/src/data/sqlite/sqlite_database_handle.dart` | Один WAL-коннект | Как есть |
| `lib/src/bot/handlers/private_handlers.dart` | Facade + `part` | Тот же приём |
| `lib/src/bot/handlers/private/private_context.dart` | `message` / `callback_query` | Как есть |
| `lib/src/bot/handlers/private/private_flow_store.dart` | In-memory шаг | Нужен; **статусы воронки и оплаты только в SQLite** |
| `lib/src/bot/handlers/private/admin_gate.dart` | `ADMIN_USER_IDS` | Как есть |
| `lib/src/messages/html_escaper.dart` | Escape | Как есть |
| `lib/src/messages/message_templates.dart` | Copy и клавиатуры | Каркас; тексты подставляет заказчик |
| `lib/src/data/google_sheets_funnel_dashboard.dart` | Вёрстка листа `FUNNEL` | Клон раскладки, другие KPI/шаги (гайд → прогрев → оплата) |
| `lib/src/jobs/google_sheets_funnel_export_job.dart` | Периодический wipe+write | Как есть |
| `test/support/fakes.dart`, harness | Фейковый sender | Перенести |

`group_handlers` и антиспам не нужны. Закрытый канал — invite, не welcome в открытую группу.

---

## 4. Runtime

`BotRunner.start()`: `deleteWebhook` → таймеры джобов → `getUpdates` в `runTracked` → SIGINT/SIGTERM → idle → закрыть SQLite/HTTP.

Long polling остаётся. Если шлюз (ЮKassa или LeadPay) отдаёт HTTP-уведомления — **sidecar HTTPS** рядом. Это единственная новая инфра относительно DVOR.

`allowed_updates`:

- `message` — `/start`, админка;
- `callback_query` — кнопки;
- `chat_member` / `my_chat_member` — вход в канал запуска, блок бота;
- без `pre_checkout_query` / `successful_payment`.

Джобы исходящих сообщений проверяют тихие часы: вне 10:00–21:00 МСК — не слать, подождать следующего тика.

---

## 5. Домен: таблица соответствий

Не тащить `TrainingBooking` и расписание. Сущности курса, статусы и джобы — по правилам DVOR.

| DVOR | Курс (MVP) | Комментарий |
| --- | --- | --- |
| `telegram_users` | Профиль: tg id, username, источник, `warmup_opt_out` | Источник **один раз** при первом `/start` с payload |
| start payload `book` / `start` / `ref_ID` | `ig_reels_guide`, `threads_guide`, `tg_announce`, `direct_course` | 64 символа, `[A-Za-z0-9_]` |
| `OnboardingPhase` / step | lead → magnet_issued → warming → checkout → deposit / paid → access | Один шаг на сообщение |
| `OnboardingNudgeJob` | Прогрев: **шаг 0 сразу после гайда** (из хендлера), остальные — джоб по цепочке заказчика | Ключи шагов — строки в БД |
| `pendingPayment` | Нажал «Оплатить», платежа нет | Касание через N часов и через сутки |
| `paymentSubmitted` | Платёж создан в кассе / ждём callback | Короткий, если автокасса живая |
| `partialPaid` | Предоплата, есть `amount_due` + `due_at` | Доплата **в боте**. Канала нет, пока не `paid` |
| `paid` | Полная сумма **или** списание по рассрочке | Снять с продающего drip; выдать invite канала **этого** `launch_id` |
| `cancelled` | Админ отменил / возврат | Revoke invite если выдавали |
| `PaymentReminderJob` | Брошенный чекаут + напоминание доплаты | **Без** автоотмены брони: лимита мест нет |
| `job_dedupe_log` | Идемпотентность | `warmup:{userId}:{step}`, `abandon:{orderId}:h6` |
| `createChatInviteLink` | Одноразовая ссылка | `member_limit: 1`, канал = канал запуска |
| Google Sheets `FUNNEL` | Срез в MVP | SQLite — правда, лист — витрина. Руками не правят |
| Очередь чеков | Ручной override | Всегда: вне кассы, сбой, возврат |

CTA «Записаться» — пока нет `access_granted` (не только «пока не paid»: после списания рассрочки доступ уже выдан).

---

## 6. Паттерны, которые обязательно повторить

### 6.1. Deep link на `/start`

Парсер DVOR: второй токен, lowercase. Источник пишем, только если ещё пустой.

Справочник:

- `ig_reels_guide` / `threads_guide` → гайд;
- `tg_announce` / `direct_course` → карточка курса;
- запас: `ig_stories_guide`, `email_guide`.

`https://t.me/<bot>?start=<payload>`.

### 6.2. Воронка и drip

`OnboardingService` решает следующий nudge; джоб шлёт и пишет лог. Таймеры не в хендлере — **кроме** первого сообщения сразу после `sendDocument` (это синхронно в выдаче гайда).

1. `/start` + метка → источник → гайд или курс.
2. Регистрация = Telegram. Без контакта и email.
3. PDF по `file_id` (админ заливает как onboarding-видео в DVOR) или URL.
4. Сразу текст шага 0 прогрева + кнопки «Записаться» / «Не писать».
5. `magnet_issued` не завершает воронку.
6. Дальше джоб по таблице шагов. Исключить: `warmup_opt_out`, `paid` / `access_granted`. У `deposit_paid` продающий прогрев **выкл**, напоминания доплаты **вкл**.

Ключи шагов — строки, не вечный enum: заказчица ещё пришлёт цепочку.

### 6.3. Статусы

Только SQLite. Рестарт не должен терять оплату. Лимит мест не проверять.

### 6.4. Кнопки

Оплата / гайд / отписка — **inline**, `callback_data` ≤ 64 байт, префикс + id. Reply — меню.

### 6.5. Админка

Поиск, карточка (источник, статус, платежи, канал запуска, opt-out), ручной статус, отмена/возврат, рассылка сегменту. Цифры воронки **не** дублировать большим экраном в боте — Sheets.

### 6.6. Джобы

Try/catch на каждого, батч 50–100, mark sent после успеха, dedupe, тихие часы. Если пользователь заблокировал бота — прекратить drip, в карточке видно.

### 6.7. Тесты

Хендлер + шаблон + тест. Фейковый `PaymentGateway`. Без живой кассы в unit.

### 6.8. Срез Sheets

Копировать `GoogleSheetsFunnelDashboard`: шапка, KPI-карточки, путь по шагам (% от старта / от предыдущего), 7д/30д, «где сейчас» + «источник». Убрать квиз DVOR. KPI курса: Start, в воронке, взяли гайд, начали оплату, купили / списание, конверсия. Wipe+create листа, входные вкладки не трогать (у курса входных расписаний нет — один bot-owned лист плюс при необходимости «ДЕЙСТВИЯ»).

---

## 7. Что из DVOR не копировать

- Расписание, CRUD слотов, retention строк, штаб, промокоды.
- Welcome в группу, антиспам, анонсы, рефералка, «дворяне».
- Бонусы, PRO.
- Outdoor: предоплата без доплаты в боте.
- Хардкод СБП-ссылки.
- `VOICE.md` клуба.
- Проверку лимита мест и TTL автоотмены unpaid booking.
- Telegram Payments.

---

## 8. Оплата: шлюз за интерфейсом

Хендлеры знают только `PaymentGateway`: создать платёж (full / deposit / remainder / installment) → URL; применить webhook/callback идемпотентно.

Ручной override как в `PaymentReviewService` — всегда.

### 8.1. LeadPay (первый заход)

Официальные стыки — конструкторы. Для Dart — спайк по кабинету:

- POST за уникальной ссылкой (в доке BotHelp светится `/rest/v3/.../link`) — неконтрактный;
- success URL / уведомление, которое можно повесить на наш HTTPS;
- иначе: ссылка + админ (это уже не цель MVP).

Критерий спайка: персональная ссылка **и** бот сам ставит `paid` / списание без скрина. Нет → ЮKassa.

### 8.2. ЮKassa (fallback)

1. Создать платёж: `amount`, `metadata.user_id`, `order_id`, `kind`.
2. URL-кнопка на `confirmation_url`.
3. Sidecar: `payment.succeeded` / `canceled`.
4. Статусы + exclude drip; если полная сумма или списание рассрочки → invite.

Повторы webhook не плодят второй invite.

Рассрочка: смотреть событие **списания**, не «заявка». Если касса шлёт только «одобрено» — не выдавать канал, пока нет charge.

Telegram-счёт ЮKassa не используем.

### 8.3. Доплата

В DVOR `partial_paid` есть, кнопки доплаты нет. Здесь:

- `price_full`, `amount_paid`, `amount_due`, `due_at`;
- джоб к дате (тихие часы);
- второй платёж `kind=remainder`;
- успех → `paid` → invite.

Не второе «бронирование тренировки». Без освобождения слота.

---

## 9. Доступ в канал запуска

После `paid` **или** списания рассрочки (не после депозита):

1. `createChatInviteLink` на канал **этого** `launch_id`: `member_limit: 1`.
2. В личку. Без вечной общей ссылки.
3. `chat_member` → `joined_at`; можно `revoke`.
4. Перевыдача: новая ссылка, старую отозвать.

Бот — админ с правом приглашать. Не копировать `GroupInviteNudgeJob`.

Ноябрьский продукт = новый `launch_id` + новый канал, старые invite не пускают.

Возврат: админ → статус cancelled → revoke, если ссылка/вход были.

---

## 10. Порядок сборки репо

1. Скелет: bin, config, client, runner, SQLite, Docker, `/start` жив. Параллельно спайк LeadPay (нужны её доступы).
2. Домен: `User`, `AcquisitionSource`, `Product`/`Launch`, `FunnelState`, `Order`, `Payment`. Тесты переходов, в т.ч. депозит без invite.
3. Шаблоны-заглушки + кнопка «Не писать». Тексты заказчика вставляем пачками.
4. `/start` + метки + гайд + **сразу** шаг 0 прогрева.
5. Drip-движок (остальные шаги), opt-out, тихие часы, exclude оплативших.
6. Запись: full / deposit / installment (URL кассы).
7. Шлюз после спайка + брошенная оплата + remainder.
8. Invite в канал запуска.
9. Админка + экспорт Sheets как `FUNNEL`.
10. Деплой, бэкап, runbook. Доступы отдать заказчице.

`product_id` + `launch_id` + `channel_id` в схеме с дня один. В MVP одна строка продукта.

---

## 11. Конфиг сверх DVOR

```env
BOT_TOKEN=
ADMIN_USER_IDS=
ADMIN_CHAT_ID=
BOOKINGS_DB_PATH=data/course.sqlite
TIMEZONE_OFFSET_HOURS=3
QUIET_HOURS_FROM=10
QUIET_HOURS_TO=21
POLL_TIMEOUT_SECONDS=25
LOG_LEVEL=info

COURSE_CHANNEL_ID=
LEAD_MAGNET_FILE_ID=
LEAD_MAGNET_PATH=assets/guide.pdf
WARMUP_ENABLED=true

PAYMENT_PROVIDER=leadpay   # leadpay | yookassa | manual
LEADPAY_TOKEN=
YOOKASSA_SHOP_ID=
YOOKASSA_SECRET_KEY=
PAYMENT_WEBHOOK_BIND=127.0.0.1:8080
PAYMENT_WEBHOOK_PATH=/payments/callback
PAYMENT_WEBHOOK_SECRET=

GOOGLE_SHEETS_WRITE_ENABLED=true
GOOGLE_SHEETS_CREDENTIALS_PATH=
GOOGLE_SHEETS_SPREADSHEET_ID=
```

Секреты кассы и JSON сервис-аккаунта — не в git. После сдачи — её сервер и её `.env`. Webhook кассы — только с секретом; порт на хосте не торчать в интернет.

---

## 12. Риски

| Тема | Относительно DVOR |
| --- | --- |
| Deep link + гайд + шаг 0 сразу | Низкая |
| Drip + opt-out + тихие часы | Низкая: клон nudge job |
| Брошенная оплата | Низкая: reminder без expiry слота |
| Предоплата + remainder + канал только после full | Средняя: в DVOR остаток офлайн |
| Invite на канал запуска | Средняя |
| LeadPay как касса Dart-бота | Высокая, пока нет спайка — **делать первым** |
| ЮKassa webhook | Высокая, но известная; включать только если LeadPay провалился |
| Списание vs «одобрено» у рассрочки | Средняя: завязано на события кассы |
| Sheets FUNNEL под курс | Низкая/средняя: клон дашборда, другие метрики |
| Второй продукт в ноябре | Только схема сейчас, не UI витрины |
| Email/телефон | **Не делаем** |

Идемпотентность callback кассы обязательна.

---

## 13. Чеклист каркаса

- Слои не смешаны; Telegram-клиент не знает заказ.
- Статус переживает рестарт.
- Повторный `/start` не ломает оплатившего и не перетирает источник.
- После гайда уходит первое сообщение без ожидания джоба.
- Opt-out глушит только прогрев.
- Джобы молчат ночью и не дабблят после рестарта.
- Депозит не выдаёт invite; full и списание рассрочки — выдают.
- Канал только этого запуска.
- Админ может проставить оплату, отменить, отозвать доступ.
- Лист воронки в Sheets обновляется ботом.
- `PaymentGateway` можно сменить без перепила хендлеров.
- `dart format`, `analyze --fatal-infos --fatal-warnings`, `dart test` зелёные.
