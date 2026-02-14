# Team Presentation: 2-Way Authentication Demo

This guide provides a step-by-step demonstration of two different 2-way authentication scenarios.

## Demo Architecture

```
SCENARIO 1: Browser Access (HTTPD Proxy Authentication)
┌──────────────┐
│   Browser    │ (No certificate needed)
│  (HTTP/S)    │
└──────┬───────┘
       │ HTTPS (no client cert)
       ▼
┌──────────────────────┐
│   Apache HTTPD       │
│   Port: 8080         │ ◄── Server cert only (for browser)
└──────┬───────────────┘
       │ HTTPS + HTTPD's client cert
       │ (HTTPD authenticates to backend)
       ▼
┌──────────────────────┐
│   Spring Boot        │
│   Port: 8443         │ ◄── Validates HTTPD's client certificate
└──────────────────────┘


SCENARIO 2: Direct Client Certificate (End-to-End mTLS)
┌──────────────┐
│   Client     │ (Requires certificate)
│  (curl/API)  │
└──────┬───────┘
       │ HTTPS + client cert
       ▼
┌──────────────────────┐
│   Apache HTTPD       │
│   Port: 443          │ ◄── Validates client certificate
└──────┬───────────────┘
       │ HTTPS (proxied)
       ▼
┌──────────────────────┐
│   Spring Boot        │
│   Port: 8443         │ ◄── Also validates client certificate
└──────────────────────┘
```

## Prerequisites

Before the presentation, ensure you have:

1. ✅ Docker and Docker Compose installed
2. ✅ All certificates generated
3. ✅ Services running
4. ✅ curl or Postman for testing

## Setup Instructions

### Step 1: Generate All Certificates

**Linux/Mac:**
```bash
# Generate base certificates
chmod +x generate-certs.sh
./generate-certs.sh

# Generate HTTPD client certificate for proxy authentication
chmod +x generate-httpd-client-cert.sh
./generate-httpd-client-cert.sh
```

**Windows:**
```cmd
REM Generate base certificates
generate-certs.bat

REM Generate HTTPD client certificate for proxy authentication
generate-httpd-client-cert.bat
```

### Step 2: Start Services

```bash
# Use the presentation docker-compose file
docker-compose -f docker-compose.presentation.yml up --build
```

**Wait for services to be ready:**
```
spring-app-mtls          | Started MutualTlsApplication
httpd-proxy-presentation | AH00094: Command line: 'httpd -D FOREGROUND'
```

### Step 3: Verify Services are Running

```bash
docker-compose -f docker-compose.presentation.yml ps
```

Expected output:
```
NAME                      STATUS    PORTS
httpd-proxy-presentation  Up        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8080->8080/tcp
spring-app-mtls          Up        0.0.0.0:8443->8443/tcp
```

## Demonstration Flow

---

## 🎯 SCENARIO 1: Browser Access (HTTPD Authenticates on Behalf of Client)

### Overview
In this scenario, the browser user **does not need** a client certificate. Apache HTTPD acts as a trusted proxy and authenticates to Spring Boot using its own client certificate.

### Demo Steps

#### Step 1.1: Explain the Scenario
**Say to the team:**
> "In this first scenario, we're demonstrating how a regular web browser can access our secure backend without needing to install a client certificate. This is useful for web applications where you want to secure backend communication but not burden users with certificate management."

#### Step 1.2: Test with Browser

**Open browser and navigate to:**
```
https://localhost:8080/api/hello
```

**Note:** You may need to accept the self-signed server certificate warning.

**Expected Result:**
```json
{
  "message": "Hello from secure endpoint!",
  "authenticatedUser": "httpd-proxy",
  "timestamp": "..."
}
```

**Point out:**
- ✅ No client certificate required in browser
- ✅ `authenticatedUser` shows "httpd-proxy" (HTTPD authenticated)
- ✅ Connection is still secure (HTTPS)

#### Step 1.3: Test with curl (No Client Certificate)

```bash
# Browser-like access - no client certificate needed
curl -k https://localhost:8080/api/hello
```

**Expected Response:**
```json
{
  "message": "Hello from secure endpoint!",
  "authenticatedUser": "httpd-proxy",
  "timestamp": "1234567890"
}
```

**Explain:**
> "Notice we used `-k` to skip certificate verification (for demo only). In production, you'd use proper CA certificates. The important point is: we didn't provide any client certificate, but we still got authenticated access."

#### Step 1.4: Show Other Endpoints

```bash
# Test info endpoint
curl -k https://localhost:8080/api/info

# Test status endpoint
curl -k https://localhost:8080/api/status
```

**Expected Response (info):**
```json
{
  "clientCN": "httpd-proxy",
  "authType": "Mutual TLS (2-Way Authentication)",
  "secure": true,
  "protocol": "HTTPS"
}
```

**Highlight:**
- The `clientCN` is "httpd-proxy" - this is the identity HTTPD used
- The backend still sees a properly authenticated client
- Users don't need to manage certificates

