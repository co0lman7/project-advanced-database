-- =============================================
-- Test Cases for Views, Functions, and Stored Procedures
-- Run AFTER insert_data.sql
-- =============================================

USE ProfessionalServicesBooking;
GO

PRINT '============================================='
PRINT 'TEST CASES - Views, Functions, Stored Procedures'
PRINT '============================================='
PRINT ''

-- =============================================================================
-- VIEW 1: vw_ProfessionalDashboard
-- =============================================================================
PRINT '--- VIEW 1: vw_ProfessionalDashboard ---'
PRINT ''

-- Test 1.1: Retrieve all professionals dashboard data
PRINT 'Test 1.1: All professionals with their stats'
SELECT * FROM vw_ProfessionalDashboard
ORDER BY TotalEarnings DESC;
GO

-- Test 1.2: Filter for a specific professional (Luan Ahmeti - plumber, professional_id=1)
-- Expected: 4 total reservations (IDs: 1,16,21,35), all completed, earnings = 45+45+130+40 = 260
PRINT 'Test 1.2: Specific professional - Luan Ahmeti (plumber)'
SELECT * FROM vw_ProfessionalDashboard
WHERE professional_id = 1;
GO

-- Test 1.3: Professionals with highest average rating
PRINT 'Test 1.3: Top 5 professionals by average rating'
SELECT TOP 5 ProfessionalName, AverageRating, TotalReservations, TotalEarnings
FROM vw_ProfessionalDashboard
WHERE AverageRating IS NOT NULL
ORDER BY AverageRating DESC, TotalEarnings DESC;
GO

-- Test 1.4: Professionals with zero reservations (if any)
PRINT 'Test 1.4: Professionals with no reservations'
SELECT ProfessionalName, TotalReservations
FROM vw_ProfessionalDashboard
WHERE TotalReservations = 0;
GO

-- =============================================================================
-- VIEW 2: vw_ServiceCatalog
-- =============================================================================
PRINT '--- VIEW 2: vw_ServiceCatalog ---'
PRINT ''

-- Test 2.1: Full service catalog
PRINT 'Test 2.1: Complete service catalog'
SELECT * FROM vw_ServiceCatalog
ORDER BY category_name, service_name;
GO

-- Test 2.2: Services in Plumbing category
PRINT 'Test 2.2: Plumbing services only'
SELECT service_name, ProfessionalName, base_price, custom_price, AverageRating, ReviewCount
FROM vw_ServiceCatalog
WHERE category_name = 'Plumbing'
ORDER BY custom_price;
GO

-- Test 2.3: Services with reviews (ReviewCount > 0)
PRINT 'Test 2.3: Services that have been reviewed'
SELECT service_name, ProfessionalName, AverageRating, ReviewCount
FROM vw_ServiceCatalog
WHERE ReviewCount > 0
ORDER BY ReviewCount DESC;
GO

-- Test 2.4: Most expensive services by custom price
PRINT 'Test 2.4: Top 5 most expensive services'
SELECT TOP 5 service_name, category_name, ProfessionalName, custom_price
FROM vw_ServiceCatalog
ORDER BY custom_price DESC;
GO

-- =============================================================================
-- VIEW 3: vw_ClientLoyaltyOverview
-- =============================================================================
PRINT '--- VIEW 3: vw_ClientLoyaltyOverview ---'
PRINT ''

-- Test 3.1: All clients with completed reservation counts
-- Expected: User 1 (Arben) should have the most completed reservations (8)
PRINT 'Test 3.1: All clients ordered by completed reservations'
SELECT * FROM vw_ClientLoyaltyOverview
ORDER BY CompletedReservations DESC;
GO

-- Test 3.2: Clients with no completed reservations
PRINT 'Test 3.2: Clients with zero completed reservations'
SELECT * FROM vw_ClientLoyaltyOverview
WHERE CompletedReservations = 0;
GO

-- Test 3.3: Specific client - Arben Krasniqi (user_id=1, should have 8 completed)
PRINT 'Test 3.3: Arben Krasniqi loyalty overview'
SELECT * FROM vw_ClientLoyaltyOverview
WHERE user_id = 1;
GO

