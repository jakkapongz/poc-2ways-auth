# HTTPD Configuration Explained

Complete breakdown of the two HTTPD configurations for your team presentation.

---

## 🎯 The One Key Difference

### Scenario 1 (Port 8080):
```apache
SSLVerifyClient none    # ← Browser doesn't need certificate
```

### Scenario 2 (Port 443):
```apache
SSLVerifyClient require    # ← Browser MUST provide certificate
```

**Everything else is designed to support this difference.**

---

## 📋 Complete Configuration Comparison

### Configuration File Locations
- **Scenario 1:** `httpd/httpd-ssl-no-client-auth.conf`
- **Scenario 2:** `httpd/httpd-ssl-mtls.conf`

---

## 1️⃣ Client-Facing Configuration (Browser/Client → HTTPD)

### Scenario 1: Easy Access (Port 8080)

```apache
Listen 8080

<VirtualHost _default_:8080>
    ServerName localhost

    # Enable SSL/TLS
    SSLEngine on

    # Server certificate for browser connection
    SSLCertificateFile /usr/local/apache2/conf/certs/httpd-server-cert.pem
    SSLCertificateKeyFile /usr/local/apache2/conf/certs/httpd-server-key.pem

    # ⭐ KEY SETTING: No client certificate required
    SSLVerifyClient none

    # Modern TLS only
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite HIGH:!aNULL:!MD5:!3DES
</VirtualHost>
```

**What happens:**
1. Browser connects to `https://localhost:8080`
2. HTTPD presents server certificate
3. Browser validates server certificate
4. ✅ Connection established - **no client cert needed**
5. Standard HTTPS, like accessing any website

---

### Scenario 2: Secure Access (Port 443)

```apache
Listen 443

<VirtualHost _default_:443>
    ServerName localhost

    # Enable SSL/TLS
    SSLEngine on

    # Server certificate for client connection
    SSLCertificateFile /usr/local/apache2/conf/certs/httpd-server-cert.pem
    SSLCertificateKeyFile /usr/local/apache2/conf/certs/httpd-server-key.pem

    # ⭐ KEY SETTINGS: Client certificate REQUIRED
    SSLVerifyClient require        # Require client certificate
    SSLVerifyDepth 10              # Allow cert chain up to 10 levels

    # CA certificate to validate client certificates
    SSLCACertificateFile /usr/local/apache2/conf/certs/httpd-ca-cert.pem

    # Modern TLS only
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite HIGH:!aNULL:!MD5:!3DES
</VirtualHost>
```

**What happens:**
1. Client connects to `https://localhost:443`
2. HTTPD presents server certificate
3. Client validates server certificate
4. **HTTPD requests client certificate**
5. Client presents certificate
6. HTTPD validates certificate against CA
7. ✅ Connection established only if certificate is valid
8. ❌ Connection refused if no certificate or invalid certificate

---

## 2️⃣ Backend Communication (HTTPD → Spring Boot)

### Both Scenarios Use the SAME Backend Configuration

```apache
# Reverse proxy configuration
ProxyPreserveHost On
ProxyTimeout 300

# Proxy to Spring Boot (HTTPS with mutual TLS)
ProxyPass / https://spring-app:8443/
ProxyPassReverse / https://spring-app:8443/

# ⭐ Enable SSL proxy engine
SSLProxyEngine On

# ⭐ HTTPD uses its own client certificate to authenticate to Spring Boot
SSLProxyMachineCertificateFile /usr/local/apache2/conf/certs/httpd-client-bundle.pem

# ⭐ Verify Spring Boot's server certificate
SSLProxyCACertificateFile /usr/local/apache2/conf/certs/httpd-ca-cert.pem
SSLProxyVerify require
SSLProxyCheckPeerCN on
SSLProxyCheckPeerName off
```

**What this means:**

1. **SSLProxyEngine On**
   - Enables HTTPD to make HTTPS connections to backend

2. **SSLProxyMachineCertificateFile**
   - HTTPD presents this certificate to Spring Boot
   - Contains both certificate and private key
   - This is the "httpd-proxy" identity

3. **SSLProxyCACertificateFile**
   - HTTPD trusts Spring Boot certificates signed by this CA

4. **SSLProxyVerify require**
   - HTTPD validates Spring Boot's server certificate
   - Mutual TLS in action!

**Result:** Regardless of which scenario, HTTPD always authenticates to Spring Boot as "httpd-proxy"

---

## 3️⃣ Headers Forwarded to Backend

### Scenario 1 Headers (Port 8080)

```apache
# Custom headers for proxy authentication
RequestHeader set X-Proxy-Client "httpd-proxy"
RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}e"
RequestHeader set X-Original-Client "%{REMOTE_ADDR}e"
```

