DROP PROCEDURE IF EXISTS `sp_change_info`;
DROP PROCEDURE IF EXISTS `sp_create_order`;
DROP PROCEDURE IF EXISTS `sp_create_users`;
DROP PROCEDURE IF EXISTS `sp_create_product`;
DROP PROCEDURE IF EXISTS `sp_create_promotion`;
DROP PROCEDURE IF EXISTS `sp_statistic_revenue`;
DROP PROCEDURE IF EXISTS `sp_statistic_bestsell`;
DROP PROCEDURE IF EXISTS `sp_statistic_bestuser`;
DROP PROCEDURE IF EXISTS `sp_statistic_nonrevenue`;


DELIMITER $$

/*Thay đổi thông tin info của usersm xóa củ và làm lại cái mới picture, userpicture*/
CREATE PROCEDURE `sp_change_info` (
	IN `user_id` INT, 
	IN `user_password` VARCHAR(191), 
	IN `user_description` VARCHAR(191), 
	IN `picture_url` VARCHAR(191))  
sp_change_info:BEGIN
	IF NOT EXISTS(SELECT * FROM users WHERE users.id = `user_id`) THEN
		LEAVE sp_change_info;
	END IF;
	START TRANSACTION;
		Update users SET users.Password = `user_password`, users.Description =  `user_description` WHERE users.id = `user_id`;
    		SET @PICTUREID := (SELECT ID_Picture FROM userspicture WHERE ID_Users = `user_id`);
		DELETE FROM userspicture WHERE ID_Users = `user_id`;
		DELETE FROM picture WHERE id = @PICTUREID;
		INSERT INTO picture(Url,IsDelete,created_at) VALUES(`picture_url`,0,CURRENT_TIMESTAMP);
		SET @PICTUREID := (SELECT MAX(id) FROM picture);
		INSERT INTO userspicture(ID_Users,ID_Picture,IsDelete,created_at) VALUES(`user_id`,@PICTUREID,0,CURRENT_TIMESTAMP);
	COMMIT;
END$$

/*Tạo hóa đơn, tự động cập nhật danh sách còn trong cart trong OrderProduct của user*/
CREATE PROCEDURE `sp_create_order` (
	IN `vDescription` varchar(191), 
	IN `vID_Promotion` int(10), 
	IN `vID_DeliveryPlace` int(10), 
	IN `vID_User` int(10),
	IN `vConfirmDate` date,
	IN `vIsPaied` tinyint(1),
	IN `vIsDelivered` tinyint(1),
	IN `vIsDelete` tinyint(1)
)  
BEGIN
	START TRANSACTION;	
		INSERT INTO `order`(Description,ID_Promotion,ID_DeliveryPlace,ID_User,ConfirmDate,IsPaied,IsDelivered,IsDelete,CreateDate) VALUES(`vDescription`,`vID_Promotion`,`vID_DeliveryPlace`,`vID_User`,`vConfirmDate`,`vIsPaied`,`vIsDelivered`,`vIsDelete`,CURRENT_TIMESTAMP);
		/*do sleep(10);*/
		SET @OrID := (SELECT MAX(id) FROM `order`);
		UPDATE `orderproduct` SET IsInCart = 0, ID_Order = @OrID WHERE IsDelete = 0 AND ID_User = `vID_User` AND `IsInCart` = 1;
	/*rollback;*/
	COMMIT;
END$$

/*Tạo user, tự động tạo picture and role of users*/
CREATE PROCEDURE `sp_create_users` (
	IN `vUsername` varchar(191), 
	IN `vPassword` varchar(191), 
	IN `vEmail` varchar(191), 
	IN `vDescription` varchar(191),
	IN `vIsDelete` tinyint(1),
	IN `vID_Role` tinyint(1),
	IN `picture_url` varchar(191)
)  
BEGIN
	START TRANSACTION;
		INSERT INTO `users`(Username,Password,Email,Description,IsDelete) VALUES(`vUsername`,`vPassword`,`vEmail`,`vDescription`,`vIsDelete`);
		SET @MAXID := (SELECT MAX(id) FROM `users`);
		INSERT INTO picture(Url,IsDelete,created_at) VALUES(`picture_url`,0,CURRENT_TIMESTAMP);
		SET @PICTUREID := (SELECT MAX(id) FROM picture);
		INSERT INTO userspicture(ID_Users,ID_Picture,IsDelete,created_at) VALUES(@MAXID,@PICTUREID,0,CURRENT_TIMESTAMP);
		INSERT INTO `user_role`(`ID_Users`, `ID_Role`, `IsDelete`) VALUES (@MAXID, `vID_Role`, 0);
		SELECT @MAXID as id;
	COMMIT;
END$$

