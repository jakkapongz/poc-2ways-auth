# POC 2-Way Authentication - Documentation Index

Complete documentation for the 2-Way Authentication (Mutual TLS) Proof of Concept.

---

## 🚀 Getting Started

### For Team Presentation

1. **Start Here:** [QUICK-START-PRESENTATION.md](QUICK-START-PRESENTATION.md)
   - 5-minute setup guide
   - Quick verification steps
   - Ready-to-go commands

2. **Presentation Guide:** [PRESENTATION-DEMO.md](PRESENTATION-DEMO.md)
   - Complete 30-minute script
   - Step-by-step demonstration
   - Q&A section

3. **Visual Aids:** [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md)
   - Flow diagrams for both scenarios
   - Side-by-side comparisons
   - Certificate hierarchy

4. **Presenter Reference:** [PRESENTATION-README.md](PRESENTATION-README.md)
   - Complete presentation package overview
   - Presenter notes and tips
   - Demo script examples

### For Development/Testing

1. **Start Here:** [README.md](README.md)
   - Technical documentation
   - API endpoints
   - Configuration details
   - Cross-platform instructions

2. **Windows Users:** [WINDOWS-SETUP.md](WINDOWS-SETUP.md)
   - Windows-specific setup
   - Troubleshooting
   - IDE configuration

3. **Project Overview:** [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)
   - Architecture overview
   - Use cases
   - Technology stack
   - Production considerations

---

## 📂 File Organization

### Setup Scripts

| File | Platform | Purpose |
|------|----------|---------|
| `setup-presentation.sh` | Linux/Mac | Complete setup for presentation |
| `setup-presentation.bat` | Windows | Complete setup for presentation |
| `generate-certs.sh` | Linux/Mac | Generate base certificates |
| `generate-certs.bat` | Windows | Generate base certificates |
| `generate-httpd-client-cert.sh` | Linux/Mac | Generate HTTPD proxy certificate |
| `generate-httpd-client-cert.bat` | Windows | Generate HTTPD proxy certificate |

### Demo Scripts

| File | Platform | Purpose |
|------|----------|---------|
| `demo-scenario1.sh` | Linux/Mac | Interactive demo - Scenario 1 |
| `demo-scenario1.bat` | Windows | Interactive demo - Scenario 1 |
| `demo-scenario2.sh` | Linux/Mac | Interactive demo - Scenario 2 |
| `demo-scenario2.bat` | Windows | Interactive demo - Scenario 2 |
| `test-endpoints.sh` | Linux/Mac | Automated endpoint testing |
| `test-endpoints.bat` | Windows | Automated endpoint testing |
| `test-endpoints.ps1` | PowerShell | Automated endpoint testing |

### Documentation

| File | Purpose | Target Audience |
|------|---------|----------------|
| **INDEX.md** | This file - Documentation index | Everyone |
| **README.md** | Main technical documentation | Developers |
| **QUICK-START-PRESENTATION.md** | 5-minute setup guide | Presenters |
| **PRESENTATION-DEMO.md** | Complete presentation script | Presenters |
| **PRESENTATION-README.md** | Presentation package overview | Presenters |
| **ARCHITECTURE-DIAGRAMS.md** | Visual diagrams | Presenters/Architects |
| **WINDOWS-SETUP.md** | Windows-specific guide | Windows users |
| **PROJECT-SUMMARY.md** | High-level overview | Managers/Architects |

### Configuration

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Standard Docker setup |
| `docker-compose.presentation.yml` | Presentation Docker setup (both scenarios) |
| `httpd/httpd-ssl-mtls.conf` | HTTPD config - Scenario 2 (mTLS) |
| `httpd/httpd-ssl-no-client-auth.conf` | HTTPD config - Scenario 1 (proxy auth) |
| `httpd/Dockerfile` | Standard HTTPD Docker image |
| `httpd/Dockerfile.presentation` | Presentation HTTPD Docker image |
| `Dockerfile` | Spring Boot Docker image |
| `build.gradle` | Gradle build configuration |
| `Makefile` | Build automation (Linux/Mac) |

