#!/usr/bin/env bash
mkdir -p /srv/{scripts,config}

############################################
# PARSE DE ARGUMENTOS
############################################
for arg in "$@"; do
  case $arg in
    --timezone=*) TZ="${arg#*=}" ;;
    --domain=*) DOMAIN="${arg#*=}" ;;
    --admin-name=*) ADMIN_NAME="${arg#*=}" ;;
    --admin-email=*) ADMIN_EMAIL="${arg#*=}" ;;
    --admin-password=*) ADMIN_PASSWORD="${arg#*=}" ;;
    --admin-phone=*) ADMIN_PHONE="${arg#*=}" ;;
    --smtp-host=*) SMTP_HOST="${arg#*=}" ;;
    --smtp-port=*) SMTP_PORT="${arg#*=}" ;;
    --smtp-username=*) SMTP_USERNAME="${arg#*=}" ;;
    --smtp-password=*) SMTP_PASSWORD="${arg#*=}" ;;
    --owncloud-host=*) OWNCLOUD_HOST="${arg#*=}" ;;
    --owncloud-username=*) OWNCLOUD_USERNAME="${arg#*=}" ;;
    --owncloud-password=*) OWNCLOUD_PASSWORD="${arg#*=}" ;;
    --cloudflare-email=*) CLOUDFLARE_EMAIL="${arg#*=}" ;;
    --cloudflare-api-key=*) CLOUDFLARE_API_KEY="${arg#*=}" ;;
    --cloudflare-zone-id=*) CLOUDFLARE_ZONE_ID="${arg#*=}" ;;
    --docker-username=*) DOCKER_USERNAME="${arg#*=}" ;;
    --docker-api-token=*) DOCKER_API_TOKEN="${arg#*=}" ;;
    --zapi-instance-id=*) ZAPI_INSTANCE_ID="${arg#*=}" ;;
    --zapi-instance-token=*) ZAPI_INSTANCE_TOKEN="${arg#*=}" ;;
    --zapi-instance-secret=*) ZAPI_INSTANCE_SECRET="${arg#*=}" ;;
    --typebot-github-client-id=*) TYPEBOT_GITHUB_CLIENT_ID="${arg#*=}" ;;
    --typebot-github-client-secret=*) TYPEBOT_GITHUB_CLIENT_SECRET="${arg#*=}" ;;
    --asaas-environment=*) ASAAS_ENVIRONMENT="${arg#*=}" ;;
    --asaas-api-key=*) ASAAS_API_KEY="${arg#*=}" ;;
    *) echo "❌ Unknown argument $arg" && exit 1 ;;
  esac
done

############################################
# VALIDACOES
############################################
: "${TZ:?}"
: "${DOMAIN:?}"
: "${ADMIN_NAME:?}"
: "${ADMIN_EMAIL:?}"
: "${ADMIN_PASSWORD:?}"
: "${ADMIN_PHONE:?}"
: "${SMTP_HOST:?}"
: "${SMTP_PORT:?}"
: "${SMTP_USERNAME:?}"
: "${SMTP_PASSWORD:?}"
: "${CLOUDFLARE_API_KEY:?}"
: "${ZAPI_INSTANCE_ID:?}"
: "${ZAPI_INSTANCE_TOKEN:?}"
: "${ZAPI_INSTANCE_SECRET:?}"
: "${DOCKER_USERNAME:?}"
: "${DOCKER_API_TOKEN:?}"
: "${TYPEBOT_GITHUB_CLIENT_ID:?}"
: "${TYPEBOT_GITHUB_CLIENT_SECRET:?}"
: "${ASAAS_ENVIRONMENT:?}"
: "${ASAAS_API_KEY:?}"

