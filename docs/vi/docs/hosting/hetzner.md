[English](../../../hosting/hetzner.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="deploying-sure-on-hetzner-cloud"></a>
# Triển khai Sure trên Hetzner Cloud

Hướng dẫn triển khai Sure trên server Hetzner Cloud bằng Docker Compose, gồm chứng chỉ SSL, gia cố bảo mật và sao lưu tự động.

<a id="prerequisites"></a>
## Điều kiện tiên quyết

Trước khi bắt đầu, bảo đảm có:

- Server Hetzner Cloud (khuyến nghị tối thiểu 4GB RAM, 2 lõi CPU)
- Tên miền trỏ tới địa chỉ IP server
- Quyền truy cập server qua SSH
- Kiến thức cơ bản về dòng lệnh Linux

<a id="step-1-server-setup-and-security"></a>
## Bước 1: Thiết lập và bảo mật server

Kết nối server Hetzner và thiết lập môi trường cơ bản:

```bash
# Connect to your server (replace with your server's IP)
ssh root@YOUR_SERVER_IP

# Update the system
apt update && apt upgrade -y

# Install essential packages
apt install -y curl wget git ufw fail2ban

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add your user to docker group (replace 'your_username' with your actual username)
# If you are using root, you can skip this step
if [ "$(whoami)" != "root" ]; then
    usermod -aG docker "$(whoami)"
fi

# Configure firewall
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

# Configure fail2ban for SSH protection
systemctl enable fail2ban
systemctl start fail2ban
```

<a id="step-2-create-application-directory"></a>
## Bước 2: Tạo thư mục ứng dụng

```bash
# Create directory for the application
mkdir -p /opt/sure
cd /opt/sure

# Download the Docker Compose configuration
curl -o compose.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.yml
```

<a id="step-3-configure-environment-variables"></a>
## Bước 3: Cấu hình biến môi trường

Tạo cấu hình môi trường an toàn:

```bash
# Create environment file
nano .env
```

Thêm nội dung sau vào `.env` (thay bằng giá trị của bạn):

```bash
# Generate a secure secret key
SECRET_KEY_BASE="$(openssl rand -hex 64)"

# Database configuration
POSTGRES_USER="sure_user"
POSTGRES_PASSWORD="$(openssl rand -base64 32)"
POSTGRES_DB="sure_production"

# Optional: OpenAI integration (add your API key if you want AI features)
# OPENAI_ACCESS_TOKEN="your_openai_api_key_here"
```

**Lưu ý bảo mật quan trọng:**
- Không bao giờ dùng giá trị mặc định của file mẫu trong production
- Bảo vệ `.env`, tuyệt đối không commit vào hệ thống quản lý phiên bản
- `SECRET_KEY_BASE` rất quan trọng với bảo mật Rails; hãy giữ bí mật

<a id="step-4-set-up-reverse-proxy-with-ssl"></a>
## Bước 4: Thiết lập reverse proxy với SSL

Dùng Nginx làm reverse proxy với chứng chỉ SSL Let's Encrypt:

```bash
# Install Nginx and Certbot
apt install -y nginx certbot python3-certbot-nginx

# Create Nginx configuration for your domain
nano /etc/nginx/sites-available/sure
```

Thêm cấu hình Nginx sau (thay `yourdomain.com` bằng tên miền thực):

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
}
```

```bash
# Enable the site
ln -s /etc/nginx/sites-available/sure /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Start Nginx
systemctl enable nginx
systemctl start nginx

# Get SSL certificate
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

<a id="step-5-deploy-the-application"></a>
## Bước 5: Triển khai ứng dụng

Triển khai ứng dụng Sure:

```bash
# Navigate to the application directory
cd /opt/sure

# Pull the latest Docker images
docker compose pull

# Start the application
docker compose up -d

# Check if everything is running
docker compose ps

# View logs to ensure everything started correctly
docker compose logs -f
```

<a id="step-6-test-the-deployment"></a>
## Bước 6: Kiểm tra bản triển khai

Xác minh bản triển khai hoạt động:

```bash
# Check if the application is accessible
curl -I https://yourdomain.com

# Check Docker container health
docker compose ps
```

Bây giờ bạn có thể:

1. **Truy cập ứng dụng**: mở `https://yourdomain.com` trong trình duyệt
2. **Tạo tài khoản admin**: nhấp “Create your account” trên trang đăng nhập
3. **Thiết lập hộ gia đình đầu tiên**: làm theo quy trình onboarding

<a id="optional-disable-self-service-registration"></a>
### Tùy chọn: Tắt đăng ký tự phục vụ

