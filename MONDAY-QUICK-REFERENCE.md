# Monday Quick Reference Card

**Quick commands for implementation day.**

---

## 🎯 Recommended Approach: Docker (Fastest & Safest)

### Pre-Check (5 minutes)
```bash
# Check if Docker available
which docker && docker --version

# Check ports available
netstat -tlnp | grep -E ":443|:8080|:8443"

# Check disk space
df -h | grep -E "/$|/opt"
```

### Install Docker (if needed - 10 minutes)
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```

### Deploy Application (15 minutes)
```bash
cd /opt
sudo git clone https://github.com/jakkapongz/poc-2ways-auth.git
cd poc-2ways-auth
git checkout develop

# Generate certificates
chmod +x *.sh
./generate-certs.sh
./generate-httpd-client-cert.sh

# Start services
docker-compose -f docker-compose.presentation.yml up -d

# Check status
docker-compose -f docker-compose.presentation.yml ps
```

### Test (5 minutes)
```bash
# Scenario 1 (no cert)
curl -k https://localhost:8080/api/hello

# Scenario 2 (with cert)
curl --cert certs/client-cert.pem --key certs/client-key.pem --cacert certs/ca-cert.pem https://localhost:443/api/hello
```

**Total Time: ~35 minutes**

---

## 🏭 Production HTTPD Config (HTTP In, HTTPS Out)

### Quick Config for Relay Architecture

```bash
# Create config file
sudo vi /etc/httpd/conf.d/mtls-proxy.conf
```

```apache
# HTTP from Relay, HTTPS to Spring Boot
Listen 14088

<VirtualHost *:14088>
    ServerName localhost

    # NO SSLEngine - Relay handles SSL

    ErrorLog /var/log/httpd/mtls_error_log
    CustomLog /var/log/httpd/mtls_access_log combined

    ProxyPreserveHost On
    ProxyTimeout 300

    # SSL for backend only
    SSLProxyEngine On
    SSLProxyMachineCertificateFile /etc/httpd/certs/httpd-client-bundle.pem
    SSLProxyCACertificateFile /etc/httpd/certs/ca-cert.pem
    SSLProxyVerify require
    SSLProxyCheckPeerCN on
    SSLProxyCheckPeerName off

    RequestHeader set X-Proxy-Client "httpd-proxy"
    RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}e"

    # Adjust context path as needed
    ProxyPass /my-api https://localhost:8443/my-api
    ProxyPassReverse /my-api https://localhost:8443/my-api

    <Location /my-api>
        Require all granted
    </Location>
</VirtualHost>
```

### Required Modules
```bash
# Add to /etc/httpd/conf/httpd.conf:
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule headers_module modules/mod_headers.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
```

### Test
```bash
# Test config
sudo httpd -t

# Test from Relay (HTTP)
curl http://localhost:14088/my-api/hello

# Check modules
sudo httpd -M | grep -E "proxy|ssl|headers"
```

---

## 🔧 Alternative: Compile Modules

### Install Tools (5 minutes)
```bash
sudo yum install -y gcc make apr-devel apr-util-devel openssl-devel httpd-devel
```

### Download & Build (30 minutes)
```bash
cd /tmp
wget https://downloads.apache.org/httpd/httpd-2.4.59.tar.bz2
tar xjf httpd-2.4.59.tar.bz2
cd httpd-2.4.59

./configure \
    --enable-ssl=shared \
    --enable-proxy=shared \
    --enable-proxy-http=shared \
    --enable-headers=shared \
    --enable-socache-shmcb=shared

make
```

### Install Modules (5 minutes)
```bash
sudo cp modules/ssl/.libs/mod_ssl.so /etc/httpd/modules/
sudo cp modules/proxy/.libs/mod_proxy*.so /etc/httpd/modules/
sudo cp modules/metadata/.libs/mod_headers.so /etc/httpd/modules/
sudo cp modules/cache/.libs/mod_socache_shmcb.so /etc/httpd/modules/
sudo chmod 755 /etc/httpd/modules/mod_*.so
```

### Configure (10 minutes)
```bash
# Add to /etc/httpd/conf/httpd.conf:
sudo tee -a /etc/httpd/conf/httpd.conf << EOF
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule headers_module modules/mod_headers.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
EOF

