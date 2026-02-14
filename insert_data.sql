-- =============================================
-- Inline Data Insertion for ProfessionalServicesBooking
-- Run AFTER Databaza...sherbime.sql
-- =============================================

USE ProfessionalServicesBooking;
GO

-- =============================================
-- Temporarily disable triggers for data insertion
-- =============================================
DISABLE TRIGGER trg_PreventDoubleReservation ON Reservation;
DISABLE TRIGGER trg_ValidateReview ON Review;
DISABLE TRIGGER trg_UpdateReservationPaymentStatus ON Payment;
DISABLE TRIGGER trg_PreventCompletedReservationEdit ON Reservation;
DISABLE TRIGGER trg_LogReservationDeletion ON Reservation;
GO

-- =============================================
-- 1. Users (30 rows: 10 clients, 15 professionals, 5 admins)
-- =============================================
SET IDENTITY_INSERT [User] ON;

INSERT INTO [User] (user_id, firstname, lastname, email, phone, password_hash, role, is_active, created_at) VALUES
(1,  N'Arben',    N'Krasniqi', N'arben.krasniqi@email.com',  '+38344123456', '9cfd354fadf6b374f0c688f074638df3585bccfa975b2c97089e0c5a055e530d', N'client', 1, '2025-01-10 09:00:00'),
(2,  N'Blerta',   N'Gashi',    N'blerta.gashi@email.com',    '+38345234567', '80a5e030cf35a88be52c39b5cdb7add73fa5a2ef4f089d8feb540b0e66382786', N'client', 1, '2025-01-15 10:30:00'),
(3,  N'Driton',   N'Berisha',  N'driton.berisha@email.com',  '+38349345678', 'ae951b375044e4ee87212f158dc23e037ea52c17f89e206b8889da1e39530eb5', N'client', 1, '2025-01-22 08:45:00'),
(4,  N'Edona',    N'Hoxha',    N'edona.hoxha@email.com',     '+38344456789', '816a9c7edbc6277db4900c5e1a05f916f4bc4fc3ce1c7e0de9c5277bfd9ab692', N'client', 1, '2025-02-03 14:00:00'),
(5,  N'Fatos',    N'Mustafa',  N'fatos.mustafa@email.com',   '+38345567890', 'bdab28edf1e4da04986dc0c67ef6d2151e366def6128bf5b8c05db6e12e134f0', N'client', 1, '2025-02-14 11:20:00'),
(6,  N'Gresa',    N'Bytyqi',   N'gresa.bytyqi@email.com',    '+38349678901', 'f2088f72c4fe70e97e0f26f7f1a4a4e685589348f679419b1aeba37f0f94ec80', N'client', 1, '2025-02-28 16:00:00'),
(7,  N'Hana',     N'Morina',   N'hana.morina@email.com',     '+38344789012', 'e9bd6dbdb84dc6734f86509b633d46675169400e39e08552b615f7959409dd9b', N'client', 1, '2025-03-05 09:15:00'),
(8,  N'Ilir',     N'Shala',    N'ilir.shala@email.com',      '+38345890123', '1585bc837c5e3edd1c7541fc6d17d2058ef4da33fb239fa8817056a67a9f46b3', N'client', 1, '2025-03-12 13:30:00'),
(9,  N'Jeta',     N'Osmani',   N'jeta.osmani@email.com',     '+38349901234', '31ebadc7b9c93df6817538d9c1e3c6b196644eb1acce0b3657e15b365422f0ee', N'client', 1, '2025-03-20 10:00:00'),
(10, N'Kushtrim', N'Rama',     N'kushtrim.rama@email.com',   '+38344012345', '3ebddcd968d77b459afe7cd4f0412476f1799ae92c75afbcfa7f07f08d96f9d4', N'client', 1, '2025-04-01 12:00:00'),
(11, N'Luan',     N'Ahmeti',   N'luan.ahmeti@email.com',     '+38345147258', '4474bca3800ce0af4c59d5c53c21606f17b8a0cfceacc02edad6128374db2862', N'professional', 1, '2025-01-05 08:00:00'),
(12, N'Mimoza',   N'Beka',     N'mimoza.beka@email.com',     '+38349258369', '398818c4b6a71c6833d19f0faa6ea6941eed5ba48cd0ccae2520c480d02668db', N'professional', 1, '2025-01-06 08:30:00'),
(13, N'Naim',     N'Cakaj',    N'naim.cakaj@email.com',      '+38344369471', 'baa2f5af04655a83352b5eba1088e9df4abded31dc1736e29bed45b5d4db6c85', N'professional', 1, '2025-01-07 09:00:00'),
(14, N'Orhan',    N'Dervishi', N'orhan.dervishi@email.com',  '+38345471582', '4b64ff5ad6d9946f2fe124075806dc0a1264aa4a66289d7ee30ed76157be39a0', N'professional', 1, '2025-01-08 09:30:00'),
(15, N'Pranvera', N'Elezi',    N'pranvera.elezi@email.com',  '+38349582693', 'f1c3f57cb5ccbb7ae6a0bd7f13756aca9ef904eb3ab55751fd20f811214742cd', N'professional', 1, '2025-01-09 10:00:00'),
(16, N'Qendrim',  N'Fetahu',   N'qendrim.fetahu@email.com', '+38344693714', 'ca33ffbb9534d5a576a170d1cfd0b270bb23a0749199517fb6b3ad705a933987', N'professional', 1, '2025-01-10 10:30:00'),
(17, N'Rineta',   N'Gjeloshi', N'rineta.gjeloshi@email.com', '+38345714825', '56dae67d057c05d1323692feee3041899c0cf83249d654832afe76eb6c17be0e', N'professional', 1, '2025-01-11 11:00:00'),
(18, N'Samir',    N'Halimi',   N'samir.halimi@email.com',    '+38349825936', '7679f798f1006d88e37c1a2e04000c18c8b9e11cb2afd6135ccda253315740b3', N'professional', 1, '2025-01-12 11:30:00'),
(19, N'Teuta',    N'Islami',   N'teuta.islami@email.com',    '+38344936147', '1c7cf1234a46845bf92f91a35cea43db59c52f7f3cb3430d3647b86acbfc213e', N'professional', 1, '2025-01-13 12:00:00'),
(20, N'Valon',    N'Jashari',  N'valon.jashari@email.com',   '+38345147369', 'ea3c9ce404706da228bce536faabd4f258c62b13d322be1b75e79c664628df0a', N'professional', 1, '2025-01-14 12:30:00'),
(21, N'Xhevat',   N'Kelmendi', N'xhevat.kelmendi@email.com','+38349258471', 'c0de9bc8824a1ac11010c5965a10392fe6d3c685fa37b98f67678bdced075606', N'professional', 1, '2025-01-15 13:00:00'),
(22, N'Yllka',    N'Limani',   N'yllka.limani@email.com',    '+38344369582', 'd4f233e5dd09a0f705e1277f172e8a877d281aef4b2b82d152d24eeea6b4a30f', N'professional', 1, '2025-01-16 13:30:00'),
(23, N'Zenun',    N'Mehmeti',  N'zenun.mehmeti@email.com',   '+38345471693', 'b0b9823d810e15d5674c99be668a15425613d219b9cc2ba7bc90b4cdb02f6126', N'professional', 1, '2025-01-17 14:00:00'),
(24, N'Arta',     N'Nikqi',    N'arta.nikqi@email.com',      '+38349582714', '99e6d98ddca4047442bceb230a2c179f6d7c019165f4a992fce95bced7eba2a5', N'professional', 1, '2025-01-18 14:30:00'),
(25, N'Besnik',   N'Uka',      N'besnik.uka@email.com',      '+38344693825', 'df2cc45a4bfb374df4483e77ec66dbe74473f3e700512616a257c67a12dac40d', N'professional', 1, '2025-01-19 15:00:00'),
(26, N'Clirim',   N'Pllana',   N'clirim.pllana@email.com',  '+38345321654', 'c017b77b51656b1c127f62e96efb373f8805b3272d7320fa6eafbc22a89f7fe8', N'admin', 1, '2025-01-01 07:00:00'),
(27, N'Dafina',   N'Qorri',    N'dafina.qorri@email.com',   '+38349432765', '21ea1c30332832ddb37fc9ba1564fa1439fbdfb3cd343495eb22ad965e41d160', N'admin', 1, '2025-01-01 07:30:00'),
(28, N'Edon',     N'Rexhepi',  N'edon.rexhepi@email.com',   '+38344543876', '6643dbf55f432d13b08fce9e94866815a68766bd5c5148ff2a72a1c54602db0d', N'admin', 1, '2025-01-01 08:00:00'),
(29, N'Florina',  N'Sadiku',   N'florina.sadiku@email.com', '+38345654987', 'feef3ad4e6a2b8203cf120f5c2739d9214829ff2273e9119029543848181d1e5', N'admin', 1, '2025-01-01 08:30:00'),
(30, N'Granit',   N'Tahiri',   N'granit.tahiri@email.com',  '+38349765198', 'd8c0ddc6c000e46202ab58722c3dc4fa1851316f63a843c000208b08996e6caf', N'admin', 1, '2025-01-01 09:00:00');

