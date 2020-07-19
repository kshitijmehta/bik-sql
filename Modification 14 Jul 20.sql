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
