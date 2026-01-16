# Professional Services Booking Platform

## Project Overview

This database project implements a comprehensive booking platform for professional services. The system allows clients to discover, book, and review services offered by various professionals (e.g., doctors, lawyers, consultants, plumbers, electricians, tutors, etc.). The platform manages the entire lifecycle from service listing to appointment completion and payment processing.

---

## Part 1: Database Design

### Entities (Minimum 5 Required)

#### 1. **Professionals**
Stores information about service providers.
| Column | Type | Constraints |
|--------|------|-------------|
| ProfessionalID | INT | PRIMARY KEY, IDENTITY |
| FirstName | NVARCHAR(50) | NOT NULL |
| LastName | NVARCHAR(50) | NOT NULL |
| Email | NVARCHAR(100) | UNIQUE, NOT NULL |
| Phone | PhoneNumber (UDDT) | NOT NULL |
| Specialization | NVARCHAR(100) | NOT NULL |
| CategoryID | INT | FOREIGN KEY |
| HourlyRate | DECIMAL(10,2) | NOT NULL |
| ExperienceYears | INT | CHECK >= 0 |
| Bio | NVARCHAR(500) | NULL |
| IsVerified | BIT | DEFAULT 0 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |

#### 2. **Clients**
Stores information about users who book services.
| Column | Type | Constraints |
|--------|------|-------------|
| ClientID | INT | PRIMARY KEY, IDENTITY |
| FirstName | NVARCHAR(50) | NOT NULL |
| LastName | NVARCHAR(50) | NOT NULL |
| Email | NVARCHAR(100) | UNIQUE, NOT NULL |
| Phone | PhoneNumber (UDDT) | NULL |
| Address | NVARCHAR(200) | NULL |
| DateOfBirth | DATE | NULL |
| CreatedAt | DATETIME | DEFAULT GETDATE() |

#### 3. **ServiceCategories**
Categories/types of professional services.
| Column | Type | Constraints |
|--------|------|-------------|
| CategoryID | INT | PRIMARY KEY, IDENTITY |
| CategoryName | NVARCHAR(100) | UNIQUE, NOT NULL |
| Description | NVARCHAR(500) | NULL |
| ParentCategoryID | INT | FOREIGN KEY (self-referencing) |

#### 4. **Services**
Specific services offered by professionals.
| Column | Type | Constraints |
|--------|------|-------------|
| ServiceID | INT | PRIMARY KEY, IDENTITY |
| ProfessionalID | INT | FOREIGN KEY, NOT NULL |
| ServiceName | NVARCHAR(100) | NOT NULL |
| Description | NVARCHAR(500) | NULL |
| DurationMinutes | INT | NOT NULL, CHECK > 0 |
| Price | DECIMAL(10,2) | NOT NULL |
| IsActive | BIT | DEFAULT 1 |

#### 5. **Bookings**
Appointment bookings between clients and professionals.
| Column | Type | Constraints |
|--------|------|-------------|
| BookingID | INT | PRIMARY KEY, IDENTITY |
| ClientID | INT | FOREIGN KEY, NOT NULL |
| ServiceID | INT | FOREIGN KEY, NOT NULL |
| ProfessionalID | INT | FOREIGN KEY, NOT NULL |
| BookingDate | DATETIME | NOT NULL |
| Status | NVARCHAR(20) | CHECK IN ('Pending', 'Confirmed', 'Completed', 'Cancelled') |
| Notes | NVARCHAR(500) | NULL |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| UpdatedAt | DATETIME | NULL |

#### 6. **Reviews**
Client reviews for completed services.
| Column | Type | Constraints |
|--------|------|-------------|
| ReviewID | INT | PRIMARY KEY, IDENTITY |
| BookingID | INT | FOREIGN KEY, UNIQUE, NOT NULL |
| Rating | INT | NOT NULL, CHECK BETWEEN 1 AND 5 |
| Comment | NVARCHAR(1000) | NULL |
| CreatedAt | DATETIME | DEFAULT GETDATE() |

#### 7. **Payments**
Payment records for bookings.
| Column | Type | Constraints |
|--------|------|-------------|
| PaymentID | INT | PRIMARY KEY, IDENTITY |
| BookingID | INT | FOREIGN KEY, UNIQUE, NOT NULL |
| Amount | DECIMAL(10,2) | NOT NULL |
| PaymentMethod | NVARCHAR(50) | NOT NULL |
| PaymentStatus | NVARCHAR(20) | CHECK IN ('Pending', 'Completed', 'Refunded', 'Failed') |
| TransactionDate | DATETIME | DEFAULT GETDATE() |

#### 8. **Availability**
Professional availability schedule.
| Column | Type | Constraints |
|--------|------|-------------|
| AvailabilityID | INT | PRIMARY KEY, IDENTITY |
| ProfessionalID | INT | FOREIGN KEY, NOT NULL |
| DayOfWeek | INT | CHECK BETWEEN 0 AND 6 |
| StartTime | TIME | NOT NULL |
| EndTime | TIME | NOT NULL |
| IsAvailable | BIT | DEFAULT 1 |

