# Task 2
/*rules about membership level upgrades:
- Only those members with a non-expired membership can receive an upgrade.
- Only the SILVER members can be upgraded to the GOLD level.
- Only the GOLD members can be upgraded to the PLATINUM level.
- There is no further upgrade for the PLATINUM members.
You will write a BEFORE UPDATE trigger called CHECK_MEMBERSHIP_UPDATE which
fires when a record is attempted to be updated in the Membership table. The trigger has to
check the conditions above to make sure that they are satisfied by the update request. If the
above conditions are satisfied, then the UPDATE statement is allowed to proceed. Otherwise,
a meaningful message needs to be displayed to the user. */

DROP TRIGGER IF EXISTS CHECK_MEMBERSHIP_UPDATE;
DELIMITER // 
CREATE TRIGGER CHECK_MEMBERSHIP_UPDATE
	BEFORE UPDATE ON membership
    FOR EACH ROW
BEGIN
	DECLARE msg VARCHAR(255);
    #Checks if only membership level is being changed
    IF OLD.MembershipLevel != NEW.MembershipLevel THEN
		#checks upgraded membership level is valid 
        IF NEW.MembershipLevel IN ('SILVER', 'GOLD', 'PLATINUM') THEN
			#Checks membership has not expired
			IF OLD.MemberExpDate <= CURDATE() THEN 
				SET msg = CONCAT('ERROR: ID# ',OLD.MembershipID,' has expired and cannot be upgraded');
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
			END IF;
			#Checks Silver memberships are only upgraded to Gold
			IF (NEW.MembershipLevel = 'GOLD')&(OLD.MembershipLevel <> 'SILVER') THEN
				SET msg = CONCAT('ERROR: Only SILVER memberships can be upgraded to GOLD. ID#', OLD.MembershipID, ' is ', OLD.MembershipLevel);
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
			END IF;
				#Checks Gold memberships are only upgraded to Platinum 
			IF (NEW.MembershipLevel = 'PLATINUM')&(OLD.MembershipLevel <> 'GOLD') THEN
				SET msg = CONCAT('ERROR: Only GOLD memberships can be upgraded to PLATINUM. ID#', OLD.MembershipID, ' is ', OLD.MembershipLevel);
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
			END IF;
				#Checks Platinum cannot upgrade further
			IF (OLD.MembershipLevel = 'PLATINUM') THEN
				SET msg = CONCAT('ERROR: ID#', OLD.MembershipID, ' is PLATINUM and cannot be upgraded further');
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
			END IF;
		ELSE
        SET msg = CONCAT('ERROR: ', NEW.MembershipLevel, ' is not a valid membership level');
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
		END IF;
    END IF;
END
// 

DELIMITER ;


#Task 3 
/*write a procedure called BrandNameCampaign which takes a brand
name as input and creates a new campaign with the top 5 most expensive products with that
brand name. The campaign will have a 4 week duration and will start after exactly two weeks
of its creation. For the campaign, the SILVER level members will receive a 10% discount, the
GOLD level members 20% and the PLATINUM level members 30%. If there are five or fewer
products with that brand name, all those products will be included in the campaign. */

#function that generates a unique campaign ID number
DROP FUNCTION IF EXISTS CreateCampaignID;
DELIMITER // 
CREATE FUNCTION CreateCampaignID ()
RETURNS INT
DETERMINISTIC
BEGIN 
	DECLARE CampaignIDnumber INT;
	SELECT MAX(CampaignID) INTO CampaignIDnumber
	FROM campaign;
	RETURN CampaignIDnumber+1;
END
// 

DELIMITER ;


#function that counts the number of products with specified brand name
DROP FUNCTION IF EXISTS isBrand;
DELIMITER // 
CREATE FUNCTION isBrand (brandName varchar(255))
RETURNS INT
DETERMINISTIC
BEGIN 
	DECLARE brandCount INT;
	SELECT count(ProductID) INTO brandCount
	FROM product
    WHERE Brand = brandName;
	RETURN brandCount;
END
// 

DELIMITER ;

# function that counts the number of campaigns between two dates
DROP FUNCTION IF EXISTS campExist;
DELIMITER // 
CREATE FUNCTION campExist(startDate Date, endDate Date, brandName varchar(255) )
RETURNS INT
DETERMINISTIC
BEGIN 
	DECLARE campCount INT;
	SELECT COUNT(c.CampaignID) INTO campCount
	FROM campaign c, discountdetails d, product p 
	WHERE c.CampaignID = d.CampaignID AND d.ProductID = p.ProductID
	AND c.CampaignStartDate = startDate AND c.CampaignEndDate = endDate
    AND p.Brand = brandName;
	RETURN campCount;
END
// 

DELIMITER ;

#Procedure that creates a new campaign 
DROP PROCEDURE IF EXISTS BrandNameCampaign;
DELIMITER // 
CREATE PROCEDURE BrandNameCampaign (IN brandName varchar(255))
BEGIN 
	# declare local variables, cursor and error handler
	DECLARE v_finished INT DEFAULT 0;
    DECLARE v_campID INT;
    DECLARE v_startDate DATE;
    DECLARE v_prodID INT;
    DECLARE V_endDate DATE;
    DECLARE msg VARCHAR(255);
    DECLARE brand_cur CURSOR FOR
		SELECT  ProductID
		FROM product
		WHERE Brand = brandName
		ORDER BY Price DESC
		LIMIT 5;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    
    SET v_campID = CreateCampaignID();
    SET v_startDate = DATE(NOW()) + INTERVAL 14 DAY;
    SET v_endDate = v_startDate + INTERVAL 28 DAY;
	
    IF (campExist(v_startDate, v_endDate, brandName) = 0) THEN -- checks campaign does not already exist
		IF (isBrand(brandName) > 0) THEN -- checks if brand exists
		# create campaign in campaign table
			INSERT INTO campaign VALUES(v_campID, v_startDate, v_endDate);
		# cursor to insert discount details into table
			OPEN brand_cur;
			REPEAT
				FETCH brand_cur INTO v_prodID;
				IF NOT(v_finished) = 1 THEN
				INSERT INTO discountdetails VALUES(v_prodID, v_campID, 'Platinum', 30);
				INSERT INTO discountdetails VALUES(v_prodID, v_campID, 'Gold', 20);
				INSERT INTO discountdetails VALUES(v_prodID, v_campID, 'Silver', 10);
				END IF;
				UNTIL v_finished
			END REPEAT;
			CLOSE brand_cur;
		ELSE
		# error message if brand does not exist
			SET msg = CONCAT('Error: No ',brandName,' products exist. A new campaign cannot be created.');
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
			END IF;
	ELSE
		#error message if campaign already exists for that brand between the proposed dates
		SET msg = CONCAT('Error: A campaign for ',brandName,' between the periods ', v_startDate, ' and ', v_endDate, ' already exists');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
		END IF;
END;
// 

DELIMITER ;
