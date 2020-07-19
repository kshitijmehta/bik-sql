CREATE OR REPLACE PROCEDURE public.spproductinsertupdatedelete(
  _ser        int
, _subcategid int
, _inrprice   numeric
, _usdprice   numeric
, _colour     int
, _size       int
, _qty        int
, INOUT _prod_id int DEFAULT NULL
)
  LANGUAGE plpgsql AS
$proc$
BEGIN
   CASE _ser    
   WHEN 1 THEN  -- INSERT
      INSERT INTO product
             (prod_subcateg_id, prod_inr_price, prod_usd_price, prod_colour, prod_size, prod_qty)
      VALUES (_subcategid     , _inrprice     , _usdprice     , _colour    , _size    , _qty    )
      RETURNING prod_id
      INTO _prod_id;   

   WHEN 2 THEN  -- UPDATE
      UPDATE product
      SET   (prod_subcateg_id, prod_inr_price, prod_usd_price, prod_size, prod_colour, prod_qty)
          = (_subcategid     , _inrprice     , _usdprice     , _size    , _colour    , _qty)
      WHERE  prod_id = _prod_id;

   WHEN 3 THEN  -- soft-DELETE
      UPDATE product
      SET    prod_datetill = now()
      WHERE  prod_id = _prod_id;

   ELSE
      RAISE EXCEPTION 'Unexpected _ser value: %', _ser;
   END CASE;
END
$proc$;