CREATE OR REPLACE PROCEDURE spProdSubCategInsertUpdateDelete(
	_ser INTEGER,
	_pcid INTEGER,
	_name VARCHAR(50),
	_desc TEXT,
	_psid INTEGER DEFAULT NULL
)

LANGUAGE 'plpgsql'

AS $BODY$

BEGIN
	
	IF _ser=1 THEN -- INSERT
	
		INSERT INTO product_sub_category (prod_category_id, prod_name, prod_desc)
		VALUES (_pcid, _name, _desc);
		
	ELSEIF _ser=2 THEN --UPDATE
		
		UPDATE product_sub_category SET
		 prod_category_id = _pcid,
		 prod_name = _name,
		 prod_desc = _desc
		 where prod_subcateg_id = _psid;
		 
	ELSEIF _ser=3 THEN --DELETE
		IF EXISTS (SELECT 1 FROM product_sub_category a 
				    INNER JOIN product b on a.prod_subcateg_id = b.prod_subcateg_id
				    WHERE a.prod_subcateg_id = _psid) THEN
			BEGIN
					RAISE NOTICE 'There are products under this category! Delete them first.';
			END;
		ELSE
			BEGIN 
				DELETE FROM product_sub_category
				WHERE prod_subcateg_id = _psid;
			END;
		END IF;
	END IF;
END

$BODY$;