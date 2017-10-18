/* Anonymous program. */
BEGIN
  /* Test record_errors procedure. */
  record_errors( object_name => 'Test Object'
               , module_name => 'Test Module'
               , class_name => 'Test Class'
               , sqlerror_code => 'ORA-00001'
               , sqlerror_message => 'ORA-00001: User Error');
END;
/
 
/* Query test results. */
SELECT ne.object_name
,      ne.module_name
,      ne.sqlerror_code
FROM   nc_error ne;
 
/* Conditionally drop the insert_item procedure. */
BEGIN
  FOR i IN (SELECT   object_name
            ,        object_type
            FROM     user_objects
            WHERE    REGEXP_LIKE(object_name,'^insert_item.*$','i')
            ORDER BY 2 DESC) LOOP
      EXECUTE IMMEDIATE 'DROP '||i.object_type||' '||i.object_name;
  END LOOP;
END;
/
 
/* Create draft insert_item procedure. */
CREATE PROCEDURE insert_item
( pv_item_barcode        VARCHAR2
, pv_item_type           VARCHAR2
, pv_item_title          VARCHAR2
, pv_item_subtitle       VARCHAR2 := NULL
, pv_item_rating         VARCHAR2
, pv_item_rating_agency  VARCHAR2
, pv_item_release_date   DATE ) IS
 
  /* Declare local variables. */
  lv_item_type  NUMBER;
  lv_rating_id  NUMBER;
  lv_user_id    NUMBER := 1;
  lv_date       DATE := TRUNC(SYSDATE);
  lv_control    BOOLEAN := FALSE;
 
  /* Declare conversion cursor. */
  CURSOR item_type_cur
  ( cv_item_type  VARCHAR2 ) IS
    SELECT common_lookup_id
    FROM   common_lookup
    WHERE  common_lookup_table = 'ITEM'
    AND    common_lookup_column = 'ITEM_TYPE'
    AND    common_lookup_type = cv_item_type;
 
  /* Declare conversion cursor. */
  CURSOR rating_cur 
  ( cv_rating         VARCHAR2
  , cv_rating_agency  VARCHAR2 ) IS
    SELECT rating_agency_id
    FROM   rating_agency
    WHERE  rating = cv_rating
    AND    rating_agency = cv_rating_agency;
 
  /*
     Enforce logic validation that the rating, rating agency and 
     media type match. This is a user-configuration area and they
     may need to add validation code for new materials here.
  */
  CURSOR match_media_to_rating 
  ( cv_item_type  NUMBER
  , cv_rating_id  NUMBER ) IS
    SELECT  NULL
    FROM    common_lookup cl CROSS JOIN rating_agency ra
    WHERE   common_lookup_id = cv_item_type
    AND    (common_lookup_type IN ('BLU-RAY','DVD','HD','SD')
    AND     rating_agency_id = cv_rating_id
    AND     rating IN ('G','PG','PG-13','R')
    AND     rating_agency = 'MPAA')
    OR     (common_lookup_type IN ('GAMECUBE','PLAYSTATION','XBOX')
    AND     rating_agency_id = cv_rating_id
    AND     rating IN ('C','E','E10+','T')
    AND     rating_agency = 'ESRB');
 
BEGIN
  /* Get the foreign key of an item type. */
  FOR i IN item_type_cur(pv_item_type) LOOP
    lv_item_type := i.common_lookup_id;
  END LOOP;
 
  /* Get the foreign key of a rating. */
  FOR i IN rating_cur(pv_item_rating, pv_item_rating_agency) LOOP
    lv_rating_id := i.rating_agency_id;
  END LOOP;
 
  /* Only insert when the two foreign key values are set matches. */
  FOR i IN match_media_to_rating(lv_item_type, lv_rating_id) LOOP
 
    INSERT
    INTO   item
    ( item_id
    , item_barcode 
    , item_type
    , item_title
    , item_subtitle
    , item_desc
    , item_release_date
    , rating_agency_id
    , created_by
    , creation_date
    , last_updated_by
    , last_update_date )
    VALUES
    ( item_s1.NEXTVAL
    , pv_item_barcode
    , lv_item_type
    , pv_item_title
    , pv_item_subtitle
    , EMPTY_CLOB()
    , pv_item_release_date
    , lv_rating_id
    , lv_user_id
    , lv_date
    , lv_user_id
    , lv_date );
 
    /* Set control to true. */
    lv_control := TRUE;
 
    /* Commmit the record. */
    COMMIT;
 
  END LOOP;
 
  /* Raise an exception when required. */
  IF NOT lv_control THEN
    RAISE_APPLICATION_ERROR(-20001,'Invalid media and rating.');
  END IF; 
 
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Error ['||SQLERRM||']');
END;
/
 
/* Enable serveroutput. */
SET SERVEROUTPUT ON SIZE UNLIMITED
 