#### Step 1.5: Show How It Works

**Explain the flow:**

1. **Browser → HTTPD:**
   - Browser connects to HTTPD on port 8080
   - Only server certificate verification (standard HTTPS)
   - No client certificate required

2. **HTTPD → Spring Boot:**
   - HTTPD uses its own client certificate (`httpd-proxy`)
   - Full mutual TLS authentication
   - Spring Boot validates HTTPD's certificate

**Show the certificates:**
```bash
# Show HTTPD's client certificate
openssl x509 -in certs/httpd-client-cert.pem -noout -subject -issuer

# Output:
# subject=C=US, ST=California, L=San Francisco, O=HTTPD Proxy, CN=httpd-proxy
# issuer=C=US, ST=California, L=San Francisco, O=Example CA, CN=Example Root CA
```

**Explain:**
> "This certificate is what HTTPD uses to authenticate to the Spring Boot backend. It's trusted because it's signed by our CA. The browser users never see or need this certificate."

---

## 🎯 SCENARIO 2: Direct Client Certificate (End-to-End Mutual TLS)

### Overview
In this scenario, the client **must provide** a valid client certificate. This demonstrates true end-to-end mutual TLS where both the client and server verify each other's identity.

### Demo Steps

#### Step 2.1: Explain the Scenario
**Say to the team:**
> "Now we'll demonstrate traditional mutual TLS where the client must have a certificate. This is common for API-to-API communication, microservices, or high-security applications where you need to be certain of the client's identity."

#### Step 2.2: Test WITHOUT Client Certificate (Should Fail)

```bash
# Attempt to connect without client certificate
curl -k https://localhost:443/api/hello
```

**Expected Result:**
```
curl: (35) error:14094410:SSL routines:ssl3_read_bytes:sslv3 alert handshake failure
```
Or:
```
curl: (56) OpenSSL SSL_read: error:14094412:SSL routines:ssl3_read_bytes:sslv3 alert bad certificate
```

**Explain:**
> "The connection was rejected because we didn't provide a client certificate. Apache HTTPD requires it, and the SSL handshake fails immediately. This is security in action!"

#### Step 2.3: Test WITH Valid Client Certificate (Success)

```bash
# Connect with valid client certificate
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

**Expected Response:**
```json
{
  "message": "Hello from secure endpoint!",
  "authenticatedUser": "client1",
  "timestamp": "1234567890"
}
```

**Point out:**
- ✅ Connection succeeded with valid certificate
- ✅ `authenticatedUser` shows "client1" (from certificate CN)
- ✅ Both layers verified the certificate (HTTPD + Spring Boot)

#### Step 2.4: Show Certificate Information

```bash
# Show the client certificate details
openssl x509 -in certs/client-cert.pem -noout -subject -issuer -dates

# Output:
# subject=C=US, ST=California, L=San Francisco, O=Example Client, CN=client1
# issuer=C=US, ST=California, L=San Francisco, O=Example CA, CN=Example Root CA
# notBefore=...
# notAfter=...
```

**Explain:**
> "The certificate identifies the client as 'client1'. This is signed by our trusted CA, which is why both HTTPD and Spring Boot accept it. In production, you'd use a real CA like DigiCert or your company's internal CA."

#### Step 2.5: Test Other Endpoints

```bash
# Test info endpoint
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/info
```

**Expected Response:**
```json
{
  "clientCN": "client1",
  "authType": "Mutual TLS (2-Way Authentication)",
  "secure": true,
  "protocol": "HTTPS"
}
```

#### Step 2.6: Direct Access to Spring Boot (Bypass HTTPD)

```bash
# Access Spring Boot directly (still requires certificate)
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:8443/api/hello
```

**Expected Response:**
```json
{
  "message": "Hello from secure endpoint!",
  "authenticatedUser": "client1",
  "timestamp": "1234567890"
}
```

**Explain:**
> "Even when bypassing the proxy, Spring Boot enforces mutual TLS. This is defense in depth - both layers independently verify certificates."

---

## 🔍 Deep Dive: How It Works

### Spring Boot Configuration

**Show the code:**
```yaml
# src/main/resources/application.yml
server:
  ssl:
    enabled: true
    client-auth: need    # ← Requires client certificate
    key-store: classpath:keystore.p12
    trust-store: classpath:truststore.p12
