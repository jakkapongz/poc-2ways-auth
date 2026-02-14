# Docker Troubleshooting Guide

This guide helps resolve common Docker issues when building and running the 2-way authentication POC.

## Common Issues

### 1. ARM64/Apple Silicon Compatibility

**Error:**
```
ERROR [internal] load metadata for docker.io/library/eclipse-temurin:17-jre-alpine
no matching manifest for linux/arm64/v8 in the manifest list entries
```

**Cause:** You're on Apple Silicon (M1/M2/M3 Mac), and some Alpine images don't support ARM64.

**Solution:** Use non-alpine images (already fixed in Dockerfile):
```dockerfile
# Instead of:
FROM eclipse-temurin:17-jre-alpine

# Use:
FROM eclipse-temurin:17-jre
```

**Why this works:** The standard (non-alpine) images are multi-architecture and support both AMD64 and ARM64.

**Trade-off:** Larger image size (~150MB vs ~50MB for Alpine), but better compatibility.

---

### 2. Docker Build Performance on ARM64

**Issue:** Builds are slower on Apple Silicon when images need emulation.

**Solution:** Ensure you're using native ARM64 images:
```bash
# Check image architecture
docker image inspect eclipse-temurin:17-jre | grep Architecture

# Should show: "Architecture": "arm64"
```

**Images confirmed to work on ARM64:**
- ✅ `gradle:8.5-jdk17` (multi-arch)
- ✅ `eclipse-temurin:17-jre` (multi-arch)
- ✅ `httpd:2.4-alpine` (multi-arch)

---

### 3. Build Context Too Large

**Error:**
```
Sending build context to Docker daemon  XXX GB
```

**Solution:** Create/update `.dockerignore`:
```bash
# Add to .dockerignore
.git/
.gradle/
build/
target/
certs/
*.md
node_modules/
```

**Test:**
```bash
# Check build context size
docker build --no-cache -t test . 2>&1 | grep "build context"
```

---

### 4. Gradle Wrapper Not Found

**Error:**
```
COPY failed: file not found in build context
```

**Solution:** Ensure Gradle wrapper files exist:
```bash
# Check for wrapper files
ls -la gradle/wrapper/

# If missing, regenerate
gradle wrapper
```

---

### 5. Port Already in Use

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:443: bind: address already in use
```

**Solution 1:** Stop conflicting services
```bash
# Find process using port
sudo lsof -i :443
sudo lsof -i :8080
sudo lsof -i :8443

# Kill process
sudo kill -9 <PID>
```

**Solution 2:** Change ports in docker-compose
```yaml
services:
  httpd-proxy:
    ports:
      - "8443:443"    # Use 8443 instead of 443
      - "8081:8080"   # Use 8081 instead of 8080
```

---

### 6. Certificate Files Not Found

**Error:**
```
Error response from daemon: error while creating mount source path
'/Users/xxx/certs': mkdir /Users/xxx/certs: no such file or directory
```

**Solution:** Generate certificates first:
```bash
# Linux/Mac
./generate-certs.sh

# Windows
generate-certs.bat

# For presentation mode, also generate HTTPD client cert
./generate-httpd-client-cert.sh
generate-httpd-client-cert.bat
```

---

### 7. Docker Daemon Not Running

**Error:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
1. Start Docker Desktop
2. Wait for it to fully initialize (green icon in system tray)
3. Verify: `docker ps`

---

### 8. Permission Denied (Linux)

**Error:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or:
newgrp docker

# Verify
docker ps
```

---

### 9. Out of Disk Space

**Error:**
```
no space left on device
```

**Solution:**
```bash
# Clean up unused Docker resources
docker system prune -a

# Remove specific items
docker image prune -a
docker container prune
docker volume prune
docker network prune

# Check disk usage
docker system df
```

---

### 10. SSL/TLS Handshake Failures

**Error:**
```
curl: (35) error:14094410:SSL routines:ssl3_read_bytes:sslv3 alert handshake failure
```

**Possible Causes:**

#### A. Certificates Not Generated
```bash
# Check certificates exist
ls -la certs/

# Should see:
# ca-cert.pem, ca-key.pem
# server-cert.pem, server-key.pem
# client-cert.pem, client-key.pem
# httpd-client-cert.pem (for presentation mode)
```

#### B. Wrong Scenario Port
```bash
# Scenario 1 (no cert) - port 8080
curl -k https://localhost:8080/api/hello

# Scenario 2 (with cert) - port 443
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

#### C. Containers Not Fully Started
```bash
# Wait for services to be ready
docker-compose -f docker-compose.presentation.yml logs -f