SET IDENTITY_INSERT [User] OFF;
GO

-- =============================================
-- 2. Categories (8 rows)
-- =============================================
SET IDENTITY_INSERT Category ON;

INSERT INTO Category (category_id, category_name, description, is_active) VALUES
(1, N'Plumbing',              N'Pipe repair water heater installation and drain cleaning', 1),
(2, N'Electrical',            N'Wiring installation lighting repair and panel upgrades', 1),
(3, N'Cleaning',              N'House cleaning office cleaning and deep sanitization', 1),
(4, N'Painting & Renovation', N'Interior and exterior painting and home renovation', 1),
(5, N'HVAC',                  N'Heating ventilation and air conditioning services', 1),
(6, N'Locksmith',             N'Lock installation key duplication and emergency lockout', 1),
(7, N'Appliance Repair',      N'Washing machine refrigerator and oven repair', 1),
(8, N'Moving & Transport',    N'Furniture moving packing and local transport', 1);

SET IDENTITY_INSERT Category OFF;
GO

-- =============================================
-- 3. Services (25 rows)
-- =============================================
SET IDENTITY_INSERT Service ON;

INSERT INTO Service (service_id, service_name, description, base_price, is_active, category_id) VALUES
(1,  N'Pipe Repair',              N'Fix leaking or burst pipes in residential properties',        40.00,  1, 1),
(2,  N'Drain Cleaning',           N'Unclog and clean kitchen and bathroom drains',                 35.00,  1, 1),
(3,  N'Water Heater Installation', N'Install or replace electric and gas water heaters',           120.00, 1, 1),
(4,  N'Electrical Wiring',        N'New wiring installation for homes and offices',                80.00,  1, 2),
(5,  N'Lighting Installation',    N'Install ceiling lights chandeliers and outdoor lighting',      45.00,  1, 2),
(6,  N'Electrical Panel Upgrade', N'Upgrade fuse box or circuit breaker panel',                   150.00, 1, 2),
(7,  N'House Cleaning',           N'Full house cleaning including kitchen and bathrooms',          30.00,  1, 3),
(8,  N'Office Cleaning',          N'Professional cleaning for offices and commercial spaces',      50.00,  1, 3),
(9,  N'Deep Sanitization',        N'Thorough disinfection and deep cleaning service',              70.00,  1, 3),
(10, N'Interior Painting',        N'Paint walls ceilings and trim for rooms and apartments',       60.00,  1, 4),
(11, N'Exterior Painting',        N'Paint exterior walls fences and balconies',                    85.00,  1, 4),
(12, N'Bathroom Renovation',      N'Complete bathroom remodeling and tile work',                  200.00, 1, 4),
(13, N'AC Installation',          N'Install split or central air conditioning units',             140.00, 1, 5),
(14, N'Heating System Repair',    N'Repair boilers radiators and central heating systems',         90.00,  1, 5),
(15, N'AC Maintenance',           N'Regular AC filter cleaning and performance check',             40.00,  1, 5),
(16, N'Lock Replacement',         N'Replace door locks for homes and businesses',                  25.00,  1, 6),
(17, N'Emergency Lockout',        N'24/7 emergency lockout assistance',                            50.00,  1, 6),
(18, N'Key Duplication',          N'Duplicate standard and security keys',                         10.00,  1, 6),
(19, N'Washing Machine Repair',   N'Diagnose and fix washing machine issues',                      55.00,  1, 7),
(20, N'Refrigerator Repair',      N'Fix cooling leaks and compressor problems',                    65.00,  1, 7),
(21, N'Oven & Stove Repair',      N'Repair electric and gas ovens and stoves',                     50.00,  1, 7),
(22, N'Local Moving',             N'Move furniture and belongings within the city',                80.00,  1, 8),
(23, N'Furniture Assembly',       N'Assemble flat-pack furniture and office desks',                35.00,  1, 8),
(24, N'Packing Service',          N'Professional packing of belongings for moving',                45.00,  1, 8),
(25, N'Long Distance Moving',     N'Move belongings between cities in Kosovo',                    180.00, 1, 8);

