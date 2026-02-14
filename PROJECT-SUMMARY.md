# Project Summary: 2-Way Authentication POC

## Overview
This project demonstrates a complete implementation of **Mutual TLS (mTLS)** authentication, also known as 2-way authentication, using Spring Boot and Apache HTTPD as a reverse proxy.

## What is 2-Way Authentication?

Traditional HTTPS (1-way authentication):
- Client verifies server's certificate
- Server doesn't verify client identity via certificate

Mutual TLS (2-way authentication):
- Client verifies server's certificate ✓
- Server verifies client's certificate ✓
- Both parties authenticate each other

## Architecture

```
┌─────────────────┐
│     Client      │
│ (with cert)     │
└────────┬────────┘
         │ HTTPS + Client Certificate
         ▼
┌─────────────────┐
│  Apache HTTPD   │
│  Reverse Proxy  │ ◄── Validates client certificate (Layer 1)
│   Port: 443     │
└────────┬────────┘
         │ HTTPS (proxied)
         ▼
┌─────────────────┐
│  Spring Boot    │
│  Application    │ ◄── Validates client certificate (Layer 2)
│   Port: 8443    │
└─────────────────┘
```

**Two-layer security**: Both Apache HTTPD and Spring Boot independently validate client certificates.

## Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Backend | Spring Boot | 3.2.2 | REST API with mTLS |
| Security | Spring Security | 6.x | X.509 authentication |
| Build Tool | Gradle | 8.5 | Build automation |
| Reverse Proxy | Apache HTTPD | 2.4 | SSL termination & proxy |
| Container | Docker | Latest | Service orchestration |
| Certificate | OpenSSL | Latest | Certificate generation |
| Runtime | Java | 17 | Application runtime |

## Project Structure

```
poc-2ways-auth/
│
├── src/main/java/com/example/mtls/
│   ├── MutualTlsApplication.java          # Main Spring Boot app
│   ├── config/
│   │   └── SecurityConfig.java             # Spring Security config
│   └── controller/
│       ├── SecureController.java           # Protected endpoints
│       └── HealthController.java           # Health check
│
├── src/main/resources/
│   ├── application.yml                     # Spring Boot config
│   ├── keystore.p12                        # Server keystore (generated)
│   └── truststore.p12                      # CA truststore (generated)
│
├── httpd/
│   ├── Dockerfile                          # Apache HTTPD container
│   └── httpd-ssl-mtls.conf                 # Apache mTLS config
│
├── certs/                                  # Generated certificates
│   ├── ca-cert.pem                         # Certificate Authority
│   ├── ca-key.pem
│   ├── server-cert.pem                     # Server certificate
│   ├── server-key.pem
│   ├── client-cert.pem                     # Client certificate
│   ├── client-key.pem
│   └── client.p12                          # Client PKCS12 for browsers
│
├── generate-certs.sh                       # Certificate generation (Unix)
├── generate-certs.bat                      # Certificate generation (Windows)
├── test-endpoints.sh                       # Testing script (Unix)
├── test-endpoints.bat                      # Testing script (Windows)
├── test-endpoints.ps1                      # Testing script (PowerShell)
├── docker-compose.yml                      # Docker orchestration
├── Dockerfile                              # Spring Boot container
├── build.gradle                            # Gradle build config
├── Makefile                                # Build automation (Unix)
├── README.md                               # Main documentation
├── WINDOWS-SETUP.md                        # Windows-specific guide
└── PROJECT-SUMMARY.md                      # This file
```

## Key Features

### 1. Certificate Infrastructure
- **Self-signed CA**: Acts as Certificate Authority
- **Server certificates**: For Spring Boot and Apache HTTPD
- **Client certificates**: For authentication
- **PKCS12 keystores**: For Java applications
- **PEM format**: For Apache and curl

### 2. Spring Boot Security
- **X.509 Authentication**: Certificate-based authentication
- **SSL/TLS Configuration**: Port 8443 with mutual TLS
- **Principal Extraction**: Extracts CN from client certificate
- **UserDetailsService**: Maps certificates to users
- **Endpoint Protection**: All endpoints require valid client cert (except health)

### 3. Apache HTTPD Reverse Proxy
- **SSL Termination**: Handles HTTPS connections
- **Client Certificate Validation**: Requires and validates client certs
- **Certificate Header Forwarding**: Passes cert info to backend
- **Modern TLS**: TLS 1.2 and 1.3 only
- **Strong Cipher Suites**: High-security encryption

### 4. Cross-Platform Support
- **Linux/macOS**: Shell scripts, Makefile
- **Windows**: Batch scripts, PowerShell scripts
- **Docker**: Consistent environment across platforms
- **Gradle Wrapper**: No Gradle installation required

## API Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/actuator/health` | GET | No | Health check endpoint |
| `/api/hello` | GET | Yes | Greeting with user info |
| `/api/info` | GET | Yes | Authentication details |
| `/api/status` | GET | Yes | Service status |

## Security Features

