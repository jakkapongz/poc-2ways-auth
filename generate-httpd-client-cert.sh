#!/bin/bash

# Script to generate a client certificate for HTTPD proxy
# This allows HTTPD to authenticate to Spring Boot on behalf of browsers

set -e

CERTS_DIR="./certs"

echo "=== Generating HTTPD Client Certificate for Proxy Authentication ==="

# Generate Client Certificate for HTTPD
echo "1. Generating HTTPD proxy client private key..."
openssl genrsa -out $CERTS_DIR/httpd-client-key.pem 4096

echo "2. Generating HTTPD proxy client certificate signing request..."
openssl req -new -key $CERTS_DIR/httpd-client-key.pem -out $CERTS_DIR/httpd-client-csr.pem \
    -subj "/C=US/ST=California/L=San Francisco/O=HTTPD Proxy/CN=httpd-proxy"

echo "3. Signing HTTPD proxy client certificate with CA..."
openssl x509 -req -days 3650 -in $CERTS_DIR/httpd-client-csr.pem \
    -CA $CERTS_DIR/ca-cert.pem -CAkey $CERTS_DIR/ca-key.pem \
    -CAcreateserial -out $CERTS_DIR/httpd-client-cert.pem

echo "   HTTPD client certificate generated: $CERTS_DIR/httpd-client-cert.pem"

# Create PEM bundle for Apache (cert + key)
echo "4. Creating PEM bundle for Apache SSLProxyMachineCertificateFile..."
cat $CERTS_DIR/httpd-client-cert.pem $CERTS_DIR/httpd-client-key.pem > $CERTS_DIR/httpd-client-bundle.pem

echo "   Bundle created: $CERTS_DIR/httpd-client-bundle.pem"

echo ""
echo "=== HTTPD Client Certificate Generation Complete ==="
echo ""
echo "Generated files:"
echo "  HTTPD Client Certificate:  $CERTS_DIR/httpd-client-cert.pem"
echo "  HTTPD Client Key:          $CERTS_DIR/httpd-client-key.pem"
echo "  HTTPD Client Bundle:       $CERTS_DIR/httpd-client-bundle.pem"
echo ""
echo "HTTPD can now authenticate to Spring Boot on behalf of browsers!"