### Entity Relationships

```
ServiceCategories (1) ----< (M) Professionals
Professionals (1) ----< (M) Services
Professionals (1) ----< (M) Availability
Professionals (1) ----< (M) Bookings
Clients (1) ----< (M) Bookings
Services (1) ----< (M) Bookings
Bookings (1) ---- (1) Reviews
Bookings (1) ---- (1) Payments
ServiceCategories (1) ----< (M) ServiceCategories (self-referencing for subcategories)
```

### Normalization
The database follows 3NF (Third Normal Form):
- 1NF: All columns contain atomic values, no repeating groups
- 2NF: All non-key columns fully depend on the primary key
- 3NF: No transitive dependencies (e.g., Category information in separate table)

---

## User Groups and Permissions

### Group 1: **Professionals (db_professional_role)**
Service providers who manage their services and appointments.

**Permissions:**
- SELECT, INSERT, UPDATE on their own Services
- SELECT, UPDATE on Bookings (for their appointments)
- SELECT on Reviews (their own reviews)
- SELECT, INSERT, UPDATE on Availability (their schedule)
- SELECT on Clients (limited - only clients who booked with them)
- NO DELETE permissions on critical tables
- NO access to Payments details (privacy)

**Restrictions:**
- Cannot view other professionals' data
- Cannot modify booking status to 'Completed' without admin approval
- Cannot delete bookings, only cancel

### Group 2: **Clients (db_client_role)**
Users who book and review services.

**Permissions:**
- SELECT on Professionals, Services, ServiceCategories (public info)
- SELECT, INSERT on Bookings (their own)
- UPDATE on Bookings (only status to 'Cancelled')
- SELECT, INSERT on Reviews (for their completed bookings)
- SELECT on Payments (their own)
- SELECT on Availability (to view schedules)

**Restrictions:**
- Cannot view other clients' information
- Cannot modify bookings after confirmation (except cancellation)
- Cannot review without completed booking

### Group 3: **Administrators (db_admin_role)** [Optional but recommended]
System administrators with full access.

**Permissions:**
- Full SELECT, INSERT, UPDATE, DELETE on all tables
- Can verify professionals
- Can process refunds
- Access to all reports and analytics

---

## Part 2: Performance Optimization

### Tables Likely to Grow Large

1. **Bookings** - High volume of appointment records
2. **Reviews** - Accumulates over time
3. **Payments** - Financial transaction history

### Partitioning Strategy

**Bookings Table Partitioning:**
```sql
-- Partition by BookingDate (monthly partitions)
CREATE PARTITION FUNCTION pf_BookingDate (DATETIME)
AS RANGE RIGHT FOR VALUES 
('2025-01-01', '2025-02-01', '2025-03-01', ...);

CREATE PARTITION SCHEME ps_BookingDate
AS PARTITION pf_BookingDate ALL TO ([PRIMARY]);
```

### Indexing Strategy

```sql
-- Bookings indexes
CREATE NONCLUSTERED INDEX IX_Bookings_ClientID ON Bookings(ClientID);
CREATE NONCLUSTERED INDEX IX_Bookings_ProfessionalID ON Bookings(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Bookings_BookingDate ON Bookings(BookingDate);
CREATE NONCLUSTERED INDEX IX_Bookings_Status ON Bookings(Status);

-- Professionals indexes
CREATE NONCLUSTERED INDEX IX_Professionals_CategoryID ON Professionals(CategoryID);
CREATE NONCLUSTERED INDEX IX_Professionals_Specialization ON Professionals(Specialization);

-- Services indexes
CREATE NONCLUSTERED INDEX IX_Services_ProfessionalID ON Services(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Services_IsActive ON Services(IsActive) WHERE IsActive = 1;

-- Reviews indexes
CREATE NONCLUSTERED INDEX IX_Reviews_BookingID ON Reviews(BookingID);
```

---

## Part 3: Application Components

### Views (Minimum 2)

#### View 1: **vw_ProfessionalDashboard** (For Professionals)
Shows professional's booking summary, upcoming appointments, and average rating.
```sql
CREATE VIEW vw_ProfessionalDashboard AS
SELECT 
    p.ProfessionalID,
    p.FirstName + ' ' + p.LastName AS ProfessionalName,
    COUNT(b.BookingID) AS TotalBookings,
    SUM(CASE WHEN b.Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedBookings,
    AVG(CAST(r.Rating AS DECIMAL(3,2))) AS AverageRating,
    SUM(pay.Amount) AS TotalEarnings
FROM Professionals p
LEFT JOIN Bookings b ON p.ProfessionalID = b.ProfessionalID
LEFT JOIN Reviews r ON b.BookingID = r.BookingID
LEFT JOIN Payments pay ON b.BookingID = pay.BookingID AND pay.PaymentStatus = 'Completed'
GROUP BY p.ProfessionalID, p.FirstName, p.LastName;
```

