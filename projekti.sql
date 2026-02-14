CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('client','professional','admin') NOT NULL,
    bio TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE professionals (
    professional_id INT PRIMARY KEY,
    experience_years INT CHECK (experience_years >= 0),
    is_verified BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_professional_user
        FOREIGN KEY (professional_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


CREATE TABLE availability (
    availability_id INT PRIMARY KEY AUTO_INCREMENT,
    professional_id INT NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('available','unavailable','booked') DEFAULT 'available',

    CONSTRAINT fk_availability_professional
        FOREIGN KEY (professional_id)
        REFERENCES professionals(professional_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_time_range CHECK (start_time < end_time)
);


CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);


CREATE TABLE services (
    service_id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_service_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
);


CREATE TABLE professional_services (
    professional_id INT NOT NULL,
    service_id INT NOT NULL,
    custom_price DECIMAL(10,2) CHECK (custom_price >= 0),

    PRIMARY KEY (professional_id, service_id),

    CONSTRAINT fk_ps_professional
        FOREIGN KEY (professional_id)
        REFERENCES professionals(professional_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ps_service
        FOREIGN KEY (service_id)
        REFERENCES services(service_id)
        ON DELETE CASCADE
);


CREATE TABLE reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    professional_id INT NOT NULL,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    status ENUM('pending','confirmed','completed','cancelled') DEFAULT 'pending',
    is_payed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reservation_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_reservation_professional
        FOREIGN KEY (professional_id)
        REFERENCES professionals(professional_id)
);


CREATE TABLE reservation_services (
    reservation_id INT NOT NULL,
    service_id INT NOT NULL,

    PRIMARY KEY (reservation_id, service_id),

    CONSTRAINT fk_rs_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_rs_service
        FOREIGN KEY (service_id)
        REFERENCES services(service_id)
        ON DELETE CASCADE
);


CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_id INT UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    method ENUM('cash','card','online') NOT NULL,
    payment_status ENUM('pending','completed','failed') DEFAULT 'pending',
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id)
        ON DELETE CASCADE
);


CREATE TABLE reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_id INT UNIQUE NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_review_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id)
        ON DELETE CASCADE
);
