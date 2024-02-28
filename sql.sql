create database test3
use test3

-- Create tables that dont have foreign keys first

CREATE TABLE [dbo].[Customer] (
    [customerID]  INT            IDENTITY (1, 1) NOT NULL,
    [name]        NVARCHAR (255) NOT NULL,
    [email]       NVARCHAR (255) NULL,
    [phoneNumber] NVARCHAR (20)  NOT NULL,
    PRIMARY KEY CLUSTERED ([customerID] ASC)
);



CREATE TABLE [dbo].[Employee] (
    [employeeID]  INT            IDENTITY (1, 1) NOT NULL,
    [firstName]   NVARCHAR (255) NOT NULL,
    [lastName]    NVARCHAR (255) NOT NULL,
    [role]        NVARCHAR (255) NOT NULL,
    [email]       NVARCHAR (255) NULL,
    [phoneNumber] NVARCHAR (20)  NOT NULL,
    PRIMARY KEY CLUSTERED ([employeeID] ASC)
);

CREATE TABLE [dbo].[Tour] (
    [tourID]  INT             NOT NULL,
    [name]    NVARCHAR (255)  NOT NULL,
    [picture] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([tourID] ASC),
	[description] NVARCHAR(MAX) NULL
);



CREATE TABLE [dbo].[Supplier] (
    [supplierID]  INT            NOT NULL,
    [name]        NVARCHAR (255) NOT NULL,
    [email]       NVARCHAR (255) NULL,
	[address] NVARCHAR (255) NULL, 
	[website] NVARCHAR (255) NULL,
	[contactPerson] NVARCHAR (255) NULL, 
	[contactPersonPhone] NVARCHAR (20) NULL,
	[contactPersonEmail] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([supplierID] ASC)
);

CREATE TABLE [dbo].[TourSupplier] (
    [tourID]       INT            NOT NULL,
    [supplierID]   INT            NOT NULL,
    [price]        DECIMAL(10, 2) NOT NULL,
    [startDay]     DATE           NOT NULL,
    [endDay]       DATE           NOT NULL,
    [description]  NVARCHAR(MAX)  NOT NULL,
    [availability] INT            NOT NULL,
    [totalSlots]   INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([tourID] ASC, [supplierID] ASC),
    FOREIGN KEY ([tourID]) REFERENCES [dbo].[Tour] ([tourID]),
    FOREIGN KEY ([supplierID]) REFERENCES [dbo].[Supplier] ([supplierID])
);


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
CREATE FUNCTION dbo.CalculatePaymentDeadline( @TourID INT, @SupplierID INT)
RETURNS DATE
AS
BEGIN
    DECLARE @StartDay DATE;

    -- Calculate the total multiplier for the specific BookingID
    SELECT @StartDay = startDay
    FROM TourSupplier
    WHERE tourID=@TourID AND supplierID=@SupplierID

--return the date that 2 days before the departure
RETURN DATEADD(DAY,-2,@StartDay)
END;


CREATE TABLE [dbo].[Booking] (
    [bookingID]       INT             NOT NULL PRIMARY KEY,
    [tourID]          INT             NOT NULL,
    [supplierID]      INT             NOT NULL,
    [date]            DATE            DEFAULT GETDATE(),
    [status]          VARCHAR (50)    DEFAULT 'Pending',
    [totalPrice]      AS              ([dbo].[CalculateTotalPrice]([bookingID],[tourID],[supplierID])),
    [customerID]      INT             NULL,
    [employeeID]      INT             NOT NULL,
    [paid]            DECIMAL (10, 2) NULL,
    [remaining] AS (ISNULL(totalPrice, 0) - ISNULL(paid, 0)),
    [paymentDeadline] AS             dbo.CalculatePaymentDeadline(TourID, SupplierID ),
    [fullyPaidDate]   DATETIME        NULL,
    CONSTRAINT [FK_Booking_TourSupplier] FOREIGN KEY ([tourID], [supplierID]) REFERENCES [dbo].[TourSupplier] ([tourID], [supplierID]),
    CONSTRAINT [FK_Booking_Customer] FOREIGN KEY ([customerID]) REFERENCES [dbo].[Customer] ([customerID]),
    CONSTRAINT [FK_Booking_Employee] FOREIGN KEY ([employeeID]) REFERENCES [dbo].[Employee] ([employeeID])
);

