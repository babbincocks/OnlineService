USE master
IF (SELECT COUNT(*) FROM sys.databases WHERE name = 'OnlineService') > 0
BEGIN
DROP DATABASE OnlineService
END
/*
This first bit just checks in the repository of databases if this one exists, and if it does, gets rid of it.
*/
PRINT 'Database dropped.'

CREATE DATABASE OnlineService
/*
This is obvious.
*/
PRINT 'Database created'

GO
USE OnlineService

/*
I created this table, SubscriptionTypes, first, because it has no columns that are reliant on another table (foreign keys),
and the table after it, Members, DOES have a foreign key referencing it, and Members is referenced by a lot of different
tables. This table is best placed at the top of the chain of CREATE TABLE statements. It covers the minimum information needed when
talking about a subscription service: the plan type, and how much it costs, as that's really all that's needed.
*/

CREATE TABLE SubscriptionTypes
(
SubID INT IDENTITY(1,1),
SubType VARCHAR(20) NOT NULL,
PlanPrice MONEY NOT NULL
CONSTRAINT PK_SubID PRIMARY KEY (SubID)
)

PRINT 'SubscriptionTypes table created'

/*
The next table I created was the Members table, as it's referenced by so many tables in my database plan, and thus needs to exist for the
foreign keys in the other tables to work. It contains the member's full name, properly split up, their gender, date of birth, date of joining,
a foreign key column to SubscriptionTypes to show what type of subscription a member has, a flag for whether the member is still subscribed
or not, and a column for notes about the member. There's also two check constraints in this table: one on the JoinDate column and one on the
BirthDate column. Both check constraints restrict entries to be less than the current date, but the JoinDate check is more lax and accepts
dates that are equal to the current date.
*/

CREATE TABLE Members
(
MemberID VARCHAR(10),
FirstName VARCHAR(20) NOT NULL,
MiddleName VARCHAR(20) NULL,
LastName VARCHAR(20) NOT NULL,
Gender VARCHAR(2) NOT NULL,
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


PRINT 'Members table created'


/*
I created a table for the addresses of members next, as it's only reliant upon the Members table. That's the case for most of the tables, and
I'll specify if it's a different case for a different table from here on in the documentation. I created a composite key on the AddressID 
column and the MemberID column, since, theoretically speaking, two members signed up could live at the same address, but it'd probably happen
so little, that creating an intermediary table would be near-pointless. I put in two columns: MailAddress, and BillAddress. In other databases,
like AdventureWorks, these would be labeled "AddressLine1" and "AddressLine2", but I wanted BillAddress to only be used for P.O. Boxes and
such, so I labeled them in the way that I did. After that is the rest of the provided address information.
*/

CREATE TABLE Addresses
(
AddressID INT IDENTITY(1,1),
MemberID VARCHAR(10) NOT NULL,
MailAddress VARCHAR(50) NOT NULL,
BillAddress VARCHAR(50) NULL,
City VARCHAR(25),
[State] VARCHAR(20),
ZIPCode VARCHAR(10)
CONSTRAINT PK_AddressID PRIMARY KEY (AddressID, MemberID)
CONSTRAINT FK_Addresses_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
)

PRINT 'Addresses table created'

/*
I noticed that the Excel file we were given had set up the Members page to contain three columns for the interests of members, some of which
repeated multiple times, so I created two tables to handle this many-to-many relationship: an Interests table, which is made first, and then
a MemberInterests table to properly connect the Interests table to the Members table. The Interests table is very simple: an ID column for the
primary key, and then a column for the actual interests. There's a unique constraint on the Interest column to ensure no repeats are inserted.
It may seem that I might as well made this table one column (the Interest column), and I considered that, but decided against it so it'd
require less typing on the intermediary table.
*/

CREATE TABLE Interests
(
InterestID INT IDENTITY(1,1),
Interest VARCHAR(40) NOT NULL
CONSTRAINT PK_InterestID PRIMARY KEY (InterestID),
CONSTRAINT UC_Interest UNIQUE (Interest)
)

PRINT 'Interests table created'

/*
The intermediary table for Members and Interests, containing both of the ID's of the respective tables.
*/
CREATE TABLE MemberInterests
(
MemberID VARCHAR(10),
InterestID INT
CONSTRAINT PK_MemberInterestID PRIMARY KEY (MemberID, InterestID)
CONSTRAINT FK_MemberInterests_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_MemberInterests_Interests FOREIGN KEY (InterestID) REFERENCES Interests(InterestID)
)

PRINT 'MemberInterests table created'

/*

*/

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


PRINT 'Transactions table created'

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

PRINT 'Events table created'

CREATE TABLE MemberEvents
(
MemberID VARCHAR(10),
EventID INT
CONSTRAINT PK_MemberEventID PRIMARY KEY (MemberID, EventID),
CONSTRAINT FK_MemberEvents_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_MemberEvents_Events FOREIGN KEY (EventID) REFERENCES [Events](EventID)
)

PRINT 'MemberEvents table created'


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


PRINT 'CardPayment table created'

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


PRINT 'OtherPayment table created'


CREATE TABLE AccountCharges
(
ChargeID INT IDENTITY,
TranID INT NOT NULL,
ChargeDate DATE NOT NULL,
ChargeTotal MONEY NOT NULL,
AccountIdentification VARCHAR(70) NOT NULL,
Success BIT NOT NULL

CONSTRAINT PK_ChargeTranID PRIMARY KEY (ChargeID, TranID),
CONSTRAINT FK_Charges_Transactions FOREIGN KEY (TranID) REFERENCES Transactions(TranID)
)

PRINT 'AccountCharges table created'

CREATE TABLE MemberEmail
(
Email VARCHAR(70)
,MemberID VARCHAR(10)


CONSTRAINT PK_ContactMemberID PRIMARY KEY (Email, MemberID),
CONSTRAINT FK_Contact_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)

)

