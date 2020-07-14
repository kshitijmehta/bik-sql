-- PROCEDURE: public.spproductcategoryinsertupdatedelete(integer, character varying)

-- DROP PROCEDURE public.spproductcategoryinsertupdatedelete(integer, character varying);

CREATE OR REPLACE PROCEDURE public.spproductcategoryinsertupdatedelete(
	_ser integer,
	_categoryname character varying,
	_pcid integer default null)
LANGUAGE 'plpgsql'
AS $BODY$

	BEGIN
	
		IF _ser =1 THEN
			
			INSERT INTO product_category (prod_category)
			VALUES(_categoryName);
		
		ELSEIF _ser = 2 THEN --UPDATE
			UPDATE product_category 
			SET prod_category = _categoryname
			where prod_category_id = _pcid;
			
		ELSEIF _ser=3 THEN --DELETE
			UPDATE product_category
			SET prod_category_datetill=now()
			WHERE prod_category_id= _pcid;
			
		END IF;
	
	END

$BODY$;




