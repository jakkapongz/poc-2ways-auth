# Architecture Diagrams for Presentation

Use these diagrams during your team presentation to explain the two scenarios.

---

## Scenario 1: Browser Access (HTTPD Proxy Authentication)

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         SCENARIO 1                              │
│              Browser Access (No Client Certificate)             │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   Browser    │  User: John Doe
│   (Chrome)   │  Certificate: NONE ❌
└──────┬───────┘
       │
       │ Step 1: HTTPS Connection
       │ Port: 8080
       │ Client Cert: Not Required
       │
       ▼
┌──────────────────────┐
│   Apache HTTPD       │  Server Certificate: ✅
│   (Reverse Proxy)    │  Validates Browser: ❌ (not required)
│                      │  Identity: httpd-proxy
└──────┬───────────────┘
       │
       │ Step 2: HTTPS Connection with mTLS
       │ Port: 8443
       │ Client Cert: httpd-client-cert.pem ✅
       │ HTTPD authenticates on behalf of browser
       │
       ▼
┌──────────────────────┐
│   Spring Boot App    │  Server Certificate: ✅
│   (Backend API)      │  Validates Client Cert: ✅ (httpd-proxy)
│                      │  Authenticated User: "httpd-proxy"
└──────────────────────┘

Response Flow: ← ← ←

Spring Boot Response:
{
  "authenticatedUser": "httpd-proxy",  ← Backend sees proxy, not browser
  "message": "Hello from secure endpoint!"
}
```

### Certificate Chain

```
Certificate Authority (CA)
    │
    ├─── Server Certificate (HTTPD) ──→ Used for browser connection
    │        Subject: CN=localhost
    │
    ├─── Server Certificate (Spring) ──→ Used for backend HTTPS
    │        Subject: CN=localhost
    │
    └─── Client Certificate (HTTPD) ──→ Used by HTTPD to authenticate to Spring
             Subject: CN=httpd-proxy
             Purpose: Backend authentication
```

### Key Points

1. ✅ **Browser doesn't need certificate**
   - Standard HTTPS connection
   - No certificate installation required
   - Good user experience

2. ✅ **HTTPD acts as trusted intermediary**
   - Has its own client certificate
   - Authenticates to backend
   - Single certificate to manage

3. ✅ **Backend is still secured**
   - Requires valid client certificate
   - Only trusts known proxies
   - Mutual TLS enforced

---

## Scenario 2: End-to-End Mutual TLS

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         SCENARIO 2                              │
│         End-to-End Mutual TLS (Client Certificate Required)     │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   Client     │  Application: API Client / curl
│   (API/CLI)  │  Certificate: client-cert.pem ✅
│              │  Identity: client1
└──────┬───────┘
       │
       │ Step 1: HTTPS Connection with mTLS
       │ Port: 443
       │ Client Cert: client-cert.pem ✅
       │ Client must provide valid certificate
       │
       ▼
┌──────────────────────┐
│   Apache HTTPD       │  Server Certificate: ✅
│   (Reverse Proxy)    │  Validates Client Cert: ✅
│                      │  Verified: CN=client1
└──────┬───────────────┘
       │
       │ Step 2: HTTPS Connection (proxied)
       │ Port: 8443
       │ Client Cert: Forwarded ✅
       │ Client identity preserved
       │
       ▼
┌──────────────────────┐
│   Spring Boot App    │  Server Certificate: ✅
│   (Backend API)      │  Validates Client Cert: ✅
│                      │  Authenticated User: "client1"
└──────────────────────┘

Response Flow: ← ← ←

Spring Boot Response:
{
  "authenticatedUser": "client1",  ← Backend sees actual client
  "message": "Hello from secure endpoint!"
}
```

### Certificate Chain

```
Certificate Authority (CA)
    │
    ├─── Server Certificate (HTTPD) ──→ Used for client connection
    │        Subject: CN=localhost
    │
    ├─── Server Certificate (Spring) ──→ Used for backend HTTPS
    │        Subject: CN=localhost
    │
    └─── Client Certificate (client1) ──→ Required from API clients
             Subject: CN=client1
             Purpose: Client authentication
```

### Authentication Flow

```
Without Certificate:
┌────────┐  HTTPS (no cert)   ┌───────────┐
│ Client │ ─────────────────→ │   HTTPD   │
└────────┘                     └─────┬─────┘
                                     │
                                     ▼
                              ❌ SSL Handshake Failed
                              Connection Rejected


With Valid Certificate:
┌────────┐  HTTPS + cert      ┌───────────┐  HTTPS    ┌────────────┐
│ Client │ ─────────────────→ │   HTTPD   │ ────────→ │   Spring   │
└────────┘  CN=client1        └───────────┘           └────────────┘
                ✅ Validated            ✅ Validated
                by HTTPD                by Spring

                                     ↓
                              Success! User: client1
```

### Key Points

1. ✅ **Client must have certificate**
   - Certificate installation required
   - Certificate management needed
   - Higher security barrier

2. ✅ **Double validation**
   - HTTPD validates client cert
   - Spring Boot also validates
   - Defense in depth