CREATE TABLE MemberPhone
(
PhoneNumber VARCHAR(15),
MemberID VARCHAR(10),
PhoneType VARCHAR(5) NULL

CONSTRAINT PK_PhoneMemberID PRIMARY KEY (PhoneNumber, MemberID),
CONSTRAINT FK_Phone_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT CK_PhoneTypes CHECK (PhoneType IN ('Home', 'Cell', 'Work'))
)

CREATE TABLE MemberLoginInfo
(
PassID INT,
MemberID VARCHAR(10),
[Login] VARCHAR(70) NOT NULL,
PasswordHash VARCHAR(40) NOT NULL

CONSTRAINT PK_PassID PRIMARY KEY (PassID),
CONSTRAINT FK_Login_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_Login_Email FOREIGN KEY ([Login]) REFERENCES MemberEmail(Email)
)

GO

CREATE TRIGGER trg_AccountOnlineEmail
ON OtherPayment
AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS (SELECT * FROM inserted WHERE AccountType <> 'Bank' AND AccountEmail IS NULL) 
		BEGIN
		RAISERROR ('Please insert the E-mail address associated with this online account.', 16, 1)
		ROLLBACK TRAN
		END

END

GO

PRINT 'E-mail check trigger created'

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

PRINT 'Bank check trigger created'

GO

CREATE TRIGGER trg_ExistingAccountID
ON AccountCharges
AFTER INSERT, UPDATE
AS
BEGIN
	IF (SELECT AccountIdentification FROM inserted) NOT IN (SELECT CardNumber FROM CardPayment) AND 
	(SELECT AccountIdentification FROM inserted) NOT IN (SELECT AccountNumber FROM OtherPayment) AND 
	(SELECT AccountIdentification FROM inserted) NOT IN (SELECT AccountEmail FROM OtherPayment)
		BEGIN
		RAISERROR ('That is not a valid way to identify the account. Either select the appropriate card number from the CardPayment table if a credit card was used, the appropriate account number from the OtherPayment table if a bank account was used, or the appropriate account email from the OtherPayment table if an online pay site was used.', 16, 1)
		ROLLBACK TRAN
		END

END
GO

PRINT 'AccountID check trigger on the AccountCharges table created'


INSERT SubscriptionTypes
VALUES ('2 Year Plan', 189.00), ('1 Year Plan', 99.00), ('Quarterly', 27.00), ('Monthly', 9.99), ('Free', 0.00)

PRINT 'SubscriptionTypes inserts completed'

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

PRINT 'Members inserts completed'

