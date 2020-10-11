CREATE OR REPLACE PROCEDURE public.spproductinsertupdatedelete(
  _ser        int
, _subcategid int
, _name		  VARCHAR(50)
, _inrprice   numeric
, _usdprice   numeric
, _colour     int
, _size       int
, _qty        int
, _desc		  TEXT
, INOUT _prod_id int DEFAULT NULL
, INOUT _pd_id int DEFAULT NULL
)
  LANGUAGE plpgsql AS
$proc$
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
		 INSERT INTO product_details
		 		(prod_id, prod_inr_price, prod_usd_price, prod_colour, prod_size, prod_qty)
		 VALUES	(_prod_id, _inrprice     , _usdprice     , _colour    , _size    , _qty)
		 RETURNING pd_id INTO _pd_id;

   WHEN 2 THEN  -- UPDATE
--       UPDATE product
--       SET   (prod_subcateg_id, prod_inr_price, prod_usd_price, prod_size, prod_colour, prod_qty)
--           = (_subcategid     , _inrprice     , _usdprice     , _size    , _colour    , _qty)
--       WHERE  prod_id = _prod_id;
		UPDATE product
		SET		(prod_subcateg_id,prod_name, prod_desc)
			=	(_subcategid,	_name	,	_desc)
		WHERE prod_id = _prod_id;
		
		UPDATE product_details
		SET  (prod_inr_price, prod_usd_price, prod_colour, prod_size, prod_qty)
			= (_inrprice     , _usdprice     , _colour    , _size    , _qty)
		WHERE pd_id = _pd_id;

   WHEN 3 THEN  -- soft-DELETE
      UPDATE product
      SET    prod_datetill = now()
      WHERE  prod_id = _prod_id;
	  
	  DELETE FROM product_details where prod_id = _prod_id;

   ELSE
      RAISE EXCEPTION 'Unexpected _ser value: %', _ser;
   END CASE;
END
$proc$;
