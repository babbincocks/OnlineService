USE master
IF (SELECT COUNT(*) FROM sys.databases WHERE name = 'OnlineService') > 0
BEGIN
DROP DATABASE OnlineService
END

CREATE DATABASE OnlineService

GO
USE OnlineService

CREATE TABLE SubscriptionTypes
(
SubID INT IDENTITY(1,1),
SubType VARCHAR(20) NOT NULL,
PlanPrice MONEY NOT NULL
CONSTRAINT PK_SubID PRIMARY KEY (SubID)
)

CREATE TABLE Members
(
MemberID VARCHAR(10),
FirstName VARCHAR(20) NOT NULL,
MiddleName VARCHAR(20) NULL,
LastName VARCHAR(20) NOT NULL,
Gender VARCHAR(2) NOT NULL,
EMail VARCHAR(70) NULL,
Phone VARCHAR(15) NULL,
BirthDate DATE NOT NULL,
JoinDate DATE NOT NULL,
SubscriptionLevel INT NOT NULL,
[Current] BIT NOT NULL,
Notes VARCHAR(MAX)
CONSTRAINT PK_MemberID PRIMARY KEY (MemberID),
CONSTRAINT FK_Members_Subscriptions FOREIGN KEY (SubscriptionLevel) REFERENCES SubscriptionTypes(SubID),
CONSTRAINT CK_PrevJoin CHECK (JoinDate <= GETDATE()),
CONSTRAINT CK_PrevBirth CHECK (BirthDate < GETDATE())
)
;

CREATE TABLE Addresses
(
AddressID INT IDENTITY(1,1),
MemberID VARCHAR(10) NOT NULL,
MailAddress VARCHAR(50) NOT NULL,
BillAddress VARCHAR(50) NULL,
City VARCHAR(25),
[State] VARCHAR(20),
ZIPCode VARCHAR(10)
CONSTRAINT PK_AddressID PRIMARY KEY (AddressID)
CONSTRAINT FK_Addresses_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
)

CREATE TABLE Interests
(
InterestID INT IDENTITY(1,1),
Interest VARCHAR(40) NOT NULL
CONSTRAINT PK_InterestID PRIMARY KEY (InterestID),
CONSTRAINT UC_Interest UNIQUE (Interest)
)

CREATE TABLE MemberInterests
(
MemberID VARCHAR(10),
InterestID INT
CONSTRAINT PK_MemberInterestID PRIMARY KEY (MemberID, InterestID)
CONSTRAINT FK_MemberInterests_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_MemberInterests_Interests FOREIGN KEY (InterestID) REFERENCES Interests(InterestID)
)



CREATE TABLE Transactions
(
TranID INT IDENTITY(1,1),
TransactionDate DATE NOT NULL,
MemberID VARCHAR(10) NOT NULL,
Result VARCHAR(15) NOT NULL
CONSTRAINT PK_TranID PRIMARY KEY (TranID),
CONSTRAINT FK_Transactions_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT CK_ResultTypes CHECK (Result IN ('Approved', 'Declined', 'Invalid Card'))
)

CREATE TABLE [Events]
(
EventID INT IDENTITY(1,1),
EventTitle VARCHAR(100) NOT NULL,
SpeakerFirstName VARCHAR(20) NOT NULL,
SpeakerMiddleName VARCHAR(20) NULL,
SpeakerLastName VARCHAR(20) NOT NULL,
EventDate DATE NOT NULL
CONSTRAINT PK_EventID PRIMARY KEY (EventID)
)

CREATE TABLE MemberEvents
(
MemberID VARCHAR(10),
EventID INT
CONSTRAINT PK_MemberEventID PRIMARY KEY (MemberID, EventID),
CONSTRAINT FK_MemberEvents_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_MemberEvents_Events FOREIGN KEY (EventID) REFERENCES [Events](EventID)
)

CREATE TABLE CardPayment
(
CardID INT IDENTITY,
MemberID VARCHAR(10) NOT NULL,
CardType VARCHAR(60) NOT NULL,
CardNumber BIGINT NOT NULL,
SecurityCode SMALLINT NOT NULL,
ExpirationDate DATE NOT NULL
CONSTRAINT PK_CardMemberID PRIMARY KEY (CardID, MemberID),
CONSTRAINT FK_Payment_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
)


