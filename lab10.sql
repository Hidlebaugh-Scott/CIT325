-- Show the output
SET SERVEROUTPUT ON

-- Begin log file
SPOOL apply_plsql_lab10.txt;

SET TRIMSPOOL ON
SET TRIMOUT ON
SET WRAP OFF
SET PAGESIZE 0
SET SERVEROUTPUT ON

BEGIN
    dbms_output.put_line('===============================');
    dbms_output.put_line('             PART 0            ');
    dbms_output.put_line('===============================');
END;
/

DROP SEQUENCE base_t;
DROP TABLE logger;
/**
* The order we drop here is very important! We must drop all types
* that have come from others (inheritance). For example if you had
* TYPE A, B, and C where C overrides B and B is overriding A you
* would have to drop C, then B, then A.
*/
DROP TYPE item_t;
DROP TYPE base_t;

BEGIN
    dbms_output.put_line('===============================');
    dbms_output.put_line('             PART 1            ');
    dbms_output.put_line('===============================');
END;
/

/**
* Here is our generic fruit object, all fruits can inherit from here.
* This is essentially just our blueprints for the fruit_t object.
*/
CREATE OR REPLACE
  TYPE base_t IS OBJECT
  ( oname VARCHAR2(30)
  , name  VARCHAR2(30)
  , CONSTRUCTOR FUNCTION base_t RETURN SELF AS RESULT
  , CONSTRUCTOR FUNCTION base_t
    ( oname  VARCHAR2
    , name   VARCHAR2 ) RETURN SELF AS RESULT
  , MEMBER FUNCTION get_name RETURN VARCHAR2
  , MEMBER FUNCTION get_oname RETURN VARCHAR2
  , MEMBER PROCEDURE set_oname (oname VARCHAR2)
  , MEMBER FUNCTION to_string RETURN VARCHAR2)
  INSTANTIABLE NOT FINAL;
/

DESCRIBE base_t;

BEGIN
    dbms_output.put_line('===============================');
    dbms_output.put_line('             PART 2            ');
    dbms_output.put_line('===============================');
END;
/

/**
* Here we add a body to the generic fruit object and Override
* the fruit_t constructor function. This is so we can extend
* (expand) what the fruit_t object can do.
*/
CREATE OR REPLACE
  TYPE BODY base_t IS

    /* Override constructor. */
    CONSTRUCTOR FUNCTION base_t RETURN SELF AS RESULT IS
    BEGIN
      self.oname := 'BASE_T';
      RETURN;
    END;

    /* Formalized default constructor. */
    CONSTRUCTOR FUNCTION base_t
    ( oname  VARCHAR2
    , name   VARCHAR2 ) RETURN SELF AS RESULT IS
    BEGIN
      /* Assign an oname value. */
      self.oname := oname;

      RETURN;
    END;

    /* A getter function to return the name attribute. */
    MEMBER FUNCTION get_name RETURN VARCHAR2 IS
    BEGIN
      RETURN self.name;
    END get_name;

    /* A getter function to return the name attribute. */
    MEMBER FUNCTION get_oname RETURN VARCHAR2 IS
    BEGIN
      RETURN self.oname;
    END get_oname;

    /* A setter procedure to set the oname attribute. */
    MEMBER PROCEDURE set_oname
    ( oname VARCHAR2 ) IS
    BEGIN
      self.oname := oname;
    END set_oname;

    /* A to_string function. */
    MEMBER FUNCTION to_string RETURN VARCHAR2 IS
    BEGIN
      RETURN '['||self.oname||']';
    END to_string;
  END;
/

DECLARE
  /* Create a default instance of the object type. */
  lv_instance  BASE_T := base_t();
BEGIN
  /* Print the default value of the oname attribute. */
  dbms_output.put_line('Default  : ['||lv_instance.get_oname()||']');

  /* Set the oname value to a new value. */
  lv_instance.set_oname('SUBSTITUTE');

  /* Print the default value of the oname attribute. */
  dbms_output.put_line('Override : ['||lv_instance.get_oname()||']');
END;
/

BEGIN
    dbms_output.put_line('===============================');
    dbms_output.put_line('             PART 3            ');
    dbms_output.put_line('===============================');
END;
/
/** Oracle supports storing objects in the database. */

/* Create logger table. */
CREATE TABLE logger
( cart_id  NUMBER
, item     BASE_T );

