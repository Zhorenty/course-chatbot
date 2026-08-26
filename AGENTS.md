# AGENTS.md

Project guidance for AI/code agents in this repository.

This is **not** a fork of the DVOR club bot. Same engineering habits (layers, DI, SQLite, long polling, jobs, tests). Different product: a course-launch funnel in Telegram. Do not port schedule, bonuses, group antispam, outdoor, or PRO.

Customer spec: [`docs/TZ.md`](docs/TZ.md) (agreed 26.08.2026). Implementation playbook: [`docs/LEKALA.md`](docs/LEKALA.md). Read both before non-trivial work. Locked product decisions live in LEKALA §0 — do not reopen them in code or in chat with the customer unless the user explicitly changes the spec.

## Project Overview

- Project: `course_chatbot`
- Stack: Dart CLI, Telegram Bot API (long polling), SQLite, Docker Compose
- MVP: one launch, one lead magnet, online checkout, one-time invite to **that launch’s** closed channel
- Second product: after the first live launch (target November). Put `product_id` / `launch_id` in the schema from day one; do not build a multi-product storefront in MVP

## Source of Truth (Key Files)

- Entry point: `bin/course_bot.dart` (shared SQLite handle)
- Runtime: `lib/src/bot/bot_runner.dart` + `lib/src/jobs/job_scheduler.dart`
- Config: `lib/src/config/app_config.dart`
- Telegram transport: `lib/src/telegram/telegram_client.dart`
- Private handlers: `lib/src/bot/handlers/private_handlers.dart` (facade + DI, keep the facade ≪200 LOC; split domains into `part` files as in DVOR)
- SQLite: `lib/src/data/sqlite/sqlite_database_handle.dart`
- Job idempotency: `lib/src/data/job_dedupe_repository.dart` (`job_dedupe_log`)
- HTML escaping: `lib/src/messages/html_escaper.dart`
- Spec / playbook: `docs/TZ.md`, `docs/LEKALA.md`

When these exist, they are also source of truth:

- `lib/src/messages/message_templates.dart` (+ `templates/*.part.dart`) — all user-facing copy and keyboards
- `lib/src/application/` — orchestration (funnel, payments, access)
- Payment: interface `PaymentGateway`; LeadPay first, YooKassa if the spike fails; never Telegram Payments (`sendInvoice`)
- Sheets: bot-owned `FUNNEL` slice (SQLite is truth; the sheet is a dashboard, not hand-edited)

## Architecture and Coding Rules

Keep layers clean:

1. `telegram_client` — raw Telegram HTTP: request, retry, decode, `TelegramApiException`. No orders, no funnel, no copy.
2. `handlers` / `application` — behavior and orchestration.
3. `message_templates` — text, HTML, keyboards. Handlers must not concatenate user-facing strings (except escaping via `escapeHtml`).
4. `domain` — statuses and entities. `data` — SQLite behind repository interfaces.

Also:

- Preserve constructor DI. Do not use service locators or globals for repos/clients.
- Package imports only (`package:course_chatbot/...`). No relative `lib` imports (`analysis_options.yaml`).
- Prefer single quotes, `unawaited_futures`, `directives_ordering`.
- No experimental Dart APIs without a strong reason.
- Prefer `final class` for services/repos; explicit types; no `dynamic` in domain.
- `callback_data` ≤ 64 bytes: short prefixes + ids, not JSON.
- Inline keyboards for actions bound to an order/user (pay, continue, opt-out). Reply keyboards for navigation only.
- In-memory `PrivateFlowState` is for the current dialogue step only. Funnel phase, payment, opt-out, and access **must** live in SQLite so they survive process restart.
- Do not check training-style seat capacity. There is **no** place limit. Do not copy DVOR `BEGIN IMMEDIATE` capacity checks or unpaid-booking auto-cancel TTL.
- One SQLite connection (WAL, foreign keys, busy timeout) shared by handlers and jobs.
- Status changes that grant access or record money run in a transaction. Payment webhooks must be idempotent: a repeated `succeeded` must not create a second invite.
- Swap payment providers behind `PaymentGateway`. Handlers never call LeadPay/YooKassa HTTP directly.
- Google Sheets export wipes and recreates bot-owned tabs. Do not treat the dashboard as a writable CRM of individual people; the person card is in admin DM.

## How to Approach Work

Follow DVOR’s change order for non-trivial features:

1. Domain / contracts first (statuses, repositories, `PaymentGateway`).
2. Templates / messages (placeholders if customer copy is not in yet).
3. Handlers / services / jobs.
4. Tests.
5. `dart format`, `analyze --fatal-infos --fatal-warnings`, `dart test`.
6. Docs if behavior or env vars changed (`README.md`, `.env.example`, `docs/TZ.md` / `docs/LEKALA.md` if the spec moved).

Build in the order in LEKALA §10. Do not start the payment sidecar until the LeadPay spike has a verdict. Do not invent a second product UI before November work is asked for.

When copying from DVOR: copy **patterns** (facade + parts, nudge job, reminder job, FUNNEL layout, admin gate). Do not copy club domain names, Voice.md, hardcoded SBP links, or group welcome.

Any new user-facing command or button needs:

- handler (or dispatch branch)
- template
- test

## Product Invariants (do not “simplify away”)

