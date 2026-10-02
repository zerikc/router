# Маршрутизация через VPN по доменам на Keenetic

Вместо ~700 статических IP-маршрутов (`legacy/staticRoutes.bat`) — списки доменов,
сгруппированные по сервисам. Keenetic сам смотрит DNS-ответы и отправляет через VPN
только адреса, которые получились из этих доменов. Поддомены включаются
автоматически: `youtube.com` покрывает `www.youtube.com`, `m.youtube.com` и т.д.

Нужен **KeeneticOS 4.0 или новее** (функция «маршрутизация по доменам»).

## Структура

| Файл | Что внутри |
|---|---|
| `domains/youtube.txt` | YouTube |
| `domains/meta.txt` | Facebook, Instagram, WhatsApp, Threads |
| `domains/twitter.txt` | X / Twitter, Grok |
| `domains/discord.txt` | Discord |
| `domains/telegram.txt` | Сайты Telegram и веб-версия |
| `domains/ai.txt` | ChatGPT, Claude, Gemini, Copilot, Cursor, Windsurf, JetBrains, DeepL |
| `domains/work.txt` | Adobe, Canva, Miro, Sketch, iMazing, LinkedIn, Signal, Aqara, Notepad++ |
| `domains/media.txt` | Netflix, SoundCloud, pixiv, MyAnimeList, Roblox, Флибуста и др. |
| `domains/kinopub.txt` | kino.pub и его CDN |
| `ip/telegram.txt` | Подсети Telegram (единственное исключение, см. ниже) |
| `keenetic/install.txt` | Готовые команды для CLI роутера (генерируются) |
| `keenetic/uninstall.txt` | Откат того, что делает `install.txt` |
| `keenetic/remove-legacy-routes.txt` | Удаление старых IP-маршрутов из `.bat` |
| `keenetic/all-domains.txt` | Все домены одним списком — для вставки в веб-интерфейс |
| `legacy/staticRoutes.bat` | Старый IP-список, для истории |

Строки с `#` — комментарии, роутер их не увидит: скрипт их вырезает.

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
   object-group fqdn media
    include example.com
   exit
   system configuration save
   ```

Поддомен отдельно добавлять не нужно, если уже есть основной домен.

## Откуда взялись списки

Почти все подсети в `legacy/staticRoutes.bat` совпадают с файлами из
[RockBlack-VPN/ip-address](https://github.com/RockBlack-VPN/ip-address): YouTube/Google,
Facebook, Instagram, WhatsApp, Telegram, Discord, ChatGPT, Gemini, Claude, Adobe,
kino.pub, Twitter, Signal, Notepad++, pixiv и другие. Их домены вошли в списки выше.
Часть сервисов (LinkedIn, Netflix, Roblox, JetBrains, Miro, SoundCloud, MyAnimeList,
DeepL) совпала лишь частично: возможно, это просто общие CDN-сети. Если что-то
из них вам не нужно, удалите строки.

Не перенесены: FaceTime/iCloud (подсети Apple `17.x`). Они работают по IP и push-каналу,
доменами их не покрыть. Если FaceTime перестанет работать, добавьте подсеть
`17.0.0.0/8` статическим маршрутом.