INSERT CardPayment
VALUES ( 'M0001', 'AmericanExpress', 337941553240515, 4623, '09-01-2019'), ( 'M0002', 'Visa', 4041372553875903, 6232, '01-01-2020'), 
( 'M0003', 'Visa', 4041593962566, 7654, '03-01-2019'), ( 'M0004', 'JCB', 3559478087149594, 9265, '04-01-2019'), 
( 'M0005', 'JCB', 3571066026049076, 2354, '07-01-2018'), ( 'M0006', 'Diners-Club-Carte-Blanche', 30423652701879, 5449, '05-01-2018'), 
( 'M0007', 'JCB', 3532950215393858, 3753, '02-01-2019'), ( 'M0008', 'JCB', 3569709859937370, 9563, '03-01-2019'), 
( 'M0009', 'JCB', 3529188090740670, 2642, '05-01-2019'), ( 'M0010', 'JCB', 3530142576111598, 7543, '11-01-2019'), 
( 'M0011', 'MasterCard', 5108756299877313, 3677, '07-01-2018'), ( 'M0012', 'JCB', 3543168150106220, 4648, '06-01-2018'), 
( 'M0013', 'JCB', 3559166521684728, 3542, '10-01-2019'), ( 'M0014', 'Diners-Club-Carte-Blanche', 30414677064054, 0695, '06-01-2018'), 
( 'M0015', 'JCB', 3542828093985763, 1357, '03-01-2020')

PRINT 'CardPayment inserts completed'


INSERT Interests (Interest)
VALUES ('Acting'), ('Video Games'), ('Crossword Puzzles'), ('Calligraphy'), ('Movies'), ('Restaurants'), ('Woodworking'), 
('Juggling'), ('Quilting'), ('Electronics'), ('Sewing'), ('Cooking'), ('Botany'), ('Skating'), ('Dancing'), 
('Coffee'), ('Foreign Languages'), ('Fashion'), ('Homebrewing'), ('Geneology'), ('Scrapbooking'), ('Surfing'), 
('Amateur Radio'), ('Computers'), ('Writing'), ('Singing'), ('Reading'), ('Pottery') 

PRINT 'Interests inserts completed'

INSERT MemberInterests
VALUES ('M0001', 1), ('M0001', 2), ('M0001', 3), ('M0002', 4), ('M0003', 5), ('M0003', 6), ('M0003', 7), 
('M0004', 8), ('M0004', 9), ('M0005', 10), ('M0006', 11), ('M0006', 12), ('M0006', 5), ('M0007', 13), ('M0007', 14), 
('M0008', 15), ('M0008', 16), ('M0008', 17), ('M0009', 18), ('M0010', 7), ('M0011', 19), ('M0011', 20), ('M0011', 21), 
('M0011', 5), ('M0012', 22), ('M0012', 23), ('M0013', 24), ('M0014', 25), ('M0014', 26), ('M0015', 27), ('M0015', 28) 

PRINT 'MemberInterests inserts completed'

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

PRINT 'Addresses inserts completed'

INSERT [Events]
VALUES 
('The History of Human Emotions', 'Tiffany', 'Watt', 'Smith', '01-12-2017'), 
('How Great Leaders Inspire Action', 'Simon', NULL, 'Sinek', '02-22-2017'), 
('The Puzzle of Motivation', 'Dan', NULL, 'Pink', '03-05-2017'), 
('Your Elusive Creative Genius', 'Elizabeth', NULL, 'Gilbert', '04-16-2017'), 
('Why are Programmers So Smart?', 'Andrew', NULL, 'Comeau', '05-01-2017') 

PRINT 'Events inserts completed'


INSERT MemberEvents
VALUES ('M0001', 3), ('M0001', 4), ('M0001', 5), ('M0002', 1), ('M0002', 3), ('M0002', 4), ('M0003', 1), ('M0003', 2), 
('M0003', 3), ('M0003', 5), ('M0004', 1), ('M0004', 2), ('M0004', 3), ('M0004', 4), ('M0004', 5), ('M0005', 1), 
('M0005', 2), ('M0005', 3), ('M0005', 4), ('M0006', 1), ('M0006', 3), ('M0006', 4), ('M0007', 2), ('M0007', 3), 
('M0007', 4), ('M0008', 1), ('M0008', 2), ('M0008', 3), ('M0008', 4), ('M0009', 2), ('M0009', 3), ('M0009', 4), 
('M0010', 1), ('M0010', 2), ('M0011', 1), ('M0011', 2), ('M0012', 1), ('M0012', 3), ('M0012', 4), ('M0012', 5), 
('M0013', 1), ('M0013', 2), ('M0013', 5), ('M0014', 2), ('M0014', 3), ('M0014', 4), ('M0015', 1), ('M0015', 2), 
('M0015', 3), ('M0015', 4)

