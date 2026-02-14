# CentOS 7 Implementation Guide - 2-Way Authentication

Complete guide for implementing 2-way authentication on CentOS 7 with custom HTTPD 2.4.59.

**Target Environment:**
- OS: CentOS 7
- HTTPD: 2.4.59 (custom built with `rpmbuild -tb`)
- Issue: Missing SSL and proxy modules
- Goal: Implement mutual TLS authentication

---

## 📋 Pre-Implementation Checklist (Run on Monday)

Before starting, gather this information:

```bash
# 1. Check current HTTPD installation
httpd -V
httpd -M
rpm -qi httpd
ls -la /etc/httpd/modules/

# 2. Check system info
cat /etc/redhat-release
uname -a
df -h

# 3. Check if Docker is available
which docker
docker --version

# 4. Check what's using ports
netstat -tlnp | grep -E ":80|:443|:8080|:8443"

# 5. Check existing HTTPD config
cat /etc/httpd/conf/httpd.conf | grep -E "Listen|LoadModule"

# 6. Check available modules
ls -la /etc/httpd/modules/ | wc -l
```

**Save all output** - this helps choose the best approach.

---

## 🎯 Solution Options (Choose Based on Your Situation)

### Quick Decision Tree

```
Can you use Docker?
├─ YES → Option 1 (EASIEST) ⭐ RECOMMENDED
└─ NO → Can teammate rebuild HTTPD?
    ├─ YES → Option 2 (PROPER FIX)
    └─ NO → Can you compile modules?
        ├─ YES → Option 3 (MIDDLE GROUND)
        └─ NO → Option 4 (SPRING BOOT ONLY)
```

---

## ⭐ OPTION 1: Docker Solution (RECOMMENDED)

**Best for:** Any situation where Docker is allowed

**Advantages:**
- ✅ No changes to custom HTTPD
- ✅ Isolated environment
- ✅ Easy rollback
- ✅ Exactly matches tested setup
- ✅ Can coexist with existing HTTPD

**Time Required:** 30-60 minutes

### Step 1: Install Docker (if not already installed)

```bash
# Install Docker on CentOS 7
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional)
sudo usermod -aG docker $USER
# Log out and back in for group to take effect

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

### Step 2: Deploy the Application

```bash
# Clone the repository
cd /opt
sudo git clone https://github.com/jakkapongz/poc-2ways-auth.git
cd poc-2ways-auth

# Checkout develop branch
git checkout develop

# Generate certificates
chmod +x generate-certs.sh generate-httpd-client-cert.sh
./generate-certs.sh
./generate-httpd-client-cert.sh

# Adjust ports if needed (if 443/8080/8443 are taken)
# Edit docker-compose.presentation.yml:
#   - "9443:443"   # Use 9443 instead of 443
#   - "9080:8080"  # Use 9080 instead of 8080
```

### Step 3: Start Services

```bash
# Start in presentation mode (both scenarios)
docker-compose -f docker-compose.presentation.yml up -d

# Check status
docker-compose -f docker-compose.presentation.yml ps

# View logs
docker-compose -f docker-compose.presentation.yml logs -f
```

### Step 4: Test

```bash
# Test Scenario 1 (no client cert)
curl -k https://localhost:8080/api/hello

# Test Scenario 2 (with client cert)
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello
```

### Step 5: Production Setup

```bash
# Create systemd service for auto-start
sudo vi /etc/systemd/system/poc-mtls.service
```

**Content:**
```ini
[Unit]
Description=POC 2-Way Authentication
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/poc-2ways-auth
ExecStart=/usr/local/bin/docker-compose -f docker-compose.presentation.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.presentation.yml down
User=root

[Install]
WantedBy=multi-user.target
```

```bash
# Enable service
sudo systemctl daemon-reload
sudo systemctl enable poc-mtls
sudo systemctl start poc-mtls
```

---

## 🔧 OPTION 2: Rebuild HTTPD RPM (Proper Solution)

**Best for:** When you control the build process

**Advantages:**
- ✅ Proper system package
- ✅ All modules included
- ✅ Native performance
- ✅ Standard management (systemctl)

**Time Required:** 1-2 hours

### Step 1: Set Up Build Environment

```bash
# Install build tools
sudo yum install -y rpm-build rpmdevtools gcc make openssl-devel pcre-devel apr-devel apr-util-devel