-- =============================================================================
-- VIEW 4: vw_AdminSystemOverview
-- =============================================================================
PRINT '--- VIEW 4: vw_AdminSystemOverview ---'
PRINT ''

-- Test 4.1: Full system overview
-- Expected: 30 users, 10 clients, 15 professionals
--           Reservations: 8 pending, 3 confirmed, 27 completed, 2 cancelled
--           Total revenue from paid payments, average rating ~4.5
PRINT 'Test 4.1: Complete system overview'
SELECT * FROM vw_AdminSystemOverview;
GO

-- Test 4.2: Verify user counts match
PRINT 'Test 4.2: Verify user count breakdown'
SELECT
    (SELECT TotalUsers FROM vw_AdminSystemOverview) AS ViewTotal,
    (SELECT COUNT(*) FROM [User]) AS ActualTotal,
    CASE
        WHEN (SELECT TotalUsers FROM vw_AdminSystemOverview) = (SELECT COUNT(*) FROM [User])
        THEN 'PASS' ELSE 'FAIL'
    END AS Result;
GO

-- Test 4.3: Verify reservation status counts add up
PRINT 'Test 4.3: Verify reservation counts add up to total'
SELECT
    PendingReservations + ConfirmedReservations + CompletedReservations + CancelledReservations AS SumFromView,
    (SELECT COUNT(*) FROM Reservation) AS ActualTotal,
    CASE
        WHEN PendingReservations + ConfirmedReservations + CompletedReservations + CancelledReservations
             = (SELECT COUNT(*) FROM Reservation)
        THEN 'PASS' ELSE 'FAIL'
    END AS Result
FROM vw_AdminSystemOverview;
GO

-- =============================================================================
-- FUNCTION 1: fn_GetProfessionalEarnings
-- =============================================================================
PRINT '--- FUNCTION 1: fn_GetProfessionalEarnings ---'
PRINT ''

-- Test 5.1: Earnings for Luan Ahmeti (prof 1) in Feb-Mar 2025
-- Reservations 1 (paid 45.00) and 16 (paid 45.00) fall in this range
PRINT 'Test 5.1: Luan Ahmeti earnings Feb-May 2025'
SELECT dbo.fn_GetProfessionalEarnings(1, '2025-02-01', '2025-05-31') AS Earnings_Prof1;
GO

-- Test 5.2: Earnings for Mimoza Beka (prof 2) full year 2025
PRINT 'Test 5.2: Mimoza Beka earnings full year 2025'
SELECT dbo.fn_GetProfessionalEarnings(2, '2025-01-01', '2025-12-31') AS Earnings_Prof2;
GO

-- Test 5.3: Earnings for a professional with no paid reservations in range
PRINT 'Test 5.3: Professional 1 earnings in 2026 (should be 0)'
SELECT dbo.fn_GetProfessionalEarnings(1, '2026-01-01', '2026-12-31') AS Earnings_None;
GO

-- Test 5.4: Earnings for all professionals in Q1 2025
PRINT 'Test 5.4: All professionals earnings Q1 2025'
SELECT
    p.professional_id,
    u.firstname + ' ' + u.lastname AS ProfessionalName,
    dbo.fn_GetProfessionalEarnings(p.professional_id, '2025-01-01', '2025-03-31') AS Q1_Earnings
FROM Professional p
JOIN [User] u ON p.user_id = u.user_id
ORDER BY Q1_Earnings DESC;
GO

-- =============================================================================
-- FUNCTION 2: fn_GetUserReservationCount
-- =============================================================================
PRINT '--- FUNCTION 2: fn_GetUserReservationCount ---'
PRINT ''

-- Test 6.1: Total reservations for Arben (user 1) - should be 8+ across all statuses
PRINT 'Test 6.1: Arben total reservations (all statuses)'
SELECT dbo.fn_GetUserReservationCount(1, NULL) AS TotalReservations_Arben;
GO

-- Test 6.2: Only completed reservations for Arben (user 1)
PRINT 'Test 6.2: Arben completed reservations only'
SELECT dbo.fn_GetUserReservationCount(1, 'completed') AS CompletedReservations_Arben;
GO

