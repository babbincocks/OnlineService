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
CONSTRAINT PK_InterestID PRIMARY KEY CLUSTERED (InterestID),
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
Here I made a table for the less in-depth details on the different transactions in the database. It included the date of the transaction,
which member was involved, and how the transaction turned out. I put a check constraint on the Result column to limit the results to 
Approved, Declined, Invalid Card, Invalid Account, and Pending, as it shouldn't need anything more than that.
*/

CREATE TABLE Transactions
(
TranID INT IDENTITY(1,1),
TransactionDate DATE NOT NULL,
MemberID VARCHAR(10) NOT NULL,
Result VARCHAR(15) NOT NULL
CONSTRAINT PK_TranID PRIMARY KEY (TranID),
CONSTRAINT FK_Transactions_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT CK_ResultTypes CHECK (Result IN ('Approved', 'Declined', 'Invalid Card', 'Invalid Account', 'Pending'))
)


PRINT 'Transactions table created'

/*
Before I get to the more detailed half of the information on transactions, I needed to create a couple of tables containing the various ways
for members to pay for their subscriptions. I started this with the more common payment method, credit/debit cards. The table contains what
type of card it is (Mastercard, Visa, etc.), the number on the card (I initially had CardNumber as a BIGINT data type, as it took up less 
space, but it caused an issue with a functional requirement later on), the security code of the card, and when the card expires. 
Pretty much exactly what would be expected.
*/

CREATE TABLE CardPayment
(
CardID INT IDENTITY,
MemberID VARCHAR(10) NOT NULL,
CardType VARCHAR(60) NOT NULL,
CardNumber VARCHAR(70) NOT NULL,
SecurityCode SMALLINT NOT NULL,
ExpirationDate DATE NOT NULL
CONSTRAINT PK_CardMemberID PRIMARY KEY (CardID, MemberID),
CONSTRAINT FK_Payment_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
)


PRINT 'CardPayment table created'

/*
To handle the other types of payment, directly using a bank account or an online pay service (like Paypal), I put them together in one table.
The way that it works is that bank accounts need the AccountNumber column filled, while online pay services need the e-mail associated with
said account filled in. There's also a check constraint on the AccountType column to only have Bank put in or different online pay services,
which I allowed a few that came to mind.
*/

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

/*
The following table functions similarly to the Transactions table, but contains the more detailed information. It works pretty much the same
as how the SalesOrderHeader and SalesOrderDetail tables work in the AdventureWorks database. At least one charge is associated with each 
transaction, hence the foreign key TranID, the date that the account was charged, how much the account was charged, whether the charge was
successful, and finally a column to identify what account is going to be charged. The AccountIdentification column must have a value that
matches either the CardNumber column in the CardPayment table, the AccountNumber column in the OtherPayment table, or the AccountEmail column
in the OtherPayment table. This is handled later on.
*/

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

CREATE TABLE EventStaff
(
StaffID INT IDENTITY,
StaffType VARCHAR(20) NOT NULL,
StaffFirstName VARCHAR(20) NOT NULL,
StaffMiddleName VARCHAR(20) NULL,
StaffLastName VARCHAR(20) NOT NULL,
StaffEmail VARCHAR(70) NOT NULL,
StaffPhone VARCHAR(15) NOT NULL

CONSTRAINT PK_StaffID PRIMARY KEY (StaffID),
CONSTRAINT CK_StaffTypes CHECK (StaffType IN ('Organizer', 'Admin', 'Employee'))
)

PRINT 'EventStaff table created.'

CREATE TABLE Series
(
SeriesID INT IDENTITY, 
SeriesTitle VARCHAR(100) NOT NULL,
StartDate DATE NOT NULL,
EndDate DATE NULL,
AdminID INT NOT NULL,
SeriesDescription VARCHAR(MAX) NULL

CONSTRAINT PK_SeriesID PRIMARY KEY (SeriesID),
CONSTRAINT FK_Series_EventStaff FOREIGN KEY (AdminID) REFERENCES EventStaff(StaffID)
)

PRINT 'Series table created.'

/*
Coming up is another many-to-many relationship to show which members have gone to what events. First the table that contains all of the info
I was given on the events: the name of the event, the name of the speaker, and when the event happened.
*/

CREATE TABLE [Events]
(
EventID INT IDENTITY(1,1),
EventTitle VARCHAR(100) NOT NULL,
SeriesID INT NULL,
OrganizerID INT NOT NULL,
EventDate DATE NOT NULL,
EventDescription VARCHAR(MAX) NULL
CONSTRAINT PK_EventID PRIMARY KEY (EventID),
CONSTRAINT FK_Events_Series FOREIGN KEY (SeriesID) REFERENCES Series(SeriesID),
CONSTRAINT FK_Events_Staff FOREIGN KEY (OrganizerID) REFERENCES EventStaff(StaffID)
)

PRINT 'Events table created'

/*
Immediately afterwards, I created an intermediary table for Members and Events, like last time with MemberInterests.
*/

CREATE TABLE MemberEvents
(
MemberID VARCHAR(10),
EventID INT
CONSTRAINT PK_MemberEventID PRIMARY KEY (MemberID, EventID),
CONSTRAINT FK_MemberEvents_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_MemberEvents_Events FOREIGN KEY (EventID) REFERENCES [Events](EventID)
)

PRINT 'MemberEvents table created'


CREATE TABLE EventInterests
(
EventID INT,
InterestID INT

CONSTRAINT PK_InterestEventID PRIMARY KEY (EventID, InterestID),
CONSTRAINT FK_EventInt_Interests FOREIGN KEY (InterestID) REFERENCES Interests(InterestID),
CONSTRAINT FK_EventInt_Events FOREIGN KEY (EventID) REFERENCES [Events](EventID)
)

PRINT 'EventInterests table created.'

/*
I almost kept the member's email in the Members table, but then I realized that I needed it to be separate to fulfill a functional requirement,
so I moved it into it's own small table. All it contains is the ID of each member, and their email.

*/

