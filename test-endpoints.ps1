# PowerShell Test Script for Mutual TLS Endpoints

$CERT = ".\certs\client-cert.pem"
$KEY = ".\certs\client-key.pem"
$CA = ".\certs\ca-cert.pem"

# Check if curl is available
if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: curl is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install curl from: https://curl.se/windows/" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Testing Mutual TLS Authentication ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Via Apache HTTPD
Write-Host "[Test 1] Testing via Apache HTTPD (https://localhost:443)" -ForegroundColor Yellow
Write-Host "---"
Write-Host ""

Write-Host "1. GET /api/hello" -ForegroundColor Green
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost/api/hello
Write-Host ""
Write-Host ""

Write-Host "2. GET /api/info" -ForegroundColor Green
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost/api/info
Write-Host ""
Write-Host ""

Write-Host "3. GET /api/status" -ForegroundColor Green
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost/api/status
Write-Host ""
Write-Host ""

# Test 2: Directly to Spring Boot
Write-Host "[Test 2] Testing Spring Boot directly (https://localhost:8443)" -ForegroundColor Yellow
Write-Host "---"
Write-Host ""

Write-Host "1. GET /api/hello" -ForegroundColor Green
curl -s --cert $CERT --key $KEY --cacert $CA https://localhost:8443/api/hello
Write-Host ""
Write-Host ""

# Test 3: Without client certificate (should fail)
Write-Host "[Test 3] Testing without client certificate (should fail)" -ForegroundColor Yellow
Write-Host "---"
Write-Host ""

Write-Host "Attempting connection without client certificate..." -ForegroundColor Green
$result = curl -s --cacert $CA https://localhost/api/hello 2>&1
if ($result -match "SSL" -or $LASTEXITCODE -ne 0) {
    Write-Host "[OK] Correctly rejected - SSL error as expected" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Unexpected response - should have failed" -ForegroundColor Red
}
Write-Host ""
Write-Host ""

# Test 4: Health check (no auth required)
Write-Host "[Test 4] Testing health endpoint (no auth required)" -ForegroundColor Yellow
Write-Host "---"
Write-Host ""

Write-Host "GET /actuator/health" -ForegroundColor Green
curl -s -k https://localhost:8443/actuator/health
Write-Host ""
Write-Host ""

Write-Host "=== Tests Complete ===" -ForegroundColor Cyan
Write-Host ""
