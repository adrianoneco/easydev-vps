#!/bin/bash
source /srv/.env
# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validation
if [ -z "$CLOUDFLARE_EMAIL" ]; then
    echo -e "${RED}✗ Error: CLOUDFLARE_EMAIL not set${NC}"
    exit 1
fi

if [ -z "$CLOUDFLARE_API_KEY" ]; then
    echo -e "${RED}✗ Error: CLOUDFLARE_API_KEY not set${NC}"
    exit 1
fi

if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
    echo -e "${RED}✗ Error: CLOUDFLARE_ZONE_ID not set${NC}"
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}✗ Error: DOMAIN not set${NC}"
    exit 1
fi

echo -e "${BLUE}=== Cloudflare Auto Sync ===${NC}"
echo "Email: $CLOUDFLARE_EMAIL"
echo "Domain: $DOMAIN"
echo ""

# Function to get existing DNS records
get_existing_records() {
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?per_page=100" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json" | jq -r '.result[] | "\(.name)|\(.id)|\(.type)|\(.content)"'
}

# Function to create DNS record
create_dns_record() {
    local type="$1"
    local name="$2"
    local content="$3"
    local proxied="$4"
    
    echo -e "${YELLOW}  → Creating: $name ($type)${NC}"
    
    local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\": \"$type\",
            \"name\": \"$name\",
            \"content\": \"$content\",
            \"ttl\": 1,
            \"proxied\": $proxied
        }")
    
    if echo "$response" | grep -q '"success":true'; then
        echo -e "${GREEN}  ✓ Created successfully${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to create${NC}"
        echo "$response" | jq '.'
        return 1
    fi
}

# Function to update DNS record
update_dns_record() {
    local record_id="$1"
    local type="$2"
    local name="$3"
    local content="$4"
    local proxied="$5"
    
    echo -e "${YELLOW}  → Updating: $name ($type)${NC}"
    
    local response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$record_id" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\": \"$type\",
            \"name\": \"$name\",
            \"content\": \"$content\",
            \"ttl\": 1,
            \"proxied\": $proxied
        }")
    
    if echo "$response" | grep -q '"success":true'; then
        echo -e "${GREEN}  ✓ Updated successfully${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to update${NC}"
        return 1
    fi
}

# Extract and process labels from docker-compose
process_docker_labels() {
    echo -e "${BLUE}Processing docker-compose.yml labels...${NC}"
    
    # Get existing records
    local existing_records=$(get_existing_records)
    
    # Extract labels from docker-compose
    grep -E "cloudflare\.dns\.config" /srv/docker-compose.yml | sed "s/.*- '//; s/'$//" | while read -r label; do
        # Parse label
        local type=$(echo "$label" | grep -oP 'type=\K[^,]+')
        local name=$(echo "$label" | grep -oP 'name=\K[^,]+')
        local content=$(echo "$label" | grep -oP 'content=\K[^,}]+')
        local proxied=$(echo "$label" | grep -oP 'proxied=\K[^,}]+' | tr '[:upper:]' '[:lower:]')
        local comment=$(echo "$label" | grep -oP 'comment=\K[^,}]+')
        
        # Add domain suffix if needed
        local full_name="${name}.${DOMAIN}"
        
        # Replace variable if present
        content="${content//\$\{DOMAIN\}/$DOMAIN}"
        
        echo ""
        echo -e "${BLUE}Label: $comment${NC}"
        echo "  Type: $type | Name: $full_name | Content: $content | Proxied: $proxied"
        
        # Check if record exists
        local record_id=$(echo "$existing_records" | grep "^${full_name}|" | cut -d'|' -f2)
        
        if [ -z "$record_id" ]; then
            create_dns_record "$type" "$full_name" "$content" "$proxied"
        else
            update_dns_record "$record_id" "$type" "$full_name" "$content" "$proxied"
        fi
        
        sleep 0.5
    done
}

# Main execution
process_docker_labels

echo ""
echo -e "${GREEN}=== Sync completed! ===${NC}"
echo ""