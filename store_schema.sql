BEGIN;

set client_encoding='UTF8';

DROP SCHEMA IF EXISTS store CASCADE;
CREATE SCHEMA store;

CREATE TABLE store.payment(
	payment_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	payment_type VARCHAR(20) NOT NULL,
	payment_available BOOLEAN NOT NULL DEFAULT 'FALSE'
)

CREATE TABLE store.order(
	order_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id INTEGER NOT NULL REFERENCES public.users(user_id),
	order_number INTEGER,
	address_id integer references public.user_address(addr_id),
	order_date TIMESTAMP,
	order_totalprice NUMERIC,	
	order_paymentdate TIMESTAMP,
	payment_id INTEGER REFERENCES store.payment(payment_id)
)

CREATE INDEX ON store.order(user_id);


CREATE TABLE store.shippers(
	shipper_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	shipper_companyname VARCHAR(50),
	shipper_mobile VARCHAR(10)
)

CREATE TABLE store.shipments(
	shipment_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	shipper_id INTEGER REFERENCES store.shippers(shipper_id),
	shipment_date TIMESTAMP,
	shipment_trackingnumber INTEGER,
	shipment_deliverydate TIMESTAMP
);

CREATE TABLE store.orderdetails(
	orderdetail_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	order_id INTEGER REFERENCES store.order(order_id),
	prod_id INTEGER REFERENCES public.product(prod_id),
	orderdetail_qty INTEGER,
	orderdetail_price NUMERIC,
	orderdetail_price_id integer,
	orderdetail_linetotal NUMERIC GENERATED ALWAYS AS (orderdetail_qty * orderdetail_price) STORED,
	shipment_id INTEGER REFERENCES store.shipments(shipment_id)	
);

CREATE INDEX ON store.orderdetails(order_id);


--------- View for Order------------

CREATE VIEW store.order_view AS
	SELECT o.order_id,
	o.user_id,
	CONCAT(u.user_fname,' ',u.user_lname) AS "Name",
	o.order_date,
	o.order_totalprice,
	o.order_paymentdate,
	py.payment_type,
	(
		select json_agg(ll) as orderitems from (
			select l.orderdetail_id, l.prod_id, ps.prod_name, l.orderdetail_qty,l.orderdetail_price
			from store.orderdetails l
			INNER JOIN public.product pr on l.prod_id= pr.prod_id
			INNER JOIN public.product_sub_category ps on pr.prod_subcateg_id = ps.prod_subcateg_id
				WHERE l.order_id=o.order_id			
		) ll
	)
	FROM store.order o
	INNER JOIN public.users u on o.user_id=u.user_id
	INNER JOIN store.payment py on o.payment_id=py.payment_id;

----------------------------SP for New Order----------------------------------
----- input - user_id
----- output - new order_id
CREATE OR REPLACE FUNCTION store.cart_new_id (_uid INTEGER, OUT id INTEGER)

LANGUAGE 'plpgsql'
AS
$BODY$
	
	BEGIN
		
		INSERT INTO store.order (user_id)
		select u.user_id from public.users u 
		where u.user_id = _uid
		RETURNING store.order.order_id into id;
		
	END;
$BODY$;

----------------------- function to view cart id i.e. unpaid order--------------

---- input  - user_id
---- output - order_id that is still open - null if none

CREATE OR REPLACE FUNCTION store.fn_cart_get_id(_uid INTEGER, OUT id INTEGER)

LANGUAGE 'plpgsql'
AS
$BODY$

	BEGIN
		SELECT o.order_id INTO id
		FROM store.order o
		where o.user_id = _uid
		AND o.order_paymentdate is null;
		
	END;

$BODY$;

----------------- Function to insert order line items-----------Begin-------

---- input - user_id, prod_id, prod_price,price_id,Qty

CREATE OR REPLACE FUNCTION store.order_item_add (_uid INTEGER, _pid INTEGER, _price NUMERIC, _prid INTEGER,
												 _qty INTEGER,OUT status SMALLINT, out js JSON)
