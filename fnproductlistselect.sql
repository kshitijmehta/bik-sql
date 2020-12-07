-- FUNCTION: public.fnproductlistselect(text, text, text)

-- DROP FUNCTION public.fnproductlistselect(text, text, text);
--select * from fnproductlistselect (_colour:='(1,2)')
--select * from fnproductlistselect (_size:='(1)',_colour:='(1,2)',_prodcategid := 4)
--select * from fnproductlistselect (_prodcategid := 4)
--select * from fnproductlistselect ()
--select * from fnproductlistselect (_subcategid  := '(2,3)') 

CREATE OR REPLACE FUNCTION public.fnproductlistselect(
	_colour text DEFAULT NULL::text,
	_size text DEFAULT NULL::text,
	_price text DEFAULT NULL::text
   , _prodcategid INTEGER DEFAULT NULL
   , _subcategid text default null
   , _prodname text default null)
   
    RETURNS TABLE(prodid integer, prodcategory character varying, prodsubcategory character varying, prodname character varying, proddesc text
				  , inrprice numeric, usdprice numeric, colour character varying, size character varying, qty integer
				  , prodimgpath TEXT) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
    
AS $BODY$
	
	DECLARE
	
	_sql TEXT := 'SELECT b.prod_id, c.prod_category,a.prod_subcateg_name, b.prod_name,b.prod_desc, pd.prod_inr_price,
		pd.prod_usd_price, d.colour_value, e.size_value,pd.prod_qty,f.prod_img_path FROM product_sub_category a
		INNER JOIN product b ON a.prod_subcateg_id = b.prod_subcateg_id
		INNER JOIN product_category c ON a.prod_category_id = c.prod_category_id
		INNER JOIN product_details pd ON b.prod_id = pd.prod_id
		LEFT JOIN ref_colour d ON d.colour_id = pd.prod_colour
		LEFT JOIN ref_size e ON e.size_id = pd.prod_size 
		LEFT JOIN product_image f ON b.prod_id = f.prod_id ';
	--	WHERE
	--	f.prod_img_path  = (select prod_img_path from product_image where prod_id= b.prod_id LIMIT 1)'; 
		--WHERE 1=1 ';
	_where TEXT;

	BEGIN
		 
		 _where = CONCAT_WS(' AND '
						  -- ,  CASE WHEN _colour IS NOT NULL THEN '('||_colour||')' END
							, 'f.prod_img_path  = (select prod_img_path from product_image where prod_id= b.prod_id LIMIT 1)'
				    		--   , 'pd.pd_id = (select pd_id from product_details where prod_id = b.prod_id LIMIT 1)'
						   ,  CASE WHEN _colour IS NOT NULL THEN 'd.colour_id in ' ||_colour||' ' END
						   ,  CASE WHEN _size IS NOT NULL THEN 
									'e.size_id in ' || _size||' ' 
								ELSE
									'pd.pd_id = (select pd_id from product_details where prod_id = b.prod_id LIMIT 1)'
								END
						   ,  CASE WHEN _prodcategid IS NOT NULL THEN 'c.prod_category_id ='|| _prodcategid  END
							, CASE WHEN _subcategid IS NOT NULL THEN 'a.prod_subcateg_id in '||_subcategid||' ' END
						   ,  CASE WHEN _price IS NOT NULL THEN _price END||' '
						   ,  CASE WHEN _prodname IS NOT NULL THEN 'lower(b.prod_name) like lower(''%'||_prodname||'%'') ' END||' ');
		
		 IF _where <> '' THEN
 		 	_sql :=_sql ||' where '|| _where ||' order by b.prod_id';
			--_sql :=_sql || _where ||' order by b.prod_id';
		
		 ELSE
		  
		 	_sql := _sql ||' order by b.prod_id';
		
		END IF;
			 RETURN QUERY
			 
			 EXECUTE _sql
			 USING $1,$2,$3,$4,$5,$6;
		END
$BODY$;

/* Commented on 20 Nov 20
CREATE OR REPLACE FUNCTION public.fnproductlistselect(
	_colour text DEFAULT NULL::text,
	_size text DEFAULT NULL::text,
	_price text DEFAULT NULL::text
   , _prodcategid INTEGER DEFAULT NULL
   , _subcategid text default null)
   
    RETURNS TABLE(prodid integer, prodcategory character varying, prodsubcategory character varying, prodname character varying, proddesc text
				  , inrprice numeric, usdprice numeric, colour character varying, size character varying, qty integer
				  , prodimgpath TEXT) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
    
AS $BODY$
	
	DECLARE
	
	_sql TEXT := 'SELECT b.prod_id, c.prod_category,a.prod_subcateg_name, b.prod_name,b.prod_desc, pd.prod_inr_price,
		pd.prod_usd_price, d.colour_value, e.size_value,pd.prod_qty,f.prod_img_path FROM product_sub_category a
		INNER JOIN product b ON a.prod_subcateg_id = b.prod_subcateg_id
		INNER JOIN product_category c ON a.prod_category_id = c.prod_category_id
		INNER JOIN product_details pd ON b.prod_id = pd.prod_id
		LEFT JOIN ref_colour d ON d.colour_id = pd.prod_colour
		LEFT JOIN ref_size e ON e.size_id = pd.prod_size 
		LEFT JOIN product_image f ON b.prod_id = f.prod_id ';
	--	WHERE
	--	f.prod_img_path  = (select prod_img_path from product_image where prod_id= b.prod_id LIMIT 1)'; 
		--WHERE 1=1 ';
	_where TEXT;

	BEGIN
		 
		 _where = CONCAT_WS(' AND '
						  -- ,  CASE WHEN _colour IS NOT NULL THEN '('||_colour||')' END
							, 'f.prod_img_path  = (select prod_img_path from product_image where prod_id= b.prod_id LIMIT 1)'
						   ,  CASE WHEN _colour IS NOT NULL THEN 'd.colour_id in ' ||_colour||' ' END
						   ,  CASE WHEN _size IS NOT NULL THEN 'e.size_id in ' || _size||' ' END
						   ,  CASE WHEN _prodcategid IS NOT NULL THEN 'c.prod_category_id ='|| _prodcategid  END
							, CASE WHEN _subcategid IS NOT NULL THEN 'a.prod_subcateg_id in '||_subcategid||' ' END
						   ,  CASE WHEN _price IS NOT NULL THEN _price END||' ');
		
		 IF _where <> '' THEN
 		 	_sql :=_sql ||' where '|| _where ||' order by b.prod_id';
			--_sql :=_sql || _where ||' order by b.prod_id';
		
		 ELSE
		  
		 	_sql := _sql ||' order by b.prod_id';
		
		END IF;
			 RETURN QUERY
			 
			 EXECUTE _sql
			 USING $1,$2,$3,$4;
		END
$BODY$;
*/

