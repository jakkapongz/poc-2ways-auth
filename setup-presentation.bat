@echo off
REM Complete setup script for presentation demo

setlocal EnableDelayedExpansion

echo ==========================================
echo Setting Up 2-Way Authentication Demo
echo ==========================================
echo.

REM Step 1: Generate base certificates
echo Step 1: Generating base certificates...
echo ----------------------------------------
if not exist "certs\ca-cert.pem" (
    call generate-certs.bat
    echo [OK] Base certificates generated
) else (
    echo [OK] Base certificates already exist
)
echo.

REM Step 2: Generate HTTPD client certificate
echo Step 2: Generating HTTPD client certificate...
echo ----------------------------------------
if not exist "certs\httpd-client-bundle.pem" (
    call generate-httpd-client-cert.bat
    echo [OK] HTTPD client certificate generated
) else (
    echo [OK] HTTPD client certificate already exists
)
echo.

REM Step 3: Build and start services
echo Step 3: Building and starting services...
echo ----------------------------------------
echo This may take a few minutes on first run...
docker-compose -f docker-compose.presentation.yml up --build -d

echo.
echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

REM Step 4: Check service health
echo.
echo Step 4: Verifying services...
echo ----------------------------------------

docker ps | findstr spring-app-mtls >nul
if %ERRORLEVEL% equ 0 (
    echo [OK] Spring Boot is running on port 8443
) else (
    echo [FAIL] Spring Boot is not running
    exit /b 1
)

docker ps | findstr httpd-proxy-presentation >nul
if %ERRORLEVEL% equ 0 (
    echo [OK] Apache HTTPD is running on ports 443 and 8080
) else (
    echo [FAIL] Apache HTTPD is not running
    exit /b 1
)

echo.
echo Testing connectivity...

REM Test Scenario 1 (port 8080)
curl -k -s https://localhost:8080/api/status >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Scenario 1 (Port 8080) is accessible
) else (
    echo [FAIL] Scenario 1 (Port 8080) failed
)

REM Test Scenario 2 (port 443 with cert)
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem -s https://localhost:443/api/status >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Scenario 2 (Port 443) is accessible
) else (
    echo [FAIL] Scenario 2 (Port 443) failed
)

echo.
echo ==========================================
echo Setup Complete!
echo ==========================================
echo.
echo Your presentation environment is ready!
echo.
echo Available Demonstrations:
echo.
echo SCENARIO 1: Browser Access (No Client Cert)
echo   Port: 8080
echo   Browser: https://localhost:8080/api/hello
echo   Script:  demo-scenario1.bat
echo.
echo SCENARIO 2: End-to-End Mutual TLS (Client Cert Required)
echo   Port: 443
echo   Script:  demo-scenario2.bat
echo.
echo Documentation:
echo   Full guide: PRESENTATION-DEMO.md
echo.
echo Quick Test:
echo   Scenario 1: curl -k https://localhost:8080/api/hello
echo.
echo View logs:
echo   docker-compose -f docker-compose.presentation.yml logs -f
echo.
echo Stop demo:
echo   docker-compose -f docker-compose.presentation.yml down
echo.
pause