```

**Explain:**
> "The key setting is `client-auth: need`. This tells Spring Boot to require and validate client certificates. The truststore contains our CA certificate, so any certificate signed by that CA is trusted."

### Apache HTTPD Configuration

**Scenario 1 (Port 8080):**
```apache
SSLVerifyClient none    # ← No client cert from browser
SSLProxyMachineCertificateFile /path/to/httpd-client-bundle.pem  # ← HTTPD's cert
```

**Scenario 2 (Port 443):**
```apache
SSLVerifyClient require    # ← Client cert required
SSLCACertificateFile /path/to/ca-cert.pem  # ← Trust anchor
```

---

## 📊 Comparison Table

| Feature | Scenario 1 (Port 8080) | Scenario 2 (Port 443) |
|---------|------------------------|------------------------|
| **Client Cert Required** | ❌ No | ✅ Yes |
| **User Experience** | Easy (like normal HTTPS) | Complex (cert installation) |
| **Security** | Backend secured | End-to-end secured |
| **Best For** | Web applications | API/microservices |
| **Client Identity** | Proxy (httpd-proxy) | Actual client (client1) |
| **Certificate Management** | Centralized (HTTPD only) | Distributed (each client) |

---

## 🎓 Use Cases Discussion

### When to Use Scenario 1 (Proxy Authentication)

✅ **Good for:**
- Web applications with human users
- Internal applications behind corporate firewall
- When you control the reverse proxy
- Centralizing certificate management
- Mobile apps (cert in app, not on device)

❌ **Limitations:**
- Backend sees proxy identity, not end user
- Proxy is a single point of failure
- Additional hop in request chain

### When to Use Scenario 2 (End-to-End mTLS)

✅ **Good for:**
- Microservice communication
- API integrations (B2B)
- IoT device authentication
- High-security requirements
- Zero-trust architectures
- When you need to know the actual client

❌ **Limitations:**
- Certificate distribution complexity
- User experience challenges
- Certificate lifecycle management

---

## 🧪 Additional Demos

### Demo: Certificate Validation

**Try with an invalid certificate:**
```bash
# Generate a self-signed cert (not from our CA)
openssl req -x509 -newkey rsa:2048 -keyout /tmp/fake-key.pem \
    -out /tmp/fake-cert.pem -days 1 -nodes -subj "/CN=fake"

# Try to use it
curl --cert /tmp/fake-cert.pem \
     --key /tmp/fake-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

**Expected Result:**
```
SSL certificate problem: unable to get local issuer certificate
```

**Explain:**
> "This fails because the certificate isn't signed by our trusted CA. This demonstrates how certificate validation protects against unauthorized access."

### Demo: Certificate Expiration

**Show certificate validity:**
```bash
# Check when certificate expires
openssl x509 -in certs/client-cert.pem -noout -dates

# Output:
# notBefore=Jan 15 00:00:00 2024 GMT
# notAfter=Jan 12 00:00:00 2034 GMT
```

**Explain:**
> "Certificates have an expiration date. In production, you'd need certificate rotation and renewal processes. Services like cert-manager in Kubernetes can automate this."

---

## 🎬 Presentation Script

### Opening (2 minutes)
1. Introduce the concept of mutual TLS
2. Explain why it matters (zero-trust, API security)
3. Preview the two scenarios

### Scenario 1 Demo (8 minutes)
1. Show browser access (no cert needed)
2. Explain HTTPD proxy authentication
3. Show curl examples
4. Discuss use cases

### Scenario 2 Demo (8 minutes)
1. Show failed access (no cert)
2. Show successful access (with cert)
3. Explain certificate chain
4. Discuss use cases

### Deep Dive (7 minutes)
1. Show configuration files
2. Explain certificate validation
3. Show certificate details
4. Answer questions

### Q&A (5 minutes)
- Common questions below

---

## ❓ Common Questions & Answers

**Q: Can we use this with OAuth/JWT?**
A: Yes! You can combine mTLS for transport security with OAuth/JWT for authorization. mTLS proves "who you are," JWT proves "what you can do."

**Q: How do we handle certificate rotation?**
A: Use tools like cert-manager (Kubernetes), Vault, or cloud provider certificate services. Automate renewal before expiration.

**Q: What about performance?**
A: mTLS has minimal overhead (~1-5ms). Use SSL session caching and connection pooling to optimize. The security benefits far outweigh the cost.

**Q: Can browsers handle client certificates?**
A: Yes, but UX is poor. Import PKCS12 file into browser. Better to use Scenario 1 (proxy auth) for browser users.

**Q: What about mobile apps?**
A: Embed the certificate in the app binary. Use certificate pinning for additional security. Rotate certificates with app updates.

**Q: How is this different from API keys?**
A: API keys are passwords (can be stolen/leaked). Certificates use cryptographic proof of identity and can't be guessed or brute-forced.

---

## 🧹 Cleanup After Presentation

```bash
# Stop services
docker-compose -f docker-compose.presentation.yml down

# Optional: Remove volumes
docker-compose -f docker-compose.presentation.yml down -v
```

---

## 📝 Summary

**Key Takeaways:**
1. ✅ Mutual TLS provides strong authentication (both parties verify each other)
2. ✅ Scenario 1: Proxy authentication - Easy for users, secure backend
3. ✅ Scenario 2: End-to-end mTLS - Maximum security, client identity
4. ✅ Certificate management is crucial in production
5. ✅ Choose the right scenario based on your use case

**Next Steps:**
- Evaluate which scenario fits your architecture
- Plan certificate management strategy
- Consider automation for cert rotation
- Review compliance requirements (PCI-DSS, HIPAA, etc.)
