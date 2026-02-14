# Production Setup Guide - Real Implementation

**This guide is for the ACTUAL production setup, not the POC demo.**

---

## Your Situation

You need to configure HTTPD to proxy requests to an **existing Spring Boot service** owned by another team.

### Architecture

```
User (no client cert)
    ↓
[Relay Component] - Handles SSL/TLS termination
    ↓ (Plain HTTP)
[YOUR HTTPD on port 14xxx] - You configure this
    ↓ (HTTPS + Client Certificate - 2-way auth)
[Their Spring Boot Service] - Already running, requires client cert
```

### What You Have

- ✅ Their `.p12` client certificate file
- ✅ Password for the `.p12` file
- ✅ CentOS 7 server with custom HTTPD 2.4.59 (missing SSL/proxy modules)

### What You Need to Do

1. Add SSL/proxy modules to HTTPD
2. Convert their `.p12` to PEM format
3. Configure HTTPD to proxy with client certificate authentication

---

## Step 1: Compile HTTPD Modules (~40 minutes)

Your custom HTTPD is missing required modules. Compile them:

```bash
# Install build tools
sudo yum install -y gcc make apr-devel apr-util-devel openssl-devel httpd-devel

# Download Apache HTTPD source (match your version)
cd /tmp
wget https://downloads.apache.org/httpd/httpd-2.4.59.tar.bz2
tar xjf httpd-2.4.59.tar.bz2
cd httpd-2.4.59

# Configure for module building
./configure \
    --with-apr=/usr/bin/apr-1-config \
    --with-apr-util=/usr/bin/apu-1-config \
    --enable-ssl=shared \
    --enable-proxy=shared \
    --enable-proxy-http=shared \
    --enable-headers=shared \
    --enable-socache-shmcb=shared \
    --enable-so

# Build modules
make

# Backup existing modules
sudo cp -r /etc/httpd/modules /etc/httpd/modules.backup.$(date +%Y%m%d)

# Install new modules
sudo cp modules/ssl/.libs/mod_ssl.so /etc/httpd/modules/
sudo cp modules/proxy/.libs/mod_proxy.so /etc/httpd/modules/
sudo cp modules/proxy/.libs/mod_proxy_http.so /etc/httpd/modules/
sudo cp modules/metadata/.libs/mod_headers.so /etc/httpd/modules/
sudo cp modules/cache/.libs/mod_socache_shmcb.so /etc/httpd/modules/

# Set permissions
sudo chmod 755 /etc/httpd/modules/mod_*.so
sudo chown root:root /etc/httpd/modules/mod_*.so

# Verify
ls -la /etc/httpd/modules/ | grep -E "ssl|proxy|headers|socache"
```

---

## Step 2: Convert Their .p12 Certificate (~5 minutes)

Convert the `.p12` file they gave you to PEM format for HTTPD:

```bash
# Create certs directory
sudo mkdir -p /etc/httpd/certs

# Convert .p12 to PEM bundle (cert + key combined)
openssl pkcs12 -in /path/to/their-client-cert.p12 -out /tmp/httpd-client-bundle.pem -nodes
# Enter their password when prompted

# Extract CA certificate (if included in .p12)
openssl pkcs12 -in /path/to/their-client-cert.p12 -cacerts -nokeys -out /tmp/ca-cert.pem
# Enter their password when prompted

# Verify what was extracted
echo "=== Client Certificate Info ==="
openssl x509 -in /tmp/httpd-client-bundle.pem -noout -subject -issuer
echo ""
echo "=== CA Certificate Info ==="
openssl x509 -in /tmp/ca-cert.pem -noout -subject

# If CA extraction succeeded, copy files to HTTPD location
sudo cp /tmp/httpd-client-bundle.pem /etc/httpd/certs/
sudo cp /tmp/ca-cert.pem /etc/httpd/certs/
sudo chmod 600 /etc/httpd/certs/*.pem
sudo chown root:root /etc/httpd/certs/*.pem

# Clean up temp files
rm /tmp/httpd-client-bundle.pem /tmp/ca-cert.pem
```

**If CA extraction fails:**
Ask the other team for the CA certificate file separately.

---

## Step 3: Configure HTTPD (~10 minutes)

### 3.1 Enable Modules

Edit `/etc/httpd/conf/httpd.conf`:

```bash
sudo vi /etc/httpd/conf/httpd.conf
```

Add these lines (at the end of LoadModule section):

```apache
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule headers_module modules/mod_headers.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
```

### 3.2 Create Proxy Configuration

Create `/etc/httpd/conf.d/mtls-proxy.conf`:

```bash
sudo vi /etc/httpd/conf.d/mtls-proxy.conf
```

**IMPORTANT:** Replace placeholders with actual values from the other team:
- `14088` → Your assigned port number
- `their-springboot-host` → Their Spring Boot hostname/IP
- `8443` → Their Spring Boot port
- `/my-api` → Their API context path

