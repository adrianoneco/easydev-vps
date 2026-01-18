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
    }" | jq > /dev/null 2>&1

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
    }" | jq > /dev/null 2>&1

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
    }" | jq > /dev/null 2>&1
}

function delete_record() {
    local RECORD_ID=$1

    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" | jq > /dev/null 2>&1
}

function list_dns_records() {
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" | jq > /dev/null 2>&1
}

function get_record_id() {
    local RECORD_NAME=$1

    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?name=${RECORD_NAME}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id' > /dev/null 2>&1
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
    }" | jq > /dev/null 2>&1
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
    }" | jq > /dev/null 2>&1
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
    }" | jq > /dev/null 2>&1
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
    }" | jq > /dev/null 2>&1

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
    }" | jq  > /dev/null 2>&1

}

function auto_fix_server() {
    local IPV4=$(curl -s https://ipv4.icanhazip.com)
    local IPV6=$(curl -s https://ipv6.icanhazip.com)
    local DOMAIN=$1
    echo "Auto-fixing DNS records for ${DOMAIN}..."
    add_a_record "mail" "$IPV4" false > /dev/null 2>&1
    add_aaaa_record "$DOMAIN" "$IPV6" true > /dev/null 2>&1

    add_cname_record "www" "$DOMAIN" true > /dev/null 2>&1
    add_mx_record "$DOMAIN" "mail.$DOMAIN" 10 > /dev/null 2>&1
    add_txt_record "$DOMAIN" "v=spf1 ip4:${IPV4} include:${DOMAIN} -all" > /dev/null 2>&1
    add_txt_record "_dmarc" "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;rua=mailto:admin@${DOMAIN}" > /dev/null 2>&1
    add_txt_record "*._domainkey" "v=DKIM1; k=rsa; p=" > /dev/null 2>&1
}



auto_fix_server "$1"