LANGUAGE 'plpgsql'
AS
$BODY$
	DECLARE
		cart_id INTEGER;
		line_id INTEGER;
		prod_price NUMERIC;
		e6 text; e7 text; e8 text; e9 text;
	BEGIN
		SELECT id into cart_id FROM store.fn_cart_get_id(_uid);
		IF cart_id is null THEN
			SELECT id into cart_id FROM store.cart_new_id(_uid);
		END IF;
		SELECT orderdetail_id into line_id 
		FROM store.orderdetails WHERE order_id =cart_id
		AND prod_id = _pid;
		IF line_id IS NULL THEN
			INSERT INTO store.orderdetails (order_id, prod_id, orderdetail_qty, orderdetail_price, orderdetail_price_id)
						VALUES			    (cart_id, _pid	 , _qty			  , _price			 , _prid)
						RETURNING orderdetail_id into line_id;
		ELSE
			--This will check if the existing price in orderdetails is same or not. If not it will update the price as well.
			SELECT orderdetail_price into prod_price
			FROM store.orderdetails WHERE orderdetail_id = line_id;
			IF prod_price == _price THEN
				UPDATE store.orderdetails 
				SET orderdetail_qty = orderdetail_qty + _qty
				WHERE orderdetail_id = line_id;
			ELSE
				RAISE INFO 'Price of one of the items in your cart has been updated';
				UPDATE store.orderdetails 
				SET  orderdetail_qty = orderdetail_qty + _qty
					,orderdetail_price = _price
				WHERE orderdetail_id = line_id;
			END IF;
		END IF;
		status := 200;
		js := row_to_json(r.*) from store.orderdetails r where orderdetail_id = line_id;
	
	EXCEPTION 
		
		when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
		js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
		status := 500;
				
	END;
$BODY$;


----------------- Function to insert order line items-----------End-------


----------------- Procedure to delete order line items-----------Begin-------
CREATE OR REPLACE PROCEDURE store.order_item_delete ( _odid INTEGER, inout status SMALLINT, INOUT js json)
LANGUAGE 'plpgsql'
AS $BODY$

	declare
	e6 text; e7 text; e8 text; e9 text;
	BEGIN
		
		js := row_to_json(r.*) from store.orderdetails r where orderdetail_id = _odid;
		status := 200;
		if js is null then
			status := 404;
			js := '{}';
		else
			delete from store.orderdetails where orderdetail_id = _odid;
		end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
	
	END
$BODY$;
----------------- Procedure to delete order line items-----------End-------


-- do $$
-- declare s smallint; j json;
-- begin
-- call store.order_item_delete(1,s,j);
-- end
-- $$;

------------Procedure to Update order line items-----------------Begin--------
--Input = Orderdetails_id, Qty
CREATE OR REPLACE PROCEDURE store.order_item_update (_odid INTEGER, _qty INTEGER,
													INOUT status SMALLINT, INOUT js JSON)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE e6 text; e7 text; e8 text; e9 text;

BEGIN
	
	PERFORM 1 FROM store.orderdetails where orderdetail_id=_odid;
	IF NOT FOUND THEN
		status := 404;
		js := '{}';
	
	ELSEIF _qty > 0 THEN
		UPDATE store.orderdetails
		SET orderdetail_qty = _qty
		WHERE orderdetail_id = _odid;
		status := 200;
		js := row_to_json(r.*) from store.orderdetails r where orderdetail_id=_odid;
	
	ELSE
		DELETE FROM store.orderdetails where orderdetail_id = _odid;
		status := 200;
		js := '{}';
	END IF;
EXCEPTION
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
		
END;

$BODY$;
------------Procedure to Update order line items-----------------END--------

-----------Function to get Order ---------------------------------Begin-----
----Input - order id
CREATE OR REPLACE FUNCTION store.fn_order_get(_oid INTEGER, 
											  OUT status SMALLINT, OUT js JSON)
LANGUAGE 'plpgsql'
AS $BODY$

BEGIN
	
	js := row_to_json(r) from (
			select * from store.order_view WHERE order_id =_oid) r;
	status := 200;
	IF js IS NULL THEN
		js:='{}';
		status := 400;
	END IF;

END;

$BODY$;

-----------Function to get Order ---------------------------------End----

-----------Procedure for order payment----------------------Start--------
-------Input : OrderId,totalprice, payment_id
CREATE OR REPLACE PROCEDURE store.order_paid(_oid INTEGER, _price NUMERIC, _payid INTEGER,
											INOUT status SMALLINT, INOUT js JSON)
LANGUAGE 'plpgsql'
AS $BODY$
declare
	e6 text; e7 text; e8 text; e9 text;
	
BEGIN
	
	UPDATE store.order
	SET order_paymentdate = now(),
		order_totalprice = _price,
		payment_id = _payid
	WHERE order_id = _oid
	AND order_paymentdate IS NULL;
	SELECT x.status, x.js INTO status, js
	FROM store.fn_order_get(_oid) x;
	exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;

END;
$BODY$;

---------------------------------Function to get cart of a user------------------------------
CREATE OR REPLACE FUNCTION fn_get_cart (_userid INTEGER,
					OUT status SMALLINT, OUT js JSON)

LANGUAGE 'plpgsql'

