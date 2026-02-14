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
-- PART 2: Create Tables
-- =============================================

-- 1. Users Table (unified - replaces separate Professionals/Clients)
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('client', 'professional', 'admin')),
    LoyaltyTier NVARCHAR(20) DEFAULT 'Bronze' CHECK (LoyaltyTier IN ('Bronze', 'Silver', 'Gold', 'Platinum')),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT CHK_Email_Format CHECK (Email LIKE '%_@_%.__%')
);
GO

-- 2. Professionals Table (ISA subtype of Users)
CREATE TABLE Professionals (
    ProfessionalID INT PRIMARY KEY,
    ExperienceYears INT CHECK (ExperienceYears >= 0),
    Bio NVARCHAR(500) NULL,
    IsVerified BIT DEFAULT 0,
    CONSTRAINT FK_Professional_User FOREIGN KEY (ProfessionalID)
        REFERENCES Users(UserID)
        ON DELETE CASCADE
);
GO

-- 3. Availability Table
CREATE TABLE Availability (
    AvailabilityID INT PRIMARY KEY IDENTITY(1,1),
    ProfessionalID INT NOT NULL,
    Date DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    Status NVARCHAR(20) DEFAULT 'available' CHECK (Status IN ('available', 'unavailable', 'booked')),
    CONSTRAINT FK_Availability_Professional FOREIGN KEY (ProfessionalID)
        REFERENCES Professionals(ProfessionalID)
        ON DELETE CASCADE,
    CONSTRAINT CHK_Availability_TimeRange CHECK (EndTime > StartTime)
);
GO

-- 4. Categories Table
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) UNIQUE NOT NULL,
    Description NVARCHAR(500) NULL,
    IsActive BIT DEFAULT 1
);
GO

-- 5. Services Table (linked to Categories)
CREATE TABLE Services (
    ServiceID INT PRIMARY KEY IDENTITY(1,1),
    CategoryID INT NOT NULL,
    ServiceName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    BasePrice DECIMAL(10,2) NOT NULL CHECK (BasePrice >= 0),
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_Service_Category FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
        ON DELETE NO ACTION
);
GO

-- 6. ProfessionalServices Junction Table (M:N - Professional offers Service)
CREATE TABLE ProfessionalServices (
    ProfessionalID INT NOT NULL,
    ServiceID INT NOT NULL,
    CustomPrice DECIMAL(10,2) NULL CHECK (CustomPrice >= 0),
    PRIMARY KEY (ProfessionalID, ServiceID),
    CONSTRAINT FK_PS_Professional FOREIGN KEY (ProfessionalID)
        REFERENCES Professionals(ProfessionalID)
        ON DELETE CASCADE,
    CONSTRAINT FK_PS_Service FOREIGN KEY (ServiceID)
        REFERENCES Services(ServiceID)
        ON DELETE CASCADE
);
GO

-- 7. Reservations Table (replaces Bookings)
CREATE TABLE Reservations (
    ReservationID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    ProfessionalID INT NOT NULL,
    ReservationDate DATE NOT NULL,
    ReservationTime TIME NOT NULL,
    Status NVARCHAR(20) DEFAULT 'pending' CHECK (Status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    IsPayed BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Reservation_User FOREIGN KEY (UserID)
        REFERENCES Users(UserID),
    CONSTRAINT FK_Reservation_Professional FOREIGN KEY (ProfessionalID)
        REFERENCES Professionals(ProfessionalID)
);
GO

-- 8. ReservationServices Junction Table (M:N - Reservation includes Service)
CREATE TABLE ReservationServices (
    ReservationID INT NOT NULL,
    ServiceID INT NOT NULL,
    PRIMARY KEY (ReservationID, ServiceID),
    CONSTRAINT FK_RS_Reservation FOREIGN KEY (ReservationID)
        REFERENCES Reservations(ReservationID)
        ON DELETE CASCADE,
    CONSTRAINT FK_RS_Service FOREIGN KEY (ServiceID)
        REFERENCES Services(ServiceID)
        ON DELETE CASCADE
);
GO

-- 9. Payments Table (1:1 with Reservation)
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    ReservationID INT UNIQUE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount >= 0),
    Method NVARCHAR(50) NOT NULL CHECK (Method IN ('cash', 'card', 'online')),
    PaymentStatus NVARCHAR(20) DEFAULT 'pending' CHECK (PaymentStatus IN ('pending', 'completed', 'failed')),
    TransactionDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Payment_Reservation FOREIGN KEY (ReservationID)
        REFERENCES Reservations(ReservationID)
        ON DELETE CASCADE
);
GO

