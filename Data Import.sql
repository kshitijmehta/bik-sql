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
--------------------------------------------------
INSERT INTO product_category(prod_category) values ('Lingerie')
INSERT INTO product_sub_category (prod_category_id,prod_subcateg_name)
	VALUES	(2,'Bra');
------------------------------------------------
--Create table to store Bra sample data--------
CREATE TABLE public.sampledata_bra(
		productname varchar(20),
		stylecode varchar(50),
		sku	varchar(50),
		description varchar(50),
		mrp numeric,
		size varchar(10),
		colour varchar(20),
		model varchar(100)
	)
------------Importing data---------------
COPY public.sampledata_bra(stylecode,description,sku,mrp,size,colour,productname,model) FROM 'F:\KP\SB\SampleData_bra_2.csv' DELIMITER ',' CSV HEADER;
----------Updating product tables------------------------
INSERT INTO ref_colour (colour_value,colour_code)   --- Updating colour
	select distinct(colour),substring(trim(colour),0,4) from sampledata_bra where colour not in 
		(select colour_value from ref_colour)

INSERT INTO	ref_size (size_value,size_code, prod_category_id) ---Updating Sizes
	select distinct(size),size,2 from sampledata_bra order by size --- Use product category as per your own table

ALTER TABLE product add column prod_sku VARCHAR(100)


INSERT INTO product (prod_subcateg_id, prod_name,prod_desc,prod_sku,prod_datetimeinserted)  ----SKU column is holding stylecode data
with cte_p as (
	select distinct on (model) model, productname, stylecode, description from sampledata_bra order by model, productname,stylecode)
	select 5, productname, description, stylecode, now() from cte_p order by productname;


INSERT INTO product_details (prod_id,prod_inr_price,prod_size,prod_colour,prod_qty)
	select pr.prod_id, sd.mrp, rs.size_id, rc.colour_id, 10 from sampledata_bra sd 
	inner join product pr on sd.stylecode = pr.prod_sku
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	order by pr.prod_id	
--------------------------------------------------Bra end-------------------------------------
---------------------------Camisole Begin---------------------------------------------
select * from product_sub_category
INSERT INTO product_sub_category (prod_category_id, prod_subcateg_name) values (2,'Camisole')
CREATE TABLE public.sampledata_camisole(
		productname varchar(20),
		stylecode varchar(50),
		sku	varchar(50),
		description text,
		mrp numeric,
		usd numeric,
		size varchar(10),
		colour varchar(20),
		model varchar(100)
	)
------Importing data-----------------
COPY public.sampledata_camisole(stylecode,description,sku,mrp,size,colour,productname,model) FROM 'F:\KP\SB\Data\Lingerie\camisole_csv.csv' DELIMITER ',' CSV HEADER;
---------------
--------Insert size
INSERT INTO ref_size (size_value,size_code,prod_category_id)
	select distinct(size),size,2 from sampledata_camisole
--------Insert Colour
INSERT INTO ref_colour (colour_value,colour_code)  
	select distinct(colour),substring(trim(colour),0,4) from sampledata_camisole where colour not in 
		(select colour_value from ref_colour)
--------Insert product and details
select distinct(stylecode),productname from sampledata_camisole
INSERT INTO product (prod_subcateg_id, prod_name,prod_desc,prod_sku,prod_datetimeinserted)  ----SKU column is holding stylecode data
with cte_p as (
	select distinct on (stylecode) stylecode, productname,  description from sampledata_camisole order by stylecode,productname)
	select 6, productname, description, stylecode, now() from cte_p order by productname;
select * from product_sub_category
select * from product  order by prod_datetimeinserted desc, prod_id
select count(*) from sampledata_camisole where mrp=500

update sampledata_camisole set usd = 6.80
where mrp = 500

update sampledata_camisole set usd = 8.16
where mrp = 600
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty)
	select pr.prod_id, sd.mrp, sd.usd, rs.size_id, rc.colour_id, 30 from sampledata_camisole sd 
	inner join product pr on sd.stylecode = pr.prod_sku
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	order by pr.prod_id	
----------------------Camisole end----------------------------------------
------------------Heels for women---Begin---------------------------
CREATE TABLE public.sampledata_heels(
		productname varchar(100),
		stylecode varchar(50),
		sku	varchar(50),
		description text,
		mrp numeric,
		usd numeric,
		qty smallint,
		size varchar(10),
		colour varchar(20),
		model varchar(100),
		dateinsert timestamp
	)
	
