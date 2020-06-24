
-- Database: bik

-- DROP DATABASE bik;

CREATE DATABASE bik
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;


-- Table: public.ref_usr_type

-- DROP TABLE public.ref_usr_type;

CREATE TABLE public.ref_usr_type
(
    usr_typecode character(1) COLLATE pg_catalog."default" NOT NULL,
    usr_typedesc character varying(20) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT ref_usr_type_pkey PRIMARY KEY (usr_typecode)
)

TABLESPACE pg_default;

ALTER TABLE public.ref_usr_type
    OWNER to postgres;


INSERT INTO ref_usr_type VALUES ('c','customer')
INSERT INTO ref_usr_type VALUES ('a','admin')


-- Table: public.users

-- DROP TABLE public.users;

CREATE TABLE public.users
(
    user_id integer NOT NULL DEFAULT nextval('users_usr_id_seq'::regclass),
    user_fname character varying(50) COLLATE pg_catalog."default",
    user_lname character varying(50) COLLATE pg_catalog."default",
    user_gender character(7) COLLATE pg_catalog."default",
    user_dob date,
    user_emailaddr character varying(50) COLLATE pg_catalog."default" NOT NULL,
    user_mobileno character varying(10) COLLATE pg_catalog."default" NOT NULL,
    user_password text COLLATE pg_catalog."default" NOT NULL,
    user_typecode character(1) COLLATE pg_catalog."default",
    user_verified boolean,
    user_discount character varying(10) COLLATE pg_catalog."default",
    user_datetimecreated time without time zone,
    CONSTRAINT users_pkey PRIMARY KEY (user_id),
    CONSTRAINT usr_email_unique UNIQUE (user_emailaddr),
    CONSTRAINT users_usr_typecode_fkey FOREIGN KEY (user_typecode)
        REFERENCES public.ref_usr_type (usr_typecode) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT usr_dob_check CHECK (user_dob > '1900-01-01'::date)
)

TABLESPACE pg_default;

ALTER TABLE public.users
    OWNER to postgres;



-- PROCEDURE: public.spuserinsertupdate(integer, character varying, character varying, text, character, character varying, character varying, character, date, boolean, character varying)

-- DROP PROCEDURE public.spuserinsertupdate(integer, character varying, character varying, text, character, character varying, character varying, character, date, boolean, character varying);

CREATE OR REPLACE PROCEDURE public.spuserinsertupdate(
	_ser integer,
	_email character varying,
	_mobileno character varying,
	_pwd text,
	_typecode character,
	_fname character varying DEFAULT NULL::character varying,
	_lname character varying DEFAULT NULL::character varying,
	_gender character DEFAULT NULL::bpchar,
	_dob date DEFAULT NULL::date,
	_verified boolean DEFAULT false,
	_discount character varying DEFAULT NULL::character varying)
LANGUAGE 'plpgsql'
AS $BODY$

	BEGIN
	    -- Add user
		IF _ser= 1 THEN
			INSERT INTO users (user_emailaddr, user_mobileno, user_password, user_typecode, user_datetimecreated)
			VALUES (_email, _mobileno, _pwd, _typecode ,now());
			
	    -- Update user
		ELSEIF _ser= 2 THEN
			UPDATE users
			SET user_fname = _fname,
				user_lname = _lname,
				user_gender = _gender,
				user_dob = _dob,
				user_mobileno = _mobileno
			WHERE user_emailaddr = _email;
			
		-- Update password
		ELSEIF _ser= 3 THEN
			UPDATE users
			SET user_password = _pwd
			WHERE user_emailaddr = _email;
			
		-- Update verified
		ELSEIF _ser= 4 THEN
			UPDATE users
			SET user_verified = _verified
			WHERE user_emailaddr = _email;
			
		-- Update discount
		ELSEIF _ser= 5 THEN
			UPDATE users
			SET user_discount = _discount
			WHERE user_emailaddr = _email;

		END IF;
				
	END 
$BODY$;



-- Table: public.ref_address_type

-- DROP TABLE public.ref_address_type;

CREATE TABLE public.ref_address_type
(
    addr_type_code character(1) COLLATE pg_catalog."default" NOT NULL,
    addr_type_description character varying(10) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT ref_address_type_pkey PRIMARY KEY (addr_type_code)
)

