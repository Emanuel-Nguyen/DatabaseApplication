
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
 availability nvarchar(255), 
 FOREIGN KEY (tourID) REFERENCES Tour(tourID),
 FOREIGN KEY (supplierID) REFERENCES Supplier(supplierID)
);

-- Tạo bảng Employee --
CREATE TABLE Employee (
 employeeID int PRIMARY KEY,
 name nvarchar(255),
 role nvarchar(255),
 email nvarchar(255),
 phoneNumber nvarchar(20)
);

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
 method nvarchar(255),
 FOREIGN KEY (bookingID) REFERENCES Booking(bookingID)
);

-- Tạo bảng Participant --
CREATE TABLE Participant (
 participantID int PRIMARY KEY,
 bookingID int,
 name nvarchar(255),
 DOB date,
 FOREIGN KEY (bookingID) REFERENCES Booking(bookingID)
);

-- Tạo bảng Ticket --
CREATE TABLE Ticket (
 ticketID int PRIMARY KEY,
 participantID int,
 issuedTime datetime,
 FOREIGN KEY (participantID) REFERENCES Participant(participantID)
);

-- Tạo dữ liệu giả lập cho bảng Customer --
INSERT INTO Customer (customerID, name, email, phoneNumber)
VALUES
    (1, 'John Doe', 'john.doe@example.com', '123-456-7890'),
    (2, 'Jane Smith', 'jane.smith@example.com', '987-654-3210'),
    (3, 'Alice Johnson', 'alice.johnson@example.com', '555-123-4567'),
    (4, 'Bob Williams', 'bob.williams@example.com', '111-222-3333'),
    (5, 'Eva Brown', 'eva.brown@example.com', '999-888-7777');

-- Tạo dữ liệu giả lập cho bảng Supplier --
INSERT INTO Supplier (supplierID, name, email, phoneNumber)
VALUES
    (1, 'ABC Supplier', 'abc.supplier@example.com', '555-123-4567'),
    (2, 'XYZ Supplier', 'xyz.supplier@example.com', '111-999-8888'),
    (3, 'DEF Supplier', 'def.supplier@example.com', '777-888-9999'),
    (4, 'GHI Supplier', 'ghi.supplier@example.com', '333-444-5555'),
    (5, 'JKL Supplier', 'jkl.supplier@example.com', '222-666-7777');

-- Tạo dữ liệu giả lập cho bảng Tour --
INSERT INTO Tour (tourID, name, picture)
VALUES
    (1, 'Mountain Adventure', 0x0123456789ABCDEF),
    (2, 'Beach Getaway', 0xFEDCBA9876543210),
    (3, 'City Exploration', 0xABCDEF0123456789),
    (4, 'Historical Sites Tour', 0x9876543210FEDCBA),
    (5, 'Wildlife Safari', 0x0123456789ABCDEF);

-- Tạo dữ liệu giả lập cho bảng TourSupplier --
INSERT INTO TourSupplier (tourID, supplierID, price, startDay, endDay, discription, availability)
VALUES
    (1, 1, 500.00, '2024-03-01', '2024-03-07', 'Mountain tour with hiking activities', 'Limited spots available'),
    (2, 2, 800.00, '2024-04-01', '2024-04-10', 'Relaxing beach vacation with water sports', 'Open for booking'),
    (3, 3, 300.00, '2024-05-01', '2024-05-07', 'Explore the city landmarks and culture', 'Limited availability'),
    (4, 4, 400.00, '2024-06-01', '2024-06-10', 'Visit historical sites and learn about the past', 'Available for booking'),
    (5, 5, 600.00, '2024-07-01', '2024-07-15', 'Observe wildlife in their natural habitat', 'Limited spaces left');

-- Tạo dữ liệu giả lập cho bảng Employee --
INSERT INTO Employee (employeeID, name, role, email, phoneNumber)
VALUES
    (1, 'Manager One', 'Manager', 'manager1@example.com', '777-111-2222'),
    (2, 'Agent Two', 'Booking Agent', 'agent2@example.com', '333-444-5555'),
    (3, 'Coordinator Three', 'Coordinator', 'coordinator3@example.com', '999-888-7777'),
    (4, 'Assistant Four', 'Assistant', 'assistant4@example.com', '111-222-3333'),
    (5, 'Supervisor Five', 'Supervisor', 'supervisor5@example.com', '444-555-6666');

-- Tạo dữ liệu giả lập cho bảng Booking --
INSERT INTO Booking (bookingID, tourID, supplierID, customerID, date, status, totalPrice, paid, remaining, employeeID)
VALUES
    (1, 1, 1, 1, '2024-02-15', 'Confirmed', 500.00, 250.00, 250.00, 1),
    (2, 2, 2, 2, '2024-03-01', 'Pending', 800.00, 0.00, 800.00, 2),
    (3, 3, 3, 3, '2024-04-15', 'Confirmed', 300.00, 150.00, 150.00, 3),
    (4, 4, 4, 4, '2024-05-01', 'Pending', 400.00, 0.00, 400.00, 4),
    (5, 5, 5, 5, '2024-06-15', 'Confirmed', 600.00, 300.00, 300.00, 5);

-- Tạo dữ liệu giả lập cho bảng Payment --
INSERT INTO Payment (paymentID, bookingID, amount, date, method)
VALUES
    (1, 1, 250.00, '2024-02-20', 'Credit Card'),
    (2, 2, 800.00, '2024-03-02', 'PayPal'),
    (3, 3, 150.00, '2024-04-20', 'Bank Transfer'),
    (4, 4, 200.00, '2024-05-10', 'Cash'),
    (5, 5, 300.00, '2024-06-20', 'Credit Card');

-- Tạo dữ liệu giả lập cho bảng Participant --
INSERT INTO Participant (participantID, bookingID, name, DOB)
VALUES
    (1, 1, 'Participant One', '1990-05-15'),
    (2, 2, 'Participant Two', '1985-08-22'),
    (3, 3, 'Participant Three', '1998-02-10'),
    (4, 4, 'Participant Four', '1990-06-21'),
    (5, 5, 'Participant Five', '1992-11-30');

-- Tạo dữ liệu giả lập cho bảng Ticket --
INSERT INTO Ticket (ticketID, participantID, issuedTime)
VALUES
    (1, 1, '2024-02-22 08:30:00'),
    (2, 2, '2024-03-05 10:00:00'),
    (3, 3, '2024-04-18 15:45:00'),
    (4, 4, '2024-05-03 12:00:00'),
    (5, 5, '2024-06-16 09:30:00');