SET IDENTITY_INSERT Service OFF;
GO

-- =============================================
-- 4. Professionals (15 rows)
-- =============================================
SET IDENTITY_INSERT Professional ON;

INSERT INTO Professional (professional_id, bio, experience_years, is_verified, user_id) VALUES
(1,  N'Licensed master plumber with 12 years in residential and commercial plumbing',           12, 1, 11),
(2,  N'Certified electrician specializing in home wiring and panel upgrades',                     8, 1, 12),
(3,  N'Professional cleaner running a team of 5 for homes and offices in Prishtina',              6, 1, 13),
(4,  N'Interior and exterior painter with renovation experience across Kosovo',                  10, 1, 14),
(5,  N'HVAC technician certified for split and central AC systems',                               5, 1, 15),
(6,  N'Emergency locksmith available 24/7 in the Prishtina area',                                 7, 1, 16),
(7,  N'Appliance repair specialist for all major brands',                                         9, 1, 17),
(8,  N'Moving company owner with a fleet of 3 trucks in Kosovo',                                 11, 1, 18),
(9,  N'Junior plumber specializing in drain cleaning and maintenance',                            3, 1, 19),
(10, N'Electrician focused on smart home installations and lighting',                              4, 1, 20),
(11, N'Deep cleaning specialist with hospital-grade sanitization equipment',                       8, 1, 21),
(12, N'Renovation contractor experienced in bathroom and kitchen remodeling',                     14, 1, 22),
(13, N'HVAC engineer with experience in large commercial heating systems',                         6, 1, 23),
(14, N'Appliance technician specialized in washing machines and refrigerators',                    5, 1, 24),
(15, N'Experienced mover and furniture assembly professional',                                     7, 1, 25);

