# X-Road Docker

Dự án X-Road sử dụng Docker, bao gồm Central Server, Security Server và TestCA để phát triển và kiểm thử.

## Tổng quan

X-Road là một nền tảng trao đổi dữ liệu an toàn giữa các hệ thống thông tin. Dự án này containerize toàn bộ môi trường X-Road để dễ dàng triển khai và quản lý.

## Kiến trúc

Dự án bao gồm hai thành phần chính:

### 1. Central Service
- **Central Server**: Máy chủ trung tâm quản lý cấu hình và chứng chỉ
- **Management Security Server**: Máy chủ bảo mật quản lý
- **TestCA**: Certificate Authority thử nghiệm
- **Setup Service**: Dịch vụ tự động cấu hình

### 2. Security Server
- **Security Server**: Máy chủ bảo mật cho các tổ chức thành viên
- **Database**: PostgreSQL cho Security Server
- **Setup Service**: Dịch vụ tự động cấu hình

## Cài đặt và chạy

### 1. Clone repository

```bash
git clone <repository-url>
cd x-road-docker
```

### 2. Khởi động Central Service

```bash
cd central-service
docker-compose up -d
```

### 3. Khởi động Security Server (máy khác)

```bash
cd ../security-server
docker-compose up -d
```

## Cấu hình

### Central Service

Các biến môi trường chính trong `central-service/docker-compose.yml`:

- Tùy chỉnh port để truy cập dịch vụ
- `XROAD_TOKEN_PIN`: Mã PIN cho token bảo mật
- `XROAD_ADMIN_USER`: Tên người dùng quản trị
- `XROAD_ADMIN_PASSWORD`: Mật khẩu quản trị

### Security Server

Các biến môi trường chính trong `security-server/setup/scenarios/vars.env`:

- `central-server`: IP máy chạy CS
- `API_KEY_FROM_CENTRAL_SERVER`: API_KEY từ CS - dùng lệnh `docker exec central-server cat /etc/xroad/conf.d/local.ini | grep api-token`

Các biến môi trường chính trong `security-server/docker-compose.yml`:

- Tùy chỉnh port để truy cập dịch vụ
- `XROAD_TOKEN_PIN`: Mã PIN cho token bảo mật
- `XROAD_ADMIN_USER`: Tên người dùng quản trị
- `XROAD_ADMIN_PASSWORD`: Mật khẩu quản trị
- `XROAD_DB_HOST`: Host của database
- `XROAD_DB_PWD`: Mật khẩu database

## Dịch vụ và Ports

### Central Service
- **TestCA**: 
  - OCSP: `8888`
  - TSA: `8899`
  - ACME: `8887`
- **Central Server**: `4000` (HTTPS)
- **Management Security Server**: `4004` (HTTPS)

### Security Server
- **Security Server**: `4000` (HTTPS)
- **Database**: `5432` (PostgreSQL)

> **Lưu ý**: Các ports được comment trong docker-compose.yml để bảo mật. Bỏ comment nếu cần truy cập từ bên ngoài.

## Sử dụng

### 1. Kiểm tra trạng thái dịch vụ

```bash
# Central Service
cd central-service
docker-compose ps

# Security Server
cd ../security-server
docker-compose ps
```

### 2. Xem logs

```bash
# Central Service
docker-compose logs -f central-server
docker-compose logs -f management-security-server
docker-compose logs -f testca

# Security Server
docker-compose logs -f security-server
```

### 3. Truy cập giao diện quản trị

Sau khi các dịch vụ khởi động thành công, bạn có thể truy cập:

- **Central Server**: `https://localhost:4000`
- **Management Security Server**: `https://localhost:4000`
- **Security Server**: `https://localhost:4000`

### 4. Thông tin đăng nhập mặc định

#### Central Server
- Username: `cs-admin`
- Password: `cs-admin123123@`

#### Management Security Server
- Username: `ssm-admin`
- Password: `ssm-admin123123@`

#### Security Server
- Username: `admin`
- Password: `Admin123123@`