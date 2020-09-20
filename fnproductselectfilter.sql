-- FUNCTION: public.fnproductselectfilter(integer, integer)

-- DROP FUNCTION public.fnproductselectfilter(integer, integer);

CREATE OR REPLACE FUNCTION public.fnproductselectfilter(
	_cid integer DEFAULT NULL::integer,
	_sid integer DEFAULT NULL::integer,
	_pcid integer DEFAULT NULL)
    RETURNS TABLE(prodid integer, prodcategory character varying, prodname character varying, proddesc text
				  , inrprice numeric, usdprice numeric, colour character varying, size character varying, qty integer
				  , prodimgpath text ) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
    
AS $BODY$
	
	DECLARE
	
	_sql TEXT := 'SELECT b.prod_id,c.prod_category, a.prod_name,a.prod_desc, b.prod_inr_price,
		b.prod_usd_price, d.colour_value, e.size_value,b.prod_qty
		,f.prod_img_path
		FROM product_sub_category a
		INNER JOIN product b ON a.prod_subcateg_id = b.prod_subcateg_id
		INNER JOIN product_category c ON a.prod_category_id = c.prod_category_id
		LEFT JOIN ref_colour d ON d.colour_id = b.prod_colour
		LEFT JOIN ref_size e ON e.size_id = b.prod_size 
		LEFT JOIN product_image f ON b.prod_id = f.prod_id WHERE
		f.prod_img_path  = (select prod_img_path from product_image where prod_id= b.prod_id LIMIT 1) '
		;
	--	WHERE 1=1 ';
	_where TEXT;
	
	BEGIN
		 
		 _where = CONCAT_WS('AND'
						   ,  CASE WHEN _cid IS NOT NULL THEN ' d.colour_id=$1 ' END
						   ,  CASE WHEN _sid IS NOT NULL THEN ' e.size_id = $2 ' END
						   ,  CASE WHEN _pcid IS NOT NULL THEN ' c.prod_category_id = $3 ' END);
		
		 IF _where <> '' THEN
		 	--_sql :=_sql ||'where '|| _where ||'order by b.prod_id';
			_sql :=_sql ||'and'|| _where ||'order by b.prod_id';
		
		 ELSE
		  
		 	_sql := _sql ||'order by b.prod_id';
		
		END IF;
			 RETURN QUERY
			 
			 EXECUTE _sql
			 USING $1,$2,$3;
		END
$BODY$;

-- ALTER FUNCTION public.fnproductselectfilter(integer, integer)
--     OWNER TO postgres;