-- 10. Reviews Table (0..1 with Reservation)
CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    ReservationID INT UNIQUE NOT NULL,
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(1000) NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Review_Reservation FOREIGN KEY (ReservationID)
        REFERENCES Reservations(ReservationID)
        ON DELETE CASCADE
);
GO

-- 11. UserLoyaltyBenefits Table (multivalue attribute - benefits per user)
CREATE TABLE UserLoyaltyBenefits (
    BenefitID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    BenefitName NVARCHAR(100) NOT NULL,
    BenefitDescription NVARCHAR(500) NULL,
    GrantedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_ULB_User FOREIGN KEY (UserID)
        REFERENCES Users(UserID)
        ON DELETE CASCADE
);
GO

-- =============================================
-- PART 3: Create Indexes for Performance
-- =============================================

-- Users indexes
CREATE NONCLUSTERED INDEX IX_Users_Role ON Users(Role);
CREATE NONCLUSTERED INDEX IX_Users_Email ON Users(Email);
GO

-- Reservations indexes
CREATE NONCLUSTERED INDEX IX_Reservations_UserID ON Reservations(UserID);
CREATE NONCLUSTERED INDEX IX_Reservations_ProfessionalID ON Reservations(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Reservations_Date ON Reservations(ReservationDate);
CREATE NONCLUSTERED INDEX IX_Reservations_Status ON Reservations(Status);
GO

-- Services indexes
CREATE NONCLUSTERED INDEX IX_Services_CategoryID ON Services(CategoryID);
CREATE NONCLUSTERED INDEX IX_Services_IsActive ON Services(IsActive) WHERE IsActive = 1;
GO

-- Availability indexes
CREATE NONCLUSTERED INDEX IX_Availability_ProfessionalID ON Availability(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Availability_Date ON Availability(Date);
GO

-- Reviews indexes
CREATE NONCLUSTERED INDEX IX_Reviews_ReservationID ON Reviews(ReservationID);
GO

-- UserLoyaltyBenefits indexes
CREATE NONCLUSTERED INDEX IX_ULB_UserID ON UserLoyaltyBenefits(UserID);
GO

-- =============================================
-- PART 4: Create Views
-- =============================================

-- View 1: vw_ProfessionalDashboard
CREATE VIEW vw_ProfessionalDashboard AS
SELECT
    p.ProfessionalID,
    u.FirstName + ' ' + u.LastName AS ProfessionalName,
    COUNT(DISTINCT r.ReservationID) AS TotalReservations,
    SUM(CASE WHEN r.Status = 'completed' THEN 1 ELSE 0 END) AS CompletedReservations,
    AVG(CAST(rev.Rating AS DECIMAL(3,2))) AS AverageRating,
    SUM(CASE WHEN pay.PaymentStatus = 'completed' THEN pay.Amount ELSE 0 END) AS TotalEarnings
FROM Professionals p
JOIN Users u ON p.ProfessionalID = u.UserID
LEFT JOIN Reservations r ON p.ProfessionalID = r.ProfessionalID
LEFT JOIN Reviews rev ON r.ReservationID = rev.ReservationID
LEFT JOIN Payments pay ON r.ReservationID = pay.ReservationID
GROUP BY p.ProfessionalID, u.FirstName, u.LastName;
GO

-- View 2: vw_ServiceCatalog
CREATE VIEW vw_ServiceCatalog AS
SELECT
    s.ServiceID,
    s.ServiceName,
    s.Description,
    s.BasePrice,
    c.CategoryName,
    u.FirstName + ' ' + u.LastName AS ProfessionalName,
    p.ExperienceYears,
    ps.CustomPrice,
    AVG(CAST(rev.Rating AS DECIMAL(3,2))) AS AverageRating,
    COUNT(DISTINCT rev.ReviewID) AS ReviewCount
FROM Services s
JOIN Categories c ON s.CategoryID = c.CategoryID
JOIN ProfessionalServices ps ON s.ServiceID = ps.ServiceID
JOIN Professionals p ON ps.ProfessionalID = p.ProfessionalID
JOIN Users u ON p.ProfessionalID = u.UserID
LEFT JOIN Reservations r ON r.ProfessionalID = p.ProfessionalID
LEFT JOIN ReservationServices rs ON r.ReservationID = rs.ReservationID AND rs.ServiceID = s.ServiceID
LEFT JOIN Reviews rev ON r.ReservationID = rev.ReservationID
WHERE s.IsActive = 1 AND p.IsVerified = 1
GROUP BY s.ServiceID, s.ServiceName, s.Description, s.BasePrice, c.CategoryName,
         u.FirstName, u.LastName, p.ExperienceYears, ps.CustomPrice;
GO

-- View 3: vw_ClientLoyaltyOverview
CREATE VIEW vw_ClientLoyaltyOverview AS
SELECT
    u.UserID,
    u.FirstName + ' ' + u.LastName AS ClientName,
    u.LoyaltyTier,
    COUNT(DISTINCT r.ReservationID) AS CompletedReservations,
    (
        SELECT STRING_AGG(ulb.BenefitName, ', ')
        FROM UserLoyaltyBenefits ulb
        WHERE ulb.UserID = u.UserID
    ) AS ActiveBenefits
FROM Users u
LEFT JOIN Reservations r ON u.UserID = r.UserID AND r.Status = 'completed'
WHERE u.Role = 'client'
GROUP BY u.UserID, u.FirstName, u.LastName, u.LoyaltyTier;
GO

-- =============================================
-- PART 5: Create Functions
-- =============================================

-- Function 1: fn_GetProfessionalEarnings
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

    SELECT @TotalEarnings = ISNULL(SUM(pay.Amount), 0)
    FROM Payments pay
    JOIN Reservations r ON pay.ReservationID = r.ReservationID
    WHERE r.ProfessionalID = @ProfessionalID
      AND pay.PaymentStatus = 'completed'
      AND pay.TransactionDate BETWEEN @StartDate AND @EndDate;

    RETURN @TotalEarnings;
END;
GO

-- Function 2: fn_GetUserReservationCount
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
    FROM Reservations
    WHERE UserID = @UserID
      AND (@Status IS NULL OR Status = @Status);

    RETURN @Count;
END;
GO

-- Function 3: fn_GetUserLoyaltyTier (calculates tier based on completed reservations)
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
    FROM Reservations
    WHERE UserID = @UserID AND Status = 'completed';

    SET @TierName = CASE
        WHEN @CompletedCount >= 30 THEN 'Platinum'
        WHEN @CompletedCount >= 15 THEN 'Gold'
        WHEN @CompletedCount >= 5  THEN 'Silver'
        ELSE 'Bronze'
    END;

    RETURN @TierName;
END;
GO

-- =============================================
-- PART 6: Create Stored Procedures
-- =============================================

-- Stored Procedure 1: sp_GetReservationsByDateRange
CREATE PROCEDURE sp_GetReservationsByDateRange
    @StartDate DATE,
    @EndDate DATE,
    @ProfessionalID INT = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SELECT
        r.ReservationID,
        r.ReservationDate,
        r.ReservationTime,
        r.Status,
        uc.FirstName + ' ' + uc.LastName AS ClientName,
        up.FirstName + ' ' + up.LastName AS ProfessionalName
    FROM Reservations r
    JOIN Users uc ON r.UserID = uc.UserID
    JOIN Users up ON r.ProfessionalID = up.UserID
    WHERE r.ReservationDate BETWEEN @StartDate AND @EndDate
      AND (@ProfessionalID IS NULL OR r.ProfessionalID = @ProfessionalID)
      AND (@Status IS NULL OR r.Status = @Status)
    ORDER BY r.ReservationDate, r.ReservationTime;
END;
GO

-- Stored Procedure 2: sp_GetRevenueReport
CREATE PROCEDURE sp_GetRevenueReport
    @StartDate DATE,
    @EndDate DATE,
    @CategoryID INT = NULL
AS
BEGIN
    SELECT
        c.CategoryName,
        COUNT(DISTINCT r.ReservationID) AS TotalReservations,
        COUNT(DISTINCT r.UserID) AS UniqueClients,
        SUM(pay.Amount) AS TotalRevenue,
        AVG(pay.Amount) AS AverageReservationValue
    FROM Payments pay
    JOIN Reservations r ON pay.ReservationID = r.ReservationID
    JOIN ReservationServices rs ON r.ReservationID = rs.ReservationID
    JOIN Services s ON rs.ServiceID = s.ServiceID
    JOIN Categories c ON s.CategoryID = c.CategoryID
    WHERE pay.PaymentStatus = 'completed'
      AND pay.TransactionDate BETWEEN @StartDate AND @EndDate
      AND (@CategoryID IS NULL OR c.CategoryID = @CategoryID)
    GROUP BY c.CategoryName
    ORDER BY TotalRevenue DESC;
END;
GO

-- Stored Procedure 3: sp_GetServiceFrequencyAnalysis
CREATE PROCEDURE sp_GetServiceFrequencyAnalysis
    @StartDate DATE,
    @EndDate DATE,
    @CategoryID INT = NULL
AS
BEGIN
    SELECT
        s.ServiceID,
        s.ServiceName,
        c.CategoryName,
        COUNT(rs.ReservationID) AS TimesBooked,
        COUNT(DISTINCT r.UserID) AS UniqueClients,
        SUM(CASE WHEN r.Status = 'completed' THEN 1 ELSE 0 END) AS CompletedBookings,
        SUM(CASE WHEN r.Status = 'cancelled' THEN 1 ELSE 0 END) AS CancelledBookings,
        CAST(
            SUM(CASE WHEN r.Status = 'completed' THEN 1.0 ELSE 0 END) /
            NULLIF(COUNT(rs.ReservationID), 0) * 100
        AS DECIMAL(5,2)) AS CompletionRate
    FROM Services s
    JOIN Categories c ON s.CategoryID = c.CategoryID
    JOIN ReservationServices rs ON s.ServiceID = rs.ServiceID
    JOIN Reservations r ON rs.ReservationID = r.ReservationID
    WHERE r.ReservationDate BETWEEN @StartDate AND @EndDate
      AND (@CategoryID IS NULL OR c.CategoryID = @CategoryID)
    GROUP BY s.ServiceID, s.ServiceName, c.CategoryName
    ORDER BY TimesBooked DESC;
END;
GO

-- =============================================
-- PART 7: Create Triggers
-- =============================================

-- Trigger 1: trg_PreventDoubleReservation (INSERT)
CREATE TRIGGER trg_PreventDoubleReservation
ON Reservations
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Reservations r ON i.ProfessionalID = r.ProfessionalID
        WHERE r.Status NOT IN ('cancelled')
          AND i.ReservationDate = r.ReservationDate
          AND i.ReservationTime = r.ReservationTime
    )
    BEGIN
        RAISERROR('Reservation conflicts with an existing appointment for this professional.', 16, 1);
        RETURN;
    END

    INSERT INTO Reservations (UserID, ProfessionalID, ReservationDate, ReservationTime, Status, IsPayed, CreatedAt)
    SELECT UserID, ProfessionalID, ReservationDate, ReservationTime,
           ISNULL(Status, 'pending'), ISNULL(IsPayed, 0), GETDATE()
    FROM inserted;
END;
GO

-- Trigger 2: trg_UpdateReservationPaymentStatus (UPDATE on Payments)
CREATE TRIGGER trg_UpdateReservationPaymentStatus
ON Payments
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Reservations
    SET IsPayed = 1
    FROM Reservations r
    INNER JOIN inserted i ON r.ReservationID = i.ReservationID
    WHERE i.PaymentStatus = 'completed';
END;
GO

-- Trigger 3: trg_ValidateReview (INSERT)
CREATE TRIGGER trg_ValidateReview
ON Reviews
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Reservations r ON i.ReservationID = r.ReservationID
        WHERE r.Status != 'completed'
    )
    BEGIN
        RAISERROR('Reviews can only be submitted for completed reservations.', 16, 1);
        RETURN;
    END

    INSERT INTO Reviews (ReservationID, Rating, Comment, CreatedAt)
    SELECT ReservationID, Rating, Comment, GETDATE()
    FROM inserted;
