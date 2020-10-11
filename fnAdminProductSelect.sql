--This function is for Admin to view all the products based on product category  along with their quantity available

CREATE OR REPLACE FUNCTION fnAdminProductSelect ()
	RETURNS TABLE (prodID int, prodCategory VARCHAR(50), prodName VARCHAR(50),prodDesc text,
				  qty int)

AS
				   
$func$
	
	BEGIN
		
		RETURN QUERY 
		
		with cte_productgetdetails as (
		select a.prod_category, b.prod_subcateg_id
		, c.prod_id, c.prod_name, c.prod_desc from 
		product_sub_category b inner join  product_category a  on  b.prod_category_id =a.prod_category_id 
		inner join product c on b.prod_subcateg_id = c.prod_subcateg_id
		)
		select prod_id, prod_category, prod_name
		, prod_desc , sum(pd.prod_qty) as Qty  from product_details pd 
		inner join cte_productgetdetails ct using (prod_id)
		inner join ref_colour rc on pd.prod_colour = rc.colour_id
		inner join ref_size rs on pd.prod_size = rs.size_id
		group by prod_id,prod_category, prod_name, prod_desc;
		
		
		
-- 		RETURN QUERY
-- 		SELECT b.prod_id,c.prod_category, a.prod_name,a.prod_desc, b.prod_inr_price,
-- 		b.prod_usd_price, d.colour_value, e.size_value,b.prod_qty FROM product_sub_category a
-- 		INNER JOIN product b ON a.prod_subcateg_id = b.prod_subcateg_id
-- 		INNER JOIN product_category c ON a.prod_category_id = c.prod_category_id
-- 		LEFT JOIN ref_colour d ON d.colour_id = b.prod_colour
-- 		LEFT JOIN ref_size e ON e.size_id = b.prod_size
-- 		ORDER BY b.prod_id;
	
	END

$func$ LANGUAGE plpgsql;
