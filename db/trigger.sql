/*Tai 1 thoi diem nhat dinh chi ap dung 1 gia cho 1 san pham*/
/*Kiem tra lúc insert giá san pham*/
DELIMITER $$
CREATE TRIGGER TG_PRODUCT_PRICE AFTER INSERT ON productprice
FOR EACH ROW 
BEGIN
    SET @NBD := new.StartDate ;
    SET @NKT := new.EndDate ;
    if EXISTS(select pp.Price 
                FROM productprice PP 
                WHERE ((@NBD < PP.EndDate) AND ( @NBD > PP.StartDate))
              	OR ((@NKT  < PP.EndDate)AND (@NKT > PP.StartDate))
              	OR ((pp.StartDate > @NBD) AND ( PP.EndDate < @NKT))
                OR (@NBD > @NKT)
			)
     THEN 
     	DELETE FROM productprice WHERE id = new.id;
     END IF; 	 
END$$
DELIMITER ;	

/* kiem tra lúc update giá san pham */
DELIMITER $$
CREATE TRIGGER TG_UPDATE_PRODUCT_PRICE AFTER UPDATE ON productprice
FOR EACH ROW 
BEGIN
    SET @NBD := new.StartDate ;
    SET @NKT := new.EndDate ;
    if EXISTS(select pp.Price
                FROM productprice PP 
                WHERE ((@NBD < PP.EndDate) AND ( @NBD > PP.StartDate))
              	OR ((@NKT  < PP.EndDate)AND (@NKT > PP.StartDate))
              	OR ((pp.StartDate > @NBD) AND ( PP.EndDate < @NKT))
                OR (@NBD > @NKT)
			)
     THEN 
     	DELETE FROM productprice WHERE id = new.id;
     END IF; 	
END$$
----
INSERT INTO productprice VALUES ('100','50000','2018-01-05', '2018 - 03-05','0' ,'1','0',NULL,NULL)
--Cap nhat order_product khi tr?ng thái isDelete trong bang order ='1'
DELIMITER $$
CREATE TRIGGER TRG_UPDATE_ORDER_PRODUCT AFTER UPDATE ON `order`
FOR EACH ROW 
BEGIN
	SET @ID := new.id;
    	SET @isDelete := new.IsDelete;
    
    	if @IsDelete = 1 then  		
    		UPDATE `orderproduct`
    		SET IsDelete = 1
   		WHERE @ID =  `orderproduct`.ID_Order ;
    	END if; 
END$$
DELIMITER ;
---Xóa bang order thì se xóa toàn bo orderproduct liên quan 
DELIMITER $$
CREATE TRIGGER TRG_DELETE_ORDER_PRODUCT AFTER DELETE ON `order`
FOR EACH ROW 
BEGIN
	SET @ID := OLD.id;
    SET @isDelete := OLD.IsDelete;	
    DELETE FROM  `orderproduct`
   	WHERE @ID =  `orderproduct`.ID_Order ;
END$$
DELIMITER ;