# Quick Start: Team Presentation

This guide gets you ready for the team presentation in 5 minutes.

## 🚀 One-Command Setup

**Linux/Mac:**
```bash
chmod +x setup-presentation.sh
./setup-presentation.sh
```

**Windows:**
```cmd
setup-presentation.bat
```

This will:
1. ✅ Generate all certificates (CA, server, client, HTTPD proxy)
2. ✅ Build Docker images
3. ✅ Start all services
4. ✅ Verify everything is working

## 📊 Two Scenarios Ready

### Scenario 1: Browser Access (Port 8080)
**No client certificate needed - HTTPD authenticates for you**

**Test in Browser:**
```
https://localhost:8080/api/hello
```

**Run Demo Script:**
```bash
./demo-scenario1.sh        # Linux/Mac
demo-scenario1.bat         # Windows
```

**What to Show:**
- Browser access without certificate
- HTTPD acts as trusted proxy
- Backend receives authenticated request
- User identity: "httpd-proxy"

---

### Scenario 2: End-to-End mTLS (Port 443)
**Client certificate required**

**Test with curl:**
```bash
# Will fail - no certificate
curl -k https://localhost:443/api/hello

# Will succeed - with certificate
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

**Run Demo Script:**
```bash
./demo-scenario2.sh        # Linux/Mac
demo-scenario2.bat         # Windows
```

**What to Show:**
- Request fails without certificate
- Request succeeds with valid certificate
- Certificate validation in action
- User identity: "client1" (actual client)

---

## 🎬 Presentation Flow (30 minutes)

### 1. Introduction (3 min)
- What is mutual TLS?
- Why it matters for security
- Two scenarios we'll demonstrate

### 2. Scenario 1 Demo (10 min)
```bash
./demo-scenario1.sh
```
- Show browser access
- Explain proxy authentication
- Show HTTPD certificate
- Discuss use cases (web apps)

### 3. Scenario 2 Demo (10 min)
```bash
./demo-scenario2.sh
```
- Show failed access (no cert)
- Show successful access (with cert)
- Explain certificate chain
- Discuss use cases (APIs, microservices)

### 4. Comparison & Q&A (7 min)
- Compare both scenarios
- Show configuration differences
- Answer questions
- Next steps

---

## 🔍 Quick Tests

### Scenario 1 Tests
```bash
# Browser-friendly (no cert)
curl -k https://localhost:8080/api/hello
curl -k https://localhost:8080/api/info
curl -k https://localhost:8080/api/status
```

**Expected Response:**
```json
{
  "message": "Hello from secure endpoint!",
  "authenticatedUser": "httpd-proxy",
  "timestamp": "..."
}
```

### Scenario 2 Tests
```bash
# Requires client certificate
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
  "timestamp": "..."
}
```

---

## 📝 Key Points to Emphasize

### Scenario 1 (HTTPD Proxy Auth)
✅ Users don't need certificates
✅ HTTPD authenticates to backend
✅ Good for web applications
✅ Easier user experience
✅ Backend identity: proxy server

### Scenario 2 (End-to-End mTLS)
✅ True mutual authentication
✅ Client provides certificate
✅ Backend knows actual client
✅ Best for APIs/microservices
✅ Higher security posture

---

## 🛠️ Troubleshooting

### Services not starting?
```bash
docker-compose -f docker-compose.presentation.yml logs
```

### Port conflicts?
```bash
# Check what's using the ports
netstat -an | grep 8080
netstat -an | grep 443
```

### Certificates missing?
```bash
# Regenerate everything
rm -rf certs/
./generate-certs.sh
./generate-httpd-client-cert.sh
```

---

## 🎯 Port Reference

| Port | Purpose | Client Cert Required | Identity |
|------|---------|---------------------|----------|
| 8080 | Scenario 1 - Proxy Auth | ❌ No | httpd-proxy |
| 443  | Scenario 2 - End-to-End mTLS | ✅ Yes | client1 |
| 8443 | Spring Boot Direct | ✅ Yes | client1 |

---

## 📖 Full Documentation

For detailed information, see:
- **PRESENTATION-DEMO.md** - Complete presentation guide with Q&A
- **README.md** - Technical documentation
- **WINDOWS-SETUP.md** - Windows-specific setup

---

## 🧹 Cleanup After Presentation

```bash
# Stop services
docker-compose -f docker-compose.presentation.yml down

# Remove volumes (optional)
docker-compose -f docker-compose.presentation.yml down -v
```

---

## ✅ Pre-Presentation Checklist

Before your presentation:

- [ ] Run `./setup-presentation.sh` (or `.bat`)
- [ ] Verify both scenarios work
- [ ] Test in browser (https://localhost:8080/api/hello)
- [ ] Test with curl (both with and without cert)
- [ ] Open PRESENTATION-DEMO.md for reference
- [ ] Have certificates location ready to show
- [ ] Prepare to answer common questions

---

## 💡 Demo Tips

1. **Start Simple**: Begin with Scenario 1 (easier to understand)
2. **Show Failure**: Demonstrate Scenario 2 without cert first (shows security)
3. **Show Success**: Then show with cert (explains why certs matter)
4. **Visual Aids**: Keep architecture diagrams visible
5. **Real Browser**: Demonstrate Scenario 1 in actual browser
6. **Explain Identity**: Emphasize the different `authenticatedUser` values

---

## 🎓 Common Questions

**Q: Which scenario should we use?**
A: Depends on your use case:
- Web applications → Scenario 1
- API/microservices → Scenario 2

**Q: How do we distribute certificates?**
A: Options include:
- Embedded in application/device
- Certificate management systems (Vault, cert-manager)
- Cloud provider services (AWS ACM, etc.)

**Q: What about certificate expiration?**
A: Implement:
- Automated rotation (cert-manager, Vault)
- Monitoring and alerts
- Short validity periods (90 days)

---

Ready to present! Good luck! 🎉
