-- PROCEDURE: public.spproductinsertupdatedelete(integer, integer, character varying, numeric, numeric, integer, integer, integer, text, integer, integer)

-- DROP PROCEDURE public.spproductinsertupdatedelete(integer, integer, character varying, numeric, numeric, integer, integer, integer, text, integer, integer);

CREATE OR REPLACE PROCEDURE public.spproductinsertupdatedelete(
	_ser integer,
	_subcategid integer,
	_name character varying,
	_desc text,
	INOUT _prod_id integer DEFAULT NULL::integer
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
   CASE _ser    
   WHEN 1 THEN  -- INSERT
--       INSERT INTO product
--              (prod_subcateg_id, prod_inr_price, prod_usd_price, prod_colour, prod_size, prod_qty)
--       VALUES (_subcategid     , _inrprice     , _usdprice     , _colour    , _size    , _qty    )
--       RETURNING prod_id
--       INTO _prod_id;   
		 INSERT INTO product
             (prod_subcateg_id, prod_name, prod_desc)
			  VALUES (_subcategid, _name, _desc     )
			  RETURNING prod_id
			  INTO _prod_id;  
		 

   WHEN 2 THEN  -- UPDATE
--       UPDATE product
--       SET   (prod_subcateg_id, prod_inr_price, prod_usd_price, prod_size, prod_colour, prod_qty)
--           = (_subcategid     , _inrprice     , _usdprice     , _size    , _colour    , _qty)
--       WHERE  prod_id = _prod_id;
		UPDATE product
		SET		(prod_subcateg_id,prod_name, prod_desc)
			=	(_subcategid,	_name	,	_desc)
		WHERE prod_id = _prod_id;
		
		

   WHEN 3 THEN  -- soft-DELETE
      UPDATE product
      SET    prod_datetill = now()
      WHERE  prod_id = _prod_id;
	  
	 

   ELSE
      RAISE EXCEPTION 'Unexpected _ser value: %', _ser;
   END CASE;
END
$BODY$;