SET IDENTITY_INSERT Professional OFF;
GO

-- =============================================
-- 5. ProfessionalService (38 rows)
-- =============================================
INSERT INTO ProfessionalService (professional_id, service_id, custom_price) VALUES
(1,  1,  45.00),
(1,  2,  40.00),
(1,  3,  130.00),
(2,  4,  85.00),
(2,  5,  50.00),
(2,  6,  160.00),
(3,  7,  28.00),
(3,  8,  45.00),
(3,  9,  65.00),
(4,  10, 65.00),
(4,  11, 90.00),
(4,  12, 220.00),
(5,  13, 150.00),
(5,  14, 95.00),
(5,  15, 45.00),
(6,  16, 30.00),
(6,  17, 55.00),
(6,  18, 12.00),
(7,  19, 60.00),
(7,  20, 70.00),
(7,  21, 55.00),
(8,  22, 90.00),
(8,  24, 50.00),
(8,  25, 200.00),
(9,  1,  35.00),
(9,  2,  30.00),
(10, 4,  75.00),
(10, 5,  42.00),
(11, 7,  35.00),
(11, 9,  75.00),
(12, 10, 70.00),
(12, 12, 250.00),
(13, 13, 145.00),
(13, 14, 100.00),
(14, 19, 50.00),
(14, 20, 60.00),
(15, 22, 75.00),
(15, 23, 38.00);
GO