CREATE TABLE MemberEmail
(
Email VARCHAR(70)
,MemberID VARCHAR(10)


CONSTRAINT PK_ContactMemberID PRIMARY KEY (Email),
CONSTRAINT FK_Contact_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
)
PRINT 'MemberEmail table created.'

/*
For pretty much all of the same reasons, I did the same thing with the member's phone numbers as I did with the member's emails. I also
added what type of phone it is, which I made optional, as none of the phone numbers given specified what kind of numbers they were, and
it's not THAT important, but it could be useful information if the company needed to make a call. The PhoneType column also has a check
constraint on it to limit to Home, Cell, and Work, as that's the standard with actual companies.
*/

CREATE TABLE MemberPhone
(
PhoneNumber VARCHAR(15),
MemberID VARCHAR(10),
PhoneType VARCHAR(5) NULL

CONSTRAINT PK_PhoneMemberID PRIMARY KEY (PhoneNumber, MemberID),
CONSTRAINT FK_Phone_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT CK_PhoneTypes CHECK (PhoneType IN ('Home', 'Cell', 'Work'))
)

PRINT 'MemberPhone table created.'

/*
As a final table, I created a table containing the login information for each member. I made the primary key a composite key on both PassID
and the MemberID so as to ensure that no members have two logins inserted on accident, as they should only have one. The actual login column
just links back to the Email table, and the PasswordHash is an encrypted hash of the member's password.
*/

CREATE TABLE MemberLoginInfo
(
PassID INT IDENTITY(1,1),
MemberID VARCHAR(10),
[Login] VARCHAR(70) NOT NULL,
PasswordHash VARCHAR(40) NOT NULL,
ChangeDate DATE NOT NULL

CONSTRAINT PK_PassID PRIMARY KEY (PassID, MemberID),
CONSTRAINT FK_Login_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_Login_Email FOREIGN KEY ([Login]) REFERENCES MemberEmail(Email)
)

PRINT 'MemberLoginInfo table created.'

GO

/*
Now we switch over to the triggers. This first trigger is on the OtherPayments table to ensure it works the way I intend. It checks to see
if what's being put into it is an online pay service, and if it is, that it has AccountEmail filled in, and just AccountEmail.
*/

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

	IF EXISTS (SELECT * FROM inserted WHERE AccountType <> 'Bank' AND AccountNumber IS NOT NULL)
		BEGIN
		RAISERROR ('Online pay service accounts should not have AccountNumber filled in. That is reserved for bank accounts.', 16, 1)
		ROLLBACK TRAN
		END
END

GO

PRINT 'E-mail check trigger created'

GO

/*
Pretty much the exact same trigger as the last one, but this trigger covers all of the opposite things in the OtherPayment table. So it
ensures that Bank accounts have their bank account number in, and ONLY their bank account number.
*/

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

	IF EXISTS (SELECT * FROM inserted WHERE AccountType = 'Bank' AND AccountEmail IS NOT NULL)
	BEGIN
	RAISERROR ('Bank accounts should not have an Email filled out here. That is reserved for only online pay service accounts.', 16, 1)
	ROLLBACK TRAN
	END
END
GO

PRINT 'Bank check trigger created'

GO

/*
This trigger works with the AccountCharges table in that ensuring that the AccountIdentification column contains a valid value from CardPayment
or OtherPayment to ensure that it works in the way that I want it to. It essentially functions as a foreign key that connects to three 
different columns instead of one.
*/

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

GO

/*
This trigger is one of the functional requirements for the database: The database should identify expired credit cards before it tries to 
bill to them. This trigger is set off whenever something is inserted into the AccountCharges table, and connects it to the CardPayment
table to check if the expiration date of the card that was just inserted/updated is less than today's date. If so, it raises an error, and
cancels out of the transactions. Since the other triggers set the AccountCharges table up to only have credit card numbers or other payment
type identifiers in this, this should work (and testing it with a later procedure showed that it did indeed work).
*/

CREATE TRIGGER trg_ExpiredCardCharge
ON AccountCharges
AFTER INSERT, UPDATE
AS
BEGIN

	IF (SELECT ExpirationDate FROM inserted i INNER JOIN CardPayment C ON C.CardNumber = i.AccountIdentification) < GETDATE()
	BEGIN
	RAISERROR ('This card is expired. A new card will need to be used before any charges can be made.', 16, 1)
	ROLLBACK TRAN
	END

END
GO
PRINT 'Expired Card trigger created.'

--UPDATE CardPayment
--SET ExpirationDate = '02-01-2018'
--WHERE MemberID = 'M0006'

GO
CREATE TRIGGER trg_SeriesAdmins
ON Series
AFTER INSERT, UPDATE
AS
BEGIN

	IF (SELECT AdminID FROM inserted i ) NOT IN (SELECT StaffID FROM EventStaff WHERE StaffType = 'Admin')
	BEGIN
	RAISERROR ('The inserted person for the admin of this series is not registered as a series admin.', 16, 1)
	ROLLBACK TRAN
	END

END
GO
PRINT 'Series admins trigger created.'
GO
--------------------------------------------INSERTS BEGIN HERE--------------------------------------------------