Khi tài khoản admin đầu tiên sẵn sàng, mở **Settings > Self-Hosting > Onboarding** để chọn cách đăng ký:

- **Open**: bất kỳ ai cũng có thể đăng ký.
- **Invite-only**: đăng ký mới cần mã mời hợp lệ, trừ khi bạn cấu hình hộ gia đình mặc định cho onboarding chỉ theo lời mời.
- **Closed**: chặn đăng ký mới từ trang đăng ký.

Với bản triển khai chỉ có một admin hoặc cần kiểm soát chặt, đặt onboarding thành **Closed** sau thiết lập ban đầu.

<a id="step-7-set-up-automated-backups"></a>
## Bước 7: Thiết lập sao lưu tự động

`compose.yml` đã tải có dịch vụ sao lưu cơ sở dữ liệu, file tải lên và cấu hình cùng nhau, tổ chức theo phiên bản ứng dụng. Dịch vụ dùng cùng image với ứng dụng nên không cần cài thêm. Khởi động để sao lưu hằng ngày:

```bash
cd /opt/sure

# Optional: change the defaults in .env
#   BACKUP_DIR=/opt/sure/backups   (default: ./backups)
#   BACKUP_SCHEDULE="0 2 * * *"     (daily at 02:00 UTC)
#   BACKUP_KEEP_DAYS=7

docker compose --profile backup up -d backup
```

Có thể sao lưu thủ công bất kỳ lúc nào, ví dụ trước khi cập nhật:

```bash
docker compose run --rm backup create
docker compose run --rm backup list
```

