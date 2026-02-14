#!/bin/bash

# Script to generate certificates for mutual TLS authentication
# This creates: CA certificate, server certificate, and client certificate

set -e

CERTS_DIR="./certs"
RESOURCES_DIR="./src/main/resources"

# Create directories
mkdir -p $CERTS_DIR
mkdir -p $RESOURCES_DIR

echo "=== Generating Certificates for Mutual TLS Authentication ==="

# 1. Generate CA (Certificate Authority)
echo "1. Generating CA private key and certificate..."
openssl genrsa -out $CERTS_DIR/ca-key.pem 4096

openssl req -new -x509 -days 3650 -key $CERTS_DIR/ca-key.pem -out $CERTS_DIR/ca-cert.pem \
    -subj "/C=US/ST=California/L=San Francisco/O=Example CA/CN=Example Root CA"

echo "   CA certificate generated: $CERTS_DIR/ca-cert.pem"

# 2. Generate Server Certificate
echo "2. Generating server private key..."
openssl genrsa -out $CERTS_DIR/server-key.pem 4096

echo "3. Generating server certificate signing request..."
openssl req -new -key $CERTS_DIR/server-key.pem -out $CERTS_DIR/server-csr.pem \
    -subj "/C=US/ST=California/L=San Francisco/O=Example Server/CN=localhost"

echo "4. Signing server certificate with CA..."
openssl x509 -req -days 3650 -in $CERTS_DIR/server-csr.pem \
    -CA $CERTS_DIR/ca-cert.pem -CAkey $CERTS_DIR/ca-key.pem \
    -CAcreateserial -out $CERTS_DIR/server-cert.pem \
    -extfile <(printf "subjectAltName=DNS:localhost,DNS:spring-app,IP:127.0.0.1")

echo "   Server certificate generated: $CERTS_DIR/server-cert.pem"

# 3. Generate Client Certificate
echo "5. Generating client private key..."
openssl genrsa -out $CERTS_DIR/client-key.pem 4096

echo "6. Generating client certificate signing request..."
openssl req -new -key $CERTS_DIR/client-key.pem -out $CERTS_DIR/client-csr.pem \
    -subj "/C=US/ST=California/L=San Francisco/O=Example Client/CN=client1"

echo "7. Signing client certificate with CA..."
openssl x509 -req -days 3650 -in $CERTS_DIR/client-csr.pem \
    -CA $CERTS_DIR/ca-cert.pem -CAkey $CERTS_DIR/ca-key.pem \
    -CAcreateserial -out $CERTS_DIR/client-cert.pem

echo "   Client certificate generated: $CERTS_DIR/client-cert.pem"

# 4. Create PKCS12 keystores for Spring Boot
echo "8. Creating PKCS12 keystore for server..."
openssl pkcs12 -export -out $RESOURCES_DIR/keystore.p12 \
    -inkey $CERTS_DIR/server-key.pem \
    -in $CERTS_DIR/server-cert.pem \
    -certfile $CERTS_DIR/ca-cert.pem \
    -password pass:changeit -name server

echo "9. Creating PKCS12 truststore with CA certificate..."
keytool -import -trustcacerts -noprompt -alias ca \
    -file $CERTS_DIR/ca-cert.pem \
    -keystore $RESOURCES_DIR/truststore.p12 \
    -storepass changeit -storetype PKCS12

echo "   Keystore created: $RESOURCES_DIR/keystore.p12"
echo "   Truststore created: $RESOURCES_DIR/truststore.p12"

# 5. Create PKCS12 for client (for testing)
echo "10. Creating PKCS12 keystore for client..."
openssl pkcs12 -export -out $CERTS_DIR/client.p12 \
    -inkey $CERTS_DIR/client-key.pem \
    -in $CERTS_DIR/client-cert.pem \
    -certfile $CERTS_DIR/ca-cert.pem \
    -password pass:changeit -name client

echo "   Client keystore created: $CERTS_DIR/client.p12"

# 6. Copy certificates for Apache HTTPD
echo "11. Copying certificates for Apache HTTPD..."
cp $CERTS_DIR/ca-cert.pem $CERTS_DIR/httpd-ca-cert.pem
cp $CERTS_DIR/server-cert.pem $CERTS_DIR/httpd-server-cert.pem
cp $CERTS_DIR/server-key.pem $CERTS_DIR/httpd-server-key.pem

echo ""
echo "=== Certificate Generation Complete ==="
echo ""
echo "Generated files:"
echo "  CA Certificate:      $CERTS_DIR/ca-cert.pem"
echo "  Server Certificate:  $CERTS_DIR/server-cert.pem"
echo "  Server Key:          $CERTS_DIR/server-key.pem"
echo "  Client Certificate:  $CERTS_DIR/client-cert.pem"
echo "  Client Key:          $CERTS_DIR/client-key.pem"
echo "  Client PKCS12:       $CERTS_DIR/client.p12"
echo "  Server Keystore:     $RESOURCES_DIR/keystore.p12"
echo "  Server Truststore:   $RESOURCES_DIR/truststore.p12"
echo ""
echo "You can now build and run the application!"
