USE master
IF (SELECT COUNT(*) FROM sys.databases WHERE name = 'OnlineService') > 0
BEGIN
DROP DATABASE OnlineService
END

CREATE DATABASE OnlineService

GO
USE OnlineService


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
[Current] BIT NOT NULL,
Notes VARCHAR(MAX)
CONSTRAINT PK_MemberID PRIMARY KEY (MemberID)
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
CONSTRAINT PK_AddressMemberID PRIMARY KEY (AddressID, MemberID)
CONSTRAINT FK_Addresses_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
)

CREATE TABLE Interests
(
InterestID INT IDENTITY(1,1),
Interest VARCHAR(40) NOT NULL
CONSTRAINT PK_InterestID PRIMARY KEY (InterestID)
)

CREATE TABLE MemberInterests
(
MemberID VARCHAR(10),
InterestID INT
CONSTRAINT PK_MemberInterestID PRIMARY KEY (MemberID, InterestID)
CONSTRAINT FK_MemberInterests_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_MemberInterests_Interests FOREIGN KEY (InterestID) REFERENCES Interests(InterestID)
)

CREATE TABLE SubscriptionTypes
(
SubID INT IDENTITY(1,1),
SubType VARCHAR(20) NOT NULL,
PlanPrice MONEY NOT NULL
CONSTRAINT PK_SubID PRIMARY KEY (SubID)
)

CREATE TABLE Transactions
(
TranID INT IDENTITY(1,1),
TransactionType INT NOT NULL,
TransactionDate DATE NOT NULL,
MemberID VARCHAR(10) NOT NULL,
Total MONEY NOT NULL,
Result VARCHAR(15) NOT NULL
CONSTRAINT PK_TranID PRIMARY KEY (TranID),
CONSTRAINT FK_Transactions_SubscriptionTypes FOREIGN KEY (TransactionType) REFERENCES SubscriptionTypes(SubID),
CONSTRAINT FK_Transactions_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT CK_ResultTypes CHECK (Result IN ('Approved', 'Declined', 'Invalid Card'))
)

CREATE TABLE [Events]
(
EventID INT IDENTITY(1,1),
EventTitle VARCHAR(100) NOT NULL,
SpeakerFirstName VARCHAR(20) NOT NULL,
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

CREATE TABLE PaymentMethod
(
CardID INT IDENTITY(1,1),
MemberID VARCHAR(10),
CardType VARCHAR(100) NOT NULL,
CardNumber BIGINT NOT NULL,
ExpirationDate DATE NOT NULL
CONSTRAINT PK_CardMemberID PRIMARY KEY (CardID, MemberID),
CONSTRAINT FK_Payment_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
)

INSERT Members
VALUES ('M0001', 'Otis', 'Brooke', 'Fallon', 'M', 'bfallon0@artisteer.com', '818-873-3863', '06-29-1971', '04-07-2017', 1, 'nascetur ridiculus mus etiam vel augue vestibulum rutrum rutrum neque aenean auctor gravida sem praesent id'),
('M0002', 'Katee', 'Virgie', 'Gepp', 'F', 'vgepp1@nih.gov', '503-689-8066', '04-03-1972', '11-29-2017', 1, 'a pede posuere nonummy integer non velit donec diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum primis in faucibus'),
('M0003', 'Lilla', 'Charmion', 'Eatttok'