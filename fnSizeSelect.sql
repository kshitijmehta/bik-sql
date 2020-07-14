CREATE OR REPLACE FUNCTION fnSizeSelect()
	RETURNS TABLE ( s_id INTEGER,
				   s_code VARCHAR(20),
				   s_value VARCHAR(50),
				  	prod_category INTEGER)
	AS
	
$func$

BEGIN
	
	RETURN QUERY
	SELECT size_id, size_code, size_value, prod_category_id from ref_size
	WHERE size_datetill is null;

END

$func$ LANGUAGE  plpgsql



