-- =============================================
-- Professional Services Booking Platform
-- Database Creation Script for SQL Server
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

-- 1. ServiceCategories Table (must be created first due to self-referencing FK)
CREATE TABLE ServiceCategories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) UNIQUE NOT NULL,
    Description NVARCHAR(500) NULL,
    ParentCategoryID INT NULL,
    CONSTRAINT FK_ServiceCategories_Parent FOREIGN KEY (ParentCategoryID)
        REFERENCES ServiceCategories(CategoryID)
);
GO

-- 2. Professionals Table
CREATE TABLE Professionals (
    ProfessionalID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Phone PhoneNumber NOT NULL,
    Specialization NVARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL,
    HourlyRate DECIMAL(10,2) NOT NULL,
    ExperienceYears INT CHECK (ExperienceYears >= 0),
    Bio NVARCHAR(500) NULL,
    IsVerified BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Professionals_Category FOREIGN KEY (CategoryID)
        REFERENCES ServiceCategories(CategoryID)
);
GO

-- 3. Clients Table
CREATE TABLE Clients (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(20) NULL,
    Address NVARCHAR(200) NULL,
    DateOfBirth DATE NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 4. Services Table
CREATE TABLE Services (
    ServiceID INT PRIMARY KEY IDENTITY(1,1),
    ProfessionalID INT NOT NULL,
    ServiceName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    DurationMinutes INT NOT NULL CHECK (DurationMinutes > 0),
    Price DECIMAL(10,2) NOT NULL,
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_Services_Professional FOREIGN KEY (ProfessionalID)
        REFERENCES Professionals(ProfessionalID)
);
GO

-- 5. Availability Table
CREATE TABLE Availability (
    AvailabilityID INT PRIMARY KEY IDENTITY(1,1),
    ProfessionalID INT NOT NULL,
    DayOfWeek INT CHECK (DayOfWeek BETWEEN 0 AND 6),
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    IsAvailable BIT DEFAULT 1,
    CONSTRAINT FK_Availability_Professional FOREIGN KEY (ProfessionalID)
        REFERENCES Professionals(ProfessionalID),
    CONSTRAINT CHK_Availability_TimeRange CHECK (EndTime > StartTime)
);
GO

-- 6. Bookings Table
CREATE TABLE Bookings (
    BookingID INT PRIMARY KEY IDENTITY(1,1),
    ClientID INT NOT NULL,
    ServiceID INT NOT NULL,
    ProfessionalID INT NOT NULL,
    BookingDate DATETIME NOT NULL,
    Status NVARCHAR(20) CHECK (Status IN ('Pending', 'Confirmed', 'Completed', 'Cancelled')),
    Notes NVARCHAR(500) NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME NULL,
    CONSTRAINT FK_Bookings_Client FOREIGN KEY (ClientID)
        REFERENCES Clients(ClientID),
    CONSTRAINT FK_Bookings_Service FOREIGN KEY (ServiceID)
        REFERENCES Services(ServiceID),
    CONSTRAINT FK_Bookings_Professional FOREIGN KEY (ProfessionalID)
        REFERENCES Professionals(ProfessionalID)
);
GO

-- 7. Reviews Table
CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    BookingID INT UNIQUE NOT NULL,
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(1000) NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Reviews_Booking FOREIGN KEY (BookingID)
        REFERENCES Bookings(BookingID)
);
GO

-- 8. Payments Table
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    BookingID INT UNIQUE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL,
    PaymentStatus NVARCHAR(20) CHECK (PaymentStatus IN ('Pending', 'Completed', 'Refunded', 'Failed')),
    TransactionDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Payments_Booking FOREIGN KEY (BookingID)
        REFERENCES Bookings(BookingID)
);
GO

-- =============================================
-- PART 3: Create Indexes for Performance
-- =============================================