-- =============================================
-- 6. Availability (35 rows)
-- =============================================
SET IDENTITY_INSERT Availability ON;

INSERT INTO Availability (availability_id, status, [date], start_time, end_time, professional_id) VALUES
(1,  N'available',   '2025-06-02', '08:00', '12:00', 1),
(2,  N'available',   '2025-06-02', '13:00', '17:00', 1),
(3,  N'booked',      '2025-06-03', '08:00', '11:00', 1),
(4,  N'available',   '2025-06-02', '07:30', '15:30', 2),
(5,  N'available',   '2025-06-03', '07:30', '15:30', 2),
(6,  N'unavailable', '2025-06-04', '07:30', '15:30', 2),
(7,  N'available',   '2025-06-02', '06:00', '14:00', 3),
(8,  N'available',   '2025-06-03', '06:00', '14:00', 3),
(9,  N'booked',      '2025-06-04', '06:00', '10:00', 3),
(10, N'available',   '2025-06-02', '08:00', '16:00', 4),
(11, N'booked',      '2025-06-03', '08:00', '12:00', 4),
(12, N'available',   '2025-06-04', '08:00', '16:00', 4),
(13, N'available',   '2025-06-02', '07:00', '15:00', 5),
(14, N'available',   '2025-06-03', '07:00', '15:00', 5),
(15, N'available',   '2025-06-02', '09:00', '21:00', 6),
(16, N'available',   '2025-06-03', '09:00', '21:00', 6),
(17, N'booked',      '2025-06-04', '18:00', '21:00', 6),
(18, N'available',   '2025-06-02', '08:00', '17:00', 7),
(19, N'available',   '2025-06-03', '08:00', '17:00', 7),
(20, N'available',   '2025-06-02', '06:00', '18:00', 8),
(21, N'booked',      '2025-06-03', '06:00', '12:00', 8),
(22, N'available',   '2025-06-02', '08:00', '14:00', 9),
(23, N'available',   '2025-06-03', '08:00', '14:00', 9),
(24, N'available',   '2025-06-02', '09:00', '17:00', 10),
(25, N'unavailable', '2025-06-04', '09:00', '17:00', 10),
(26, N'available',   '2025-06-02', '05:30', '13:30', 11),
(27, N'available',   '2025-06-03', '05:30', '13:30', 11),
(28, N'available',   '2025-06-02', '07:00', '16:00', 12),
(29, N'available',   '2025-06-03', '07:00', '16:00', 12),
(30, N'available',   '2025-06-02', '08:00', '16:00', 13),
(31, N'booked',      '2025-06-03', '08:00', '12:00', 13),
(32, N'available',   '2025-06-02', '09:00', '17:00', 14),
(33, N'available',   '2025-06-03', '09:00', '17:00', 14),
(34, N'available',   '2025-06-02', '06:00', '14:00', 15),
(35, N'available',   '2025-06-03', '06:00', '14:00', 15);

SET IDENTITY_INSERT Availability OFF;
GO

-- =============================================
-- 7. Reservations (40 rows)
-- =============================================
SET IDENTITY_INSERT Reservation ON;

