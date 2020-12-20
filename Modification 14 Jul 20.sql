--14 Jul 20---
/*
Run the following command of adding a column before executing spProdCategoryInsertUpdateDelet
*/
ALTER TABLE product_category
ADD COLUMN prod_category_datetill TIMESTAMP DEFAULT NULL

-------------------------17 Jul 20-----------------------
/* Create Images table---- Begin*/
CREATE TABLE product_image (
	
	prod_img_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
	prod_id INTEGER REFERENCES product(prod_id),
	prod_img_name VARCHAR(20) NOT NULL,
	prod_img_path TEXT
);
/* Create Images table---- End*/

-------------------18 Jul 20-----------------------------

CREATE TABLE coupon(
	coupon_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	coupon_code VARCHAR(20) NOT NULL,
	coupon_value VARCHAR(20) NOT NULL
);

---------------------19 Jul 20---------------

ALTER TABLE coupon
ADD COLUMN coupon_datetill TIMESTAMP DEFAULT NULL

----------------------04 Aug 20------------------
-----Create table ref_size---------------Begin
-- Table: public.ref_size

-- DROP TABLE public.ref_size;

CREATE TABLE public.ref_size
(
    size_code character varying(20) COLLATE pg_catalog."default" NOT NULL,
    size_value character varying(50) COLLATE pg_catalog."default" NOT NULL,
    prod_category_id integer NOT NULL,
    size_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    size_datetill timestamp without time zone,
    CONSTRAINT ref_size_pkey PRIMARY KEY (size_id),
    CONSTRAINT ref_size_prod_category_id_fkey FOREIGN KEY (prod_category_id)
        REFERENCES public.product_category (prod_category_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE public.ref_size
    OWNER to postgres;
-----Create table ref_size---------------End

------------------------09 Aug 20------------------------------

-----Create Table ref_colour-----begin

-- DROP TABLE public.ref_colour;

CREATE TABLE public.ref_colour
(
    colour_code character varying(20) COLLATE pg_catalog."default" NOT NULL,
    colour_value character varying(50) COLLATE pg_catalog."default" NOT NULL,
    colour_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    colour_datetill timestamp without time zone,
    CONSTRAINT ref_colour_pkey PRIMARY KEY (colour_id)
)

TABLESPACE pg_default;

ALTER TABLE public.ref_colour
    OWNER to postgres;
-----Create Table ref_colout-----end---

-----------------04 Oct 20------------------

---Columns added in product table and renamed in product_subcategory table---------
alter table product
add column prod_name varchar(50);

alter table product
add column prod_desc text;

alter table product_sub_category
rename prod_name to prod_subcateg_name;


alter table product_sub_category
rename prod_desc to prod_subcateg_desc;

------------------11 Oct 20-------------------------
--- Restructured Product table and created product_details table
create table product(
	
	  prod_id INTEGER PRIMARY KEY NOT NULL GENERATED ALWAYS AS IDENTITY
	, prod_subcateg_id INTEGER 
	, prod_name VARCHAR(50)
	, prod_desc TEXT
	, prod_datetill TIMESTAMP
	
	,CONSTRAINT fk_prod_subcateg FOREIGN KEY(prod_subcateg_id) REFERENCES product_sub_category(prod_subcateg_id)
)

create table product_details(
	  pd_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY
	, prod_id INTEGER REFERENCES product(prod_id)
	, prod_inr_price numeric
	, prod_usd_price numeric
	, prod_colour INTEGER REFERENCES ref_colour(colour_id)
	, prod_size INTEGER REFERENCES ref_size(size_id)
	, prod_qty integer
)
----------------------08 Nov 20----------------------------------------------
-----Order table modification---------
alter table store.order
add column coupon_id integer references public.coupon(coupon_id)

alter table store.order
add column user_discount varchar

---------------------12 Nov 20--------------------------------------------
-----Product Table Modification------------------
alter table product
add column prod_datetimeinserted TIMESTAMP

------------------16 Nov 20----------------------
-----Product Table Modification------------------
alter table product
add column prod_trending boolean default False,
add column prod_latest boolean default false;


-----------------19 Nov 20-------------------
-------------store.orderdetails table modification---------
alter table store.orderdetails
add column orderdetail_return VARCHAR(20),
 ADD COLUMN orderdetail_returnpayment VARCHAR(10);
 
-----------03 Dec 20-------------
----Product table modified------
ALTER TABLE product
RENAME prod_sku to prod_stylecode;
ALTER TABLE product ADD CONSTRAINT product_UniqueStylecode UNIQUE (prod_stylecode);

-----07 Dec 20-----
----- Open the store.order_view in create script mode---
--- In seperate query do the following----
drop view store.order_view
ALTER TABLE product alter prod_name type VARCHAR(150)
update product set prod_name = prod_desc where prod_subcateg_id=5;--177 rows
update product set prod_name = prod_desc where prod_subcateg_id=6;--181 rows
---Create store.order_view again----


-----20 Dec 20-----
-----Updating USD value of lingerie-----------
update product_details  set prod_usd_price = trunc(((prod_inr_price * 2.5)/ 70),2) where
prod_id in (select prod_id from product where prod_subcateg_id in (5,6));




