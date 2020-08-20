CREATE OR REPLACE PROCEDURE spCouponInsertUpdateDelete (
	  _ser INTEGER
	, _cp_code VARCHAR(20)
	, _cp_value VARCHAR(20)
	, INOUT _cp_id INTEGER DEFAULT NULL
)

LANGUAGE 'plpgsql'

AS $BODY$

	BEGIN
		CASE _ser
		WHEN 1 THEN --- INSERT
			INSERT INTO coupon 
				   (coupon_code, coupon_value)
			VALUES (_cp_code   , _cp_value   );
		
		WHEN 2 THEN --- UPDATE
			UPDATE coupon
			SET		(coupon_code, coupon_value)
				   =(_cp_code   , _cp_value)
			WHERE coupon_id = _cp_id;
		
		WHEN 3 THEN --- DELETE
			UPDATE coupon
			SET coupon_datetill = now()
			WHERE coupon_id = _cp_id;
		
		ELSE 
			RAISE EXCEPTION 'Unexpected Serial Value: %', _ser;
		END CASE;
		
	
	END

$BODY$;