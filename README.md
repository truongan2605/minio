# MinIO (2 Zones) + MySQL - Docker Local Setup

Dự án storage sử dụng **MinIO (Object Storage — Zone 1 & Zone 2)** + **MySQL** (kèm tùy chọn **Ngrok** để expose API), chạy local bằng Docker Compose.

---

## 📋 Cấu trúc thư mục

```
minio/
├── docker-compose.yml       ← Khởi động toàn bộ services (minio1, minio2, minio-init, mysql, ngrok1, ngrok2)
├── .env.example             ← Mẫu biến môi trường (copy thành .env trước khi chạy)
├── db/
│   └── init.sql             ← Schema database (tự chạy khi khởi động MySQL lần đầu)
├── api-tests/
│   └── minio-test.http      ← File test HTTP API (dùng với VS Code REST Client)
├── s3.md                    ← Tài liệu tham khảo S3 / Admin HTTP API
└── README.md
```

---

## 🚀 Hướng dẫn cài đặt & khởi động

### Yêu cầu

- Đã cài [Docker Desktop](https://www.docker.com/products/docker-desktop/) (hoặc Docker Engine + Docker Compose)

### Bước 1: Clone dự án & tạo file `.env`

```bash
git clone https://github.com/truongan2605/minio.git
cd minio
```

Copy `.env.example` thành `.env`:

```powershell
# PowerShell (Windows)
Copy-Item .env.example .env
```

```bash
# macOS / Linux / Git Bash
cp .env.example .env
```

> **Lưu ý:** Có thể giữ nguyên cấu hình mặc định trong `.env` để chạy local. Nếu cần expose MinIO ra ngoài qua Ngrok, hãy điền `NGROK_AUTHTOKEN_1/2` và `NGROK_DOMAIN_1/2` của riêng bạn vào `.env`.

### Bước 2: Khởi động services

**Cách A — Chỉ chạy MinIO (2 Zone) + MySQL ở local (khuyên dùng nếu không cần Ngrok):**

```bash
docker compose up -d minio1 minio2 minio-init mysql
```

**Cách B — Chạy toàn bộ (bao gồm Ngrok 1 & Ngrok 2):**

```bash
docker compose up -d
```

### Bước 3: Kiểm tra services đang chạy

```bash
docker compose ps
```

Output mong đợi:
```
NAME          STATUS
minio1        Up (healthy)
minio2        Up (healthy)
mysql         Up (healthy)
minio-init    Exited (0)    ← OK! Tạo bucket & policy xong là tự thoát
```

### Bước 4: Truy cập MinIO Console

| Zone | Web Console | S3 API Endpoint | Username | Password |
|---|---|---|---|---|
| **Zone 1 (`minio1`)** | http://localhost:9001 | http://localhost:9000 | `minioadmin` | `minioadmin123` |
| **Zone 2 (`minio2`)** | http://localhost:9003 | http://localhost:9002 | `minioadmin` | `minioadmin123` |

---

## 🪣 Buckets được tạo tự động (trên cả 2 Zone)

| Bucket | Policy | Mục đích |
|---|---|---|
| `public-files` | Public (download) | File công khai |
| `private-files` | Private | File riêng tư |
| `avatars` | Public (download) | Ảnh đại diện |

---

## 🗄️ Kết nối MySQL

```
Host:     localhost
Port:     3306
Database: storage_db
User:     storage_user
Password: storage_pass123
```

---

## 🛑 Dừng services

```bash
# Dừng nhưng giữ data
docker compose stop

# Dừng và XÓA containers (data vẫn giữ trong volumes)
docker compose down

# Dừng và XÓA tất cả (kể cả data!)
docker compose down -v
```

---

## 🔌 Endpoints tổng hợp

| Service | Endpoint | Mô tả |
|---|---|---|
| MinIO Zone 1 API | `http://localhost:9000` | S3 API (dùng cho SDK/CLI) |
| MinIO Zone 1 Console | `http://localhost:9001` | Web Console Zone 1 |
| MinIO Zone 1 Health | `http://localhost:9000/minio/health/live` | Health check Zone 1 |
| MinIO Zone 2 API | `http://localhost:9002` | S3 API Zone 2 |
| MinIO Zone 2 Console | `http://localhost:9003` | Web Console Zone 2 |
| MinIO Zone 2 Health | `http://localhost:9002/minio/health/live` | Health check Zone 2 |
| Ngrok 1 Inspector | `http://localhost:4040` | Giao diện kiểm tra tunnel Zone 1 (nếu bật Ngrok) |
| Ngrok 2 Inspector | `http://localhost:4041` | Giao diện kiểm tra tunnel Zone 2 (nếu bật Ngrok) |

---

## 📦 MinIO SDK - Java (Spring Boot)

Thêm vào `pom.xml`:

```xml
<dependency>
    <groupId>io.minio</groupId>
    <artifactId>minio</artifactId>
    <version>8.5.7</version>
</dependency>
```

Kết nối:

```java
MinioClient minioClient = MinioClient.builder()
    .endpoint("http://localhost:9000") // hoặc http://localhost:9002 cho Zone 2
    .credentials("minioadmin", "minioadmin123")
    .build();
```