END;
GO

-- =============================================
-- PART 8: Create Database Roles and Permissions
-- =============================================

-- Create database roles
CREATE ROLE db_professional_role;
CREATE ROLE db_client_role;
CREATE ROLE db_admin_role;
GO

-- =============================================
-- Permissions for db_professional_role
-- =============================================

GRANT SELECT ON Users TO db_professional_role;
GRANT SELECT, UPDATE ON Professionals TO db_professional_role;
GRANT SELECT, INSERT, UPDATE ON ProfessionalServices TO db_professional_role;
GRANT SELECT, INSERT, UPDATE ON Availability TO db_professional_role;
GRANT SELECT, UPDATE ON Reservations TO db_professional_role;
GRANT SELECT ON ReservationServices TO db_professional_role;
GRANT SELECT ON Services TO db_professional_role;
GRANT SELECT ON Categories TO db_professional_role;
GRANT SELECT ON Reviews TO db_professional_role;
GRANT SELECT ON vw_ProfessionalDashboard TO db_professional_role;
GRANT EXECUTE ON fn_GetProfessionalEarnings TO db_professional_role;
GO

-- =============================================
-- Permissions for db_client_role
-- =============================================

GRANT SELECT ON Users TO db_client_role;
GRANT SELECT ON Professionals TO db_client_role;
GRANT SELECT ON Services TO db_client_role;
GRANT SELECT ON Categories TO db_client_role;
GRANT SELECT ON Availability TO db_client_role;
GRANT SELECT ON ProfessionalServices TO db_client_role;
GRANT SELECT, INSERT ON Reservations TO db_client_role;
GRANT UPDATE ON Reservations TO db_client_role;
GRANT SELECT, INSERT ON ReservationServices TO db_client_role;
GRANT SELECT, INSERT ON Reviews TO db_client_role;
GRANT SELECT ON Payments TO db_client_role;
GRANT SELECT ON vw_ServiceCatalog TO db_client_role;
GRANT SELECT ON vw_ClientLoyaltyOverview TO db_client_role;
GRANT EXECUTE ON fn_GetUserReservationCount TO db_client_role;
GRANT EXECUTE ON fn_GetUserLoyaltyTier TO db_client_role;
GRANT SELECT ON UserLoyaltyBenefits TO db_client_role;
GO