CREATE TABLE OtherPayment
(AccountID INT IDENTITY,
MemberID VARCHAR(10) NOT NULL,
AccountType VARCHAR(20) NOT NULL,
AccountNumber VARCHAR(15) NULL,
AccountEmail VARCHAR(70) NULL


CONSTRAINT PK_AccountID PRIMARY KEY (AccountID),
CONSTRAINT FK_Other_Members FOREIGN KEY (MemberID) REFERENCES Members (MemberID),
CONSTRAINT CK_AccountType CHECK (AccountType IN ('Bank', 'PayPal', 'Swipe', 'Google Wallet'))
)



CREATE TABLE AccountCharges
(
ChargeID INT IDENTITY,
TranID INT NOT NULL,
ChargeDate DATE NOT NULL,
ChargeTotal MONEY NOT NULL,
Success BIT NOT NULL

CONSTRAINT PK_ChargeTranID PRIMARY KEY (ChargeID, TranID),
CONSTRAINT FK_Charges_Transactions FOREIGN KEY (TranID) REFERENCES Transactions(TranID)
)

GO

CREATE TRIGGER trg_AccountOnlineEmail
ON OtherPayment
AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS (SELECT * FROM inserted WHERE AccountType <> 'Bank' AND AccountEmail IS NULL) 
		BEGIN
		RAISERROR ('Please insert the E-mail address associated with the online account.', 16, 1)
		ROLLBACK TRAN
		END

END

GO

CREATE TRIGGER trg_AccountBankNumber
ON OtherPayment
AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS (SELECT * FROM inserted WHERE AccountType = 'Bank' AND AccountNumber IS NULL)
	BEGIN
	RAISERROR ('Please insert the account number associated with this bank account.', 16, 1)
	ROLLBACK TRAN
	END
END
GO

INSERT SubscriptionTypes
VALUES ('2 Year Plan', 189.00), ('1 Year Plan', 99.00), ('Quarterly', 27.00), ('Monthly', 9.99)