-- Test 6.3: Pending reservations for Kushtrim (user 10)
PRINT 'Test 6.3: Kushtrim pending reservations'
SELECT dbo.fn_GetUserReservationCount(10, 'pending') AS PendingReservations_Kushtrim;
GO

-- Test 6.4: Cancelled reservations for Jeta (user 9)
PRINT 'Test 6.4: Jeta cancelled reservations'
SELECT dbo.fn_GetUserReservationCount(9, 'cancelled') AS CancelledReservations_Jeta;
GO

-- Test 6.5: User with no reservations (admin user 26)
PRINT 'Test 6.5: Admin user with no reservations'
SELECT dbo.fn_GetUserReservationCount(26, NULL) AS Reservations_Admin;
GO

-- =============================================================================
-- FUNCTION 3: fn_GetUserLoyaltyTier
-- =============================================================================
PRINT '--- FUNCTION 3: fn_GetUserLoyaltyTier ---'
PRINT ''

-- Test 7.1: Arben (user 1) has 8 completed -> should be Silver (>=5)
PRINT 'Test 7.1: Arben loyalty tier (8 completed = Silver)'
SELECT dbo.fn_GetUserLoyaltyTier(1) AS LoyaltyTier_Arben;
GO

-- Test 7.2: User with few completed -> should be Bronze
PRINT 'Test 7.2: Edona loyalty tier (1 completed = Bronze)'
SELECT dbo.fn_GetUserLoyaltyTier(4) AS LoyaltyTier_Edona;
GO

-- Test 7.3: Admin user with 0 completed -> Bronze
PRINT 'Test 7.3: Admin user loyalty tier (0 completed = Bronze)'
SELECT dbo.fn_GetUserLoyaltyTier(26) AS LoyaltyTier_Admin;
GO

-- Test 7.4: All clients with their loyalty tiers
PRINT 'Test 7.4: All clients with loyalty tiers'
SELECT
    u.user_id,
    u.firstname + ' ' + u.lastname AS ClientName,
    dbo.fn_GetUserReservationCount(u.user_id, 'completed') AS CompletedCount,
    dbo.fn_GetUserLoyaltyTier(u.user_id) AS LoyaltyTier
FROM [User] u
WHERE u.role = 'client'
ORDER BY CompletedCount DESC;
GO

-- =============================================================================
-- STORED PROCEDURE 1: sp_GetReservationsByDateRange
-- =============================================================================
PRINT '--- SP 1: sp_GetReservationsByDateRange ---'
PRINT ''

-- Test 8.1: All reservations in February 2025
PRINT 'Test 8.1: All reservations in Feb 2025'
EXEC sp_GetReservationsByDateRange
    @StartDate = '2025-02-01',
    @EndDate = '2025-02-28';
GO

-- Test 8.2: Reservations for professional 1 (Luan - plumber) in 2025
PRINT 'Test 8.2: Luan Ahmeti reservations in 2025'
EXEC sp_GetReservationsByDateRange
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31',
    @ProfessionalID = 1;
GO

-- Test 8.3: Only completed reservations in Q2 2025
PRINT 'Test 8.3: Completed reservations Q2 2025'
EXEC sp_GetReservationsByDateRange
    @StartDate = '2025-04-01',
    @EndDate = '2025-06-30',
    @Status = 'completed';
GO

-- Test 8.4: Pending reservations in 2026
PRINT 'Test 8.4: Pending reservations in 2026'
EXEC sp_GetReservationsByDateRange
    @StartDate = '2026-01-01',
    @EndDate = '2026-12-31',
    @Status = 'pending';
GO

-- Test 8.5: Date range with no reservations
PRINT 'Test 8.5: Empty date range (should return 0 rows)'
EXEC sp_GetReservationsByDateRange
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31';
GO

-- Test 8.6: Combined filters - specific professional + status
PRINT 'Test 8.6: Professional 4 confirmed reservations in Jul 2025'
EXEC sp_GetReservationsByDateRange
    @StartDate = '2025-07-01',
    @EndDate = '2025-07-31',
    @ProfessionalID = 4,
    @Status = 'confirmed';
GO

-- =============================================================================
-- STORED PROCEDURE 2: sp_GetRevenueReport
-- =============================================================================
PRINT '--- SP 2: sp_GetRevenueReport ---'
PRINT ''