1. **Mutual Authentication**: Both parties verify each other
2. **Certificate Validation**: Only CA-signed certs are trusted
3. **Two-Layer Verification**: Apache and Spring Boot both validate
4. **Modern TLS**: TLS 1.2+ only, strong ciphers
5. **No Password Authentication**: Certificate-based only
6. **Principal Extraction**: Identifies users by certificate CN

## Use Cases

### When to Use Mutual TLS

✅ **Good for:**
- Machine-to-machine communication
- Microservices authentication
- API gateways
- High-security environments
- Zero-trust architectures
- IoT device authentication
- Financial services
- Healthcare systems (HIPAA compliance)
- Government systems
- B2B API integration

❌ **Not ideal for:**
- Public web applications
- Consumer-facing services
- Applications requiring easy user onboarding
- When certificate distribution is challenging

### Real-World Examples

1. **Banking APIs**: Banks use mTLS for inter-bank transfers
2. **Cloud Services**: AWS, GCP use mTLS for service mesh
3. **Payment Gateways**: PCI-DSS compliance requires strong auth
4. **IoT Platforms**: Device authentication and authorization
5. **Kubernetes**: Pod-to-pod communication in service mesh
6. **Microservices**: Istio, Linkerd use mTLS for zero-trust

## Quick Start Commands

### Linux/macOS
```bash
# Generate certificates
./generate-certs.sh

# Start services
docker-compose up --build

# Test
./test-endpoints.sh
```

### Windows
```cmd
# Generate certificates
generate-certs.bat

# Start services
docker-compose up --build

# Test
test-endpoints.bat
```

### Gradle Commands
```bash
# Build (Unix)
./gradlew clean build

# Build (Windows)
gradlew.bat clean build

# Run
./gradlew bootRun
gradlew.bat bootRun
```

## Testing Examples

### With curl
```bash
# Successful request (with client cert)
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost/api/hello

# Failed request (without client cert)
curl --cacert certs/ca-cert.pem https://localhost/api/hello
```

### With Browser
1. Import `certs/client.p12` into browser (password: `changeit`)
2. Navigate to `https://localhost/api/hello`
3. Select client certificate when prompted

## Configuration Highlights

### Spring Boot (application.yml)
```yaml
server:
  port: 8443
  ssl:
    enabled: true
    client-auth: need  # Require client certificate
    key-store: classpath:keystore.p12
    trust-store: classpath:truststore.p12
```

### Apache HTTPD (httpd-ssl-mtls.conf)
```apache
SSLVerifyClient require      # Require client certificate
SSLVerifyDepth 10
SSLCACertificateFile /path/to/ca-cert.pem
```

## Production Considerations

### Before Production Deployment

1. **Use Real CA**: Replace self-signed CA with trusted CA (Let's Encrypt, DigiCert, etc.)
2. **Certificate Management**: Implement rotation and renewal automation
3. **Revocation**: Set up CRL or OCSP for certificate revocation
4. **Monitoring**: Track certificate expiration dates
5. **Secrets Management**: Use vault for private keys
6. **Performance**: Enable SSL session caching
7. **Logging**: Implement audit logging for certificate events
8. **Backup**: Secure backup of CA and private keys
9. **Documentation**: Document certificate distribution process
10. **Testing**: Test certificate renewal process

### Security Hardening

- Use Hardware Security Modules (HSM) for CA keys
- Implement certificate pinning for critical clients
- Enable OCSP stapling
- Use shorter certificate validity periods
- Implement automated certificate renewal
- Regular security audits
- Monitor for certificate anomalies

## Learning Resources

### Documentation
- [Spring Security X.509](https://docs.spring.io/spring-security/reference/servlet/authentication/x509.html)
- [Apache mod_ssl](https://httpd.apache.org/docs/2.4/mod/mod_ssl.html)
- [OpenSSL Documentation](https://www.openssl.org/docs/)

### Standards
- [RFC 8446 - TLS 1.3](https://www.rfc-editor.org/rfc/rfc8446.html)
- [RFC 8705 - OAuth 2.0 Mutual-TLS](https://www.rfc-editor.org/rfc/rfc8705.html)
- [X.509 Certificate Standard](https://www.itu.int/rec/T-REC-X.509)

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| SSL handshake failed | Regenerate certificates |
| Certificate not trusted | Check CA in truststore |
| Port already in use | Change port in docker-compose.yml |
| OpenSSL not found (Windows) | Install from slproweb.com |
| Gradle not found | Use wrapper: `./gradlew` or `gradlew.bat` |

## Development Team Notes

### Adding New Endpoints
1. Create controller in `src/main/java/com/example/mtls/controller/`
2. Protected endpoints automatically require client cert
3. Use `Principal principal` parameter to get authenticated user

### Customizing Authentication
Edit `SecurityConfig.java` to modify:
- Certificate validation rules
- User mapping logic
- Authorization rules

### Certificate Renewal
```bash
# Regenerate all certificates
rm -rf certs/ src/main/resources/*.p12
./generate-certs.sh
docker-compose restart
```

## License
This is a proof-of-concept project for educational purposes.

## Contributing
This is a demonstration project. Feel free to fork and adapt for your needs.

---

**Created**: 2024
**Last Updated**: 2024
**Status**: Production-Ready POC
**Maintained**: Yes