/* Call the insert_item procedure. */
BEGIN
  insert_item( pv_item_barcode => 'B01IOHVPA8'
             , pv_item_type => 'DVD'
             , pv_item_title => 'Jason Bourne'
             , pv_item_rating => 'PG-13'
             , pv_item_rating_agency => 'MPAA'
             , pv_item_release_date => '06-DEC-2016');
END;
/
 
/* Query result from the insert_item procedure. */
COL item_barcode FORMAT A10 HEADING "Item|Barcode"
COL item_title   FORMAT A30 HEADING "Item Title"
COL release_date FORMAT A12 HEADING "Item|Release|Date"
SELECT i.item_barcode
,      i.item_title
,      i.item_release_date AS release_date
FROM   item i
WHERE  i.item_title = 'Jason Bourne';
 
 
/* Conditionally drop the common lookup types, table and then objectWHERE. */
BEGIN
  FOR i IN (SELECT   type_name
            FROM     user_types
            WHERE    type_name IN ('ITEM_OBJ','ITEM_TAB')
            ORDER BY 1 DESC) LOOP
    EXECUTE IMMEDIATE 'DROP TYPE '||i.type_name;
  END LOOP;
END;
/
 
/* Create an item object type. */
CREATE OR REPLACE
  TYPE item_obj IS OBJECT
  ( item_barcode        VARCHAR2(20)
  , item_type           VARCHAR2(7)
  , item_title          VARCHAR2(60)
  , item_subtitle       VARCHAR2(60)
  , item_rating         VARCHAR2(8)
  , item_rating_agency  VARCHAR2(4)
  , item_release_date   DATE );
/
 
CREATE OR REPLACE
  TYPE item_tab IS TABLE OF item_obj;
/
 
/* Conditionally drop the common lookup types, table and then objectWHERE. */
BEGIN
  FOR i IN (SELECT   object_name
            FROM     user_objects
            WHERE    object_name = 'INSERT_ITEMS') LOOP
    EXECUTE IMMEDIATE 'DROP PROCEDURE '||i.object_name;
  END LOOP;
END;
/
 
/* Create draft insert_items procedure. */
CREATE PROCEDURE insert_items
( pv_items  ITEM_TAB ) IS
 
BEGIN
  /* Read the list of items and call the insert_item procedure. */
  FOR i IN 1..pv_items.COUNT LOOP
    insert_item( pv_item_barcode => pv_items(i).item_barcode
               , pv_item_type => pv_items(i).item_type
               , pv_item_title => pv_items(i).item_title
               , pv_item_subtitle => pv_items(i).item_subtitle
               , pv_item_rating => pv_items(i).item_rating
               , pv_item_rating_agency => pv_items(i).item_rating_agency
               , pv_item_release_date => pv_items(i).item_release_date );
  END LOOP;
END;
/
 
 
/* Create draft insert_item procedure. */
DECLARE
  /* Create a collection. */
  lv_items  ITEM_TAB :=
    item_tab(
        item_obj( item_barcode => 'B002ZHKZCO'
                , item_type => 'BLU-RAY'
                , item_title => 'The Bourne Identity'
                , item_subtitle => NULL
                , item_rating => 'PG-13'
                , item_rating_agency => 'MPAA'
                , item_release_date => '19-JAN-2010')
      , item_obj( item_barcode => 'B0068FZ18C'
                , item_type => 'BLU-RAY'
                , item_title => 'The Bourne Supremacy'
                , item_subtitle => NULL
                , item_rating => 'PG-13'
                , item_rating_agency => 'MPAA'
                , item_release_date => '10-JAN-2012')
      , item_obj( item_barcode => 'B00AIZK85E'
                , item_type => 'BLU-RAY'
                , item_title => 'The Bourne Ultimatum'
                , item_subtitle => NULL
                , item_rating => 'PG-13'
                , item_rating_agency => 'MPAA'
                , item_release_date => '11-DEC-2012')
      , item_obj( item_barcode => 'B01AT251XY'
                , item_type => 'BLU-RAY'
                , item_title => 'The Bourne Legacy'
                , item_subtitle => NULL
                , item_rating => 'PG-13'
                , item_rating_agency => 'MPAA'
                , item_release_date => '05-APR-2016'));
BEGIN
  /* Call a element processing procedure. */
  insert_items(lv_items);
END;
/ 
 
/* Query result from the insert_item procedure. */
COL item_barcode FORMAT A10 HEADING "Item|Barcode"
COL item_title   FORMAT A30 HEADING "Item Title"
COL release_date FORMAT A12 HEADING "Item|Release|Date"
SELECT   i.item_barcode
,        i.item_title
,        i.item_release_date AS release_date
FROM     item i
WHERE    REGEXP_LIKE(i.item_title,'^.*bourne.*$','i')
ORDER BY i.item_release_date;