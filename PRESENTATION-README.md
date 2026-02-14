# Team Presentation Package

Complete package for demonstrating 2-way authentication to your team.

## 📦 What's Included

### Setup Scripts
- `setup-presentation.sh` / `setup-presentation.bat` - One-command setup
- `generate-httpd-client-cert.sh` / `.bat` - HTTPD proxy certificate

### Demo Scripts
- `demo-scenario1.sh` / `.bat` - Interactive demo for Scenario 1
- `demo-scenario2.sh` / `.bat` - Interactive demo for Scenario 2

### Documentation
- `QUICK-START-PRESENTATION.md` - 5-minute quick start guide
- `PRESENTATION-DEMO.md` - Complete 30-minute presentation script
- `ARCHITECTURE-DIAGRAMS.md` - Visual diagrams for explanation

### Infrastructure
- `docker-compose.presentation.yml` - Docker setup with both scenarios
- `httpd/Dockerfile.presentation` - Apache HTTPD with dual configuration
- `httpd/httpd-ssl-no-client-auth.conf` - Scenario 1 configuration
- `httpd/httpd-ssl-mtls.conf` - Scenario 2 configuration

---

## 🚀 Quick Start (5 Minutes)

### 1. Setup Everything

**Linux/Mac:**
```bash
chmod +x setup-presentation.sh
./setup-presentation.sh
```

**Windows:**
```cmd
setup-presentation.bat
```

### 2. Verify Setup

**Test Scenario 1:**
```bash
curl -k https://localhost:8080/api/hello
```

**Expected:** `"authenticatedUser": "httpd-proxy"`

**Test Scenario 2:**
```bash
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

**Expected:** `"authenticatedUser": "client1"`

---

## 🎯 Two Demonstration Scenarios

### Scenario 1: Browser Access (Port 8080)
**No client certificate required - HTTPD authenticates on behalf of clients**

**Perfect for:**
- Explaining proxy-based authentication
- Showing how browsers can access secure backends
- Demonstrating centralized certificate management

**Demo:**
```bash
./demo-scenario1.sh        # Linux/Mac
demo-scenario1.bat         # Windows
```

**Or manually in browser:**
```
https://localhost:8080/api/hello
https://localhost:8080/api/info
https://localhost:8080/api/status
```

**Key Teaching Points:**
- ✅ Browser doesn't need certificate
- ✅ HTTPD uses its own certificate to authenticate
- ✅ Backend sees "httpd-proxy" as authenticated user
- ✅ Good UX for web applications

---

### Scenario 2: End-to-End Mutual TLS (Port 443)
**Client certificate required - full mutual TLS authentication**

**Perfect for:**
- Showing true end-to-end security
- Demonstrating certificate validation
- Explaining API/microservice authentication

**Demo:**
```bash
./demo-scenario2.sh        # Linux/Mac
demo-scenario2.bat         # Windows
```

**Or manually with curl:**
```bash
# This will FAIL - no certificate
curl -k https://localhost:443/api/hello

# This will SUCCEED - with certificate
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

**Key Teaching Points:**
- ✅ Client must provide certificate
- ✅ Connection fails without valid certificate
- ✅ Backend sees actual client identity ("client1")
- ✅ Higher security, more complex management

---

## 📊 Presentation Flow (30 Minutes)

### Part 1: Introduction (3 min)
**Topics to Cover:**
- What is 2-way authentication (mutual TLS)?
- Why it matters in modern security
- Overview of both scenarios

**Visual Aid:** ARCHITECTURE-DIAGRAMS.md (comparison section)

---

### Part 2: Scenario 1 Demo (10 min)

**1. Live Browser Demo** (3 min)
```
https://localhost:8080/api/hello
```
- Show it works without certificate
- Point out no certificate prompt
- Explain user experience benefit

**2. Curl Demo** (2 min)
```bash
./demo-scenario1.sh
```
- Show same result with curl
- Display response JSON
- Point out "httpd-proxy" identity

**3. Technical Explanation** (3 min)
- Show HTTPD client certificate
- Explain proxy authentication
- Show architecture diagram

**4. Use Cases Discussion** (2 min)
- Web applications
- Internal tools
- Mobile apps

---

### Part 3: Scenario 2 Demo (10 min)

**1. Failure Demo** (2 min)
```bash
curl -k https://localhost:443/api/hello
```
- Show SSL handshake failure
- Explain why it failed
- Emphasize security in action

**2. Success Demo** (3 min)
```bash
./demo-scenario2.sh
```
- Show successful authentication
- Display "client1" identity
- Explain certificate validation

**3. Certificate Details** (2 min)
```bash
openssl x509 -in certs/client-cert.pem -noout -text
```
- Show certificate properties
- Explain CA signature
- Discuss trust chain

**4. Use Cases Discussion** (3 min)
- API integrations
- Microservices
- IoT devices
- B2B communication

---

### Part 4: Deep Dive (5 min)

**Configuration Walkthrough:**
```yaml
# Spring Boot - application.yml
server:
  ssl:
    client-auth: need    # ← Key setting
```

```apache
# HTTPD Scenario 1
SSLVerifyClient none    # ← No client cert needed
SSLProxyMachineCertificateFile ...  # ← HTTPD's cert

# HTTPD Scenario 2
SSLVerifyClient require    # ← Client cert required
```

**Show:**
- Spring Security configuration
- HTTPD configuration files
- Certificate files structure

