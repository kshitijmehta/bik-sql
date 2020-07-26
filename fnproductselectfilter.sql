CREATE OR REPLACE FUNCTION public.fnproductselectfilter(
	  _cid INTEGER DEFAULT NULL
	, _sid INTEGER DEFAULT NULL
	
	)
    RETURNS TABLE(prodid integer, prodcategory character varying, prodname character varying, proddesc text, inrprice numeric, usdprice numeric, colour character varying, size character varying, qty integer) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
    
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
		 
		 _where = CONCAT_WS('AND'
						   ,  CASE WHEN _cid IS NOT NULL THEN ' d.colour_id=$1 ' END
						   ,  CASE WHEN _sid IS NOT NULL THEN ' e.size_id = $2 ' END);
		
		 IF _where <> '' THEN
		 	_sql :=_sql ||'where '|| _where ||'order by b.prod_id';
		
		 ELSE
		  
		 	_sql := _sql ||'order by b.prod_id';
		
		END IF;
			 RETURN QUERY
			 
			 EXECUTE _sql
			 USING $1,$2;
		END
$BODY$;


