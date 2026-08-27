# Деплой: SmartApe VPS → бот

Инструкция, чтобы со стороны сервера всё было готово: VPS, Docker, `.env`, контейнер, (по необходимости) HTTPS для кассы.

Telegram работает **long polling** — публичный домен для самого бота не нужен. HTTPS нужен только когда касса шлёт webhook (ЮKassa почти наверняка; LeadPay — после спайка).

Ориентир по ТЗ: **~350 ₽/мес**. Путь на сервере: `/opt/course-chatbot`. Репозиторий: `https://github.com/Zhorenty/course-chatbot.git`.

---

## 0. Что должно быть на руках до заказа


| Что                                                 | Зачем                                    |
| --------------------------------------------------- | ---------------------------------------- |
| Токен бота (`BOT_TOKEN`)                            | из @BotFather                            |
| Свой Telegram user id                               | `@userinfobot` → `ADMIN_USER_IDS`        |
| Числовой id канала (`-100…`)                        | бот уже админ канала с правом приглашать |
| (опционально) LeadPay / ЮKassa                      | без кассы бот живёт в `manual`           |
| (опционально) Google-таблица + JSON сервис-аккаунта | срез `ВОРОНКА`                          |


Без токена и admin id контейнер не стартует осмысленно. Касса, Sheets и домен можно добить вторым заходом.

---



## 1. Заказать VPS в SmartApe