3. ✅ **True client identity**
   - Backend knows actual client
   - No intermediary identity
   - Full audit trail

---

## Side-by-Side Comparison

```
┌──────────────────────────┬──────────────────────────┐
│      SCENARIO 1          │      SCENARIO 2          │
│   (Proxy Auth)           │   (End-to-End mTLS)      │
├──────────────────────────┼──────────────────────────┤
│                          │                          │
│  Browser (No Cert)       │  Client (With Cert)      │
│       │                  │       │                  │
│       │ HTTPS            │       │ HTTPS + Cert     │
│       ▼                  │       ▼                  │
│  HTTPD (Port 8080)       │  HTTPD (Port 443)        │
│  - No client auth        │  - Requires client cert  │
│  - Uses own cert         │  - Validates cert        │
│       │                  │       │                  │
│       │ mTLS             │       │ Proxied          │
│       ▼                  │       ▼                  │
│  Spring Boot             │  Spring Boot             │
│  - Sees "httpd-proxy"    │  - Sees "client1"        │
│  - Backend secured       │  - End-to-end secured    │
│                          │                          │
└──────────────────────────┴──────────────────────────┘

Use Case:                    Use Case:
- Web Applications           - API Integration
- Mobile Apps               - Microservices
- Internal Tools            - B2B Communication
- Easy UX                   - IoT Devices
                            - High Security
```

---

## Certificate Hierarchy

```
                    ┌─────────────────────────┐
                    │  Certificate Authority  │
                    │        (CA)             │
                    │  ca-cert.pem            │
                    └───────────┬─────────────┘
                                │
                                │ Signs all certificates
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                    │
           ▼                    ▼                    ▼
    ┌────────────┐      ┌─────────────┐     ┌──────────────┐
    │   Server   │      │   Server    │     │   Client     │
    │   HTTPD    │      │   Spring    │     │  Certificates│
    │            │      │             │     │              │
    └────────────┘      └─────────────┘     └──────┬───────┘
    CN=localhost        CN=localhost               │
                                                    │
                                    ┌───────────────┼──────────────┐
                                    │               │              │
                                    ▼               ▼              ▼
                            ┌──────────┐   ┌──────────┐   ┌──────────┐
                            │  httpd-  │   │ client1  │   │ client2  │
                            │  proxy   │   │          │   │          │
                            └──────────┘   └──────────┘   └──────────┘
                            Scenario 1     Scenario 2     Future use
```

---

## Data Flow: Request to Response

### Scenario 1 Flow

```
[Browser] ──1──→ [HTTPD:8080] ──2──→ [Spring:8443] ──3──→ [Response]
                       ↓                    ↓
                  No client             Validates
                  cert check         httpd-proxy cert

1. Browser → HTTPD
   - TLS handshake (server cert only)
   - No client certificate required
   - Connection established

2. HTTPD → Spring Boot
   - mTLS handshake
   - HTTPD presents client certificate (CN=httpd-proxy)
   - Spring validates certificate against CA
   - Connection established

3. Spring Boot → Response
   - Process request
   - Return response with authenticatedUser="httpd-proxy"
   - Response flows back through HTTPD to browser
```

### Scenario 2 Flow

```
[Client] ──1──→ [HTTPD:443] ──2──→ [Spring:8443] ──3──→ [Response]
    ↓                ↓                   ↓
Presents        Validates            Validates
client1 cert    client1 cert        client1 cert

1. Client → HTTPD
   - mTLS handshake
   - Client presents certificate (CN=client1)
   - HTTPD validates certificate against CA
   - Connection established

2. HTTPD → Spring Boot
   - mTLS handshake (proxied)
   - Client certificate info forwarded
   - Spring validates certificate against CA
   - Connection established

3. Spring Boot → Response
   - Process request
   - Return response with authenticatedUser="client1"
   - Response flows back through HTTPD to client
```

---

## Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Security Layers                         │
└─────────────────────────────────────────────────────────────┘

Scenario 1 (Proxy Authentication):
┌──────────────┬──────────────┬──────────────┐
│   Browser    │    HTTPD     │    Spring    │
├──────────────┼──────────────┼──────────────┤
│ No Auth      │ Server TLS   │ mTLS         │
│              │ ✅ Layer 1   │ ✅ Layer 2   │
└──────────────┴──────────────┴──────────────┘

Scenario 2 (End-to-End mTLS):
┌──────────────┬──────────────┬──────────────┐
│   Client     │    HTTPD     │    Spring    │
├──────────────┼──────────────┼──────────────┤
│ mTLS         │ mTLS         │ mTLS         │
│ ✅ Layer 1   │ ✅ Layer 2   │ ✅ Layer 3   │
└──────────────┴──────────────┴──────────────┘
       Defense in Depth - Multiple validation points
```

---

## Use These Diagrams

During your presentation:

1. **Start with comparison** - Show side-by-side
2. **Deep dive Scenario 1** - Show flow diagram
3. **Deep dive Scenario 2** - Show flow diagram
4. **Show certificate hierarchy** - Explain trust chain
5. **Discuss security layers** - Explain defense in depth

Keep these visible during demos for reference!
