CREATE OR REPLACE PROCEDURE spImageInsertUpdateDelete(
	_ser integer,
	_prodid integer,
	_name1 VARCHAR(20) DEFAULT NULL,
	_img1path TEXT DEFAULT NULL,
	_name2 VARCHAR(20) DEFAULT NULL,
	_img2path TEXT DEFAULT NULL,
	_name3 VARCHAR(20) DEFAULT NULL,
	_img3path TEXT DEFAULT NULL,
	_name4 VARCHAR(20) DEFAULT NULL,
	_img4path TEXT DEFAULT NULL,
	_name5 VARCHAR(20) DEFAULT NULL,
	_img5path TEXT DEFAULT NULL,
	_imgid integer DEFAULT NULL
)

LANGUAGE 'plpgsql'

AS $BODY$
	DECLARE  
	_sql TEXT := 'INSERT INTO product_image (prod_id, prod_img_name, prod_img_path) 
	 		VALUES ($2,$3,$4)';
	_val text;
			

BEGIN 

	IF _ser = 1 THEN -- insert
-- 		INSERT INTO product_image (prod_id, prod_img_name, prod_img_path) 
-- 		VALUES (_prodid,_name1, _imgpath1),(_prodid, _name2, _imgpath2),(_prodid, _name3, _imgpath3),
-- 				(_prodid, _name4, _imgpath4),(_prodid, _name5, _imgpath5);
		_val = CONCAT (
				CASE WHEN _name2 IS NOT NULL THEN ',($2,$5,$6)' END,
				CASE WHEN _name3 IS NOT NULL THEN ',($2,$7,$8)' END,
				CASE WHEN _name4 IS NOT NULL THEN ',($2,$9,$10)' END,
				CASE WHEN _name5 IS NOT NULL THEN ',($2,$11,$12)' END
		);
		
		IF _val <> '' THEN
			_sql := _sql || _val ||';';
		ELSE
			_sql := _sql || ';';
		END IF;
		
		EXECUTE _sql
		USING _ser,_prodid,_name1,_img1path,_name2,_img2path,
			  _name3, _img3path, _name4, _img4path, _name5, _img5path;
	
	ELSEIF _ser = 2 THEN --update
		UPDATE product_image set
		 prod_img_name = _name1,
		 prod_img_path = _img1path
		 where prod_img_id = _imgid;
		 
	ELSEIF _ser = 3 THEN --DELETE
		DELETE FROM product_image WHERE prod_img_id=_imgid;
	
	END IF;
		 
	

END


$BODY$;

