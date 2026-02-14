-- =============================================
-- Professional Services Booking Platform
-- Database Creation Script for SQL Server
-- Updated to match ER Diagram
-- =============================================

-- Create Database
USE master;
GO

-- Drop database if it exists (for development purposes)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'ProfessionalServicesBooking')
BEGIN
    ALTER DATABASE ProfessionalServicesBooking SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ProfessionalServicesBooking;
END
GO

CREATE DATABASE ProfessionalServicesBooking;
GO

USE ProfessionalServicesBooking;
GO

-- =============================================
-- PART 1: User Defined Data Type (UDDT)
-- =============================================

-- Create PhoneNumber UDDT
CREATE TYPE PhoneNumber FROM VARCHAR(20) NOT NULL;
GO

-- Create a rule for phone number validation
CREATE RULE rule_PhoneNumber AS
    @value LIKE '+[0-9]%'
    AND LEN(@value) >= 10
    AND LEN(@value) <= 20;
GO

-- Bind the rule to the PhoneNumber type
EXEC sp_bindrule 'rule_PhoneNumber', 'PhoneNumber';
GO

-- =============================================
-- PART 1.5: Create Partition Function and Scheme
-- =============================================

-- Partition by ReservationDate (yearly ranges)
CREATE PARTITION FUNCTION pf_ReservationDate (DATE)
AS RANGE RIGHT FOR VALUES ('2024-01-01', '2025-01-01', '2026-01-01', '2027-01-01');
GO

CREATE PARTITION SCHEME ps_ReservationDate
AS PARTITION pf_ReservationDate ALL TO ([PRIMARY]);
GO

-- =============================================
-- PART 2: Create Tables
-- =============================================

-- 1. Users Table (unified - replaces separate Professionals/Clients)
-- USERS
CREATE TABLE [User] (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    firstname NVARCHAR(100) NOT NULL,
    lastname NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    role NVARCHAR(50) NOT NULL CHECK (role IN ('client', 'professional', 'admin')),
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

-- CATEGORY
CREATE TABLE Category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name NVARCHAR(150) NOT NULL UNIQUE,
    description NVARCHAR(500),
    is_active BIT NOT NULL DEFAULT 1
);

-- SERVICE
CREATE TABLE Service (
    service_id INT IDENTITY(1,1) PRIMARY KEY,
    service_name NVARCHAR(150) NOT NULL,
    description NVARCHAR(500),
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
    is_active BIT NOT NULL DEFAULT 1,
    category_id INT NOT NULL,
    CONSTRAINT FK_Service_Category
        FOREIGN KEY (category_id)
        REFERENCES Category(category_id)
        ON DELETE CASCADE
);

-- PROFESSIONAL
CREATE TABLE Professional (
    professional_id INT IDENTITY(1,1) PRIMARY KEY,
    bio NVARCHAR(500),
    experience_years INT CHECK (experience_years >= 0),
    is_verified BIT NOT NULL DEFAULT 0,
    user_id INT NOT NULL UNIQUE,
    CONSTRAINT FK_Professional_User
        FOREIGN KEY (user_id)
        REFERENCES [User](user_id)
        ON DELETE CASCADE
);

-- PROFESSIONAL_SERVICE (M:N)
CREATE TABLE ProfessionalService (
    professional_id INT NOT NULL,
    service_id INT NOT NULL,
    custom_price DECIMAL(10,2) NULL CHECK (custom_price >= 0),
    CONSTRAINT PK_ProfessionalService PRIMARY KEY (professional_id, service_id),
    CONSTRAINT FK_PS_Professional
        FOREIGN KEY (professional_id)
        REFERENCES Professional(professional_id)
        ON DELETE CASCADE,
    CONSTRAINT FK_PS_Service
        FOREIGN KEY (service_id)
        REFERENCES Service(service_id)
        ON DELETE CASCADE
);

-- AVAILABILITY
CREATE TABLE Availability (
    availability_id INT IDENTITY(1,1) PRIMARY KEY,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('available', 'booked', 'unavailable')),
    [date] DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    professional_id INT NOT NULL,
    CONSTRAINT FK_Availability_Professional
        FOREIGN KEY (professional_id)
        REFERENCES Professional(professional_id)
        ON DELETE CASCADE,
    CONSTRAINT CHK_Time_Valid CHECK (start_time < end_time)
);

