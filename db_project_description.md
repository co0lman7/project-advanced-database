# Professional Services Booking Platform

## Project Overview

This database project implements a comprehensive booking platform for professional services. The system allows clients to discover, book, and review services offered by various professionals (e.g., doctors, lawyers, consultants, plumbers, electricians, tutors, etc.). The platform manages the entire lifecycle from service listing to appointment completion and payment processing.

---

## Part 1: Database Design

### Entities

#### 1. **Users**
Unified table for all platform users (clients, professionals, admins, etc.).
| Column | Type | Constraints |
|--------|------|-------------|
| UserID | INT | PRIMARY KEY, IDENTITY |
| FirstName | NVARCHAR(50) | NOT NULL |
| LastName | NVARCHAR(50) | NOT NULL |
| Email | NVARCHAR(100) | UNIQUE, NOT NULL |
| PasswordHash | NVARCHAR(255) | NOT NULL |
| Role | NVARCHAR(20) | NOT NULL, CHECK IN ('client', 'professional', 'admin', 'superadmin', 'guest') |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |

#### 2. **Professionals** (ISA subtype of Users)
Extended attributes for users with the 'professional' role. Uses ISA (generalization/specialization) relationship with Users.
| Column | Type | Constraints |
|--------|------|-------------|
| ProfessionalID | INT | PRIMARY KEY, FK → Users(UserID) |
| ExperienceYears | INT | CHECK >= 0 |
| Bio | NVARCHAR(500) | NULL |
| IsVerified | BIT | DEFAULT 0 |

#### 3. **Availability**
Professional availability schedule.
| Column | Type | Constraints |
|--------|------|-------------|
| AvailabilityID | INT | PRIMARY KEY, IDENTITY |
| ProfessionalID | INT | FOREIGN KEY → Professionals |
| Date | DATE | NOT NULL |
| StartTime | TIME | NOT NULL |
| EndTime | TIME | NOT NULL |
| Status | NVARCHAR(20) | DEFAULT 'available', CHECK IN ('available', 'unavailable', 'booked') |

#### 4. **Categories**
Service categories for organizing services.
| Column | Type | Constraints |
|--------|------|-------------|
| CategoryID | INT | PRIMARY KEY, IDENTITY |
| CategoryName | NVARCHAR(100) | UNIQUE, NOT NULL |
| Description | NVARCHAR(500) | NULL |
| IsActive | BIT | DEFAULT 1 |

#### 5. **Services**
Services available on the platform, linked to categories.
| Column | Type | Constraints |
|--------|------|-------------|
| ServiceID | INT | PRIMARY KEY, IDENTITY |
| CategoryID | INT | FOREIGN KEY → Categories, NOT NULL |
| ServiceName | NVARCHAR(100) | NOT NULL |
| Description | NVARCHAR(500) | NULL |
| BasePrice | DECIMAL(10,2) | NOT NULL, CHECK >= 0 |
| IsActive | BIT | DEFAULT 1 |

#### 6. **ProfessionalServices** (Junction Table)
M:N relationship between Professionals and Services (a professional offers services with optional custom pricing).
| Column | Type | Constraints |
|--------|------|-------------|
| ProfessionalID | INT | PK, FK → Professionals |
| ServiceID | INT | PK, FK → Services |
| CustomPrice | DECIMAL(10,2) | NULL, CHECK >= 0 |

#### 7. **Reservations**
Appointment reservations made by users with professionals.
| Column | Type | Constraints |
|--------|------|-------------|
| ReservationID | INT | PRIMARY KEY, IDENTITY |
| UserID | INT | FOREIGN KEY → Users, NOT NULL |
| ProfessionalID | INT | FOREIGN KEY → Professionals, NOT NULL |
| ReservationDate | DATE | NOT NULL |
| ReservationTime | TIME | NOT NULL |
| Status | NVARCHAR(20) | DEFAULT 'pending', CHECK IN ('pending', 'confirmed', 'completed', 'cancelled') |
| IsPayed | BIT | DEFAULT 0 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |

#### 8. **ReservationServices** (Junction Table)
M:N relationship between Reservations and Services (a reservation includes multiple services).
| Column | Type | Constraints |
|--------|------|-------------|
| ReservationID | INT | PK, FK → Reservations |
| ServiceID | INT | PK, FK → Services |

#### 9. **Payments**
Payment records for reservations (1:1 with Reservation).
| Column | Type | Constraints |
|--------|------|-------------|
| PaymentID | INT | PRIMARY KEY, IDENTITY |
| ReservationID | INT | FOREIGN KEY → Reservations, UNIQUE, NOT NULL |
| Amount | DECIMAL(10,2) | NOT NULL, CHECK >= 0 |
| Method | NVARCHAR(50) | NOT NULL, CHECK IN ('cash', 'card', 'online') |
| PaymentStatus | NVARCHAR(20) | DEFAULT 'pending', CHECK IN ('pending', 'completed', 'failed') |
| TransactionDate | DATETIME | DEFAULT GETDATE() |

#### 10. **Reviews**
Client reviews for completed reservations (0..1 with Reservation).
| Column | Type | Constraints |
|--------|------|-------------|
| ReviewID | INT | PRIMARY KEY, IDENTITY |
| ReservationID | INT | FOREIGN KEY → Reservations, UNIQUE, NOT NULL |
| Rating | INT | NOT NULL, CHECK BETWEEN 1 AND 5 |
| Comment | NVARCHAR(1000) | NULL |
| CreatedAt | DATETIME | DEFAULT GETDATE() |

### Entity Relationships

```
Users (1) ---- (0..1) Professionals          [ISA / generalization-specialization]
Professionals (1) ----< (N) Availability      [has]
Professionals (N) >----< (M) Services         [offers, via ProfessionalServices]
Services (N) >---- (1) Categories             [has]
Users (1) ----< (N) Reservations              [makes]
Professionals (1) ----< (N) Reservations      [assigned_to]
Reservations (N) >----< (M) Services          [includes, via ReservationServices]
Reservations (1) ---- (1) Payments            [is_payed]
Reservations (1) ---- (0..1) Reviews          [makes]
```

### Normalization
The database follows 3NF (Third Normal Form):
- **1NF**: All columns contain atomic values, no repeating groups
- **2NF**: All non-key columns fully depend on the primary key. Junction tables (ProfessionalServices, ReservationServices) eliminate partial dependencies
- **3NF**: No transitive dependencies. Category information is in a separate table. User base attributes are separated from Professional-specific attributes via ISA relationship. Service base pricing is separated from professional-specific custom pricing

---

## User Groups and Permissions

### Group 1: **Professionals (db_professional_role)**
Service providers who manage their services and appointments.

**Permissions:**
- SELECT on Users (to view client info for their reservations)
- SELECT, UPDATE on Professionals (their own profile)
- SELECT, INSERT, UPDATE on ProfessionalServices (manage their offered services)
- SELECT, INSERT, UPDATE on Availability (their schedule)
- SELECT, UPDATE on Reservations (for their appointments)
- SELECT on ReservationServices, Services, Categories, Reviews

**Restrictions:**
- Cannot view other professionals' data
- Cannot delete reservations, only update status
- No direct access to Payments

### Group 2: **Clients (db_client_role)**
Users who book and review services.

**Permissions:**
- SELECT on Users, Professionals, Services, Categories, Availability, ProfessionalServices
- SELECT, INSERT, UPDATE on Reservations (their own)
- SELECT, INSERT on ReservationServices (for their reservations)
- SELECT, INSERT on Reviews (for their completed reservations)
- SELECT on Payments (their own)

**Restrictions:**
- Cannot view other clients' information
- Cannot modify reservations after confirmation (except cancellation)
- Cannot review without completed reservation

### Group 3: **Administrators (db_admin_role)**
System administrators with full access.