AS $BODY$
	BEGIN
		js:= row_to_json(r) from (
									select ps.prod_subcateg_name, p.prod_name
											, a.orderdetail_price, a.orderdetail_qty
											, a.orderdetail_linetotal, pi.prod_img_path from store.orderdetails a
									inner join product p on a.prod_id=p.prod_id
									inner join product_sub_category ps on p.prod_subcateg_id = ps.prod_subcateg_id
									inner join product_image pi on  a.prod_id = pi.prod_id
									inner join store.order oe on a.order_id = oe.order_id
									where oe.user_id = _userid
									and prod_img_path = (select prod_img_path from product_image where prod_id= a.prod_id LIMIT 1)
									
									) r;
		status := 200;
		
		
		

	END;

$BODY$;




COMMIT;

------------------------Kshitij
-- FUNCTION: store.order_item_add(integer, integer, integer, integer)

-- DROP FUNCTION store.order_item_add(integer, integer, integer, integer);

CREATE OR REPLACE FUNCTION store.order_item_add(
	_uid integer,
	_prid integer,
	_qty integer,
	_pdid integer,
	OUT status smallint,
	OUT js json)
    RETURNS record
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    
AS $BODY$
	DECLARE
		cart_id INTEGER;
		line_id INTEGER;
		prod_price NUMERIC;
		client_price NUMERIC;
		price_inr NUMERIC;
		price_usd NUMERIC;
		e6 text; e7 text; e8 text; e9 text;
	BEGIN
		-- creating cartid
		SELECT id into cart_id FROM store.fn_cart_get_id(_uid);
		IF cart_id is null THEN
			SELECT id into cart_id FROM store.cart_new_id(_uid);
		END IF;
		-- selecting current price
		SELECT prod_inr_price, prod_usd_price into price_inr,price_usd
		FROM product_details where pd_id = _pdid;
		-- checking for product already in cart
		SELECT orderdetail_id into line_id 
		FROM store.orderdetails WHERE order_id =cart_id
		AND prod_detail_id = _pdid;
		-- setting price INR or USD based on clien
		IF _prid = 1 THEN
			client_price = price_inr;
		ELSE
			client_price = price_usd;
		END IF;
		IF line_id IS NULL THEN
			INSERT INTO store.orderdetails (order_id, prod_detail_id, orderdetail_qty, orderdetail_price, orderdetail_price_id)
						VALUES			    (cart_id, _pdid	 , _qty			  , client_price			 , _prid)
						RETURNING orderdetail_id into line_id;
		ELSE
			--This will check if the existing price in orderdetails is same or not. If not it will update the price as well.
			SELECT orderdetail_price into prod_price
			FROM store.orderdetails WHERE orderdetail_id = line_id;
			IF prod_price = client_price THEN
				UPDATE store.orderdetails 
				SET orderdetail_qty = orderdetail_qty + _qty
				WHERE orderdetail_id = line_id;
			ELSE
				RAISE INFO 'Price of one of the items in your cart has been updated';
				UPDATE store.orderdetails 
				SET  orderdetail_qty = orderdetail_qty + _qty
					,orderdetail_price = client_price
				WHERE orderdetail_id = line_id;
			END IF;
		END IF;
		status := 200;
		js := row_to_json(r.*) from store.orderdetails r where orderdetail_id = line_id;
	
	EXCEPTION 
		
		when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
		js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
		status := 500;
				
	END;
$BODY$;

ALTER FUNCTION store.order_item_add(integer, integer, integer, integer)
    OWNER TO postgres;
 
----------------------------------------------------------Kshitij
-- Table: store.orderdetails

-- DROP TABLE store.orderdetails;

CREATE TABLE store.orderdetails
(
    orderdetail_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    order_id integer,
    prod_detail_id integer,
    orderdetail_qty integer,
    orderdetail_price numeric,
    orderdetail_price_id integer,
    orderdetail_linetotal numeric GENERATED ALWAYS AS (((orderdetail_qty)::numeric * orderdetail_price)) STORED,
    shipment_id integer,
    CONSTRAINT orderdetails_pkey PRIMARY KEY (orderdetail_id),
    CONSTRAINT orderdetails_order_id_fkey FOREIGN KEY (order_id)
        REFERENCES store."order" (order_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT orderdetails_prod_detail_id_fkey FOREIGN KEY (prod_detail_id)
        REFERENCES public.product_details (pd_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT orderdetails_shipment_id_fkey FOREIGN KEY (shipment_id)
        REFERENCES store.shipments (shipment_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE store.orderdetails
    OWNER to postgres;
-- Index: fki_orderdetails_prod_detail_id_fkey

-- DROP INDEX store.fki_orderdetails_prod_detail_id_fkey;

CREATE INDEX fki_orderdetails_prod_detail_id_fkey
    ON store.orderdetails USING btree
    (prod_detail_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: orderdetails_order_id_idx

-- DROP INDEX store.orderdetails_order_id_idx;

CREATE INDEX orderdetails_order_id_idx
    ON store.orderdetails USING btree
    (order_id ASC NULLS LAST)
    TABLESPACE pg_default;

