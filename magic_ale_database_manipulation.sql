
#Task 4.1
/*Create an appropriate table for each of these relations (in BCNF), keeping the key
constraints in mind. */

#Create Tables
CREATE TABLE products(
	ProductID VARCHAR(45) NOT NULL,
	ProductType VARCHAR(45), 
    PackageType VARCHAR(45), 
    YearProduced YEAR,
    Price DECIMAL(10,2), 
    Brand VARCHAR(45),
    PRIMARY KEY (ProductID)
);
    
CREATE TABLE campaign(
	CampaignID VARCHAR(45) NOT NULL, 
    CampaignStartDate DATE, 
    CampaignEndDate DATE,
    PRIMARY KEY (CampaignID)
);

CREATE TABLE branch(
	BranchID VARCHAR(45) NOT NULL,
    PRIMARY KEY (BranchID)
    );
    
CREATE TABLE members(
	MemberID VARCHAR(45) NOT NULL, 
    FirstName VARCHAR (45), 
    LastName VARCHAR(45),
    eMail VARCHAR(45),
    MembershipLevel VARCHAR(45),
    MembershipExpDate DATE,
    BranchID VARCHAR(45) NOT NULL,
	PRIMARY KEY (MemberID),
    FOREIGN KEY (BranchID) REFERENCES branch(BranchID)
);
    
CREATE TABLE stock(
	ProductID VARCHAR(45) NOT NULL,
    BranchID VARCHAR(45) NOT NULL,
    StockLevel INT,
    PRIMARY KEY (ProductID, BranchID),
    FOREIGN KEY (ProductID) REFERENCES products(ProductID),
    FOREIGN KEY (BranchID) REFERENCES branch(BranchID)
);

CREATE TABLE discount(
	ProductID VARCHAR(45) NOT NULL,
    CampaignID VARCHAR(45) NOT NULL,
    MemberID VARCHAR(45) NOT NULL, 
	Discount DECIMAL(5,2),
    PRIMARY KEY (ProductID, CampaignID, MemberID), 
	FOREIGN KEY (ProductID) REFERENCES products(ProductID),
    FOREIGN KEY (CampaignID) REFERENCES campaign(CampaignID),
    FOREIGN KEY (MemberID) REFERENCES members(MemberID) 
);
 
 SHOW TABLES;
 
 #Task 4.2
 /*Insert five rows of (made-up) data into each table. Make sure that the data you enter
in these tables should be sufficient to return at least one row for each query in Task
5. */

 INSERT INTO products 
	VALUES 
		('P001','WINE', '750ML BOTTLE', 2010, 899.00, 'PENFOLDS GRANGE'),
		('P002', 'BEER', '6 PACK 375ML CAN', 2021, 22.50, 'VB'),
		('P003', 'BEER', '6 PACK 330ML BOTTLE', 2021, 26.95, 'ASAHI'),
		('P004', 'BEER', '24 CASE 330ML BOTTLE', 2021, 45.95, 'TOOHEYS NEW'),
        ('P005', 'BEER', '30 CASE 375ML CAN', 2021, 55.85, 'XXXX'),
        ('P006', 'SPIRIT', '700ML BOTTLE', 2020, 75.00, 'PETES WHISKEY');
    
INSERT INTO branch
	VALUES
		('B201'), ('B325'), ('B851'), ('B647'), ('B138'), ('B187'), ('B359');
        
 INSERT INTO members
	VALUES
		('M1011', 'SIMONE', 'SINGH', 'SSINGH@EMAIL.COM', 'GOLD', '2021-11-19', 'B647'),
        ('M10458', 'FRANK', 'BARKER', 'FBARK65@EMAIL.COM', 'SILVER', '2021-11-16', 'B359'),
        ('M25896', 'BOB', 'MCMAHON', 'BOBBY7@EMAIL.COM', 'GOLD', '2021-12-29', 'B851'),
        ('M72563', 'TIFFANY', 'RAM', 'RAMMY.T@EMAIL.COM', 'PLATINUM', '2021-10-05', 'B851'),
        ('M45965', 'MILLIE', 'SMITH', 'MS9989@EMAIL.COM', 'SILVER', '2021-09-30', 'B851');

INSERT INTO campaign
	VALUES
		('C4552','2021-12-01', '2021-12-31'),
        ('C8564', '2021-08-25', '2021-10-01'),
        ('C9685', '2020-04-01', '2020-05-05'),
        ('C3251', '2021-03-16', '2021-04-18'),
        ('C4646', '2020-09-27', '2020-10-27');
        
INSERT INTO stock
	VALUES
    ('P001', 'B201', 8),
    ('P001', 'B325', 1),
    ('P001', 'B187', 12),
    ('P002', 'B647', 22),
    ('P003', 'B138', 5),
    ('P005', 'B187', 2),
    ('P002', 'B359', 46);
    
INSERT INTO discount
	VALUES
		('P003', 'C4552', 'M1011', 0.20),
        ('P005', 'C8564', 'M1011', 0.15),
        ('P002', 'C9685', 'M72563', 0.15),
        ('P001', 'C3251', 'M45965', 0.10),
        ('P001', 'C4646', 'M45965', 0.05);

#Task 4.3
/*Display the content of each table using a SELECT * query. */

SELECT *
FROM branch;

SELECT *
FROM campaign;

SELECT *
FROM discount;

SELECT *
FROM members;
 
SELECT *
FROM products;

SELECT *
FROM stock;

#Task 5.1
/* List the branches (ID) of MA that have in stock at least 5 bottles of Penfold
Grange 2010.*/

SELECT BranchID
FROM stock s, products p
WHERE p.ProductID = s.ProductID
    AND p.Brand LIKE '%PENFOLDS GRANGE%'
    AND p.YearProduced = 2010
    AND s.StockLevel >= 5;

#Task 5.2
/* Simone Singh plans to do some last-minute Christmas shopping on
24/12/2021. List details of each beer that she will be entitled to get 20% discount on.*/

SELECT p.*
FROM products p, campaign c, discount d, members m
WHERE p.ProductID = d.ProductID AND c.CampaignID = d.CampaignID AND m.MemberID = d.MemberID
	AND m.FirstName LIKE '%SIMONE%' AND m.LastName LIKE '%SINGH%'
	AND DATE('2021-12-24') BETWEEN c.CampaignStartDate AND c.CampaignEndDate
    AND p.ProductType LIKE '%BEER%'
    AND d.Discount = 0.20;

#Task 5.3
/* Generate a list of all email addresses of members whose card will expire in
the month after the coming month. Thus, for instance, if the query is run in November
2121, it will list the emails of all members whose membership will expire in January
2122. The emails should be ordered by Branch ID, then by expiry date, and then by
the email address, all in ascending order. */

SELECT FirstName, LastName, BranchID, MembershipExpDate, eMail
FROM members
WHERE MONTH(MembershipExpDate) = MONTH(DATE_ADD(NOW(),INTERVAL 2 MONTH))
ORDER BY BranchID, MembershipExpDate, eMail ASC;

#Task 5.4
/* Determine how many times Penfold Grange 2010 has gone on sale since
Covid-19 related lockdown started (assume it to be March 01, 2020).*/

SELECT count(d.ProductID)
FROM products p, discount d, campaign c
WHERE p.ProductID = d.ProductID AND  c.CampaignID = d.CampaignID
	AND p.Brand LIKE '%PENFOLDS GRANGE%'
	AND p.YearProduced = 2010
    AND DATE('2020-03-01') <= c.CampaignStartDate;  
    