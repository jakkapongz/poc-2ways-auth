# POC: 2-Way Authentication (Mutual TLS)

This project demonstrates mutual TLS (mTLS) authentication with:
- **Spring Boot** application requiring client certificates
- **Apache HTTPD** reverse proxy with mutual TLS authentication
- Complete certificate infrastructure (CA, server, client)

## Architecture

```
Client (with client cert)
    |
    | HTTPS + Client Cert
    ↓
Apache HTTPD (validates client cert)
    |
    | HTTPS (reverse proxy)
    ↓
Spring Boot App (validates client cert)
```

Both layers validate client certificates for maximum security.

> **Windows Users**: See the detailed [Windows Setup Guide](WINDOWS-SETUP.md) for platform-specific instructions, troubleshooting, and IDE setup.

## Prerequisites

- Java 17+
- Gradle 8.5+ (or use included wrapper: `./gradlew` or `gradlew.bat`)
- Docker & Docker Compose
- OpenSSL (Windows users: install from [here](https://slproweb.com/products/Win32OpenSSL.html) or use Git Bash)
- curl (for testing)

## Quick Start

### 1. Generate Certificates

First, generate all required certificates (CA, server, client):

**Linux/Mac:**
```bash
chmod +x generate-certs.sh
./generate-certs.sh
```

**Windows (Command Prompt):**
```cmd
generate-certs.bat
```

**Windows (PowerShell):**
```powershell
.\generate-certs.bat
```

**Windows (Git Bash):**
```bash
chmod +x generate-certs.sh
./generate-certs.sh
```

This creates:
- CA certificate and key
- Server certificate and key
- Client certificate and key
- PKCS12 keystores for Spring Boot
- Certificates for Apache HTTPD

### 2. Run with Docker Compose

Build and start all services:

```bash
docker-compose up --build
```

This starts:
- Spring Boot app on `https://localhost:8443`
- Apache HTTPD proxy on `https://localhost:443`

### 3. Test the Setup

**Easy Way (Using Test Script):**

**Linux/Mac:**
```bash
chmod +x test-endpoints.sh
./test-endpoints.sh
```

**Windows:**
```cmd
test-endpoints.bat
```

**Manual Testing:**

#### Test via Apache HTTPD (with client certificate)

**Linux/Mac:**
```bash
# Test hello endpoint
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost/api/hello

# Test info endpoint
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost/api/info

# Test status endpoint
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost/api/status
```

**Windows:**
```cmd
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost/api/hello
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost/api/info
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost/api/status
```

#### Test without client certificate (should fail)

```bash
curl --cacert certs/ca-cert.pem https://localhost/api/hello
# Expected: SSL certificate problem or connection refused
```

#### Test Spring Boot directly (bypassing HTTPD)

**Linux/Mac:**
```bash
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:8443/api/hello
```

**Windows:**
```cmd
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost:8443/api/hello
```

## Running Locally (without Docker)

### 1. Build the application

**Linux/Mac:**
```bash
./gradlew clean build
```

**Windows:**
```cmd
gradlew.bat clean build
```

### 2. Run Spring Boot

**Linux/Mac:**
```bash
./gradlew bootRun
```
Or:
```bash
java -jar build/libs/poc-2ways-auth-1.0.0-SNAPSHOT.jar
```

**Windows:**
```cmd
gradlew.bat bootRun
```
Or:
```cmd
java -jar build\libs\poc-2ways-auth-1.0.0-SNAPSHOT.jar
```

The application will start on `https://localhost:8443`

### 3. Test

**Linux/Mac:**
```bash
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:8443/api/hello
```

**Windows:**
```cmd
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost:8443/api/hello
```

## Project Structure

```
poc-2ways-auth/
├── src/
│   └── main/
│       ├── java/com/example/mtls/
│       │   ├── MutualTlsApplication.java
│       │   ├── config/
│       │   │   └── SecurityConfig.java
│       │   └── controller/
│       │       ├── SecureController.java
│       │       └── HealthController.java
│       └── resources/
│           ├── application.yml
│           ├── keystore.p12 (generated)
│           └── truststore.p12 (generated)
├── httpd/
│   ├── Dockerfile
│   ├── Dockerfile.presentation
│   ├── httpd-ssl-mtls.conf (Scenario 2: Client cert required)
│   ├── httpd-ssl-no-client-auth.conf (Scenario 1: No client cert)
│   └── httpd-relay-proxy.conf (Production: HTTP in, HTTPS out)
├── certs/ (generated)
│   ├── ca-cert.pem
│   ├── ca-key.pem
│   ├── server-cert.pem
│   ├── server-key.pem
│   ├── client-cert.pem
│   ├── client-key.pem
│   └── client.p12
├── generate-certs.sh (Linux/Mac)
├── generate-certs.bat (Windows)
├── test-endpoints.sh (Linux/Mac)
├── test-endpoints.bat (Windows)
├── docker-compose.yml
├── Dockerfile
├── build.gradle
├── settings.gradle
├── gradlew (Linux/Mac)
└── gradlew.bat (Windows)
```

## How It Works

### Spring Boot Configuration

The application uses:
- **SSL/TLS**: Configured in `application.yml` with keystore and truststore
- **Client Certificate Authentication**: `server.ssl.client-auth=need`
- **Spring Security**: X.509 authentication configured in `SecurityConfig.java`
- **Certificate Validation**: Only certificates signed by the trusted CA are accepted

### Apache HTTPD Configuration

The reverse proxy:
- **Requires client certificates**: `SSLVerifyClient require`
- **Validates against CA**: `SSLCACertificateFile`
- **Forwards requests**: Proxies to Spring Boot backend
- **Passes certificate info**: Adds headers with client certificate details

### Certificate Chain

1. **CA Certificate**: Root of trust, signs both server and client certificates
2. **Server Certificate**: Used by Spring Boot and Apache HTTPD for TLS
3. **Client Certificate**: Required from clients to authenticate
4. **Truststore**: Contains CA certificate to validate client certificates

## API Endpoints

### Public Endpoints
- `GET /actuator/health` - Health check (no authentication required)

### Protected Endpoints (require client certificate)
- `GET /api/hello` - Simple greeting with authenticated user info
- `GET /api/info` - Detailed authentication information
- `GET /api/status` - Service status

## Security Features

1. **Mutual TLS Authentication**: Both client and server verify each other
2. **Certificate Validation**: Only CA-signed certificates are trusted
3. **Two-Layer Security**: Apache HTTPD and Spring Boot both validate certificates
4. **Modern TLS**: Uses TLS 1.2 and 1.3 only
5. **Strong Ciphers**: Configured for high-security cipher suites

## Troubleshooting

### Certificate Issues

If you get certificate errors, regenerate them:

**Linux/Mac:**
```bash
rm -rf certs/ src/main/resources/*.p12
./generate-certs.sh
docker-compose down
docker-compose up --build
```

**Windows (Command Prompt):**
```cmd
rmdir /s /q certs
del /q src\main\resources\*.p12
generate-certs.bat
docker-compose down
docker-compose up --build
```

**Windows (PowerShell):**
```powershell
Remove-Item -Recurse -Force certs
Remove-Item src\main\resources\*.p12
.\generate-certs.bat
docker-compose down
docker-compose up --build
```

### Connection Refused

Check if services are running:

```bash
docker-compose ps
docker-compose logs spring-app
docker-compose logs httpd-proxy
```

### Windows-Specific Issues

**OpenSSL not found:**
- Install OpenSSL from [slproweb.com](https://slproweb.com/products/Win32OpenSSL.html)
- Or use Git Bash which includes OpenSSL
- Add OpenSSL to your PATH

**keytool not found:**
- Ensure JAVA_HOME is set correctly
- Add `%JAVA_HOME%\bin` to your PATH
- Example: `set JAVA_HOME=C:\Program Files\Java\jdk-17`

**curl not found:**
- Windows 10/11 includes curl by default
- If not available, download from [curl.se](https://curl.se/windows/)
- Or use Git Bash which includes curl

### SSL Handshake Errors

Enable SSL debugging in Spring Boot:

```yaml
logging:
  level:
    javax.net.ssl: DEBUG
```

## Production Deployment

### CentOS 7 Production Setup

This project includes comprehensive guides for deploying on CentOS 7 with custom HTTPD:

📖 **[CENTOS7-IMPLEMENTATION-GUIDE.md](CENTOS7-IMPLEMENTATION-GUIDE.md)** - Complete step-by-step guide
📋 **[MONDAY-QUICK-REFERENCE.md](MONDAY-QUICK-REFERENCE.md)** - Quick commands and troubleshooting

### Production Architecture with Relay

For environments where a relay component handles SSL termination:

```
User (HTTPS 443)
    ↓
[Relay] - SSL/TLS termination
    ↓ (HTTP)
[HTTPD on port 14xxx] - Plain HTTP in, HTTPS out
    ↓ (HTTPS + Client Cert)
[Spring Boot on 8443] - Validates HTTPD's client certificate
```

Use **`httpd/httpd-relay-proxy.conf`** for this configuration.

### Production Considerations

1. **Use proper CA**: Replace self-signed CA with trusted CA certificates
2. **Certificate Management**: Implement certificate rotation and renewal
3. **Revocation**: Set up CRL or OCSP for certificate revocation
4. **Monitoring**: Add metrics and alerts for certificate expiration
5. **Secrets Management**: Use vault or secrets manager for private keys
6. **Performance**: Consider SSL session caching and connection pooling
7. **Firewall**: Configure appropriate port restrictions (14088 internal only)

## Testing with Browser

To test with a browser, import `certs/client.p12` into your browser:

**Chrome/Edge**:
1. Settings → Privacy and Security → Security → Manage Certificates
2. Import `client.p12` (password: `changeit`)
3. Navigate to `https://localhost/api/hello`

**Firefox**:
1. Settings → Privacy & Security → Certificates → View Certificates
2. Your Certificates → Import
3. Select `client.p12` (password: `changeit`)

## License

This is a proof-of-concept project for educational purposes.

## Resources

- [Spring Security X.509 Authentication](https://docs.spring.io/spring-security/reference/servlet/authentication/x509.html)
- [Apache HTTPD SSL/TLS](https://httpd.apache.org/docs/2.4/ssl/)
- [Mutual TLS Best Practices](https://www.rfc-editor.org/rfc/rfc8705.html)