-- RESERVATION
CREATE TABLE Reservation (
    reservation_id INT IDENTITY(1,1) PRIMARY KEY,
    [date] DATE NOT NULL,
    [time] TIME NOT NULL,
    status NVARCHAR(50) NOT NULL CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    service_id INT NOT NULL,
    professional_id INT NOT NULL,
    user_id INT NOT NULL,
    CONSTRAINT FK_Reservation_Service
        FOREIGN KEY (service_id)
        REFERENCES Service(service_id),
    CONSTRAINT FK_Reservation_Professional
        FOREIGN KEY (professional_id)
        REFERENCES Professional(professional_id),
    CONSTRAINT FK_Reservation_User
        FOREIGN KEY (user_id)
        REFERENCES [User](user_id)
);

-- REVIEW
CREATE TABLE Review (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment NVARCHAR(500),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    reservation_id INT NOT NULL UNIQUE,
    CONSTRAINT FK_Review_Reservation
        FOREIGN KEY (reservation_id)
        REFERENCES Reservation(reservation_id)
        ON DELETE CASCADE
);

-- PAYMENT
CREATE TABLE Payment (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    method NVARCHAR(50) NOT NULL CHECK (method IN ('card', 'cash', 'paypal')),
    payment_status NVARCHAR(50) NOT NULL CHECK (payment_status IN ('pending', 'paid', 'failed')),
    transaction_date DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    reservation_id INT NOT NULL UNIQUE,
    CONSTRAINT FK_Payment_Reservation
        FOREIGN KEY (reservation_id)
        REFERENCES Reservation(reservation_id)
);

-- 11. ReservationAuditLog Table (for tracking deleted reservations)
CREATE TABLE ReservationAuditLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    ReservationID INT NOT NULL,
    UserID INT NOT NULL,
    ProfessionalID INT NOT NULL,
    ReservationDate DATE NOT NULL,
    ReservationTime TIME NOT NULL,
    Status NVARCHAR(20),
    IsPayed BIT,
    DeletedAt DATETIME DEFAULT GETDATE(),
    DeletedBy NVARCHAR(128) DEFAULT SUSER_SNAME()
);
GO

-- =============================================
-- PART 3: Create Indexes for Performance
-- =============================================

-- Users indexes
-- Users indexes
CREATE NONCLUSTERED INDEX IX_User_Role ON [User](role);
CREATE NONCLUSTERED INDEX IX_User_Email ON [User](email);
GO

-- Reservations indexes
CREATE NONCLUSTERED INDEX IX_Reservation_UserID ON Reservation(user_id);
CREATE NONCLUSTERED INDEX IX_Reservation_ProfessionalID ON Reservation(professional_id);
CREATE NONCLUSTERED INDEX IX_Reservation_Date ON Reservation([date]);
CREATE NONCLUSTERED INDEX IX_Reservation_Status ON Reservation(status);
GO

-- Services indexes
CREATE NONCLUSTERED INDEX IX_Service_CategoryID ON Service(category_id);
CREATE NONCLUSTERED INDEX IX_Service_IsActive ON Service(is_active) WHERE is_active = 1;
GO

-- Availability indexes
CREATE NONCLUSTERED INDEX IX_Availability_ProfessionalID ON Availability(professional_id);
CREATE NONCLUSTERED INDEX IX_Availability_Date ON Availability([date]);
GO

-- Reviews indexes
CREATE NONCLUSTERED INDEX IX_Review_ReservationID ON Review(reservation_id);
GO

-- View 1: vw_ProfessionalDashboard
CREATE VIEW vw_ProfessionalDashboard AS
SELECT
    p.professional_id,
    u.firstname + ' ' + u.lastname AS ProfessionalName,
    COUNT(DISTINCT r.reservation_id) AS TotalReservations,
    SUM(CASE WHEN r.status = 'completed' THEN 1 ELSE 0 END) AS CompletedReservations,
    AVG(CAST(rev.rating AS DECIMAL(3,2))) AS AverageRating,
    SUM(CASE WHEN pay.payment_status = 'paid' THEN pay.amount ELSE 0 END) AS TotalEarnings