/*Tạo create product, khởi tạo product nếu không tồn tại Id and tạo picture, size, color by list array*/
CREATE PROCEDURE `sp_create_product` (
	IN `vId` int(10),
	IN `vID_ProductCategory` int(10), 
	IN `vName` varchar(191),
	IN `vDescription` varchar(191),
	IN `vIsDelete` tinyint(1),
	IN `vPrice` varchar(191),
	IN `vDiscount` INT,
	IN `vListColor` varchar(191),
	IN `vListSize` varchar(191),
	IN `vListPicture` varchar(191)
)  
BEGIN
	START TRANSACTION;
	IF EXISTS (SELECT * FROM `product` WHERE id = `vId`) THEN
		UPDATE `product` SET ID_ProductCategory = `vID_ProductCategory`, Name = `vName`, Description=`vDescription`, IsDelete =`vIsDelete` WHERE id = `vId`;
		SET @MAXID := `vId`;
	ELSE
		INSERT INTO `product`(`ID_ProductCategory`, `Name`, `Description`, `IsDelete`) VALUES (`vID_ProductCategory`, `vName`, `vDescription`, `vIsDelete`);
		SET @MAXID := (SELECT MAX(id) FROM `product`);
	END IF;
	INSERT INTO `productprice`(`Price`, `StartDate`, `EndDate`, `IsDelete`, `ID_Product`, `Discount`, `created_at`) VALUES (`vPrice`, CURRENT_TIMESTAMP, NULL, 0, @MAXID, vDiscount, CURRENT_TIMESTAMP);
	set @valueColor :=`vListColor`; 
	WHILE (LOCATE(',', @valueColor) > 0 AND @valueColor <> '') 
		DO
		SET @V_DESIGNATION = SUBSTRING(@valueColor,1, LOCATE(',',@valueColor)-1); 
		SET @valueColor = SUBSTRING(@valueColor, LOCATE(',',@valueColor) + 1); 
		INSERT INTO `productcolor`(`ID_Product`, `ID_Color`, `IsDelete`) VALUES (@MAXID, @V_DESIGNATION, 0);
	END WHILE;
	set @valueSize :=`vListSize`; 
	WHILE (LOCATE(',', @valueSize) > 0 AND @valueSize <> '') 
		DO
		SET @V_DESIGNATION = SUBSTRING(@valueSize,1, LOCATE(',',@valueSize)-1); 
		SET @valueSize = SUBSTRING(@valueSize, LOCATE(',',@valueSize) + 1); 
		INSERT INTO `productsize`(`ID_Product`,`ID_Size`, `IsDelete`) VALUES (@MAXID, @V_DESIGNATION, 0);
	END WHILE;
	set @valuePicture :=`vListPicture`; 
	WHILE (LOCATE(',', @valuePicture) > 0 AND @valuePicture <> '') 
		DO
		SET @V_DESIGNATION = SUBSTRING(@valuePicture,1, LOCATE(',',@valuePicture)-1); 
		SET @valuePicture = SUBSTRING(@valuePicture, LOCATE(',',@valuePicture) + 1); 
		INSERT INTO picture(Url,IsDelete,created_at) VALUES(@V_DESIGNATION,0,CURRENT_TIMESTAMP);
		SET @PICTUREID := (SELECT MAX(id) FROM picture);
		INSERT INTO `productpicture`(`ID_Product`,`ID_Picture`,`IsDelete`) VALUES(@MAXID,@PICTUREID,0);
	END WHILE;
	select @MAXID as id;
	COMMIT;
END$$

/*Tạo khuyễn mãi với picture*/
CREATE PROCEDURE `sp_create_promotion` (
	IN `vId` int(10),
	IN `vDescription` varchar(191), 
	IN `vName` varchar(191),
	IN `vDiscount` varchar(191),
	IN `vBasePurchase` double(15,2),
	IN `vStartDate` date,
	IN `vEndDate` date,
	IN `vIsDelete` 	tinyint(1),
	IN `vPicture` varchar(191)
)  
BEGIN
	START TRANSACTION;
	IF EXISTS (SELECT * FROM `promotion` WHERE id = `vId`) THEN
		UPDATE `promotion` SET Description = `vDescription`, Name = `vName`, Discount=`vDiscount`, BasePurchase =`vBasePurchase`, StartDate =`vStartDate`, EndDate = `vEndDate`, IsDelete = `vIsDelete` WHERE id = `vId`;
		SET @MAXID := `vId`;
	ELSE
		INSERT INTO `promotion`(`Description`, `Name`, `Discount`, `BasePurchase`, `StartDate`, `EndDate`, `IsDelete`) VALUES(`vDescription`, `vName`, `vDiscount`, `vBasePurchase`, `vStartDate`, `vEndDate`, `vIsDelete`);
		SET @MAXID := (SELECT MAX(id) FROM `promotion`);
	END IF;	
	INSERT INTO picture(Url,IsDelete,created_at) VALUES(`vPicture`,0,CURRENT_TIMESTAMP);
	SET @PICTUREID := (SELECT MAX(id) FROM picture);
	INSERT INTO `promotionpicture`(`ID_Promotion`,`ID_Picture`,`IsDelete`) VALUES(@MAXID,@PICTUREID,0);
	select @MAXID as id;
	COMMIT;
END$$

