CREATE DATABASE test3;
USE test3;

-- Tạo các bảng duy trì dữ liệu (không chứa Foreign Keys)

CREATE TABLE Customer (
    customerID  INT PRIMARY KEY IDENTITY (1, 1) NOT NULL,
    name        NVARCHAR (255) NOT NULL,
    email       NVARCHAR (255) NULL,
    phoneNumber NVARCHAR (20) NOT NULL
);

CREATE TABLE Employee (
    employeeID  INT PRIMARY KEY IDENTITY (1, 1) NOT NULL,
    firstName   NVARCHAR (255) NOT NULL,
    lastName    NVARCHAR (255) NOT NULL,
    role        NVARCHAR (255) NOT NULL,
    email       NVARCHAR (255) NOT NULL,
    phoneNumber NVARCHAR (20) NOT NULL
);

CREATE TABLE Tour (
    tourID      INT PRIMARY KEY NOT NULL,
    name        NVARCHAR (255) NOT NULL,
    picture     NVARCHAR (255) NULL,
    description NVARCHAR (MAX) NULL
);

CREATE TABLE Supplier (
    supplierID          INT PRIMARY KEY NOT NULL,
    name                NVARCHAR (255) NOT NULL,
    email               NVARCHAR (255) NULL,
    address             NVARCHAR (255) NULL,
    website             NVARCHAR (255) NULL,
    contactPerson       NVARCHAR (255) NULL,
    contactPersonPhone  NVARCHAR (20) NOT NULL,
    contactPersonEmail  NVARCHAR (255) NOT NULL
);

CREATE TABLE TourSupplier (
    tourID       INT PRIMARY KEY NOT NULL,
    supplierID   INT PRIMARY KEY NOT NULL,
    price        DECIMAL (10, 2) NOT NULL,
    startDay     DATE NOT NULL,
    endDay       DATE NOT NULL,
    description  NVARCHAR (MAX) NOT NULL,
    availability INT NOT NULL,
    totalSlots   INT NOT NULL,
    FOREIGN KEY (tourID) REFERENCES Tour (tourID),
    FOREIGN KEY (supplierID) REFERENCES Supplier (supplierID)
);

--Tạo Function tự động tính tổng giá trị Booking

CREATE FUNCTION CalculateTotalPrice(
    @BookingID INT, 
    @TourID INT, 
    @SupplierID INT
) RETURNS DECIMAL(10, 2) AS BEGIN
    DECLARE @TotalMultiplier DECIMAL(10, 2);
    SELECT @TotalMultiplier = ISNULL(SUM(multiplier), 0) FROM Member WHERE bookingID = @BookingID;
    RETURN @TotalMultiplier * ISNULL((SELECT price FROM TourSupplier WHERE tourID = @TourID AND supplierID = @SupplierID), 0);
END;

--Tạo Function tự động tính thời hạn thanh toán Booking

CREATE FUNCTION CalculatePaymentDeadline(
    @TourID INT, 
    @SupplierID INT
) RETURNS DATE AS BEGIN
    DECLARE @StartDay DATE;
    SELECT @StartDay = startDay FROM TourSupplier WHERE tourID = @TourID AND supplierID = @SupplierID;
    RETURN DATEADD(DAY, -2, @StartDay);
END;

--Tạo các bảng giao dịch

CREATE TABLE Booking (
    bookingID       INT PRIMARY KEY NOT NULL,
    tourID          INT NOT NULL,
    supplierID      INT NOT NULL,
    date            DATE DEFAULT GETDATE(),
    status          VARCHAR (50) DEFAULT 'Pending',
    totalPrice      AS CalculateTotalPrice(bookingID, tourID, supplierID),
    customerID      INT NULL,
    employeeID      INT NOT NULL,
    paid            DECIMAL (10, 2) NULL,
    remaining       AS ISNULL(totalPrice, 0) - ISNULL(paid, 0),
    paymentDeadline AS CalculatePaymentDeadline(tourID, supplierID),
    fullyPaidDate   DATETIME NULL,
    CONSTRAINT FK_Booking_TourSupplier FOREIGN KEY (tourID, supplierID) REFERENCES TourSupplier (tourID, supplierID),
    CONSTRAINT FK_Booking_Customer FOREIGN KEY (customerID) REFERENCES Customer (customerID),
    CONSTRAINT FK_Booking_Employee FOREIGN KEY (employeeID) REFERENCES Employee (employeeID)
);

--Tạo trigger tự động cập nhật trạng thái Booking sau mỗi lần cập nhật Paid

