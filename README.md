# Маршрутизация через VPN по доменам на Keenetic

Через VPN идут **только** сервисы, которые:

- **заблокированы или замедлены в России** — файлы `domains/ru-*.txt`;
- **сами не пускают пользователей из России** (Claude, ChatGPT, Adobe, Netflix…) —
  файлы `domains/geo-*.txt`.

Всё остальное (банки, Госуслуги, российские сайты, обычный интернет) идёт напрямую через
провайдера, поэтому никаких исключений для Кинопоиска и т.п. больше не нужно.

Keenetic сам смотрит DNS-ответы и отправляет через VPN только адреса, полученные
из этих доменов. Поддомены включаются автоматически: `claude.ai` покрывает
`api.claude.ai` и т.д. Нужен **KeeneticOS 4.0 или новее**.

## Структура

| Файл | Что внутри |
|---|---|
| `domains/ru-youtube.txt` | YouTube |
| `domains/ru-meta.txt` | Facebook, Instagram, Threads, WhatsApp |
| `domains/ru-twitter.txt` | X / Twitter |
| `domains/ru-discord.txt` | Discord |
| `domains/ru-telegram.txt` | Сайты Telegram и веб-версия |
| `domains/ru-kinopub.txt` | kino.pub и его CDN |
| `domains/ru-other.txt` | Signal, LinkedIn, Roblox, Флибуста, Notepad++, Pornhub |
| `domains/geo-ai.txt` | Claude, ChatGPT, Gemini, Grok, Copilot, Cursor, Windsurf, JetBrains AI |
| `domains/geo-software.txt` | JetBrains, Adobe, Canva, Miro, Sketch, iMazing, Aqara |
| `domains/geo-media.txt` | Netflix, pixiv |
| `ip/telegram.txt` | Подсети Telegram (единственное исключение, см. ниже) |
| `keenetic/install.txt` | Готовые команды для CLI роутера (генерируются) |
| `keenetic/uninstall.txt` | Откат того, что делает `install.txt` |
| `keenetic/remove-legacy-routes.txt` | Удаление старых IP-маршрутов из `.bat` |
| `keenetic/all-domains.txt` | Все домены одним списком — для вставки в веб-интерфейс |
| `legacy/staticRoutes.bat` | Старый IP-список, для истории |

Строки с `#` — комментарии, роутер их не увидит: скрипт их вырезает. Сервисы, про
которые не ясно, нужен ли им VPN (DeepL, SoundCloud, MyAnimeList), закомментированы:
если без VPN не открываются, уберите `#` перед доменом и пересоберите команды.

## Почему Telegram остался на IP

Приложение Telegram подключается к своим серверам по жёстко прописанным IP, без DNS.
Доменная маршрутизация его не поймает, поэтому 10 подсетей Telegram добавляются
обычными статическими маршрутами. Всё остальное — только по доменам.

## Установка

### 1. Узнать имя VPN-интерфейса

Подключитесь к роутеру по telnet/SSH (`telnet 192.168.1.1`, логин и пароль от
веб-интерфейса) и выполните:

```
show interface
```

Типичные имена: `Wireguard0`, `Wireguard1`, `OpenVPN0`, `Proxy0`.

### 2. Сгенерировать команды под свой интерфейс

```
scripts/build.sh Wireguard0
```

В репозитории файлы уже собраны для `Wireguard0`. Если у вас он же — шаг можно пропустить.

### 3. Удалить старые IP-маршруты

Проще всего в веб-интерфейсе: **Маршрутизация** → отметить все старые маршруты → удалить.
Или вставить в telnet/SSH содержимое `keenetic/remove-legacy-routes.txt`
(ошибки «маршрут не найден» — это нормально: в `.bat` были дубли).

### 4. Добавить доменные маршруты

Вставить в telnet/SSH содержимое `keenetic/install.txt`. Последняя команда
`system configuration save` сохраняет настройки.

Проверка:

