
-- Tạo bảng Customer --
CREATE TABLE Customer (
 customerID int PRIMARY KEY,
 name nvarchar(255),
 email nvarchar(255),
 phoneNumber nvarchar(20)
);

-- Tạo bảng Supplier --
CREATE TABLE Supplier (
 supplierID int PRIMARY KEY,
 name nvarchar(255),
 email nvarchar(255),
 phoneNumber nvarchar(20)
);

-- Tạo bảng Tour --
CREATE TABLE Tour (
 tourID int PRIMARY KEY,
 name nvarchar(255),
 picture varbinary(max)
);

-- Tạo bảng TourSupplier --
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

-- Tạo bảng Employee --
CREATE TABLE Employee (
 employeeID int PRIMARY KEY,
 firstName nvarchar(255),
 lastName nvarchar(225)
 role nvarchar(255),
 email nvarchar(255),
 phoneNumber nvarchar(20)
);

--Tạo function tính tổng giá trị Booking
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

-- Tạo bảng Booking --
CREATE TABLE Booking (
 bookingID int PRIMARY KEY,
 tourID int,
 supplierID int,
 customerID int,
 date date,
 status nvarchar(255),
 totalPrice float,
 paid float,
 remaining float,
 employeeID int, 
 FOREIGN KEY (tourID) REFERENCES Tour(tourID), 
 FOREIGN KEY (supplierID) REFERENCES Supplier(supplierID), 
 FOREIGN KEY (customerID) REFERENCES Customer(customerID), 
 FOREIGN KEY (employeeID) REFERENCES Employee(employeeID)
);

-- Tạo bảng Payment --
CREATE TABLE Payment (
 paymentID int PRIMARY KEY,
 bookingID int,
 amount float,
 date datetime,
 method nvarchar(10) CHECK (method IN ('banking', 'cash')),
 FOREIGN KEY (bookingID) REFERENCES Booking(bookingID)
);

ALTER TABLE Booking
	ADD paid Decimal(10,2);
UPDATE Booking
	SET paid = (
		SELECT ISNULL(SUM(amount), 0)
		FROM Payment
		WHERE Booking.bookingID = Payment.bookingID
	);

ALTER TABLE Booking
	ADD remaining Decimal(10,2);
UPDATE Booking
	SET remaining = ISNULL(totalPrice, 0) - ISNULL(paid, 0);

-- Tạo bảng đơn thừa kế Member --
CREATE TABLE Member (
    memberID INT PRIMARY KEY,
    bookingID INT,
 	  foreign key (bookingID) references Booking(bookingID)
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
        ELSE NULL
        
	END
    )
 );

-- Tạo bảng Ticket --
CREATE TABLE Ticket (
 ticketID int PRIMARY KEY,
 memberID int,
 issuedTime datetime,
 FOREIGN KEY (memberID) REFERENCES Member(memberID)
);