/*
All of my inserts go in pretty much the same order the tables they belong to were created in for the same reason: foreign key constraints.
They don't really require explaining, as that's already been covered.
*/
GO
INSERT SubscriptionTypes
VALUES ('2 Year Plan', 189.00), ('1 Year Plan', 99.00), ('Quarterly', 27.00), ('Monthly', 9.99), ('Free', 0.00)
GO
PRINT 'SubscriptionTypes inserts completed'
GO
INSERT Members
VALUES ('M0001', 'Otis', 'Brooke', 'Fallon', 'M', '06-29-1971', '04-07-2017', 4, 1, 'nascetur ridiculus mus etiam vel augue vestibulum rutrum rutrum neque aenean auctor gravida sem praesent id'),
('M0002', 'Katee', 'Virgie', 'Gepp', 'F', '04-03-1972', '11-29-2017', 4, 1, 'a pede posuere nonummy integer non velit donec diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum primis in faucibus'),
('M0003', 'Lilla', 'Charmion', 'Eatttok', 'F', '12-13-1975', '02-26-2017', 3, 1, 'porttitor lorem id ligula suspendisse ornare consequat lectus in est risus auctor sed tristique in tempus sit amet sem fusce consequat nulla nisl nunc nisl'),
('M0004', 'Ddene', 'Shelba', 'Clapperton', 'F', '02-19-1997', '11-05-2017', 3, 1, 'morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante nulla justo aliquam quis turpis'), 
('M0005', 'Audrye', 'Agathe', 'Dawks', 'F', '02-07-1989', '01-15-2016', 4, 1, 'nisi at nibh in hac habitasse platea dictumst aliquam augue quam sollicitudin vitae consectetuer eget rutrum at lorem integer'), 
('M0006', 'Fredi', 'Melisandra', 'Burgyn', 'F', '05-31-1956', '03-13-2017', 2, 1, 'congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien'), 
('M0007', 'Dimitri', 'Francisco', 'Bellino', 'M', '10-12-1976', '08-09-2017', 4, 1, 'eros vestibulum ac est lacinia nisi venenatis tristique fusce congue diam id ornare imperdiet sapien urna pretium'), 
('M0008', 'Enrico', 'Cleve', 'Seeney', 'M', '02-29-1988', '09-09-2016', 2, 1, 'dapibus duis at velit eu est congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum'), 
('M0009', 'Marylinda', 'Jenine', 'O' + '''' + 'Siaghail', 'F', '02-06-1965', '11-21-2016', 2, 0, 'curae duis faucibus accumsan odio curabitur convallis duis consequat dui nec nisi volutpat eleifend donec ut dolor morbi vel lectus in quam'),
('M0010', 'Luce', 'Codi', 'Kovalski', 'M', '03-31-1978', '12-22-2017', 4, 1, 'magna vulputate luctus cum sociis natoque penatibus et magnis dis parturient montes nascetur ridiculus mus'), 
('M0011', 'Claiborn', 'Shadow', 'Baldinotti', 'M', '12-26-1991', '03-19-2017', 4, 1, 'lorem integer tincidunt ante vel ipsum praesent blandit lacinia erat vestibulum sed magna at nunc commodo'), 
('M0012', 'Isabelle', 'Betty', 'Glossop', 'F', '02-17-1965', '04-25-2016', 3, 1, 'magna ac consequat metus sapien ut nunc vestibulum ante ipsum primis in faucibus orci luctus'), 
('M0013', 'Davina', 'Lira', 'Wither', 'F', '12-16-1957', '03-21-2016', 2, 1, 'bibendum felis sed interdum venenatis turpis enim blandit mi in porttitor pede justo eu massa donec dapibus duis at'), 
('M0014', 'Panchito', 'Hashim', 'De Gregorio', 'M', '10-14-1964', '01-27-2017', 4, 1, 'imperdiet sapien urna pretium nisl ut volutpat sapien arcu sed augue aliquam erat volutpat in congue etiam justo etiam pretium iaculis justo in hac habitasse'), 
('M0015', 'Rowen', 'Arvin', 'Birdfield', 'M', '01-09-1983', '10-06-2017', 4, 0, 'etiam pretium iaculis justo in hac habitasse platea dictumst etiam faucibus cursus urna ut tellus nulla ut erat id mauris vulputate elementum nullam varius') 
GO
PRINT 'Members inserts completed'
GO
INSERT CardPayment
VALUES ( 'M0001', 'AmericanExpress', 337941553240515, 4623, '09-01-2019'), ( 'M0002', 'Visa', 4041372553875903, 6232, '01-01-2020'), 
( 'M0003', 'Visa', 4041593962566, 7654, '03-01-2019'), ( 'M0004', 'JCB', 3559478087149594, 9265, '04-01-2019'), 
( 'M0005', 'JCB', 3571066026049076, 2354, '07-01-2018'), ( 'M0006', 'Diners-Club-Carte-Blanche', 30423652701879, 5449, '05-01-2018'), 
( 'M0007', 'JCB', 3532950215393858, 3753, '02-01-2019'), ( 'M0008', 'JCB', 3569709859937370, 9563, '03-01-2019'), 
( 'M0009', 'JCB', 3529188090740670, 2642, '05-01-2019'), ( 'M0010', 'JCB', 3530142576111598, 7543, '11-01-2019'), 
( 'M0011', 'MasterCard', 5108756299877313, 3677, '07-01-2018'), ( 'M0012', 'JCB', 3543168150106220, 4648, '06-01-2018'), 
( 'M0013', 'JCB', 3559166521684728, 3542, '10-01-2019'), ( 'M0014', 'Diners-Club-Carte-Blanche', 30414677064054, 0695, '06-01-2018'), 
( 'M0015', 'JCB', 3542828093985763, 1357, '03-01-2020')
GO
PRINT 'CardPayment inserts completed'
GO

INSERT Interests (Interest)
VALUES ('Acting'), ('Video Games'), ('Crossword Puzzles'), ('Calligraphy'), ('Movies'), ('Restaurants'), ('Woodworking'), 
('Juggling'), ('Quilting'), ('Electronics'), ('Sewing'), ('Cooking'), ('Botany'), ('Skating'), ('Dancing'), 
('Coffee'), ('Foreign Languages'), ('Fashion'), ('Homebrewing'), ('Geneology'), ('Scrapbooking'), ('Surfing'), 
('Amateur Radio'), ('Computers'), ('Writing'), ('Singing'), ('Reading'), ('Pottery'), ('Pyschology'), ('Ancient History'), ('Modern History'), 
('Board Games')
GO
PRINT 'Interests inserts completed'
GO
INSERT MemberInterests
VALUES ('M0001', 1), ('M0001', 2), ('M0001', 3), ('M0002', 4), ('M0003', 5), ('M0003', 6), ('M0003', 7), 
('M0004', 8), ('M0004', 9), ('M0005', 10), ('M0006', 11), ('M0006', 12), ('M0006', 5), ('M0007', 13), ('M0007', 14), 
('M0008', 15), ('M0008', 16), ('M0008', 17), ('M0009', 18), ('M0010', 7), ('M0011', 19), ('M0011', 20), ('M0011', 21), 
('M0011', 5), ('M0012', 22), ('M0012', 23), ('M0013', 24), ('M0014', 25), ('M0014', 26), ('M0015', 27), ('M0015', 28) 
GO
PRINT 'MemberInterests inserts completed'
GO
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
GO
PRINT 'Addresses inserts completed'
GO
INSERT EventStaff
VALUES ('Organizer', 'Tiffany', 'Watt', 'Smith', 'wattsup43@gmail.com', '541-555-1235'), 
('Organizer', 'Simon', NULL, 'Sinek', 'sinkingsimon@trubadello.net', '489-555-1709'), 
('Organizer', 'Dan', NULL, 'Pink', 'ilovebeingpurple@starpatrick.com', '897-555-5693'), 
('Organizer', 'Elizabeth', NULL, 'Gilbert', 'gilbeliz52@hotmail.com', '567-867-5309'), 
('Organizer', 'Andrew', NULL, 'Comeau', 'sqlismybreadandbutter@comeau.net', '678-555-4571') 
GO
PRINT 'EventStaff inserts completed.'
GO
INSERT [Events]
VALUES 
('The History of Human Emotions', NULL, 1, '01-12-2017', NULL), 
('How Great Leaders Inspire Action', NULL, 2, '02-22-2017', NULL), 
('The Puzzle of Motivation', NULL, 3, '03-05-2017', NULL), 
('Your Elusive Creative Genius', NULL, 4, '04-16-2017', NULL), 
('Why are Programmers So Smart?', NULL, 5, '05-01-2017', NULL) 
GO
PRINT 'Events inserts completed'
GO

INSERT MemberEvents
VALUES ('M0001', 3), ('M0001', 4), ('M0001', 5), ('M0002', 1), ('M0002', 3), ('M0002', 4), ('M0003', 1), ('M0003', 2), 
('M0003', 3), ('M0003', 5), ('M0004', 1), ('M0004', 2), ('M0004', 3), ('M0004', 4), ('M0004', 5), ('M0005', 1), 
('M0005', 2), ('M0005', 3), ('M0005', 4), ('M0006', 1), ('M0006', 3), ('M0006', 4), ('M0007', 2), ('M0007', 3), 
('M0007', 4), ('M0008', 1), ('M0008', 2), ('M0008', 3), ('M0008', 4), ('M0009', 2), ('M0009', 3), ('M0009', 4), 
('M0010', 1), ('M0010', 2), ('M0011', 1), ('M0011', 2), ('M0012', 1), ('M0012', 3), ('M0012', 4), ('M0012', 5), 
('M0013', 1), ('M0013', 2), ('M0013', 5), ('M0014', 2), ('M0014', 3), ('M0014', 4), ('M0015', 1), ('M0015', 2), 
('M0015', 3), ('M0015', 4)
GO
PRINT 'MemberEvents inserts completed'
GO
INSERT EventInterests
VALUES (1, 20), (1, 29), (1, 30), (1, 31), (2, 1), (2, 17), (2, 29), (2, 30), (2, 31), (3, 29), (4, 1), (4, 4), (4, 7), (4, 8), (4, 9), (4, 12), 
(4, 14), (4, 15), (4, 18), (4, 23), (4, 25), (4, 26), (4, 28), (5, 10), (5, 24), (5, 25), (5, 29)
GO
PRINT 'EventInterests inserts completed.'
GO
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
GO
PRINT 'Transactions inserts completed'
GO
/*
The only insert worth explaining a bit about is this insert. Due to the trigger I set up on the AccountCharges table,
multiple entries can't be made at once, like the other inserts were. As such, I set them up to insert individually. I don't think
this will really pose an issue, as this being actually done would probably be automated and not inserted simultaneously.
*/

INSERT AccountCharges VALUES (1, '01-15-2016', 9.99, '3571066026049076', 1) 
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
GO
PRINT 'AccountCharges inserts completed.'
GO
INSERT MemberEmail
VALUES ('bfallon0@artisteer.com', 'M0001'), ('vgepp1@nih.gov', 'M0002'), ('ceatttok2@google.com.br', 'M0003'), 
('sclapperton3@mapquest.com', 'M0004'), ('adawks4@mlb.com', 'M0005'), ('mburgyn5@cbslocal.com', 'M0006'), 
('fbellino6@devhub.com', 'M0007'), ('cseeney7@macromedia.com', 'M0008'), ('josiaghail8@tuttocitta.it', 'M0009'), 
('ckovalski9@facebook.com', 'M0010'), ('sbaldinottia@discuz.net', 'M0011'), ('bglossopb@msu.edu', 'M0012'), 
('lwitherc@smugmug.com', 'M0013'), ('hdegregoriod@a8.net', 'M0014'), ('abirdfielde@over-blog.com', 'M0015')
GO
PRINT 'MemberEmail inserts completed.'
GO
INSERT MemberPhone
VALUES ('818-873-3863', 'M0001', NULL), ('503-689-8066', 'M0002', NULL), ('210-426-7426', 'M0003', NULL), 
('716-674-1640', 'M0004', NULL), ('305-415-9419', 'M0005', NULL), ('214-650-9837', 'M0006', NULL), 
('937-971-1026', 'M0007', NULL), ('407-445-6895', 'M0008', NULL), ('206-484-6850', 'M0009', NULL), 
('253-159-6773', 'M0010', NULL), ('253-141-4314', 'M0011', NULL), ('412-646-5145', 'M0012', NULL), 
('404-495-3676', 'M0013', NULL), ('484-717-6750', 'M0014', NULL), ('915-299-3451', 'M0015', NULL)
GO
PRINT 'MemberPhone inserts completed.'
GO
INSERT MemberLoginInfo 
VALUES ('M0001', 'bfallon0@artisteer.com', '0x6FDE671F0A9FE8464E56B7437AA421B5', '02-01-2018'), ('M0002', 'vgepp1@nih.gov', '0xC77BF39F89640A6AEB1DA2AB34F1EF0C', '02-10-2018'), ('M0003', 'ceatttok2@google.com.br', '0x8F7C8C3380036FF264DF94A88F1B88C4', '02-05-2018'),
('M0004', 'sclapperton3@mapquest.com', '0xDB0D094E24D4AB4A27AC52E37E05E06A', '01-30-2018'), ('M0005', 'adawks4@mlb.com', '0xA217631C403F14D4481D91E3A171C68E', '01-26-2018'), ('M0006', 'mburgyn5@cbslocal.com', '0xD24E184228E9F8371C0F7B190D4841EB', '02-01-2018'), 
('M0007', 'fbellino6@devhub.com', '0x48850EC0E8FB821ACD0BA7466F70C929', '02-02-2018'), ('M0008', 'cseeney7@macromedia.com', '0xEAE7D9562FDFF6006045B871AB06A374', '01-22-2018'), ('M0009', 'josiaghail8@tuttocitta.it', '0x329BE5577BE302F648A22F2D7CA69CFB', '01-27-2018'), 
('M0010', 'ckovalski9@facebook.com', '0xE93F77ABA9EB9257D927E6C71DB5C23D', '02-01-2018'), ('M0011', 'sbaldinottia@discuz.net', '0x42F92EBA8E2901306C96E5C8C000BC25', '02-08-2018'), ('M0012', 'bglossopb@msu.edu', '0x856D9E07FF9DC93027FE33C4AA1FA7EB', '02-03-2018'), 
('M0013', 'lwitherc@smugmug.com', '0x144CB675F03640D68F2D3E8399D38A32', '01-16-2018'), ('M0014', 'hdegregoriod@a8.net', '0x586086033FD654F28626BFC31DA055B0', '01-27-2018'), ('M0015', 'abirdfielde@over-blog.com', '0x4E7A0E62373AAD8225F85EF86CC73976', '02-02-2018') 
GO
PRINT 'Member LoginInfo inserts completed.'

GO

-----------------------------END OF INSERTS----------------------------------------

/*
Here's my first functional requirement fulfilled: "Attendance per event over a given time frame. (Number of members at each event.)"
I had this done as a function, as a view wouldn't be able to accept the parameters, and this information feels like it might be used with 
other tables for analytical purposes, and making it a table-valued function allows that. It accepts two parameters to set up the window
of time it's observing, groups by the event, and counts up the number of members that had went to it in the MemberEvents table.
*/
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

/*
The next function is for the functional requirement "A list of members who are celebrating their birthday this month."
I made this one a table-valued function as well purely because the only reason that comes to mind to have it is so some kind of message can 
be sent to the members that have their birthday this month, and they might want to get their emails or phone numbers, so I kept it as a 
function so they can easily do that. I could've also done a view, but I tend to resort views for something that will be used often, while
this should only be used at most once a month.

It retrieves the members full name and birthdate with a WHERE clause that ensures that the month in that member's birthday matches the month
of the current date. Simple stuff.
*/

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

/*
For this functional requirement ("A complete contact list for current members with name, physical mailing address, phone number and e-mail."),
I used a view, as it seems like something that would not only be used at near-random intervals, but quite often as well, and chances are work
would need to be done with them, all of which a view is good for. In essence, it's just a simple query: join the Members table with the 
Addresses table, the MemberEmail table, and the MemberPhone table. From these it retrieves the full name of the members, all address info
except for the billing address, their phone and email, and it ensures that it only retrieves current members in the WHERE clause by only 
accepting members that don't have their Current column value be 0.
*/
CREATE VIEW [dbo].[CurrentMemberContact]
AS

SELECT M.MemberID, FirstName, MiddleName, LastName, MailAddress, City, [State], ZIPCode, PhoneNumber, Email
FROM Members M
INNER JOIN Addresses A
ON M.MemberID = A.MemberID
INNER JOIN MemberEmail ME
ON ME.MemberID = M.MemberID
INNER JOIN MemberPhone MP
ON MP.MemberID = M.MemberID
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

/*
A very simple view meets the requirements for the functional requirement "An e-mail list with the member name and e-mail." It joins the 
Members table with the MemberEmail table and retrieves the member's full name and email, and makes sure only current members are retrieved
in the WHERE clause.
*/

CREATE VIEW [dbo].[MemberEmails]
AS

SELECT FirstName, MiddleName, LastName, EMail
FROM Members M
INNER JOIN MemberEmail E
ON E.MemberID = M.MemberID
WHERE [Current] <> 0

GO

PRINT 'Member Email list view created.'


GO
/*
Alright, here's a big one. This is for the dreaded # 4 requirement: A solution for scheduled billing of members on the appropriate 
anniversary of the date they joined. To start off, I created a view to get together all of the information from the different tables that's
needed to properly insert a new record into both the Transactions table and the AccountCharges table. The first section of the view collects
everyone that has a monthly subscription, retrieving their ID, full name, the date they joined, what kind of subscription they have and
what it costs, and columns for all of the different ways they could be paying. The WHERE clause ensures that the Current flag is definitely
not false (so it only retrieves current members), the member has a monthly subscription (4 is the ID for a monthly subscription), and it
checks that today is the same day of the month as the day the member joined.
*/
CREATE VIEW [dbo].[RenewalList]
AS

SELECT	M.MemberID, M.FirstName, M.MiddleName, M.LastName, M.JoinDate, M.SubscriptionLevel, ST.PlanPrice, 
		CP.CardNumber, OP.AccountNumber, OP.AccountEmail 
FROM Members M
INNER JOIN SubscriptionTypes ST
ON ST.SubID = M.SubscriptionLevel
LEFT JOIN CardPayment CP
ON CP.MemberID = M.MemberID
LEFT JOIN OtherPayment OP
ON OP.MemberID = M.MemberID
WHERE M.[Current] <> 0 AND DATEPART(DAY, M.JoinDate) = DATEPART(DAY, GETDATE()) AND M.SubscriptionLevel = 4

UNION ALL

/*
All of the above is repeated again with some slight variations, and a full union is performed between the SELECT statements. What's 
different inbetween the two is that this next one is geared towards quarterly subscriptions (hence the 3), so it still gets the same day, 
but now it also checks if the current month is the same month as one of the months that are 3, 6, or 9 months ahead of the month that 
a member joined in.
*/

SELECT	M.MemberID, FirstName, MiddleName, LastName, JoinDate, SubscriptionLevel, PlanPrice, 
		CardNumber, AccountNumber, AccountEmail
FROM Members M
INNER JOIN SubscriptionTypes ST
ON ST.SubID = M.SubscriptionLevel
LEFT JOIN CardPayment CP
ON CP.MemberID = M.MemberID
LEFT JOIN OtherPayment OP
ON OP.MemberID = M.MemberID
WHERE [Current] <> 0 AND DATEPART(DAY, JoinDate) = DATEPART(DAY, GETDATE()) AND SubscriptionLevel = 3 
	AND DATEPART(MONTH, GETDATE()) IN ((SELECT (DATEPART(MONTH, M.JoinDate) + 3)), (SELECT (DATEPART(MONTH, JoinDate) + 6)),
  (SELECT (DATEPART(MONTH, JoinDate) + 9)))

UNION ALL 
/*
Similar to the other ones, except it's simpler with this one. All it checks is that the current month and day is the same as the date the
member joined, which logically should mean that it will be renewed every year on the same day.
*/
  SELECT	M.MemberID, FirstName, MiddleName, LastName, JoinDate, SubscriptionLevel, PlanPrice, 
		CardNumber, AccountNumber, AccountEmail
FROM Members M
INNER JOIN SubscriptionTypes ST
ON ST.SubID = M.SubscriptionLevel
LEFT JOIN CardPayment CP
ON CP.MemberID = M.MemberID
LEFT JOIN OtherPayment OP
ON OP.MemberID = M.MemberID

WHERE [Current] <> 0 AND DATEPART(DAY, JoinDate) = DATEPART(DAY, GETDATE()) AND SubscriptionLevel = 2
AND DATEPART(MONTH, GETDATE()) = DATEPART(MONTH, M.JoinDate)

UNION ALL
/*
This last union is probably the most complicated out of all of the SELECT statements in this, but not by much. This one does the same
as all of the other SELECT statements, except now it searches for bi-yearly subscriptions, hence the 1 in the WHERE clause. Like the yearly
subscription, it ensures that the day and month are the same, but now it has an added layer to it that checks the year of both the current
date and the member's join date with a modulus of 2, essentially checking if a year is divisible by 2. If it returns 1, it's an odd number;
if it returns 0, it's an even number. This guarantees that a customer will only show up in this if it's been some interval of 2 years since
they joined. I checked this with both even and odd numbers by changing the join date of one of the members to 2 years ago, and then changing
GETDATE() to a date in 2017, and it indeed worked.
*/
SELECT	M.MemberID, FirstName, MiddleName, LastName, JoinDate, SubscriptionLevel, PlanPrice, 
		CardNumber, AccountNumber, AccountEmail
FROM Members M
INNER JOIN SubscriptionTypes ST
ON ST.SubID = M.SubscriptionLevel
LEFT JOIN CardPayment CP
ON CP.MemberID = M.MemberID
LEFT JOIN OtherPayment OP
ON OP.MemberID = M.MemberID
WHERE [Current] <> 0 AND DATEPART(DAY, JoinDate) = DATEPART(DAY, GETDATE()) AND SubscriptionLevel = 1
AND DATEPART(MONTH, GETDATE()) = DATEPART(MONTH, M.JoinDate) AND (CAST(DATEPART(YEAR, GETDATE())AS INT) % 2) = 
																	(CAST(DATEPART(YEAR, JoinDate)AS INT) % 2)


GO

PRINT 'Preliminary view for Subscription Renewal stored procedure created.'

/*
And now for the big stored procedure. I tried approaching this from a lot of different directions, but I finally got it to work. To start
off, I took the results from the view I created in the last step, and put it into a temporary table with a variable-turned-column that
functions as a flag for members that have yet to have their subscription renewed so I could have a while loop that keeps running through 
what needs to be renewed. While there's anyone in the temp table that hasn't been updated, it runs through everyone that has yet to be updated,
retrieves the top row of people with a certain pay type (first credit cards, then bank accounts, and finally online pay services), then 
inserts the relevant info into the Transactions table: the date of the transaction (today), which member is being renewed, and then it just
goes to a transaction status of "Pending". 

After that it goes into the AccountCharges table, retrieves the ID of the transaction entry I just created (which is primarily why this goes
through one entry at a time instead of doing all of the entries at once, as SCOPE_IDENTITY can't really retrieve a group of ID's), the date
of the charge (today), the price for the member's subscription that's being focused on right now, their card number, and finally a couple 
of system functions, ROUND and RAND that takes the result of RAND and rounds it to either 0 or 1 to decide whether the charge to the 
member's account was successful or not. The procedure is basically all of what I just described (or... most of it. The temp table isn't 
recreated 3 times, for example), and doing it 3 times, once for each paytype. Since this one was more complicated than the rest of the
functional requirements, I left what I used to check if it was working down below this stored procedure.
*/
GO

CREATE PROC sp_BillRenewal
AS
BEGIN
	DECLARE @ToBeRenewed BIT = 1
	SELECT L.*,  @ToBeRenewed [ToBeRenewed]
	INTO #RenewalUpdates 
	FROM RenewalList L
	
	WHILE EXISTS (SELECT * FROM #RenewalUpdates WHERE ToBeRenewed <> 0)
		BEGIN
			WHILE (SELECT TOP 1 CardNumber FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND CardNumber IS NOT NULL) IS NOT NULL
			BEGIN
				INSERT Transactions
				VALUES (GETDATE(), (SELECT TOP 1 MemberID FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND CardNumber IS NOT NULL), 'Pending')
				INSERT AccountCharges
				VALUES (SCOPE_IDENTITY(), GETDATE(), 
						(SELECT TOP 1 PlanPrice FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND CardNumber IS NOT NULL), 
						(SELECT TOP 1 CardNumber FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND CardNumber IS NOT NULL), ROUND(RAND(), 0))
				UPDATE TOP (1) #RenewalUpdates 
				SET ToBeRenewed = 0
				WHERE CardNumber IS NOT NULL
				
			END
			WHILE (SELECT TOP 1 AccountNumber FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountNumber IS NOT NULL) IS NOT NULL
			BEGIN
				INSERT Transactions
				VALUES (GETDATE(), (SELECT TOP 1 MemberID FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountNumber IS NOT NULL), 'Pending')
				INSERT AccountCharges
				VALUES (SCOPE_IDENTITY(), GETDATE(), 
						(SELECT TOP 1 PlanPrice FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountNumber IS NOT NULL), 
						(SELECT TOP 1 AccountNumber FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountNumber IS NOT NULL), ROUND(RAND(), 0))
				UPDATE TOP (1) #RenewalUpdates 
				SET ToBeRenewed = 0
				WHERE AccountNumber IS NOT NULL
				
			END 
			WHILE (SELECT TOP 1 AccountEmail FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountEmail IS NOT NULL) IS NOT NULL
			BEGIN
				INSERT Transactions
				VALUES (GETDATE(), (SELECT TOP 1 MemberID FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountEmail IS NOT NULL), 'Pending')
				INSERT AccountCharges
				VALUES (SCOPE_IDENTITY(), GETDATE(), 
						(SELECT TOP 1 PlanPrice FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountEmail IS NOT NULL), 
						(SELECT TOP 1 AccountEmail FROM #RenewalUpdates WHERE ToBeRenewed <> 0 AND AccountEmail IS NOT NULL), ROUND(RAND(), 0))
				UPDATE TOP (1) #RenewalUpdates 
				SET ToBeRenewed = 0
				WHERE AccountEmail IS NOT NULL
				
			END 
			
		END
		
END

GO  

PRINT 'Subscription Renewal stored procedure created.'
/*
After running the script, you can uncomment the update and insert statements, and then I suggest running each one of those statements 
below individually, and the JoinDate in the update statement and the JoinDate in the insert statement (1-12-2018) should be updated to reflect
whatever day you're running this.
*/

--UPDATE Members
--SET JoinDate = '02-12-2017'
--WHERE MemberID = 'M0006'
--INSERT Members
--VALUES ('M0016', 'test', 'test', 'test', 'M', '01-01-2001', '01-12-2018', 4, 1, NULL)
--INSERT OtherPayment
--VALUES ('M0016', 'Bank', 'F234215890P367', NULL)

--SELECT * FROM RenewalList ORDER BY MemberID

--EXEC sp_BillRenewal

--SELECT * FROM Transactions T INNER JOIN AccountCharges A ON A.TranID = T.TranID WHERE MemberID IN ('M0006', 'M0016')


/*
This next table-valued function is for the functional requirement of "We need to see the company's monthly income from member payments 
over a given time frame." I used a table-valued function because I needed to have parameters, but this information seems like information
that would need to be modified or worked with every once in a while, so a table-valued function fits that best. Now how it works is very
similar (in fact, almost exactly the same) to the earlier stored procedure that retrieves how many members signed up per month. It retrieves
the month in the same manner, just using the TransactionDate column in the Transactions table instead. To retrieve how much the company
made in the month, it groups by the Month and then the Year of the TransactionDate column and sums together all of the totals
of the charges. To ensure that it doesn't also pick up on failed charge attempts, the WHERE clause specifies that the Result
in the Transactions table is set to "Approved", and the Success flag in AccountCharges is not 0.
*/

GO
CREATE FUNCTION fn_MonthlyIncome
(
@BeginDate DATE,
@EndDate DATE
)
RETURNS TABLE
AS
RETURN
SELECT CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, MAX(TransactionDate)), 0) AS DATE) [Month], SUM(ChargeTotal) [Income]
	FROM Transactions T
	INNER JOIN AccountCharges A
	ON A.TranID = T.TranID
	WHERE TransactionDate BETWEEN @BeginDate AND @EndDate AND Result = 'Approved' AND Success <> 0
	GROUP BY DATEPART(MONTH, TransactionDate), DATEPART(YEAR, TransactionDate)

GO

/*
1. On your new Members database, create a View that shows the list of all events held to date with the event name, description, organizer name 
and the number of people who attended.  Sort by event date descending. **Write the view so that it protects the design of the tables and fields 
it depends on from being changed. **  Test and verify this protection by writing DDL that will change two or more of the field names and 
remove at least one of the relationships used by the view.  Document the results in comments.
*/
--DROP VIEW AllEvents


CREATE VIEW AllEvents
WITH SCHEMABINDING
AS

SELECT TOP 9000000000000000 EventTitle,  MAX(StaffFirstName) [Organizer First Name], MAX(StaffMiddleName) [Organizer Middle Name], 
						MAX(StaffLastName) [Organizer Last Name], COUNT(MemberID) [Attendance], MAX(EventDescription) [Event Description]
FROM dbo.[Events] E
INNER JOIN dbo.MemberEvents ME
ON ME.EventID = E.EventID
INNER JOIN dbo.EventStaff S
ON S.StaffID = E.OrganizerID
GROUP BY EventTitle, EventDate
ORDER BY EventDate DESC

GO



--EXEC sp_rename 'Events.SpeakerFirstName', 'OrganizerFirstName', 'COLUMN'
--EXEC sp_rename 'Events.EventDate', 'TimeofEvent', 'COLUMN'

--Errors that arise from those two EXEC commands: 
--											Object 'Events.SpeakerFirstName' cannot be renamed because the object participates in enforced dependencies.
--											Object 'Events.EventDate' cannot be renamed because the object participates in enforced dependencies.

--ALTER TABLE MemberEvents
--DROP CONSTRAINT FK_MemberEvents_Events

--Getting rid of this foreign key constraint that is used in the view was not stopped by WITH SCHEMABINDING.


/*
#2.  On the Members database, create a view that will be used by all employees to view all information on ** current ** individual members with ** 
paid accounts ** and their address information. Updates will be performed through this view and ** it's important that none of these updates change 
the data in such a way that the member record is no longer visible through the view **.  Specifically, the member's current status and subscription 
level need to be protected against accidental changes.

*/


CREATE VIEW emp_CurrentMembers
AS

SELECT M.*, MailAddress, BillAddress, City, [State], ZIPCode
FROM Members M
INNER JOIN Addresses A
ON A.MemberID = M.MemberID
WHERE [Current] <> 0 AND SubscriptionLevel <> 5
WITH CHECK OPTION
GO
/*
UPDATE emp_CurrentMembers
SET SubscriptionLevel = 5
WHERE MemberID = 'M0001'

UPDATE emp_CurrentMembers
SET [Current] = 0
WHERE MemberID = 'M0001'
*/
/*
These two update statements return the following error: "The attempted insert or update failed because the target view either specifies 
WITH CHECK OPTION or spans a view that specifies WITH CHECK OPTION and one or more rows resulting from the operation did not qualify under 
the CHECK OPTION constraint", so the information should be safe.
*/

INSERT EventStaff
VALUES ('Admin', 'Patrick', 'Lucas', 'McKay', 'mccruiserxd@gmail.com', '207-555-1829')
,('Organizer', 'Rebecca', NULL, 'Boyce', 'oboyceherewego@yahoo.com', '462-555-5234')
,('Organizer', 'Troy', NULL, 'Yetter', '54dovesinthesea@scott.co.uk', '02-44-122-2145')
,('Organizer', 'Irving', 'Leonard', 'Finkel', 'ifinkel@britishmuseum.org', '423-555-1890')
,('Admin', 'Keith', NULL, 'Plunkett', 'sillystringwrestler@netscape.net', '623-555-7482')
,('Organizer', 'Trisha', 'Nicole', 'Valencian', 'tvalenc99@gmail.com', '542-555-1423')
,('Organizer', 'Jennifer', NULL, 'Ciris', 'pittsinpits@outlook.com', '891-555-5481')

INSERT Series
VALUES ('The Games We Play', '07-25-2017', '09-24-2017', 6, 'A series of lectures into the different psychological effects of playing various types of games humans play, and how they can affect the physiology of different people.')
INSERT Series
VALUES ('The Secrets of Your Home', '12-20-2017', NULL, 10, 'A series of lectures that cover different aspects of maintaining a house that many overlook, and clever tricks to make maintaining a house much easier.')

INSERT [Events]
VALUES ('"King Me" Kings', 1, 7, '07-25-2017', 'A look into how the game of checkers began, and how its influence over people over the ages has changed how people interact with each other.'), 
('From Pixels to (Near) Perfection', 1, 8, '08-11-2017', 'Speaker Troy Yetter broadly covers the history of video games, going into more detail on how and why the first video game came to be, where technology may be going from here, and why we may be going in that direction.'), 
('The Royal Game of Ur', 1, 9, '08-29-2017', 'The renowned Irving Finkel discusses the ancient Egyptian board game, Ur, how it was played, and how it may have affected the culture of ancient Egypt.'), 
('Why Do We Play Board Games?', 1, 6, '09-24-2017', 'An in-depth analysis of the different board games that people have made over the ages, the different formats, and most importantly, why we ever made them to begin with.')
,('What' + '''' +'s in Your Walls?', 2, 11, '12-20-2017', 'Speaker Trisha Valencian goes over the different risks that may come from buying older houses, namely what the walls are made of and what may be found inside, and provides efficient solutions to fixing any issues that may arise from them.')
,('Magic Attics', 2, 10, '01-07-2018', 'Speaker Keith Plunkett covers the many uses of attics that many don' + ''''+ 't consider, how you can physically expand upon them, and how they could potentially save your life.')
,('Furthering the Art of Feng Shui', 2, 12, '01-25-2018', 'Speaker Jennifer Ciris tells of the benefits of feng shui and how detrimental home life can be without proper planning on the setup of your living arrangements.')
INSERT EventInterests
VALUES (6, 29), (6, 30), (6, 31), (6, 32), (7, 2), (7, 10), (7, 24), (7, 29), (7, 31), (8, 17), (8, 29), (8, 30), (8, 32), (9, 29), (9, 30), (9, 31), 
(9, 32), (10, 7), (10, 12), (11, 5), (11, 7), (11, 13), (11, 23), (11, 24), (11, 25), (12, 7), (12, 9), (12, 11), (12, 18), (12, 29)

INSERT MemberEvents
VALUES ('M0001', 6), ('M0003', 6), ('M0006', 6), ('M0007', 6), ('M0010', 6), ('M0011', 6), ('M0013', 6), ('M0014', 6), ('M0001', 7), ('M0003', 7), 
('M0005', 7), ('M0008', 7), ('M0010', 7),('M0011', 7), ('M0013', 7), ('M0001', 8), ('M0002', 8), ('M0003', 8), ('M0006', 8), ('M0008', 8), ('M0010', 8), 
('M0011', 8), ('M0013', 8), ('M0014', 8), ('M0001', 9), ('M0002', 9), ('M0004', 9), ('M0008', 9), ('M0010', 9), ('M0012', 9), ('M0013', 9), ('M0014', 9),
('M0002', 10), ('M0003', 10), ('M0004', 10), ('M0006', 10), ('M0008', 10), ('M0010', 10), ('M0011', 10), ('M0014', 10), ('M0003', 11), ('M0006', 11), 
('M0007', 11), ('M0010', 11), ('M0011', 11), ('M0012', 11), ('M0013', 11), ('M0003', 12), ('M0004', 12), ('M0006', 12), ('M0007', 12), ('M0008', 12), ('M0011', 12), 
('M0013', 12), ('M0014', 12)
--SELECT EventID, COUNT(MemberID) FROM MemberEvents GROUP BY EventID
--SELECT * FROM [Events]
--SELECT * FROM Interests ORDER BY InterestID
--SELECT M.MemberID, I.* FROM MemberInterests M INNER JOIN Interests I ON I.InterestID = M.InterestID