**What Spring Boot sees:**
```
X-Proxy-Client: httpd-proxy
X-Forwarded-For: 192.168.65.1 (actual browser IP)
X-Original-Client: 192.168.65.1
Authenticated User: httpd-proxy (from SSL cert)
```

---

### Scenario 2 Headers (Port 443)

```apache
# Pass client certificate information to backend
RequestHeader set X-SSL-Client-Cert "%{SSL_CLIENT_CERT}s"
RequestHeader set X-SSL-Client-S-DN "%{SSL_CLIENT_S_DN}s"
RequestHeader set X-SSL-Client-I-DN "%{SSL_CLIENT_I_DN}s"
RequestHeader set X-SSL-Verified "%{SSL_CLIENT_VERIFY}s"
```

**What Spring Boot sees:**
```
X-SSL-Client-Cert: (full client certificate in PEM format)
X-SSL-Client-S-DN: CN=client1,O=Example Client,L=San Francisco,ST=California,C=US
X-SSL-Client-I-DN: CN=Example Root CA,O=Example CA,...
X-SSL-Verified: SUCCESS
Authenticated User: httpd-proxy (from HTTPD's SSL cert to backend)
```

**Key Point:** Spring Boot could parse these headers to get the actual client identity if needed.

---

## 4️⃣ Security Validation Flow

### Scenario 1: Single-Layer Client Authentication

```
┌─────────┐                  ┌──────────┐                  ┌──────────────┐
│ Browser │                  │  HTTPD   │                  │ Spring Boot  │
└────┬────┘                  └────┬─────┘                  └──────┬───────┘
     │                            │                                │
     │ 1. HTTPS Request           │                                │
     │ (No client cert)           │                                │
     ├──────────────────────────> │                                │
     │                            │                                │
     │ 2. Server cert             │                                │
     │ <────────────────────────┤ │                                │
     │                            │                                │
     │ 3. Validate server cert    │                                │
     │ ✅ (Browser trusts it)     │                                │
     │                            │                                │
     │ 4. Connection OK           │                                │
     │ ══════════════════════════>│                                │
     │         HTTPS              │                                │
     │                            │ 5. HTTPS + Client Cert         │
     │                            │   (httpd-client-bundle.pem)    │
     │                            ├──────────────────────────────> │
     │                            │                                │
     │                            │ 6. Validate HTTPD cert         │
     │                            │                                │ ✅
     │                            │ 7. Connection OK               │
     │                            │ <══════════════════════════════│
     │                            │         mTLS                   │
     │                            │                                │
```

**Validation Points:**
- Browser validates HTTPD server cert ✅
- Spring Boot validates HTTPD client cert ✅
- **Total: 2 validations**

---

### Scenario 2: Double-Layer Client Authentication

```
┌─────────┐                  ┌──────────┐                  ┌──────────────┐
│ Client  │                  │  HTTPD   │                  │ Spring Boot  │
└────┬────┘                  └────┬─────┘                  └──────┬───────┘
     │                            │                                │
     │ 1. HTTPS Request           │                                │
     │    + client cert           │                                │
     ├──────────────────────────> │                                │
     │                            │                                │
     │ 2. Server cert             │                                │
     │ <────────────────────────┤ │                                │
     │                            │                                │
     │ 3. Validate server cert    │                                │
     │ ✅ (Client trusts it)      │                                │
     │                            │                                │
     │ 4. Request client cert     │                                │
     │ <────────────────────────┤ │                                │
     │                            │                                │
     │ 5. Send client cert        │                                │
     │ ├──────────────────────────>│                               │
     │                            │                                │
     │                            │ 6. Validate client cert        │
     │                            │    against CA                  │
     │                            │ ✅                              │
     │                            │                                │
     │ 7. Connection OK           │                                │
     │ ══════════════════════════>│                                │
     │         mTLS               │                                │
     │                            │ 8. HTTPS + HTTPD Client Cert   │
     │                            │   (httpd-client-bundle.pem)    │
     │                            ├──────────────────────────────> │
     │                            │                                │
     │                            │ 9. Validate HTTPD cert         │
     │                            │                                │ ✅
     │                            │ 10. Connection OK              │
     │                            │ <══════════════════════════════│
     │                            │         mTLS                   │
```

**Validation Points:**
- Client validates HTTPD server cert ✅
- HTTPD validates client cert ✅
- Spring Boot validates HTTPD client cert ✅
- **Total: 3 validations (Defense in Depth!)**

---

## 5️⃣ Certificate Files Used

### Scenario 1 (Port 8080)

