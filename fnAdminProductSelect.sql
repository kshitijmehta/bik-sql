CREATE OR REPLACE FUNCTION fnAdminProductSelect ()
	RETURNS TABLE (prodID int, prodCategory VARCHAR(50), prodName VARCHAR(50),prodDesc text,
				   inrPrice numeric, usdPrice numeric,
				   colour varchar(50), size varchar(50), qty int)

AS
				   
$func$
	
	BEGIN
		
		RETURN QUERY
		SELECT b.prod_id,c.prod_category, a.prod_name,a.prod_desc, b.prod_inr_price,
		b.prod_usd_price, d.colour_value, e.size_value,b.prod_qty FROM product_sub_category a
		INNER JOIN product b ON a.prod_subcateg_id = b.prod_subcateg_id
		INNER JOIN product_category c ON a.prod_category_id = c.prod_category_id
		LEFT JOIN ref_colour d ON d.colour_id = b.prod_colour
		LEFT JOIN ref_size e ON e.size_id = b.prod_size
		ORDER BY b.prod_id;
	
	END

$func$ LANGUAGE plpgsql;

