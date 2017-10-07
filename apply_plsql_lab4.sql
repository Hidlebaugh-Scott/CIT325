SPOOL plsql_lab4.txt

/* Display Output */
SET SERVEROUTPUT ON
SET VERIFY OFF;

CREATE OR REPLACE
        TYPE ordinal IS OBJECT
        ( xnumber  NUMBER
        , xtext    VARCHAR2(9));
/
CREATE OR REPLACE
        TYPE gift_name IS OBJECT
        ( xqty    VARCHAR2(6)
        , xgift   VARCHAR2(30));

/

DECLARE
  /* Declare an array of days and gifts. */
  TYPE days IS TABLE OF ordinal;
  TYPE gifts IS TABLE OF gift_name;

 

  /* Initialize the collection of days. */                    
  lv_days DAYS := days( ordinal(1,'First')
                      , ordinal(2,'Second')
                      , ordinal(3,'Third')
                      , ordinal(4,'Fourth')
                      , ordinal(5,'Fifth')
                      , ordinal(6,'Sixth')
                      , ordinal(7,'Seventh')
                      , ordinal(8,'Eighth')
                      , ordinal(9,'Ninth')
                      , ordinal(10,'Tenth')
                      , ordinal(11,'Eleventh')
                      , ordinal(12,'Twelfth'));

   /* Initialize the collection of gifts. */
   lv_gifts GIFTS := gifts(gift_name('and a','Partridge in a pear tree')
                        , gift_name('Two','Turtle Doves')
                        , gift_name('Three','French Hens')
                        , gift_name('Four','Calling birds')
                        , gift_name('Five','Golden rings')
                        , gift_name('Six','Geese a laying')
                        , gift_name('Seven','Swans a swimming')
                        , gift_name('Eight','Maids a milking')
                        , gift_name('Nine','Ladies dancing')
                        , gift_name('Ten','Lords a leaping')
                        , gift_name('Eleven','Pipers piping')
                        , gift_name('Twelve','Drummers drumming'));

BEGIN

   

  /* Read forward through the contents of the loop. */

  FOR i IN 1..lv_days.COUNT LOOP
          dbms_output.put_line('On the '||lv_days(i).xtext||' day of Christmas my true love gave to me ');

        /* Read backward through a range of values. */

          FOR x IN REVERSE 1..i LOOP
            /* Print values right aligned. */
            IF i > 1 THEN
              dbms_output.put_line(lv_gifts(x).xqty||' '||lv_gifts(x).xgift);
            ELSE
              dbms_output.put_line('a '||lv_gifts(x).xgift);
            END IF;

          END LOOP;
        dbms_output.put_line(CHR(13));
  END LOOP;

END;

/

SPOOL OFF