export DEBIAN_FRONTEND=noninteractive
timedatectl set-timezone "$TZ"
# force TZ
export TZ="$TZ"
############################################
# Criar usuario baseado no $DOMAIN
############################################
USER_NAME=$(echo "$DOMAIN" | cut -d. -f1 | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')
if ! id -u "$USER_NAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USER_NAME" --comment "User for $DOMAIN" --create-home --home /home/"$USER_NAME" --password "$(openssl passwd -6 "$ADMIN_PASSWORD")"
  echo "$USER_NAME:$ADMIN_PASSWORD" | chpasswd
  usermod -aG sudo "$USER_NAME"
fi

############################################
# BASE SYSTEM UPDATE
############################################
apt update -y
apt upgrade -y
apt full-upgrade -y
apt install -y \
  ca-certificates curl wget gnupg lsb-release \
  software-properties-common unzip jq mailutils \
  pwgen net-tools dnsutils sendmail argon2 dovecot-core



function passgen() {
  EXCLUDE_CHARS="\"'!\`@#$%^&*(){}[]<>|\\~"
  set +H
  pwgen -Bsyv -r "$EXCLUDE_CHARS" 64 1
}
############################################
# PYTHON + CERTBOT + CLOUDFLARE
############################################
apt install -y python3 python3-pip certbot python3-certbot-dns-cloudflare

############################################
# NODE 22
############################################
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
npm install -g npm@latest @nestjs/cli next@latest dotenv dotenv-cli concurrently pm2

############################################
# POSTGRESQL CLIENT (PGDG)
############################################
install -d /usr/share/postgresql-common/pgdg
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc

. /etc/os-release
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
> /etc/apt/sources.list.d/pgdg.list

apt update -y
apt install -y postgresql-client-17

############################################
# MINIO CLIENT
############################################
curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc \
  -o /srv/scripts/mc
chmod +x /srv/scripts/mc

############################################
# DOCKER
############################################
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "$DOCKER_API_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin

############################################
# GIT + GH
############################################
wget -qO /etc/apt/keyrings/githubcli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg
chmod go+r /etc/apt/keyrings/githubcli.gpg
echo "deb [signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
> /etc/apt/sources.list.d/github-cli.list
apt update -y
apt install -y git gh


############################################
# Server Signature
############################################
echo "🆔 Server ID: Generating..."

# 🔑 Chave secreta (ideal vir de ENV ou Vault)
HMAC_SECRET="${HMAC_SECRET:-$(openssl rand -hex 32)}"

# 🌐 IPv4
IPV4=$(curl -4 -s https://api.ipify.org)

# 🌐 IPv6 (se existir)
IPV6=$(curl -6 -s https://api64.ipify.org || echo "N/A")

# Reverse Domain
REVERSE_DOMAIN=$(nslookup $IPV4 | grep '.in-addr.arpa' | awk '{print $NF}' | rev | cut -c2- | rev)

# 🆔 UUID
UUID=$(uuidgen)

# 🧱 Payload
PAYLOAD="${IPV4}|${IPV6}|${UUID}|$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# 🔐 Assinatura HMAC-SHA512 (hex)
SIGNATURE_HASH=$(printf "%s" "$PAYLOAD" \
  | openssl dgst -sha512 -hmac "$HMAC_SECRET" \
  | awk '{print $NF}')

SERVER_IDENTIFIER=$(echo -n "$PAYLOAD" | sha256sum | awk '{print $1}')
HOST_NAME=$(hostname)
############################################
# ENV CENTRAL
############################################
mkdir -p /srv
cat > /srv/.env <<EOF
TZ="${TZ}"
DOMAIN="${DOMAIN}"
REVERSE_DOMAIN=${REVERSE_DOMAIN}
HOST_NAME="${HOST_NAME}"
IPV4="${IPV4}"
IPV6="${IPV6}"

SERVER_IDENTIFIER="${SERVER_IDENTIFIER}"
SERVER_SIGNATURE="${SIGNATURE_HASH}"

ADMIN_NAME="${ADMIN_NAME}"
ADMIN_EMAIL="${ADMIN_EMAIL}"
ADMIN_PHONE="${ADMIN_PHONE}"
SMTP_HOST="${SMTP_HOST}"
SMTP_PORT="${SMTP_PORT}"
SMTP_USERNAME="${SMTP_USERNAME}"
SMTP_PASSWORD="${SMTP_PASSWORD}"

OWNCLOUD_HOST="${OWNCLOUD_HOST:-}"
OWNCLOUD_USERNAME="${OWNCLOUD_USERNAME:-}"
OWNCLOUD_PASSWORD="${OWNCLOUD_PASSWORD:-}"
OWNCLOUD_PATH="/backups/$(hostname)/"

ASAAS_ENVIRONMENT="${ASAAS_ENVIRONMENT}"
ASAAS_API_KEY="${ASAAS_API_KEY}"

CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL:-}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY}"
CLOUDFLARE_ZONE_ID="${CLOUDFLARE_ZONE_ID:-}"

ZAPI_INSTANCE_ID="${ZAPI_INSTANCE_ID}"
ZAPI_INSTANCE_TOKEN="${ZAPI_INSTANCE_TOKEN}"
ZAPI_INSTANCE_SECRET="${ZAPI_INSTANCE_SECRET}"

POSTGRES_PASSWORD=$(passgen)

PGADMIN_PASSWORD="$(passgen)"

MAIL_DOMAIN="mail.${DOMAIN}"
MAIL_PORT=465

MINIO_USER=minio
MINIO_PASSWORD="$(passgen)"

REDIS_USER=redis
REDIS_PASSWORD="$(passgen)"

MAILSERVER_SRS_SECRET="$(pwgen -Bsv 32 1)"

EVOLUTION_API_KEY="$(uuidgen | tr [:lower:] [:upper:])"

TYPEBOT_SECRET="$(pwgen -Bsv 32 1)"

TYPEBOT_SMTP_USERNAME="typebot@${DOMAIN}"
TYPEBOT_SMTP_PASSWORD="${ADMIN_PASSWORD}"
TYPEBOT_GITHUB_CLIENT_ID=
TYPEBOT_GITHUB_CLIENT_SECRET=

N8N_SMTP_USERNAME="n8n@${DOMAIN}"
N8N_SMTP_PASSWORD="${ADMIN_PASSWORD}"
N8N_ENCRYPTION_KEY="$(pwgen -Bsv 32 1)"
EOF

chmod 600 /srv/.env

bash ./cloudflare.sh


cat <<EOL > /srv/docker-compose.yml
services:
  postgresql:
    image: pgvector/pgvector:pg17
    container_name: postgresql
    restart: always
    environment:
      - TZ=America/Sao_Paulo
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_DB=postgres
    ports:
      - "127.0.0.1:5000:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - /srv/pgsql-init.sql:/docker-entrypoint-initdb.d/init.sql

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    restart: always
    environment:
      - TZ=America/Sao_Paulo
      - PGADMIN_DEFAULT_EMAIL=\${ADMIN_EMAIL}
      - PGADMIN_DEFAULT_PASSWORD=\${PGADMIN_PASSWORD}
    volumes:
      - pgadmin_data:/var/lib/pgadmin
      - /srv/servers.json:/pgadmin4/servers.json:ro
      - /srv/config/pgadmin4_pgpass.conf:/srv/pgadmin4_pgpass.cf:ro
    ports:
      - "127.0.0.1:5001:80"
    labels:
      - 'cloudflare.dns.config=type=CNAME,name=pgadmin,content=\${DOMAIN},proxied=true,port=5050,comment=PgAdmin4'

  minio:
    image: minio/minio:latest
    
    container_name: minio
    restart: always
    environment:
      - TZ=America/Sao_Paulo
      - MINIO_ROOT_USER=\${MINIO_USER}
      - MINIO_ROOT_PASSWORD=\${MINIO_PASSWORD}
      - SERVER_URL=https://s3.\${DOMAIN}
    command: server /data --address ":9000" --console-address ":9001"
    volumes:
      - minio_data:/data
    ports:
      - "127.0.0.1:5002:9000"
      - "127.0.0.1:5003:9001"
    labels:
      - 'cloudflare.dns.config=type=CNAME,name=minio,content=\${DOMAIN},proxied=true,port=9001,comment=MinIO S3 Manager'
      - 'cloudflare.dns.config=type=CNAME,name=s3,content=\${DOMAIN},proxied=true,port=9000,comment=MinIO S3 Server'
  redis:
    image: redis:latest
    container_name: redis
    restart: always
    volumes:
      - redis_data:/data
      - /srv/config/redis.acl:/etc/redis/users.acl:ro
    environment:
      - TZ=America/Sao_Paulo
    ports:
      - "127.0.0.1:5004:6379"
    command: >
      redis-server
      --aclfile /etc/redis/users.acl
      --protected-mode yes
      --bind 0.0.0.0

  mailserver:
    image: ghcr.io/docker-mailserver/docker-mailserver:latest
    container_name: mailserver
    hostname: mail
    domainname: \${DOMAIN}
    restart: always
    environment:
      - TZ=America/Sao_Paulo
      - SSL_TYPE=manual
      - SSL_CERT_PATH=/ssl/fullchain.pem
      - SSL_KEY_PATH=/ssl/privkey.pem
      - VIRUSMAILS_DELETE_DELAY=7
      - ENABLE_QUOTAS=1
      - POSTFIX_MAILBOX_SIZE_LIMIT=10240000
      - POSTFIX_MESSAGE_SIZE_LIMIT=10240000
      - CLAMAV_MESSAGE_SIZE_LIMIT=25M
      - REPORT_RECIPIENT=mailserver-report@\${DOMAIN}
      - PERMIT_DOCKER=network
      - SPOOF_PROTECTION=1
      - DMS_DEBUG=1
      - POSTMASTER_ADDRESS=postmaster@\${DOMAIN}
      - ENABLE_UPDATE_CHECK=1
      - UPDATE_CHECK_INTERVAL=1
      - ENABLE_SRS=1
      - ENABLE_OPENDKIM=1
      - ENABLE_OPENDMARC=1
      - ENABLE_POLICYD_SPF=1
      - ENABLE_POP3=1
      - ENABLE_IMAP=1
      - SPAM_SUBJECT=**SPAM**
      - RSPAMD_CHECK_AUTHENTICATED=0
      - RSPAMD_GREYLISTING=1
      - RSPAMD_HFILTER=1
      - RSPAMD_HFILTER_HOSTNAME_UNKNOWN_SCORE=6
      - ENABLE_AMAVIS=1
      - AMAVIS_LOGLEVEL=-1
      - FAIL2BAN_BLOCKTYPE=drop
      - ENABLE_MANAGESIEVE=1
      - POSTSCREEN_ACTION=enforce
      - LOGROTATE_INTERVAL=weekly
      - LOGROTATE_COUNT=4
      - POSTFIX_INET_PROTOCOLS=all
      - ENABLE_MTA_STS=1
      - DOVECOT_INET_PROTOCOLS=all
      - ENABLE_SPAMASSASSIN=1
      - SPAMASSASSIN_SPAM_TO_INBOX=1
      - MOVE_SPAM_TO_JUNK=1
      - ENABLE_POSTGREY=1
      - POSTGREY_DELAY=300
      - POSTGREY_MAX_AGE=7
      - POSTGREY_TEXT="Delayed by Postgrey"
      - POSTGREY_AUTO_WHITELIST_CLIENTS=5
      - ENABLE_SASLAUTHD=0
      - ENABLE_LDAP=0
      - SRS_SENDER_CLASSES=envelope_sender
      - SRS_SECRET=\${MAILSERVER_SRS_SECRET}
      - DEFAULT_RELAY_HOST=[\${SMTP_HOST}]:587
      - RELAY_HOST=\${SMTP_HOST}
      - RELAY_PORT=\${SMTP_PORT}
      - RELAY_USER=\${SMTP_USERNAME}
      - RELAY_PASSWORD=\${SMTP_PASSWORD}
    volumes:
      - mail_data:/var/mail/
      - mail_state:/var/mail-state/
      - mail_logs:/var/log/mail/
      - /etc/localtime:/etc/localtime:ro
      - /srv/certbot/config/live/mail:/ssl
      - /srv/config/postfix-accounts.conf:/tmp/docker-mailserver/postfix-accounts.cf
    stop_grace_period: 1m
    cap_add:
      - NET_ADMIN
    ports:
      - "127.0.0.1:5005:25"
      - "127.0.0.1:5006:143"
      - "127.0.0.1:5007:465"
      - "127.0.0.1:5008:587"
      - "127.0.0.1:5009:993"
      - "127.0.0.1:5010:995"
    labels:
      - 'cloudflare.dns.config=type=A,name=mail,content=\${IPV4},proxied=false,comment=Mail Server'
    mem_limit: 8g
    memswap_limit: 16g

  roundcube:
    image: roundcube/roundcubemail:latest
    container_name: roundcube
    restart: always
    environment:
      - ROUNDCUBEMAIL_DB_TYPE=pgsql
      - ROUNDCUBEMAIL_DB_HOST=postgresql
      - ROUNDCUBEMAIL_DB_PORT=5432
      - ROUNDCUBEMAIL_DB_USER=postgres
      - ROUNDCUBEMAIL_DB_PASSWORD=\${POSTGRES_PASSWORD}
      - ROUNDCUBEMAIL_DB_NAME=roundcubemail
      - ROUNDCUBEMAIL_DEFAULT_HOST=ssl://mail.\${DOMAIN}
      - ROUNDCUBEMAIL_DEFAULT_PORT=993
      - ROUNDCUBEMAIL_SMTP_SERVER=ssl://mail.\${DOMAIN}
      - ROUNDCUBEMAIL_SMTP_PORT=465
      - ROUNDCUBEMAIL_PLUGINS=managesieve,markasjunk
      - OVERWRITEPROTOCOL=https
      - SUBDOMAIN=webmail
    ports:
      - "127.0.0.1:5011:80"
    depends_on:
      - postgresql
      - mailserver
    volumes:
      - roundcube_data:/var/roundcube/config
    labels:
      - 'cloudflare.dns.config=type=CNAME,name=webmail,content=\${DOMAIN},proxied=true,port=8081,comment=Roundcube Webmail'
    mem_limit: 8g
    memswap_limit: 16g

  evolution:
    container_name: evolution
    image:  evoapicloud/evolution-api:latest
    restart: always
    environment:
      - SERVER_URL=https://evolution.\${DOMAIN}
      - LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG,VERBOSE,DARK,WEBHOOKS,WEBSOCKET
      - LOG_COLOR=true
      - LOG_BAILEYS=error
      - EVENT_EMITTER_MAX_LISTENERS=50
      - DEL_INSTANCE=false
      - DATABASE_PROVIDER=postgresql
      - DATABASE_CONNECTION_URI=postgresql://postgres:\${POSTGRES_PASSWORD}@postgresql:5432/evolution?schema=public
      - DATABASE_CONNECTION_CLIENT_NAME=\$(HOST_NAME)
      - DATABASE_SAVE_DATA_INSTANCE=true
      - DATABASE_SAVE_DATA_NEW_MESSAGE=true
      - DATABASE_SAVE_MESSAGE_UPDATE=true
      - DATABASE_SAVE_DATA_CONTACTS=true
      - DATABASE_SAVE_DATA_CHATS=true
      - DATABASE_SAVE_DATA_LABELS=true
      - DATABASE_SAVE_DATA_HISTORIC=true
      - DATABASE_SAVE_IS_ON_WHATSAPP=true
      - DATABASE_SAVE_IS_ON_WHATSAPP_DAYS=90
      - DATABASE_DELETE_MESSAGE=true
      - RABBITMQ_ENABLED=false
      - RABBITMQ_GLOBAL_ENABLED=false
      - SQS_ENABLED=false
      - CONFIG_SESSION_PHONE_CLIENT=EvolutionAPI
      - CONFIG_SESSION_PHONE_NAME=EvolutionAPI
      - QRCODE_LIMIT=60
      - QRCODE_COLOR=#175197
      - WEBSOCKET_ENABLED=true
      - ENABLE_WEBSOCKET_EVENTS=true
      - TYPEBOT_ENABLED=true
      - TYPEBOT_API_VERSION=latest
      - CHATWOOT_ENABLED=true
      - OPENAI_ENABLED=true
      - DIFY_ENABLED=true
      - N8N_ENABLED=true
      - EVOAI_ENABLED=true
      - CACHE_REDIS_ENABLED=false
      - CACHE_LOCAL_ENABLED=false
      - S3_ENABLED=true
      - S3_ACCESS_KEY=\${MINIO_USER}
      - S3_SECRET_KEY=\${MINIO_PASSWORD}
      - S3_BUCKET=evolution
      - S3_PORT=443
      - S3_ENDPOINT=s3.\${DOMAIN}
      - S3_USE_SSL=true
      - VIDEO_UPLOAD_ENABLED=true
      - MEDIA_VIDEO_ENABLED=true
      - S3_SKIP_POLICY=true
      - S3_SAVE_VIDEO=true
      - S3_SAVE_AUDIO=true
      - MAX_FILE_SIZE=51200000
      - LANGUAGE=pt-BR
      - AUTHENTICATION_API_KEY=\${EVOLUTION_API_KEY}
      - SERVER_PORT=8080
      - WEBHOOK_GLOBAL_URL=https://\${DOMAIN}/webhook/chatapp_webhook
      - WEBHOOK_GLOBAL_ENABLED=false
      - WEBHOOK_EVENTS_APPLICATION_STARTUP=false
      - WEBHOOK_EVENTS_QRCODE_UPDATED=false
      - WEBHOOK_EVENTS_MESSAGES_SET=false
      - WEBHOOK_EVENTS_MESSAGES_UPSERT=true
      - WEBHOOK_EVENTS_MESSAGES_UPDATE=false
      - WEBHOOK_EVENTS_MESSAGES_DELETE=true
      - WEBHOOK_EVENTS_SEND_MESSAGE=false
      - WEBHOOK_EVENTS_CONTACTS_SET=false
      - WEBHOOK_EVENTS_CONTACTS_UPSERT=false
      - WEBHOOK_EVENTS_CONTACTS_UPDATE=false
      - WEBHOOK_EVENTS_PRESENCE_UPDATE=false
      - WEBHOOK_EVENTS_CHATS_SET=false
      - WEBHOOK_EVENTS_CHATS_UPSERT=false
      - WEBHOOK_EVENTS_CHATS_UPDATE=false
      - WEBHOOK_EVENTS_CHATS_DELETE=false
      - WEBHOOK_EVENTS_GROUPS_UPSERT=false
      - WEBHOOK_EVENTS_GROUPS_UPDATE=false
      - WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE=false
      - WEBHOOK_EVENTS_CONNECTION_UPDATE=false
      - WEBHOOK_EVENTS_LABELS_EDIT=false
      - WEBHOOK_EVENTS_LABELS_ASSOCIATION=false
      - WEBHOOK_EVENTS_CALL=true
      - WEBHOOK_EVENTS_NEW_JWT_TOKEN=false
      - WEBHOOK_EVENTS_TYPEBOT_START=false
      - WEBHOOK_EVENTS_TYPEBOT_CHANGE_STATUS=false
      - WEBHOOK_EVENTS_CHAMA_AI_ACTION=false
      - WEBHOOK_EVENTS_ERRORS=false
      - WEBHOOK_EVENTS_ERRORS_WEBHOOK=false
      - MEDIA_UPLOAD=true
      - WA_BUSINESS_URL=https://graph.facebook.com
      - WA_BUSINESS_VERSION=v22.0
      - WA_BUSINESS_LANGUAGE=pt_BR
      - TELEMETRY=false
    depends_on:
      - postgresql
    ports:
      - "127.0.0.1:5012:8080"
    volumes:
      - evolution_data:/app
    dns:
      - 8.8.8.8
      - 8.8.4.4
    labels:
      - 'cloudflare.dns.config=type=CNAME,name=evolution,content=\${DOMAIN},proxied=true,port=9002,comment=Evolution API'

  typebot_builder:
    image: baptistearno/typebot-builder:latest
    container_name: typebot_builder
    ports:
      - "127.0.0.1:5013:3000"
    restart: always
    environment:
      - DATABASE_URL=postgresql://postgres:\${POSTGRES_PASSWORD}@postgresql:5432/typebot
      - NEXTAUTH_URL=https://typebot.\${DOMAIN}
      - NEXT_PUBLIC_VIEWER_URL=https://bot.\${DOMAIN}
      - ENCRYPTION_SECRET=\${TYPEBOT_SECRET}
      - ADMIN_EMAIL=\${TYPEBOT_ADMIN_EMAIL}
      - SMTP_HOST=\${MAIL_DOMAIN}
      - SMTP_USERNAME=\${TYPEBOT_SMTP_USERNAME}
      - SMTP_PASSWORD=\${TYPEBOT_SMTP_PASSWORD}
      - SMTP_PORT=\${MAIL_PORT}
      - NEXT_PUBLIC_SMTP_FROM=Typebot <typebot@\${DOMAIN}>
      - SMTP_SECURE=true
      - SMTP_AUTH_DISABLED=false
      - GITHUB_CLIENT_ID=\${TYPEBOT_GITHUB_CLIENT_ID}
      - GITHUB_CLIENT_SECRET=\${TYPEBOT_GITHUB_CLIENT_SECRET}
      - S3_ACCESS_KEY=\${MINIO_USER}
      - S3_SECRET_KEY=\${MINIO_PASSWORD}
      - S3_BUCKET=typebot
      - S3_PORT=9000
      - S3_ENDPOINT=minio
      - S3_SSL=false
      - SUBDOMAIN=typebot
    depends_on:
      - postgresql
      - minio
    labels:
      - 'cloudflare.dns.config=type=CNAME,name=typebot,content=\${DOMAIN},proxied=true,port=8001,comment=TypeBot Builder'
    mem_limit: 8g
    memswap_limit: 16g

  typebot_viewer:
    image: baptistearno/typebot-viewer:latest
    container_name: typebot_viewer
    ports:
      - "127.0.0.1:5014:3000"
    restart: always
    environment:
      - DATABASE_URL=postgresql://postgres:\${POSTGRES_PASSWORD}@postgresql:5432/typebot
      - NEXTAUTH_URL=https://typebot.\${DOMAIN}
      - NEXT_PUBLIC_VIEWER_URL=https://bot.\${DOMAIN}
      - ENCRYPTION_SECRET=\${TYPEBOT_SECRET}
      - ADMIN_EMAIL=\${TYPEBOT_ADMIN_EMAIL}
      - SMTP_HOST=\${MAIL_DOMAIN}
      - SMTP_USERNAME=\${TYPEBOT_SMTP_USERNAME}
      - SMTP_PASSWORD=\${TYPEBOT_SMTP_PASSWORD}
      - SMTP_PORT=\${MAIL_PORT}
      - NEXT_PUBLIC_SMTP_FROM=Typebot <typebot@\${DOMAIN}>
      - SMTP_SECURE=true
      - SMTP_AUTH_DISABLED=false
      - GITHUB_CLIENT_ID=\${TYPEBOT_GITHUB_CLIENT_ID}
      - GITHUB_CLIENT_SECRET=\${TYPEBOT_GITHUB_CLIENT_SECRET}
      - S3_ACCESS_KEY=\${MINIO_USER}
      - S3_SECRET_KEY=\${MINIO_PASSWORD}
      - S3_BUCKET=typebot
      - S3_PORT=9000
      - S3_ENDPOINT=minio
      - S3_SSL=false
      - SUBDOMAIN=bot
    depends_on:
      - postgresql
      - minio
    labels:
      - 'cloudflare.dns.config=type=CNAME,name=bot,content=\${DOMAIN},proxied=true,port=8002,comment=TypeBot Viewer'
    mem_limit: 8g
    memswap_limit: 16g

  n8n:
    image: docker.n8n.io/n8nio/n8n:beta
    container_name: n8n
    restart: always
    ports:
      - "127.0.0.1:5015:5678"
    environment:
      - TZ=America/Sao_Paulo
      - N8N_SECURE_COOKIE=false
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_HOST=postgresql
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_SCHEMA=public
      - DB_POSTGRESDB_PASSWORD=\${POSTGRES_PASSWORD}
      - N8N_ENCRYPTION_KEY=\${N8N_ENCRYPTION_KEY}
      - WEBHOOK_URL=https://n8n.\${DOMAIN}
      - N8N_EXTERNAL_STORAGE_S3_HOST=minio:9000
      - N8N_EXTERNAL_STORAGE_S3_BUCKET_NAME=n8n
      - N8N_EXTERNAL_STORAGE_S3_BUCKET_REGION=us-east-1
      - N8N_EXTERNAL_STORAGE_S3_ACCESS_KEY=\${MINIO_USER}
      - N8N_EXTERNAL_STORAGE_S3_ACCESS_SECRET=\${MINIO_PASSWORD}
      - N8N_PAYLOAD_SIZE_MAX=1000000000000
      - WORKFLOWS_DEFAULT_NAME=Workflow
      - N8N_RUNNERS_ENABLED=true
      - N8N_EMAIL_MODE=smtp
      - N8N_SMTP_HOST=\${MAIL_DOMAIN}
      - N8N_SMTP_PORT=\${MAIL_PORT}
      - N8N_SMTP_USER=\${N8N_SMTP_USERNAME}
      - N8N_SMTP_PASS=\${N8N_SMTP_PASSWORD}
      - N8N_SMTP_SENDER="N8N <n8n@\${DOMAIN}>"
      - N8N_SMTP_SSL=false
    volumes:
      - n8n_data:/home/node/.n8n
      - /srv/.env:/home/node/.n8n/.env
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - postgresql
      - minio
    labels:
      - 'cloudflare.dns.config=type=CNAME,name=n8n,content=\${DOMAIN},proxied=true,port=5678,comment=N8N Workflow Manager'
    mem_limit: 8g
    memswap_limit: 16g

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/postgres_data

  pgadmin_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/pgadmin_data

  minio_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/minio_data

  redis_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/redis_data

  mail_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/mail_data/data

  mail_state:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/mail_data/state

  mail_logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/mail_data/logs

  n8n_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/n8n_data

  roundcube_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/roundcube_data

  evolution_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/evolution_data
EOL

source /srv/.env
bash ./docker-cloudflare.sh

############################################
# RCLONE BACKUP MANAGEMENT
############################################
curl https://rclone.org/install.sh | sudo bash > /dev/null 2>&1

cat <<EOF > /srv/config/rclone.conf
[owncloud]
type = webdav
url = https://${OWNCLOUD_HOST}/remote.php/webdav/
vendor = owncloud
user = ${OWNCLOUD_USERNAME}
pass = $(rclone obscure ${OWNCLOUD_PASSWORD})
EOF

rm -f /root/.config/rclone/rclone.conf
chmod 600 /srv/config/rclone.conf
ln -sf /srv/config/rclone.conf /root/.config/rclone/rclone.conf

############################################
# NGINX + MODSECURITY + FAIL2BAN
############################################
apt install -y nginx fail2ban goaccess

rm -rf /etc/nginx/conf.d/*

cp -r /etc/nginx /srv/nginx
ln -sf /srv/nginx /etc/nginx
systemctl enable nginx
systemctl start nginx

############################################
# FAIL2BAN ALERT WHATSAPP + EMAIL
############################################
cat > /srv/scripts/fail2ban-dual-alert.sh <<'EOF'
#!/bin/bash
IP="$1"
JAIL="$2"
source /srv/.env
MSG="🚨 FAIL2BAN\nIP: $IP\nJail: $JAIL\nHost: $(hostname)"
curl -s -X POST "https://api.z-api.io/instances/${ZAPI_INSTANCE_ID}/token/${ZAPI_INSTANCE_TOKEN}/send-text" \
  -H "Client-Token: ${ZAPI_INSTANCE_SECRET}" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"${ADMIN_PHONE}\",\"message\":\"${MSG}\"}" >/dev/null

echo -e "Subject: Fail2Ban Alert\n\n${MSG}" | sendmail \
  -S "${SMTP_HOST}:${SMTP_PORT}" \
  -au"${SMTP_USERNAME}" \
  -ap"${SMTP_PASSWORD}" \
  "${ADMIN_EMAIL}"
EOF

chmod +x /srv/scripts/fail2ban-dual-alert.sh

cat > /etc/fail2ban/action.d/dual-alert.conf <<EOF
[Definition]
actionban = /srv/scripts/fail2ban-dual-alert.sh <ip> <name>
EOF

sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sed -i '/\[DEFAULT\]/a banaction = dual-alert' /etc/fail2ban/jail.local
systemctl restart fail2ban

############################################
# CERTBOT WILDCARD (CLOUDFLARE)
############################################
mkdir -p /srv/certbot/cloudflare
cat > /srv/certbot/cloudflare/cloudflare.ini <<EOF
dns_cloudflare_email = ${CLOUDFLARE_EMAIL}
dns_cloudflare_api_key = ${CLOUDFLARE_API_KEY}
dns_cloudflare_zone_id = ${CLOUDFLARE_ZONE_ID}
EOF
chmod 600 /srv/certbot/cloudflare/cloudflare.ini

certbot certonly --non-interactive --agree-tos \
  --email "$ADMIN_EMAIL" \
  --dns-cloudflare \
  --dns-cloudflare-credentials /srv/certbot/cloudflare/cloudflare.ini \
  --config-dir /srv/certbot/config \
  --work-dir /srv/certbot \
  --logs-dir /srv/certbot/logs \
  -d "$DOMAIN" -d "*.$DOMAIN"

sudo apt autoremove -y

############################################
# FIREWALLD (EASYDEV + DOCKER TRUSTED)
############################################
apt install -y firewalld

systemctl enable firewalld
systemctl start firewalld

# Criar zona easydev (se não existir)
firewall-cmd --permanent --new-zone=easydev || true

# Liberar serviços essenciais
firewall-cmd --permanent --zone=easydev --add-service=ssh
firewall-cmd --permanent --zone=easydev --add-service=http
firewall-cmd --permanent --zone=easydev --add-service=https

# Descobrir interface principal automaticamente
MAIN_IFACE=$(ip route | awk '/default/ {print $5; exit}')

# Associar interface à zona easydev
firewall-cmd --permanent --zone=easydev --change-interface="$MAIN_IFACE"

# Docker totalmente livre (zona trusted)
firewall-cmd --permanent --zone=trusted --add-interface=docker0

# Liberar redes Docker (bridge padrão + custom)
firewall-cmd --permanent --zone=trusted --add-source=172.17.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=172.18.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=172.19.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=172.20.0.0/14

# Definir easydev como padrão
firewall-cmd --set-default-zone=easydev

# Aplicar regras
firewall-cmd --reload

# Status
echo "🔥 FIREWALLD STATUS"
firewall-cmd --get-active-zones
firewall-cmd --zone=easydev --list-all
firewall-cmd --zone=trusted --list-all

############################################
# Configurear E-mail Postfix + Dovecot
cat <<EOF > /srv/config/postfix-accounts.conf
postmaster@${DOMAIN}$(doveadm pw -s ARGON2ID -p "${ADMIN_PASSWORD}")
admin@${DOMAIN}$(doveadm pw -s ARGON2ID -p "${ADMIN_PASSWORD}")
n8n@${DOMAIN}$(doveadm pw -s ARGON2ID -p "${ADMIN_PASSWORD}")
typebot@${DOMAIN}$(doveadm pw -s ARGON2ID -p "${ADMIN_PASSWORD}")
EOF
chmod 600 /srv/config/postfix-accounts.conf


# Redis ACL
cat <<EOF > /srv/config/redis.acl
user admin on >Admin@Strong2026! ~* +@all
user default off
EOF

cat <<EOF > /srv/config/pgadmin4_pgpass.conf
postgresql:5432:postgres:postgres:${POSTGRES_PASSWORD}
EOF
chmod 600 /srv/config/pgadmin4_pgpass.conf

cat <<EOF > /srv/servers.json
{
  "Servers": {
    "1": {
      "Name": "Local Server",
      "Group": "Local Servers",
      "Host": "postgresql",
      "Port": 5432,
      "Username": "postgres",
      "SSLMode": "prefer",
      "Password": "${POSTGRES_PASSWORD}",
      "MaintenanceDB": "postgres",
      "PassFile": "/pgadmin4/pgpass"
    }
  }
}
EOF

cat <<EOF > /srv/pgsql-init.sql
-- Typebot --
CREATE DATABASE typebot OWNER postgres;
\c typebot
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
ALTER DATABASE typebot SET timezone TO 'America/Sao_Paulo';

-- Evolution --
CREATE DATABASE evolution OWNER postgres;
\c evolution
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
ALTER DATABASE evolution SET timezone TO 'America/Sao_Paulo';

-- Roundcube --
CREATE DATABASE roundcubemail OWNER postgres;
\c roundcubemail
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
ALTER DATABASE roundcubemail SET timezone TO 'America/Sao_Paulo';

-- N8N --
CREATE DATABASE n8n OWNER postgres;
\c n8n
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
ALTER DATABASE n8n SET timezone TO 'America/Sao_Paulo';
EOF


docker compose up -d
############################################
# FINAL
############################################
echo "✅ Provisionamento concluído com sucesso
🔑 Admin Email: $ADMIN_EMAIL
🌐 Domain: $DOMAIN
📅 Timezone: $TZ
🆔 Server ID: ${SERVER_IDENTIFIER}"

echo "🚀 Server is ready!"