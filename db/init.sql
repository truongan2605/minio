-- ============================================================
-- Storage App - Database Schema
-- ============================================================

-- Bảng users
CREATE TABLE IF NOT EXISTS users (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    role        ENUM('ADMIN', 'USER') NOT NULL DEFAULT 'USER',
    avatar_url  VARCHAR(500),
    storage_quota_mb  BIGINT NOT NULL DEFAULT 1024,  -- 1GB mặc định
    storage_used_mb   BIGINT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Bảng buckets (metadata, bucket thật sẽ trên MinIO)
CREATE TABLE IF NOT EXISTS buckets (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    owner_id    BIGINT NOT NULL,
    policy      ENUM('PUBLIC', 'PRIVATE') NOT NULL DEFAULT 'PRIVATE',
    description VARCHAR(255),
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Bảng files (metadata của từng object trên MinIO)
CREATE TABLE IF NOT EXISTS files (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    object_name    VARCHAR(500) NOT NULL,       -- key trong MinIO
    original_name  VARCHAR(255) NOT NULL,       -- tên gốc khi upload
    bucket_name    VARCHAR(100) NOT NULL,
    owner_id       BIGINT NOT NULL,
    content_type   VARCHAR(100),
    size_bytes     BIGINT NOT NULL DEFAULT 0,
    etag           VARCHAR(255),                -- checksum MinIO trả về
    is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_bucket_owner (bucket_name, owner_id),
    INDEX idx_owner (owner_id)
);

-- Bảng shared_links (presigned URLs được tạo để chia sẻ)
CREATE TABLE IF NOT EXISTS shared_links (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_id     BIGINT NOT NULL,
    token       VARCHAR(255) NOT NULL UNIQUE,
    expires_at  DATETIME NOT NULL,
    created_by  BIGINT NOT NULL,
    download_count INT NOT NULL DEFAULT 0,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Bảng activity_logs
CREATE TABLE IF NOT EXISTS activity_logs (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT,
    action      VARCHAR(50) NOT NULL,  -- UPLOAD, DOWNLOAD, DELETE, SHARE, LOGIN...
    object_name VARCHAR(500),
    bucket_name VARCHAR(100),
    ip_address  VARCHAR(45),
    user_agent  VARCHAR(500),
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_action (user_id, action),
    INDEX idx_created_at (created_at)
);

-- ─────────────────────────────────────────────
-- Seed data: tài khoản admin mặc định
-- Password: Admin@123 (BCrypt hash)
-- ─────────────────────────────────────────────
INSERT IGNORE INTO users (username, email, password, role, storage_quota_mb)
VALUES (
    'admin',
    'admin@storage.local',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',  -- Admin@123
    'ADMIN',
    102400  -- 100GB cho admin
);
