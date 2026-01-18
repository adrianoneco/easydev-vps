# Cloudflare DNS Manager & Docker Compose Setup

Script bash para gerenciar registros DNS na Cloudflare e configurar ambiente multi-serviços.

## Requisitos

- `bash` shell
- `curl` instalado
- `jq` instalado (para parsing JSON)
- `docker` e `docker-compose`
- Credenciais da Cloudflare
- Credenciais de serviços externos (SMTP, APIs, etc)

## Configuração Inicial

### Script de Instalação (run.sh)

Use o script `run.sh` para configurar todos os serviços de uma vez:

```bash
#!/bin/bash
chmod +x install.sh
sudo ./install.sh \
  --timezone="TIMEZONE" \
  --domain="DOMINIO" \
  --admin-name="NOME_ADMIN" \
  --admin-email="EMAIL_ADMIN" \
  --admin-password="SENHA_ADMIN" \
  --admin-phone="TELEFONE_ADMIN" \
  --smtp-host="HOST_SMTP" \
  --smtp-port="PORTA_SMTP" \
  --smtp-username="USUARIO_SMTP" \
  --smtp-password="SENHA_SMTP" \
  --cloudflare-email="EMAIL_CLOUDFLARE" \
  --cloudflare-api-key="API_KEY_CLOUDFLARE" \
  --cloudflare-zone-id="ZONE_ID_CLOUDFLARE" \
  --docker-username="USUARIO_DOCKER" \
  --docker-api-token="TOKEN_DOCKER" \
  --zapi-instance-id="INSTANCE_ID_ZAPI" \
  --zapi-instance-token="TOKEN_ZAPI" \
  --zapi-instance-secret="SECRET_ZAPI" \
  --owncloud-host="HOST_OWNCLOUD" \
  --owncloud-username="USUARIO_OWNCLOUD" \
  --owncloud-password="SENHA_OWNCLOUD" \
  --typebot-github-client-id="CLIENT_ID_GITHUB" \
  --typebot-github-client-secret="CLIENT_SECRET_GITHUB" \
  --asaas-environment="AMBIENTE_ASAAS" \
  --asaas-api-key="API_KEY_ASAAS"
```

### Parâmetros de Configuração

| Parâmetro | Descrição | Exemplo |
|-----------|-----------|---------|
| `timezone` | Fuso horário | `America/Sao_Paulo` |
| `domain` | Domínio principal | `example.com.br` |
| `admin-name` | Nome do administrador | `João Silva` |
| `admin-email` | Email do admin | `admin@example.com` |
| `admin-password` | Senha do admin | Caracteres especiais recomendados |
| `admin-phone` | Telefone | `+55 41 99999-9999` |
| `smtp-host` | Host SMTP | `smtp-relay.brevo.com` |
| `smtp-port` | Porta SMTP | `587` |
| `smtp-username` | Usuário SMTP | `seu_usuario@smtp` |
| `smtp-password` | Senha SMTP | Token gerado no serviço |
| `cloudflare-email` | Email Cloudflare | `user@example.com` |
| `cloudflare-api-key` | API Key Cloudflare | Obtido no dashboard |
| `cloudflare-zone-id` | Zone ID Cloudflare | Obtido no dashboard |
| `docker-username` | Usuário Docker Hub | `seu_usuario` |
| `docker-api-token` | Token Docker Hub | `dckr_pat_xxxxx` |
| `zapi-instance-id` | Instance ID Z-API | Obtido na plataforma |
| `zapi-instance-token` | Token Z-API | Token gerado |
| `zapi-instance-secret` | Secret Z-API | Secret gerado |
| `owncloud-host` | Host OwnCloud | `drive.example.com` |
| `owncloud-username` | Usuário OwnCloud | `usuario` |
| `owncloud-password` | Senha OwnCloud | Senha segura |
| `typebot-github-client-id` | GitHub Client ID | `Iv23liXXXXXXXXXXXX` |
| `typebot-github-client-secret` | GitHub Client Secret | `abcd1234efgh5678` |
| `asaas-environment` | Ambiente ASAAS | `sandbox` ou `production` |
| `asaas-api-key` | API Key ASAAS | `$aact_xxxx` |