PRINT 'MemberEvents inserts completed'

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

PRINT 'Transactions inserts completed'

INSERT AccountCharges
VALUES (1, '01-15-2016', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (2, '02-15-2016', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (3, '03-15-2016', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (4, '03-21-2016', 99.00, '3559166521684728', 1) 
INSERT AccountCharges VALUES (5, '2016-04-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (6, '2016-04-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (7, '2016-05-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (8, '2016-06-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (9, '2016-07-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (10, '2016-07-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (11, '2016-08-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (12, '2016-09-09', 99.00, '3569709859937370', 1) 
INSERT AccountCharges VALUES (13, '2016-09-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (14, '2016-10-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (15, '2016-10-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (16, '2016-11-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (17, '2016-11-21', 99.00, '3529188090740670', 1) 
INSERT AccountCharges VALUES (18, '2016-12-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (19, '2017-01-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (20, '2017-01-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (21, '2017-01-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (22, '2017-02-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (23, '2017-02-26', 27.00, '4041593962566', 1) 
INSERT AccountCharges VALUES (24, '2017-02-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (25, '2017-03-13', 99.00, '30423652701879', 1) 
INSERT AccountCharges VALUES (26, '2017-03-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (27, '2017-03-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (28, '2017-03-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (29, '2017-04-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (30, '2017-04-15',9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (31, '2017-04-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (32, '2017-04-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (33, '2017-04-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (34, '2017-05-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (35, '2017-05-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (36, '2017-05-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (37, '2017-05-26', 27.00, '4041593962566', 1) 
INSERT AccountCharges VALUES (38, '2017-05-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (39, '2017-06-07', 9.99, '337941553240515', 0) 
INSERT AccountCharges VALUES (39, '2017-06-07', 9.99, '337941553240515', 0) 
INSERT AccountCharges VALUES (39, '2017-06-07', 9.99, '337941553240515', 0) 
INSERT AccountCharges VALUES (40, '2017-06-08', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (41, '2017-06-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (42, '2017-06-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (43, '2017-06-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (44, '2017-07-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (45, '2017-07-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (46, '2017-07-19', 9.99, '5108756299877313', 0) 
INSERT AccountCharges VALUES (46, '2017-07-19', 9.99, '5108756299877313', 0) 
INSERT AccountCharges VALUES (46, '2017-07-19', 9.99, '5108756299877313', 0) 
INSERT AccountCharges VALUES (47, '2017-07-20', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (48, '2017-07-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (49, '2017-07-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (50, '2017-08-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (51, '2017-08-09', 9.99, '3532950215393858', 1) 
INSERT AccountCharges VALUES (52, '2017-08-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (53, '2017-08-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (54, '2017-08-26', 27.00, '4041593962566', 1) 
INSERT AccountCharges VALUES (55, '2017-08-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (56, '2017-09-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (57, '2017-09-09', 9.99, '3532950215393858', 1) 
INSERT AccountCharges VALUES (58, '2017-09-09', 99.00, '3569709859937370', 1) 
INSERT AccountCharges VALUES (59, '2017-09-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (60, '2017-09-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (61, '2017-09-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (62, '2017-10-06', 9.99, '3542828093985763', 0) 
INSERT AccountCharges VALUES (63, '2017-10-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (64, '2017-10-09', 9.99, '3532950215393858', 1) 
INSERT AccountCharges VALUES (65, '2017-10-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (66, '2017-10-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (67, '2017-10-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (68, '2017-10-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (69, '2017-11-05', 27.00, '3559478087149594', 1) 
INSERT AccountCharges VALUES (70, '2017-11-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (71, '2017-11-09', 9.99, '3532950215393858', 1) 
INSERT AccountCharges VALUES (72, '2017-11-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (73, '2017-11-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (74, '2017-11-26', 27.00, '4041593962566', 0) 
INSERT AccountCharges VALUES (74, '2017-11-26', 27.00, '4041593962566', 0) 
INSERT AccountCharges VALUES (74, '2017-11-26', 27.00, '4041593962566', 0) 
INSERT AccountCharges VALUES (75, '2017-11-27', 27.00, '4041593962566', 1) 
INSERT AccountCharges VALUES (76, '2017-11-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (77, '2017-11-29', 9.99, '4041372553875903', 1) 
INSERT AccountCharges VALUES (78, '2017-12-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (79, '2017-12-09', 9.99, '3532950215393858', 1) 
INSERT AccountCharges VALUES (80, '2017-12-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (81, '2017-12-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (82, '2017-12-22', 9.99, '3530142576111598', 1) 
INSERT AccountCharges VALUES (83, '2017-12-27', 9.99, '30414677064054', 1) 
INSERT AccountCharges VALUES (84, '2017-12-29', 9.99, '4041372553875903', 1) 
INSERT AccountCharges VALUES (85, '2018-01-07', 9.99, '337941553240515', 1) 
INSERT AccountCharges VALUES (86, '2018-01-09', 9.99, '3532950215393858', 1) 
INSERT AccountCharges VALUES (87, '2018-01-15', 9.99, '3571066026049076', 1) 
INSERT AccountCharges VALUES (88, '2018-01-19', 9.99, '5108756299877313', 1) 
INSERT AccountCharges VALUES (89, '2018-01-22', 9.99, '3530142576111598', 1) 
INSERT AccountCharges VALUES (90, '2018-01-25', 27.00, '3543168150106220', 1) 
INSERT AccountCharges VALUES (91, '2018-01-27', 9.99, '30414677064054', 1)

PRINT 'AccountCharges inserts completed'


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
PRINT 'Event Attendance user function created'
GO
CREATE FUNCTION [dbo].[fn_MemberBirthdays]
()
RETURNS TABLE
AS
RETURN
SELECT FirstName, MiddleName, LastName, BirthDate
FROM Members
WHERE DATEPART(MONTH, BirthDate) = DATEPART(MONTH, GETDATE())

GO
PRINT 'Member Birthdays user function created'
GO
CREATE VIEW [dbo].[CurrentMemberContact]
AS

SELECT M.MemberID, FirstName, MiddleName, LastName, MailAddress, City, [State], ZIPCode, Phone, EMail
FROM Members M
INNER JOIN Addresses A
ON M.MemberID = A.MemberID
WHERE [Current] <> 0

GO
PRINT 'Current Member Contact Info view created'
GO

/*
	The goal of the next stored procedure is to return "New member sign-ups per month over a given time frame." The way that it 
works is that it takes two parameters and sets that as the scale that the JoinDate of the members being checked can be 
contained within (which is what the WHERE statement is doing). It's grouping by the month and then the year of the 
JoinDate to properly split up the members into each individual, unique month that they joined in (I grouped by the year as 
well so as to not return all members that joined in all unique months combined [January 2017 being grouped in with January 
2018, for example]). 
	
	Now we get to the slightly intimidating part: what I did in the SELECT statement. As you can see, I 
have a DATEADD function, with a DATEDIFF function within it. The DATEDIFF statement within it checks the number of months 
there are between the maximum joindate that's contained within the group by clause (essentially just turning it into a 
representative of a specific month), and the earliest date there is in this datatype (which should be January 1, 1900). 
It then takes that number of months and adds it to the earliest date to get back to the month that the JoinDate was 
contained in. It's pretty much just a weird way to retrieve a date representative of the entire month, rather than the 
maximum date that someone joined within a month. Finally, I did a count on the MemberID's, as they're being grouped
by the month and year that they joined, so it should retrieve how many people joined in that specific month.
*/
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
--EXEC sp_NewSignUps '01-01-2016', '12-31-2018'
PRINT 'New Monthly Sign Ups stored procedure created'
GO

CREATE VIEW [dbo].[MemberEmails]
AS

SELECT FirstName, MiddleName, LastName, EMail
FROM Members M
INNER JOIN MemberEmail E
ON E.MemberID = M.MemberID
WHERE [Current] <> 0

GO



--SELECT DATEDIFF(MONTH, 0, JoinDate)
--FROM Members
--SELECT JoinDate
--FROM Members
--GO

--CREATE VIEW [dbo].[RenewalList]
--AS
--SELECT
--FROM Members

--CREATE PROC sp_BillRenewal
--AS
--BEGIN
--	IF (SELECT JoinDate FROM Members) =  (SELECT CAST(GETDATE() AS DATE))
--		BEGIN


--		END



--END

--GO

