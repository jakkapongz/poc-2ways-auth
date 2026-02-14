#!/bin/bash

# Complete setup script for presentation demo

set -e

echo "=========================================="
echo "Setting Up 2-Way Authentication Demo"
echo "=========================================="
echo ""

# Step 1: Generate base certificates
echo "Step 1: Generating base certificates..."
echo "----------------------------------------"
if [ ! -f "certs/ca-cert.pem" ]; then
    chmod +x generate-certs.sh
    ./generate-certs.sh
    echo "✓ Base certificates generated"
else
    echo "✓ Base certificates already exist"
fi
echo ""

# Step 2: Generate HTTPD client certificate
echo "Step 2: Generating HTTPD client certificate..."
echo "----------------------------------------"
if [ ! -f "certs/httpd-client-bundle.pem" ]; then
    chmod +x generate-httpd-client-cert.sh
    ./generate-httpd-client-cert.sh
    echo "✓ HTTPD client certificate generated"
else
    echo "✓ HTTPD client certificate already exists"
fi
echo ""

# Step 3: Build and start services
echo "Step 3: Building and starting services..."
echo "----------------------------------------"
echo "This may take a few minutes on first run..."
docker-compose -f docker-compose.presentation.yml up --build -d

echo ""
echo "Waiting for services to be ready..."
sleep 10

# Step 4: Check service health
echo ""
echo "Step 4: Verifying services..."
echo "----------------------------------------"

if docker ps | grep -q spring-app-mtls; then
    echo "✓ Spring Boot is running on port 8443"
else
    echo "✗ Spring Boot is not running"
    exit 1
fi

if docker ps | grep -q httpd-proxy-presentation; then
    echo "✓ Apache HTTPD is running on ports 443 and 8080"
else
    echo "✗ Apache HTTPD is not running"
    exit 1
fi

echo ""
echo "Testing connectivity..."

# Test Scenario 1 (port 8080)
if curl -k -s https://localhost:8080/api/status > /dev/null 2>&1; then
    echo "✓ Scenario 1 (Port 8080) is accessible"
else
    echo "✗ Scenario 1 (Port 8080) failed"
fi

# Test Scenario 2 (port 443 with cert)
if curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem -s https://localhost:443/api/status > /dev/null 2>&1; then
    echo "✓ Scenario 2 (Port 443) is accessible"
else
    echo "✗ Scenario 2 (Port 443) failed"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Your presentation environment is ready!"
echo ""
echo "📊 Available Demonstrations:"
echo ""
echo "SCENARIO 1: Browser Access (No Client Cert)"
echo "  Port: 8080"
echo "  Browser: https://localhost:8080/api/hello"
echo "  Script:  ./demo-scenario1.sh"
echo ""
echo "SCENARIO 2: End-to-End Mutual TLS (Client Cert Required)"
echo "  Port: 443"
echo "  Script:  ./demo-scenario2.sh"
echo ""
echo "📖 Documentation:"
echo "  Full guide: PRESENTATION-DEMO.md"
echo ""
echo "🎬 Quick Test:"
echo "  Scenario 1: curl -k https://localhost:8080/api/hello"
echo "  Scenario 2: curl --cert certs/client-cert.pem \\"
echo "                   --key certs/client-key.pem \\"
echo "                   --cacert certs/ca-cert.pem \\"
echo "                   https://localhost:443/api/hello"
echo ""
echo "📋 View logs:"
echo "  docker-compose -f docker-compose.presentation.yml logs -f"
echo ""
echo "🛑 Stop demo:"
echo "  docker-compose -f docker-compose.presentation.yml down"
echo ""
