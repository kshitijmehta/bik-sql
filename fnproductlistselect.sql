CREATE OR REPLACE FUNCTION public.fnproductlistselect(
	_colour text default NULL,
	_size text DEFAULT NULL,
	_price TEXT DEFAULT NULL)
    RETURNS TABLE(prodid integer, prodcategory character varying, prodname character varying, proddesc text, inrprice numeric, usdprice numeric, colour character varying, size character varying, qty integer) 
    LANGUAGE 'plpgsql'

       
AS $BODY$
	
	DECLARE
	
	_sql TEXT := 'SELECT b.prod_id,c.prod_category, a.prod_name,a.prod_desc, b.prod_inr_price,
		b.prod_usd_price, d.colour_value, e.size_value,b.prod_qty FROM product_sub_category a
		INNER JOIN product b ON a.prod_subcateg_id = b.prod_subcateg_id
		INNER JOIN product_category c ON a.prod_category_id = c.prod_category_id
		LEFT JOIN ref_colour d ON d.colour_id = b.prod_colour
		LEFT JOIN ref_size e ON e.size_id = b.prod_size ';
	--	WHERE 1=1 ';
	_where TEXT;
	
	BEGIN
		 
		 _where = CONCAT_WS(' AND '
						   ,  CASE WHEN _colour IS NOT NULL THEN '('||_colour||')' END
						   ,  CASE WHEN _size IS NOT NULL THEN _size END
						   ,  CASE WHEN _price IS NOT NULL THEN _price END);
		
		 IF _where <> '' THEN
		 	_sql :=_sql ||'where '|| _where ||'order by b.prod_id';
		
		 ELSE
		  
		 	_sql := _sql ||'order by b.prod_id';
		
		END IF;
			 RETURN QUERY
			 
			 EXECUTE _sql
			 USING $1,$2,$3;
		END
$BODY$;