-- Test 9.1: Revenue report for full year 2025
PRINT 'Test 9.1: Revenue report full year 2025'
EXEC sp_GetRevenueReport
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31';
GO

-- Test 9.2: Revenue for Q1 2025 only
PRINT 'Test 9.2: Revenue report Q1 2025'
EXEC sp_GetRevenueReport
    @StartDate = '2025-01-01',
    @EndDate = '2025-03-31';
GO

-- Test 9.3: Revenue filtered by Plumbing category (category_id=1)
PRINT 'Test 9.3: Revenue for Plumbing category only'
EXEC sp_GetRevenueReport
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31',
    @CategoryID = 1;
GO

-- Test 9.4: Revenue for Electrical category (category_id=2)
PRINT 'Test 9.4: Revenue for Electrical category only'
EXEC sp_GetRevenueReport
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31',
    @CategoryID = 2;
GO

-- Test 9.5: Revenue in a range with no paid payments
PRINT 'Test 9.5: Revenue in 2026 (no paid payments expected)'
EXEC sp_GetRevenueReport
    @StartDate = '2026-01-01',
    @EndDate = '2026-12-31';
GO

-- =============================================================================
-- STORED PROCEDURE 3: sp_GetServiceFrequencyAnalysis
-- =============================================================================
PRINT '--- SP 3: sp_GetServiceFrequencyAnalysis ---'
PRINT ''

-- Test 10.1: Service frequency for full year 2025
PRINT 'Test 10.1: Service frequency full year 2025'
EXEC sp_GetServiceFrequencyAnalysis
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31';
GO

-- Test 10.2: Service frequency for Cleaning category (category_id=3)
PRINT 'Test 10.2: Cleaning services frequency'
EXEC sp_GetServiceFrequencyAnalysis
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31',
    @CategoryID = 3;
GO

-- Test 10.3: Service frequency Q1 2025
PRINT 'Test 10.3: Service frequency Q1 2025'
EXEC sp_GetServiceFrequencyAnalysis
    @StartDate = '2025-01-01',
    @EndDate = '2025-03-31';
GO

-- Test 10.4: Service frequency for Moving & Transport (category_id=8)
PRINT 'Test 10.4: Moving & Transport frequency'
EXEC sp_GetServiceFrequencyAnalysis
    @StartDate = '2025-01-01',
    @EndDate = '2025-12-31',
    @CategoryID = 8;
GO

-- =============================================================================
-- STORED PROCEDURE 4: sp_SafeSearchUsers
-- =============================================================================
PRINT '--- SP 4: sp_SafeSearchUsers ---'
PRINT ''

-- Test 11.1: Search by name
PRINT 'Test 11.1: Search users by name "Arben"'
EXEC sp_SafeSearchUsers @SearchName = 'Arben';
GO

-- Test 11.2: Search by partial last name
PRINT 'Test 11.2: Search users by partial name "sh" (Gjeloshi, Jashari, Shala)'
EXEC sp_SafeSearchUsers @SearchName = 'sh';
GO

-- Test 11.3: Search by email
PRINT 'Test 11.3: Search by email "luan"'
EXEC sp_SafeSearchUsers @SearchEmail = 'luan';
GO

-- Test 11.4: Search by role
PRINT 'Test 11.4: Search all admins'
EXEC sp_SafeSearchUsers @SearchRole = 'admin';
GO

-- Test 11.5: Combined search - professionals with name containing "a"
PRINT 'Test 11.5: Professionals with "a" in name'
EXEC sp_SafeSearchUsers @SearchName = 'a', @SearchRole = 'professional';
GO

-- Test 11.6: Search with no results
PRINT 'Test 11.6: Search for non-existent name (should return 0 rows)'
EXEC sp_SafeSearchUsers @SearchName = 'XYZ_NoMatch';
GO

-- Test 11.7: SQL injection attempt (should be safe due to parameterized query)
PRINT 'Test 11.7: SQL injection attempt (should return 0 rows safely)'
EXEC sp_SafeSearchUsers @SearchName = '''; DROP TABLE [User]; --';
GO

PRINT ''
PRINT '============================================='
PRINT 'ALL TEST CASES COMPLETED'
PRINT '============================================='
GO
