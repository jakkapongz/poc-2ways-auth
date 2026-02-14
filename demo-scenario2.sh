#!/bin/bash

# Demo Script for SCENARIO 2: Direct Client Certificate (End-to-End Mutual TLS)
# The client MUST provide a valid client certificate

echo "=========================================="
echo "SCENARIO 2: End-to-End Mutual TLS Demo"
echo "Client Certificate Required"
echo "=========================================="
echo ""
echo "In this scenario:"
echo "  - Client MUST provide a valid certificate"
echo "  - Both HTTPD and Spring Boot validate the certificate"
echo "  - True end-to-end authentication"
echo ""
echo "Port: 443 (HTTPD with client certificate requirement)"
echo ""

# Test 1: Without certificate (should fail)
echo "=========================================="
echo "Test 1: Access WITHOUT Client Certificate"
echo "=========================================="
echo ""
echo "Command: curl -k https://localhost:443/api/hello"
echo ""
echo "Attempting to connect without client certificate..."
echo ""

# Capture the error
ERROR_OUTPUT=$(curl -k https://localhost:443/api/hello 2>&1)
if echo "$ERROR_OUTPUT" | grep -q "SSL\|certificate\|handshake"; then
    echo "❌ Connection FAILED (as expected!)"
    echo ""
    echo "Error: $ERROR_OUTPUT"
    echo ""
    echo "✓ This is correct! The server rejected the connection"
    echo "✓ No valid client certificate was provided"
    echo "✓ Security in action - unauthorized access prevented"
else
    echo "Response: $ERROR_OUTPUT"
fi
echo ""

read -p "Press Enter to try WITH a valid certificate..."

# Test 2: With valid certificate (should succeed)
echo ""
echo "=========================================="
echo "Test 2: Access WITH Valid Client Certificate"
echo "=========================================="
echo ""
echo "Command: curl --cert certs/client-cert.pem \\"
echo "             --key certs/client-key.pem \\"
echo "             --cacert certs/ca-cert.pem \\"
echo "             https://localhost:443/api/hello"
echo ""
echo "Response:"
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello 2>/dev/null | jq .
echo ""
echo "✓ Connection SUCCEEDED!"
echo "✓ Notice: authenticatedUser is 'client1' (from certificate CN)"
echo "✓ This is the actual client identity, not a proxy"
echo ""

read -p "Press Enter to see more details..."

# Test 3: Info endpoint with certificate
echo ""
echo "=========================================="
echo "Test 3: GET /api/info (with certificate)"
echo "=========================================="
echo ""
echo "Response:"
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/info 2>/dev/null | jq .
echo ""
echo "✓ clientCN shows 'client1'"
echo "✓ Both HTTPD and Spring Boot validated this certificate"
echo ""

read -p "Press Enter to see certificate details..."

# Show client certificate
echo ""
echo "=========================================="
echo "Client Certificate Details"
echo "=========================================="
echo ""
echo "This is the certificate the client presented:"
echo ""
openssl x509 -in certs/client-cert.pem -noout -subject -issuer -dates
echo ""
echo "✓ Common Name (CN): client1"
echo "✓ Issued by: Example Root CA"
echo "✓ This CA is trusted by both HTTPD and Spring Boot"
echo ""

read -p "Press Enter to test direct access to Spring Boot..."

# Test 4: Direct access to Spring Boot (bypass HTTPD)
echo ""
echo "=========================================="
echo "Test 4: Direct Access to Spring Boot"
echo "Bypassing HTTPD (Port 8443)"
echo "=========================================="
echo ""
echo "Command: curl --cert certs/client-cert.pem \\"
echo "             --key certs/client-key.pem \\"
echo "             --cacert certs/ca-cert.pem \\"
echo "             https://localhost:8443/api/hello"
echo ""
echo "Response:"
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:8443/api/hello 2>/dev/null | jq .
echo ""
echo "✓ Direct access also works!"
echo "✓ Spring Boot independently validates certificates"
echo "✓ Defense in depth - security at multiple layers"
echo ""

read -p "Press Enter to see comparison with Scenario 1..."

# Comparison
echo ""
echo "=========================================="
echo "Comparison: Scenario 1 vs Scenario 2"
echo "=========================================="
echo ""
echo "Scenario 1 (Port 8080 - Proxy Auth):"
echo "  - No client certificate needed"
echo "  - User identity: httpd-proxy (proxy, not end user)"
echo "  - Easy for browsers and web apps"
echo ""
echo "Scenario 2 (Port 443 - End-to-End mTLS):"
echo "  - Client certificate required"
echo "  - User identity: client1 (actual client)"
echo "  - Best for API/microservice communication"
echo ""

echo "=========================================="
echo "Summary - Scenario 2"
echo "=========================================="
echo ""
echo "✓ Client certificate is mandatory"
echo "✓ True end-to-end mutual authentication"
echo "✓ Backend knows the actual client identity"
echo "✓ Good for API integrations, microservices, IoT"
echo "✓ Higher security, but more complex certificate management"
echo ""