### Arquivo .env Alternativo

Você pode também criar um arquivo `.env` com todas as variáveis:

```bash
# Configurações de Timezone e Domínio
TIMEZONE=America/Sao_Paulo
DOMAIN=example.com.br

# Admin
ADMIN_NAME=João Silva
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=SenhaForte@123
ADMIN_PHONE=+5541999999999

# SMTP
MAIL_DOMAIN=smtp-relay.brevo.com
MAIL_PORT=587
SMTP_USERNAME=usuario@smtp
SMTP_PASSWORD=sua_senha_smtp

# Cloudflare
CLOUDFLARE_EMAIL=seu_email@cloudflare.com
CLOUDFLARE_API_KEY=sua_api_key
CLOUDFLARE_ZONE_ID=seu_zone_id

# Docker
DOCKER_USERNAME=seu_usuario_docker
DOCKER_API_TOKEN=seu_token_docker

# Z-API
ZAPI_INSTANCE_ID=seu_instance_id
ZAPI_INSTANCE_TOKEN=seu_token
ZAPI_INSTANCE_SECRET=seu_secret

# OwnCloud
OWNCLOUD_HOST=drive.example.com
OWNCLOUD_USERNAME=usuario
OWNCLOUD_PASSWORD=senha

# TypeBot
TYPEBOT_GITHUB_CLIENT_ID=seu_client_id
TYPEBOT_GITHUB_CLIENT_SECRET=seu_client_secret

# ASAAS
ASAAS_ENVIRONMENT=sandbox
ASAAS_API_KEY=sua_api_key

# PostgreSQL
POSTGRES_PASSWORD=senha_postgres

# MinIO
MINIO_USER=minioadmin
MINIO_PASSWORD=senha_minio

# Redis
REDIS_PASSWORD=senha_redis

# Evolution API
EVOLUTION_API_KEY=sua_api_key

# N8N
N8N_ENCRYPTION_KEY=sua_chave_encriptacao

# TypeBot
TYPEBOT_SECRET=seu_secret
TYPEBOT_ADMIN_EMAIL=admin@typebot.com
TYPEBOT_SMTP_USERNAME=typebot@smtp
TYPEBOT_SMTP_PASSWORD=senha_typebot
```

## Execução

```bash
# Executar o script de instalação
bash run.sh

# Ou executar manualmente
chmod +x install.sh
sudo ./install.sh --timezone="America/Sao_Paulo" --domain="example.com.br" ...
```

## Gerenciamento de DNS (cloudflare.sh)

### Requisitos

- `bash` shell
- `curl` instalado
- `jq` instalado (para parsing JSON)
- Credenciais da Cloudflare

### Configuração

Crie ou edite o arquivo `.env`:

```bash
CLOUDFLARE_EMAIL=seu_email@example.com
CLOUDFLARE_API_KEY=sua_api_key_aqui
CLOUDFLARE_ZONE_ID=seu_zone_id_aqui
DOMAIN=seu_domain.com
```

### Uso

#### Carregar o Script

```bash
source cloudflare.sh
```

### Funções Disponíveis

#### 1. Registros A (IPv4)

**Criar:**
```bash
add_a_record "subdomain" "192.168.1.1" true
# Parâmetros: nome, IP, proxied (true/false)
```

**Atualizar:**
```bash
update_a_record "record_id" "subdomain" "192.168.1.2" false
```

#### 2. Registros AAAA (IPv6)

**Criar:**
```bash
add_aaaa_record "subdomain" "2001:db8::1" true
```

**Atualizar:**
```bash
update_aaaa_record "record_id" "subdomain" "2001:db8::2" false
```

#### 3. Registros CNAME

**Criar:**
```bash
add_cname_record "www" "example.com" true
```

**Atualizar:**
```bash
update_cname_record "record_id" "www" "example.com" false
```

#### 4. Registros MX (Email)

```bash
add_mx_record "example.com" "mail.example.com" 10
# Parâmetros: nome, servidor de mail, prioridade
```

#### 5. Registros TXT (SPF, DKIM, DMARC)

```bash
add_txt_record "example.com" "v=spf1 ip4:192.168.1.1 -all"
add_txt_record "_dmarc" "v=DMARC1; p=reject"
```