# Set up RPM build tree
rpmdev-setuptree
```

### Step 2: Create Proper Spec File

```bash
cd ~/rpmbuild

# Download HTTPD source
wget https://downloads.apache.org/httpd/httpd-2.4.59.tar.bz2 -O SOURCES/httpd-2.4.59.tar.bz2

# Create spec file
vi SPECS/httpd-custom.spec
```

**Spec file content:**
```spec
Name:           httpd-custom
Version:        2.4.59
Release:        1%{?dist}
Summary:        Apache HTTP Server with all modules

License:        Apache
URL:            https://httpd.apache.org/
Source0:        httpd-%{version}.tar.bz2

BuildRequires:  apr-devel >= 1.4.0
BuildRequires:  apr-util-devel >= 1.4.0
BuildRequires:  pcre-devel
BuildRequires:  openssl-devel
BuildRequires:  zlib-devel

%description
Apache HTTP Server 2.4.59 with SSL, proxy, and all essential modules enabled.

%prep
%setup -q -n httpd-%{version}

%build
./configure \
    --prefix=/usr \
    --exec-prefix=/usr \
    --sysconfdir=/etc/httpd/conf \
    --includedir=/usr/include/httpd \
    --libexecdir=/usr/lib64/httpd/modules \
    --datadir=/var/www \
    --enable-so \
    --enable-ssl \
    --enable-proxy \
    --enable-proxy-http \
    --enable-proxy-connect \
    --enable-proxy-balancer \
    --enable-headers \
    --enable-rewrite \
    --enable-deflate \
    --enable-expires \
    --enable-cache \
    --enable-socache-shmcb \
    --with-ssl=/usr \
    --with-pcre \
    --with-included-apr

make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}

# Create necessary directories
mkdir -p %{buildroot}/etc/httpd/conf.d
mkdir -p %{buildroot}/var/log/httpd
mkdir -p %{buildroot}/run/httpd