# Look for:
# spring-app    | Started MutualTlsApplication
# httpd-proxy   | AH00094: Command line: 'httpd -D FOREGROUND'
```

---

## Platform-Specific Issues

### macOS (Apple Silicon)

**Issue:** Rosetta 2 emulation causing slow builds

**Solution:**
```bash
# Use native ARM64 images (already configured)
# Verify with:
docker buildx ls
```

**Issue:** VirtioFS performance

**Solution:**
Enable VirtioFS in Docker Desktop:
- Settings → General → Enable VirtioFS

---

### Windows

**Issue:** Line ending conversion breaking scripts

**Solution:**
```bash
# Git configuration
git config --global core.autocrlf false

# Re-clone repository or fix files:
dos2unix generate-certs.sh
dos2unix demo-scenario1.sh
```

**Issue:** OpenSSL not found in Docker

**Solution:** Use Git Bash or install OpenSSL for Windows

---

### Linux

**Issue:** SELinux blocking volume mounts

**Solution:**
```bash
# Temporarily disable SELinux (testing only)
sudo setenforce 0

# Or add :z flag to volumes in docker-compose.yml
volumes:
  - ./certs:/usr/local/apache2/conf/certs:ro,z
```

---

## Build Optimization

### Faster Builds

1. **Use BuildKit:**
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or in docker-compose.yml
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1
```

2. **Multi-stage caching:**
```bash
# Build with cache
docker-compose build

# Rebuild specific service
docker-compose build spring-app
```

3. **Gradle daemon:**
Already optimized with `--no-daemon` to avoid memory issues in containers.

---

## Debugging Commands

### Check Service Status
```bash
# All services
docker-compose -f docker-compose.presentation.yml ps

# Specific service logs
docker-compose -f docker-compose.presentation.yml logs spring-app
docker-compose -f docker-compose.presentation.yml logs httpd-proxy

# Follow logs
docker-compose -f docker-compose.presentation.yml logs -f
```

### Inspect Containers
```bash
# List running containers
docker ps

# Inspect container
docker inspect spring-app-mtls

# Execute command in container
docker exec -it spring-app-mtls sh

# Check container logs
docker logs spring-app-mtls
```

### Network Debugging
```bash
# List networks
docker network ls

# Inspect network
docker network inspect poc-2ways-auth_mtls-network

# Test connectivity between containers
docker exec spring-app-mtls ping httpd-proxy
```

### Volume Debugging
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume-name>

# Check certificate files in container
docker exec httpd-proxy-presentation ls -la /usr/local/apache2/conf/certs/
```

---

## Clean Restart

If all else fails, clean restart:

```bash
# Stop everything
docker-compose -f docker-compose.presentation.yml down -v

# Remove all project containers and images
docker-compose -f docker-compose.presentation.yml down --rmi all -v

# Clean Docker system
docker system prune -a

# Regenerate certificates
rm -rf certs/
./generate-certs.sh
./generate-httpd-client-cert.sh

# Rebuild and start
docker-compose -f docker-compose.presentation.yml up --build
```

---

## Performance Tuning

### Docker Desktop Settings (macOS/Windows)

**Memory:**
- Recommended: 4GB minimum, 8GB optimal
- Settings → Resources → Memory

**CPU:**
- Recommended: 4 cores minimum
- Settings → Resources → CPUs

**Disk:**
- Recommended: 10GB free space minimum
- Settings → Resources → Disk image size

---

## Health Checks

### Verify Everything Works

```bash
# 1. Check Docker
docker --version
docker-compose --version

# 2. Check services
docker-compose -f docker-compose.presentation.yml ps

# 3. Test Scenario 1
curl -k https://localhost:8080/api/hello

# 4. Test Scenario 2
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello

# 5. Check logs for errors
docker-compose -f docker-compose.presentation.yml logs | grep -i error
```

---

## Getting Help

If you're still stuck:

1. Check service logs: `docker-compose logs -f`
2. Verify certificates: `ls -la certs/`
3. Test connectivity: `docker exec spring-app-mtls wget --spider https://localhost:8443/actuator/health`
4. Review documentation: `README.md`, `WINDOWS-SETUP.md`

---

## Known Working Configurations

### Apple Silicon (M1/M2/M3)
- ✅ macOS Sonoma 14.x
- ✅ Docker Desktop 4.25+
- ✅ Non-alpine images

### Intel Mac
- ✅ macOS Catalina 10.15+
- ✅ Docker Desktop 4.x+
- ✅ Both alpine and standard images

### Windows
- ✅ Windows 10/11
- ✅ Docker Desktop with WSL2
- ✅ Git Bash for scripts

### Linux
- ✅ Ubuntu 20.04+
- ✅ Docker Engine 20.10+
- ✅ docker-compose 1.29+

---

## Summary

Most issues are resolved by:
1. ✅ Using non-alpine base images (ARM64 compatibility)
2. ✅ Generating certificates before starting containers
3. ✅ Ensuring Docker has sufficient resources
4. ✅ Checking port availability

The Dockerfile has been updated to work on all platforms including Apple Silicon.