1. Зарегистрируйся на [smartape.ru](https://www.smartape.ru), подтверди почту.
2. Пополни баланс (карта / СБП — что даст кабинет).
3. Закажи **VPS / SSD VPS**, не выделенный сервер и не «VPS с панелью хостинга».
4. В конфигураторе выставь:


| Параметр   | Значение                                                                          |
| ---------- | --------------------------------------------------------------------------------- |
| Ресурсы    | минимум **1 vCPU / 1 ГБ RAM / 20 ГБ SSD**; комфортнее **1–2 vCPU / 2 ГБ / 30 ГБ** |
| Дата-центр | **Москва** (ближе к Telegram и кассе)                                             |
| ОС         | **Ubuntu 24.04** (подойдёт и 26.04, если кабинет отдаёт только её)                |
| Панель     | **без панели** (не Hestia, не ISPmanager)                                         |
| SSH        | если есть поле — вставь свой публичный ключ (`cat ~/.ssh/id_ed25519.pub`)         |
| Hostname   | например `course-bot`                                                             |


1. Оплати. В письме / кабинете появятся **IP**, логин (обычно `root`) и пароль, если ключ не задали.
2. В панели SmartApe проверь, что сервер **Running**, и что есть **VNC/консоль** на случай, если SSH не пускает.

---



## 2. Первый вход по SSH

Заходи **по IP**, не по имени из письма. `*.smartape-vps.com` часто не резолвится в DNS (`nodename nor servname provided`).

С Mac:

```bash
ssh root@IP_СЕРВЕРА
```

Приглашение `password:` ничего не печатает — так и должно быть. Вставь пароль из кабинета и Enter.

Дальше система:

```bash
apt update && apt upgrade -y
timedatectl set-timezone Europe/Moscow
```

На своей машине удобно прописать хост:

```bash
# ~/.ssh/config
Host course-bot
  HostName IP_СЕРВЕРА
  User root
  IdentityFile ~/.ssh/id_ed25519
```

Потом: `ssh course-bot`.

### Если `Permission denied (publickey,password)`

Это не «сервер мёртв»: порт 22 отвечает, но **пароль root по SSH не принимают** (типично для свежей Ubuntu: `PermitRootLogin prohibit-password`) **или** пароль вставили криво.

1. Принудительно пароль, без ключа (ключ с Mac сервер всё равно не знает):

```bash
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@IP_СЕРВЕРА
```

Пароль копируй целиком, без пробела в конце. Раскладка латиница.

1. Если снова отказ — **веб-консоль / VNC в кабинете SmartApe** (не SSH). Логин `root` и тот же пароль там обычно работают.

В консоли посмотри политику SSH:

```bash
grep -RE 'PermitRootLogin|PasswordAuthentication' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
```

И сразу положи **свой ключ**, чтобы больше не зависеть от пароля. На Mac:

```bash
cat ~/.ssh/id_ed25519.pub
```

Если файла нет: `ssh-keygen -t ed25519 -C "course-bot"`.

В консоли сервера:

```bash
mkdir -p /root/.ssh
chmod 700 /root/.ssh
# вставь одну строку из id_ed25519.pub:
echo "ssh-ed25519 AAAA... твой_комментарий" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

С Mac проверь:

```bash
ssh -i ~/.ssh/id_ed25519 root@IP_СЕРВЕРА
```

1. Пароль из письма после этого **смени** в консоли (`passwd`) и в кабинете SmartApe, если светился в чате / почте.

Не коммить IP, пароль и `.env` в git.

---



## 3. Docker

Официальный скрипт (Ubuntu 24.04):

```bash
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
docker compose version
```

Проверка: `docker run --rm hello-world`.

---



## 4. Фаервол

Не открывай порт `8080` в интернет. Compose и так слушает только `127.0.0.1:8080`.

```bash
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
ufw status
```

Порты 80/443 понадобятся, когда появится HTTPS для кассы. Если кассы ещё нет — их можно не открывать.

---



## 5. Клонировать бота

```bash
mkdir -p /opt
cd /opt
git clone https://github.com/Zhorenty/course-chatbot.git course-chatbot
cd /opt/course-chatbot
git checkout main
mkdir -p data/backups secrets assets
```

Если репозиторий приватный — добавь deploy key (read-only) в GitHub или клонируй по SSH.

Запасной путь без git — с Mac:

```bash
rsync -avz --exclude '.git' --exclude 'data' --exclude '.env' \
  --exclude 'secrets/*.json' \
  ./ course-bot:/opt/course-chatbot/
```

---



## 6. `.env` на сервере

```bash
cd /opt/course-chatbot
cp .env.example .env
nano .env
```

Выход из nano: `Ctrl+O`, Enter (сохранить), `Ctrl+X` (выйти). Если не хочешь ставить nano — `vi .env`.

Секреты **не** коммитить. После правок `.env` контейнер нужно пересоздать (шаг 8).

### Минимальный контур (бот уже отвечает в Telegram)

```env
BOT_TOKEN=123456:ABCDEF
ADMIN_USER_IDS=123456789
ADMIN_CHAT_ID=123456789
COURSE_CHANNEL_ID=-1001234567890

PAYMENT_PROVIDER=manual
PAYMENT_WEBHOOK_SECRET=

GOOGLE_SHEETS_WRITE_ENABLED=false
```

Цены, даты запуска — вкладка `COURSES` (`gid=0`) в Google-таблице, не `.env`. Тихие часы, путь к гайду и бэкап SQLite заданы в `AppConfig` (`lib/src/config/app_config.dart`). Compose сам ставит `PAYMENT_WEBHOOK_BIND=0.0.0.0:8080` внутри контейнера.

`COURSE_CHANNEL_ID` — числовой id (`-100…`), **не** `t.me/+…`. Постоянный invite ученикам не отдаём.

Несколько админов: `ADMIN_USER_IDS=111,222,333`.

`ADMIN_CHAT_ID` — куда бот пересылает свободный текст ученика («напиши сюда»). Если пусто, уходит каждому id из `ADMIN_USER_IDS`. Часто совпадает с твоим user id. Можно указать id группы админов.

### Когда появится LeadPay

```env
PAYMENT_PROVIDER=leadpay
LEADPAY_TOKEN=...
PAYMENT_WEBHOOK_SECRET=длинная_случайная_строка
```

Секрет:

```bash
openssl rand -hex 32
```

В кабинете LeadPay callback: `https://ТВОЙ_ДОМЕН/payments/callback?secret=ТОТ_ЖЕ_СЕКРЕТ`  
(или заголовок `X-Webhook-Secret`, или path `/payments/callback/СЕКРЕТ`).

Пока токена нет — оставь `PAYMENT_PROVIDER=manual`: админ отмечает оплату в личке.

### Когда запасной шлюз — ЮKassa

```env
PAYMENT_PROVIDER=yookassa
YOOKASSA_SHOP_ID=...
YOOKASSA_SECRET_KEY=...
YOOKASSA_RETURN_URL=https://t.me/ИМЯ_БОТА
PAYMENT_WEBHOOK_SECRET=длинная_случайная_строка
```

ЮKassa требует **HTTPS**. Без домена и шага 9 живой шлюз не включать.

### Google Sheets (`COURSES` + `ССЫЛКИ` + срез `ВОРОНКА`)

Первый лист таблицы (`gid=0`) — каталог запуска **`COURSES`**. Его правят руками (цена, предоплата, даты). Если он пустой, бот при первом коннекте запишет шапку и текущие значения. Вкладка **`ССЫЛКИ`** — диплинки; бот создаёт её и заполняет колонку ссылок, строки заказчицы не затирает. Бот пересобирает вкладку `ВОРОНКА` раз в 5 минут и по кнопке админа; `ВОРОНКА` руками не править (wipe + create). Старый лист `FUNNEL` удаляется. `gid=0` и `ССЫЛКИ` бот не удаляет и не затирает дашбордом.

Нужны три вещи: **сервис-аккаунт JSON**, **таблица**, **доступ редактора** этой почте на таблицу.

#### 1. Google Cloud — ключ

В браузере, лучше с того Google-аккаунта, которым потом будешь смотреть таблицу:

1. Открой [console.cloud.google.com](https://console.cloud.google.com).
2. Создай проект (например `course-chatbot`) или выбери существующий.
3. **APIs & Services → Library** → найди **Google Sheets API** → **Enable**. Drive API не нужен: таблицу создаёшь ты, бот только пишет в уже расшаренный файл.
4. **APIs & Services → Credentials → Create credentials → Service account**.
   - имя: `course-bot-sheets`
   - роль можно не выдавать (доступ идёт через шаринг таблицы, не через IAM)
5. Открой созданный аккаунт → вкладка **Keys → Add key → Create new key → JSON**. Скачается файл вида `course-chatbot-….json`.

JSON скачивается **в браузер на Mac**, не на VPS. Дальше все команды этого шага — **в Terminal на Mac**, в каталоге репозитория:

```bash
cd ~/Developer/PET/course-chatbot
mkdir -p secrets
ls ~/Downloads/*.json
mv ~/Downloads/ИМЯ-СКАЧАННОГО-ФАЙЛА.json secrets/google-sheets.json
python3 -c "import json; print(json.load(open('secrets/google-sheets.json'))['client_email'])"
```

Последняя команда печатает почту вида `course-bot-sheets@….iam.gserviceaccount.com` — её шаришь на таблицу.

JSON в git не коммитить (уже в `.gitignore`: `secrets/*.json`).

#### 2. Таблица

1. [sheets.new](https://sheets.new) — пустая таблица. Название любое, например «Воронка курса».
2. **Настройки доступа → Добавить пользователей** → вставь `client_email` из шага выше → роль **Редактор** → сними галку «Уведомить» → **Отправить**.
3. Из адресной строки скопируй id — кусок между `/d/` и `/edit`:

```
https://docs.google.com/spreadsheets/d/ВОТ_ЭТОТ_ID/edit
```

#### 3. На сервер

С Mac:

```bash
scp secrets/google-sheets.json course-bot:/opt/course-chatbot/secrets/google-sheets.json
```

Если хоста `course-bot` в `~/.ssh/config` нет:

```bash
scp secrets/google-sheets.json root@IP_СЕРВЕРА:/opt/course-chatbot/secrets/google-sheets.json
```

На сервере в `.env`:

```env
GOOGLE_SHEETS_WRITE_ENABLED=true
GOOGLE_SHEETS_CREDENTIALS_PATH=secrets/google-sheets.json
GOOGLE_SHEETS_SPREADSHEET_ID=ВОТ_ЭТОТ_ID
```

Пересоздать контейнер (после любой правки `.env`):

```bash
cd /opt/course-chatbot
chmod 600 secrets/google-sheets.json
docker compose up -d --force-recreate
docker compose logs -f --tail=80
```

Ожидаемое в логах:

- `Google Sheets write enabled. spreadsheetId=…`
- `COURSES catalog synced. launch=…`
- в течение минуты: `Google Sheets ВОРОНКА export completed`

Если `Failed to enable Google Sheets write`:

| Симптом | Что проверить |
| --- | --- |
| `credentials file not found` | файл лежит в `/opt/course-chatbot/secrets/google-sheets.json`, не рядом с `.env` под другим именем |
| `spreadsheet id is missing` | в `.env` нет пустой строки и нет кавычек вокруг id |
| `403` / `PERMISSION_DENIED` | таблицу шарили именно на `client_email` из JSON, роль Редактор |
| `404` | id скопирован не из URL (не gid листа, не имя файла) |
| `Google Sheets API has not been used` | в том же GCP-проекте не включили Sheets API |

Вкладка `ВОРОНКА` появится сама. Руками её не верстать. Первый лист (`gid=0`) бот переименует в `COURSES` и заполнит, если он пустой. Вкладка `ССЫЛКИ` тоже появится сама; новые метки добавляют строкой, колонку ссылок бот переписывает.

---



## 7. PDF гайда

В репозитории уже есть `assets/guide.pdf`. Compose монтирует `./assets` read-only. Если файла нет:

```bash
# с Mac
scp assets/guide.pdf course-bot:/opt/course-chatbot/assets/guide.pdf
```

---



## 8. Собрать и запустить

```bash
cd /opt/course-chatbot
docker compose up -d --build
docker compose ps
docker compose logs -f --tail=100
```

После любой правки `.env`:

```bash
docker compose up -d --force-recreate
```

Ожидаемое:

- контейнер `course-chatbot`, `restart: unless-stopped`;
- healthcheck бьёт в `http://127.0.0.1:8080/health` **внутри** контейнера;
- с хоста: `curl -fsS http://127.0.0.1:8080/health`;
- в логах — polling, без ошибки токена;
- в Telegram `/start` отвечает, админ видит админку.

Один инстанс. Второй контейнер с тем же токеном даст 409 на `getUpdates`.

Если `docker compose ps` показывает `Restarting` / `exited with code 1`:

```bash
docker compose logs --tail=80
```

| В логе | Что делать |
| --- | --- |
| `Failed to load dynamic library 'libsqlite3.so'` | Образ без symlink на `libsqlite3.so.0`. Пересобрать текущим Dockerfile: `docker compose up -d --build` |
| `ADMIN_USER_IDS is required` / `Missing bot token` / `PAYMENT_WEBHOOK_SECRET` | Это **code 2**. Дописать `.env` и `docker compose up -d --force-recreate` |
| `Polling conflict (409)` | Второй процесс с тем же токеном (локальный `make bot`, старый контейнер). Оставить один инстанс |

---



## 9. HTTPS для webhook кассы (когда понадобится)

Порт 8080 снаружи не публикуем. Ставим reverse proxy на `127.0.0.1:8080`.

Нужны домен (A-запись на IP VPS) и открытые 80/443.

Caddy:

```bash
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy
```

`/etc/caddy/Caddyfile`:

```caddy
pay.example.ru {
    encode gzip
    reverse_proxy 127.0.0.1:8080
}
```

```bash
systemctl reload caddy
curl -fsS https://pay.example.ru/health
```

В кассе укажи `https://pay.example.ru/payments/callback?secret=...`.

---



## 10. Обновление кода

| Скрипт | Когда |
| --- | --- |
| `scripts/restart_bot.sh` | Процесс завис, код не менялся |
| `scripts/update_and_logs.sh` | Обычный патч: текст, хендлер, шаблон. На сервере: `git pull` + сборка **с кэшем Docker** |
| `scripts/full_deploy.sh` | Новые пакеты (`pubspec.yaml`), Dockerfile/compose, `.env`, ключ Sheets, или кэш оставил старый бинарник |

Обычный апдейт на сервере:

```bash
cd /opt/course-chatbot
bash scripts/update_and_logs.sh
```

Полный деплой с Mac (после commit + push):

```bash
./scripts/full_deploy.sh
```

Скрипт проверит, что рабочее дерево чистое и origin совпадает с HEAD, затем по SSH (`course-bot` из `~/.ssh/config`): `git pull`, сборка без кэша, recreate контейнера, логи.

Другой хост: `COURSE_SSH=root@IP ./scripts/full_deploy.sh`.

Уже в SSH на VPS:

```bash
cd /opt/course-chatbot
bash scripts/full_deploy.sh
```

Первый запуск нового скрипта: сначала push, на сервере один раз `git pull`, дальше можно вызывать с Mac.

SQLite живёт в `/opt/course-chatbot/data/` — `git pull` её не затирает. Бэкапы: `data/backups/` (`VACUUM INTO`, по умолчанию 7 копий).

Снять снимок руками:

```bash
docker compose exec course-chatbot ls -l /app/data
# или с хоста:
cp -a /opt/course-chatbot/data/course.sqlite /opt/course-chatbot/data/backups/manual-$(date +%F-%H%M).sqlite
```

---



## 11. Чеклист «сервер готов»

- [ ] VPS Ubuntu 24.04 в Москве, без панели, SSH по ключу
- [ ] Docker + Compose установлены
- [ ] `ufw`: 22 (+ 80/443, если будет касса); **8080 закрыт**
- [ ] Репозиторий в `/opt/course-chatbot`
- [ ] `.env` заполнен: токен, админы, канал
- [ ] `PAYMENT_PROVIDER=manual` **или** живая касса + `PAYMENT_WEBHOOK_SECRET` + HTTPS
- [ ] `docker compose up -d --build`, контейнер healthy
- [ ] `curl http://127.0.0.1:8080/health` ок
- [ ] `/start` в Telegram работает
- [ ] Бот админ канала, `COURSE_CHANNEL_ID` числовой
- [ ] Sheets: JSON в `secrets/`, таблица расшарена на `client_email`, `GOOGLE_SHEETS_WRITE_ENABLED=true`

После сдачи заказчице: доступы SmartApe, `.env`, бэкапы SQLite. Копию бота у себя не оставлять.