#### View 2: **vw_ServiceCatalog** (For Clients)
Public view of available services with professional info (no sensitive data).
```sql
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
```

### Functions (Minimum 2)

#### Function 1: **fn_GetProfessionalEarnings** (For Professionals)
Calculate total earnings for a professional within a date range.
```sql
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
```

#### Function 2: **fn_GetClientBookingCount** (For Clients)
Get the number of bookings for a client by status.
```sql
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
```

### Stored Procedures (Minimum 2)

#### Stored Procedure 1: **sp_GetBookingsByDateRange**
Parametric search for bookings within a date range.
```sql
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
```

#### Stored Procedure 2: **sp_GetRevenueReport**
Generate revenue report by category and time period.
```sql
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
```

### User Defined Data Type (UDDT)

#### **PhoneNumber**
A custom data type for standardized phone number storage.
```sql
-- Create the UDDT
CREATE TYPE PhoneNumber FROM VARCHAR(20) NOT NULL;

-- Create a rule for validation
CREATE RULE rule_PhoneNumber AS
    @value LIKE '+[0-9]%' 
    AND LEN(@value) >= 10 
    AND LEN(@value) <= 20;

-- Bind the rule to the type
EXEC sp_bindrule 'rule_PhoneNumber', 'PhoneNumber';
```

### Triggers (Minimum 3)

#### Trigger 1: **trg_PreventDoubleBooking** (INSERT)
Prevents overlapping bookings for the same professional.
```sql
CREATE TRIGGER trg_PreventDoubleBooking
ON Bookings
INSTEAD OF INSERT
AS
BEGIN
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
```

#### Trigger 2: **trg_UpdateBookingTimestamp** (UPDATE)
Automatically updates the UpdatedAt timestamp when booking is modified.
```sql
CREATE TRIGGER trg_UpdateBookingTimestamp
ON Bookings
AFTER UPDATE
AS
BEGIN
    UPDATE Bookings
    SET UpdatedAt = GETDATE()
    FROM Bookings b
    INNER JOIN inserted i ON b.BookingID = i.BookingID;
END;
```

#### Trigger 3: **trg_ValidateReview** (INSERT)
Ensures reviews can only be created for completed bookings.
```sql
CREATE TRIGGER trg_ValidateReview
ON Reviews
INSTEAD OF INSERT
AS
BEGIN
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
```

---

## Project Roadmap

### Phase 1: Database Foundation
- [ ] Create SQL Server database
- [ ] Create all tables with proper constraints
- [ ] Implement User Defined Data Type (PhoneNumber)
- [ ] Create rules and bind to UDDT
- [ ] Populate each table with minimum 20 records
- [ ] Document relational schema (ER diagram)

### Phase 2: Security & Users
- [ ] Create database roles (db_professional_role, db_client_role, db_admin_role)
- [ ] Create sample users for each role
- [ ] Grant appropriate permissions to each role
- [ ] Test permission restrictions

### Phase 3: Performance Optimization
- [ ] Implement partitioning on Bookings table
- [ ] Create all necessary indexes
- [ ] Test query performance
- [ ] Document optimization decisions

### Phase 4: Database Objects
- [ ] Create View 1: vw_ProfessionalDashboard
- [ ] Create View 2: vw_ServiceCatalog
- [ ] Create Function 1: fn_GetProfessionalEarnings
- [ ] Create Function 2: fn_GetClientBookingCount
- [ ] Create Stored Procedure 1: sp_GetBookingsByDateRange
- [ ] Create Stored Procedure 2: sp_GetRevenueReport
- [ ] Create Trigger 1: trg_PreventDoubleBooking
- [ ] Create Trigger 2: trg_UpdateBookingTimestamp
- [ ] Create Trigger 3: trg_ValidateReview

### Phase 5: Web Application
- [ ] Set up web application framework
- [ ] Create Professional interface (login, dashboard, manage services)
- [ ] Create Client interface (browse services, book, review)
- [ ] Integrate Views for reports display
- [ ] Implement Functions for calculations
- [ ] Connect Stored Procedures for date-based queries
- [ ] Test data entry forms with Triggers

### Phase 6: Documentation & Delivery
- [ ] Write final documentation (PDF)
- [ ] Include all SQL scripts
- [ ] Prepare database backup
- [ ] Test presentation on personal computer

---

## Deliverables Checklist

1. **Documentation (PDF)**
   - Project description and topic explanation
   - Relational schema diagram
   - User groups and permissions documentation
   - Performance optimization explanation
   - All SQL object code

2. **Database**
   - .bak file or database export
   - All tables with 20+ records each

3. **SQL Scripts**
   - Table creation scripts
   - UDDT and Rules scripts
   - Index and Partition scripts
   - Views scripts
   - Functions scripts
   - Stored Procedures scripts
   - Triggers scripts
   - User/Role creation scripts
   - Sample data insertion scripts

4. **Web Application**
   - Source code
   - Instructions for running locally
