#!/bin/bash

# Portainer Stack Deployment Script
# Automates deployment via Portainer API

set -e

# Configuration
PORTAINER_URL="${PORTAINER_URL:-http://localhost:9000}"
PORTAINER_API_KEY="${PORTAINER_API_KEY}"
STACK_NAME="${STACK_NAME:-privateness-network}"
STACK_FILE="${STACK_FILE:-portainer-stack.yml}"
ENDPOINT_ID="${ENDPOINT_ID:-1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Privateness Network - Portainer Deployment${NC}"
echo "=============================================="

# Check prerequisites
if [ -z "$PORTAINER_API_KEY" ]; then
    echo -e "${RED}Error: PORTAINER_API_KEY not set${NC}"
    echo "Get your API key from Portainer: User → My account → API tokens"
    exit 1
fi

if [ ! -f "$STACK_FILE" ]; then
    echo -e "${RED}Error: Stack file not found: $STACK_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking Portainer connection...${NC}"
if ! curl -s -f -H "X-API-Key: $PORTAINER_API_KEY" "$PORTAINER_URL/api/status" > /dev/null; then
    echo -e "${RED}Error: Cannot connect to Portainer at $PORTAINER_URL${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Portainer${NC}"

# Check if stack exists
STACK_ID=$(curl -s -H "X-API-Key: $PORTAINER_API_KEY" \
    "$PORTAINER_URL/api/stacks" | \
    jq -r ".[] | select(.Name==\"$STACK_NAME\") | .Id")

if [ -n "$STACK_ID" ]; then
    echo -e "${YELLOW}Stack '$STACK_NAME' already exists (ID: $STACK_ID)${NC}"
    read -p "Update existing stack? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Updating stack...${NC}"
        
        RESPONSE=$(curl -s -X PUT \
            -H "X-API-Key: $PORTAINER_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"StackFileContent\": $(jq -Rs . < "$STACK_FILE"),
                \"Env\": [],
                \"Prune\": false,
                \"PullImage\": true
            }" \
            "$PORTAINER_URL/api/stacks/$STACK_ID?endpointId=$ENDPOINT_ID")
        
        if echo "$RESPONSE" | jq -e '.Id' > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Stack updated successfully${NC}"
        else
            echo -e "${RED}Error updating stack:${NC}"
            echo "$RESPONSE" | jq .
            exit 1
        fi
    else
        echo "Deployment cancelled"
        exit 0
    fi
else
    echo -e "${YELLOW}Creating new stack '$STACK_NAME'...${NC}"
    
    RESPONSE=$(curl -s -X POST \
        -H "X-API-Key: $PORTAINER_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"Name\": \"$STACK_NAME\",
            \"StackFileContent\": $(jq -Rs . < "$STACK_FILE"),
            \"Env\": [],
            \"FromAppTemplate\": false
        }" \
        "$PORTAINER_URL/api/stacks?type=2&method=string&endpointId=$ENDPOINT_ID")
    
    if echo "$RESPONSE" | jq -e '.Id' > /dev/null 2>&1; then
        STACK_ID=$(echo "$RESPONSE" | jq -r '.Id')
        echo -e "${GREEN}✓ Stack created successfully (ID: $STACK_ID)${NC}"
    else
        echo -e "${RED}Error creating stack:${NC}"
        echo "$RESPONSE" | jq .
        exit 1
    fi
fi

# Wait for deployment
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 5

# Check stack status
STACK_STATUS=$(curl -s -H "X-API-Key: $PORTAINER_API_KEY" \
    "$PORTAINER_URL/api/stacks/$STACK_ID" | jq -r '.Status')

echo ""
echo -e "${GREEN}Deployment Summary${NC}"
echo "==================="
echo "Stack Name: $STACK_NAME"
echo "Stack ID: $STACK_ID"
echo "Status: $STACK_STATUS"
echo ""
echo -e "${GREEN}Access Points:${NC}"
echo "  Emercoin RPC: http://localhost:6662"
echo "  I2P Console: http://localhost:7657"
echo "  Privateness: http://localhost:8080"
echo "  Portainer: $PORTAINER_URL"
echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