| Topic | Rule |
| --- | --- |
| Checkout | Online kassa with auto-status. Manual admin override is fallback (out-of-band transfer, webhook failure, refund), not the main path |
| Provider | Spike **LeadPay** first (customer cabinet). If no unique payment URL **and** server-side paid signal → **YooKassa**. Same MVP scope |
| Installment | Exists only on the kassa page. Bot does not store a payment schedule. Channel invite after **actual charge**, not “application approved” |
| Channel access | Full payment → invite. Deposit → **no** invite until remainder is paid. Installment → after charge |
| Channel identity | One closed channel **per launch**. Old-stream members do not get this launch’s invite |
| Lead magnet | Telegram user id only. Do not collect name / email / phone |
| Warmup | First message **immediately** after the guide is delivered (in the handler). Later steps: job + customer copy. Keys are strings in DB, not a frozen enum |
| Opt-out | “Не писать” stops **selling** drip only. Menu, guide, enroll remain. Abandoned-payment and remainder reminders still send |
| Quiet hours | Outbound jobs: 10:00–21:00 Europe/Moscow unless config says otherwise. If outside the window, skip and wait for the next tick |
| Refunds | Human writes to admin; admin sets cancelled and revokes invite. Bot does not call kassa refund APIs |
| Attribution | Deep-link payload on first `/start` wins. Do not overwrite source on later `/start` |
| CTA | “Записаться на курс” until access is granted |
| Analytics | Funnel slice in Google Sheets in MVP (Start, in funnel, guide, checkout started, paid, sources) |

## Voice and Copy

Customer writes all marketing/warmup copy and sequences. Do not import DVOR `docs/VOICE.md`. Do not invent a sales tone.

Until copy arrives, keep **stubs**: fact → status → one next step. Short. Address the person as «ты» in DM.

- Escape every user- or payload-derived string before HTML (`escapeHtml`).
- HTML parse mode: `<b>` on a headline or key fact only, not whole paragraphs.
- Do not invent prices, dates, or channel URLs. Do not publish a permanent invite link.
- One CTA per message when the message is about an action.
- Admin-facing text can be denser; still no walls of unexplained jargon in user DM.

## Telegram Behavior Contract

- Long polling. Call `deleteWebhook` before `getUpdates`.
- `allowed_updates`: `message`, `callback_query`, `chat_member` (and `my_chat_member` when tracking blocks). Do **not** add `pre_checkout_query` / `successful_payment`.
- Private chat is the product. There is no DVOR-style open-group welcome/antispam.
- Bot must be channel admin with invite permission before issuing `createChatInviteLink` (`member_limit: 1`). Revoke on re-issue and on admin cancel.
- If the user has blocked the bot, stop drip; record it on the person card. Do not treat send failures as fatal for the whole job batch (try/catch per recipient, batch 50–100).
- Prefer HTML + escaping for bot UX. Do not send unescaped `<` from usernames or payloads.

## Config and Secrets

Never hardcode tokens or commit real credentials (`.env`, `secrets/*.json`, kassa keys).

Precedence (highest to lowest):

1. CLI args
2. Environment variables
3. `.env`
4. defaults

Core env (see `.env.example`): `BOT_TOKEN`, `ADMIN_USER_IDS` / `ADMIN_CHAT_ID`, `BOOKINGS_DB_PATH`, `POLL_TIMEOUT_SECONDS`, `TIMEZONE_OFFSET_HOURS`, `QUIET_HOURS_FROM` / `QUIET_HOURS_TO`, `COURSE_CHANNEL_ID`, `LEAD_MAGNET_FILE_ID`, `WARMUP_ENABLED`, `PAYMENT_PROVIDER`, LeadPay/YooKassa secrets, `PAYMENT_WEBHOOK_BIND`, `PAYMENT_WEBHOOK_SECRET`, `PAYMENT_WEBHOOK_PATH`, Google Sheets write flags, `SQLITE_BACKUP_*`, `LOG_LEVEL`.

After `.env` changes in Docker: recreate the container.

## Reliability Baseline

- Keep timeout/retry on Telegram HTTP; retry unless `TelegramApiException`.
- Handle API failures explicitly; log and continue per user in jobs.
- Keep graceful shutdown (`SIGINT`/`SIGTERM`), `JobScheduler.waitForIdle`, then close SQLite and HTTP clients.
- Jobs: in-flight guard by name (`JobScheduler.launch`). Drip, abandoned payment, and remainder reminders **claim** keys in `job_dedupe_log` so a restart does not double-send.
- Polling 409: retry with backoff, then exit non-zero so the process manager restarts a single instance.
- If a payment provider needs HTTPS callbacks, add a small sidecar; do not replace long polling with a Telegram webhook.
- SQLite file lives on a persistent volume (`./data`). Backup is copy of that file.

## Required Validation Before Handoff

```bash
dart format bin lib test
dart analyze --fatal-infos --fatal-warnings
dart test
```

All three must pass. Tests use fakes (`test/support/fakes.dart`); do not hit live Telegram or live kassa in unit tests.

## Documentation Update Rules

Update when behavior, config, or ops change:

- `README.md` — commands, config, how to run
- `.env.example` — new env vars
- `docs/TZ.md` — only if the customer-facing contract changed (and the user asked)
- `docs/LEKALA.md` — if implementation constraints or locked decisions changed
- this file — if architecture or agent rules changed

## Safe Change Flow

1. Domain/contracts first.
2. Templates/messages.
3. Handlers/services/jobs.
4. Tests.
5. Format, analyze, tests.
6. Docs if needed.

Do not drive-by refactor unrelated DVOR leftovers. Do not add GetCourse/Salebot. Do not add email capture “just in case.”
