-- PROCEDURE: public.spcolourinsertupdatedelete(integer, character varying, character varying)

-- DROP PROCEDURE public.spcolourinsertupdatedelete(integer, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.spcolourinsertupdatedelete(
	_ser integer,
	_code character varying,
	_value character varying,
	_cid integer default null)
LANGUAGE 'plpgsql'
AS $BODY$

BEGIN
	IF _ser =1 THEN --Insert Block
		INSERT INTO ref_colour 
		VALUES(_code, _value);
	
	ELSEIF _ser =2 THEN
		UPDATE ref_colour 
			SET colour_code = _code,
				colour_value = _value
			WHERE colour_id = _cid;
		
	ELSEIF _ser = 3 THEN --- DELETE
		UPDATE ref_colour SET colour_datetill=now()
		WHERE colour_id = _cid;
	
	END IF;
END

$BODY$;