INSERT INTO Reservation (reservation_id, [date], [time], status, created_at, service_id, professional_id, user_id) VALUES
(1,  '2025-02-10', '08:30', N'completed', '2025-02-07 10:00:00', 1,  1,  1),
(2,  '2025-02-12', '09:00', N'completed', '2025-02-09 11:00:00', 4,  2,  2),
(3,  '2025-02-15', '07:00', N'completed', '2025-02-12 09:00:00', 7,  3,  3),
(4,  '2025-02-20', '08:00', N'completed', '2025-02-17 14:00:00', 10, 4,  4),
(5,  '2025-03-01', '10:00', N'completed', '2025-02-26 08:00:00', 13, 5,  5),
(6,  '2025-03-05', '18:00', N'completed', '2025-03-02 10:00:00', 17, 6,  6),
(7,  '2025-03-10', '09:00', N'completed', '2025-03-07 09:00:00', 19, 7,  7),
(8,  '2025-03-15', '07:00', N'completed', '2025-03-12 11:00:00', 22, 8,  8),
(9,  '2025-03-20', '08:00', N'completed', '2025-03-17 09:00:00', 2,  9,  9),
(10, '2025-03-25', '10:00', N'completed', '2025-03-22 10:00:00', 5,  10, 10),
(11, '2025-04-01', '08:30', N'completed', '2025-03-28 08:00:00', 9,  11, 1),
(12, '2025-04-05', '08:00', N'completed', '2025-04-02 10:00:00', 12, 12, 2),
(13, '2025-04-10', '09:00', N'completed', '2025-04-07 14:00:00', 14, 13, 3),
(14, '2025-04-15', '09:30', N'completed', '2025-04-12 11:00:00', 20, 14, 4),
(15, '2025-04-20', '07:00', N'completed', '2025-04-17 09:00:00', 23, 15, 5),
(16, '2025-05-01', '08:00', N'completed', '2025-04-28 10:00:00', 1,  1,  6),
(17, '2025-05-05', '09:00', N'completed', '2025-05-02 08:00:00', 4,  2,  7),
(18, '2025-05-10', '06:30', N'completed', '2025-05-07 14:00:00', 7,  3,  8),
(19, '2025-05-15', '08:00', N'completed', '2025-05-12 08:00:00', 16, 6,  1),
(20, '2025-05-20', '10:00', N'completed', '2025-05-17 10:00:00', 22, 8,  1),
(21, '2025-06-01', '08:30', N'completed', '2025-05-28 10:00:00', 3,  1,  3),
(22, '2025-06-05', '07:30', N'completed', '2025-06-02 11:00:00', 6,  2,  4),
(23, '2025-06-10', '06:00', N'completed', '2025-06-07 09:00:00', 8,  3,  1),
(24, '2025-06-15', '08:00', N'completed', '2025-06-12 09:00:00', 11, 4,  1),
(25, '2025-06-20', '07:00', N'completed', '2025-06-17 10:00:00', 15, 5,  1),
(26, '2025-07-01', '09:00', N'confirmed', '2025-06-28 09:00:00', 10, 4,  7),
(27, '2025-07-05', '08:00', N'confirmed', '2025-07-02 10:00:00', 13, 5,  8),
(28, '2025-07-10', '18:30', N'confirmed', '2025-07-07 11:00:00', 17, 6,  9),
(29, '2025-07-15', '09:00', N'pending',   '2025-07-12 14:00:00', 1,  1,  10),
(30, '2025-07-20', '08:00', N'pending',   '2025-07-17 10:00:00', 19, 7,  2),
(31, '2025-08-01', '07:00', N'pending',   '2025-07-28 09:00:00', 7,  3,  5),
(32, '2025-08-05', '09:00', N'pending',   '2025-08-02 11:00:00', 21, 7,  6),
(33, '2025-08-10', '10:00', N'cancelled', '2025-08-07 08:00:00', 14, 13, 9),
(34, '2025-08-15', '08:00', N'cancelled', '2025-08-12 10:00:00', 24, 8,  10),
(35, '2025-09-01', '08:30', N'completed', '2025-08-28 10:00:00', 2,  1,  1),
(36, '2025-09-05', '09:00', N'completed', '2025-09-02 11:00:00', 5,  2,  1),
(37, '2026-01-10', '08:00', N'pending',   '2025-12-20 10:00:00', 1,  9,  2),
(38, '2026-01-15', '09:00', N'pending',   '2025-12-22 11:00:00', 10, 4,  3),
(39, '2026-01-20', '07:00', N'confirmed', '2025-12-25 09:00:00', 22, 15, 5),
(40, '2026-02-01', '06:00', N'pending',   '2026-01-15 10:00:00', 9,  11, 6);

