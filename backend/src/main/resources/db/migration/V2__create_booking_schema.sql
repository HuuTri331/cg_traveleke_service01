
-- V2: Multi-hotel booking schema
-- MySQL 9.0 / Flyway
-- Quy ước: BIGINT UNSIGNED, InnoDB, utf8mb4

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT uk_users_email UNIQUE (email),
    CONSTRAINT chk_users_status
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE roles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(40) NOT NULL,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT uk_roles_code UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE user_roles (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id)
        REFERENCES users(id),
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id)
        REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO roles (code, name) VALUES
('SUPER_ADMIN', 'Quản trị hệ thống'),
('HOTEL_MANAGER', 'Quản lý khách sạn'),
('HOTEL_STAFF', 'Nhân viên khách sạn'),
('CUSTOMER', 'Khách hàng');

CREATE TABLE hotels (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(220) NOT NULL,
    description TEXT,
    address VARCHAR(500) NOT NULL,
    city VARCHAR(120) NOT NULL,
    country VARCHAR(120) NOT NULL DEFAULT 'Vietnam',
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    star_rating TINYINT UNSIGNED,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_by BIGINT UNSIGNED,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT uk_hotels_slug UNIQUE (slug),
    CONSTRAINT fk_hotels_creator FOREIGN KEY (created_by)
        REFERENCES users(id),
    CONSTRAINT chk_hotels_stars
        CHECK (star_rating IS NULL OR star_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_hotels_status
        CHECK (status IN ('DRAFT', 'PENDING', 'ACTIVE', 'INACTIVE')),
    INDEX idx_hotels_city_status (city, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE hotel_staff (
    hotel_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    staff_role VARCHAR(20) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (hotel_id, user_id),
    CONSTRAINT fk_hs_hotel FOREIGN KEY (hotel_id)
        REFERENCES hotels(id),
    CONSTRAINT fk_hs_user FOREIGN KEY (user_id)
        REFERENCES users(id),
    CONSTRAINT chk_hs_role
        CHECK (staff_role IN ('MANAGER', 'STAFF')),
    INDEX idx_hs_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE room_types (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hotel_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    max_adults INT UNSIGNED NOT NULL DEFAULT 2,
    max_children INT UNSIGNED NOT NULL DEFAULT 0,
    base_price DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_rt_hotel FOREIGN KEY (hotel_id)
        REFERENCES hotels(id),
    CONSTRAINT uk_rt_hotel_name UNIQUE (hotel_id, name),
    CONSTRAINT uk_rt_id_hotel UNIQUE (id, hotel_id),
    CONSTRAINT chk_rt_price CHECK (base_price >= 0),
    CONSTRAINT chk_rt_status
        CHECK (status IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE rooms (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_type_id BIGINT UNSIGNED NOT NULL,
    room_number VARCHAR(30) NOT NULL,
    floor_number INT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_rooms_type FOREIGN KEY (room_type_id)
        REFERENCES room_types(id),
    CONSTRAINT uk_rooms_type_number
        UNIQUE (room_type_id, room_number),
    CONSTRAINT chk_rooms_status
        CHECK (status IN ('ACTIVE', 'MAINTENANCE', 'INACTIVE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE room_inventory (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_type_id BIGINT UNSIGNED NOT NULL,
    inventory_date DATE NOT NULL,
    total_rooms INT UNSIGNED NOT NULL,
    available_rooms INT UNSIGNED NOT NULL,
    CONSTRAINT fk_inventory_type FOREIGN KEY (room_type_id)
        REFERENCES room_types(id),
    CONSTRAINT uk_inventory_type_date
        UNIQUE (room_type_id, inventory_date),
    CONSTRAINT chk_inventory_available
        CHECK (available_rooms <= total_rooms)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE room_rates (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_type_id BIGINT UNSIGNED NOT NULL,
    rate_date DATE NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    CONSTRAINT fk_rates_type FOREIGN KEY (room_type_id)
        REFERENCES room_types(id),
    CONSTRAINT uk_rates_type_date
        UNIQUE (room_type_id, rate_date),
    CONSTRAINT chk_rates_price CHECK (price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE bookings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_code VARCHAR(40) NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    hotel_id BIGINT UNSIGNED NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'VND',
    status VARCHAR(30) NOT NULL DEFAULT 'PAYMENT_PENDING',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT uk_bookings_code UNIQUE (booking_code),
    CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id)
        REFERENCES users(id),
    CONSTRAINT fk_bookings_hotel FOREIGN KEY (hotel_id)
        REFERENCES hotels(id),
    CONSTRAINT uk_bookings_id_hotel UNIQUE (id, hotel_id),
    CONSTRAINT chk_bookings_dates CHECK (check_out > check_in),
    CONSTRAINT chk_bookings_amount CHECK (total_amount >= 0),
    CONSTRAINT chk_bookings_status CHECK (status IN (
        'PAYMENT_PENDING', 'PENDING', 'CONFIRMED',
        'CHECKED_IN', 'COMPLETED', 'CANCELLED',
        'REJECTED', 'PAYMENT_EXPIRED'
    )),
    INDEX idx_bookings_customer (customer_id, created_at),
    INDEX idx_bookings_hotel_status (hotel_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE booking_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    hotel_id BIGINT UNSIGNED NOT NULL,
    room_type_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    CONSTRAINT fk_bi_booking_hotel
        FOREIGN KEY (booking_id, hotel_id)
        REFERENCES bookings(id, hotel_id),
    CONSTRAINT fk_bi_room_type_hotel
        FOREIGN KEY (room_type_id, hotel_id)
        REFERENCES room_types(id, hotel_id),
    CONSTRAINT chk_bi_quantity CHECK (quantity > 0),
    CONSTRAINT chk_bi_price
        CHECK (unit_price >= 0 AND subtotal >= 0),
    INDEX idx_bi_room_type (room_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    provider VARCHAR(30) NOT NULL,
    transaction_code VARCHAR(150),
    amount DECIMAL(15,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'VND',
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    paid_at DATETIME(6),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(id),
    CONSTRAINT uk_payments_provider_transaction
        UNIQUE (provider, transaction_code),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0),
    CONSTRAINT chk_payments_status CHECK (status IN (
        'PENDING', 'PAID', 'FAILED',
        'EXPIRED', 'REFUND_PENDING', 'REFUNDED'
    )),
    INDEX idx_payments_booking (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE reviews (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    hotel_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL,
    comment TEXT,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT uk_reviews_booking UNIQUE (booking_id),
    CONSTRAINT fk_reviews_booking_hotel
        FOREIGN KEY (booking_id, hotel_id)
        REFERENCES bookings(id, hotel_id),
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id)
        REFERENCES users(id),
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    INDEX idx_reviews_hotel (hotel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ai_conversations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255),
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_ai_conversations_user FOREIGN KEY (user_id)
        REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ai_messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT UNSIGNED NOT NULL,
    sender VARCHAR(20) NOT NULL,
    content LONGTEXT NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_ai_messages_conversation
        FOREIGN KEY (conversation_id)
        REFERENCES ai_conversations(id),
    CONSTRAINT chk_ai_messages_sender
        CHECK (sender IN ('USER', 'ASSISTANT', 'TOOL')),
    INDEX idx_ai_messages_conversation
        (conversation_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
