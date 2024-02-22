create database test2
use test2
--Create tables that dont have FK first

CREATE TABLE Customer (
 customerID int identity(1,1) PRIMARY KEY,
 name nvarchar(255),
 email nvarchar(255),
 phoneNumber nvarchar(20)
);
select * from Customer


CREATE TABLE Supplier (
 supplierID int PRIMARY KEY,
 name nvarchar(255),
 email nvarchar(255),
 phoneNumber nvarchar(20)
);
select * from Supplier

CREATE TABLE Tour (
 tourID int PRIMARY KEY,
 name nvarchar(255),
 picture varbinary(max)
);
select * from Tour

CREATE TABLE Employee (
	employeeID int identity(1,1) PRIMARY KEY,
	firstName nvarchar(255),
	lastName nvarchar(255),
	role nvarchar(255),
	email nvarchar(255),
	phoneNumber nvarchar(20)
);
select * from Employee

CREATE TABLE TourSupplier (
	 tourID int,
	 supplierID int,
	 price float,
	 startDay date,
	 endDay date,
	 discription nvarchar(max),
	 availability int, 
	 PRIMARY KEY (tourID, supplierID),
	 FOREIGN KEY (tourID) REFERENCES Tour(tourID),
	 FOREIGN KEY (supplierID) REFERENCES Supplier(supplierID)
	);
select * from TourSupplier

CREATE FUNCTION dbo.CalculateTotalPrice(@BookingID INT, @TourID INT, @SupplierID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @TotalMultiplier DECIMAL(10, 2);

    -- Calculate the total multiplier for the specific BookingID
    SELECT @TotalMultiplier = ISNULL(SUM(multiplier), 0)
    FROM Member
    WHERE bookingID = @bookingID;

    -- Calculate the total multiplier * price using the specific TourID
    RETURN @TotalMultiplier * ISNULL((SELECT price
                                      FROM TourSupplier
                                      WHERE tourID = @tourID and supplierID = @supplierID), 0);
END;
GO


CREATE TABLE Booking (
    bookingID INT PRIMARY KEY,
    tourID INT,
    supplierID INT,
    date DATE,
    status VARCHAR(50),
    totalPrice AS dbo.CalculateTotalPrice(bookingID,tourID,supplierID),
    FOREIGN KEY (tourID, supplierID) REFERENCES TourSupplier(tourID, supplierID)
);

ALTER TABLE Booking
ADD customerID INT;
ALTER TABLE Booking
ADD CONSTRAINT FK_Booking_Customer
FOREIGN KEY (customerID)
REFERENCES Customer(customerID);

ALTER TABLE Booking
ADD employeeID INT;
ALTER TABLE Booking
ADD CONSTRAINT FK_Booking_Employee
FOREIGN KEY (employeeID)
REFERENCES Employee(employeeID);



CREATE TABLE Member (
    memberID INT PRIMARY KEY,
    bookingID INT,
    firstName VARCHAR(100),
    lastName VARCHAR(100),
    DOB DATE,
	Type AS (
		CASE
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) > 12 THEN 'Adult'
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 5 AND 12 THEN 'Child'
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 2 AND 4 THEN 'Young Child'
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 0 AND 1 THEN 'Baby'
		ELSE 'Unidentified'

    END),
	
    multiplier AS (
        CASE
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) > 12 THEN 1
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 5 AND 12 THEN 0.7
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 2 AND 4 THEN 0.5
        WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 0 AND 1 THEN 0
        ELSE NULL  -- Handle other cases if needed
        
	END
    ),

	foreign key (bookingID) references Booking(bookingID)
	);


CREATE TABLE Ticket (
	 ticketID int PRIMARY KEY,
	 memberID int,
	 issuedTime datetime,
	 FOREIGN KEY (memberID) REFERENCES Member(memberID)
	);


CREATE TABLE Payment (
    paymentID INT PRIMARY KEY,
    bookingID INT,
    amount FLOAT,
    date DATETIME,
    method NVARCHAR(10) CHECK (method IN ('banking', 'cash')),
    FOREIGN KEY (bookingID) REFERENCES Booking(bookingID)
);
use test2

alter table Member
add gender int check (gender in ('1','2'))
--PAYMENT DEADLINE 
ALTER TABLE Booking
ADD paymentDeadline DATE;

-- Update the paymentDeadline column based on startDate from TourSupplier
UPDATE Booking
SET paymentDeadline = (
    SELECT DATEADD(DAY, -2, startDay)
    FROM TourSupplier
    WHERE Booking.tourID = TourSupplier.tourID
      AND Booking.supplierID = TourSupplier.supplierID

--PAID VALUEs

ALTER TABLE Booking
	ADD paid Decimal(10,2);
use test2
UPDATE Booking
SET paid = (
    SELECT ISNULL(SUM(amount), 0)
    FROM Payment
    WHERE Booking.bookingID = Payment.bookingID
);

--REMAINING VALUES

ALTER TABLE Booking
	ADD remaining Decimal(10,2);

UPDATE Booking
SET remaining = ISNULL(totalPrice, 0) - ISNULL(paid, 0);
UPDATE Booking
SET remaining = CASE
    WHEN (totalPrice - paid) < 0 THEN 0
    ELSE (totalPrice - paid)
END;

SELECT * FROM Booking;

-- FULLY PAYMENT DATE

ALTER TABLE Booking
ADD fullyPaidDate DATETIME;

UPDATE Booking
SET fullyPaidDate = (
    SELECT MAX(date)
    FROM Payment
    WHERE Payment.bookingID = Booking.bookingID and remaining=0
);


--TOTAL SLOT

ALTER TABLE TourSupplier
ADD totalSlots INT

--STATUS OF BOOKING -> ARCHIVED, replcds by triggers

"""UPDATE Booking
SET status = CASE
    WHEN fullyPaidDate IS NOT NULL AND fullyPaidDate <= paymentDeadline THEN 'Success'
    WHEN fullyPaidDate IS NOT NULL AND fullyPaidDate > paymentDeadline THEN 'Expired'
    WHEN fullyPaidDate IS NULL AND GETDATE() > paymentDeadline THEN 'Expired'
    WHEN fullyPaidDate IS NULL AND GETDATE() <= paymentDeadline THEN 'Pending'
    ELSE 'Pending'
END;"""


-- REFUND INFORMATION
CREATE TABLE Refund (
    refundID INT PRIMARY KEY,
    bookingID INT REFERENCES Booking(bookingID),
    name VARCHAR(255), -- Customer name or other identifier
    method VARCHAR(50) CHECK (method IN ('banking', 'cash')),
    bankingNumber VARCHAR(255), -- Banking details for refund
    bankName VARCHAR(255), -- Name of the bank
    amount DECIMAL(10, 2),
    status VARCHAR(50),
    transactionConfirmation VARCHAR(255), 
	)