INSERT Members
VALUES ('M0001', 'Otis', 'Brooke', 'Fallon', 'M', 'bfallon0@artisteer.com', '818-873-3863', '06-29-1971', '04-07-2017', 4, 1, 'nascetur ridiculus mus etiam vel augue vestibulum rutrum rutrum neque aenean auctor gravida sem praesent id'),
('M0002', 'Katee', 'Virgie', 'Gepp', 'F', 'vgepp1@nih.gov', '503-689-8066', '04-03-1972', '11-29-2017', 4, 1, 'a pede posuere nonummy integer non velit donec diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum primis in faucibus'),
('M0003', 'Lilla', 'Charmion', 'Eatttok', 'F', 'ceatttok2@google.com.br', '210-426-7426', '12-13-1975', '02-26-2017', 3, 1, 'porttitor lorem id ligula suspendisse ornare consequat lectus in est risus auctor sed tristique in tempus sit amet sem fusce consequat nulla nisl nunc nisl'),
('M0004', 'Ddene', 'Shelba', 'Clapperton', 'F', 'sclapperton3@mapquest.com', '716-674-1640', '02-19-1997', '11-05-2017', 3, 1, 'morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante nulla justo aliquam quis turpis'), 
('M0005', 'Audrye', 'Agathe', 'Dawks', 'F', 'adawks4@mlb.com', '305-415-9419', '02-07-1989', '01-15-2016', 4, 1, 'nisi at nibh in hac habitasse platea dictumst aliquam augue quam sollicitudin vitae consectetuer eget rutrum at lorem integer'), 
('M0006', 'Fredi', 'Melisandra', 'Burgyn', 'F', 'mburgyn5@cbslocal.com', '214-650-9837', '05-31-1956', '03-13-2017', 2, 1, 'congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien'), 
('M0007', 'Dimitri', 'Francisco', 'Bellino', 'M', 'fbellino6@devhub.com', '937-971-1026', '10-12-1976', '08-09-2017', 4, 1, 'eros vestibulum ac est lacinia nisi venenatis tristique fusce congue diam id ornare imperdiet sapien urna pretium'), 
('M0008', 'Enrico', 'Cleve', 'Seeney', 'M', 'cseeney7@macromedia.com', '407-445-6895', '02-29-1988', '09-09-2016', 2, 1, 'dapibus duis at velit eu est congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum'), 
('M0009', 'Marylinda', 'Jenine', 'O' + '''' + 'Siaghail', 'F', 'josiaghail8@tuttocitta.it', '206-484-6850', '02-06-1965', '11-21-2016', 2, 0, 'curae duis faucibus accumsan odio curabitur convallis duis consequat dui nec nisi volutpat eleifend donec ut dolor morbi vel lectus in quam'),
('M0010', 'Luce', 'Codi', 'Kovalski', 'M', 'ckovalski9@facebook.com', '253-159-6773', '03-31-1978', '12-22-2017', 4, 1, 'magna vulputate luctus cum sociis natoque penatibus et magnis dis parturient montes nascetur ridiculus mus'), 
('M0011', 'Claiborn', 'Shadow', 'Baldinotti', 'M', 'sbaldinottia@discuz.net', '253-141-4314', '12-26-1991', '03-19-2017', 4, 1, 'lorem integer tincidunt ante vel ipsum praesent blandit lacinia erat vestibulum sed magna at nunc commodo'), 
('M0012', 'Isabelle', 'Betty', 'Glossop', 'F', 'bglossopb@msu.edu', '412-646-5145', '02-17-1965', '04-25-2016', 3, 1, 'magna ac consequat metus sapien ut nunc vestibulum ante ipsum primis in faucibus orci luctus'), 
('M0013', 'Davina', 'Lira', 'Wither', 'F', 'lwitherc@smugmug.com', '404-495-3676', '12-16-1957', '03-21-2016', 2, 1, 'bibendum felis sed interdum venenatis turpis enim blandit mi in porttitor pede justo eu massa donec dapibus duis at'), 
('M0014', 'Panchito', 'Hashim', 'De Gregorio', 'M', 'hdegregoriod@a8.net', '484-717-6750', '10-14-1964', '01-27-2017', 4, 1, 'imperdiet sapien urna pretium nisl ut volutpat sapien arcu sed augue aliquam erat volutpat in congue etiam justo etiam pretium iaculis justo in hac habitasse'), 
('M0015', 'Rowen', 'Arvin', 'Birdfield', 'M', 'abirdfielde@over-blog.com', '915-299-3451', '01-09-1983', '10-06-2017', 4, 0, 'etiam pretium iaculis justo in hac habitasse platea dictumst etiam faucibus cursus urna ut tellus nulla ut erat id mauris vulputate elementum nullam varius') 

INSERT Interests (Interest)
VALUES ('Acting'), ('Video Games'), ('Crossword Puzzles'), ('Calligraphy'), ('Movies'), ('Restaurants'), ('Woodworking'), 
('Juggling'), ('Quilting'), ('Electronics'), ('Sewing'), ('Cooking'), ('Botany'), ('Skating'), ('Dancing'), 
('Coffee'), ('Foreign Languages'), ('Fashion'), ('Homebrewing'), ('Geneology'), ('Scrapbooking'), ('Surfing'), 
('Amateur Radio'), ('Computers'), ('Writing'), ('Singing'), ('Reading'), ('Pottery') 

INSERT MemberInterests
VALUES ('M0001', 1), ('M0001', 2), ('M0001', 3), ('M0002', 4), ('M0003', 5), ('M0003', 6), ('M0003', 7), 
('M0004', 8), ('M0004', 9), ('M0005', 10), ('M0006', 11), ('M0006', 12), ('M0006', 5), ('M0007', 13), ('M0007', 14), 
('M0008', 15), ('M0008', 16), ('M0008', 17), ('M0009', 18), ('M0010', 7), ('M0011', 19), ('M0011', 20), ('M0011', 21), 
('M0011', 5), ('M0012', 22), ('M0012', 23), ('M0013', 24), ('M0014', 25), ('M0014', 26), ('M0015', 27), ('M0015', 28) 

INSERT Addresses
VALUES ( 'M0001', '020 New Castle Way', NULL, 'Port Washington', 'New York', '11054'), 
( 'M0002', '8 Corry Parkway', 'P.O. Box 7088', 'Newton', 'Massachusetts', '2458'), 
( 'M0003', '39426 Stone Corner Drive', NULL, 'Peoria', 'Illinois', '61605'), 
( 'M0004', '921 Granby Junction', NULL, 'Oklahoma City', 'Oklahoma', '73173'), 
( 'M0005', '77 Butternut Parkway', NULL, 'Saint Paul', 'Minnesota', '55146'), 
( 'M0006', '821 Ilene Drive', NULL, 'Odessa', 'Texas', '79764'), 
( 'M0007', '1110 Johnson Court', NULL, 'Rochester', 'New York', '14624'), 
( 'M0008', '6 Canary Hill', 'P.O. Box 255', 'Tallahassee', 'Florida', '32309'), 
( 'M0009', '9 Buhler Lane', NULL, 'Bismarck', 'North Dakota', '58505'), 
( 'M0010', '99 Northwestern Pass', NULL, 'Midland', 'Texas', '79710'), 
( 'M0011', '69 Spenser Hill', NULL, 'Provo', 'Utah', '84605'), 
( 'M0012', '3234 Kings Court', 'P.O. Box 1233', 'Tacoma', 'Washington', '98424'), 
( 'M0013', '3 Lakewood Gardens Circle', NULL, 'Columbia', 'South Carolina', '29225'), 
( 'M0014', '198 Muir Parkway', NULL, 'Fairfax', 'Virginia', '22036'), 
( 'M0015', '258 Jenna Drive', NULL, 'Pensacola', 'Florida', '32520')

INSERT [Events]
VALUES 
('The History of Human Emotions', 'Tiffany', 'Watt', 'Smith', '01-12-2017'), 
('How Great Leaders Inspire Action', 'Simon', NULL, 'Sinek', '02-22-2017'), 
('The Puzzle of Motivation', 'Dan', NULL, 'Pink', '03-05-2017'), 
('Your Elusive Creative Genius', 'Elizabeth', NULL, 'Gilbert', '04-16-2017'), 
('Why are Programmers So Smart?', 'Andrew', NULL, 'Comeau', '05-01-2017') 

INSERT MemberEvents
VALUES ('M0001', 3), ('M0001', 4), ('M0001', 5), ('M0002', 1), ('M0002', 3), ('M0002', 4), ('M0003', 1), ('M0003', 2), 
('M0003', 3), ('M0003', 5), ('M0004', 1), ('M0004', 2), ('M0004', 3), ('M0004', 4), ('M0004', 5), ('M0005', 1), 
('M0005', 2), ('M0005', 3), ('M0005', 4), ('M0006', 1), ('M0006', 3), ('M0006', 4), ('M0007', 2), ('M0007', 3), 
('M0007', 4), ('M0008', 1), ('M0008', 2), ('M0008', 3), ('M0008', 4), ('M0009', 2), ('M0009', 3), ('M0009', 4), 
('M0010', 1), ('M0010', 2), ('M0011', 1), ('M0011', 2), ('M0012', 1), ('M0012', 3), ('M0012', 4), ('M0012', 5), 
('M0013', 1), ('M0013', 2), ('M0013', 5), ('M0014', 2), ('M0014', 3), ('M0014', 4), ('M0015', 1), ('M0015', 2), 
('M0015', 3), ('M0015', 4)



INSERT Transactions
VALUES ( '01-15-2016', 'M0005', 'Approved'), ( '02-15-2016', 'M0005', 'Approved'), 
('03-15-2016','M0005','Approved'), ('03-21-2016','M0013','Approved'), ('04-15-2016','M0005','Approved'), 
('04-25-2016','M0012','Approved'), ('05-15-2016','M0005','Approved'), ('06-15-2016','M0005','Approved'), 
('07-15-2016','M0005','Approved'), ('07-25-2016','M0012','Approved'), ('08-15-2016','M0005','Approved'), 
('09-09-2016','M0008','Approved'), ('09-15-2016','M0005','Approved'), ('10-15-2016','M0005','Approved'), 
('10-25-2016','M0012','Approved'), ('11-15-2016','M0005','Approved'), ('11-21-2016','M0009','Approved'), 
('12-15-2016','M0005','Approved'), ('01-15-2017','M0005','Approved'), ('01-25-2017','M0012','Approved'), 
('01-27-2017','M0014','Approved'), ('02-15-2017','M0005','Approved'), ('02-26-2017','M0003','Approved'), 
('02-27-2017','M0014','Approved'), ('03-13-2017','M0006','Approved'), ('03-15-2017','M0005','Approved'), 
('03-19-2017','M0011','Approved'), ('03-27-2017','M0014','Approved'), ('04-07-2017','M0001','Approved'), 
('04-15-2017','M0005','Approved'), ('04-19-2017','M0011','Approved'), ('04-25-2017','M0012','Approved'), 
('04-27-2017','M0014','Approved'), ('05-07-2017','M0001','Approved'), ('05-15-2017','M0005','Approved'), 
('05-19-2017','M0011','Approved'), ('05-26-2017','M0003','Approved'), ('05-27-2017','M0014','Approved'), 
('06-07-2017','M0001','Declined'), ('06-08-2017','M0001','Approved'), ('06-15-2017','M0005','Approved'),
('06-19-2017','M0011','Approved'), ('06-27-2017','M0014','Approved'), ('07-07-2017','M0001','Approved'), 
('07-15-2017','M0005','Approved'), ('07-19-2017','M0011','Declined'), ('07-20-2017','M0011','Approved'), 
('07-25-2017','M0012','Approved'), ('07-27-2017','M0014','Approved'), ('08-07-2017','M0001','Approved'), 
('08-09-2017','M0007','Approved'), ('08-15-2017','M0005','Approved'), ('08-19-2017','M0011','Approved'), 
('08-26-2017','M0003','Approved'), ('08-27-2017','M0014','Approved'), ('09-07-2017','M0001','Approved'), 
('09-09-2017','M0007','Approved'), ('09-09-2017','M0008','Approved'), ('09-15-2017','M0005','Approved'), 
('09-19-2017','M0011','Approved'), ('09-27-2017','M0014','Approved'), ('10-06-2017','M0015','Invalid Card'), 
('10-07-2017','M0001','Approved'), ('10-09-2017','M0007','Approved'), ('10-15-2017','M0005','Approved'), 
('10-19-2017','M0011','Approved'), ('10-25-2017','M0012','Approved'), ('10-27-2017','M0014','Approved'), 
('11-05-2017','M0004','Approved'), ('11-07-2017','M0001','Approved'), ('11-09-2017','M0007','Approved'), 
('11-15-2017','M0005','Approved'), ('11-19-2017','M0011','Approved'), ('11-26-2017','M0003','Declined'), 
('11-27-2017','M0003','Approved'), ('11-27-2017','M0014','Approved'), ('11-29-2017','M0002','Approved'), 
('12-07-2017','M0001','Approved'), ('12-09-2017','M0007','Approved'), ('12-15-2017','M0005','Approved'), 
('12-19-2017','M0011','Approved'), ('12-22-2017','M0010','Approved'), ('12-27-2017','M0014','Approved'), 
('12-29-2017','M0002','Approved'), ('01-07-2018','M0001','Approved'), ('01-09-2018','M0007','Approved'), 
('01-15-2018','M0005','Approved'), ('01-19-2018','M0011','Approved'), ('01-22-2018','M0010','Approved'), 
('01-25-2018','M0012','Approved'), ('01-27-2018','M0014','Approved')

SELECT * FROM Transactions
INSERT AccountCharges
VALUES (1, '01-15-2016', 9.99, 1), (2, '02-15-2016', 9.99, 1), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , ), 
(, '', , ), (, '', , ), (, '', , )

GO
CREATE FUNCTION [dbo].[fn_EventAttendance]
(
@BeginDate DATE,
@EndDate DATE
)
RETURNS TABLE
AS
RETURN 
SELECT EventTitle, COUNT(MemberID) [Attendance]
FROM MemberEvents ME
INNER JOIN [Events] E
ON ME.EventID = E.EventID
WHERE E.EventDate BETWEEN @BeginDate AND @EndDate
GROUP BY ME.EventID, E.EventTitle

GO

CREATE PROC sp_MemberBirthdays
AS
BEGIN
SELECT FirstName, MiddleName, LastName, BirthDate
FROM Members
WHERE DATEPART(MONTH, BirthDate) = DATEPART(MONTH, GETDATE())
END


GO
CREATE VIEW [dbo].[CurrentMemberContact]
AS

SELECT M.MemberID, FirstName, MiddleName, LastName, MailAddress, City, [State], ZIPCode, Phone, EMail
FROM Members M
INNER JOIN Addresses A
ON M.MemberID = A.MemberID
WHERE [Current] <> 0

GO

CREATE PROC sp_NewSignUps
(
@BeginDate DATE,
@EndDate DATE
)
AS
BEGIN

	SELECT CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, MAX(JoinDate)), 0) AS DATE) [Month], COUNT(MemberID) [Number of Sign Ups]
	FROM Members
	WHERE JoinDate BETWEEN @BeginDate AND @EndDate
	GROUP BY DATEPART(MONTH, JoinDate), DATEPART(YEAR, JoinDate)
END

GO

--EXEC sp_NewSignUps'01-01-2016', '12-31-2018'

GO

--CREATE PROC sp_BillRenewal
--AS
--BEGIN
--	IF (SELECT JoinDate FROM Members) =  (SELECT CAST(GETDATE() AS DATE))
--		BEGIN


--		END



--END

--GO