### Source Code

| Directory | Contents |
|-----------|----------|
| `src/main/java/com/example/mtls/` | Spring Boot application |
| `src/main/java/com/example/mtls/config/` | Security configuration |
| `src/main/java/com/example/mtls/controller/` | REST controllers |
| `src/main/resources/` | Application configuration |

---

## 🎯 Quick Navigation by Task

### I want to... present this to my team

1. Read: [QUICK-START-PRESENTATION.md](QUICK-START-PRESENTATION.md)
2. Run: `./setup-presentation.sh` (or `.bat`)
3. Reference: [PRESENTATION-DEMO.md](PRESENTATION-DEMO.md)
4. Show: [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md)

### I want to... understand how it works

1. Read: [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)
2. Review: [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md)
3. Deep dive: [README.md](README.md)

### I want to... set it up on Windows

1. Read: [WINDOWS-SETUP.md](WINDOWS-SETUP.md)
2. Run: `generate-certs.bat`
3. Run: `docker-compose up --build`
4. Test: `test-endpoints.bat`

### I want to... set it up on Linux/Mac

1. Run: `./generate-certs.sh`
2. Run: `docker-compose up --build`
3. Test: `./test-endpoints.sh`
4. Reference: [README.md](README.md)

### I want to... understand the differences between scenarios

1. Read: [PRESENTATION-DEMO.md](PRESENTATION-DEMO.md) - Comparison section
2. View: [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md) - Side-by-side
3. Try: `./demo-scenario1.sh` and `./demo-scenario2.sh`

### I want to... deploy to production

1. Read: [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) - Production section
2. Review: [README.md](README.md) - Security features
3. Plan: Certificate management strategy
4. Implement: Real CA certificates
5. Setup: Monitoring and rotation

---

## 📊 Two Scenarios Explained

### Scenario 1: Browser Access (Port 8080)
**Files:**
- Config: `httpd/httpd-ssl-no-client-auth.conf`
- Demo: `demo-scenario1.sh` / `.bat`
- Cert: `certs/httpd-client-cert.pem`

**What:**
- Browser connects without client certificate
- HTTPD authenticates to Spring Boot using its own certificate
- Good for web applications