-- Bookings indexes
CREATE NONCLUSTERED INDEX IX_Bookings_ClientID ON Bookings(ClientID);
CREATE NONCLUSTERED INDEX IX_Bookings_ProfessionalID ON Bookings(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Bookings_BookingDate ON Bookings(BookingDate);
CREATE NONCLUSTERED INDEX IX_Bookings_Status ON Bookings(Status);
GO

-- Professionals indexes
CREATE NONCLUSTERED INDEX IX_Professionals_CategoryID ON Professionals(CategoryID);
CREATE NONCLUSTERED INDEX IX_Professionals_Specialization ON Professionals(Specialization);
GO

-- Services indexes
CREATE NONCLUSTERED INDEX IX_Services_ProfessionalID ON Services(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Services_IsActive ON Services(IsActive) WHERE IsActive = 1;
GO

-- Reviews indexes
CREATE NONCLUSTERED INDEX IX_Reviews_BookingID ON Reviews(BookingID);
GO

-- =============================================
-- PART 4: Create Views
-- =============================================

-- View 1: vw_ProfessionalDashboard
CREATE VIEW vw_ProfessionalDashboard AS
SELECT
    p.ProfessionalID,
    p.FirstName + ' ' + p.LastName AS ProfessionalName,
    COUNT(b.BookingID) AS TotalBookings,
    SUM(CASE WHEN b.Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedBookings,
    AVG(CAST(r.Rating AS DECIMAL(3,2))) AS AverageRating,
    SUM(CASE WHEN pay.PaymentStatus = 'Completed' THEN pay.Amount ELSE 0 END) AS TotalEarnings
FROM Professionals p
LEFT JOIN Bookings b ON p.ProfessionalID = b.ProfessionalID
LEFT JOIN Reviews r ON b.BookingID = r.BookingID
LEFT JOIN Payments pay ON b.BookingID = pay.BookingID
GROUP BY p.ProfessionalID, p.FirstName, p.LastName;
GO

-- View 2: vw_ServiceCatalog
CREATE VIEW vw_ServiceCatalog AS
SELECT
    s.ServiceID,
    s.ServiceName,
    s.Description,
    s.Price,
    s.DurationMinutes,
    p.FirstName + ' ' + p.LastName AS ProfessionalName,
    p.Specialization,
    p.ExperienceYears,
    c.CategoryName,
    AVG(CAST(r.Rating AS DECIMAL(3,2))) AS AverageRating,
    COUNT(r.ReviewID) AS ReviewCount
FROM Services s
JOIN Professionals p ON s.ProfessionalID = p.ProfessionalID
JOIN ServiceCategories c ON p.CategoryID = c.CategoryID
LEFT JOIN Bookings b ON s.ServiceID = b.ServiceID
LEFT JOIN Reviews r ON b.BookingID = r.BookingID
WHERE s.IsActive = 1 AND p.IsVerified = 1
GROUP BY s.ServiceID, s.ServiceName, s.Description, s.Price, s.DurationMinutes,
         p.FirstName, p.LastName, p.Specialization, p.ExperienceYears, c.CategoryName;
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
    JOIN Bookings b ON pay.BookingID = b.BookingID
    WHERE b.ProfessionalID = @ProfessionalID
      AND pay.PaymentStatus = 'Completed'
      AND pay.TransactionDate BETWEEN @StartDate AND @EndDate;

    RETURN @TotalEarnings;
END;
GO

-- Function 2: fn_GetClientBookingCount
CREATE FUNCTION fn_GetClientBookingCount
(
    @ClientID INT,
    @Status NVARCHAR(20) = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;

    SELECT @Count = COUNT(*)
    FROM Bookings
    WHERE ClientID = @ClientID
      AND (@Status IS NULL OR Status = @Status);

    RETURN @Count;
END;
GO

-- =============================================
-- PART 6: Create Stored Procedures
-- =============================================

-- Stored Procedure 1: sp_GetBookingsByDateRange
CREATE PROCEDURE sp_GetBookingsByDateRange
    @StartDate DATETIME,
    @EndDate DATETIME,
    @ProfessionalID INT = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SELECT
        b.BookingID,
        b.BookingDate,
        b.Status,
        c.FirstName + ' ' + c.LastName AS ClientName,
        s.ServiceName,
        p.FirstName + ' ' + p.LastName AS ProfessionalName
    FROM Bookings b
    JOIN Clients c ON b.ClientID = c.ClientID
    JOIN Services s ON b.ServiceID = s.ServiceID
    JOIN Professionals p ON b.ProfessionalID = p.ProfessionalID
    WHERE b.BookingDate BETWEEN @StartDate AND @EndDate
      AND (@ProfessionalID IS NULL OR b.ProfessionalID = @ProfessionalID)
      AND (@Status IS NULL OR b.Status = @Status)
    ORDER BY b.BookingDate;
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
        sc.CategoryName,
        COUNT(DISTINCT b.BookingID) AS TotalBookings,
        COUNT(DISTINCT b.ClientID) AS UniqueClients,
        SUM(pay.Amount) AS TotalRevenue,
        AVG(pay.Amount) AS AverageBookingValue
    FROM Payments pay
    JOIN Bookings b ON pay.BookingID = b.BookingID
    JOIN Professionals p ON b.ProfessionalID = p.ProfessionalID
    JOIN ServiceCategories sc ON p.CategoryID = sc.CategoryID
    WHERE pay.PaymentStatus = 'Completed'
      AND pay.TransactionDate BETWEEN @StartDate AND @EndDate
      AND (@CategoryID IS NULL OR sc.CategoryID = @CategoryID)
    GROUP BY sc.CategoryName
    ORDER BY TotalRevenue DESC;
END;
GO

-- =============================================
-- PART 7: Create Triggers
-- =============================================

-- Trigger 1: trg_PreventDoubleBooking (INSERT)
CREATE TRIGGER trg_PreventDoubleBooking
ON Bookings
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Bookings b ON i.ProfessionalID = b.ProfessionalID
        JOIN Services s ON i.ServiceID = s.ServiceID
        WHERE b.Status NOT IN ('Cancelled')
          AND i.BookingDate < DATEADD(MINUTE,
              (SELECT DurationMinutes FROM Services WHERE ServiceID = b.ServiceID),
              b.BookingDate)
          AND DATEADD(MINUTE, s.DurationMinutes, i.BookingDate) > b.BookingDate
    )
    BEGIN
        RAISERROR('Booking conflicts with an existing appointment.', 16, 1);
        RETURN;
    END

    INSERT INTO Bookings (ClientID, ServiceID, ProfessionalID, BookingDate, Status, Notes, CreatedAt)
    SELECT ClientID, ServiceID, ProfessionalID, BookingDate, Status, Notes, GETDATE()
    FROM inserted;
END;
GO

-- Trigger 2: trg_UpdateBookingTimestamp (UPDATE)
CREATE TRIGGER trg_UpdateBookingTimestamp
ON Bookings
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Bookings
    SET UpdatedAt = GETDATE()
    FROM Bookings b
    INNER JOIN inserted i ON b.BookingID = i.BookingID;
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
        JOIN Bookings b ON i.BookingID = b.BookingID
        WHERE b.Status != 'Completed'
    )
    BEGIN
        RAISERROR('Reviews can only be submitted for completed bookings.', 16, 1);
        RETURN;
    END

    INSERT INTO Reviews (BookingID, Rating, Comment, CreatedAt)
    SELECT BookingID, Rating, Comment, GETDATE()
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

-- Can view and manage their own services
GRANT SELECT, INSERT, UPDATE ON Services TO db_professional_role;

-- Can view and update bookings (for their appointments)
GRANT SELECT, UPDATE ON Bookings TO db_professional_role;

-- Can view their own reviews
GRANT SELECT ON Reviews TO db_professional_role;

-- Can manage their availability
GRANT SELECT, INSERT, UPDATE ON Availability TO db_professional_role;

-- Can view clients (limited - those who booked with them)
GRANT SELECT ON Clients TO db_professional_role;

-- Can view service categories
GRANT SELECT ON ServiceCategories TO db_professional_role;

-- Can use the professional dashboard view
GRANT SELECT ON vw_ProfessionalDashboard TO db_professional_role;

-- Can use the earnings function
GRANT EXECUTE ON fn_GetProfessionalEarnings TO db_professional_role;
GO

-- =============================================
-- Permissions for db_client_role
-- =============================================

-- Can view public professional information
GRANT SELECT ON Professionals TO db_client_role;

-- Can view services and categories
GRANT SELECT ON Services TO db_client_role;
GRANT SELECT ON ServiceCategories TO db_client_role;

-- Can view availability (to check schedules)
GRANT SELECT ON Availability TO db_client_role;

-- Can view and create their own bookings
GRANT SELECT, INSERT ON Bookings TO db_client_role;
GRANT UPDATE ON Bookings TO db_client_role;

-- Can view and create reviews (for their completed bookings)
GRANT SELECT, INSERT ON Reviews TO db_client_role;

-- Can view their own payments
GRANT SELECT ON Payments TO db_client_role;

-- Can use the service catalog view
GRANT SELECT ON vw_ServiceCatalog TO db_client_role;

-- Can use the booking count function
GRANT EXECUTE ON fn_GetClientBookingCount TO db_client_role;
GO

-- =============================================
-- Permissions for db_admin_role
-- =============================================

-- Full access to all tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ServiceCategories TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Professionals TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Clients TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Services TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Availability TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Bookings TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Reviews TO db_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Payments TO db_admin_role;

-- Access to all views
GRANT SELECT ON vw_ProfessionalDashboard TO db_admin_role;
GRANT SELECT ON vw_ServiceCatalog TO db_admin_role;

-- Access to all functions and procedures
GRANT EXECUTE ON fn_GetProfessionalEarnings TO db_admin_role;
GRANT EXECUTE ON fn_GetClientBookingCount TO db_admin_role;
GRANT EXECUTE ON sp_GetBookingsByDateRange TO db_admin_role;
GRANT EXECUTE ON sp_GetRevenueReport TO db_admin_role;
GO

-- =============================================
-- PART 9: Create Sample Users (Optional)
-- =============================================

-- Note: Uncomment and modify these as needed for your environment
-- These create SQL Server logins and map them to database users

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