-----------------------
COPY public.sampledata_heels(stylecode,description,sku,mrp,usd,qty,productname,colour,size,model) FROM 'F:\KP\SB\Data\Footwear\Heelsforwomen_csv.csv' DELIMITER ',' CSV HEADER;
update sampledata_heels set dateinsert =now()
--------------Insert Size---------
INSERT INTO ref_size (size_value,size_code,prod_category_id)
	with cte_s as 
	(	
		select 'UK '||size as shoe_size from sampledata_heels
	)
	select distinct(shoe_size),shoe_size,1 from cte_s --- 1 here is the Product Categ ID for footwear, add as per your value
	order by shoe_size
------------Insert Colour------------
INSERT INTO ref_colour (colour_value,colour_code)  
	select distinct(colour),substring(trim(colour),0,4) from sampledata_heels where colour not in 
		(select colour_value from ref_colour)
--------Insert products------------
INSERT INTO product (prod_sku,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,3 from sampledata_heels
	order by stylecode;

INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty)
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_heels sd 
	inner join product pr on sd.stylecode = pr.prod_sku
	inner join ref_size rs on 'UK '||sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	order by pr.prod_id,rs.size_id
------------------Heels for women---End---------------------------
--------------Flat Sandals--- Begin------------------------
CREATE TABLE public.sampledata_flats(
		productname varchar(100),
		stylecode varchar(50),
		sku	varchar(50),
		description text,
		mrp numeric,
		usd numeric,
		qty smallint,
		size varchar(10),
		colour varchar(20),
		model varchar(100),
		model2 varchar(100),
		model3 varchar(100),
		model4 varchar(100),
		model5 varchar(100),
		model6 varchar(100),
		dateinsert timestamp
	)
---------data import----------
COPY public.sampledata_flats(stylecode,description,sku,mrp,qty,colour,productname,size,model,model2,model3,model5,model6) 
	FROM 'F:\KP\SB\Data\Footwear\flat sandals_csv.csv' DELIMITER ',' CSV HEADER;

update sampledata_flats 
	set mrp = 599,
		usd = 8.13,
		qty = 10,
		dateinsert=now()
--------Insert Size----
INSERT INTO ref_size (size_value,size_code, prod_category_id)
	select distinct(size),size,1 from sampledata_flats where size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  
	select distinct(colour),substring(trim(colour),0,4) from sampledata_flats where colour not in 
		(select colour_value from ref_colour)
-------Insert Products----
INSERT INTO product (prod_sku,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,2 from sampledata_flats --- Add Prod Subcateg id as per ypur db
	order by stylecode;

INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty)
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_flats sd 
	inner join product pr on sd.stylecode = pr.prod_sku
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	order by pr.prod_id,rs.size_id
-----Flat Sandals--- End-----------
---------Bellies-----Start-----------
CREATE TABLE public.sampledata_bellies(
		stylecode varchar(50),	
		description text,
		sku	varchar(50),
		mrp numeric,
		usd numeric,
		qty smallint,
		colour varchar(20),
		productname varchar(100),
		size varchar(10),		
		model varchar(100),
		model2 varchar(100),
		model3 varchar(100),
		model4 varchar(100),
		model5 varchar(100),
		dateinsert timestamp
	)