---

### Part 5: Q&A (2 min)

**Common Questions:**
- Which scenario should we use?
- How do we manage certificates?
- What about certificate expiration?
- Can we combine with OAuth/JWT?
- Performance impact?

See PRESENTATION-DEMO.md for detailed Q&A

---

## 🎓 Key Takeaways

### For the Team

1. **Security Options**
   - Scenario 1: Easy UX, proxy-based security
   - Scenario 2: Maximum security, client identity

2. **Use Cases**
   - Web apps → Scenario 1
   - APIs/microservices → Scenario 2
   - Can use both in same system

3. **Implementation**
   - Spring Boot supports both easily
   - HTTPD can handle both scenarios
   - Certificate management is crucial

4. **Production Considerations**
   - Use real CA certificates
   - Implement cert rotation
   - Monitor expiration
   - Consider automation tools

---

## 📖 Documentation Quick Reference

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **QUICK-START-PRESENTATION.md** | 5-min setup guide | Before presentation |
| **PRESENTATION-DEMO.md** | Full presentation script | During presentation |
| **ARCHITECTURE-DIAGRAMS.md** | Visual explanations | During explanation |
| **README.md** | Technical details | After presentation |
| **WINDOWS-SETUP.md** | Windows specifics | For Windows users |

---

## 🛠️ Technical Details

### Ports Configuration

| Port | Scenario | Client Cert | Purpose |
|------|----------|-------------|---------|
| 8080 | Scenario 1 | ❌ Not required | Browser access |
| 443  | Scenario 2 | ✅ Required | API/mTLS access |
| 8443 | Direct | ✅ Required | Spring Boot direct |

### Certificate Files

```
certs/
├── ca-cert.pem              # Certificate Authority
├── ca-key.pem               # CA private key
├── server-cert.pem          # Server certificates
├── server-key.pem
├── httpd-client-cert.pem    # HTTPD's client cert (Scenario 1)
├── httpd-client-key.pem
├── httpd-client-bundle.pem  # Combined cert+key for Apache
├── client-cert.pem          # User client cert (Scenario 2)
├── client-key.pem
└── client.p12               # Browser import format
```

### Services Running

```
spring-app-mtls           - Spring Boot backend (8443)
httpd-proxy-presentation  - Apache HTTPD proxy (80, 443, 8080)
```

---

## 🔍 Troubleshooting

### Service Issues

**Check logs:**
```bash
docker-compose -f docker-compose.presentation.yml logs -f
```

**Restart services:**
```bash
docker-compose -f docker-compose.presentation.yml restart
```

### Certificate Issues

**Regenerate all:**
```bash
rm -rf certs/
./generate-certs.sh
./generate-httpd-client-cert.sh
docker-compose -f docker-compose.presentation.yml restart
```

### Port Conflicts

**Find what's using ports:**
```bash
# Linux/Mac
lsof -i :8080
lsof -i :443

# Windows
netstat -ano | findstr :8080
netstat -ano | findstr :443
```

---

## 🎬 Demo Script Examples

### Opening Statement
> "Today I'll demonstrate two approaches to mutual TLS authentication. The first shows how we can provide secure access to browsers without requiring certificates. The second demonstrates true end-to-end mutual authentication for APIs and microservices."

### Scenario 1 Introduction
> "In this first scenario, we're using Apache HTTPD as a trusted proxy. Watch what happens when I access the API from my browser - I don't need any client certificate. The proxy authenticates to the backend on my behalf."

### Scenario 2 Introduction
> "Now let's see true mutual TLS. First, I'll try to connect without a certificate... see, it fails. Now with a valid certificate... it succeeds. This is how APIs and microservices can verify each other's identity cryptographically."

### Closing Statement
> "Both approaches have their place. For web applications and user-facing services, Scenario 1 provides better UX. For API integrations and microservices where you need strong identity verification, Scenario 2 is the way to go. Questions?"

---

## 📝 Presenter Notes

### Before Presentation
- [ ] Run setup script
- [ ] Test both scenarios
- [ ] Open documentation files
- [ ] Prepare browser window
- [ ] Have terminal ready with scripts

### During Presentation
- [ ] Keep architecture diagrams visible
- [ ] Show actual certificate files
- [ ] Demonstrate both success and failure
- [ ] Explain "why" not just "how"
- [ ] Encourage questions

### After Presentation
- [ ] Share documentation links
- [ ] Provide access to code repository
- [ ] Schedule follow-up if needed
- [ ] Clean up demo environment

---

## 🧹 Cleanup

**Stop services:**
```bash
docker-compose -f docker-compose.presentation.yml down
```

**Remove everything:**
```bash
docker-compose -f docker-compose.presentation.yml down -v
rm -rf certs/
```

---

## 🎯 Success Criteria

Your presentation is successful if the team understands:

1. ✅ **What** mutual TLS is
2. ✅ **Why** it matters for security
3. ✅ **When** to use each scenario
4. ✅ **How** it works technically
5. ✅ **Where** to implement it

---

## 📞 Support

For questions or issues:
- Review PRESENTATION-DEMO.md for detailed Q&A
- Check README.md for technical details
- See WINDOWS-SETUP.md for Windows-specific help

---

Good luck with your presentation! 🎉

**Remember:** The goal is to educate, not to overwhelm. Focus on the concepts and use cases, then dive into technical details as needed.
