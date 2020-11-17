-- FUNCTION: public.fngetlatesttrendingproduct(integer)

-- DROP FUNCTION public.fngetlatesttrendingproduct(integer);

CREATE OR REPLACE FUNCTION public.fngetlatesttrendingproduct(
	i integer)
    RETURNS TABLE(prod_id integer, prod_name character varying, prod_desc text, 
				  prod_inr_price numeric, prod_usd_price numeric,prod_img_name character varying, prod_img_path text) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
    
AS $BODY$
	BEGIN
		IF i = 1 THEN ---- LATEST
			RETURN QUERY
			
			select a.prod_id,a.prod_name,
				a.prod_desc
				,pd.prod_inr_price, pd.prod_usd_price,
				b.prod_img_name, b.prod_img_path from public.product a
			left join public.product_image b on a.prod_id=b.prod_id 
			left join public.product_details pd on a.prod_id = pd.prod_id
			where a.prod_id in (select pd.prod_id from product_details pd)
			and a.prod_datetill is null
			and a.prod_latest = true 
			and pd.pd_id = (select pds.pd_id from public.product_details pds where pds.prod_id = a.prod_id LIMIT 1)
			and b.prod_img_name = (select pi.prod_img_name from public.product_image pi where pi.prod_id=a.prod_id LIMIT 1);
		
		ELSEIF i = 2 THEN ---- TRENDING
			
			RETURN QUERY
			
			select a.prod_id,a.prod_name,
				a.prod_desc
				,pd.prod_inr_price, pd.prod_usd_price
				, b.prod_img_name, b.prod_img_path from public.product a
			left join public.product_image b on a.prod_id=b.prod_id 
			left join public.product_details pd on a.prod_id = pd.prod_id
			where a.prod_id in (select pd.prod_id from product_details pd)
			and a.prod_datetill is null
			and a.prod_trending = true
			and pd.pd_id = (select pds.pd_id from public.product_details pds where pds.prod_id = a.prod_id LIMIT 1)
			and b.prod_img_name = (select pi.prod_img_name from public.product_image pi where pi.prod_id=a.prod_id LIMIT 1);
		
		END IF;
	
	END;

$BODY$;

ALTER FUNCTION public.fngetlatesttrendingproduct(integer)
    OWNER TO postgres;
