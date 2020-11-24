truncate product_category cascade----- This will delete data from all product related and referenced tables
truncate ref_colour cascade
truncate product_image
truncate store.order cascade
truncate store.payment cascade
truncate store.shippers cascade
truncate coupon cascade
------------Resetting the sequences--------------
alter sequence coupon_coupon_id_seq restart with 1
alter sequence product_category_prod_category_id_seq restart with 1
alter sequence product_type_prod_type_id_seq restart with 1
alter sequence product_details_pd_id_seq restart with 1
alter sequence product_image_prod_img_id_seq restart with 1
alter sequence product_prod_id_seq restart with 100001
alter sequence ref_colour_colour_id_seq restart with 1
alter sequence ref_size_Size_id_seq restart with 1
--------------Create sample table to import data--------------
CREATE TABLE public.sampledata
(
    productname character varying(50) COLLATE pg_catalog."default",
    category character varying(50) COLLATE pg_catalog."default",
    individualdetail character varying(50) COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    inr numeric,
    usd numeric,
    colour character varying(20) COLLATE pg_catalog."default",
    size1 character varying(10) COLLATE pg_catalog."default",
    size2 character varying(10) COLLATE pg_catalog."default",
    size3 character varying(10) COLLATE pg_catalog."default",
    size4 character varying(10) COLLATE pg_catalog."default",
    size5 character varying(10) COLLATE pg_catalog."default",
    size6 character varying(10) COLLATE pg_catalog."default",
    size7 character varying(10) COLLATE pg_catalog."default",
    size8 character varying(10) COLLATE pg_catalog."default",
    size9 character varying(10) COLLATE pg_catalog."default",
    image1 character varying(10) COLLATE pg_catalog."default",
    image2 character varying(10) COLLATE pg_catalog."default",
    image3 character varying(10) COLLATE pg_catalog."default",
    image4 character varying(10) COLLATE pg_catalog."default",
    image5 character varying(10) COLLATE pg_catalog."default",
    quantity smallint
)

TABLESPACE pg_default;

ALTER TABLE public.sampledata
    OWNER to postgres;
-----------------Convert the xlxs file into csv file and import the data into sampledata table---------------
COPY public.sampledata FROM 'F:\SB\SampleData.csv' DELIMITER ',' CSV HEADER;---column header should match the table created above
SELECT * FROM sampledata --- 599 rows imported
UPDATE sampledata set productname='Footwear'---- Updating Ladies Footwear to Footwear
-------------------Insert Product Category----------------------
INSERT INTO product_category(prod_category)
	SELECT DISTINCT productname from sampledata;
------------------Insert Product Sub Categories----------------
INSERT INTO product_sub_category (prod_subcateg_name, prod_category_id)
	SELECT DISTINCT(sd.category), pc.prod_category_id FROM sampledata sd
	INNER JOIN product_category pc ON sd.productname = pc.prod_category
	ORDER BY sd.category;
-----------------------Insert into Product table------------------
INSERT INTO product (prod_name,prod_desc,prod_subcateg_id,prod_datetimeinserted)
	SELECT sd.individualdetail, sd.description, psc.prod_subcateg_id,now()
	FROM sampledata sd
	INNER JOIN product_sub_category psc ON sd.category = psc.prod_subcateg_name
	ORDER BY psc.prod_subcateg_id; 
--------------------Insert Sizes--------------------
SELECT t.*  into temp table sizes from sampledata sd
cross join lateral (
	values
		(sd.size1,sd.size1),
		(sd.size2,sd.size2),
		(sd.size3,sd.size3),
		(sd.size4,sd.size4),
		(sd.size5,sd.size5),
		(sd.size6,sd.size6),
		(sd.size7,sd.size7),
		(sd.size8,sd.size8),
		(sd.size9,sd.size9)
) as t(sizes, sizecode) limit 8;
INSERT INTO ref_size (size_code,size_value,prod_category_id)
	select sizecode,sizes,1 from sizes ---- Write the Product Category ID for 3rd column e.g. 1 here
-------------Insert Colours---------------------------
create unique index unique_color_value on ref_colour(lower(color_value));---Unique index on colour values 
INSERT INTO ref_colour (colour_code, colour_value)
	select distinct(substring(trim(colour),0,4)),colour from sampledata;
-------------Insert Product Details----------------------
INSERT INTO product_details (prod_id, prod_inr_price, prod_usd_price, prod_colour,prod_size,prod_qty) ----- 5472 rows inserted
	SELECT pr.prod_id,sd.inr, sd.usd,rc.colour_id,rs.size_id,sd.quantity from sampledata sd
	cross join lateral (
		values
			(sd.size1),
			(sd.size2),
			(sd.size3),
			(sd.size4),
			(sd.size5),
			(sd.size6),
			(sd.size7),
			(sd.size8),
			(sd.size9)
	) as t(sizes)
	inner join product pr on sd.individualdetail=pr.prod_name
	inner join ref_colour rc on sd.colour = rc.colour_value
	inner join ref_size rs on t.sizes= rs.size_value
	where t.sizes is not null
	group by pr.prod_id,sd.inr, sd.usd,rc.colour_id,rs.size_id,sd.quantity
	order by pr.prod_id;