Xem [Sao lưu, nâng cấp và rollback](docker.md#backups-upgrades-and-rollbacks) về bản sao ngoài hệ thống, khôi phục và quay lại phiên bản cũ.

<a id="step-8-set-up-basic-monitoring"></a>
## Bước 8: Thiết lập giám sát cơ bản

Tạo script kiểm tra tình trạng để giám sát ứng dụng:

```bash
# Install htop for system monitoring
apt install -y htop

# Create a simple health check script
nano /opt/sure/health-check.sh
```

Thêm script kiểm tra sau:

```bash
#!/bin/bash
# Check if the application is responding
if curl -f -s https://yourdomain.com > /dev/null; then
    echo "$(date): Application is healthy"
else
    echo "$(date): Application is down - restarting"
    cd /opt/sure
    docker compose restart web worker
fi
```

```bash
# Make health check executable
chmod +x /opt/sure/health-check.sh

# Add to crontab to run every 5 minutes
crontab -e
```

Thêm dòng này:
```bash
*/5 * * * * /opt/sure/health-check.sh >> /var/log/sure-health.log 2>&1
```

<a id="maintenance-commands"></a>
## Lệnh bảo trì

Các lệnh thiết yếu để bảo trì bản triển khai:

<a id="update-the-application"></a>
### Cập nhật ứng dụng:
```bash
cd /opt/sure
docker compose run --rm backup create
docker compose pull web worker
docker compose up -d
```

<a id="view-logs"></a>
### Xem nhật ký:
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f web
docker compose logs -f worker
docker compose logs -f db
```

<a id="restart-services"></a>
### Khởi động lại dịch vụ:
```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart web
```

<a id="check-system-resources"></a>
### Kiểm tra tài nguyên hệ thống:
```bash
# Docker resource usage
docker stats

# System resources
htop
df -h
```

<a id="restore-from-backup"></a>
### Khôi phục từ bản sao lưu:
Trên cùng server (ví dụ để hoàn tác nâng cấp):
```bash
cd /opt/sure
docker compose run --rm backup list
docker compose stop web worker
docker compose run --rm backup restore <version>/<backup>   # or "latest"
# Set SURE_IMAGE_TAG in .env to the version printed by restore, then:
docker compose up -d
```

Trên server mới, sao chép thư mục sao lưu sang và chạy `restore.sh` của bản sao đó. Script khôi phục `.env`, gồm `SECRET_KEY_BASE`; thiếu khóa này thì không đọc được dữ liệu đã mã hóa:
```bash
sh /path/to/<backup>/restore.sh
```

<a id="security-features"></a>
## Tính năng bảo mật

Bản triển khai có các biện pháp bảo mật:

1. **Tường lửa**: chỉ mở cổng 22 (SSH), 80 (HTTP) và 443 (HTTPS)
2. **Fail2ban**: bảo vệ SSH trước tấn công dò mật khẩu brute force
3. **SSL/TLS**: HTTPS tự động với chứng chỉ Let's Encrypt
4. **Biến môi trường**: dữ liệu nhạy cảm lưu an toàn trong `.env`
5. **Container không chạy root**: ứng dụng chạy dưới người dùng không phải root
6. **Cập nhật thường xuyên**: giữ hệ thống và image Docker được cập nhật

<a id="troubleshooting"></a>
## Xử lý sự cố

<a id="common-issues-and-solutions"></a>
### Vấn đề thường gặp và cách khắc phục

**Ứng dụng không khởi động:**
```bash
# Check logs for errors
docker compose logs -f

# Check if ports are available
netstat -tulpn | grep :3000
```

**Lỗi kết nối cơ sở dữ liệu:**
```bash
# Check database container
docker compose logs db

# Test database connection
docker compose exec db psql -U sure_user -d sure_production -c "SELECT 1;"
```

**Lỗi chứng chỉ SSL:**
```bash
# Renew certificates
certbot renew --dry-run

# Check certificate status
certbot certificates
```

**Hết dung lượng đĩa:**
```bash
# Check disk usage
df -h

# Clean up Docker images
docker system prune -a

# Clean up old scheduled backups (backups you took by hand are kept)
cd /opt/sure && docker compose run --rm backup prune
```

**Ứng dụng chậm:**
```bash
# Check system resources
htop
docker stats

# Check if containers are healthy
docker compose ps
```

<a id="performance-optimization"></a>
## Tối ưu hiệu năng

Để cải thiện hiệu năng trên Hetzner Cloud:

1. **Dùng SSD**: Hetzner Cloud cung cấp NVMe SSD mặc định
2. **Chọn cấu hình server phù hợp**:
   - Tối thiểu: CX21 (2 vCPU, 4GB RAM)
   - Khuyến nghị: CX31 (2 vCPU, 8GB RAM) cho nhiều người dùng
3. **Bật swap** (nếu cần):
   ```bash
   fallocate -l 2G /swapfile
   chmod 600 /swapfile
   mkswap /swapfile
   swapon /swapfile
   echo '/swapfile none swap sw 0 0' >> /etc/fstab
   ```

<a id="backup-strategy"></a>
## Chiến lược sao lưu

Chiến lược sao lưu gồm:

1. **Sao lưu tự động hằng ngày** cơ sở dữ liệu, file tải lên và cấu hình, tổ chức theo phiên bản ứng dụng
2. **Giữ bản sao theo lịch 7 ngày**; bản sao thủ công được giữ lại
3. **Thư mục sao lưu** tại `./backups` (hoặc `BACKUP_DIR`)
4. **Ghi nhật ký** thao tác sao lưu (`docker compose logs backup`)

Cân nhắc các phương án bổ sung:
- **Sao lưu ngoài hệ thống**: đặt `BACKUP_DESTINATION` để sao chép mỗi bản sao tới S3, Google Cloud, v.v. qua rclone (xem `.env.example`)
- **Nhân bản cơ sở dữ liệu**: thiết lập PostgreSQL streaming replication
- **Sao lưu snapshot**: dùng snapshot Hetzner Cloud để sao lưu toàn hệ thống

<a id="next-steps"></a>
## Bước tiếp theo

Sau khi triển khai thành công:

1. **Tạo tài khoản admin** tại `https://yourdomain.com`
2. **Thiết lập hộ gia đình đầu tiên** trong ứng dụng
3. **Cấu hình kết nối ngân hàng** (nếu dùng tích hợp Plaid)
4. **Thiết lập thêm người dùng** khi cần
5. **Giám sát bản triển khai** qua nhật ký kiểm tra tình trạng

<a id="support"></a>
## Hỗ trợ

Nếu gặp vấn đề:

1. Xem [mục xử lý sự cố](#troubleshooting) phía trên
2. Xem nhật ký ứng dụng: `docker compose logs -f`
3. Kiểm tra tài nguyên hệ thống: `htop` và `df -h`
4. Mở thảo luận trong [repository GitHub](https://github.com/we-promise/sure/discussions)

<a id="security-reminders"></a>
## Nhắc nhở bảo mật

- Cập nhật server: `apt update && apt upgrade`
- Theo dõi nhật ký thường xuyên: `docker compose logs backup` và `/var/log/sure-health.log`
- Dùng mật khẩu mạnh cho mọi tài khoản
- Cân nhắc xác thực bằng khóa SSH thay cho mật khẩu
- Rà soát quy tắc tường lửa thường xuyên: `ufw status`
- Theo dõi hạn chứng chỉ SSL: `certbot certificates`
