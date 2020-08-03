-- PROCEDURE: public.spsizeinsertupdatedelete(integer, character varying, character varying)

-- DROP PROCEDURE public.spsizeinsertupdatedelete(integer, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.spsizeinsertupdatedelete(
	_ser integer,
	_pcid integer,
	_code character varying,
	_value character varying,
	_sid integer DEFAULT NULL)
LANGUAGE 'plpgsql'
AS $BODY$

BEGIN
	CASE _ser 
	WHEN 1 THEN --- INSERT
		INSERT INTO ref_size 
			  (prod_category_id, size_code, size_value)
		VALUES(_pcid		   ,_code	  , _value);
	
	WHEN 2 THEN --- UPDATE
		UPDATE ref_size
		SET (prod_category_id, size_code, size_value)
		   =(_pcid			 , _code	, _value)
		WHERE size_id = _sid;
	
	WHEN 3 THEN ---SOFT DELETE
		UPDATE ref_size
		SET    size_datetill = now()
		WHERE  size_id= _sid;
	
	ELSE 
		RAISE EXCEPTION 'Unexpected _ser value: %', _ser;
	
	END CASE;
		
END

$BODY$;