```
show object-group fqdn
show ip route
```

Флаг `auto` в командах значит, что маршрут работает, только пока VPN поднят.
Если хотите, чтобы при упавшем VPN эти сайты блокировались, а не шли напрямую через
провайдера, допишите `reject` в строки `dns-proxy route ...`.

### Вариант через веб-интерфейс

В разделе маршрутизации по доменам (в 4.x — **Маршрутизация** → **Маршруты DNS**;
название пункта может немного отличаться в разных версиях) создайте список, вставьте
домены из нужного файла `domains/*.txt` (без строк с `#`) и выберите VPN-интерфейс.
Подсети Telegram из `ip/telegram.txt` добавьте как обычные статические маршруты.

## Чтобы это работало

Доменная маршрутизация видит только DNS-запросы, которые идут через роутер.
Поэтому:

- **Отключите DNS-over-HTTPS в браузерах** (Chrome: «Безопасный DNS», Firefox:
  «DNS через HTTPS») и «Частный DNS» на Android. Иначе браузер резолвит в обход роутера.
- **iCloud Private Relay** на iPhone/Mac тоже выключить для домашней сети.
- **IPv6**: если провайдер выдаёт IPv6, трафик может уйти мимо VPN. Проще отключить
  IPv6 на интерфейсе провайдера.
- **DNS роутера**: включите DoT/DoH (компонент «Прокси-сервер DNS-over-TLS»), например
  `1.1.1.1` / `cloudflare-dns.com`, и «Игнорировать DNS провайдера». Иначе провайдер
  может подменять ответы для заблокированных доменов.
- После изменений очистите DNS-кэш на устройствах (`ipconfig /flushdns` в Windows)
  или просто переподключитесь к Wi-Fi. Приложения вроде Instagram иногда нужно
  перезапустить.

## Как добавить сайт

1. Откройте сайт в браузере, F12 → вкладка **Network**, посмотрите, с каких доменов
   он грузит данные.
2. Допишите домены в подходящий `domains/*.txt` (или создайте новый файл —
   из него получится отдельная группа).
3. `scripts/build.sh <интерфейс>` и вставьте на роутер только новые строки, например:

   ```
   object-group fqdn geo-media
    include example.com
   exit
   system configuration save
   ```

Поддомен отдельно добавлять не нужно, если уже есть основной домен.

## Откуда взялись списки

Подсети из `legacy/staticRoutes.bat` сверены с файлами
[RockBlack-VPN/ip-address](https://github.com/RockBlack-VPN/ip-address), чтобы понять,
какие сервисы за ними стоят. В списки попали только те, что заблокированы в РФ или
сами блокируют РФ, плюс ваш DNS-список. Широкие подсети Google, Amazon, Cloudflare
и Microsoft из старого списка не перенесены: через них работает половина интернета,
и гнать их через VPN незачем.

Не перенесены: FaceTime/iCloud (подсети Apple `17.x`). Они работают по IP и push-каналу,
доменами их не покрыть. Если FaceTime перестанет работать, добавьте подсеть
`17.0.0.0/8` статическим маршрутом.

## Если вы уже ставили прошлую версию

Группы тогда назывались иначе. Удалите их перед установкой новой:

```
no dns-proxy route object-group ai Wireguard0
no dns-proxy route object-group work Wireguard0
no dns-proxy route object-group media Wireguard0
no dns-proxy route object-group kinopub Wireguard0
no dns-proxy route object-group youtube Wireguard0
no dns-proxy route object-group meta Wireguard0
no dns-proxy route object-group twitter Wireguard0
no dns-proxy route object-group discord Wireguard0
no dns-proxy route object-group telegram Wireguard0
no object-group fqdn ai
no object-group fqdn work
no object-group fqdn media
no object-group fqdn kinopub
no object-group fqdn youtube
no object-group fqdn meta
no object-group fqdn twitter
no object-group fqdn discord
no object-group fqdn telegram
system configuration save
```
