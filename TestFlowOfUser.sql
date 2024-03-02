use test3	
select * from TourSupplier
 -- UNDER THE MPLOYEE ROLE -> 1. RECEIVE and MAKE A BOOKING
 select * from Booking
 select * from Employee

 INSERT INTO [dbo].[Booking] (
    [bookingID],
    [tourID],
    [supplierID],
    [employeeID]
)
VALUES (
    1000, -- BookingID
    1001, -- TourID
    1,    -- SupplierID
    1     --EmployeeID
	)
select * from Booking
delete from Booking
delete from Member
--ERROR: totalprice s not updated->AHH PERCHE NON inserted MEMBER

-- paid, remaining,show up as null 
---> alter column paid, set default is null
ALTER TABLE [dbo].[Booking]
ADD CONSTRAINT [DF_Booking_paid] DEFAULT (0) FOR [paid];

ALTER TABLE [dbo].[Booking]
DROP COLUMN [remaining];

ALTER TABLE [dbo].[Booking]
ADD [remaining] DECIMAL(10, 2) DEFAULT (0);

DROP  TRIGGER UpdateRemainingTrigger
ON Booking
AFTER UPDATE
AS
BEGIN
    UPDATE b
    SET b.remaining = ISNULL(i.totalPrice, 0) - ISNULL(i.paid, 0)
    FROM Booking b
    INNER JOIN inserted i ON b.bookingID = i.bookingID;
END;

--->alter column remaining, set default is total price, butthe toal price is computed column-> drop this table


--2. add MEMBER to a booking
INSERT INTO [dbo].[Member] ([memberID], [bookingID], [firstName], [lastName], [DOB], [height])
VALUES (10001, 1000, 'Mai', 'Anh', '2004-02-12', 158);
INSERT INTO [dbo].[Member] ([memberID], [bookingID], [firstName], [lastName], [DOB], [height])
VALUES (10002, 1000, 'Mai', 'Em', '2004-02-12', 200);
INSERT INTO [dbo].[Member] ([memberID], [bookingID], [firstName], [lastName], [DOB], [height])
VALUES (10003, 1000, 'Mai', 'Chi', '2004-02-12', 100);

--3. add payment for the bookin
INSERT INTO [dbo].[Payment] ([paymentID], [bookingID], [amount], [date], [method])
VALUES (1001, 1000, 100.00, '2024-01-18', 'cash');

--THE CASE: BOOKING IS EXPIRED, NOW LET"S REFUND
--4, add refund information-> some attribute should be added
INSERT INTO [dbo].[Refund] ([refundID], [bookingID], [name], [method], [bankingNumber], [bankName], [status], [transactionConfirmation])
VALUES (1000, 1000, 'mai', 'banking', '001293746352', 'VP Bank', 'success', 'ID: 728884');

--recreate the table(because ther is no constrant so it quite straigtforward)

--way1:create column amount as paid in booking (nt allowed for subquieries, as the bookingID is not yet created for useing)
--way2:create trigger
-- Drop the existing Refund table if it exists

CREATE TABLE dbo.Refund (
    [refundID]                INT           NOT NULL,
    [bookingID]               INT           NOT NULL,
    [name]                    VARCHAR (255) ,
    [method]                  VARCHAR (50)  NOT NULL,
    [bankingNumber]           VARCHAR (255) NULL,
    [bankName]                VARCHAR (255) NULL,
    [status]                  VARCHAR (50)  NOT NULL,
    [transactionConfirmation] VARCHAR (255) ,
    [amount]                  DECIMAL (10, 2) DEFAULT (0), -- Default to 0 initially
    PRIMARY KEY CLUSTERED ([refundID] ASC),
    FOREIGN KEY ([bookingID]) REFERENCES [dbo].[Booking] ([bookingID]),
    CHECK ([method]='cash' OR [method]='banking')
);

