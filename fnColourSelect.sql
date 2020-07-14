CREATE OR REPLACE FUNCTION fnColourSelect()
	RETURNS TABLE ( col_id INTEGER,
				   col_code VARCHAR(20),
				   col_value VARCHAR(50))
	AS
	
$func$

BEGIN
	
	RETURN QUERY
	SELECT colour_id, colour_code, colour_value from ref_colour
	WHERE colour_datetill is null;

END

$func$ LANGUAGE  plpgsql