----------Data Import----------------------
COPY public.sampledata_bellies(stylecode,description,sku,mrp,usd,qty,colour,productname,size,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies2_csv.csv' DELIMITER ',' CSV HEADER;
update sampledata_bellies set dateinsert=now()
-------------------------------
INSERT INTO product_sub_category(prod_category_id, prod_subcateg_name) values (1,'Bellies')
-------Insert Size----------
INSERT INTO ref_size (size_value,size_code,prod_category_id)--- 0 Rows, all sizes are pre exisiting
	with cte_s as 
	(	
		select 'UK '||size as shoe_size from sampledata_bellies
	)
	select distinct(shoe_size),shoe_size,1 from cte_s --- 1 here is the Product Categ ID for footwear, add as per your value
	where shoe_size not in (select size_value from ref_size where prod_category_id=1)
	order by shoe_size
------- Inserting Colours---------------
INSERT INTO ref_colour (colour_value,colour_code)   --- 0 rows, all colours are pre existing
	select distinct(colour),substring(trim(colour),0,4) from sampledata_bellies where colour not in 
		(select colour_value from ref_colour)
-------Inserting Products---------------
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --5 ROWS
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,7 from sampledata_bellies --- Add Prod Subcateg id as per ypur db
	order by stylecode;

INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --30 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_bellies sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on 'UK '||sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	order by pr.prod_id,rs.size_id;
---------------Bellies---- end------------
---------------Wedges------start---------
CREATE TABLE public.sampledata_wedges(
		stylecode varchar(50),	
		description text,
		sku	varchar(50),
		mrp numeric,
		usd numeric,
		qty smallint,
		colour varchar(20),
		productname varchar(100),
		size varchar(10),		
		model varchar(100),
		model2 varchar(100),
		model3 varchar(100),
		model4 varchar(100),
		model5 varchar(100),
		dateinsert timestamp
	)
-------------Data Import------------------
COPY public.sampledata_wedges(stylecode,description,sku,mrp,usd,qty,colour,productname,size,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\wedges_csv.csv' DELIMITER ',' CSV HEADER;
update sampledata_wedges set dateinsert=now();
--------------------
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(size),size,1 from sampledata_wedges where size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  ---1 Row
	select distinct(colour),substring(trim(colour),0,4) from sampledata_wedges where colour not in 
		(select colour_value from ref_colour)
-------Insert Products----
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,4 from sampledata_wedges --- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --78 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_wedges sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	order by pr.prod_id,rs.size_id
---------------Wedges---end---------------
--------------Heels 2--- Begin------------
ALTER TABLE sampledata_heels
ADD COLUMN model2 varchar(100),
add column model3 varchar(100),
ADD COLUMN model4 VARCHAR(100),
ADD COLUMN model5 VARCHAR(100);
--------------------------Data Import---------
COPY public.sampledata_heels(stylecode,description,sku,mrp,usd,size,qty,colour,productname,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\heels_csv.csv' DELIMITER ',' CSV HEADER;
UPDATE sampledata_heels set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
--------------Insert size----------
INSERT INTO ref_size (size_value,size_code,prod_category_id)--- 1 Row
	with cte_s as 
	(	
		select 'UK '||size as shoe_size from sampledata_heels where dateinsert = '2020-12-03 19:42:32.547083'
	)
	select distinct(shoe_size),shoe_size,1 from cte_s --- 1 here is the Product Categ ID for footwear, add as per your value
	where shoe_size not in (select size_value from ref_size where prod_category_id=1)
	order by shoe_size
------- Inserting Colours---------------
INSERT INTO ref_colour (colour_value,colour_code)   --- 1 Row
	select distinct(colour),substring(trim(colour),0,4) from sampledata_heels where dateinsert = '2020-12-03 19:42:32.547083' and
	colour not in (select colour_value from ref_colour)
-------Inserting Products---------------
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --15 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,3 from sampledata_heels --- Add Prod Subcateg id as per ypur db
	where dateinsert = '2020-12-03 19:42:32.547083' order by stylecode;

INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty)
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_heels sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on 'UK '||sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	where sd.dateinsert = '2020-12-03 19:42:32.547083'
	order by pr.prod_id,rs.size_id;
---------------------Heels 2--- end-----------
--------------Bellies,wedges,flats_bellies_csv----Begin-----------
COPY public.sampledata_bellies(stylecode,description,sku,mrp,usd,qty,colour,productname,size,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies,wedges,flats_bellies_csv.csv' DELIMITER ',' CSV HEADER;
UPDATE sampledata_bellies set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
-----------------------
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(size),size,1 from sampledata_bellies where dateinsert ='2020-12-03 20:12:50.831904' and size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  ---0 Row
	select distinct(colour),substring(trim(colour),0,4) from sampledata_bellies where dateinsert ='2020-12-03 20:12:50.831904' and 
	colour not in (select colour_value from ref_colour)
-------Insert Products----
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,7 from sampledata_bellies
	where dateinsert ='2020-12-03 20:12:50.831904'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --24 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_bellies sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	where sd.dateinsert ='2020-12-03 20:12:50.831904'
	order by pr.prod_id,rs.size_id
--------------Bellies,wedges,flats_bellies_csv----End-----------
-------------Bellies,wedges,flats_wedges_csv----Begin-----------
COPY public.sampledata_wedges(stylecode,description,sku,mrp,usd,size,qty,colour,productname,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies,wedges,flats_wedges_csv.csv' DELIMITER ',' CSV HEADER;
UPDATE sampledata_wedges set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
-----------------------
select distinct(dateinsert) from sampledata_wedges
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(size),size,1 from sampledata_wedges where dateinsert ='2020-12-04 00:33:45.295146' and size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  ---1 Row
	select distinct(colour),substring(trim(colour),0,4) from sampledata_wedges where dateinsert ='2020-12-04 00:33:45.295146' and 
	colour not in (select colour_value from ref_colour)
-------Insert Products----
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --19 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,4 from sampledata_wedges
	where dateinsert ='2020-12-04 00:33:45.295146'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --114 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_wedges sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	where sd.dateinsert ='2020-12-04 00:33:45.295146'
	order by pr.prod_id,rs.size_id
-------------Bellies,wedges,flats_wedges_csv----End-----------	
-------------Bellies,wedges,flats_flats_csv----Begin-----------
select * from sampledata_flats where dateinsert ='2020-12-04 00:58:54.520789'
COPY public.sampledata_flats(stylecode,description,sku,mrp,usd,size,qty,colour,productname,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies,wedges,flats_flats_csv.csv' DELIMITER ',' CSV HEADER;
UPDATE sampledata_flats set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
-----------------------
select distinct(dateinsert) from sampledata_flats
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(size),size,1 from sampledata_flats where dateinsert ='2020-12-04 00:58:54.520789' and size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  ---0 Rows
	select distinct(colour),substring(trim(colour),0,4) from sampledata_flats where dateinsert ='2020-12-04 00:58:54.520789' and 
	colour not in (select colour_value from ref_colour)
-------Insert Products----
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --5 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,2 from sampledata_flats
	where dateinsert ='2020-12-04 00:58:54.520789'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) -- 30rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_flats sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	where sd.dateinsert ='2020-12-04 00:58:54.520789'
	order by pr.prod_id,rs.size_id
-------------Bellies,wedges,flats_flats_csv----End-----------
---------------Bellies,heels,flats_bellies_csv---Begin------
select * from sampledata_bellies where dateinsert ='2020-12-04 01:23:38.247821' and colour='Multi'
COPY public.sampledata_bellies(stylecode,description,sku,mrp,usd,size,qty,colour,productname,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies,heels,flats_bellies_csv.csv' DELIMITER ',' CSV HEADER;
UPDATE sampledata_bellies set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
UPDATE sampledata_bellies set colour = 'Multicolour', productname='Multicolour Bellies'
where dateinsert ='2020-12-04 01:23:38.247821' and colour='Multi';
-----------------------
select distinct(dateinsert) from sampledata_bellies
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(size),size,1 from sampledata_bellies where dateinsert ='2020-12-04 01:23:38.247821' and size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  ---0 Rows
	select distinct(colour),substring(trim(colour),0,4) from sampledata_bellies where dateinsert ='2020-12-04 01:23:38.247821' and 
	colour not in (select colour_value from ref_colour)
-------Insert Products----
select * from product_sub_category
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,7 from sampledata_bellies
	where dateinsert ='2020-12-04 01:23:38.247821'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --291 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_bellies sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	where sd.dateinsert ='2020-12-04 01:23:38.247821'
	order by pr.prod_id,rs.size_id
-----------------Bellies,heels,flats_bellies_csv---End------------
---------------------Home essentials------Begin-----------------
CREATE TABLE public.sampledata_homeessential(
		stylecode varchar(250),	
		description text,
		sku	varchar(50),
		mrp numeric,
		usd numeric,
		qty smallint,
		colour varchar(20),
		productname varchar(100),
		size varchar(10),		
		model varchar(100),
		model2 varchar(100),
		model3 varchar(100),
		model4 varchar(100),
		model5 varchar(100),
		dateinsert timestamp
	)
	
COPY public.sampledata_homeessential(stylecode,productname,description,mrp,usd,colour,model,model2,model3,qty) 
	FROM 'F:\KP\SB\Data\Home Essential\home essentials_csv.csv' DELIMITER ',' CSV HEADER;
	
update sampledata_homeessential set dateinsert= now()
update sampledata_homeessential set stylecode = 'Pen/brush/cutlery Holder Orange Round' where
model='https://www.dropbox.com/s/a4ygsz74qxijaq9/Photo%2026-11-19%2C%206%2014%2052%20PM.jpg?dl=0';

----------Inserting Colours-----------
update sampledata_homeessential set colour = 'Orange' where trim(colour) = 'Orange.'
update sampledata_homeessential set colour = 'Black' where trim(colour) = 'Black.'
update sampledata_homeessential set colour = 'Silver' where trim(colour) = 'Silver.'

INSERT INTO ref_colour (colour_value,colour_code)   --- 5 Rows
	select distinct(trim(colour)),substring(trim(colour),0,4) from sampledata_homeessential where 
	trim(colour) not in (select colour_value from ref_colour)
	
-------------Inserting Products--------------
INSERT INTO product_category (prod_category) values ('Home Essential')
select * from product_sub_category -- HD-8
INSERT INTO product_sub_category(prod_category_id, prod_subcateg_name) values (3, 'Home Decor')

INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --60 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,8 from sampledata_homeessential --- Add Prod Subcateg id as per ypur db
	 order by stylecode;

update sampledata_homeessential set qty = 5

INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_colour,prod_qty)
	select  pr.prod_id,sd.mrp, sd.usd, rc.colour_id, sd.qty from sampledata_homeessential sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_colour rc on trim(sd.colour)= rc.colour_value
	order by pr.prod_id;
--------------Home Decor end----------------------------
--------------Bellies-Final------Begin
select * from sampledata_bellies
select * from product_sub_category where prod_category_id=1----2,3,4,7
delete from product_details
where prod_id in (select  prod_id from product where prod_subcateg_id in (2,3,4,7))
delete from product where prod_subcateg_id in (2,3,4,7)---129 rows

COPY public.sampledata_bellies(stylecode,productname,description,sku,mrp,usd,size,qty,colour,model,model2,model3,model4,model5) --255 rows
	FROM 'F:\KP\SB\Data\footwear\bellies_final_csv.csv' DELIMITER ',' CSV HEADER;

update sampledata_bellies set dateinsert=now() where dateinsert is null

select distinct(dateinsert) from sampledata_bellies--- "2020-12-10 23:40:02.934108"

INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(trim(size),trim(size),1) from sampledata_bellies where dateinsert ='2020-12-10 23:40:02.934108' 
					and trim(size) not in (select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
UPDATE sampledata_bellies set colour='Multicolour' where colour='Multi'
INSERT INTO ref_colour (colour_value,colour_code)  ---1 Row
	select distinct(trim(colour)),substring(trim(colour),0,4) from sampledata_bellies where dateinsert ='2020-12-10 23:40:02.934108' and 
	colour not in (select colour_value from ref_colour)
-------Insert Products----
select * from product_sub_category
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)  --39 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,7 from sampledata_bellies
	where dateinsert ='2020-12-10 23:40:02.934108'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --255 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_bellies sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on trim(sd.colour)= rc.colour_value
	where sd.dateinsert ='2020-12-10 23:40:02.934108'
	order by pr.prod_id,rs.size_id
--------------Bellies-Final------End
ALTER TABLE product_details ADD CONSTRAINT product_details_unique_record UNIQUE (prod_id,prod_inr_price,prod_usd_price,prod_colour,prod_size,prod_qty);
------------Bellies,heels,flats-Heels----------Begin-----------------
--------------------------Data Import---------
select distinct(dateinsert) from sampledata_heels where dateinsert is null---"2020-12-11 18:13:50.183101"
COPY public.sampledata_heels(stylecode,productname,description,sku,mrp,usd,size,qty,colour,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies,heels,flats-Final-Heels_csv.csv' DELIMITER ',' CSV HEADER; --84 rows
	
UPDATE sampledata_heels set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
--------------Insert size----------
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(trim(size),trim(size),1) from sampledata_heels where dateinsert ='2020-12-11 18:13:50.183101' 
					and trim(size) not in (select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
------- Inserting Colours---------------
INSERT INTO ref_colour (colour_value,colour_code)   --- 0 Row
	select distinct(trim(colour)),substring(trim(colour),0,4) from sampledata_heels where dateinsert = '2020-12-11 18:13:50.183101' and
	trim(colour) not in (select colour_value from ref_colour)
-------Inserting Products---------------
select * from product_sub_category  --- heels=3
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --15 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,3 from sampledata_heels --- Add Prod Subcateg id as per ypur db
	where dateinsert = '2020-12-11 18:13:50.183101' order by stylecode;

INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty)
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_heels sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on trim(sd.colour)= rc.colour_value
	where sd.dateinsert = '2020-12-11 18:13:50.183101'
	order by pr.prod_id,rs.size_id;
------------Bellies,heels,flats-Heels----------End-----------------
------------Bellies,heels,flats-Final-Flats-------Begin
COPY public.sampledata_flats(stylecode,productname,description,sku,mrp,usd,qty,colour,size,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies,heels,flats-Final-Flats_csv.csv' DELIMITER ',' CSV HEADER;---751 rows
UPDATE sampledata_flats set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
select distinct(dateinsert) from sampledata_flats----"2020-12-11 18:37:22.958961"
-----------------------
select distinct(dateinsert) from sampledata_flats
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(size),size,1 from sampledata_flats where dateinsert ='2020-12-11 18:37:22.958961' and size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  ---1 Row
	select distinct(trim(colour)),substring(trim(colour),0,4) from sampledata_flats where dateinsert ='2020-12-11 18:37:22.958961' and 
	trim(colour) not in (select colour_value from ref_colour)
-------Insert Products----
select * from product_sub_category---flats=2
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --110 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,2 from sampledata_flats
	where dateinsert ='2020-12-11 18:37:22.958961'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
update sampledata_flats set stylecode='802_blue_2' where productname='Women Flat Sandals' and stylecode='802_blue'

INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)
	select distinct(stylecode), productname, description,now()::timestamp,2 from sampledata_flats where 
	productname='Women Flat Sandals' and stylecode='802_blue_2';
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) -- 751rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_flats sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	where sd.dateinsert ='2020-12-11 18:37:22.958961'
	order by pr.prod_id,rs.size_id
------------Bellies,heels,flats-Final-Flats-------End
---------------------Heels_final_csv-------Begin
--------------------------Data Import---------
select distinct(dateinsert) from sampledata_heels where dateinsert is null---""2020-12-12 00:14:29.248489""
COPY public.sampledata_heels(stylecode,productname,description,sku,mrp,usd,size,qty,colour,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Heels_final_csv.csv' DELIMITER ',' CSV HEADER; --104 rows
	
UPDATE sampledata_heels set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
--------------Insert size----------
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(trim(size),trim(size),1) from sampledata_heels where dateinsert ='2020-12-12 00:14:29.248489' 
					and trim(size) not in (select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
------- Inserting Colours---------------
INSERT INTO ref_colour (colour_value,colour_code)   --- 0 Row
	select distinct(trim(colour)),substring(trim(colour),0,4) from sampledata_heels where dateinsert = '2020-12-12 00:14:29.248489' and
	trim(colour) not in (select colour_value from ref_colour)
-------Inserting Products---------------
select * from product_sub_category  --- heels=3

update sampledata_heels set stylecode='1817_MULTI_2' where 
stylecode='1817_MULTI' and dateinsert='2020-12-12 00:14:29.248489'

INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --03ows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,3 from sampledata_heels --- Add Prod Subcateg id as per ypur db
	where dateinsert = '2020-12-12 00:14:29.248489' order by stylecode;

INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty)---18 rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_heels sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on trim(sd.colour)= rc.colour_value
	where sd.dateinsert = '2020-12-12 00:14:29.248489'
	order by pr.prod_id,rs.size_id;
------------------------------------Heels_final_csv-------End------
--------------Bellies and wedges_bellies_csv------Begin
COPY public.sampledata_bellies(stylecode,productname,description,sku,mrp,usd,size,qty,colour,model,model2,model3,model4,model5) --30 rows
	FROM 'F:\KP\SB\Data\footwear\Bellies and Wedges-Bellies_csv.csv' DELIMITER ',' CSV HEADER;

update sampledata_bellies set dateinsert=now() where dateinsert is null

select distinct(dateinsert) from sampledata_bellies--- "2020-12-13 01:41:14.344349"

INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(trim(size),trim(size),1) from sampledata_bellies where dateinsert ='2020-12-13 01:41:14.344349' 
					and trim(size) not in (select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----

INSERT INTO ref_colour (colour_value,colour_code)  ---0 Row
	select distinct(trim(colour)),substring(trim(colour),0,4) from sampledata_bellies where dateinsert ='2020-12-13 01:41:14.344349' and 
	colour not in (select colour_value from ref_colour)
-------Insert Products----
select * from product_sub_category
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id)  --
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,7 from sampledata_bellies
	where dateinsert ='2020-12-13 01:41:14.344349'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --30 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_bellies sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on trim(sd.colour)= rc.colour_value
	where sd.dateinsert ='2020-12-13 01:41:14.344349'
	order by pr.prod_id,rs.size_id
--------------Bellies and Wedges - Bellies_csv-------end
-------------Bellies and Wedges - wedges_csv----Begin-----------
select * from sampledata_wedges where dateinsert is null
COPY public.sampledata_wedges(stylecode,productname,description,sku,mrp,usd,size,qty,colour,model,model2,model3,model4,model5) 
	FROM 'F:\KP\SB\Data\Footwear\Bellies and Wedges-Wedges_csv.csv' DELIMITER ',' CSV HEADER; --78 Rows
UPDATE sampledata_wedges set dateinsert = now() where dateinsert is null --- Use the latest date for items imported in this iteration
-----------------------
select distinct(dateinsert) from sampledata_wedges --"2020-12-13 01:48:59.264865"
INSERT INTO ref_size (size_value,size_code, prod_category_id) --- 0 Rows
	select distinct(size),size,1 from sampledata_wedges where dateinsert ='2020-12-13 01:48:59.264865' and size not in 
	(select size_value from ref_size where prod_category_id=1)---- Use prod_category_id as per your db
-------Insert Colour-----
INSERT INTO ref_colour (colour_value,colour_code)  ---0 Row
	select distinct(colour),substring(trim(colour),0,4) from sampledata_wedges where dateinsert ='2020-12-13 01:48:59.264865' and 
	colour not in (select colour_value from ref_colour)
-------Insert Products----
select * from product_sub_category---wedges=4
INSERT INTO product (prod_stylecode,prod_name,prod_desc,prod_datetimeinserted,prod_subcateg_id) --13 Rows
	select distinct on (stylecode) stylecode, productname, description,now()::timestamp,4 from sampledata_wedges
	where dateinsert ='2020-12-13 01:48:59.264865'--- Add Prod Subcateg id as per ypur db
	order by stylecode;
	
INSERT INTO product_details (prod_id,prod_inr_price,prod_usd_price,prod_size,prod_colour,prod_qty) --78 Rows
	select  pr.prod_id,sd.mrp, sd.usd, rs.size_id, rc.colour_id, sd.qty from sampledata_wedges sd 
	inner join product pr on sd.stylecode = pr.prod_stylecode
	inner join ref_size rs on sd.size = rs.size_value
	inner join ref_colour rc on sd.colour= rc.colour_value
	where sd.dateinsert ='2020-12-13 01:48:59.264865'
	order by pr.prod_id,rs.size_id
-------------Bellies and Wedges - wedges_csv---End-----------	