SET IDENTITY_INSERT Reservation OFF;
GO

-- =============================================
-- 8. Reviews (25 rows)
-- =============================================
SET IDENTITY_INSERT Review ON;

INSERT INTO Review (review_id, rating, comment, created_at, reservation_id) VALUES
(1,  5, N'Fixed the leaking pipe in under an hour. Excellent work',              '2025-02-11 10:00:00', 1),
(2,  4, N'Rewired the living room quickly and cleanly',                          '2025-02-13 11:00:00', 2),
(3,  5, N'House was spotless after the cleaning. Very thorough',                 '2025-02-16 09:00:00', 3),
(4,  4, N'Great interior painting. Colors look amazing',                         '2025-02-21 14:00:00', 4),
(5,  5, N'AC installed perfectly and works great. Very professional',            '2025-03-02 08:00:00', 5),
(6,  4, N'Got locked out at night and he came within 20 minutes',               '2025-03-06 10:00:00', 6),
(7,  3, N'Washing machine fixed but took longer than expected',                  '2025-03-11 09:00:00', 7),
(8,  5, N'Moving team was fast and careful with furniture',                       '2025-03-16 11:00:00', 8),
(9,  4, N'Drain is flowing perfectly now. Good job',                             '2025-03-21 09:00:00', 9),
(10, 5, N'Smart lighting installed in the whole apartment. Love it',             '2025-03-26 10:00:00', 10),
(11, 5, N'Deep sanitization was very thorough. Office smells fresh',             '2025-04-02 08:00:00', 11),
(12, 4, N'Bathroom renovation turned out beautiful. Minor delay on tiles',       '2025-04-06 10:00:00', 12),
(13, 5, N'Heating system repaired same day. Very knowledgeable',                 '2025-04-11 14:00:00', 13),
(14, 4, N'Refrigerator cooling again. Fair price for the repair',               '2025-04-16 11:00:00', 14),
(15, 5, N'Assembled all IKEA furniture perfectly. Very efficient',               '2025-04-21 09:00:00', 15),
(16, 5, N'Second time using this plumber. Always reliable',                      '2025-05-02 10:00:00', 16),
(17, 4, N'Electrical panel upgraded smoothly. Clean work',                       '2025-05-06 08:00:00', 17),
(18, 4, N'Office cleaned to a high standard. Will book again',                   '2025-05-11 14:00:00', 18),
(19, 5, N'Lock replaced quickly. Feels much more secure now',                    '2025-05-16 08:00:00', 19),
(20, 5, N'Third move with this team. Always careful and fast',                   '2025-05-21 10:00:00', 20),
(21, 4, N'Water heater installed and working perfectly',                         '2025-06-02 10:00:00', 21),
(22, 5, N'Panel upgrade done professionally with new breakers',                  '2025-06-06 11:00:00', 22),
(23, 4, N'Office deep cleaned before our opening. Looked great',                 '2025-06-11 09:00:00', 23),
(24, 5, N'Exterior painting transformed the look of our house',                  '2025-06-16 09:00:00', 24),
(25, 4, N'AC maintenance done quickly. Running much cooler now',                 '2025-06-21 10:00:00', 25);

SET IDENTITY_INSERT Review OFF;
GO

-- =============================================
-- 9. Payments (30 rows)
-- =============================================
SET IDENTITY_INSERT Payment ON;