# Test
sudo httpd -t
sudo httpd -M | grep -E "ssl|proxy|headers"
```

**Total Time: ~50 minutes**

---

## 🚨 Troubleshooting Quick Fixes

### Docker Issues
```bash
# Container won't start
docker-compose -f docker-compose.presentation.yml logs

# Port conflict
# Edit docker-compose.presentation.yml, change ports:
#   - "9443:443"
#   - "9080:8080"

# Permission denied
sudo chown -R $USER:$USER .
```

### Module Issues
```bash
# Module not loading
sudo httpd -M | grep ssl

# Check file exists
ls -la /etc/httpd/modules/mod_ssl.so

# Check permissions
sudo chmod 755 /etc/httpd/modules/mod_*.so

# SELinux blocking
sudo setenforce 0  # Temporary test
# If this fixes it, add proper SELinux context later
```

### Certificate Issues
```bash
# Regenerate all
rm -rf certs/
./generate-certs.sh
./generate-httpd-client-cert.sh

# Verify
openssl x509 -in certs/ca-cert.pem -noout -text
openssl verify -CAfile certs/ca-cert.pem certs/client-cert.pem
```

### Connection Issues
```bash
# Test local connectivity
curl -k https://localhost:8443/actuator/health

# Check firewall
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

# Check SELinux
getenforce
sudo ausearch -m avc -ts recent
```

---

## 📋 Success Criteria Checklist

- [ ] Services start without errors
- [ ] Scenario 1 works (no client cert): `curl -k https://localhost:8080/api/hello`
- [ ] Scenario 2 fails without cert: `curl -k https://localhost:443/api/hello`
- [ ] Scenario 2 works with cert: `curl --cert ... https://localhost:443/api/hello`
- [ ] Logs show no errors
- [ ] System stable after 10 minutes

---

## 🔄 Rollback Plan

### If Docker:
```bash
docker-compose -f docker-compose.presentation.yml down
docker system prune -a
```

### If Compiled Modules:
```bash
# Restore backup
sudo rm /etc/httpd/modules/mod_*.so
sudo cp /etc/httpd/modules.backup/* /etc/httpd/modules/

# Restore config
sudo vi /etc/httpd/conf/httpd.conf
# Remove LoadModule lines

# Restart
sudo systemctl restart httpd
```

---

## 📞 Emergency Contacts

**If stuck, check:**
1. `/var/log/httpd/error_log`
2. `docker-compose logs`
3. `journalctl -u httpd -f`

**Common errors:**
- "Port already in use" → Change ports or stop conflicting service
- "Permission denied" → Check file permissions and SELinux
- "Module not found" → Verify .so file exists and LoadModule path correct
- "SSL handshake failed" → Check certificates with openssl verify

---

## ⏰ Time Estimates

| Task | Docker | Modules | Notes |
|------|--------|---------|-------|
| Pre-check | 5 min | 5 min | Always do this first |
| Installation | 10 min | 5 min | If tools missing |
| Build/Download | 5 min | 30 min | Docker faster |
| Configuration | 10 min | 10 min | Similar |
| Testing | 5 min | 5 min | Same tests |
| **Total** | **35 min** | **55 min** | Docker recommended |

---

## 🎯 Monday Morning Checklist

**Before you start:**
- [ ] Coffee ready ☕
- [ ] Full guide read (`CENTOS7-IMPLEMENTATION-GUIDE.md`)
- [ ] Server access verified
- [ ] Sudo password ready
- [ ] Backup plan ready
- [ ] 2-3 hour time window reserved

**Start with:**
1. Run pre-check commands
2. Choose Docker if available
3. Follow step-by-step from guide
4. Test thoroughly
5. Document any issues

**Good luck! 🚀**

---

**Keep this card open while working!**
