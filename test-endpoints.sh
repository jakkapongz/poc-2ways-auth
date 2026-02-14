#!/bin/bash

# Test script for mutual TLS endpoints

CERT="./certs/client-cert.pem"
KEY="./certs/client-key.pem"
CA="./certs/ca-cert.pem"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Testing Mutual TLS Authentication ==="
echo ""

# Test 1: Via Apache HTTPD
echo -e "${YELLOW}Test 1: Testing via Apache HTTPD (https://localhost:443)${NC}"
echo "---"

echo "1. GET /api/hello"
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost/api/hello | jq .
echo ""

echo "2. GET /api/info"
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost/api/info | jq .
echo ""

echo "3. GET /api/status"
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost/api/status | jq .
echo ""

# Test 2: Directly to Spring Boot
echo -e "${YELLOW}Test 2: Testing Spring Boot directly (https://localhost:8443)${NC}"
echo "---"

echo "1. GET /api/hello"
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost:8443/api/hello | jq .
echo ""

# Test 3: Without client certificate (should fail)
echo -e "${YELLOW}Test 3: Testing without client certificate (should fail)${NC}"
echo "---"

echo "Attempting connection without client certificate..."
if curl -s --cacert $CA https://localhost/api/hello 2>&1 | grep -q "SSL"; then
    echo -e "${GREEN}✓ Correctly rejected - SSL error as expected${NC}"
else
    echo -e "${RED}✗ Unexpected response - should have failed${NC}"
fi
echo ""

# Test 4: Health check (no auth required)
echo -e "${YELLOW}Test 4: Testing health endpoint (no auth required)${NC}"
echo "---"

echo "GET /actuator/health"
curl -s -k https://localhost:8443/actuator/health | jq .
echo ""

echo "=== Tests Complete ==="