CREATE TRIGGER UpdateStatusTrigger
ON Booking AFTER UPDATE AS BEGIN
    IF UPDATE(Paid) 
    BEGIN
        UPDATE Booking
        SET status = 
            CASE
                WHEN fullyPaidDate IS NOT NULL AND fullyPaidDate <= paymentDeadline THEN 'Success'
                WHEN fullyPaidDate IS NOT NULL AND fullyPaidDate > paymentDeadline THEN 'Expired'
                WHEN fullyPaidDate IS NULL AND GETDATE() > paymentDeadline THEN 'Expired'
                WHEN fullyPaidDate IS NULL AND GETDATE() <= paymentDeadline THEN 'Pending'
                ELSE 'Pending'
            END;
    END;
END;

CREATE TABLE Member (
    memberID   INT PRIMARY KEY NOT NULL,
    bookingID  INT NOT NULL,
    firstName  VARCHAR (100) NOT NULL,
    lastName   VARCHAR (100) NOT NULL,
    gender     INT CHECK (gender IN (0, 1)),
    DOB        DATE NOT NULL,
    height     INT NOT NULL, 
    multiplier AS (
        CASE
            WHEN height > 120 THEN 1
            WHEN height >= 60 THEN 0.7
            WHEN height > 0 THEN 0
            ELSE 'Unidentified'
        END
    ),
    FOREIGN KEY (bookingID) REFERENCES Booking (bookingID)
);

--Tạo Trigger tự động update slots còn trống nếu status của Booking chuyển sang 'Success'

CREATE TRIGGER UpdateAvailabilityTrigger
ON Booking AFTER UPDATE AS BEGIN
    IF UPDATE(status) AND EXISTS (SELECT 1 FROM inserted WHERE status = 'Success')
    BEGIN
        UPDATE TourSupplier
        SET availability = totalSlots - (
            SELECT COUNT(*) 
            FROM Member 
            WHERE bookingID IN (SELECT bookingID FROM inserted) AND height >= 60
        )
        WHERE tourID IN (SELECT tourID FROM inserted) AND supplierID IN (SELECT supplierID FROM inserted);
    END;
END;

CREATE TABLE Ticket (
    ticketID   INT PRIMARY KEY NOT NULL,
    memberID   INT NOT NULL,
    issuedTime DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (memberID) REFERENCES Member (memberID)
);

CREATE TABLE Payment (
    paymentID INT PRIMARY KEY NOT NULL,
    bookingID INT NOT NULL,
    amount FLOAT (53) NOT NULL,
    date DATETIME NOT NULL,
    method NVARCHAR (10) NOT NULL,
    PRIMARY KEY CLUSTERED (paymentID ASC),
    FOREIGN KEY (bookingID) REFERENCES Booking (bookingID),
    CHECK (method='cash' OR method='banking')
);

--Tạo Trigger cập nhật lượng tiền đã thanh toán (paid) của bảng Booking sau mỗi Payment 

CREATE TRIGGER UpdatePaidTrigger
ON Payment AFTER INSERT, UPDATE AS BEGIN
    UPDATE Booking
    SET paid = ISNULL(
        (SELECT SUM(amount) 
         FROM Payment 
         WHERE bookingID IN (SELECT bookingID FROM inserted)),
        0
    );
END;

CREATE TABLE Refund (
    refundID                INT PRIMARY KEY NOT NULL,
    bookingID               INT NOT NULL,
    name                    VARCHAR (255) NOT NULL,
    method                  VARCHAR (50) NOT NULL,
    bankingNumber           VARCHAR (255) NULL,
    bankName                VARCHAR (255) NULL,
    status                  VARCHAR (50) NOT NULL,
    transactionConfirmation VARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED (refundID ASC),
    FOREIGN KEY (bookingID) REFERENCES Booking (bookingID),
    CHECK (method='cash' OR method='banking')
);

CREATE TABLE Supplier (
    supplierID         INT PRIMARY KEY NOT NULL,
    name               NVARCHAR (255) NOT NULL,
    email              NVARCHAR (255) NULL,
    address            NVARCHAR (255) NULL,
    website            NVARCHAR (255) NULL,
    contactPerson      NVARCHAR (255) NULL,
    contactPersonPhone NVARCHAR (20) NULL,
    contactPersonEmail NVARCHAR (255) NULL
);

CREATE TABLE TourSupplier (
    tourID       INT PRIMARY KEY NOT NULL,
    supplierID   INT PRIMARY KEY NOT NULL,
    price        DECIMAL (10, 2) NOT NULL,
    startDay     DATE NOT NULL,
    endDay       DATE NOT NULL,
    description  NVARCHAR (MAX) NOT NULL,
    availability INT NOT NULL,
    totalSlots   INT NOT NULL,
    FOREIGN KEY (tourID) REFERENCES Tour (tourID),
    FOREIGN KEY (supplierID) REFERENCES Supplier (supplierID)
);

