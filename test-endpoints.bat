@echo off
REM Test script for mutual TLS endpoints on Windows

setlocal EnableDelayedExpansion

set CERT=.\certs\client-cert.pem
set KEY=.\certs\client-key.pem
set CA=.\certs\ca-cert.pem

REM Check if curl is available
where curl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: curl is not installed or not in PATH
    echo Please install curl from: https://curl.se/windows/
    pause
    exit /b 1
)

echo === Testing Mutual TLS Authentication ===
echo.

REM Test 1: Via Apache HTTPD
echo [Test 1] Testing via Apache HTTPD (https://localhost:443)
echo ---
echo.

echo 1. GET /api/hello
curl -s --cert %CERT% --key %KEY% --cacert %CA% https://localhost/api/hello
echo.
echo.

echo 2. GET /api/info
curl -s --cert %CERT% --key %KEY% --cacert %CA% https://localhost/api/info
echo.
echo.

echo 3. GET /api/status
curl -s --cert %CERT% --key %KEY% --cacert %CA% https://localhost/api/status
echo.
echo.

REM Test 2: Directly to Spring Boot
echo [Test 2] Testing Spring Boot directly (https://localhost:8443)
echo ---
echo.

echo 1. GET /api/hello
curl -s --cert %CERT% --key %KEY% --cacert %CA% https://localhost:8443/api/hello
echo.
echo.

REM Test 3: Without client certificate (should fail)
echo [Test 3] Testing without client certificate (should fail)
echo ---
echo.

echo Attempting connection without client certificate...
curl -s --cacert %CA% https://localhost/api/hello 2>&1 | findstr /C:"SSL" >nul
if %ERRORLEVEL% equ 0 (
    echo [OK] Correctly rejected - SSL error as expected
) else (
    echo [FAIL] Unexpected response - should have failed
)
echo.
echo.

REM Test 4: Health check (no auth required)
echo [Test 4] Testing health endpoint (no auth required)
echo ---
echo.

echo GET /actuator/health
curl -s -k https://localhost:8443/actuator/health
echo.
echo.

echo === Tests Complete ===
echo.
pause
