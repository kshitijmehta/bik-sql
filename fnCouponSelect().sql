CREATE OR REPLACE FUNCTION fnCouponSelect()
	RETURNS TABLE(cp_id INTEGER, cp_code VARCHAR(20), cp_value VARCHAR(20))
	AS $BODY$
		BEGIN
			RETURN QUERY 
			SELECT coupon_id, coupon_code, coupon_value FROM coupon 
			WHERE coupon_datetill is null;
		END
	
	$BODY$ LANGUAGE plpgsql;
	
	
	
	
	