INSERT INTO Payment (payment_id, amount, method, payment_status, transaction_date, reservation_id) VALUES
(1,  45.00,  N'card',   N'paid',    '2025-02-10 09:00:00', 1),
(2,  85.00,  N'card',   N'paid',    '2025-02-12 09:30:00', 2),
(3,  28.00,  N'cash',   N'paid',    '2025-02-15 07:30:00', 3),
(4,  65.00,  N'card',   N'paid',    '2025-02-20 08:30:00', 4),
(5,  150.00, N'paypal', N'paid',    '2025-03-01 10:30:00', 5),
(6,  55.00,  N'cash',   N'paid',    '2025-03-05 18:30:00', 6),
(7,  60.00,  N'card',   N'paid',    '2025-03-10 09:30:00', 7),
(8,  90.00,  N'card',   N'paid',    '2025-03-15 07:30:00', 8),
(9,  30.00,  N'cash',   N'paid',    '2025-03-20 08:30:00', 9),
(10, 42.00,  N'paypal', N'paid',    '2025-03-25 10:30:00', 10),
(11, 75.00,  N'card',   N'paid',    '2025-04-01 09:00:00', 11),
(12, 250.00, N'card',   N'paid',    '2025-04-05 08:30:00', 12),
(13, 100.00, N'paypal', N'paid',    '2025-04-10 09:30:00', 13),
(14, 60.00,  N'cash',   N'paid',    '2025-04-15 10:00:00', 14),
(15, 38.00,  N'card',   N'paid',    '2025-04-20 07:30:00', 15),
(16, 45.00,  N'card',   N'paid',    '2025-05-01 08:30:00', 16),
(17, 85.00,  N'paypal', N'paid',    '2025-05-05 09:30:00', 17),
(18, 28.00,  N'cash',   N'paid',    '2025-05-10 07:00:00', 18),
(19, 30.00,  N'card',   N'paid',    '2025-05-15 08:30:00', 19),
(20, 90.00,  N'card',   N'paid',    '2025-05-20 10:30:00', 20),
(21, 130.00, N'paypal', N'paid',    '2025-06-01 09:00:00', 21),
(22, 160.00, N'card',   N'paid',    '2025-06-05 08:00:00', 22),
(23, 45.00,  N'cash',   N'paid',    '2025-06-10 06:30:00', 23),
(24, 90.00,  N'card',   N'paid',    '2025-06-15 08:30:00', 24),
(25, 45.00,  N'paypal', N'paid',    '2025-06-20 07:30:00', 25),
(26, 65.00,  N'card',   N'pending', '2025-07-01 09:30:00', 26),
(27, 150.00, N'paypal', N'pending', '2025-07-05 08:30:00', 27),
(28, 55.00,  N'cash',   N'pending', '2025-07-10 19:00:00', 28),
(29, 45.00,  N'card',   N'pending', '2025-07-15 09:30:00', 29),
(30, 60.00,  N'card',   N'failed',  '2025-07-20 08:30:00', 30);

SET IDENTITY_INSERT Payment OFF;
GO

-- =============================================
-- Re-enable all triggers
-- =============================================
ENABLE TRIGGER trg_PreventDoubleReservation ON Reservation;
ENABLE TRIGGER trg_ValidateReview ON Review;
ENABLE TRIGGER trg_UpdateReservationPaymentStatus ON Payment;
ENABLE TRIGGER trg_PreventCompletedReservationEdit ON Reservation;
ENABLE TRIGGER trg_LogReservationDeletion ON Reservation;
GO

-- =============================================
-- Verification: Row counts
-- =============================================
SELECT 'User' AS TableName, COUNT(*) AS RowCount FROM [User]
UNION ALL SELECT 'Category',            COUNT(*) FROM Category
UNION ALL SELECT 'Service',             COUNT(*) FROM Service
UNION ALL SELECT 'Professional',        COUNT(*) FROM Professional
UNION ALL SELECT 'ProfessionalService', COUNT(*) FROM ProfessionalService
UNION ALL SELECT 'Availability',        COUNT(*) FROM Availability
UNION ALL SELECT 'Reservation',         COUNT(*) FROM Reservation
UNION ALL SELECT 'Review',              COUNT(*) FROM Review
UNION ALL SELECT 'Payment',             COUNT(*) FROM Payment
UNION ALL SELECT 'ReservationAuditLog', COUNT(*) FROM ReservationAuditLog
ORDER BY TableName;
GO
