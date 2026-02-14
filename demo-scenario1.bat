@echo off
REM Demo Script for SCENARIO 1: Browser Access (HTTPD Proxy Authentication)

echo ==========================================
echo SCENARIO 1: Browser Access Demo
echo HTTPD Proxy Authentication
echo ==========================================
echo.
echo In this scenario:
echo   - Browser connects to HTTPD (no client cert needed)
echo   - HTTPD authenticates to Spring Boot using its own certificate
echo   - Users don't need to manage certificates
echo.
echo Port: 8080 (HTTPD with proxy authentication)
echo.

REM Test 1: Hello endpoint
echo ==========================================
echo Test 1: GET /api/hello
echo ==========================================
echo.
echo Command: curl -k https://localhost:8080/api/hello
echo.
echo Response:
curl -k https://localhost:8080/api/hello 2>nul
echo.
echo [OK] Notice: authenticatedUser is 'httpd-proxy'
echo [OK] No client certificate was provided
echo [OK] HTTPD authenticated to backend on your behalf
echo.
pause

REM Test 2: Info endpoint
echo.
echo ==========================================
echo Test 2: GET /api/info
echo ==========================================
echo.
echo Command: curl -k https://localhost:8080/api/info
echo.
echo Response:
curl -k https://localhost:8080/api/info 2>nul
echo.
echo [OK] clientCN shows 'httpd-proxy'
echo [OK] This is the identity HTTPD used to authenticate
echo.
pause

REM Test 3: Status endpoint
echo.
echo ==========================================
echo Test 3: GET /api/status
echo ==========================================
echo.
echo Command: curl -k https://localhost:8080/api/status
echo.
echo Response:
curl -k https://localhost:8080/api/status 2>nul
echo.
pause

REM Show certificate
echo.
echo ==========================================
echo HTTPD Client Certificate Details
echo ==========================================
echo.
echo This is the certificate HTTPD uses to authenticate to Spring Boot:
echo.
openssl x509 -in certs\httpd-client-cert.pem -noout -subject -issuer -dates
echo.
echo [OK] Common Name (CN): httpd-proxy
echo [OK] Issued by: Example Root CA
echo [OK] Valid for: ~10 years
echo.

echo ==========================================
echo Browser Test Instructions
echo ==========================================
echo.
echo Try this in your browser:
echo   1. Open: https://localhost:8080/api/hello
echo   2. Accept the security warning (self-signed cert)
echo   3. See the JSON response
echo.
echo Notice: You were NOT asked for a client certificate!
echo.
echo ==========================================
echo Summary - Scenario 1
echo ==========================================
echo.
echo [OK] Browser users don't need certificates
echo [OK] HTTPD acts as trusted proxy
echo [OK] Backend is still secured with mutual TLS
echo [OK] Good for web applications and APIs with proxy
echo.
pause
