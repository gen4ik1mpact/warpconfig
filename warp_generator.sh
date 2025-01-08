#!/bin/bash

clear
mkdir -p ~/.cloudshell && touch ~/.cloudshell/no-apt-get-warning # Для Google Cloud Shell, но лучше там не выполнять
echo "Установка зависимостей..."
apt update -y && apt install sudo -y # Для Aeza Terminator, там sudo не установлен по умолчанию
sudo apt-get update -y --fix-missing && sudo apt-get install wireguard-tools jq wget -y --fix-missing # Update второй раз, если sudo установлен и обязателен (в строке выше не сработал)

priv="${1:-$(wg genkey)}"
pub="${2:-$(echo "${priv}" | wg pubkey)}"
api="https://api.cloudflareclient.com/v0i1909051800"
ins() { curl -s -H 'user-agent:' -H 'content-type: application/json' -X "$1" "${api}/$2" "${@:3}"; }
sec() { ins "$1" "$2" -H "authorization: Bearer $3" "${@:4}"; }
response=$(ins POST "reg" -d "{\"install_id\":\"\",\"tos\":\"$(date -u +%FT%T.000Z)\",\"key\":\"${pub}\",\"fcm_token\":\"\",\"type\":\"ios\",\"locale\":\"en_US\"}")

clear
echo -e "НЕ ИСПОЛЬЗУЙТЕ GOOGLE CLOUD SHELL ДЛЯ ГЕНЕРАЦИИ! Если вы сейчас в Google Cloud Shell, прочитайте актуальный гайд: https://t.me/immalware/1211\n"

id=$(echo "$response" | jq -r '.result.id')
token=$(echo "$response" | jq -r '.result.token')
response=$(sec PATCH "reg/${id}" "$token" -d '{"warp_enabled":true}')
peer_pub=$(echo "$response" | jq -r '.result.config.peers[0].public_key')
#peer_endpoint=$(echo "$response" | jq -r '.result.config.peers[0].endpoint.host')
client_ipv4=$(echo "$response" | jq -r '.result.config.interface.addresses.v4')
client_ipv6=$(echo "$response" | jq -r '.result.config.interface.addresses.v6')

conf=$(cat <<-EOM
{
  "interface": {
   "private_key": "${priv}",
   "s1": 0,
   "s2": 0,
   "j_c": 120,
   "j_min": 23,
   "j_max": 911,
   "h1": 1,
   "h2": 2,
   "h3": 3,
   "h4": 4,
   "mtu": 1500,
   "address": "${client_ipv4}, ${client_ipv6}",
   "dns": "1.1.1.1 , 2606:4700:4700::1111, 1.0.0.1, 2606:4700:4700::1001"
  },
  "peer": {
   "publicKey": "${peer_pub}",
   "allowed_ips": "0.0.0.0/0, ::/0",
   "endpoint": "188.114.97.66:3138"
  }
}
EOM
)

echo -e "\n\n\n"
[ -t 1 ] && echo "########## НАЧАЛО КОНФИГА ##########"
echo "${conf}"
[ -t 1 ] && echo "########### КОНЕЦ КОНФИГА ###########"

conf_base64=$(echo -n "${conf}" | base64 -w 0)
echo "Скачать конфиг файлом: https://immalware.github.io/downloader.html?filename=WARP.conf&content=${conf_base64}"
echo -e "\n"
echo "Что-то не получилось? Есть вопросы? Пишите в чат: https://t.me/immalware_chat"