/*Thống kê doanh thu theo khoản thời gian*/
CREATE PROCEDURE `sp_statistic_revenue` (
	IN `vStartDate` DATE,
	IN `vEndDate` DATE
)  
BEGIN
	SELECT o.id,o.CreateDate,IF(m.BasePurchase IS NOT NULL AND m.BasePurchase <= SUM(op.Count*(pr.Price * (100- pr.Discount) / 100)),SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))*(100-m.Discount)/100,SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))) Price FROM `order` o JOIN `orderproduct` as op ON o.id = op.ID_Order
	JOIN `product` p ON op.ID_Product = p.id
	JOIN `productprice` pr ON p.id = pr.ID_Product AND ((pr.StartDate <= o.CreateDate AND pr.EndDate > o.CreateDate) || (pr.StartDate <= o.CreateDate AND pr.EndDate IS NULL))
	LEFT JOIN `promotion` m ON o.ID_Promotion = m.id
	WHERE  `vStartDate` <= o.CreateDate AND o.CreateDate <= `vEndDate` AND o.IsPaied = 1
	GROUP BY o.CreateDate,o.id
	ORDER BY o.CreateDate ASC;
END$$

/*Thống kê không phải doanh thu theo khoản thời gian*/
CREATE PROCEDURE `sp_statistic_nonrevenue` (
	IN `vStartDate` DATE,
	IN `vEndDate` DATE
)  
BEGIN
	/*SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;*/
	SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED ;
	START TRANSACTION;
		SELECT o.id,o.CreateDate,IF(m.BasePurchase IS NOT NULL AND m.BasePurchase <= SUM(op.Count*(pr.Price * (100- pr.Discount) / 100)),SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))*(100-m.Discount)/100,SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))) Price FROM `order` o 
		LEFT JOIN `orderproduct` as op ON o.id = op.ID_Order
		LEFT JOIN `product` p ON op.ID_Product = p.id
		LEFT JOIN `productprice` pr ON p.id = pr.ID_Product AND ((pr.StartDate <= o.CreateDate AND pr.EndDate > o.CreateDate) || (pr.StartDate <= o.CreateDate AND pr.EndDate IS NULL))
		LEFT JOIN `promotion` m ON o.ID_Promotion = m.id
		WHERE  `vStartDate` <= o.CreateDate AND o.CreateDate <= `vEndDate` AND o.IsPaied <> 1
		GROUP BY o.CreateDate,o.id
		ORDER BY o.CreateDate ASC;
	COMMIT;

END$$

/*Thống kê theo sản phẩm theo khoản thời gian*/
CREATE PROCEDURE `sp_statistic_bestsell` (
	IN `vStartDate` DATE,
	IN `vEndDate` DATE
)  
BEGIN
	SELECT p.id,o.CreateDate,p.Name,count(DISTINCT o.id) as `count`,IF(m.BasePurchase IS NOT NULL AND m.BasePurchase <= SUM(op.Count*(pr.Price * (100- pr.Discount) / 100)),SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))*(100-m.Discount)/100,SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))) Price FROM `order` o JOIN `orderproduct` as op ON o.id = op.ID_Order
	JOIN `product` p ON op.ID_Product = p.id
	JOIN `productprice` pr ON p.id = pr.ID_Product AND ((pr.StartDate <= o.CreateDate AND pr.EndDate > o.CreateDate) || (pr.StartDate <= o.CreateDate AND pr.EndDate IS NULL))
	LEFT JOIN `promotion` m ON o.ID_Promotion = m.id
	WHERE  `vStartDate` <= o.CreateDate AND o.CreateDate <= `vEndDate` AND o.IsPaied = 1
	GROUP BY o.CreateDate,p.id,p.Name
	ORDER BY o.CreateDate ASC;
END$$

/*Thống kê theo khách hàng theo khoản thời gian*/
CREATE PROCEDURE `sp_statistic_bestuser` (
	IN `vStartDate` DATE,
	IN `vEndDate` DATE
)  
BEGIN
	SELECT u.Username,count(DISTINCT o.id) as `count`,IF(m.BasePurchase IS NOT NULL AND m.BasePurchase <= SUM(op.Count*(pr.Price * (100- pr.Discount) / 100)),SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))*(100-m.Discount)/100,SUM(op.Count*(pr.Price * (100- pr.Discount) / 100))) Price FROM `order` o JOIN `orderproduct` as op ON o.id = op.ID_Order
	JOIN `product` p ON op.ID_Product = p.id
	JOIN `productprice` pr ON p.id = pr.ID_Product AND ((pr.StartDate <= o.CreateDate AND pr.EndDate > o.CreateDate) || (pr.StartDate <= o.CreateDate AND pr.EndDate IS NULL))
	LEFT JOIN `promotion` m ON o.ID_Promotion = m.id
	JOIN `users` u ON  o.ID_User = u.id
	WHERE  `vStartDate` <= o.CreateDate AND o.CreateDate <= `vEndDate` AND o.IsPaied = 1
	GROUP BY u.Username
	ORDER BY u.Username ASC;
END$$

DELIMITER ;