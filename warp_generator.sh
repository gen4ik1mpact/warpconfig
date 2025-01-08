#!/bin/bash
clear
mkdir -p ~/.cloudshell && touch ~/.cloudshell/no-apt-get-warning
echo "Установка зависимостей..."
apt update -y && apt install sudo -y
sudo apt-get update -y --fix-missing && sudo apt-get install wireguard-tools jq wget curl -y --fix-missing

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
client_ipv4=$(echo "$response" | jq -r '.result.config.interface.addresses.v4')
client_ipv6=$(echo "$response" | jq -r '.result.config.interface.addresses.v6')

# Загружаем конфиг по прямой ссылке
config_url="https://raw.githubusercontent.com/trypophob1a/remotewarpconfig/main/config_templates/template.json"
if ! config=$(curl -s "$config_url"); then
    echo "Ошибка загрузки конфига"
    exit 1
fi

# Экранируем специальные символы в переменных
priv_esc=$(printf '%s\n' "$priv" | sed 's:[\/&]:\\&:g;$!s/$/\\/')
client_ipv4_esc=$(printf '%s\n' "$client_ipv4" | sed 's:[\/&]:\\&:g;$!s/$/\\/')
client_ipv6_esc=$(printf '%s\n' "$client_ipv6" | sed 's:[\/&]:\\&:g;$!s/$/\\/')
peer_pub_esc=$(printf '%s\n' "$peer_pub" | sed 's:[\/&]:\\&:g;$!s/$/\\/')

# Заменяем переменные в конфиге используя | как разделитель
conf=$(echo "$config" | sed \
    -e "s|\${priv}|$priv_esc|g" \
    -e "s|\${client_ipv4}|$client_ipv4_esc|g" \
    -e "s|\${client_ipv6}|$client_ipv6_esc|g" \
    -e "s|\${peer_pub}|$peer_pub_esc|g")

echo -e "\n\n\n"
[ -t 1 ] && echo "########## НАЧАЛО КОНФИГА ##########"
echo "${conf}"
[ -t 1 ] && echo "########### КОНЕЦ КОНФИГА ###########"
conf_base64=$(echo -n "${conf}" | base64 -w 0)
echo "Скачать конфиг файлом: https://immalware.github.io/downloader.html?filename=WARP.conf&content=${conf_base64}"
echo -e "\n"
echo "Что-то не получилось? Есть вопросы? Пишите в чат: https://t.me/immalware_chat"