```apache
# Production Configuration: HTTP In, HTTPS Out with Client Cert
# Relay handles SSL termination - HTTPD receives plain HTTP
# HTTPD proxies to backend Spring Boot with client certificate authentication

Listen 14088

<VirtualHost *:14088>
    ServerName your-server.example.com

    # NO SSL for incoming connections (Relay handles this)
    # SSLEngine is NOT enabled here

    # Logging
    ErrorLog /var/log/httpd/mtls_error_log
    CustomLog /var/log/httpd/mtls_access_log combined
    LogLevel warn

    # Reverse proxy configuration
    ProxyPreserveHost On
    ProxyTimeout 300

    # Enable SSL for OUTGOING connections to backend Spring Boot
    SSLProxyEngine On

    # HTTPD authenticates to Spring Boot using their client certificate
    SSLProxyMachineCertificateFile /etc/httpd/certs/httpd-client-bundle.pem

    # Trust backend server certificate
    SSLProxyCACertificateFile /etc/httpd/certs/ca-cert.pem
    SSLProxyVerify require
    SSLProxyCheckPeerCN on
    SSLProxyCheckPeerName off

    # Headers to track request origin
    RequestHeader set X-Proxy-Client "httpd-proxy"
    RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}e"
    RequestHeader set X-Forwarded-Proto "https"

    # Route to their Spring Boot service
    # ⚠️ CHANGE THESE VALUES ⚠️
    ProxyPass /my-api https://their-springboot-host:8443/my-api
    ProxyPassReverse /my-api https://their-springboot-host:8443/my-api

    <Location /my-api>
        Require all granted
    </Location>

</VirtualHost>
```

---

## Step 4: Test Configuration (~10 minutes)

```bash
# 1. Test HTTPD config syntax
sudo httpd -t
# Expected: Syntax OK

# 2. Check modules are loaded
sudo httpd -M | grep -E "proxy|ssl|headers"
# Expected: Should see mod_ssl, mod_proxy, mod_proxy_http, mod_headers

# 3. Restart HTTPD
sudo systemctl restart httpd

# 4. Check HTTPD is listening
sudo netstat -tlnp | grep :14088
# Expected: httpd process listening on port 14088

# 5. Test from localhost (plain HTTP to HTTPD)
curl http://localhost:14088/my-api/hello

# 6. Check logs if there are errors
sudo tail -f /var/log/httpd/mtls_error_log
```

---

## Step 5: Verify with Relay Component

Once HTTPD is configured, test the full flow:

```bash
# From a machine that can access the Relay
curl -k https://your-relay-host/my-api/hello

# Should return response from their Spring Boot service
```

---

## Information to Get from the Other Team

Before Monday, ask them:

1. **"What is the hostname and port of your Spring Boot service?"**
   - For `ProxyPass` configuration
   - Example: `their-server.example.com:8443`

2. **"What is the context path for your API?"**
   - For `ProxyPass` configuration
   - Example: `/api`, `/service`, `/my-api`

3. **"Is the CA certificate included in the .p12 file, or do you have it separately?"**
   - If separate, ask them to provide it

4. **"Can you verify the .p12 works with Postman?"**
   - Test before Monday to ensure the certificate is valid

---

## Troubleshooting

### Issue: "cannot load SSL module"

```bash
# Check if mod_ssl.so exists
ls -la /etc/httpd/modules/mod_ssl.so

# Check file permissions
sudo chmod 755 /etc/httpd/modules/mod_ssl.so
```

### Issue: "Proxy client certificate callback: downstream server wanted client certificate but none are configured"

```bash
# Verify bundle file exists and has both cert and key
openssl x509 -in /etc/httpd/certs/httpd-client-bundle.pem -noout -text
openssl rsa -in /etc/httpd/certs/httpd-client-bundle.pem -check

# Check file permissions
sudo chmod 600 /etc/httpd/certs/httpd-client-bundle.pem
```

### Issue: "SSL certificate problem: unable to verify"

```bash
# Verify CA certificate
openssl x509 -in /etc/httpd/certs/ca-cert.pem -noout -text

# Test certificate chain
openssl verify -CAfile /etc/httpd/certs/ca-cert.pem /etc/httpd/certs/httpd-client-bundle.pem
```

### Issue: Cannot extract CA from .p12

```bash
# List all contents of .p12
openssl pkcs12 -in their-cert.p12 -info -nodes
# Enter password when prompted

# If CA not in .p12, ask the other team for it
```

---

## Rollback Plan

If something goes wrong:

```bash
# Stop HTTPD
sudo systemctl stop httpd

# Restore original modules
sudo rm /etc/httpd/modules/mod_ssl.so /etc/httpd/modules/mod_proxy*.so /etc/httpd/modules/mod_headers.so
sudo cp /etc/httpd/modules.backup.YYYYMMDD/* /etc/httpd/modules/

# Remove configuration
sudo rm /etc/httpd/conf.d/mtls-proxy.conf

# Remove LoadModule lines from httpd.conf
sudo vi /etc/httpd/conf/httpd.conf

# Restart
sudo systemctl start httpd
```

---

## Summary Checklist

- [ ] Compile and install HTTPD SSL/proxy modules
- [ ] Convert their .p12 to PEM format
- [ ] Get CA certificate (from .p12 or from them)
- [ ] Enable modules in httpd.conf
- [ ] Create proxy configuration
- [ ] Test HTTPD config syntax
- [ ] Restart HTTPD
- [ ] Test locally
- [ ] Test through Relay
- [ ] Verify with their team

**Estimated Total Time: 60-75 minutes**

---

## The Difference: POC vs Production

| Aspect | POC (Demo) | Production (Real) |
|--------|------------|-------------------|
| **Purpose** | Show how 2-way auth works | Actually proxy to their service |
| **Spring Boot** | You deploy from repo | Their existing service |
| **Certificates** | Generate your own | Use their .p12 file |
| **Deployment** | Docker or native | HTTPD config only |
| **Backend** | localhost:8443 | their-server:8443 |

The POC is for **understanding and presentation**.
Production is for **actual implementation**.

---

Good luck on Monday! 🚀