/* Create logger_s sequence. */
CREATE SEQUENCE logger_s;

INSERT INTO cart
VALUES
( logger_s.NEXTVAL
, base_t());

INSERT INTO logger
VALUES
( logger_s.NEXTVAL
, base_t(oname => 'BASE_T', name => 'NEW' ));

DECLARE
  /* Declare a variable of the UDT type. */
  lv_base  BASE_T;
BEGIN
  /* Assign an instance of the variable. */
  lv_base := base_t(
      oname => 'BASE_T'
    , name => 'OLD' );

    /* Insert instance of the base_t object type into table. */
    INSERT INTO logger
    VALUES (logger_s.NEXTVAL, lv_base);

    /* Commit the record. */
    COMMIT;
END;
/

COLUMN oname     FORMAT A20
COLUMN get_name  FORMAT A20
COLUMN to_string FORMAT A20
SELECT g.logger_id
,      g.item.oname AS oname
,      NVL(g.item.get_name(),'Unset') AS get_name
,      g.item.to_string() AS to_string
FROM  (SELECT c.logger_id
       ,      TREAT(c.item AS base_t) AS item
       FROM   logger c) g
WHERE  g.item.oname = 'BASE_T';

BEGIN
    dbms_output.put_line('===============================');
    dbms_output.put_line('             PART 4            ');
    dbms_output.put_line('===============================');
END;
/

/**
* Now lets extend the generic fruit_t object! We can make
* sub-types or sub-classes as long as what we try to inherit
* from is not marked as FINAL. Here we'll make apple_t a
* sub-type of the fruit_t object.
*/
CREATE OR REPLACE
  TYPE apple_t UNDER fruit_t
  ( variety     VARCHAR2(20)
  , class_size  VARCHAR2(20)
  , CONSTRUCTOR FUNCTION apple_t
    ( oname       VARCHAR2
    , name        VARCHAR2
    , variety     VARCHAR2
    , class_size  VARCHAR2 ) RETURN SELF AS RESULT
  , OVERRIDING MEMBER FUNCTION get_name RETURN VARCHAR2
  , OVERRIDING MEMBER FUNCTION to_string RETURN VARCHAR2)
  INSTANTIABLE NOT FINAL;
/

DESCRIBE apple_t;

CREATE OR REPLACE
  TYPE BODY apple_t IS

    /* Default constructor, implicitly available, but you should
       include it for those who forget that fact. */
    CONSTRUCTOR FUNCTION apple_t
    ( oname       VARCHAR2
    , name        VARCHAR2
    , variety     VARCHAR2
    , class_size  VARCHAR2 ) RETURN SELF AS RESULT IS
    BEGIN
      /* Assign inputs to instance variables. */
      self.oname := oname;

      /* Assign a designated value or assign a null value. */
      IF name IS NOT NULL AND name IN ('NEW','OLD') THEN
        self.name := name;
      END IF;

      /* Assign inputs to instance variables. */
      self.variety := variety;
      self.class_size := class_size;

      /* Return an instance of self. */
      RETURN;
    END;

    /* An overriding function for the generalized class. */
    OVERRIDING MEMBER FUNCTION get_name RETURN VARCHAR2 IS
    BEGIN
      RETURN (self AS fruit_t).get_name();
    END get_name;

    /* An overriding function for the generalized class. */
    OVERRIDING MEMBER FUNCTION to_string RETURN VARCHAR2 IS
    BEGIN
      RETURN (self AS fruit_t).to_string()||'.['||self.name||']';
    END to_string;
  END;
/

BEGIN
    dbms_output.put_line('===============================');
    dbms_output.put_line('             PART 5            ');
    dbms_output.put_line('===============================');
END;
/

INSERT INTO cart
VALUES
( cart_s.NEXTVAL
, apple_t(
    oname => 'APPLE_T'
  , name => 'NEW'
  , variety => 'PIPPIN'
  , class_size => 'MEDIUM'));

COLUMN oname     FORMAT A20
COLUMN get_name  FORMAT A20
COLUMN to_string FORMAT A20
SELECT g.cart_id
,      g.item.oname AS oname
,      NVL(g.item.get_name(),'Unset') AS get_name
,      g.item.to_string() AS to_string
FROM  (SELECT c.cart_id
       ,      TREAT(c.item AS fruit_t) AS item
       FROM   cart c) g
WHERE  g.item.oname IN ('FRUIT_T','APPLE_T');