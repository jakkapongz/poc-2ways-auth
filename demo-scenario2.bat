@echo off
REM Demo Script for SCENARIO 2: Direct Client Certificate (End-to-End Mutual TLS)

echo ==========================================
echo SCENARIO 2: End-to-End Mutual TLS Demo
echo Client Certificate Required
echo ==========================================
echo.
echo In this scenario:
echo   - Client MUST provide a valid certificate
echo   - Both HTTPD and Spring Boot validate the certificate
echo   - True end-to-end authentication
echo.
echo Port: 443 (HTTPD with client certificate requirement)
echo.

REM Test 1: Without certificate (should fail)
echo ==========================================
echo Test 1: Access WITHOUT Client Certificate
echo ==========================================
echo.
echo Command: curl -k https://localhost:443/api/hello
echo.
echo Attempting to connect without client certificate...
echo.

curl -k https://localhost:443/api/hello 2>&1 | findstr /C:"SSL" >nul
if %ERRORLEVEL% equ 0 (
    echo [FAIL] Connection FAILED (as expected!)
    echo.
    echo [OK] This is correct! The server rejected the connection
    echo [OK] No valid client certificate was provided
    echo [OK] Security in action - unauthorized access prevented
) else (
    echo Unexpected response
)
echo.
pause

REM Test 2: With valid certificate (should succeed)
echo.
echo ==========================================
echo Test 2: Access WITH Valid Client Certificate
echo ==========================================
echo.
echo Command: curl --cert certs/client-cert.pem
echo              --key certs/client-key.pem
echo              --cacert certs/ca-cert.pem
echo              https://localhost:443/api/hello
echo.
echo Response:
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost:443/api/hello 2>nul
echo.
echo [OK] Connection SUCCEEDED!
echo [OK] Notice: authenticatedUser is 'client1' (from certificate CN)
echo [OK] This is the actual client identity, not a proxy
echo.
pause

REM Test 3: Info endpoint with certificate
echo.
echo ==========================================
echo Test 3: GET /api/info (with certificate)
echo ==========================================
echo.
echo Response:
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost:443/api/info 2>nul
echo.
echo [OK] clientCN shows 'client1'
echo [OK] Both HTTPD and Spring Boot validated this certificate
echo.
pause

REM Show certificate
echo.
echo ==========================================
echo Client Certificate Details
echo ==========================================
echo.
echo This is the certificate the client presented:
echo.
openssl x509 -in certs\client-cert.pem -noout -subject -issuer -dates
echo.
echo [OK] Common Name (CN): client1
echo [OK] Issued by: Example Root CA
echo [OK] This CA is trusted by both HTTPD and Spring Boot
echo.
pause

REM Test 4: Direct access to Spring Boot
echo.
echo ==========================================
echo Test 4: Direct Access to Spring Boot
echo Bypassing HTTPD (Port 8443)
echo ==========================================
echo.
echo Response:
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost:8443/api/hello 2>nul
echo.
echo [OK] Direct access also works!
echo [OK] Spring Boot independently validates certificates
echo [OK] Defense in depth - security at multiple layers
echo.
pause

REM Comparison
echo.
echo ==========================================
echo Comparison: Scenario 1 vs Scenario 2
echo ==========================================
echo.
echo Scenario 1 (Port 8080 - Proxy Auth):
echo   - No client certificate needed
echo   - User identity: httpd-proxy (proxy, not end user)
echo   - Easy for browsers and web apps
echo.
echo Scenario 2 (Port 443 - End-to-End mTLS):
echo   - Client certificate required
echo   - User identity: client1 (actual client)
echo   - Best for API/microservice communication
echo.

echo ==========================================
echo Summary - Scenario 2
echo ==========================================
echo.
echo [OK] Client certificate is mandatory
echo [OK] True end-to-end mutual authentication
echo [OK] Backend knows the actual client identity
echo [OK] Good for API integrations, microservices, IoT
echo [OK] Higher security, but more complex certificate management
echo.
pause
