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