| Certificate | Purpose | Used By |
|-------------|---------|---------|
| `httpd-server-cert.pem` | HTTPD server cert | Browser validates this |
| `httpd-client-bundle.pem` | HTTPD client cert | HTTPD uses to authenticate to Spring Boot |
| `ca-cert.pem` | CA certificate | Spring Boot trusts certs signed by this |

**Client certificates NOT used:**
- ❌ `client-cert.pem` (not needed for browser)

---

### Scenario 2 (Port 443)

| Certificate | Purpose | Used By |
|-------------|---------|---------|
| `httpd-server-cert.pem` | HTTPD server cert | Client validates this |
| `ca-cert.pem` (client validation) | CA certificate | HTTPD validates client certs against this |
| `client-cert.pem` | Client certificate | Client presents this to HTTPD |
| `httpd-client-bundle.pem` | HTTPD client cert | HTTPD uses to authenticate to Spring Boot |
| `ca-cert.pem` (backend validation) | CA certificate | Spring Boot trusts certs signed by this |

**All certificates used:** ✅

---

## 6️⃣ Testing the Configurations

### Test Scenario 1 (Port 8080)

```bash
# Should work - no certificate needed
curl -k https://localhost:8080/api/hello

# Response:
# {"authenticatedUser":"httpd-proxy","message":"Hello from secure endpoint!"}
```

---

### Test Scenario 2 (Port 443)

```bash
# Should FAIL - no certificate provided
curl -k https://localhost:443/api/hello
# Error: SSL certificate problem / handshake failure

# Should SUCCEED - with certificate
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello

# Response:
# {"authenticatedUser":"httpd-proxy","message":"Hello from secure endpoint!"}
```

---

## 7️⃣ Common Configuration Elements

Both scenarios share these settings:

```apache
# Modern TLS configuration
SSLProtocol -all +TLSv1.2 +TLSv1.3
SSLCipherSuite HIGH:!aNULL:!MD5:!3DES
SSLHonorCipherOrder on

# Session caching for performance
SSLSessionCache "shmcb:/usr/local/apache2/logs/ssl_scache(512000)"
SSLSessionCacheTimeout 300

# Proxy settings
ProxyPreserveHost On
ProxyTimeout 300

# Logging
ErrorLog /proc/self/fd/2
TransferLog /proc/self/fd/1
LogLevel warn
```

---

## 8️⃣ When to Use Which Configuration

### Use Scenario 1 (Port 8080) When:

- ✅ Building web applications for humans
- ✅ You control the proxy infrastructure
- ✅ Certificate distribution to users is impractical
- ✅ User experience is prioritized
- ✅ Backend security is still required
- ✅ Internal corporate applications

**Example:** Employee portal, customer dashboard, internal tools

---

### Use Scenario 2 (Port 443) When:

- ✅ Building API integrations
- ✅ Microservices communication
- ✅ Client identity is critical
- ✅ Highest security required
- ✅ Clients are applications, not humans
- ✅ Zero-trust architecture

**Example:** Service mesh, B2B APIs, IoT devices, payment systems

---

## 9️⃣ Production Considerations

### For Both Scenarios:

1. **Use Real CA Certificates**
   ```apache
   # Replace self-signed CA with real CA
   SSLCACertificateFile /path/to/real-ca.pem
   ```

2. **Enable OCSP Stapling**
   ```apache
   SSLUseStapling on
   SSLStaplingCache "shmcb:/var/run/ocsp(128000)"
   ```

3. **Implement Certificate Pinning** (optional, for high security)

4. **Monitor Certificate Expiration**
   - Set up alerts 30-60 days before expiration
   - Automate renewal with tools like cert-manager

5. **Logging and Monitoring**
   ```apache
   # Detailed logging for security audits
   LogLevel ssl:warn
   CustomLog /var/log/httpd/ssl_access_log combined
   ```

---

## 🔟 Quick Reference Table

| Feature | Port 8080 | Port 443 |
|---------|-----------|----------|
| **Client Cert Required** | ❌ No | ✅ Yes |
| **SSLVerifyClient** | `none` | `require` |
| **User Experience** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐ Complex |
| **Security Level** | ⭐⭐⭐⭐ High | ⭐⭐⭐⭐⭐ Maximum |
| **Backend Auth** | httpd-proxy | httpd-proxy |
| **Client Identity** | IP address only | Certificate DN |
| **Use Case** | Web apps | APIs/Services |
| **Cert Management** | Centralized | Distributed |

---

## Summary

**The core difference is one line:**
- Scenario 1: `SSLVerifyClient none` - Easy access
- Scenario 2: `SSLVerifyClient require` - Secure access

**Everything else supports this choice:**
- Headers passed
- Certificates validated
- Use cases served

Both scenarios maintain backend security through HTTPD's client certificate to Spring Boot!