TABLESPACE pg_default;

ALTER TABLE public.ref_address_type
    OWNER to postgres;


INSERT INTO public.ref_address_type(
	addr_type_code, addr_type_description)
	VALUES ('h', 'home');



-- Table: public.user_address

-- DROP TABLE public.user_address;

CREATE TABLE public.user_address
(
    addr_id integer NOT NULL DEFAULT nextval('usr_address_addr_id_seq'::regclass),
    user_id integer NOT NULL DEFAULT nextval('usr_address_user_id_seq'::regclass),
    addr_serial smallint NOT NULL,
    addr_type_code character(1) COLLATE pg_catalog."default" NOT NULL,
    addr_line1 character varying(40) COLLATE pg_catalog."default" NOT NULL,
    addr_line2 character varying(40) COLLATE pg_catalog."default" DEFAULT NULL::character varying,
    addr_line3 character varying(40) COLLATE pg_catalog."default" DEFAULT NULL::character varying,
    addr_city character varying(30) COLLATE pg_catalog."default" NOT NULL,
    addr_state character varying(30) COLLATE pg_catalog."default" NOT NULL,
    addr_pincode character varying(10) COLLATE pg_catalog."default" NOT NULL,
    addr_country character varying(30) COLLATE pg_catalog."default" NOT NULL,
    addr_datetimecreated timestamp without time zone,
    addr_datetill timestamp without time zone,
    CONSTRAINT usr_address_pkey PRIMARY KEY (addr_id),
    CONSTRAINT usr_address_addr_type_code_fkey FOREIGN KEY (addr_type_code)
        REFERENCES public.ref_address_type (addr_type_code) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT usr_address_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES public.users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE public.user_address
    OWNER to postgres;


-- PROCEDURE: public.spaddressinsertupdatedelete(integer, integer, integer, character, character varying, character varying, character varying, character varying, character varying, character varying, character varying)

-- DROP PROCEDURE public.spaddressinsertupdatedelete(integer, integer, integer, character, character varying, character varying, character varying, character varying, character varying, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.spaddressinsertupdatedelete(
	_ser integer,
	_userid integer,
	_addrserial integer,
	_typecode character,
	_line1 character varying,
	_line2 character varying,
	_line3 character varying,
	_city character varying,
	_state character varying,
	_pincode character varying,
	_country character varying)
LANGUAGE 'plpgsql'
AS $BODY$

begin 
	if _ser =1 then
		
		insert into user_address (user_id, addr_serial, addr_type_code, addr_line1, addr_line2, addr_line3, 
								addr_city, addr_state, addr_pincode,addr_country, addr_datetimecreated)
		values (_userid, _addrserial, _typecode, _line1, _line2, _line3, _city, _state, _pincode,
			   _country, now());
	
	end if;
	
	if _ser=2 then --Update address
	
		update user_address
		set addr_datetill = now()
		where user_id=_userid;
		
		insert into user_address (user_id, addr_serial, addr_type_code, addr_line1, addr_line2, addr_line3, 
								addr_city, addr_state, addr_pincode,addr_country, addr_datetimecreated)
		values (_userid, _addrserial, _typecode, _line1, _line2, _line3, _city, _state, _pincode,
			   _country, now());
	end if;

end
$BODY$;


-- FUNCTION: public.personalinfoselect(integer)

-- DROP FUNCTION public.personalinfoselect(integer);

CREATE OR REPLACE FUNCTION public.personalinfoselect(
	_userid integer)
    RETURNS TABLE(userid integer, fname character varying, lname character varying, mobno character varying, dob date, addrline1 character varying, addrline2 character varying, addrline3 character varying, city character varying, state character varying, pincode character varying, country character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
    
AS $BODY$

BEGIN
	
	RETURN QUERY 
	select a.user_id,a.user_fname, a.user_lname, a.user_mobileno,
	a.user_dob,b.addr_line1,b.addr_line2,b.addr_line3,
	b.addr_city, b.addr_state, b.addr_pincode, b.addr_country
	from users a
	inner join user_address b ON b.user_id = a.user_id
	where a.user_id= $1 and b.addr_datetill is null;

END

$BODY$;

ALTER FUNCTION public.personalinfoselect(integer)
    OWNER TO postgres;
