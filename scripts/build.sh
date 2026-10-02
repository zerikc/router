#!/bin/sh
# Собирает команды для Keenetic CLI из domains/*.txt и ip/*.txt.
# Использование: scripts/build.sh [интерфейс_VPN]   (по умолчанию Wireguard0)
set -eu
cd "$(dirname "$0")/.."
IFACE=${1:-Wireguard0}

clean() { sed -e 's/#.*//' -e 's/[[:space:]]//g' "$1" | grep -v '^$'; }

{
  echo "! Сгенерировано scripts/build.sh для интерфейса $IFACE"
  for f in domains/*.txt; do
    g=$(basename "$f" .txt)
    echo "object-group fqdn $g"
    clean "$f" | sed 's/^/ include /'
    echo "exit"
    echo "dns-proxy route object-group $g $IFACE auto"
  done
  for f in ip/*.txt; do
    clean "$f" | sed "s|.*|ip route & $IFACE auto|"
  done
  echo "system configuration save"
} > keenetic/install.txt

{
  echo "! Удаление групп и маршрутов, созданных install.txt"
  for f in domains/*.txt; do
    g=$(basename "$f" .txt)
    echo "no dns-proxy route object-group $g $IFACE"
    echo "no object-group fqdn $g"
  done
  for f in ip/*.txt; do
    clean "$f" | sed "s|.*|no ip route & $IFACE|"
  done
  echo "system configuration save"
} > keenetic/uninstall.txt

# Удаление старых статических маршрутов из legacy/staticRoutes.bat
{
  echo "! Удаление старых IP-маршрутов (legacy/staticRoutes.bat) с интерфейса $IFACE"
  awk -v ifc="$IFACE" '
    function bits(m,  a, i, n, o) {
      split(m, a, "."); n = 0
      for (i = 1; i <= 4; i++) { o = a[i] + 0
        while (o > 0) { n += o % 2; o = int(o / 2) } }
      return n
    }
    $1 == "route" && $2 == "add" && $4 == "mask" {
      r = $3 "/" bits($5)
      if (!(r in seen)) { seen[r] = 1; print "no ip route " r " " ifc }
    }' legacy/staticRoutes.bat
  echo "system configuration save"
} > keenetic/remove-legacy-routes.txt

# Плоский список доменов для вставки в веб-интерфейс
for f in domains/*.txt; do clean "$f"; done > keenetic/all-domains.txt

echo "Готово: keenetic/install.txt, keenetic/uninstall.txt, keenetic/remove-legacy-routes.txt, keenetic/all-domains.txt"