FROM Professional p
JOIN [User] u ON p.user_id = u.user_id
LEFT JOIN Reservation r ON p.professional_id = r.professional_id
LEFT JOIN Review rev ON r.reservation_id = rev.reservation_id
LEFT JOIN Payment pay ON r.reservation_id = pay.reservation_id
GROUP BY p.professional_id, u.firstname, u.lastname;
GO


-- View 2: vw_ServiceCatalog
CREATE VIEW vw_ServiceCatalog AS
SELECT
    s.service_id,
    s.service_name,
    s.description,
    s.base_price,
    c.category_name,
    u.firstname + ' ' + u.lastname AS ProfessionalName,
    p.experience_years,
    ps.custom_price,
    AVG(CAST(rev.rating AS DECIMAL(3,2))) AS AverageRating,
    COUNT(DISTINCT rev.review_id) AS ReviewCount
FROM Service s
JOIN Category c ON s.category_id = c.category_id
JOIN ProfessionalService ps ON s.service_id = ps.service_id
JOIN Professional p ON ps.professional_id = p.professional_id
JOIN [User] u ON p.user_id = u.user_id
LEFT JOIN Reservation r ON r.professional_id = p.professional_id AND r.service_id = s.service_id
LEFT JOIN Review rev ON r.reservation_id = rev.reservation_id
WHERE s.is_active = 1 AND p.is_verified = 1
GROUP BY
    s.service_id, s.service_name, s.description, s.base_price,
    c.category_name, u.firstname, u.lastname, p.experience_years, ps.custom_price;
GO


-- View 3: vw_ClientLoyaltyOverview
CREATE VIEW vw_ClientLoyaltyOverview AS
SELECT
    u.user_id,
    u.firstname + ' ' + u.lastname AS ClientName,
    COUNT(DISTINCT r.reservation_id) AS CompletedReservations
FROM [User] u
LEFT JOIN Reservation r ON u.user_id = r.user_id AND r.status = 'completed'
WHERE u.role = 'client'
GROUP BY u.user_id, u.firstname, u.lastname;
GO


-- View 4: vw_AdminSystemOverview
CREATE VIEW vw_AdminSystemOverview AS
SELECT
    (SELECT COUNT(*) FROM [User]) AS TotalUsers,
    (SELECT COUNT(*) FROM [User] WHERE role = 'client') AS TotalClients,
    (SELECT COUNT(*) FROM [User] WHERE role = 'professional') AS TotalProfessionals,
    (SELECT COUNT(*) FROM Reservation WHERE status = 'pending') AS PendingReservations,
    (SELECT COUNT(*) FROM Reservation WHERE status = 'confirmed') AS ConfirmedReservations,
    (SELECT COUNT(*) FROM Reservation WHERE status = 'completed') AS CompletedReservations,
    (SELECT COUNT(*) FROM Reservation WHERE status = 'cancelled') AS CancelledReservations,
    (SELECT ISNULL(SUM(amount), 0) FROM Payment WHERE payment_status = 'paid') AS TotalRevenue,
    (SELECT AVG(CAST(rating AS DECIMAL(3,2))) FROM Review) AS OverallAverageRating;
GO

