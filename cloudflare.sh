#!/bin/bash
source /srv/.env


function add_a_record() {
    local RECORD_NAME=$1
    local IP_ADDRESS=$2
    local TTL=120
    local PROXIED=$3

    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"A\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"${IP_ADDRESS}\",
        \"ttl\": ${TTL},
        \"proxied\": ${PROXIED}
    }" | jq

}

function add_aaaa_record() {
    local RECORD_NAME=$1
    local IP_ADDRESS=$2
    local TTL=120
    local PROXIED=$3

    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"AAAA\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"${IP_ADDRESS}\",
        \"ttl\": ${TTL},
        \"proxied\": ${PROXIED}
    }" | jq

}

function add_cname_record() {
    local RECORD_NAME=$1
    local CNAME_TARGET=$2
    local TTL=120
    local PROXIED=$3

    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"CNAME\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"${CNAME_TARGET}\",
        \"ttl\": ${TTL},
        \"proxied\": ${PROXIED}
    }" | jq
}

function delete_record() {
    local RECORD_ID=$1

    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" | jq
}

function list_dns_records() {
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" | jq
}

function get_record_id() {
    local RECORD_NAME=$1

    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?name=${RECORD_NAME}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id'
}

function update_a_record() {
    local RECORD_ID=$1
    local RECORD_NAME=$2
    local IP_ADDRESS=$3
    local TTL=120
    local PROXIED=$4

    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"A\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"${IP_ADDRESS}\",
        \"ttl\": ${TTL},
        \"proxied\": ${PROXIED}
    }" | jq
}

function update_aaaa_record() {
    local RECORD_ID=$1
    local RECORD_NAME=$2
    local IP_ADDRESS=$3
    local TTL=120
    local PROXIED=$4

    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"AAAA\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"${IP_ADDRESS}\",
        \"ttl\": ${TTL},
        \"proxied\": ${PROXIED}
    }" | jq
}

function update_cname_record() {
    local RECORD_ID=$1
    local RECORD_NAME=$2
    local CNAME_TARGET=$3
    local TTL=120
    local PROXIED=$4

    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"CNAME\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"${CNAME_TARGET}\",
        \"ttl\": ${TTL},
        \"proxied\": ${PROXIED}
    }" | jq
}

function add_mx_record() {
    local RECORD_NAME=$1
    local MAIL_SERVER=$2
    local PRIORITY=$3
    local TTL=120

    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"MX\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"${MAIL_SERVER}\",
        \"priority\": ${PRIORITY},
        \"ttl\": ${TTL}
    }" | jq

}

function add_txt_record() {
    local RECORD_NAME=$1
    local TEXT_VALUE=$2
    local TTL=120

    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "{
        \"type\": \"TXT\",
        \"name\": \"${RECORD_NAME}\",
        \"content\": \"\\\"${TEXT_VALUE}\\\"\",
        \"ttl\": ${TTL}
    }" | jq

}

function auto_fix_server() {
    local IPV4=$(curl -s https://ipv4.icanhazip.com)
    local IPV6=$(curl -s https://ipv6.icanhazip.com)
    local HOST_NAME=$1
    echo "Auto-fixing DNS records for ${HOST_NAME}..."
    add_a_record "mail" "$IPV4" false
    add_aaaa_record "$HOST_NAME" "$IPV6" true

    add_cname_record "www" "$HOST_NAME" true
    add_mx_record "$HOST_NAME" "mail.$HOST_NAME" 10
    add_txt_record "$HOST_NAME" "v=spf1 ip4:${IPV4} include:${HOST_NAME} -all"
    add_txt_record "_dmarc" "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;rua=mailto:admin@${HOST_NAME}"
    add_txt_record "*._domainkey" "v=DKIM1; k=rsa; p="
}



auto_fix_server "$1"