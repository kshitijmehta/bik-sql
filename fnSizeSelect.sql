CREATE OR REPLACE FUNCTION fnSizeSelect()
	RETURNS TABLE ( s_id INTEGER,
				   s_code VARCHAR(20),
				   s_value VARCHAR(50),
				  	prod_category INTEGER,
					prod_categoryname VARCHAR(50))
	AS
	
$func$

BEGIN
	
	RETURN QUERY
	SELECT size_id, size_code, size_value, a.prod_category_id,b.prod_category from ref_size a
	inner join product_category b on a.prod_category_id = b.prod_category_id
	WHERE a.size_datetill is null;

END

$func$ LANGUAGE  plpgsql