**Read:**
- [PRESENTATION-DEMO.md](PRESENTATION-DEMO.md#scenario-1)
- [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md#scenario-1)

### Scenario 2: End-to-End mTLS (Port 443)
**Files:**
- Config: `httpd/httpd-ssl-mtls.conf`
- Demo: `demo-scenario2.sh` / `.bat`
- Cert: `certs/client-cert.pem`

**What:**
- Client must provide valid certificate
- Both HTTPD and Spring Boot validate
- Good for APIs and microservices

**Read:**
- [PRESENTATION-DEMO.md](PRESENTATION-DEMO.md#scenario-2)
- [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md#scenario-2)

---

## 🔧 Common Commands

### Setup
```bash
# Linux/Mac
./setup-presentation.sh
./generate-certs.sh
./generate-httpd-client-cert.sh

# Windows
setup-presentation.bat
generate-certs.bat
generate-httpd-client-cert.bat
```

### Running
```bash
# Presentation mode (both scenarios)
docker-compose -f docker-compose.presentation.yml up --build

# Standard mode
docker-compose up --build

# Local Gradle
./gradlew bootRun          # Linux/Mac
gradlew.bat bootRun        # Windows
```

### Testing
```bash
# Scenario 1 (no cert needed)
curl -k https://localhost:8080/api/hello

# Scenario 2 (cert required)
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

### Demos
```bash
# Interactive demos
./demo-scenario1.sh        # Linux/Mac
demo-scenario1.bat         # Windows

./demo-scenario2.sh        # Linux/Mac
demo-scenario2.bat         # Windows
```

---

## 🎓 Learning Path

### Beginner
1. Start: [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) - Overview
2. Understand: [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md) - Visuals
3. Try: `./demo-scenario1.sh` - Simple scenario
4. Try: `./demo-scenario2.sh` - Advanced scenario

### Intermediate
1. Setup: `./setup-presentation.sh` - Complete environment
2. Read: [README.md](README.md) - Technical details
3. Explore: Spring Boot code in `src/`
4. Customize: Modify configurations

### Advanced
1. Study: Certificate generation scripts
2. Modify: `SecurityConfig.java`
3. Extend: Add custom authentication logic
4. Deploy: Production planning

---

## 🐛 Troubleshooting

### Quick Fixes
- **Services won't start:** Check [README.md](README.md#troubleshooting)
- **Windows issues:** Check [WINDOWS-SETUP.md](WINDOWS-SETUP.md)
- **Certificate errors:** Regenerate with cert scripts
- **Port conflicts:** Change ports in docker-compose

### Detailed Help
- General: [README.md](README.md#troubleshooting)
- Windows: [WINDOWS-SETUP.md](WINDOWS-SETUP.md#common-issues-and-solutions)
- Presentation: [PRESENTATION-DEMO.md](PRESENTATION-DEMO.md#troubleshooting)

---

## 📞 Support Resources

### Documentation
- All docs in this repository
- Inline code comments
- Configuration file comments

### External Resources
- [Spring Security X.509 Docs](https://docs.spring.io/spring-security/reference/servlet/authentication/x509.html)
- [Apache HTTPD SSL/TLS](https://httpd.apache.org/docs/2.4/ssl/)
- [Mutual TLS Best Practices](https://www.rfc-editor.org/rfc/rfc8705.html)

---

## ✅ Checklist by Role

### For Presenters
- [ ] Read: QUICK-START-PRESENTATION.md
- [ ] Run: setup-presentation.sh
- [ ] Practice: demo-scenario1.sh and demo-scenario2.sh
- [ ] Review: PRESENTATION-DEMO.md (Q&A section)
- [ ] Prepare: ARCHITECTURE-DIAGRAMS.md (print or display)

### For Developers
- [ ] Read: README.md
- [ ] Run: generate-certs.sh
- [ ] Build: gradlew build
- [ ] Test: test-endpoints.sh
- [ ] Review: src/ code

### For Windows Users
- [ ] Read: WINDOWS-SETUP.md
- [ ] Install: Prerequisites (OpenSSL, Java, Docker)
- [ ] Run: generate-certs.bat
- [ ] Test: test-endpoints.bat

### For Architects
- [ ] Read: PROJECT-SUMMARY.md
- [ ] Review: ARCHITECTURE-DIAGRAMS.md
- [ ] Study: Security features
- [ ] Plan: Production deployment

---

## 🎯 Key Files by Importance

### Must Read (Everyone)
1. **This file (INDEX.md)** - You are here
2. [README.md](README.md) - Main documentation

### Must Read (Presenters)
3. [QUICK-START-PRESENTATION.md](QUICK-START-PRESENTATION.md)
4. [PRESENTATION-DEMO.md](PRESENTATION-DEMO.md)

### Should Read
5. [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)
6. [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md)

### Platform Specific
7. [WINDOWS-SETUP.md](WINDOWS-SETUP.md) - Windows users only

---

## 📈 Version Information

**Project:** POC 2-Way Authentication
**Version:** 1.0.0
**Spring Boot:** 3.2.2
**Java:** 17
**Gradle:** 8.5

---

## 🎉 Quick Wins

Get up and running in:

- **5 minutes:** Run `setup-presentation.sh`
- **10 minutes:** Complete both scenario demos
- **30 minutes:** Full team presentation
- **1 hour:** Deep technical understanding

---

**Start exploring!** Pick your path above and dive in. Every document is written to stand alone, but they're even better together.

Happy learning! 🚀