#### 6. Listar Registros DNS

```bash
list_dns_records
# Lista todos os registros da zona
```

#### 7. Buscar ID de Registro

```bash
get_record_id "subdomain.example.com"
# Retorna o ID do registro
```

#### 8. Deletar Registro

```bash
delete_record "record_id"
```

#### 9. Auto-Fix Server (Configuração Automática)

```bash
auto_fix_server "example.com"
```

**Cria automaticamente:**
- Registro A para `mail.example.com` (IPv4 público)
- Registro AAAA para `example.com` (IPv6 público)
- CNAME `www` → `example.com`
- Registro MX
- Registros TXT (SPF, DMARC, DKIM placeholder)

### Exemplos Práticos

#### Configurar Email Server

```bash
source cloudflare.sh

# Obter IPs públicos
IPV4=$(curl -s https://ipv4.icanhazip.com)
IPV6=$(curl -s https://ipv6.icanhazip.com)

# Criar registros de email
add_a_record "mail" "$IPV4" false
add_aaaa_record "mail" "$IPV6" true
add_mx_record "example.com" "mail.example.com" 10
add_txt_record "example.com" "v=spf1 ip4:${IPV4} -all"
```

#### Atualizar Subdomain

```bash
# 1. Encontrar ID do registro
RECORD_ID=$(get_record_id "subdomain.example.com")

# 2. Atualizar com novo IP
update_a_record "$RECORD_ID" "subdomain.example.com" "203.0.113.5" true
```

#### Deletar Registro

```bash
# 1. Listar registros
list_dns_records

# 2. Copiar o ID desejado e deletar
delete_record "abc123def456"
```

## Docker Compose Integration

Use com seu `docker-compose.yml`:

```yaml
labels:
  - 'cloudflare.dns.config=type=CNAME,name=bot,content=${DOMAIN},proxied=true,comment=TypeBot Viewer'
```

Depois execute:

```bash
bash cloudflare.sh
```

## Troubleshooting

### Erro: "CLOUDFLARE_EMAIL not set"

```bash
# Certifique-se que o arquivo .env existe e está carregado
source /srv/.env
# ou
export CLOUDFLARE_EMAIL="seu_email@example.com"
```

### Erro: "curl not found"

```bash
# Instalar curl
apt-get install curl
```

### Erro: "jq not found"

```bash
# Instalar jq
apt-get install jq
```

### Verificar Credenciais

```bash
# Testar conexão com a API
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" | jq '.success'
```

## Segurança

⚠️ **IMPORTANTE:**
- Nunca compartilhe suas **API Keys** e **Tokens**
- Não commita o arquivo `.env` no Git
- Mude as senhas padrão após a instalação
- Use `.gitignore` para proteger credenciais:

```bash
# .gitignore
.env
.env.local
*.env
/srv/
/volumes/
run.sh
```

- Gere senhas fortes com caracteres especiais
- Revise permissões dos arquivos:

```bash
chmod 600 .env
chmod 755 *.sh
```

## Referência da API Cloudflare

- [API Docs](https://developers.cloudflare.com/api/)
- [DNS Records](https://developers.cloudflare.com/api/operations/dns-records-list-dns-records)
- [Authentication](https://developers.cloudflare.com/api/operations/user-api-token-verify-token)

## Estrutura de Portas

O docker-compose usa portas sequenciais começando em 5000:

| Serviço | Porta Host |
|---------|-----------|
| PostgreSQL | 5000 |
| PgAdmin | 5001 |
| MinIO (S3) | 5002 |
| MinIO (Console) | 5003 |
| Redis | 5004 |
| Mailserver (SMTP) | 5005 |
| Mailserver (IMAP) | 5006 |
| Mailserver (SMTPS) | 5007 |
| Mailserver (Submission) | 5008 |
| Mailserver (IMAPS) | 5009 |
| Mailserver (POP3S) | 5010 |
| Roundcube | 5011 |
| Evolution API | 5012 |
| TypeBot Builder | 5013 |
| TypeBot Viewer | 5014 |
| N8N | 5015 |

## Licença

MIT

## Autor

Script de gerenciamento Docker Compose, Cloudflare DNS e ambiente multi-serviços