**Permissions:**
- Full SELECT, INSERT, UPDATE, DELETE on all tables
- Access to all views, functions, and stored procedures

---

## Part 2: Performance Optimization

### Tables Likely to Grow Large

1. **Reservations** - High volume of appointment records
2. **ReservationServices** - Multiple services per reservation
3. **Payments** - Financial transaction history
4. **Reviews** - Accumulates over time

### Indexing Strategy

```sql
-- Users indexes
CREATE NONCLUSTERED INDEX IX_Users_Role ON Users(Role);
CREATE NONCLUSTERED INDEX IX_Users_Email ON Users(Email);

-- Reservations indexes
CREATE NONCLUSTERED INDEX IX_Reservations_UserID ON Reservations(UserID);
CREATE NONCLUSTERED INDEX IX_Reservations_ProfessionalID ON Reservations(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Reservations_Date ON Reservations(ReservationDate);
CREATE NONCLUSTERED INDEX IX_Reservations_Status ON Reservations(Status);

-- Services indexes
CREATE NONCLUSTERED INDEX IX_Services_CategoryID ON Services(CategoryID);
CREATE NONCLUSTERED INDEX IX_Services_IsActive ON Services(IsActive) WHERE IsActive = 1;

-- Availability indexes
CREATE NONCLUSTERED INDEX IX_Availability_ProfessionalID ON Availability(ProfessionalID);
CREATE NONCLUSTERED INDEX IX_Availability_Date ON Availability(Date);

-- Reviews indexes
CREATE NONCLUSTERED INDEX IX_Reviews_ReservationID ON Reviews(ReservationID);
```

---

## Part 3: Application Components

### Views (2)

#### View 1: **vw_ProfessionalDashboard** (For Professionals)
Shows professional's reservation summary, completed count, average rating, and total earnings.

#### View 2: **vw_ServiceCatalog** (For Clients)
Public view of available services with professional info, category, custom pricing, and ratings.

### Functions (2)

#### Function 1: **fn_GetProfessionalEarnings**
Calculate total earnings for a professional within a date range. Parameters: `@ProfessionalID`, `@StartDate`, `@EndDate`.

#### Function 2: **fn_GetUserReservationCount**
Get the number of reservations for a user, optionally filtered by status. Parameters: `@UserID`, `@Status` (optional).

### Stored Procedures (2)

#### Stored Procedure 1: **sp_GetReservationsByDateRange**
Parametric search for reservations within a date range, with optional filters for professional and status.

#### Stored Procedure 2: **sp_GetRevenueReport**
Generate revenue report by category and time period.

### User Defined Data Type (UDDT)

#### **PhoneNumber**
A custom data type for standardized phone number storage.
- Base type: `VARCHAR(20) NOT NULL`
- Rule: Must start with `+` followed by digits, length between 10 and 20

### Triggers (3)

#### Trigger 1: **trg_PreventDoubleReservation** (INSTEAD OF INSERT on Reservations)
Prevents overlapping reservations for the same professional at the same date and time.

#### Trigger 2: **trg_UpdateReservationPaymentStatus** (AFTER INSERT/UPDATE on Payments)
Automatically sets `IsPayed = 1` on the reservation when payment status becomes 'completed'.

#### Trigger 3: **trg_ValidateReview** (INSTEAD OF INSERT on Reviews)
Ensures reviews can only be created for completed reservations.

---

## Deliverables Checklist

1. **Documentation (PDF)**
   - Project description and topic explanation
   - Relational schema diagram (ER diagram)
   - User groups and permissions documentation
   - Performance optimization explanation
   - All SQL object code

2. **Database**
   - .bak file or database export
   - All tables with 20+ records each

3. **SQL Scripts**
   - Table creation scripts
   - UDDT and Rules scripts
   - Index scripts
   - Views scripts
   - Functions scripts
   - Stored Procedures scripts
   - Triggers scripts
   - User/Role creation scripts
   - Sample data insertion scripts

4. **Web Application**
   - Source code
   - Instructions for running locally