-- Create an AFTER UPDATE trigger
CREATE TRIGGER UpdateStatusTrigger
ON Booking
AFTER UPDATE
AS
BEGIN
    -- Check if the status column is updated or relevant columns are updated
    IF UPDATE(Paid) 
    BEGIN
        -- Update the status column based on the specified conditions
        UPDATE Booking
        SET status = 
            CASE
                WHEN fullyPaidDate IS NOT NULL AND fullyPaidDate <= paymentDeadline THEN 'Success'
                WHEN fullyPaidDate IS NOT NULL AND fullyPaidDate > paymentDeadline THEN 'Expired'
                WHEN fullyPaidDate IS NULL AND GETDATE() > paymentDeadline THEN 'Expired'
                WHEN fullyPaidDate IS NULL AND GETDATE() <= paymentDeadline THEN 'Pending'
                ELSE 'Pending'
            END;
    END
END;


CREATE TABLE [dbo].[Member] (
    [memberID]   INT PRIMARY KEY  NOT NULL,
    [bookingID]  INT              NOT NULL,
    [firstName]  VARCHAR (100)    NOT NULL,
    [lastName]   VARCHAR (100)    NOT NULL,
	[gender]     INT    CHECK ([gender] IN (0, 1)),
    [DOB]        DATE             NOT NULL,
    [height]     INT              NOT NULL, 
    [multiplier] AS            (
        CASE
            WHEN height > 120 THEN 1
            WHEN height >=60 THEN 0.7
			WHEN height >0 then 0
			ELSE 'Unidentified'
        END
    ),
    FOREIGN KEY ([bookingID]) REFERENCES [dbo].[Booking] ([bookingID]),
);


CREATE TRIGGER [dbo].[UpdateAvailabilityTrigger]
ON [dbo].[Booking]
AFTER UPDATE
AS
BEGIN
    IF UPDATE(status) AND EXISTS (SELECT 1 FROM inserted WHERE status = 'Success')
    BEGIN
        UPDATE TourSupplier
        SET availability = totalSlots- (
            SELECT COUNT(*) 
            FROM Member 
            WHERE bookingID IN (SELECT bookingID FROM inserted) AND height>=60
        )
        WHERE tourID IN (SELECT tourID FROM inserted) and supplierID IN (SELECT supplierID FROM inserted);
    END
END;
CREATE TABLE [dbo].[Ticket] (
    [ticketID]   INT      NOT NULL,
    [memberID]   INT      NOT NULL,
    [issuedTime] DATETIME NOT NULL,
    PRIMARY KEY CLUSTERED ([ticketID] ASC),
    FOREIGN KEY ([memberID]) REFERENCES [dbo].[Member] ([memberID])
);

CREATE TABLE [dbo].[Payment] (
    [paymentID] INT           NOT NULL,
    [bookingID] INT           NOT NULL,
    [amount]    FLOAT (53)    NOT NULL,
    [date]      DATETIME      NOT NULL,
    [method]    NVARCHAR (10) NOT NULL,
    PRIMARY KEY CLUSTERED ([paymentID] ASC),
    FOREIGN KEY ([bookingID]) REFERENCES [dbo].[Booking] ([bookingID]),
    CHECK ([method]='cash' OR [method]='banking')
);

CREATE TRIGGER UpdatePaidTrigger
ON Payment
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Booking
    SET paid = ISNULL(
        (SELECT SUM(amount) 
         FROM Payment 
         WHERE bookingID IN (SELECT bookingID FROM inserted)),
        0
    );
END;


CREATE TABLE [dbo].[Refund] (
    [refundID]                INT           NOT NULL,
    [bookingID]               INT           NOT NULL,
    [name]                    VARCHAR (255) NOT NULL,
    [method]                  VARCHAR (50)  NOT NULL,
    [bankingNumber]           VARCHAR (255) NULL,
    [bankName]                VARCHAR (255) NULL,
    [status]                  VARCHAR (50)  NOT NULL,
    [transactionConfirmation] VARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([refundID] ASC),
    FOREIGN KEY ([bookingID]) REFERENCES [dbo].[Booking] ([bookingID]),
    CHECK ([method]='cash' OR [method]='banking')
);








