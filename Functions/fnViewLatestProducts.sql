CREATE OR REPLACE FUNCTION public.fnViewLatestProducts()
RETURNS TABLE (prod_id int, prod_name varchar(50), prod_desc text, prod_img_name varchar(20),prod_img_path text)
LANGUAGE 'plpgsql'
AS $BODY$
	BEGIN
			RETURN QUERY
			
			select a.prod_id,a.prod_name,
				a.prod_desc, b.prod_img_name, b.prod_img_path from public.product a
			left join public.product_image b on a.prod_id=b.prod_id 
			where a.prod_id in (select pd.prod_id from product_details pd)
			and a.prod_datetimeinserted is not null
			and a.prod_datetill is null
			and b.prod_img_name = (select pi.prod_img_name from public.product_image pi where pi.prod_id=a.prod_id LIMIT 1)
			order by prod_datetimeinserted desc;
	
	END;
$BODY$;