%files
%defattr(-,root,root,-)
/usr/bin/httpd
/usr/bin/apachectl
/usr/lib64/httpd/modules/*
/etc/httpd/conf/*
/var/www/*
/usr/share/man/man8/httpd*

%changelog
* Mon Feb 17 2025 Your Name <email@example.com> - 2.4.59-1
- Custom build with all modules for 2-way authentication
```

### Step 3: Build the RPM

```bash
# Build
rpmbuild -ba SPECS/httpd-custom.spec

# Find the built RPM
ls -la RPMS/x86_64/
```

### Step 4: Install

```bash
# Stop existing httpd
sudo systemctl stop httpd

# Backup existing
sudo rpm -e httpd  # Or keep both if needed

# Install new RPM
sudo rpm -ivh RPMS/x86_64/httpd-custom-2.4.59-1.el7.x86_64.rpm

# Verify modules
httpd -M | grep -E "ssl|proxy|headers|socache"

# Should see:
# ssl_module (shared)
# proxy_module (shared)
# proxy_http_module (shared)
# headers_module (shared)
# socache_shmcb_module (shared)
```

### Step 5: Configure for 2-Way Auth

```bash
# Copy configuration files from repository
sudo cp /path/to/poc-2ways-auth/httpd/httpd-ssl-mtls.conf /etc/httpd/conf.d/

# Copy certificates
sudo mkdir -p /etc/httpd/certs
sudo cp /path/to/certs/*.pem /etc/httpd/certs/

# Edit config to adjust paths
sudo vi /etc/httpd/conf.d/httpd-ssl-mtls.conf
# Change: /usr/local/apache2/conf/certs → /etc/httpd/certs

# Test configuration
sudo httpd -t

# Start
sudo systemctl start httpd
sudo systemctl enable httpd
```

---

## 🛠️ OPTION 3: Compile Modules Only

**Best for:** When full rebuild is not possible

**Advantages:**
- ✅ Keep existing HTTPD
- ✅ Add only needed modules
- ✅ Faster than full rebuild

**Time Required:** 1 hour

### Step 1: Install Development Tools

```bash
sudo yum install -y gcc make apr-devel apr-util-devel openssl-devel pcre-devel httpd-devel
```

### Step 2: Download and Extract Source

```bash
cd /tmp
wget https://downloads.apache.org/httpd/httpd-2.4.59.tar.bz2
tar xjf httpd-2.4.59.tar.bz2
cd httpd-2.4.59
```

### Step 3: Configure for Module Building

```bash
./configure \
    --with-apr=/usr/bin/apr-1-config \
    --with-apr-util=/usr/bin/apu-1-config \
    --enable-ssl=shared \
    --enable-proxy=shared \
    --enable-proxy-http=shared \
    --enable-headers=shared \
    --enable-socache-shmcb=shared \
    --enable-so
```

### Step 4: Build Modules

```bash
# Build
make

# Find compiled modules
find . -name "mod_ssl.so"
find . -name "mod_proxy.so"
find . -name "mod_proxy_http.so"
find . -name "mod_headers.so"
find . -name "mod_socache_shmcb.so"
```

### Step 5: Install Modules

```bash
# Backup existing modules directory
sudo cp -r /etc/httpd/modules /etc/httpd/modules.backup

# Copy new modules
sudo cp modules/ssl/.libs/mod_ssl.so /etc/httpd/modules/
sudo cp modules/proxy/.libs/mod_proxy.so /etc/httpd/modules/
sudo cp modules/proxy/.libs/mod_proxy_http.so /etc/httpd/modules/
sudo cp modules/proxy/.libs/mod_proxy_connect.so /etc/httpd/modules/
sudo cp modules/mappers/.libs/mod_rewrite.so /etc/httpd/modules/
sudo cp modules/metadata/.libs/mod_headers.so /etc/httpd/modules/
sudo cp modules/cache/.libs/mod_socache_shmcb.so /etc/httpd/modules/

# Set permissions
sudo chmod 755 /etc/httpd/modules/mod_*.so
sudo chown root:root /etc/httpd/modules/mod_*.so
```

### Step 6: Enable Modules in Config

```bash
# Edit main config
sudo vi /etc/httpd/conf/httpd.conf

# Add these LoadModule directives:
```

```apache
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule headers_module modules/mod_headers.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
```

### Step 7: Test and Restart

```bash
# Test configuration
sudo httpd -t

# Check modules loaded
sudo httpd -M | grep -E "ssl|proxy|headers|socache"

# Restart
sudo systemctl restart httpd
```

---

## 🚀 OPTION 4: Spring Boot Only (Simplest)

**Best for:** When all else fails or you want simplest setup

**Advantages:**
- ✅ No HTTPD needed
- ✅ Spring Boot handles everything
- ✅ Simplest deployment

**Disadvantages:**
- ❌ No reverse proxy layer
- ❌ Less flexible

### Step 1: Install Java

```bash
# Install Java 17
sudo yum install -y java-17-openjdk java-17-openjdk-devel

# Verify
java -version
```

### Step 2: Build Application

```bash
cd /opt/poc-2ways-auth

# Build
./gradlew clean build

# Or use pre-built jar if available
```

### Step 3: Generate Certificates

```bash
./generate-certs.sh
```

### Step 4: Run Spring Boot

```bash
# Run directly
java -jar build/libs/poc-2ways-auth-1.0.0-SNAPSHOT.jar

# Or create systemd service
```

**Systemd service:**
```bash
sudo vi /etc/systemd/system/mtls-app.service
```

```ini
[Unit]
Description=Mutual TLS Spring Boot Application
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/opt/poc-2ways-auth
ExecStart=/usr/bin/java -jar build/libs/poc-2ways-auth-1.0.0-SNAPSHOT.jar
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start mtls-app
sudo systemctl enable mtls-app
```

---

## 📊 Comparison Table

| Aspect | Docker | Rebuild RPM | Compile Modules | Spring Only |
|--------|--------|-------------|-----------------|-------------|
| **Difficulty** | ⭐ Easy | ⭐⭐⭐ Hard | ⭐⭐ Medium | ⭐ Easy |
| **Time** | 30-60 min | 1-2 hours | 1 hour | 20 min |
| **Reversibility** | ✅ Perfect | ⚠️ Medium | ⚠️ Medium | ✅ Perfect |
| **Isolation** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **System Changes** | Minimal | Full | Moderate | Minimal |
| **Production Ready** | ✅ Yes | ✅ Yes | ⚠️ Maybe | ✅ Yes |
| **Maintenance** | Easy | Medium | Hard | Easy |
| **Matches POC** | ✅ 100% | ✅ 100% | ✅ 100% | ⚠️ 80% |

---

## 🎯 My Recommendation for Monday

**Follow this order:**

1. **Try Docker first** (Option 1)
   - Takes 30-60 minutes
   - Easy rollback if issues
   - No risk to existing HTTPD

2. **If Docker not allowed:**
   - Ask teammate to rebuild RPM properly (Option 2)
   - Provide them the spec file from this guide

3. **If rebuild not possible:**
   - Compile modules only (Option 3)
   - More work but achievable

4. **Last resort:**
   - Spring Boot only (Option 4)
   - Loses reverse proxy benefits

---

## 📝 Testing Checklist (After Implementation)

Run these tests regardless of which option you choose:

```bash
# 1. Test Scenario 1 (Browser access - no cert)
curl -k https://localhost:8080/api/hello

# Expected: {"authenticatedUser":"httpd-proxy",...}

# 2. Test Scenario 2 (With client cert)
curl --cert certs/client-cert.pem \
     --key certs/client-key.pem \
     --cacert certs/ca-cert.pem \
     https://localhost:443/api/hello

# Expected: {"authenticatedUser":"httpd-proxy",...}

# 3. Test Scenario 2 (Without cert - should fail)
curl -k https://localhost:443/api/hello

# Expected: SSL handshake failure

# 4. Check logs
# Docker:
docker-compose -f docker-compose.presentation.yml logs

# Native:
tail -f /var/log/httpd/error_log
tail -f /var/log/httpd/ssl_error_log
```

---

## 🔒 Security Checklist

Before going live:

- [ ] Replace self-signed CA with real CA
- [ ] Implement certificate rotation
- [ ] Set up monitoring for cert expiration
- [ ] Configure firewall rules
- [ ] Enable SELinux properly
- [ ] Set up log rotation
- [ ] Document certificate distribution process
- [ ] Create rollback plan
- [ ] Test failure scenarios

---

## 📞 Support Information

**If you encounter issues on Monday:**

1. Check logs first:
   ```bash
   # Docker
   docker-compose -f docker-compose.presentation.yml logs -f

   # Native HTTPD
   tail -f /var/log/httpd/error_log

   # Spring Boot
   tail -f /opt/poc-2ways-auth/logs/spring-boot.log
   ```

2. Verify certificates:
   ```bash
   openssl x509 -in certs/ca-cert.pem -noout -text
   openssl x509 -in certs/server-cert.pem -noout -text
   openssl verify -CAfile certs/ca-cert.pem certs/server-cert.pem
   ```

3. Test connectivity:
   ```bash
   # Test HTTPD
   telnet localhost 443

   # Test Spring Boot
   telnet localhost 8443
   ```

---

## 📚 Additional Resources

- **Docker docs:** Created in `DOCKER-TROUBLESHOOTING.md`
- **HTTPD config:** Explained in `HTTPD-CONFIG-EXPLAINED.md`
- **Windows guide:** Available in `WINDOWS-SETUP.md`
- **Architecture:** See `ARCHITECTURE-DIAGRAMS.md`

---

## ✅ Pre-Monday Preparation

**Do these before Monday:**

1. ✅ Read this entire guide
2. ✅ Decide which option to try first
3. ✅ Check if Docker is allowed in your environment
4. ✅ Verify you have sudo access on CentOS 7 server
5. ✅ Confirm Spring Boot can run on server (Java 17)
6. ✅ Check available disk space (need ~2GB)
7. ✅ Prepare rollback plan
8. ✅ Schedule time window (recommend 2-3 hours)

**Good luck on Monday!** 🚀

---

**Document Version:** 1.0
**Last Updated:** February 2025
**Target Environment:** CentOS 7 + Custom HTTPD 2.4.59