CREATE FUNCTION fn_GetProfessionalEarnings
(
    @ProfessionalID INT,
    @StartDate DATE,
    @EndDate DATE
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @TotalEarnings DECIMAL(12,2);

    SELECT @TotalEarnings = ISNULL(SUM(pay.amount), 0)
    FROM Payment pay
    JOIN Reservation r ON pay.reservation_id = r.reservation_id
    WHERE r.professional_id = @ProfessionalID
      AND pay.payment_status = 'paid'
      AND pay.transaction_date BETWEEN @StartDate AND @EndDate;

    RETURN @TotalEarnings;
END;
GO


CREATE FUNCTION fn_GetUserReservationCount
(
    @UserID INT,
    @Status NVARCHAR(20) = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;

    SELECT @Count = COUNT(*)
    FROM Reservation
    WHERE user_id = @UserID
      AND (@Status IS NULL OR status = @Status);

    RETURN @Count;
END;
GO


CREATE FUNCTION fn_GetUserLoyaltyTier
(
    @UserID INT
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @TierName NVARCHAR(20);
    DECLARE @CompletedCount INT;

    SELECT @CompletedCount = COUNT(*)
    FROM Reservation
    WHERE user_id = @UserID AND status = 'completed';

    SET @TierName = CASE
        WHEN @CompletedCount >= 30 THEN 'Platinum'
        WHEN @CompletedCount >= 15 THEN 'Gold'
        WHEN @CompletedCount >= 5  THEN 'Silver'
        ELSE 'Bronze'
    END;

    RETURN @TierName;
END;
GO

CREATE PROCEDURE sp_GetReservationsByDateRange
    @StartDate DATE,
    @EndDate DATE,
    @ProfessionalID INT = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SELECT
        r.reservation_id,
        r.[date],
        r.[time],
        r.status,
        uc.firstname + ' ' + uc.lastname AS ClientName,
        up.firstname + ' ' + up.lastname AS ProfessionalName
    FROM Reservation r
    JOIN [User] uc ON r.user_id = uc.user_id
    JOIN Professional p ON r.professional_id = p.professional_id
    JOIN [User] up ON p.user_id = up.user_id
    WHERE r.[date] BETWEEN @StartDate AND @EndDate
      AND (@ProfessionalID IS NULL OR r.professional_id = @ProfessionalID)
      AND (@Status IS NULL OR r.status = @Status)
    ORDER BY r.[date], r.[time];
END;
GO
-- Stored Procedure 2: sp_GetRevenueReport (ADAPTED)
CREATE PROCEDURE sp_GetRevenueReport
    @StartDate DATE,
    @EndDate DATE,
    @CategoryID INT = NULL
AS
BEGIN
    SELECT
        c.category_name,
        COUNT(DISTINCT r.reservation_id) AS TotalReservations,
        COUNT(DISTINCT r.user_id) AS UniqueClients,
        SUM(pay.amount) AS TotalRevenue,
        AVG(pay.amount) AS AverageReservationValue
    FROM Payment pay
    JOIN Reservation r ON pay.reservation_id = r.reservation_id
    JOIN Service s ON r.service_id = s.service_id
    JOIN Category c ON s.category_id = c.category_id
    WHERE pay.payment_status = 'paid'
      AND pay.transaction_date BETWEEN @StartDate AND @EndDate
      AND (@CategoryID IS NULL OR c.category_id = @CategoryID)
    GROUP BY c.category_name
    ORDER BY TotalRevenue DESC;
END;
GO


-- Stored Procedure 3: sp_GetServiceFrequencyAnalysis (ADAPTED)
CREATE PROCEDURE sp_GetServiceFrequencyAnalysis
    @StartDate DATE,
    @EndDate DATE,
    @CategoryID INT = NULL
AS
BEGIN
    SELECT
        s.service_id,
        s.service_name,
        c.category_name,
        COUNT(r.reservation_id) AS TimesBooked,
        COUNT(DISTINCT r.user_id) AS UniqueClients,
        SUM(CASE WHEN r.status = 'completed' THEN 1 ELSE 0 END) AS CompletedBookings,
        SUM(CASE WHEN r.status = 'cancelled' THEN 1 ELSE 0 END) AS CancelledBookings,
        CAST(
            SUM(CASE WHEN r.status = 'completed' THEN 1.0 ELSE 0 END) * 100.0 /
            NULLIF(COUNT(r.reservation_id), 0)
        AS DECIMAL(5,2)) AS CompletionRate
    FROM Service s
    JOIN Category c ON s.category_id = c.category_id
    JOIN Reservation r ON s.service_id = r.service_id
    WHERE r.[date] BETWEEN @StartDate AND @EndDate
      AND (@CategoryID IS NULL OR c.category_id = @CategoryID)
    GROUP BY s.service_id, s.service_name, c.category_name
    ORDER BY TimesBooked DESC;
END;
GO


-- Stored Procedure 4: sp_SafeSearchUsers (ADAPTED)
CREATE PROCEDURE sp_SafeSearchUsers
    @SearchName NVARCHAR(100) = NULL,
    @SearchEmail NVARCHAR(100) = NULL,
    @SearchRole NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX) =
    N'SELECT user_id, firstname, lastname, email, role, is_active, created_at
      FROM [User]
      WHERE 1 = 1';

    IF @SearchName IS NOT NULL
        SET @SQL += N' AND (firstname LIKE @Name OR lastname LIKE @Name)';

    IF @SearchEmail IS NOT NULL
        SET @SQL += N' AND email LIKE @Email';

    IF @SearchRole IS NOT NULL
        SET @SQL += N' AND role = @Role';

    SET @SQL += N' ORDER BY lastname, firstname';

    EXEC sp_executesql @SQL,
        N'@Name NVARCHAR(100), @Email NVARCHAR(100), @Role NVARCHAR(20)',
        @Name = '%' + @SearchName + '%',
        @Email = '%' + @SearchEmail + '%',
        @Role = @SearchRole;
END;
GO

-- Create roles
CREATE ROLE db_professional_role;
CREATE ROLE db_client_role;
CREATE ROLE db_admin_role;
GO

-- PROFESSIONAL permissions
GRANT SELECT ON [User] TO db_professional_role;
GRANT SELECT, UPDATE ON Professional TO db_professional_role;
GRANT SELECT, INSERT, UPDATE ON ProfessionalService TO db_professional_role;
GRANT SELECT, INSERT, UPDATE ON Availability TO db_professional_role;
GRANT SELECT, UPDATE ON Reservation TO db_professional_role;
GRANT SELECT ON Service TO db_professional_role;
GRANT SELECT ON Category TO db_professional_role;
GRANT SELECT ON Review TO db_professional_role;
GRANT SELECT ON vw_ProfessionalDashboard TO db_professional_role;
GRANT EXECUTE ON fn_GetProfessionalEarnings TO db_professional_role;
GO

-- CLIENT permissions
GRANT SELECT ON [User] TO db_client_role;
GRANT SELECT ON Professional TO db_client_role;
GRANT SELECT ON Service TO db_client_role;
GRANT SELECT ON Category TO db_client_role;
GRANT SELECT ON Availability TO db_client_role;
GRANT SELECT ON ProfessionalService TO db_client_role;
GRANT SELECT, INSERT, UPDATE ON Reservation TO db_client_role;
GRANT SELECT, INSERT ON Review TO db_client_role;
GRANT SELECT ON Payment TO db_client_role;
GRANT SELECT ON vw_ServiceCatalog TO db_client_role;
GRANT SELECT ON vw_ClientLoyaltyOverview TO db_client_role;
GRANT EXECUTE ON fn_GetUserReservationCount TO db_client_role;
GRANT EXECUTE ON fn_GetUserLoyaltyTier TO db_client_role;
GO

-- ADMIN permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON [User] TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Professional TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Category TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Service TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ProfessionalService TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Availability TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Reservation TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Review TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Payment TO db_admin_role;

GRANT SELECT ON vw_ProfessionalDashboard TO db_admin_role;
GRANT SELECT ON vw_ServiceCatalog TO db_admin_role;
GRANT SELECT ON vw_ClientLoyaltyOverview TO db_admin_role;
GRANT SELECT ON vw_AdminSystemOverview TO db_admin_role;

GRANT EXECUTE ON fn_GetProfessionalEarnings TO db_admin_role;
GRANT EXECUTE ON fn_GetUserReservationCount TO db_admin_role;
GRANT EXECUTE ON fn_GetUserLoyaltyTier TO db_admin_role;
GRANT EXECUTE ON sp_GetReservationsByDateRange TO db_admin_role;
GRANT EXECUTE ON sp_GetRevenueReport TO db_admin_role;
GRANT EXECUTE ON sp_GetServiceFrequencyAnalysis TO db_admin_role;
GRANT EXECUTE ON sp_SafeSearchUsers TO db_admin_role;
GO

-- Create SQL Server logins
CREATE LOGIN professional_user WITH PASSWORD = 'Prof@2025!';
CREATE LOGIN client_user WITH PASSWORD = 'Client@2025!';
CREATE LOGIN admin_user WITH PASSWORD = 'Admin@2025!';
GO

-- Create DB users
CREATE USER professional_user FOR LOGIN professional_user;
CREATE USER client_user FOR LOGIN client_user;
CREATE USER admin_user FOR LOGIN admin_user;
GO

-- Assign roles
ALTER ROLE db_professional_role ADD MEMBER professional_user;
ALTER ROLE db_client_role ADD MEMBER client_user;
ALTER ROLE db_admin_role ADD MEMBER admin_user;
GO
