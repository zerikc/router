# Списки для обхода блокировок на Keenetic

Через VPN идут только сервисы, заблокированные в России или не работающие из России.
Всё остальное идёт напрямую через провайдера.

| Файл | Что внутри |
|---|---|
| `01-ai.txt` | Claude, ChatGPT, Gemini, Grok, Copilot, Cursor, Windsurf |
| `02-youtube.txt` | YouTube |
| `03-instagram-facebook-whatsapp.txt` | Instagram, Facebook, WhatsApp, Threads |
| `04-telegram.txt` | Telegram (сайты, веб-версия) |
| `05-twitter.txt` | X / Twitter |
| `06-discord.txt` | Discord |
| `07-kinopub.txt` | kino.pub |
| `08-media.txt` | Netflix, Spotify, pixiv |
| `09-blocked-other.txt` | Signal, Viber, Snapchat, Proton, LinkedIn, Roblox, Medium, Speedtest, Флибуста, Notepad++, Pornhub |
| `10-software.txt` | JetBrains, Adobe, Canva, Miro, Figma, Notion, Sketch, iMazing, Aqara |
| `telegram-ip.bat` | IP-адреса Telegram (приложение работает по IP, а не по доменам) |

## Как добавить

1. **Домены** (`01`–`10`): в веб-интерфейсе роутера откройте маршрутизацию по доменам
   (KeeneticOS 4.0+), создайте список, вставьте содержимое файла и выберите
   VPN-подключение. Повторите для каждого файла. Поддомены добавлять не нужно:
   `claude.ai` покрывает и `api.claude.ai`.
2. **Telegram**: `telegram-ip.bat` загрузите как раньше:
   «Маршрутизация» → «Загрузить из файла», интерфейс — ваш VPN.
3. Старые IP-маршруты удалите.

## Чтобы работало

- Отключите в браузерах «Безопасный DNS» (DoH), на Android — «Частный DNS»,
  на iPhone — «Частный узел iCloud».
- На роутере включите DNS-over-TLS и «Игнорировать DNS провайдера».
- Отключите IPv6 у подключения провайдера.