-- Create a trigger to update the 'amount' column after inserting a refund
CREATE TRIGGER UpdateRefundAmountTrigger
ON Refund
AFTER INSERT
AS
BEGIN
    UPDATE r
    SET amount = ISNULL(b.paid, 0)
    FROM Refund r
    INNER JOIN inserted i ON r.bookingID = i.bookingID
    LEFT JOIN Booking b ON r.bookingID = b.bookingID;
END;


select * from Refund

--SUCCESSFUL CASE

 INSERT INTO [dbo].[Booking] (
    [bookingID],
    [tourID],
    [supplierID],
    [employeeID]
)
VALUES (
    1001, -- BookingID
    1004, -- TourID
    5,    -- SupplierID
    1     --EmployeeID
	)
select * from Booking

--2. add MEMBER to a booking

INSERT INTO [dbo].[Member] ([memberID], [bookingID], [firstName], [lastName], [DOB], [height])
VALUES (10011, 1001, 'Mai', 'Anh', '2004-02-12', 158);
INSERT INTO [dbo].[Member] ([memberID], [bookingID], [firstName], [lastName], [DOB], [height])
VALUES (10012, 1001, 'Mai', 'Em', '2004-02-12', 200);
INSERT INTO [dbo].[Member] ([memberID], [bookingID], [firstName], [lastName], [DOB], [height])
VALUES (10013, 1001, 'Mai', 'Chi', '2004-02-12', 100);
select * from Member 
where bookingID = 1001

--3. add payment for the booking -> fully paid date is not updated-> the status is not accurate
INSERT INTO [dbo].[Payment] ([paymentID], [bookingID], [amount], [date], [method])
VALUES (10001, 1001, 100.00, '2024-02-03', 'cash');
INSERT INTO [dbo].[Payment] ([paymentID], [bookingID], [amount], [date], [method])
VALUES (10002, 1001, 10000, '2024-02-03', 'banking');



-- Update fullyPaidDate for a specific booking (e.g., bookingID 1001)
UPDATE Booking
SET fullyPaidDate = '2024-03-02'
WHERE bookingID = 1001;













--MAINTAIN DATA USECASES
SELECT * FROM Tour

--1. spplier
SELECT * FROM Supplier
INSERT INTO [dbo].[Supplier] ([supplierID], [name], [email], [address], [website], [contactPerson], [contactPersonPhone], [contactPersonEmail])
VALUES
    (3, N'Vietnam Travel Co', 'info@congtydulich.vn', N'123 Đường Nguyễn Huệ, Hà Nội', 'https://www.congtydulich.vn', N'Trần Văn Nam', '(84-24) 1234 5678', 'nam@congtydulich.vn'),
    (4, N'Explore Vietnam Tours', 'info@khamphavietnam.com', N'456 Đường Lê Lợi, Thành phố Hồ Chí Minh', 'https://www.khamphavietnam.com', N'Nguyễn Thị Hà', '(84-28) 8765 4321', 'ha@khamphavietnam.com'),
    (5, N'Viet Heritage Tours', 'info@dulichdisan.vn', N'789 Đường Trần Phú, Đà Nẵng', 'https://www.dulichdisan.vn', N'Lê Văn An', '(84-236) 9876 5432', 'an@dulichdisan.vn');
--2. TourSupplier
SELECT * FROM TourSupplier
INSERT INTO [dbo].[TourSupplier] ([tourID], [supplierID], [price], [startDay], [endDay], [description], [availability], [totalSlots])
VALUES
    (1004, 5, 1980.00, '2024-09-05', '2024-11-05', N'You’ll have 2 starting options
Or, you can also get picked up
See departure details
Pass by
Hanoi Opera House
Halong Bay
1
Stop: 60 minutes - Admission included
See details & photo
2
Stop: 45 minutes
See details & photo
3
Stop: 45 minutes
See details & photo
4
Stop: 30 minutes
See details & photo
You''ll return to the starting point', 30, 100);

