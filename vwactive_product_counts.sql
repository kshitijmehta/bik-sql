create view vwactive_product_counts
       ( 
         prod_subcategory_id
       , prod_subcategroy_name
       , prod_active_count
       ) as
	select 
	a.prod_subcateg_id
	, b.prod_subcateg_name
	, count(*) from product a
    inner join product_sub_category b on a.prod_subcateg_id = b.prod_subcateg_id
    where a.prod_datetill is null
    group by a.prod_subcateg_id,prod_subcateg_name; 
   
  -- select * from active_product_counts
   
   
 