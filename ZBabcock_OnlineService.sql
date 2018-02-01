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
('M0003', 'Lilla', 'Charmion', 'Eatttok', 'F', 'ceatttok2@google.com.br', '210-426-7426', '12-13-1975', '02-26-2017', 1, 'porttitor lorem id ligula suspendisse ornare consequat lectus in est risus auctor sed tristique in tempus sit amet sem fusce consequat nulla nisl nunc nisl'),
('M0004', 'Ddene', 'Shelba', 'Clapperton', 'F', 'sclapperton3@mapquest.com', '716-674-1640', '02-19-1997', '11-05-2017', 1, 'morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante nulla justo aliquam quis turpis'), 
('M0005', 'Audrye', 'Agathe', 'Dawks', 'F', 'adawks4@mlb.com', '305-415-9419', '02-07-1989', '01-15-2016', 1, 'nisi at nibh in hac habitasse platea dictumst aliquam augue quam sollicitudin vitae consectetuer eget rutrum at lorem integer'), 
('M0006', 'Fredi', 'Melisandra', 'Burgyn', 'F', 'mburgyn5@cbslocal.com', '214-650-9837', '05-31-1956', '03-13-2017', 1, 'congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien'), 
('M0007', 'Dimitri', 'Francisco', 'Bellino', 'M', 'fbellino6@devhub.com', '937-971-1026', '10-12-1976', '08-09-2017', 1, 'eros vestibulum ac est lacinia nisi venenatis tristique fusce congue diam id ornare imperdiet sapien urna pretium'), 
('M0008', 'Enrico', 'Cleve', 'Seeney', 'M', 'cseeney7@macromedia.com', '407-445-6895', '02-29-1988', '09-09-2016', 1, 'dapibus duis at velit eu est congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum'), 
('M0009', 'Marylinda', 'Jenine', 'O' + '''' + 'Siaghail', 'F', 'josiaghail8@tuttocitta.it', '206-484-6850', '02-06-1965', '11-21-2016', 0, 'curae duis faucibus accumsan odio curabitur convallis duis consequat dui nec nisi volutpat eleifend donec ut dolor morbi vel lectus in quam'),
('M0010', 'Luce', 'Codi', 'Kovalski', 'M', 'ckovalski9@facebook.com', '253-159-6773', '03-31-1978', '12-22-2017', 1, 'magna vulputate luctus cum sociis natoque penatibus et magnis dis parturient montes nascetur ridiculus mus'), 
('M0011', 'Claiborn', 'Shadow', 'Baldinotti', 'M', 'sbaldinottia@discuz.net', '253-141-4314', '12-26-1991', '03-19-2017', 1, 'lorem integer tincidunt ante vel ipsum praesent blandit lacinia erat vestibulum sed magna at nunc commodo'), 
('M0012', 'Isabelle', 'Betty', 'Glossop', 'F', 'bglossopb@msu.edu', '412-646-5145', '02-17-1965', '04-25-2016', 1, 'magna ac consequat metus sapien ut nunc vestibulum ante ipsum primis in faucibus orci luctus'), 
('M0013', 'Davina', 'Lira', 'Wither', 'F', 'lwitherc@smugmug.com', '404-495-3676', '12-16-1957', '03-21-2016', 1, 'bibendum felis sed interdum venenatis turpis enim blandit mi in porttitor pede justo eu massa donec dapibus duis at'), 
('M0014', 'Panchito', 'Hashim', 'De Gregorio', 'M', 'hdegregoriod@a8.net', '484-717-6750', '10-14-1964', '01-27-2017', 1, 'imperdiet sapien urna pretium nisl ut volutpat sapien arcu sed augue aliquam erat volutpat in congue etiam justo etiam pretium iaculis justo in hac habitasse'), 
('M0015', 'Rowen', 'Arvin', 'Birdfield', 'M', 'abirdfielde@over-blog.com', '915-299-3451', '01-09-1983', '10-06-2017', 0, 'etiam pretium iaculis justo in hac habitasse platea dictumst etiam faucibus cursus urna ut tellus nulla ut erat id mauris vulputate elementum nullam varius') 
