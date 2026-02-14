# Windows Setup Guide

This guide provides detailed instructions for setting up and running the 2-Way Authentication POC on Windows.

## Prerequisites Installation

### 1. Java 17 or Higher

**Download and Install:**
1. Download from [Adoptium](https://adoptium.net/) or [Oracle](https://www.oracle.com/java/technologies/downloads/)
2. Install and note the installation path (e.g., `C:\Program Files\Java\jdk-17`)
3. Set JAVA_HOME environment variable:
   ```cmd
   setx JAVA_HOME "C:\Program Files\Java\jdk-17"
   setx PATH "%PATH%;%JAVA_HOME%\bin"
   ```

**Verify Installation:**
```cmd
java -version
javac -version
```

### 2. OpenSSL

**Option A: Install OpenSSL for Windows**
1. Download from [slproweb.com](https://slproweb.com/products/Win32OpenSSL.html)
2. Download "Win64 OpenSSL v3.x.x" (full version, not Light)
3. Install to default location (e.g., `C:\Program Files\OpenSSL-Win64`)
4. Add to PATH:
   ```cmd
   setx PATH "%PATH%;C:\Program Files\OpenSSL-Win64\bin"
   ```

**Option B: Use Git Bash (Recommended for Developers)**
1. Download [Git for Windows](https://git-scm.com/download/win)
2. During installation, select "Use Git and optional Unix tools from the Command Prompt"
3. Git Bash includes OpenSSL and other Unix tools

**Verify Installation:**
```cmd
openssl version
```

### 3. Docker Desktop

**Download and Install:**
1. Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Install Docker Desktop
3. Enable WSL 2 backend (recommended)
4. Start Docker Desktop

**Verify Installation:**
```cmd
docker --version
docker-compose --version
```

### 4. curl (Optional)

**Windows 10/11:**
- curl is included by default in Windows 10 (version 1803+) and Windows 11

**Older Windows versions:**
1. Download from [curl.se](https://curl.se/windows/)
2. Extract to a folder (e.g., `C:\curl`)
3. Add to PATH:
   ```cmd
   setx PATH "%PATH%;C:\curl\bin"
   ```

**Verify Installation:**
```cmd
curl --version
```

## Quick Start on Windows

### Step 1: Clone or Extract the Project

```cmd
cd C:\Users\YourUsername\Projects
git clone <repository-url>
cd poc-2ways-auth
```

Or extract the ZIP file to your desired location.

### Step 2: Generate Certificates

Open Command Prompt or PowerShell in the project directory:

```cmd
generate-certs.bat
```

This will:
- Generate CA, server, and client certificates
- Create keystores for Spring Boot
- Copy certificates for Apache HTTPD

**Expected Output:**
```
=== Generating Certificates for Mutual TLS Authentication ===
1. Generating CA private key and certificate...
2. Generating server private key...
...
=== Certificate Generation Complete ===
```

### Step 3: Start Services with Docker

```cmd
docker-compose up --build
```

**Wait for services to start:**
- Spring Boot app: `https://localhost:8443`
- Apache HTTPD proxy: `https://localhost:443`

You should see:
```
spring-app-mtls  | Started MutualTlsApplication in X seconds
httpd-proxy-mtls | AH00094: Command line: 'httpd -D FOREGROUND'
```

### Step 4: Test the Endpoints

**Option 1: Use the Test Script**
```cmd
test-endpoints.bat
```

**Option 2: Manual Testing**
```cmd
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost/api/hello
```

**Expected Response:**
```json
{
  "message": "Hello from secure endpoint!",
  "authenticatedUser": "client1",
  "timestamp": "1234567890"
}
```

## Running Locally (Without Docker)

### Build with Gradle

**Using Gradle Wrapper (Recommended):**
```cmd
gradlew.bat clean build
```

**Using Installed Gradle:**
```cmd
gradle clean build
```

### Run Spring Boot

**Option 1: Using Gradle:**
```cmd
gradlew.bat bootRun
```

**Option 2: Run the JAR:**
```cmd
java -jar build\libs\poc-2ways-auth-1.0.0-SNAPSHOT.jar
```

### Test Locally

```cmd
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost:8443/api/hello
```

## Common Issues and Solutions

### Issue 1: OpenSSL Not Found

**Error:**
```
'openssl' is not recognized as an internal or external command
```

**Solution:**
1. Install OpenSSL (see prerequisites)
2. Add OpenSSL to PATH
3. Restart Command Prompt/PowerShell
4. Verify: `openssl version`

**Alternative:**
Use Git Bash instead of Command Prompt:
```bash
cd /c/path/to/project
chmod +x generate-certs.sh
./generate-certs.sh
```

### Issue 2: keytool Not Found

**Error:**
```
'keytool' is not recognized as an internal or external command
```

**Solution:**
1. Verify Java is installed: `java -version`
2. Set JAVA_HOME:
   ```cmd
   setx JAVA_HOME "C:\Program Files\Java\jdk-17"
   ```
3. Add to PATH:
   ```cmd
   setx PATH "%PATH%;%JAVA_HOME%\bin"
   ```
4. Restart Command Prompt
5. Verify: `keytool -help`

### Issue 3: Docker Not Running

**Error:**
```
error during connect: Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.24/containers/json"
```

**Solution:**
1. Start Docker Desktop
2. Wait for Docker to fully start (check system tray icon)
3. Verify: `docker ps`

### Issue 4: Port Already in Use

**Error:**
```
Bind for 0.0.0.0:443 failed: port is already allocated
```

**Solution:**
1. Find what's using the port:
   ```cmd
   netstat -ano | findstr :443
   ```
2. Kill the process:
   ```cmd
   taskkill /PID <process_id> /F
   ```
3. Or change the port in `docker-compose.yml`:
   ```yaml
   ports:
     - "8443:443"  # Use port 8443 instead of 443
   ```

### Issue 5: Permission Denied on gradlew.bat

**Error:**
```
Access is denied
```

**Solution:**
Run as Administrator or check file permissions:
```cmd
icacls gradlew.bat /grant Everyone:F
```

### Issue 6: Line Ending Issues (Git)

**Error:**
```
./gradlew: line 2: $'\r': command not found
```

**Solution:**
This happens when Git converts line endings. Fix by:
```cmd
git config --global core.autocrlf false
```
Then re-clone the repository.

## PowerShell-Specific Commands

If you prefer PowerShell, use these commands:

### Generate Certificates
```powershell
.\generate-certs.bat
```

### Build with Gradle
```powershell
.\gradlew.bat clean build
```

### Run Spring Boot
```powershell
.\gradlew.bat bootRun
```

### Test Endpoints
```powershell
.\test-endpoints.bat
```

### Clean Up
```powershell
Remove-Item -Recurse -Force certs
Remove-Item -Recurse -Force build
Remove-Item src\main\resources\*.p12
docker-compose down -v
```

## IDE Setup (Windows)

### IntelliJ IDEA

1. **Open Project:**
   - File → Open → Select `poc-2ways-auth` folder
   - IntelliJ will auto-detect Gradle

2. **Gradle Sync:**
   - Right-click on `build.gradle` → Reload Gradle Project

3. **Run Configuration:**
   - Create Run Configuration for `MutualTlsApplication`
   - Set VM options if needed: `-Djavax.net.ssl.keyStore=...`

4. **Trust Certificates:**
   - Import `certs/ca-cert.pem` into IntelliJ's trusted certificates
   - Settings → Tools → Server Certificates → Accept automatically

### Eclipse

1. **Import Project:**
   - File → Import → Gradle → Existing Gradle Project
   - Select `poc-2ways-auth` folder

2. **Build Project:**
   - Right-click project → Gradle → Refresh Gradle Project

3. **Run:**
   - Right-click `MutualTlsApplication.java` → Run As → Java Application

### VS Code

1. **Install Extensions:**
   - Extension Pack for Java
   - Spring Boot Extension Pack
   - Gradle for Java

2. **Open Folder:**
   - File → Open Folder → Select `poc-2ways-auth`

3. **Run:**
   - Press F5 or use Spring Boot Dashboard

## Testing with Windows Tools

### Postman

1. **Import Client Certificate:**
   - Settings → Certificates → Client Certificates
   - Add Certificate
   - Host: `localhost:443`
   - CRT file: `certs/client-cert.pem`
   - KEY file: `certs/client-key.pem`

2. **Disable SSL Verification:**
   - Settings → General → SSL certificate verification → OFF

3. **Test:**
   - GET `https://localhost/api/hello`

### Browser Testing

**Chrome/Edge:**
1. Settings → Privacy and security → Security → Manage certificates
2. Personal → Import → Select `certs/client.p12`
3. Password: `changeit`
4. Navigate to `https://localhost/api/hello`
5. Select the client certificate when prompted

**Firefox:**
1. Settings → Privacy & Security → Certificates → View Certificates
2. Your Certificates → Import
3. Select `certs/client.p12`, password: `changeit`
4. Navigate to `https://localhost/api/hello`

## Additional Resources

- [Gradle User Manual](https://docs.gradle.org/current/userguide/userguide.html)
- [Spring Boot Reference](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Docker Desktop on Windows](https://docs.docker.com/desktop/windows/)
- [OpenSSL for Windows](https://wiki.openssl.org/index.php/Binaries)