-- =============================================
-- Permissions for db_admin_role
-- =============================================

GRANT SELECT, INSERT, UPDATE, DELETE ON Users TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Professionals TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Categories TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Services TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ProfessionalServices TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Availability TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Reservations TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ReservationServices TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Reviews TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Payments TO db_admin_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON UserLoyaltyBenefits TO db_admin_role;

GRANT SELECT ON vw_ProfessionalDashboard TO db_admin_role;
GRANT SELECT ON vw_ServiceCatalog TO db_admin_role;
GRANT SELECT ON vw_ClientLoyaltyOverview TO db_admin_role;

GRANT EXECUTE ON fn_GetProfessionalEarnings TO db_admin_role;
GRANT EXECUTE ON fn_GetUserReservationCount TO db_admin_role;
GRANT EXECUTE ON fn_GetUserLoyaltyTier TO db_admin_role;
GRANT EXECUTE ON sp_GetReservationsByDateRange TO db_admin_role;
GRANT EXECUTE ON sp_GetRevenueReport TO db_admin_role;
GRANT EXECUTE ON sp_GetServiceFrequencyAnalysis TO db_admin_role;
GO

-- =============================================
-- PART 9: Create Sample Users (Optional)
-- =============================================

/*
-- Create logins at server level
CREATE LOGIN professional_user WITH PASSWORD = 'Prof@2025!';
CREATE LOGIN client_user WITH PASSWORD = 'Client@2025!';
CREATE LOGIN admin_user WITH PASSWORD = 'Admin@2025!';

-- Create database users and assign to roles
USE ProfessionalServicesBooking;

CREATE USER professional_user FOR LOGIN professional_user;
ALTER ROLE db_professional_role ADD MEMBER professional_user;

CREATE USER client_user FOR LOGIN client_user;
ALTER ROLE db_client_role ADD MEMBER client_user;

CREATE USER admin_user FOR LOGIN admin_user;
ALTER ROLE db_admin_role ADD MEMBER admin_user;
*/

PRINT 'Database ProfessionalServicesBooking created successfully!';
PRINT 'All tables, indexes, views, functions, stored procedures, triggers, and roles have been created.';
GO
